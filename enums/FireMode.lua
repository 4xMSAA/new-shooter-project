local TableUtils = require(shared.Common.TableUtils)

---@class FireMode
local enums = {
    {"Safety", "Clicks will not trigger the receiver"},
    {"Single", "Fires the weapon 1 bullet per click"},
    {"Burst", "Fires the weapon until Count is reached (separately defined from Enum)"},
    {"Automatic", "Fires the weapon as long as input is held"},
}

return TableUtils.toEnumList(script.Name, enums)