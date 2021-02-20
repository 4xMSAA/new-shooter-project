local HttpService = game:GetService("HttpService")

local Maid = require(shared.Common.Maid)

local NetworkLib = require(shared.Common.NetworkLib)
local Enums = shared.Enums

local ServerGun = require(_G.Server.Game.ServerGun)

---Server-side weapon manager to handle routing of all weapons
---@class ServerWeaponManager
local ServerWeaponManager = {}
ServerWeaponManager.__index = ServerWeaponManager

function ServerWeaponManager.new(config)
    assert(config, "lacking configuration, provide it as the 1st argument")
    assert(config.ProjectileManager, "WeaponManager requires ProjectileManager, provide it in the config table")
    assert(config.GameMode, "WeaponManager requires a gamemode to be specified, provide it in the config table")

    local self = {}

    self.ProjectileManager = config.ProjectileManager
    self.GameMode = config.GameMode
    self.ActiveWeapons = {}

    self.Connections = {}
    self.Connections.Characters = {}

    setmetatable(self, ServerWeaponManager)
    Maid.watch(self)

    self._packetToFunction = {
        [Enums.PacketType.WeaponEquip] = self.equip,
        [Enums.PacketType.WeaponFire] = self.fire,
    }
    return self
end

---
---@param name string Weapon name to create
---@param uuid string UUID given by server
function ServerWeaponManager:create(name, uuid)
    local weapon = ServerGun.new(name, self.GameMode)
    weapon.UUID = uuid or HttpService:GenerateGUID(false)

    return weapon
end

---
---@param weapon ServerGun
---@param uuid string
---@param client Client
function ServerWeaponManager:register(weapon, client)
    self.ActiveWeapons[weapon.UUID] = {Weapon = weapon, Owner = client}

    NetworkLib:send(Enums.PacketType.WeaponRegister, client, weapon.AssetName, weapon.UUID)

    return ServerWeaponManager
end

---
---@param client Client
---@param weaponOrUUID any
function ServerWeaponManager:equip(client, weaponOrUUID)
    local uuid = weaponOrUUID
    if typeof(weaponOrUUID) ~= "string" then
        uuid = weaponOrUUID.UUID
    end
    if not self.ActiveWeapons[uuid] then
        warn("gun UUID " .. uuid .. " is not managed by this ServerWeaponManager")
    end

    NetworkLib:send(Enums.PacketType.WeaponEquip, client, uuid)
end

---
---@param client Client
---@param weaponOrUUID userdata
---@param bulletUUID string
---@param direction userdata
function ServerWeaponManager:fire(client, weaponOrUUID, bulletUUID, direction)
    local uuid = weaponOrUUID
    if typeof(weaponOrUUID) ~= "string" then
        uuid = weaponOrUUID.UUID
    end
    if not self.ActiveWeapons[uuid] then
        warn("gun UUID " .. uuid .. " is not managed by this ServerWeaponManager")
    end

    NetworkLib:send(Enums.packetType.WeaponFire, client, uuid)
    -- TODO: sanity check high RPM
end

---
---@param client Client
---@param uuid string
---@param bulletUUID string
---@param targetPart userdata
---@param position userdata
function ServerWeaponManager:hit(client, uuid, bulletUUID, targetPart, position)
    if not self.ActiveWeapons[uuid] then
        warn("gun UUID " .. uuid .. " is not managed by this ServerWeaponManager")
    end
end

function ServerWeaponManager:route(player, packetType, ...)
    local func = self._packetToFunction[packetType]
    if func then
        func(self, ...)
    end
end

return ServerWeaponManager
