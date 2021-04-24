local Maid = require(shared.Common.Maid)

local gameLoop = require(script.GameLoop)
local gameEnd = require(script.GameEnd)

---A class description
---@class ZombiesGamemode
local ZombiesGamemode = {Name = "Zombies"}
ZombiesGamemode.__index = ZombiesGamemode

function ZombiesGamemode.new(super)
    local self = {
        ClientManager = super.ClientManager,
        WeaponManager = super.WeaponManager,

        Enemies = {}
    }

    ZombiesGamemode.gameLoop = gameLoop(self)
    ZombiesGamemode.gameEnd = gameEnd(self)

    -- there is no other reference of super anywhere except here
    -- gamemodeloader uses it merely as an intermediate step
    function self:destroy()
        super:destroy()
    end

    setmetatable(self, ZombiesGamemode)
    Maid.watch(self)
    return self
end

return ZombiesGamemode