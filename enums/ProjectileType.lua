local TableUtils = require(shared.Common.TableUtils)

---@class ProjectileType
local Enums = {
    {"Bullet", ""},
    {"Launcher", ""},
}

return TableUtils.toEnumList(script.Parent.Name, Enums)