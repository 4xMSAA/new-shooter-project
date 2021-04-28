local Maid = require(shared.Common.Maid)

local GameCharacter = require(_G.Server.Game.GameCharacter)

local gameStart = require(script.GameStart)
local gameLoop = require(script.GameLoop)
local gameEnd = require(script.GameEnd)

---Gamemode which plays out like Call of Duty Zombies. Each wave a number of 
---zombies spawn which players must eliminate to progress to the next round.
---Players can purchase weapons, roll a random weapon by a mystery box and
---progress to new areas by removing debris with acquired points.
---@class ZombiesGamemode
local ZombiesGamemode = {Name = "Zombies"}
ZombiesGamemode.__index = ZombiesGamemode

function ZombiesGamemode.new(super)
    local self = {
        super = super,
        ClientManager = super.ClientManager,
        WeaponManager = super.WeaponManager,

        Enemies = {},
        Interactables = {},

        Wave = 1
    }

    ZombiesGamemode.gameStart = gameStart(self)
    ZombiesGamemode.gameLoop = gameLoop(self)
    ZombiesGamemode.gameEnd = gameEnd(self)

    self.ClientManager.ClientAdded:listen(
        function(client)

            --!
            --! TEST CODE - NOT FINAL
            --!
            
            client.GameCharacter = GameCharacter.new(client)
            client.GameCharacter:spawn()

            local gun = self.WeaponManager:create("M1Garand")
            local gun2 = self.WeaponManager:create("M4A1")
            self.WeaponManager:register(gun, client)
            self.WeaponManager:register(gun2, client)
            self.WeaponManager:equip(client, gun)
            wait(10)
            self.WeaponManager:equip(client, gun2)

        end
    )

    setmetatable(self, ZombiesGamemode)
    Maid.watch(self)
    return self
end

return ZombiesGamemode