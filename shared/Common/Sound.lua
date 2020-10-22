---A wrapper around the Roblox Sound instance for extra features
---@class Sound
local Sound = {}
Sound.__index = Sound

Sound._customProps = {
    IsGlobal = function(self, value)
        if value then
            self.Instance.Parent = _G.Path.Sounds
        end
    end,
    Parent = function(self, parent)
        self.Instance.Parent = parent
    end
}

---
---@param props table
---@param extraProps table
function Sound.new(props, extraProps)
    local self = {
        Instance = Instance.new("Sound"),
        _instances = {}
    }

    table.insert(self._instances, self.Instance)

    -- set a metatable that first refers to the Sound table and then lastly to the Instance itself
    setmetatable(
        self,
        {
            __index = function(self, index)
                return Sound[index] or self.Instance[index]
            end
        }
    )
    self:_init(props, extraProps)

    return self
end

function Sound:_init(props, extraProps)
    if typeof(props) == "number" then
        props = {SoundId = props}
    end

    for prop, value in pairs(props) do
        if prop == "SoundId" then
            value = "rbxassetid://" .. tostring(value):match("%d+")
        end
        self.Instance[prop] = value
        for _, instance in pairs(self._instances) do
            instance[prop] = value
        end
    end
    for prop, value in pairs(extraProps) do
        self[prop] = Sound._customProps[prop](self, value)
    end
end

-- wrappers cause roblox instances are behaving stupidly or my metamethod is wrong
function Sound:play()
    self.Instance:play()
end
function Sound:stop()
    self.Instance:stop()
end
function Sound:pause()
    self.Instance:pause()
end

---
---@param max number The maximum amount to allow sound instances
---@return userdata Roblox Sound instance which is not playing
function Sound:_getPlayableInstance(max)
    for _, sound in ipairs(self._instances) do
        if not sound.IsPlaying then
            return sound
        end
    end
    if #self._instances < max then
        local sound = self.Instance:Clone()
        sound:stop()
    end

    warn("exceeding maximum range (" .. max .. ") for sound " .. self.Instance.SoundId)
    return self.Instance
end

---
function Sound:playMultiple(max)
    self:_getPlayableInstance(max):Play()

end

return Sound
