local GRAVITY_MODIFIER = _G.PROJECTILE.GRAVITY_MODIFIER

local Enums = shared.Enums

---@class Bullet
local Bullet = {}

function Bullet:init()
    self._renderObject = shared.Assets.FX.Bullet.Tracer:Clone()
end

function Bullet:destroy()
    self._renderObject:Destroy()
end

function Bullet:step(dt)
    self.Velocity = self.Velocity - Vector3.new(0, workspace.Gravity*dt*GRAVITY_MODIFIER, 0)

    local params = RaycastParams.new()
    local result = workspace:Raycast(self.Position, self.Velocity, params)

    -- continue going
    if not result.Instance then
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
end