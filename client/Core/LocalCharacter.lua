--[[
    Hassle with Roblox characters being loaded is very unknown and stupid
    Module aims to simplify use of character with custom camera setups
--]]
local Emitter = require(shared.Common.Emitter)

local LocalCharacter = {
    Player = nil,
    Velocity = 0,
    CharacterTransparency = 1,
    CameraUpdated = Emitter.new(),
    StoredState = {}
}

---Helper function to set object transparency
---@param object userdata
---@param value number
local function setObjectTransparency(object, value, originalStateTable)
    if object:IsA("BasePart") then
        object.LocalTransparencyModifier = value
    end

    if object:IsA("ParticleEmitter") then
        if not originalStateTable[object] then
            originalStateTable[object] = object.Enabled
        end
        object.Enabled = value >= 1 and false or originalStateTable[object]
    end
end

---Returns the character currently as the player's character
---@return userdata LocalPlayer's character
function LocalCharacter:get()
    return self.Character
end

---Sets a character model to be the active character to manage
---@param character userdata The LocalCharacter model of a Player to manage
function LocalCharacter:set(character)
    if not character then
        return
    end

    self.Character = character
    character.DescendantAdded:connect(
        function(object)
            self:setTransparency(self.CharacterTransparency, object)
        end
    )
    self:setTransparency(self.CharacterTransparency)
end

---Sets the active character's transparency to the specified value, optionally using an exclusion list
---@param value number Target transparency for the character
---@param target userdata Specify a part to change - default iterates through character
function LocalCharacter:setTransparency(value, target)
    self.CharacterTransparency = value
    if not target and self:get() then
        for _, object in pairs(self:get():GetDescendants()) do
            setObjectTransparency(object, value)
        end
    elseif target then
        setObjectTransparency(target, value)
    end
end

function LocalCharacter:listenPlayer(player)
    self.Player = player
    player.CharacterAdded:connect(
        function(char)
            self:set(char)
        end
    )
    if player.Character then
        self:set(player.Character)
    end
end

return LocalCharacter
