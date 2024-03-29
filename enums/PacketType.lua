local TableUtils = require(shared.Common.TableUtils)

---@class PacketType
local GameEnum = {
    {"Ready", "Ready signals to send between client and server"},
    {"GameInfo", "Data about the game's settings"},
    {"AdhocClient", "Send an ad-hoc client information about the game state that it isn't aware of"},

    {"PlayerSpawn", "Send player spawn information"}, -- TODO: merge with EntityMake?
    {"EntityMake", "Send entity spawn information"},
    {"EntityUpdate", "Send entity update information"},

    {"WeaponAdhocRegister", "Send ad-hoc clients information regarding registered weapons"},
    {"WeaponRegister", "Register a weapon"},
    {"WeaponUnregister", "Remove a weapon"},
    {"WeaponState", "Change the state of a weapon"},
    {"WeaponFire", "Fire the weapon"},
    {"WeaponEquip", "Equip the weapon"},
    {"WeaponReload", "Reload a weapon"},
    {"WeaponCancelReload", "Cancels the reload on a weapon"},

    {"ProjectileMake", "Client casts a projectile in a direction"}, -- SANITIZE ON SERVER!
    {"ProjectileHit", "Client informs the projectile has hit something"}, -- SANITIZE ON SERVER!

    {"Look", "Send pitch, yaw angles for player replication"},
    {"Run", "Send run state for player replication"},
    {"Stance", "Send stance state for player replication"},
}

return TableUtils.toEnumList(script.Parent.Name, GameEnum)
