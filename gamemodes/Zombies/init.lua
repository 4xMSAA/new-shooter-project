local Maid = require(shared.Common.Maid)

local NetworkLib = require(shared.Common.NetworkLib)

local ServerScene = require(_G.Server.Game.ServerScene)
local GameCharacter = require(_G.Server.Game.GameCharacter)
local ProjectileManager = require(_G.Server.Game.Managers.ServerProjectileManager)
local ServerWeaponManager = require(_G.Server.Game.Managers.ServerWeaponManager)
local SceneLoader = require(_G.Server.Game.SceneLoader)
local EntityManager = require(shared.Game.EntityManager)

local GameModeConfigs = shared.GameModeConfigs

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
        Configuration = require(GameModeConfigs:WaitForChild("Zombies", 5)),
        ClientManager = super.ClientManager,
        WeaponManager = ServerWeaponManager.new({
            GameMode = "Zombies",
            ProjectileManager = ProjectileManager
        }),

        Enemies = {},
        Interactables = {},

        Wave = 1
    }

    local scene = SceneLoader.new(EntityManager.new())
    scene:load("TestScene")

    ZombiesGamemode.gameStart = gameStart(self)
    ZombiesGamemode.gameLoop = gameLoop(self)
    ZombiesGamemode.gameEnd = gameEnd(self)

    self.ClientManager.ClientAdded:listen(
        function(client)

            --!
            --! TEST CODE - NOT FINAL
            --!

            client.GameCharacter = GameCharacter.new(client)
            client.GameCharacter:spawn(scene:getRandomSpawner("Player"):run())

            self:sendExistingStateToAdhoc(client)

            local gun = self.WeaponManager:create("M4A1")
            self.WeaponManager:register(gun, client)
            self.WeaponManager:equip(client, gun)
        end
    )
    self.ClientManager.ClientRemoving:listen(
        function(client)
            self.WeaponManager:unregisterAllFrom(client)
        end
    )

    local function route(player, packetType, ...)
        self.WeaponManager:route(packetType, self.ClientManager:getClientByPlayer(player), ...)
    end

    self._NetworkListener = NetworkLib:listen(route)


    setmetatable(self, ZombiesGamemode)
    Maid.watch(self)
    return self
end

---Sends game state to clients that have joined ad-hoc (in progress game)
---and are not aware of the game's previous state.
---@param client Client
function ZombiesGamemode:sendExistingStateToAdhoc(client)
    self.WeaponManager:adhocUpdate(client)
end

return ZombiesGamemode
