local VELOCITY_MODIFIER = _G.PROJECTILE.VELOCITY_MODIFIER

local Maid = require(shared.Common.Maid)

local Projectile = require(shared.Game.Projectile)

---A class description
---@class ProjectileManager
local ProjectileManager = {}
ProjectileManager.__index = ProjectileManager

function ProjectileManager.new()
    local self = {
        Projectiles = {}
    }

    setmetatable(self, ProjectileManager)
    Maid.watch(self)
    return self
end

---
---@param config userdata
---@param direction userdata
function ProjectileManager:makeProperties(config, direction)
    return {
        -- velocity units are provided in metres per second
        Velocity = config.Velocity * VELOCITY_MODIFIER
    }
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
        local proj =
            Projectile.new(cfg.Projectile.Type, self:makeProperties(cfg.Projectile, direction), start, direction)
        self.Projectiles[proj] = true
    end
end


function ProjectileManager:discard(projectile)
    projectile:destroy()
    self.Projectiles[projectile] = nil
end

---
---@param dt number Delta time since last update
function ProjectileManager:step(dt)
    for proj, _ in pairs(self.Projectiles) do
        local keepSimulating = proj:step(dt)
        proj:render()
        if not keepSimulating or proj.Lifetime > 5 then
            self:discard(proj)
        end
    end
end

return ProjectileManager
