local TableUtils = require(shared.Common.TableUtils)

---@class ProjectileType
local GameEnum = {
    {"Bullet", ""},
    {"Launcher", ""},
}

return TableUtils.toEnumList(script.Parent.Name, GameEnum)