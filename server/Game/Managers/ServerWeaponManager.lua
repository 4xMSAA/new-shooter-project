local Maid = require(shared.Common.Maid)

local NetworkLib = require(shared.Common.NetworkLib)
local Enums = shared.Enums


local ServerGun = require(script.ServerGun)

---Server-side weapon manager to handle routing of all weapons
---@class ServerWeaponManager
local ServerWeaponManager = {}
ServerWeaponManager.__index = ServerWeaponManager

function ServerWeaponManager.new(config)
    local self = {}

    self.ProjectileManager = config.ProjectileManager
    self.GameMode = config.GameMode
    self.ActiveWeapons = {}

    self.Connections = {}
    self.Connections.Characters = {}

    setmetatable(self, ServerWeaponManager)
    Maid.watch(self)
    return self
end

---
---@param name string Weapon name to create
---@param uuid string UUID given by server
function ServerWeaponManager:create(name, uuid)
    local gun = ServerGun.new(name, self.GameMode)
    gun.UUID = uuid

    return gun
end

---
---@param weapon ServerGun
---@param uuid string
---@param client Client
function ServerWeaponManager:register(weapon, uuid, client)
    self.ActiveWeapons[uuid] = {Weapon = weapon, Owner = client}
    weapon.UUID = uuid

    NetworkLib:send(Enums.PacketType.WeaponRegister, weapon.AssetName, weapon.UUID)

    return ServerWeaponManager
end

function ServerWeaponManager:equip(client, weaponOrUUID)
    local uuid = weaponOrUUID
    if typeof(weaponOrUUID) ~= "string" then
        uuid = weaponOrUUID.UUID
    end

    NetworkLib:send(Enums.packetType.WeaponEquip, client, uuid)
end

---
---@param client Client
---@param gunUUID string
---@param bulletUUID string
---@param direction userdata
function ServerWeaponManager:fire(client, gunUUID, bulletUUID, direction)
    if self.ActiveWeapons[gunUUID] then error("client's gun UUID is not managed by this ServerWeaponManager", 2) end

    -- TODO: sanity check high RPM
end

---
---@param client Client
---@param gunUUID string
---@param bulletUUID string
---@param targetPart userdata
---@param position userdata
function ServerWeaponManager:hit(client, gunUUID, bulletUUID, targetPart, position)
    if self.ActiveWeapons[gunUUID] then error("client's gun UUID is not managed by this ServerWeaponManager", 2) end
end
