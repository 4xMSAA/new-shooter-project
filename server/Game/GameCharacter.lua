local StarterPlayer = game:GetService("StarterPlayer")
local Players = game:GetService("Players")

local Enums = shared.Enums

local NetworkLib = require(shared.Common.NetworkLib)

---A character of a client
---@class GameCharacter
local GameCharacter = {}
GameCharacter.__index = GameCharacter

function GameCharacter.new(client)
    local self = {
        Client = client,
        _characterPos = Vector3.new()
    }
    setmetatable(self, GameCharacter)
    return self
end

function GameCharacter:getCharacterPosition()
end

function GameCharacter:loadCharacter(cf, parent)
    local char = StarterPlayer:WaitForChild("StarterCharacter"):Clone()
    char:SetPrimaryPartCFrame(cf or CFrame.new(0, 50, 0))
    char.Parent = parent or workspace
    self.Client.PlayerInstance.Character = char
end

function GameCharacter:spawn(cf)
    NetworkLib:send(Enums.PacketType.PlayerSpawn, self.Client.ID)
    self:loadCharacter(cf)
end

function GameCharacter:updateCharacterPosition()
    -- do legitimacy checks
end

return GameCharacter