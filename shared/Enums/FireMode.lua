local TableUtil = require(shared.Common.TableUtil)

local enums = {
    {"Safety", "Clicks will not trigger the receiver"},
    {"SemiAutomatic", "Fires the weapon 1 bullet per click"},
    {"Burst", "Fires the weapon until Count is reached (separately defined from Enum)"},
    {"Automatic", "Fires the weapon as long as input is held"},
    {"BreakAction", "Weapon reloads by opening the chamber fixated on a hinge"},
    {"BoltAction", "Weapon must cycle the bolt each fire"},
}

return TableUtil.toEnumList(script.Name, enums)