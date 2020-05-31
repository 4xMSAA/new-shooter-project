local TableUtil = require(shared.Common.TableUtil)

local Enums = {
    {"Ready", "Ready signals to send between client and server"},
    {"Spawn", "Send spawn information"},

    {"WeaponRegister", "Register a weapon"},
    {"WeaponState", "Change the state of a weapon"},
    {"WeaponEquip", "Equip the weapon"},

    {"Look", "Send pitch, yaw angles for player replication"},
    {"Run", "Send run state for player replication"},
    {"Stance", "Send stance state for player replication"},
}

return TableUtil.toEnumList(script.Parent.Name, Enums)