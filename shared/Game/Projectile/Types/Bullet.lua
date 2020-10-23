local GRAVITY_MODIFIER = _G.PROJECTILE.GRAVITY_MODIFIER

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
    self._renderObject = shared.Assets.FX.Bullet.Tracer:Clone()
end

function Bullet:simulate(dt)
    self.Velocity = self.Velocity - Vector3.new(0, (workspace.Gravity * dt * GRAVITY_MODIFIER) / 60, 0)

    local result = workspace:Raycast(self.Position, self.Velocity, params)

    -- continue going
    if not result then
        self.Position = self.Position + self.Velocity
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
    self._renderObject.Parent = _G.Path.Effects
    self._renderObject.CFrame = CFrame.new(self.Position)
end

return Bullet
