local TableUtils = require(shared.Common.TableUtils)

---@class BindAction
local GameEnum = {
    {"Primary", "Primary slot"},
    {"Secondary", "Secondary slot"},
    {"Tertiary", "Tertiary slot"},
    {"Melee", "Melee slot"},
    {"Throwable", "Throwable slot"}
    {"UtilityThrowable", "Utility throwable slot"}
}

return TableUtils.toEnumList(script.Parent.Name, GameEnum)
