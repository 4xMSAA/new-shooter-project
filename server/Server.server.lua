_G.Server = script.Parent

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Source:WaitForChild("Environment"))

local Maid = require(shared.Common.Maid)

local ClientManager = require(_G.Server.Core.ClientManager)


---A class description
---@class Server
local Server = {}
Server.__index = Server

function Server.new()
    local self = {
        ClientManager = ClientManager.new(),
    }

    setmetatable(self, Server)
    Maid.watch(self)

    return self
end

function Server:start(module, options)
    self.ClientManager:init()
    self._running = require(module)(self, options)

    return self
end


local server = Server.new()
server:start(_G.Server.Game.GameModeLoader, {GameMode = "Zombies", Scene = "TestScene"})

RunService.Heartbeat:connect(function(deltaTime)
    server._running.gameLoop(deltaTime)
end)

-- TODO: objects have :serialize method
-- TODO: scene loading (including terrain)
-- TODO: game loop
