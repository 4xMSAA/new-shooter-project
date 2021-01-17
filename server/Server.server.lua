_G.Server = script.Parent

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Source:WaitForChild("InitializeEnvironment"))

local NetworkLib = require(shared.Common.NetworkLib)
local ClientManager = require(_G.Server.Core.ClientManager).new()
local GameCharacter = require(_G.Server.Game.GameCharacter)

ClientManager:init()
ClientManager.ClientAdded:listen(
    function(client)
        client.GameCharacter = GameCharacter.new(client)
        client.GameCharacter:spawn()
    end
)

-- TODO: make a gun manager for keeping track of weapons both server and client
-- TODO: objects have :serialize method
-- TODO: map loading (including terrain)
