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

local function equip(manager, weapon, networked)
    -- equip new weapon
    manager.Connections.Viewport = weapon
    manager.ViewModelArms:attach(weapon)
    weapon:equip()
    weapon.ViewModel.Parent = _G.Path.ClientViewmodel

    -- prevent loopback
    if networked then
        return
    end
    NetworkLib:send(Enums.PacketType.WeaponEquip, weapon.UUID)
end

---Manages all weapons in a single container
---@class WeaponManager
local WeaponManager = {}
WeaponManager.__index = WeaponManager

function WeaponManager.new(config)
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

    self.Connections = {}
    self.Connections.Characters = {}
    self.Connections.Viewport = nil
    self.Connections.LocalCharacter = nil

    self.ViewModelArms = ViewModelArms.new(config and config.ViewModelArmsAsset or _G.VIEWMODEL.DEFAULT_ARMS)
    self.CameraRecoilSpring = Spring.new(4, 50, 4 * CAMERA_RECOIL_ANGULAR_DAMPENING, 4 * CAMERA_RECOIL_ANGULAR_SPEED)

    setmetatable(self, WeaponManager)
    Maid.watch(self)

    return self
end

---
---@param assetName string Weapon assetName to create
---@param uuid string UUID given by server
function WeaponManager:create(assetName, uuid)
    local gun = Gun.new(assetName, self.GameMode)
    gun.UUID = uuid

    return gun
end

---
---@param weapon Gun
---@param uuid string
---@param player userdata
function WeaponManager:register(weapon, uuid, player)
    self.ActiveWeapons[uuid] = {Weapon = weapon, Owner = player}
    weapon.UUID = uuid
    return WeaponManager
end

---Equips the weapon onto the user's screen.
---Cannot equip non-client owned weapons
---@param weapon Gun Weapon object to equip
---@param networked boolean Whether this call was networked or not (to prevent loopback)
function WeaponManager:equipViewport(weapon, networked)
    local object = self.ActiveWeapons[weapon.UUID]
    assert(
        object.Owner == Players.LocalPlayer,
        "cannot equip a weapon as viewport that does not belong to local player"
    )

    if self.Connections.Viewport then
        local yield = self.Connections.Viewport:unequip()
        yield:once(
            "done",
            function()
                equip(self, weapon, networked)
            end
        )
    else
        equip(self, weapon, networked)
    end
end

function WeaponManager:fire(weapon, state)
    if weapon.ActiveFireMode == Enums.FireMode.Automatic and state then
        self.AutoFire[weapon] = true
    else
        self.AutoFire[weapon] = nil
    end

    if not weapon.Configuration.Charge and state then
        if weapon:fire() then
            if weapon == self.Connections.Viewport then
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
    self.CameraRecoilSpring:update(math.min(1, dt))
    local recoil = self.CameraRecoilSpring.Position
    camera:updateOffset(Enums.CameraOffset.Recoil.ID, CFrame.Angles(recoil.X, recoil.Y, recoil.Z))
    camera:rawMoveLook(recoil.Y * dt * 60, recoil.X * dt * 60)

    self.Connections.Viewport:setState("Movement", velocity)
    self.Connections.Viewport.Animator:_step(dt)
    camera:updateOffset(Enums.CameraOffset.Animation.ID, self.Connections.Viewport:getExpectedCameraCFrame())
    self.Connections.Viewport:update(dt, camera.CFrame)

    -- TODO: handle third person weapons

    -- handle automatic fire
    for weapon, _ in pairs(self.AutoFire) do
        if weapon:fire() then
            if weapon == self.Connections.Viewport then
                fireViewportWeapon(self, weapon)
            end
        end
    end
end

return WeaponManager
