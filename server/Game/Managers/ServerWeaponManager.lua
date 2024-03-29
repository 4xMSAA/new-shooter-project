local HttpService = game:GetService("HttpService")

local Maid = require(shared.Common.Maid)
local log, logwarn = require(shared.Common.Log)(script:GetFullName())

local NetworkLib = require(shared.Common.NetworkLib)
local GameEnum = shared.GameEnum

local ServerGun = require(_G.Server.Game.ServerGun)

local function resolveUUID(weaponOrUUID)
    if typeof(weaponOrUUID) ~= "string" then
        return weaponOrUUID.UUID
    end
    return weaponOrUUID
end
---Server-side weapon manager to handle routing of all weapons
---@class ServerWeaponManager
local ServerWeaponManager = {}
ServerWeaponManager.__index = ServerWeaponManager


---Create a new container that manages weapon instances and their networking
---@param config table A configuration table for different behaviour
---@return ServerWeaponManager A new instance of this manager
function ServerWeaponManager.new(config)
    assert(config, "missing configuration argument, provide it as the 1st argument")
    assert(config.ProjectileManager, "WeaponManager requires ProjectileManager, provide it in the config table")
    assert(config.GameMode, "WeaponManager requires a gamemode to be specified, provide it in the config table")

    local self = {}

    self.ProjectileManager = config.ProjectileManager
    self.GameMode = config.GameMode
    self.ActiveWeapons = {}

    self._Equipped = {}

    setmetatable(self, ServerWeaponManager)
    Maid.watch(self)

    return self
end

---
---@param name string Create a weapon from the asset name provided
function ServerWeaponManager:create(name)
    local weapon = ServerGun.new(name, self.GameMode)

    return weapon
end

---Assigns an UUID and prepares it for networking
---@param weapon ServerGun
---@param client Client The owner of the registered weapon
function ServerWeaponManager:register(weapon, client)
    weapon.UUID = uuid or HttpService:GenerateGUID(false)
    self.ActiveWeapons[weapon.UUID] = {Weapon = weapon, Owner = client}

    NetworkLib:send(GameEnum.PacketType.WeaponRegister, client, weapon.AssetName, weapon.UUID)

    return ServerWeaponManager
end


function ServerWeaponManager:deregisterAllFrom(client)
    for uuid, container in pairs(self.ActiveWeapons) do
        if container.Owner == client then
            container.Weapon:Destroy()
            self.ActiveWeapons[uuid] = nil
            self._Equipped[client] = nil
            NetworkLib:send(GameEnum.PacketType.WeaponDeregister, uuid)
        end
    end
end


function ServerWeaponManager:isOwner(client, weaponOrUUID)
    local uuid = resolveUUID(weaponOrUUID)
    local container = self.ActiveWeapons[uuid]
    assert(container, "gun UUID " .. tostring(uuid) .. " is not managed by this ServerWeaponManager")

    return container.Owner == client
end

---! NETWORKED FUNCTION !
---
---@param client Client
---@param weaponOrUUID any
---@param id number Not relevant to server, but helps with reconciliation for clients
function ServerWeaponManager:clientEquip(client, weaponOrUUID, id)
    local uuid = resolveUUID(weaponOrUUID)
    assert(typeof(id) == "number", "ID sent should be numeric")
    assert(self.ActiveWeapons[uuid], "gun UUID " .. tostring(uuid) .. " is not managed by this ServerWeaponManager")
    assert(self:isOwner(client, uuid), " client sent UUID for weapon not owned by them")

    self._Equipped[client] = uuid

    NetworkLib:send(GameEnum.PacketType.WeaponEquip, client, uuid, id)
end

---! NETWORKED FUNCTION !
---
---@param client Client
---@param weaponOrUUID any
function ServerWeaponManager:clientFire(client, weaponOrUUID, state)
    local uuid = resolveUUID(weaponOrUUID)
    assert(typeof(state) == "boolean", client.Name .. " - client is sending bad args for clientFire() (#3)")
    assert(self.ActiveWeapons[uuid], "gun UUID " .. tostring(uuid) .. " is not managed by this ServerWeaponManager")
    assert(self:isOwner(client, uuid), " client sent UUID for weapon not owned by them")

    NetworkLib:sendToExcept(client, GameEnum.PacketType.WeaponFire, uuid, state)
    -- TODO: sanity check high RPM
