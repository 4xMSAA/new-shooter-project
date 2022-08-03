local Maid = require(shared.Common.Maid)

local ITERATION_PRECISION = _G.PROJECTILE.ITERATION_PRECISION
local MAX_ITERATIONS_PER_FRAME = _G.PROJECTILE.MAX_ITERATIONS_PER_FRAME
local DEFAULT_MAX_LIFETIME = _G.PROJECTILE.DEFAULT_MAX_LIFETIME


---A projectile with different properties
---@class Projectile
local Projectile = {
    ProjectileTypes = {}
}

for _, module in pairs(script.Types:GetChildren()) do
    local projectileType = require(module)
    Projectile.ProjectileTypes[module.Name] = projectileType
end

function Projectile.new(projectileType, props, origin, direction)
    assert(Projectile.ProjectileTypes[projectileType], "projectile type not found: got " .. tostring(projectileType))
    assert(typeof(props) == "table", "argument #2 (properties) must be a table")
    local self = {}

    self.UUID = props.UUID
    self.Type = Projectile.ProjectileTypes[projectileType]
    self._TypeName = projectileType
    self.Lifetime = 0
    self.MaxLifetime = props.MaxLifetime or DEFAULT_MAX_LIFETIME

    self.Origin = origin
    self.Position = origin

    self.Direction = direction
    self.Velocity = self.Direction * props.Velocity
    self.Properties = props

    setmetatable(self, {
        __index = function(this, index)
            return rawget(self.Type, index) or rawget(Projectile, index)
        end
    })

    Maid.watch(self)
    self:init()

    return self
end

---A super function to handle the simulation of all inherited projectile classes
---@param frameDelta number
function Projectile:step(frameDelta)
    -- see how many iterations we should do in case of frame lag to still
    -- do a precise simulation
    local iterations = math.floor(frameDelta / ITERATION_PRECISION)
    local dt = frameDelta - iterations * ITERATION_PRECISION

    -- add to projectile lifetime each frame
    self.Lifetime = self.Lifetime + frameDelta

    -- a for loop still runs even if the target is equal to the starting number
    for iteration = 0, iterations do
        if iteration > MAX_ITERATIONS_PER_FRAME then
            break
        end

        local iterationDelta = iteration == iterations and dt or ITERATION_PRECISION

        -- if this returns true, simulation had no issues, if false, it returns
        -- the RaycastResult object as the 2nd argument
        -- https://developer.roblox.com/en-us/api-reference/function/WorldRoot/Raycast
        local keepSimulating, rayResult = self:simulate(iterationDelta)

        if rayResult then
            if not self:hit(rayResult) then
                return false, rayResult
            end
        end
        if not keepSimulating then
            return false, rayResult
        end
    end
    return true
end

---A super function to serialize the needed properties for networking
---@return table serializedProjectile A table of properties to create a
---                                   projectile on another machine
function Projectile:serialize()
    return {
        UUID = self.UUID,
        Direction = self.Direction,
        Origin = self.Origin,
    }
end


return Projectile
