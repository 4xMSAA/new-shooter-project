local TableUtil = require(shared.Common.TableUtil)

---@class GunActionType
local enums = {
    {"ClosedBolt", "Automatic weapon cycling for next round with closed bolt chambering (default)"},
    {"OpenBolt", "Automatic weapon cycling for next round, but cannot chamber an extra round"},
    {"SingleAction", "Revolver style with delayed firing due to manual hammer actuation"},
    {"DoubleAction", "Revolver style with automatic hammer actuation"},
    {"BreakAction", "Weapon reloads by opening the chamber fixated on a hinge"},
    {"BoltAction", "Weapon must cycle the bolt each fire"}
}

return TableUtil.toEnumList(script.Name, enums)
