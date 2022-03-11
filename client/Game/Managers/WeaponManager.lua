local Players = game:GetService("Players")

local CAMERA_RECOIL_ANGULAR_DAMPENING = _G.CAMERA.RECOIL_ANGULAR_DAMPENING
local CAMERA_RECOIL_ANGULAR_SPEED = _G.CAMERA.RECOIL_ANGULAR_SPEED

local GameEnum = shared.GameEnum

local NetworkLib = require(shared.Common.NetworkLib)
local log, logwarn = require(shared.Common.Log)(script:GetFullName())
local Spring = require(shared.Common.Spring)
local Maid = require(shared.Common.Maid)
local SmallUtils = require(shared.Common.SmallUtils)

local Gun = require(_G.Client.Game.Gun)
local ViewModelArms = require(_G.Client.Game.ViewModelArms)

---Uses a value and makes a range based on v0 -+ range
---@param v0 number
---@param range number
local function springRange(v0, range)
    return SmallUtils.randomFloatRange(v0 - range, v0 + range)
end

---Equip weapon specifically for viewport
---@param manager WeaponManager
---@param weapon Gun
local function equipViewport(manager, weapon)
    if manager.ViewportWeapon then
        manager.ViewModelArms:unattach()
        manager.ViewportWeapon.ViewModel.Parent = nil
    end
    -- equip new weapon
    manager.ViewportWeapon = weapon
    manager.ViewModelArms:attach(weapon)
    weapon:equip()
    weapon.ViewModel.Parent = _G.Path.ClientViewmodel
end


local function fireViewportWeapon(manager, weapon)
    local recoil = weapon.Configuration.CameraRecoil
    local rotRange = recoil.Range
    local rotV = recoil.V3
    local pitch, yaw, roll =
        springRange(rotV.x, rotRange.x),
        springRange(rotV.y, rotRange.y),
        springRange(rotV.z, rotRange.z)

    yaw = (math.random() > 0.5 and -yaw) or yaw

    manager.CameraRecoilSpring:shove(pitch, yaw, roll)

    local camCF = manager.Camera:getCFrame()
    manager.ProjectileManager:create(weapon, camCF.p, camCF.lookVector)
end

---Manages all weapons in a single container
---@class WeaponManager
local WeaponManager = {}
WeaponManager.__index = WeaponManager

---
---@param config table
---@return table
function WeaponManager.new(config)
    assert(config, "lacking configuration, provide it as the 1st argument")
    assert(config.Camera, "WeaponManager requires a camera, provide it in the config table")
    assert(config.ProjectileManager, "WeaponManager requires ProjectileManager, provide it in the config table")
    assert(config.GameMode, "WeaponManager requires a gamemode to be specified, provide it in the config table")

    local camera = config.Camera

    if camera then
        camera:addOffset(GameEnum.CameraOffset.Animation.ID, CFrame.new())
        camera:addOffset(GameEnum.CameraOffset.Recoil.ID, CFrame.new(), true)
    end

    local self = {}
    self.Camera = camera
    self.ProjectileManager = config.ProjectileManager
    self.GameMode = config.GameMode
    self.ActiveWeapons = {}
    self.AutoFire = {}
    self.ViewportWeapon = nil

    self.Connections = {}
    self.Connections.Characters = {}
    self.Connections.LocalCharacter = nil

    self.ViewModelArms = ViewModelArms.new(config and config.ViewModelArmsAsset or _G.VIEWMODEL.DEFAULT_ARMS)
    self.CameraRecoilSpring = Spring.new(4, 50, 4 * CAMERA_RECOIL_ANGULAR_DAMPENING, 4 * CAMERA_RECOIL_ANGULAR_SPEED)

    setmetatable(self, WeaponManager)
    Maid.watch(self)

    self._packetToFunction = {
        [GameEnum.PacketType.WeaponEquip] = self.networkEquip;
        [GameEnum.PacketType.WeaponFire] = self.networkFire;
        [GameEnum.PacketType.WeaponRegister] = self.networkRegister;
        [GameEnum.PacketType.WeaponUnregister] = self.networkUnregister;
        [GameEnum.PacketType.WeaponAdhocRegister] = self.networkAdhocRegister;
    }

    return self
end

---Creates an unregistered Gun instance by an asset name
---@param assetName string Weapon assetName to create
function WeaponManager:create(assetName)
    local gun = Gun.new(assetName, self.GameMode)
    return gun
end

---Register a weapon's UUID to allow communication
---of weapon data over the network
---@param weapon Gun
---@param uuid string
---@param player userdata
function WeaponManager:register(weapon, uuid, player)
    weapon.UUID = uuid
    self.ActiveWeapons[uuid] = {Weapon = weapon, Owner = player}
    log(1, "registered", weapon.Configuration.Name, "with UUID of", uuid, "owned by", player)
    return WeaponManager
end

---Unregister a weapon UUID for garbage cleaning
---@param weaponOrUUID table
function WeaponManager:unregister(weaponOrUUID)
    local uuid = weaponOrUUID
    if typeof(weaponOrUUID) ~= "string" then
        uuid = weaponOrUUID.UUID
    end
    assert(self.ActiveWeapons[uuid], "weapon " .. weapon.Configuration.Name .. " is not registered in this WeaponManager")
    self.ActiveWeapons[uuid].Weapon:destroy()
    self.ActiveWeapons[uuid] = nil
end

---
---@param player any
---@param assetName any
---@param uuid any
function WeaponManager:networkRegister(player, assetName, uuid, overwrite)
    if self.ActiveWeapons[uuid] and not overwrite then
        logwarn(1, "UUID", uuid, "is already registered in this WeaponManager (is server wrong?) ignoring")
        return
    else
        logwarn(2, "server is overwriting UUID of", uuid)
    end

    local weapon = self:create(assetName)
    self:register(weapon, uuid, player)
