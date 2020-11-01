local Maid = require(shared.Common.Maid)
local Particle = require(shared.Common.Particle)

---Manages a group of particles in the game
---@class ParticleManager
local ParticleManager = {}
ParticleManager.__index = ParticleManager

---@param settingsControllerPath string Path to a settings controller
function ParticleManager.new(settingsControllerPath)
    local self = {
        _IDCounter = 0,
        Particles = {}
    }

    setmetatable(self, ParticleManager)
    Maid.watch(self)
    return self
end

function ParticleManager:create(effectPath, parent)
    self._IDCounter = self._IDCounter + 1

end