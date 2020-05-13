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
        Instance = Instance.new("Sound")
    }

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

    self.play = self.Instance.Play
    self.stop = self.Instance.Stop

    for prop, value in pairs(props) do
        if prop == "SoundId" then
            value = "rbxassetid://" .. value
        end
        self.Instance[prop] = value
    end
    for prop, value in pairs(extraProps) do
        self[prop] = Sound._customProps[prop](self, value)
    end
end

function Sound:playMultiple()
    -- TODO big todo, make it so play creates more sounds if needed
    -- because we don't want things to suddenly stop such as firing sounds
end

return Sound
