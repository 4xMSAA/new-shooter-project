local Maid = require(shared.Common.Maid)

local Projectile = require(shared.Game.Projectile)

---A class description
---@class ProjectileManager
local ProjectileManager = {}
ProjectileManager.__index = ProjectileManager

function ProjectileManager.new()
    local self = {}


    setmetatable(self, ProjectileManager)
    Maid.watch(self)
    return self
end

---
---@param gun Gun Configuration to read and use to create a projectile from
---@param start userdata A vector of the start position
---@param direction userdata A vector of the direction
---@param networked boolean If the projectile is networked, do not do hitscan
function ProjectileManager:create(gun, start, direction, networked)
    assert(typeof(gun) == "table", "expected Gun object, got " .. typeof(gun) .. " (arg #1)")
    assert(gun.Configuration, "gun does not own a Configuration table, see: " .. tostring(gun))

    local cfg = gun.Configuration
    assert(cfg.Projectile, "gun " .. cfg.Name .. " does not have Projectile configuration")

    for index = 1, cfg.Projectile.Amount do
        Projectile.new()
    end

end