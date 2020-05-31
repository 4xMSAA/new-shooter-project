local Players = game:GetService("Players")

local NetworkLib = require(shared.Common.NetworkLib)
local Enums = shared.Enums

local Gun = require(_G.Client.Core.Gun)
local ViewModelArms = require(_G.Client.Core.ViewModelArms)

---Manages all weapons in a single container
---@class WeaponManager
local WeaponManager = {}
WeaponManager.__index = WeaponManager

function WeaponManager.new(config)
    local self = {}
    self.ActiveWeapons = {}

    self.Connections = {}
    self.Connections.Characters = {}
    self.Connections.Viewport = nil
    self.Connections.LocalCharacter = nil

    self.ViewModelArms = ViewModelArms.new(config and config.ViewModelArmsAsset or _G.VIEWMODEL.DEFAULT_ARMS)

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
    assert(object.Owner == Players.LocalPlayer, "cannot equip a weapon that does not belong to local player")

    local function equip()
        -- equip new weapon
        self.Connections.Viewport = weapon
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

function WeaponManager:fire(weapon)
    weapon:fire()
end

function WeaponManager:reload(weapon)
    weapon:reload()
end

function WeaponManager:setState(weapon, stateName, stateValue)
    weapon:setState(stateName, stateValue)
end

function WeaponManager:step(dt, camera, velocity)
    -- handle viewport weapon
    self.Connections.Viewport:setState("Movement", velocity)
    self.Connections.Viewport.Animator:_step(dt)
    self.Connections.Viewport:update(dt, camera.CFrame)

    -- handle third person weapons
end

-- network plug-in
function WeaponManager:route()
end

return WeaponManager
