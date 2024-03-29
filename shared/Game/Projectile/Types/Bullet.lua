local GRAVITY_MODIFIER = _G.PROJECTILE.GRAVITY_MODIFIER
local FX_HIT_LIFETIME = 5
local DECAL_HIT_LIFETIME = 30
local MATERIAL_TO_HIT_FX = {
    ["Default"] = shared.Assets.FX.Hit.Bullet.Normal,
    [Enum.Material.CorrodedMetal] = shared.Assets.FX.Hit.Bullet.Metal,
    [Enum.Material.DiamondPlate] = shared.Assets.FX.Hit.Bullet.Metal,
    [Enum.Material.Concrete] = shared.Assets.FX.Hit.Bullet.Concrete,
    [Enum.Material.Granite] = shared.Assets.FX.Hit.Bullet.Concrete,
    [Enum.Material.Brick] = shared.Assets.FX.Hit.Bullet.Concrete,
    [Enum.Material.Cobblestone] = shared.Assets.FX.Hit.Bullet.Concrete,
    [Enum.Material.Metal] = shared.Assets.FX.Hit.Bullet.Metal,
    [Enum.Material.Foil] = shared.Assets.FX.Hit.Bullet.Metal,
    [Enum.Material.ForceField] = shared.Assets.FX.Hit.Bullet.Metal,
    [Enum.Material.Grass] = shared.Assets.FX.Hit.Bullet.Dirt,
    [Enum.Material.Glass] = shared.Assets.FX.Hit.Bullet.Glass,
    [Enum.Material.Ice] = shared.Assets.FX.Hit.Bullet.Glass,
    [Enum.Material.Wood] = shared.Assets.FX.Hit.Bullet.Wood,
    [Enum.Material.Mud] = shared.Assets.FX.Hit.Bullet.Dirt,
    [Enum.Material.Ground] = shared.Assets.FX.Hit.Bullet.Dirt,
    [Enum.Material.Fabric] = shared.Assets.FX.Hit.Bullet.Dirt,
    [Enum.Material.LeafyGrass] = shared.Assets.FX.Hit.Bullet.Dirt
}

local Debris = game:GetService("Debris")

local ParticleManager = _G.Client and require(_G.Client.Render.ParticleManager).new("Particles/BulletHit")

local params = RaycastParams.new()
params.FilterDescendantsInstances = {
    _G.Path.RayIgnore,
    _G.Path.Collisions,
    _G.Path.Players,
    _G.Path.FX,
    workspace.CurrentCamera
}

---@class Bullet
local Bullet = {}

function Bullet:init()
    self._renderObject = shared.Assets.FX.ProjectileTracer.Bullet:Clone()
    self._renderObject.CFrame = CFrame.new(self.Properties.VisualOrigin or self.Origin)
    self._renderObject.Parent = _G.Path.FX
end

function Bullet:simulate(dt)
    self.Velocity = self.Velocity - Vector3.new(0, ((workspace.Gravity) * GRAVITY_MODIFIER) * dt, 0)

    local result = workspace:Raycast(self.Position, self.Velocity, params)

    -- continue going
    if not result then
        self.Position = self.Position + self.Velocity * dt
        return true
    end

    return false, result
end

function Bullet:hitClient(rayResult)
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
    ParticleManager:scheduleDestroy(p, DECAL_HIT_LIFETIME)

    -- dereference renderObject (part which leaves trail) and destroy
    -- it after a fixed time by ourselves (trail disappears with parent...)
    local renderObject = self._renderObject
    self._renderObject = nil

    -- ugly hack with task.delay to show trail (because roblox doesn't allow us to step it ourself)
    task.delay(0, self.hitDeferredRender, self.Position, renderObject)

    -- clean up :D
    Debris:AddItem(renderObject, FX_HIT_LIFETIME)
end

function Bullet:hit(rayResult)
    self.Position = rayResult.Position

    if _G.Client then
        self:hitClient(rayResult)
    end

    return false
end

function Bullet:render()
    self._renderObject.CFrame = CFrame.new(self.Position)
    self._renderObject.Parent = _G.Path.FX
end

function Bullet.hitDeferredRender(pos, renderObject)
    renderObject.CFrame = CFrame.new(pos)
    renderObject.Parent = _G.Path.FX
end

function Bullet.staticStep(dt)
    ParticleManager:step(dt)
end

return Bullet
