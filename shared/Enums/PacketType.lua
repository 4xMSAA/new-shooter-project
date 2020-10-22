local TableUtils = require(shared.Common.TableUtils)

---@class PacketType
local Enums = {
    {"Ready", "Ready signals to send between client and server"},
    {"GameInfo", "Data about the game's settings"},
    {"PlayerSpawn", "Send player spawn information"},

    {"EntitySpawn", "Send entity spawn information"},
    {"EntityUpdate", "Send entity update information"},

    {"WeaponRegister", "Register a weapon"},
    {"WeaponState", "Change the state of a weapon"},
    {"WeaponEquip", "Equip the weapon"},

    {"Look", "Send pitch, yaw angles for player replication"},
    {"Run", "Send run state for player replication"},
    {"Stance", "Send stance state for player replication"},
}

return TableUtils.toEnumList(script.Parent.Name, Enums)