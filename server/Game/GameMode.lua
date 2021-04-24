local Maid = require(shared.Common.Maid)
local NetworkLib = require(shared.Common.NetworkLib)

local ProjectileManager = require(_G.Server.Game.Managers.ServerProjectileManager)
local ServerWeaponManager = require(_G.Server.Game.Managers.ServerWeaponManager)
local GameCharacter = require(_G.Server.Game.GameCharacter)



--TODO doc: expand use cases  
---Initializes core features of the game (e.g. weapon manager)
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

    self.ClientManager.ClientAdded:listen(
        function(client)

            --!
            --! TEST CODE - NOT FINAL
            --!
            
            client.GameCharacter = GameCharacter.new(client)
            client.GameCharacter:spawn()

            print("hi", client.Name)

            local gun = self.WeaponManager:create("M1Garand")
            local gun2 = self.WeaponManager:create("M4A1")
            self.WeaponManager:register(gun, client)
            self.WeaponManager:register(gun2, client)
            self.WeaponManager:equip(client, gun)
            wait(10)
            self.WeaponManager:equip(client, gun2)

        end
    )


    local function route(packetType, ...)
        self.WeaponManager:route(packetType, ...)
    end

    NetworkLib:listen(route)


    setmetatable(self, GameMode)
    Maid.watch(self)
    return self
end

return GameMode