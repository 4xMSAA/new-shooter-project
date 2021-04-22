_G.Server = script.Parent

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Source:WaitForChild("InitializeEnvironment"))

local NetworkLib = require(shared.Common.NetworkLib)
local ClientManager = require(_G.Server.Core.ClientManager).new()
local GameCharacter = require(_G.Server.Game.GameCharacter)

local ProjectileManager = require(_G.Server.Game.Managers.ServerProjectileManager)
local ServerWeaponManager =
    require(_G.Server.Game.Managers.ServerWeaponManager).new(
    {
        GameMode = "Zombies",
        ProjectileManager = ProjectileManager
    }
)

ClientManager:init()
ClientManager.ClientAdded:listen(
    function(client)

        --!
        --! TEST CODE - NOT FINAL
        --!
        
        client.GameCharacter = GameCharacter.new(client)
        client.GameCharacter:spawn()

        local gun = ServerWeaponManager:create("M1Garand")
        local gun2 = ServerWeaponManager:create("M4A1")
        ServerWeaponManager:register(gun, client)
        ServerWeaponManager:register(gun2, client)
        ServerWeaponManager:equip(client, gun)
        wait(10)
        ServerWeaponManager:equip(client, gun2)

    end
)

local function route(packetType, ...)
    ServerWeaponManager:route(packetType, ...)
end

NetworkLib:listen(route)

-- TODO: objects have :serialize method
-- TODO: map loading (including terrain)
-- TODO: load game mode
-- TODO: game loop