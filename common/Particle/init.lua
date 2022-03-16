local Maid = require(shared.Common.Maid)
local Behaviours = require(script.Behaviours)

---
---@class Particle
local Particle = {}
Particle.__index = Particle
Particle._behaviours = Behaviours

---@param effect userdata
---@param parent userdata Where to parent the Particle instances to
function Particle.new(effect, parent, props, _noClone)
    assert(effect, "effect cannot be nil (must be an Instance)")

    local self = {
        Parent = parent,
        Instances = not _noClone and effect:Clone():GetChildren() or parent:GetChildren(),
        Name = effect:GetFullName(),
        Configuration = require(
            assert(effect:WaitForChild("Configuration"), "no configuration for particle " .. effect:GetFullName())
        ),
        Properties = props
    }

    setmetatable(self, Particle)
    self:_init()
    Maid.watch(self)

    return self
end

function Particle.fromExisting(effect, parent, props)
    Particle.new(effect, parent, props, clone)
end

function Particle:_init()
    if not self.Parent:IsA("Part") then
        self._attachment = Instance.new("Attachment")
        self._attachment.Parent = self.Parent
    else
        self._attachment = self.Parent
    end

    for _, instance in pairs(self.Instances) do
        if self.Configuration.Colorable and self.Configuration.Colorable[inst.Name] then
            inst.Color = self.Configuration.Colorable[inst.Name].new(self.Properties.Color)
        end

        if instance:IsA("Light") or instance:IsA("ParticleEmitter") then
            instance.Enabled = false
        end

        instance.Parent = self._attachment
    end
end

function Particle:emit()
    for _, child in pairs(self.Instances) do
        if Particle._behaviours[child.ClassName] then
            Particle._behaviours[child.ClassName](child, self.Configuration, self.Properties)
        end
    end

    if self.Configuration.RandomSingleSound then
        local sounds = {}
        for _, sound in pairs(self.Instances) do
            if sound:IsA("Sound") then
                table.insert(sounds, sound)
            end
        end

        if #sounds > 0 then
            sounds[math.random(#sounds)]:Play()
        else
            warn("no sound instances for particle " .. self.Name)
        end
    end
end

return Particle
