local Maid = require(shared.Common.Maid)

---Manages a group of particles in the game
---@class ParticleManager
local ParticleManager = {}
ParticleManager.__index = ParticleManager

---@param settingsControllerPath string Path to a settings controller
function ParticleManager.new(settingsControllerPath)
    local self = {}


    setmetatable(self, ParticleManager)
    Maid.watch(self)
    return self
end