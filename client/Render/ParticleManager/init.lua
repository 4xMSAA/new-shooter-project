local Maid = require(shared.Common.Maid)
local Particle = require(shared.Common.Particle)

---Manages a group of particles in the game
---@class ParticleManager
local ParticleManager = {}
ParticleManager.__index = ParticleManager

---@param controllerPath string Path to a respective settings controller
---that enables/disables an effect's appearance
function ParticleManager.new(controllerPath)
    local self = {
        _Controller = controllerPath,
        _IDCounter = 0,
        Particles = {}
    }

    setmetatable(self, ParticleManager)
    Maid.watch(self)
    return self
end

function ParticleManager:create(effect, parent, props)
    self._IDCounter = (self._IDCounter % 2 ^ 16) + 1
    local p = Particle.new(effect, parent, props)

    self.Particles[self._IDCounter] = p

    return p
end

function ParticleManager:createDecal(effect, partProps, props)
    local part = effect:Clone()
    part:ClearAllChildren()
    local particle = self:create(effect, part, props)

    for prop, val in pairs(partProps) do
        part[prop] = val
    end
    particle._linkedPart = part
    part.Parent = _G.Path.FX

    return particle
end

function ParticleManager:scheduleDestroy(particle, seconds)
    -- TODO: use some actual scheduling not a coroutine every time
    coroutine.wrap(
        function()
            wait(seconds)
            particle:destroy()
        end
    )()
end

return ParticleManager
