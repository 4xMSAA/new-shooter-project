local TableUtils = require(shared.Common.TableUtils)

---@class ProjectileHitResponse
local Enums = {
    {"Stop", "Default behaviour. Stops further simulation for the projectile"},
    {"Continue", "Projectile can continue simulating"}
}

return TableUtils.toEnumList(script.Parent.Name, Enums)