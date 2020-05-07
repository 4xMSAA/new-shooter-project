local TableUtil = require(shared.Common.TableUtil)

local Enums = {
    {"Bullet", ""},
    {"Launcher", ""},
}

return TableUtil.toEnumList(script.Parent.Name, Enums)