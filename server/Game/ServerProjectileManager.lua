local VELOCITY_MODIFIER = _G.PROJECTILE.VELOCITY_MODIFIER

local GameEnum = shared.GameEnum
local Maid = require(shared.Common.Maid)
local NetworkLib = require(shared.Common.NetworkLib)

local Projectile = require(shared.Game.Projectile)

---A class description
---@class ServerProjectileManager
local ServerProjectileManager = {}
ServerProjectileManager.__index = ServerProjectileManager

function ServerProjectileManager.new()
    local self = {
        Projectiles = {}
    }

    setmetatable(self, ServerProjectileManager)
    Maid.watch(self)
    return self
end

---
---@param config userdata
function ServerProjectileManager:_makeProperties(config)
    return {
        -- velocity units are provided in metres per second
        Velocity = config.Velocity * VELOCITY_MODIFIER
    }
end

---
---@param gun Gun Configuration to read and use to create a projectile from
---@param origin userdata A vector of the origin position
---@param direction userdata A vector of the direction
function ServerProjectileManager:create(gun, origin, direction)
    assert(typeof(gun) == "table", "expected Gun object, got " .. typeof(gun) .. " (arg #1)")
    assert(gun.Configuration, "gun does not own a Configuration table, see: " .. tostring(gun))

    local cfg = gun.Configuration
    print(gun.Configuration)
    assert(cfg.Projectile, "gun " .. cfg.Name .. " does not have Projectile configuration")

    for index = 1, cfg.Projectile.Amount do
        local proj =
            Projectile.new(cfg.Projectile.Type, self:_makeProperties(cfg.Projectile), origin, direction)
        self.Projectiles[proj] = true
        self:render()
    end

end

function ServerProjectileManager:discard(projectile)
    projectile:destroy()
    self.Projectiles[projectile] = nil
end

local typesWithStep = {}
for _, projectileType in pairs(Projectile.ProjectileTypes) do
    if projectileType["staticStep"] then
        table.insert(typesWithStep, projectileType)
    end
end

---
---@param dt number Delta time since last update
function ServerProjectileManager:step(dt)
    for _, projectileType in pairs(typesWithStep) do
        projectileType.staticStep(dt)
    end

    for proj, _ in pairs(self.Projectiles) do
        local keepSimulating = proj:step(dt)
        if
            not keepSimulating
            or proj.Lifetime > proj.MaxLifetime
        then
            self:discard(proj)
        end
        -- we need to know people are playing fair - especially when
        -- they have removed parts on their side...
        -- may get tricky with moving parts in a map
    end
end


return ServerProjectileManager
