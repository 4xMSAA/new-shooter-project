local Maid = require(shared.Common.Maid)
local Behaviours = require(script.Behaviours)

---
---@class Particle
local Particle = {}
Particle.__index = Particle
Particle._behaviours = Behaviours

---@param effect userdata
---@param parent userdata Where to parent the Particle instances to
function Particle.new(effect, parent)
    local self = {
        Parent = parent,
        Instances = assert(effect, "effect cannot be nil (got " .. tostring(effect) .. ")"):Clone():GetChildren(),
        Configuration = require(
            assert(effect:WaitForChild("Configuration"), "no configuration for particle " .. effect:GetFullName())
        )
    }

    setmetatable(self, Particle)
    self:_init()
    Maid.watch(self)

    return self
end

function Particle:_init()
    if not self.Parent:IsA("Part") then
        self._attachment = Instance.new("Attachment")
        self._attachment.Parent = self.Parent
    else
        self._attachment = self.Parent
    end
    for index, instance in pairs(self.Instances) do
        -- get rid of configuration script in the cloned instance
        if instance:IsA("Script") or instance:IsA("ModuleScript") then
            table.remove(self.Instances, index)
        else
            if instance:IsA("Light") or instance:IsA("ParticleEmitter") then
                instance.Enabled = false
            end
            instance.Parent = self._attachment
        end
    end
end

-- TODO: Control for ParticleManager
function Particle:update()
    -- TODO: Make particles respect their SettingsController
end

function Particle:emit()
    for _, child in pairs(self.Instances) do
        if Particle._behaviours[child.ClassName] then
            Particle._behaviours[child.ClassName](child, self.Configuration)
        end
    end
end

return Particle