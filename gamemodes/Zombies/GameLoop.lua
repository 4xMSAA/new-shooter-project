---@param Zombies ZombiesGamemode
return function (Zombies)
    print(#Zombies.ClientManager:getClients())

    return function()
    end
end