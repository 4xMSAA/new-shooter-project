local Maid = require(shared.Common.Maid)
local NetworkLib = require(shared.Common.NetworkLib)

local ProjectileManager = require(_G.Server.Game.Managers.ServerProjectileManager)
local ServerWeaponManager = require(_G.Server.Game.Managers.ServerWeaponManager)



--TODO doc: expand use cases  
---Initializes core features of the game (e.g. weapon manager, players)
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
function GameMode.new(server)
    local self = {
        ClientManager = server.ClientManager,
        WeaponManager = ServerWeaponManager.new({
            GameMode = server.GameMode,
            ProjectileManager = ProjectileManager
        })
    }

    local function route(player, packetType, ...)
        self.WeaponManager:route(packetType, self.ClientManager:getClientByPlayer(player), ...)
    end

    self._WeaponManagerListener = NetworkLib:listen(route)

    setmetatable(self, GameMode)
    Maid.watch(self)
    return self
end

return GameMode