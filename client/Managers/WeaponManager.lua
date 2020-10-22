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
    local camera = config.Camera

    if camera then
        camera:addOffset(Enums.CameraOffset.Animation.ID, CFrame.new())
        camera:addOffset(Enums.CameraOffset.Recoil.ID, CFrame.new(), true)
    end

    local self = {}
    self.Camera = camera
    self.ActiveWeapons = {}

    self.Connections = {}
    self.Connections.Characters = {}
    self.Connections.Viewport = nil
    self.Connections.LocalCharacter = nil

    self.ViewModelArms = ViewModelArms.new(config and config.ViewModelArmsAsset or _G.VIEWMODEL.DEFAULT_ARMS)
    self.CameraRecoilSpring = Spring.new(4, 50, 4*CAMERA_RECOIL_ANGULAR_DAMPENING, 4*CAMERA_RECOIL_ANGULAR_SPEED)

    setmetatable(self, WeaponManager)

    return self
end

---
---@param name string Weapon name to create
---@param uuid string UUID given by server
function WeaponManager:create(name, uuid)
    local gun = Gun.new(name)
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
function WeaponManager:equipViewport(weapon, networked)
    local object = self.ActiveWeapons[weapon.UUID]
    assert(object.Owner == Players.LocalPlayer, "cannot equip a weapon as viewport that does not belong to local player")

    local function equip()
        -- equip new weapon
        self.Connections.Viewport = weapon
        self.ViewModelArms:attach(weapon)
        weapon:equip()
        weapon.ViewModel.Parent = _G.Path.ClientViewmodel

        -- prevent loopback
        if networked then
            return
        end
        NetworkLib:send(Enums.PacketType.WeaponEquip, weapon.UUID)
    end

    if self.Connections.Viewport then
        local yield = self.Connections.Viewport:unequip()
        yield:once("done", equip)
    else
        equip()
    end
end

function WeaponManager:fire(weapon, state)
    if not weapon.Configuration.Charge and state then
        if weapon:fire() then
            if weapon == self.Connections.Viewport then

                local recoil = weapon.Configuration.CameraRecoil
                local rotRange = recoil.Range
                local rotV = recoil.V3
                local pitch, yaw, roll =
                    springRange(rotV.x, rotRange.x),
                    springRange(rotV.y, rotRange.y),
                    springRange(rotV.z, rotRange.z)

                yaw = (math.random() > 0.5 and -yaw) or yaw

                self.CameraRecoilSpring:shove(pitch, yaw, roll)
            end
        end
    end

end

function WeaponManager:reload(weapon)
    weapon:reload()
end

function WeaponManager:setState(weapon, stateName, stateValue)
    weapon:setState(stateName, stateValue)
end

function WeaponManager:step(dt, camera, velocity)
    -- handle viewport weapon
    self.CameraRecoilSpring:update(math.min(1, dt))
    local recoil = self.CameraRecoilSpring.Position
    camera:updateOffset(Enums.CameraOffset.Recoil.ID, CFrame.Angles(recoil.X, recoil.Y, recoil.Z))
    camera:rawMoveLook(recoil.Y*dt*60, recoil.X*dt*60)

    self.Connections.Viewport:setState("Movement", velocity)
    self.Connections.Viewport.Animator:_step(dt)
    camera:updateOffset(Enums.CameraOffset.Animation.ID, self.Connections.Viewport:getExpectedCameraCFrame())
    self.Connections.Viewport:update(dt, camera.CFrame)

    -- handle third person weapons
end

-- network plug-in
function WeaponManager:route()
end

return WeaponManager
