local GRAVITY_MODIFIER = _G.PROJECTILE.GRAVITY_MODIFIER

local MATERIAL_TO_HIT_FX = {
    ["Default"] = shared.Assets.FX.Hit.Bullet.Normal,
    [Enum.Material.CorrodedMetal] = shared.Assets.FX.Hit.Bullet.Metal,
    [Enum.Material.DiamondPlate] = shared.Assets.FX.Hit.Bullet.Metal,
    [Enum.Material.Metal] = shared.Assets.FX.Hit.Bullet.Metal,
    [Enum.Material.Foil] = shared.Assets.FX.Hit.Bullet.Metal,
    [Enum.Material.ForceField] = shared.Assets.FX.Hit.Bullet.Metal,
    [Enum.Material.Grass] = shared.Assets.FX.Hit.Bullet.Dirt,
    [Enum.Material.Mud] = shared.Assets.FX.Hit.Bullet.Dirt,
    [Enum.Material.Ground] = shared.Assets.FX.Hit.Bullet.Dirt,
    [Enum.Material.Fabric] = shared.Assets.FX.Hit.Bullet.Dirt,
    [Enum.Material.LeafyGrass] = shared.Assets.FX.Hit.Bullet.Dirt,
}

local Enums = shared.Enums

local params = RaycastParams.new()
params.FilterDescendantsInstances = {
    workspace.GameFolder.RayIgnore,
    workspace.GameFolder.Collisions,
    workspace.GameFolder.Players,
    workspace.CurrentCamera
}

---@class Bullet
local Bullet = {}

function Bullet:init()
    self._renderObject = shared.Assets.FX.ProjectileTracer.Bullet:Clone()
end

function Bullet:simulate(dt)
    self.Velocity = self.Velocity - Vector3.new(0, ((workspace.Gravity) * GRAVITY_MODIFIER), 0)

    local result = workspace:Raycast(self.Position, self.Velocity, params)

    -- continue going
    if not result then
        self.Position = self.Position + self.Velocity*dt
        return true
    end

    return false, result
end

function Bullet:hit(rayResult)
    -- decision logic per material and stuff

    self.Position = rayResult.Position

    return false
end

function Bullet:render()
    self._renderObject.CFrame = CFrame.new(self.Position)
    self._renderObject.Parent = _G.Path.Effects
end

return Bullet
