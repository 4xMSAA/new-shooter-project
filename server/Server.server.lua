_G.Server = script.Parent

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Source:WaitForChild("InitializeEnvironment"))

local Maid = require(shared.Common.Maid)
local NetworkLib = require(shared.Common.NetworkLib)

local ClientManager = require(_G.Server.Core.ClientManager)

local GameModeLoader = require(_G.Server.Game.GameModeLoader)


---A class description
---@class Server
local Server = {}
Server.__index = Server

function Server.new()
    local self = {
        ClientManager = ClientManager.new(),
        GameMode = "Zombies"
    }
    self.ClientManager:init()

    setmetatable(self, Server)
    Maid.watch(self)
    return self
end

local server = Server.new()

local GameMode = GameModeLoader.loadFromServer(server)

-- TODO: objects have :serialize method
-- TODO: scene loading (including terrain)
-- TODO: load game mode
-- TODO: game loop