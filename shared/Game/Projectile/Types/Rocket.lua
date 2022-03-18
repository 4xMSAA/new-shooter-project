local GRAVITY_MODIFIER = _G.PROJECTILE.GRAVITY_MODIFIER
local ROCKET_GRAVITY_MODIFIER = 1 -- rockets are unguided but... they are still propulsion
local FX_HIT_LIFETIME = 5
local MATERIAL_TO_HIT_FX = {
    ["Default"] = shared.Assets.FX.Hit.Rocket.Normal,
}

local Debris = game:GetService("Debris")

local ParticleManager = _G.Client and require(_G.Client.Render.ParticleManager).new("Particles/ExplosionHit")

local params = RaycastParams.new()
params.FilterDescendantsInstances = {
    _G.Path.RayIgnore,
    _G.Path.Collisions,
    _G.Path.Players,
    _G.Path.FX,
    workspace.CurrentCamera
}

---@class Rocket
local Rocket = {}

function Rocket:init()
    self._renderObject = shared.Assets.FX.ProjectileTracer.Rocket:Clone()
end

function Rocket:simulate(dt)
    self.Velocity = self.Velocity - Vector3.new(0, ((workspace.Gravity) * GRAVITY_MODIFIER * ROCKET_GRAVITY_MODIFIER) * dt, 0)

    local result = workspace:Raycast(self.Position, self.Velocity * dt, params)

    -- continue going
    if not result then
        self.Position = self.Position + (self.Velocity * dt)
        return true
    end

    return false, result
end

function Rocket:hitClient(rayResult)
    local materialEffect = MATERIAL_TO_HIT_FX[rayResult.Material] or MATERIAL_TO_HIT_FX["Default"]
    local cf =
        CFrame.lookAt(
            rayResult.Position,
            rayResult.Position + rayResult.Normal,
            rayResult.Instance and rayResult.Instance.CFrame.UpVector or Vector3.new(0, 1, 0)
        ) *
        CFrame.Angles(-math.pi / 2, 0, 0) *
        CFrame.Angles(0, math.random()*math.pi*2, 0)

    local p = ParticleManager:createDecal(materialEffect, {CFrame = cf}, {Color = rayResult.Instance.Color})
    p:emit()
    ParticleManager:scheduleDestroy(p, FX_HIT_LIFETIME)

    self:render() -- one final time to update position

    -- dereference renderObject (part which leaves trail) and destroy 
    -- it after a fixed time by ourselves (trail disappears with parent...)
    local renderObject = self._renderObject
    self._renderObject = nil

    renderObject.Transparency = 1

    -- disable all particles
    for _, particle in pairs(renderObject:GetDescendants()) do
        if particle:IsA("ParticleEmitter") then
            particle.Enabled = false
        end
    end
    
    Debris:AddItem(renderObject, FX_HIT_LIFETIME)
end

function Rocket:hit(rayResult)
    self.Position = rayResult.Position

    if _G.Client then
        self:hitClient(rayResult)
    end

    return false
end

function Rocket:render()

    self._renderObject.CFrame = CFrame.lookAt(self.Position, self.Position + self.Velocity, Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, os.clock()*2)
    self._renderObject.Parent = _G.Path.FX
end

function Rocket.staticStep(dt)
    ParticleManager:step(dt)
end

return Rocket
