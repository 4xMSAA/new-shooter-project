_G.Server = script.Parent

-- load services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- initialize the game environment
require(ReplicatedStorage.Source:WaitForChild("InitializeEnvironment"))

-- load dependancies
local NetworkLib = require(shared.Common.NetworkLib)
local ClientManager = require(_G.Server.Core.ClientManager).new()
local GameCharacter = require(_G.Server.Game.GameCharacter)

-- start server code
ClientManager:init()

repeat
    wait()
until #ClientManager.Clients > 0

for _, client in pairs(ClientManager.Clients) do
    -- associate a GameCharacter with each client
    client.GameCharacter = GameCharacter.new(client)
    client.GameCharacter:spawn()
end

-- TODO: implement player loading

-- TODO: make a gun manager for keeping track of weapons both server and client
-- TODO: objects have :serialize method
-- TODO: map loading (including terrain)
