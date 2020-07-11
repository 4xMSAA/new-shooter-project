local TableUtil = require(shared.Common.TableUtil)

---@class ProjectileType
local Enums = {
    {"Bullet", ""},
    {"Launcher", ""},
}

return TableUtil.toEnumList(script.Parent.Name, Enums)