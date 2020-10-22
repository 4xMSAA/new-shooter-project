local TableUtils = require(shared.Common.TableUtils)

---@class Priority
local Enums = {
    {"Critical", ""},
    {"Important", ""},
    {"Normal", ""},
    {"Unimportant", ""},
    {"Last", ""},
}

return TableUtils.toEnumList(script.Parent.Name, Enums)