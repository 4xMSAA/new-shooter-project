local GameMode = require(_G.Server.Game.GameMode)

---Loads a gamemode and its configuration for a session
---@class GameModeLoader
local GameModeLoader = {}
GameModeLoader.__index = GameModeLoader

function GameModeLoader.initialize()
    local self = GameModeLoader
    self.GameModes = {}
    
    for _, gamemodeInstance in pairs(_G.GameModes:GetChildren()) do
        if gamemodeInstance:IsA("ModuleScript") then
            local gamemode = require(gamemodeInstance)
            self.GameModes[gamemode.Name] = gamemode
        end
    end
end

function GameModeLoader.loadFromServer(server)
    local self = GameModeLoader
    local name = server.GameMode
    local base = GameMode.new(server)

    return self.GameModes[name].new(base)
end

GameModeLoader.initialize()
return GameModeLoader
