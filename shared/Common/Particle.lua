---
---@class Particle
local Particle = {}
Particle.__index = Particle

Particle._behaviours = {
    ParticleEmitter = function(inst, config)
        inst:Emit(config[inst.Name].Amount)
    end,
    PointLight = function(inst, config)
        local light = inst:Clone()
        light.Enabled = true
    end
}

function Particle.new(effect,  parent)
    local self = {
        Parent = parent,
        Instance = assert(effect, "effect cannot be nil (got " .. effect .. ")"):Clone(),

        Configuration = assert(effect:WaitForChild("Configuration"), "no configuration for particle " .. effect:GetFullName())
    }

    setmetatable(self, Particle)
    return self
end

function Particle:_init()
    self._attachment = Instance.new("Attachment")

end

function Particle:emit()
    for _, child in pairs(self.Instance:GetChildren()) do

    end
end