end

function WeaponManager:networkUnregister(uuid)
    self:unregister(uuid)
end

---
---@param uuid any
---@return any
function WeaponManager:getByUUID(uuid)
    assert(self.ActiveWeapons[uuid], "UUID " .. uuid .. " is not registered in this WeaponManager, unable to get Weapon instance")
    return self.ActiveWeapons[uuid]
end

---
---@param owner any
---@return any
---@return any
function WeaponManager:getOwnerEquipped(owner)
    for uuid, container in pairs(self.ActiveWeapons) do
        if container.Owner == owner then
            return container.Weapon, uuid
        end
    end
end

function WeaponManager:equip(player, weapon)
    log(1, player, "is equipping", weapon.Configuration.Name)
    weapon.ViewModel.Parent = _G.Path.RayIgnore
end

---Equips the weapon onto the user's screen.
---Cannot equip non-client owned weapons
---@param weapon Gun Weapon object to equip
---@param networked boolean Whether this call was networked or not (to prevent loopback)
function WeaponManager:equipViewport(weapon, networked)
    assert(self.ActiveWeapons[weapon.UUID], "weapon " .. weapon.Configuration.Name .. " is not registered in this WeaponManager")
    log(1, "equip viewport weapon", weapon.Configuration.Name)

    local object = self.ActiveWeapons[weapon.UUID]
    assert(
        object.Owner == Players.LocalPlayer,
        "cannot equip a weapon as Viewport that does not belong to local player"
    )

    if self.ViewportWeapon then
        self.ViewportWeapon:unequip():once(
            "DONE",
            function()
                equipViewport(self, weapon)
            end
        )
    else
        equipViewport(self, weapon)
    end

    -- prevent loopback
    if not networked then
        NetworkLib:send(GameEnum.PacketType.WeaponEquip, weapon.UUID)
    end
end

function WeaponManager:networkEquip(player, uuid)
    if player == Players.LocalPlayer then
        self:equipViewport(self:getByUUID(uuid).Weapon, true)
        return
    end

    self:equip(player, self:getByUUID(uuid).Weapon)
end

function WeaponManager:fire(weapon, state)
    if weapon.ActiveFireMode == GameEnum.FireMode.Automatic and state then
        self.AutoFire[weapon] = true
    else
        self.AutoFire[weapon] = nil
    end

    if weapon.State.Sprint then return end
    if not weapon.Configuration.Charge and state then
        local didFire, reason = weapon:fire()
        if didFire then
            fireViewportWeapon(self, weapon)
            NetworkLib:send(GameEnum.PacketType.WeaponFire, weapon.UUID)
        elseif reason == "EMPTY" then
            self:reload(weapon)
        end
    end
end

function WeaponManager:networkFire(uuid)
    local weapon = self:getByUUID(uuid).Weapon
    if not weapon then return end
    if weapon == self.ViewportWeapon then return end

    weapon:fire(true)
end

function WeaponManager:reload(weapon)
    if weapon.State.Sprint then return end
    weapon:reload()
    NetworkLib:send(GameEnum.PacketType.WeaponReload, weapon.UUID)
end

function WeaponManager:networkReload(uuid)
    local weapon = self:getByUUID(uuid).Weapon
    if not weapon then return end
        
    weapon:reload()
end

function WeaponManager:setState(weapon, stateName, stateValue)
    weapon:setState(stateName, stateValue)
end

function WeaponManager:step(dt, camera, movementController)
    -- handle viewport weapon
    if self.ViewportWeapon then
        self.ViewportWeapon:setState("Sprint", movementController.IsSprinting)

        self.CameraRecoilSpring:update(math.min(1, dt))
        local recoil = self.CameraRecoilSpring.Position
        camera:updateOffset(GameEnum.CameraOffset.Recoil.ID, CFrame.Angles(recoil.X, recoil.Y, recoil.Z))
        camera:rawMoveLook(recoil.Y * dt * 60, recoil.X * dt * 60)

        self.ViewportWeapon:setState("Movement", movementController.Velocity.magnitude)
        self.ViewportWeapon.Animator:_step(dt)
        camera:updateOffset(GameEnum.CameraOffset.Animation.ID, self.ViewportWeapon:getExpectedCameraCFrame())
        self.ViewportWeapon:update(dt, camera.CFrame)

        -- handle automatic fire
        for weapon, _ in pairs(self.AutoFire) do
            if weapon == self.ViewportWeapon and not weapon.State.Sprint then
                local didFire, reason = weapon:fire()
                if didFire then
                    fireViewportWeapon(self, weapon)
                elseif reason == "EMPTY" then
                    self:reload(weapon)
                end
            end
        end
    end

    -- TODO: handle third person weapons
    for _, container in pairs(self.ActiveWeapons) do
        if self.ViewportWeapon ~= container.Weapon then
            -- ! dangerous - Character may not always be available and roblox is
            -- ! usually stupid for telling when it's ready, 
            -- ! so make a yet again wrapped instance maybe?
            -- TODO: wrapper to player for lookvectors
            container.Weapon:update(dt, container.Owner.Character.Head.CFrame)
        end
    end
end

function WeaponManager:networkAdhocRegister(weapons)
    for _, weapon in pairs(weapons) do
        self:networkRegister(weapon.Owner, weapon.AssetName, weapon.UUID)
    end
end

function WeaponManager:route(packetType, player, ...)
    local func = self._packetToFunction[packetType]
    if func then
        func(self, player, ...)
    end
end

return WeaponManager
