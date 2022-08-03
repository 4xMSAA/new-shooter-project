local Timer = require(shared.Common.Timer)

---@param Zombies ZombiesGamemode
return function (Zombies)
    print(#Zombies.ClientManager:getClients())

    local projectileManagerTimer = Timer.new(_G.PROJECTILE.ITERATION_PRECISION)

    return function(dt)
        local projectileTick = projectileManagerTimer:tick(dt)
        if projectileTick then
            Zombies.ProjectileManager:step(projectileTick)
        end
    end
end
