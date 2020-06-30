local GRAVITY_MODIFIER = _G.PROJECTILE.GRAVITY_MODIFIER

local Enums = shared.Enums

---@class Bullet
local Bullet = {}

function Bullet.step(projectile, dt)
    projectile.Velocity = projectile.Velocity - Vector3.new(0, workspace.Gravity*dt*GRAVITY_MODIFIER, 0)

    local params = RaycastParams.new()
    local result = workspace:Raycast(projectile.Position, projectile.Velocity, params)

    -- continue going
    if not result.Instance then
        return true
    end

    return false, result

end

function Bullet.hit(projectile)

    -- decision logic per material and stuff

    return Enums.ProjectileHitResponse.Stop
end