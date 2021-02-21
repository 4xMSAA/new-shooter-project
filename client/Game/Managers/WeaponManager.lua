local Players = game:GetService("Players")

local CAMERA_RECOIL_ANGULAR_DAMPENING = _G.CAMERA.RECOIL_ANGULAR_DAMPENING
local CAMERA_RECOIL_ANGULAR_SPEED = _G.CAMERA.RECOIL_ANGULAR_SPEED

local NetworkLib = require(shared.Common.NetworkLib)
local Enums = shared.Enums

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

---Manages all weapons in a single container
---@class WeaponManager
local WeaponManager = {}
WeaponManager.__index = WeaponManager

function WeaponManager.new(config)
    assert(config, "lacking configuration, provide it as the 1st argument")
    assert(config.Camera, "WeaponManager requires a camera, provide it in the config table")
    assert(config.ProjectileManager, "WeaponManager requires ProjectileManager, provide it in the config table")
    assert(config.GameMode, "WeaponManager requires a gamemode to be specified, provide it in the config table")

    local camera = config.Camera

    if camera then
        camera:addOffset(Enums.CameraOffset.Animation.ID, CFrame.new())
        camera:addOffset(Enums.CameraOffset.Recoil.ID, CFrame.new(), true)
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
        [Enums.PacketType.WeaponEquip] = self.networkEquip;
        [Enums.PacketType.WeaponFire] = self.fire;
        [Enums.PacketType.WeaponRegister] = self.networkRegister;
    }

    return self
end

---
---@param assetName string Weapon assetName to create
function WeaponManager:create(assetName)
    local gun = Gun.new(assetName, self.GameMode)
    return gun
end

---
---@param weapon Gun
---@param uuid string
---@param player userdata
function WeaponManager:register(weapon, uuid, player)
    weapon.UUID = uuid
    self.ActiveWeapons[uuid] = {Weapon = weapon, Owner = player}
    print("registered", weapon.Configuration.Name, "with UUID of", uuid, "owned by", player)
    return WeaponManager
end

function WeaponManager:networkRegister(player, assetName, uuid)
    local weapon = self:create(assetName)
    self:register(weapon, uuid, player)
end

function WeaponManager:getByUUID(uuid)
    return self.ActiveWeapons[uuid];
end

function WeaponManager:equip(player, weapon)
    print(player, "is equipping", weapon.Configuration.Name)
end


---Equip weapon specifically for viewport
---@param manager WeaponManager
---@param weapon Gun
local function equipViewport(manager, weapon)
    if manager.ViewportWeapon then
        manager.ViewportWeapon.ViewModel.Parent = nil
    end
    -- equip new weapon
    manager.ViewportWeapon = weapon
    manager.ViewModelArms:attach(weapon)
    weapon:equip()
    weapon.ViewModel.Parent = _G.Path.ClientViewmodel
end

---Equips the weapon onto the user's screen.
---Cannot equip non-client owned weapons
---@param weapon Gun Weapon object to equip
---@param networked boolean Whether this call was networked or not (to prevent loopback)
function WeaponManager:equipViewport(weapon, networked)
    assert(self.ActiveWeapons[weapon.UUID], "weapon " .. weapon.Configuration.Name .. " is not registered in this WeaponManager")
    local object = self.ActiveWeapons[weapon.UUID]
    assert(
        object.Owner == Players.LocalPlayer,
        "cannot equip a weapon as Viewport that does not belong to local player"
    )

    if self.ViewportWeapon then
        self.ViewportWeapon:unequip():once(
            "DONE",
            function()
                equipViewport(self, weapon, networked)
            end
        )
    else
        equipViewport(self, weapon, networked)
    end

    -- prevent loopback
    if networked then
        return
    end
    NetworkLib:send(Enums.PacketType.WeaponEquip, weapon.UUID)
end

function WeaponManager:networkEquip(player, uuid)
    if player == Players.LocalPlayer then
        print("equip viewport weapon", self:getByUUID(uuid).Weapon)
        self:equipViewport(self:getByUUID(uuid).Weapon, true)
        return
    end

    self:equip(player, self:getByUUID(uuid).Weapon)
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

function WeaponManager:fire(weapon, state)
    if weapon.ActiveFireMode == Enums.FireMode.Automatic and state then
        self.AutoFire[weapon] = true
    else
        self.AutoFire[weapon] = nil
    end

    if not weapon.Configuration.Charge and state then
        if weapon:fire() then
            if weapon == self.ViewportWeapon then
                fireViewportWeapon(self, weapon)
            end
        end
    end
end

function WeaponManager:reload(weapon, networked)
    weapon:reload()
    if not networked then
        NetworkLib:send(Enums.PacketType.WeaponReload)
    end
end

function WeaponManager:setState(weapon, stateName, stateValue)
    weapon:setState(stateName, stateValue)
end

function WeaponManager:step(dt, camera, velocity)
    -- handle viewport weapon
    if (self.ViewportWeapon) then
        self.CameraRecoilSpring:update(math.min(1, dt))
        local recoil = self.CameraRecoilSpring.Position
        camera:updateOffset(Enums.CameraOffset.Recoil.ID, CFrame.Angles(recoil.X, recoil.Y, recoil.Z))
        camera:rawMoveLook(recoil.Y * dt * 60, recoil.X * dt * 60)

        self.ViewportWeapon:setState("Movement", velocity)
        self.ViewportWeapon.Animator:_step(dt)
        camera:updateOffset(Enums.CameraOffset.Animation.ID, self.ViewportWeapon:getExpectedCameraCFrame())
        self.ViewportWeapon:update(dt, camera.CFrame)

        -- handle automatic fire
        for weapon, _ in pairs(self.AutoFire) do
            if weapon:fire() then
                if weapon == self.ViewportWeapon then
                    fireViewportWeapon(self, weapon)
                end
            end
        end
    end

    -- TODO: handle third person weapons
    for weapon, _ in pairs(self.ActiveWeapons) do

    end
end

function WeaponManager:route(packetType, player, ...)
    local func = self._packetToFunction[packetType]
    if func then
        func(self, player, ...)
    end
end

return WeaponManager
