local TableUtil = require(shared.Common.TableUtil)

local enums = {
    {"Safety", "Clicks will not trigger the receiver"},
    {"Single", "Fires the weapon 1 bullet per click"},
    {"Burst", "Fires the weapon until Count is reached (separately defined from Enum)"},
    {"Auto", "Fires the weapon as long as input is held"}
}

return TableUtil.toEnumList(script.Name, enums)