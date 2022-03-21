local Timer = require(shared.Common.Timer)

---@param Zombies ZombiesGamemode
return function (Zombies)
    print(#Zombies.ClientManager:getClients())

    return function()
    end
end