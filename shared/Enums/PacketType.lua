local TableUtil = require(shared.Common.TableUtil)

local Enums = {
    {"Ready", "Ready signals to send between client and server"},
    {"Spawn", "Send spawn information"},

    {"Look", "Send pitch, yaw angles for player replication"},
    {"Run", "Send run state for player replication"},
    {"Stannce", "Send stance state for player replication"},
}

return TableUtil.toEnumList(script.Parent.Name, Enums)