local Maid = require(shared.Common.Maid)

local ITERATION_PRECISION = _G.PROJECTILE.ITERATION_PRECISION
local MAX_ITERATIONS_PER_FRAME = _G.PROJECTILE.MAX_ITERATIONS_PER_FRAME

local projectileTypes = {}

for _, module in pairs(script.Types:GetChildren()) do
    local projectileType = require(module)
    projectileTypes[module.Name] = projectileType
end

---A projectile with different properties
---@class Projectile
local Projectile = {}
Projectile.__index = Projectile

function Projectile.new(projectileType, props, start, direction)
    assert(projectileTypes[projectileType])
    local self = {}

    self.Type = projectileTypes[projectileType]
    self.Lifetime = 0

    self.Origin = start
    self.Position = start

    self.Direction = direction
    self.Velocity = self.Direction * props.Velocity
    self.props = props

    setmetatable(self, {
        __index = function(self, index)
            return rawget(self.Type, index) or rawget(Projectile, index)
        end
    })
    Maid.watch(self)
    self:init()
    return self
end

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
            if not self:hit(self, rayResult) then
                return false, rayResult
            end
        end
        if not keepSimulating then
            return false, rayResult
        end
    end
    return true
end

return Projectile