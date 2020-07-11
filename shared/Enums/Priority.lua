local TableUtil = require(shared.Common.TableUtil)

---@class Priority
local Enums = {
    {"Critical", ""},
    {"Important", ""},
    {"Normal", ""},
    {"Unimportant", ""},
    {"Last", ""},
}

return TableUtil.toEnumList(script.Parent.Name, Enums)