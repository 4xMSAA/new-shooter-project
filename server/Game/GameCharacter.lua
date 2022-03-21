local StarterPlayer = game:GetService("StarterPlayer")
local Players = game:GetService("Players")

local GameEnum = shared.GameEnum

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
    char.Name = self.Client.Name
    char.Parent = parent or _G.Path.Players
    self.Client.Instance.Character = char
    return char
end

function GameCharacter:spawn(cf)
    local char = self:loadCharacter(cf)
    NetworkLib:send(GameEnum.PacketType.PlayerSpawn, self.Client.ID, char)
end

function GameCharacter:updateCharacterPosition()
    -- do legitimacy checks
end

return GameCharacter