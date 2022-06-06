local Maid = require(shared.Common.Maid)


--TODO doc: expand use cases
---Initializes core features of the game (players, for now)
---
---Gamemodes can be loaded as many times as possible. Their intention is to
---allow switching out from, for example: CTF to KotH, TDM to DM, even Zombies.
---While Zombies will practically never be switched out, this is with PvP
---scenarios in mind, where being able to load another "scene" and gamemode
---is crucial.
---@class GameMode
local GameMode = {}
GameMode.__index = GameMode

---@param server table
---@return GameMode
function GameMode.new(server, options)
    local self = {
        ClientManager = server.ClientManager,
        Options = options
    }

    setmetatable(self, GameMode)
    Maid.watch(self)
    return self
end

return GameMode