end

---! NETWORKED FUNCTION !
function ServerWeaponManager:clientReload(client, weaponOrUUID)
    local uuid = resolveUUID(weaponOrUUID)
    assert(self.ActiveWeapons[uuid], "gun UUID " .. uuid .. " is not managed by this ServerWeaponManager")
    assert(self:isOwner(client, uuid), " client sent UUID for weapon not owned by them")

    NetworkLib:sendToExcept(client, GameEnum.PacketType.WeaponReload, uuid)
end

--! NETWORKED FUNCTION !
function ServerWeaponManager:clientCancelReload(client, weaponOrUUID)
    local uuid = resolveUUID(weaponOrUUID)
    assert(self.ActiveWeapons[uuid], "gun UUID " .. uuid .. " is not managed by this ServerWeaponManager")
    assert(self:isOwner(client, uuid), " client sent UUID for weapon not owned by them")

    NetworkLib:sendToExcept(client, GameEnum.PacketType.WeaponCancelReload, uuid)
end

---! NETWORKED FUNCTION !
---
---@param client Client
---@param uuid string
---@param bulletUUID string
---@param targetPart userdata
---@param position userdata
function ServerWeaponManager:clientProjectileHit(client, uuid, bulletUUID, targetPart, position)
    assert(self.ActiveWeapons[uuid], "gun UUID " .. uuid .. " is not managed by this ServerWeaponManager")
    assert(self:isOwner(client, uuid), " client sent UUID for weapon not owned by them")
end

---! NETWORKED FUNCTION !
---
---@param client Client
---@param uuid string
---@param projectileBatch any
function ServerWeaponManager:clientProjectileMake(client, uuid, projectileBatch)
    assert(self.ActiveWeapons[uuid], "gun UUID " .. uuid .. " is not managed by this ServerWeaponManager")
    assert(self:isOwner(client, uuid), " client sent UUID for weapon not owned by them")

    local gun = self.ActiveWeapons[uuid].Weapon
    for _, projectile in pairs(projectileBatch) do
        self.ProjectileManager:create(gun, projectile.Origin, projectile.Direction)
    end
    -- TODO: sanity check high RPM

    NetworkLib:sendToExcept(client, GameEnum.PacketType.ProjectileMake, uuid, projectileBatch)
end

---Tell an ad-hoc client about the weapons that already exist before them
---@param client Client
function ServerWeaponManager:adhocUpdate(client)
    local serializedAdhocWeapons = {}
    for uuid, container in pairs(self.ActiveWeapons) do
        table.insert(serializedAdhocWeapons, {UUID = uuid, AssetName = container.Weapon.AssetName, Owner = container.Owner:serialize()})
    end

    NetworkLib:sendTo(client, GameEnum.PacketType.WeaponAdhocRegister, serializedAdhocWeapons)
    for owner, uuid in pairs(self._Equipped) do
        NetworkLib:sendTo(client, GameEnum.PacketType.WeaponEquip, owner, uuid)
    end

   log(1, "Sending ad-hoc updates to", client.Name, "- weapons:", serializedAdhocWeapons, "- equipped:", self._Equipped)
end

function ServerWeaponManager:route(packetType, player, ...)
    local func = self._packetToFunction[packetType]
    if func then
        func(self, player, ...)
    end
end


-- !IMPORTANT
-- !Any function here will allow itself to have data sent to by clients.
-- !Sanitize it.
ServerWeaponManager._packetToFunction = {
    [GameEnum.PacketType.WeaponEquip] = ServerWeaponManager.clientEquip,
    [GameEnum.PacketType.WeaponFire] = ServerWeaponManager.clientFire,
    [GameEnum.PacketType.ProjectileHit] = ServerWeaponManager.clientProjectileHit,
    [GameEnum.PacketType.WeaponReload] = ServerWeaponManager.clientReload,
    [GameEnum.PacketType.WeaponCancelReload] = ServerWeaponManager.clientCancelReload,
    [GameEnum.PacketType.ProjectileMake] = ServerWeaponManager.clientProjectileMake,
}

return ServerWeaponManager
