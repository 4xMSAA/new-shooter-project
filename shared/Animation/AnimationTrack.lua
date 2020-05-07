-- return an AnimationTrack-like object
-- https://developer.roblox.com/en-us/api-reference/class/AnimationTrack

-- i need to make it so animation tracks are playable but i'm a bit unsure how to handle it
-- so everything is on one line
-- i need to get every keyframe on that track
-- they all have their poses
-- some don't have pose data
-- so i have to keep in memory the next pose it knows
-- and create it's own intermediate interpolation value

local Emitter = require(shared.Common.Emitter)

local AnimationParser = require(shared.Source.Animation.Common.AnimationParser)

local AnimationTrack = {}
AnimationTrack.__index = AnimationTrack

AnimationTrack._bakedAnimations = {}

---
---@param keyframeSequence userdata
---@param map function A keyframe mapping function for remapping Motor6Ds
function AnimationTrack.new(keyframeSequence, map)
    local self = {
        Animation = keyframeSequence,
        IsPlaying = false,
        IsBaked = false,

        JointMap = map,

        Loop = keyframeSequence.Looped,
        Priority = keyframeSequence.Priority,
        Speed = 1,
        TimePosition = 0,
        Length = AnimationParser.getLastKeyframe().Time,

        Looped = Emitter.new(),
        Stopped = Emitter.new(),
        MarkerReached = Emitter.new(),
        _TrackedMarkers = {}
    }

    setmetatable(self, AnimationTrack)
    self:bake()
end

---When a marker is reached in the animation, the returned emitter will fire
---@param name string
function AnimationTrack:getMarkerEmitter(name)
    if not self.IsBaked then
        return error("animation not baked, cannot get marker data")
    end
    -- TODO implement fetching markers from self.Track
end

---
---@param model userdata
function AnimationTrack:bake(model)
    if not AnimationTrack._bakedAnimations[self.Animation] then
        local data = AnimationParser.createTrack(self.Animation, model, self.JointMap)
        AnimationTrack._bakedAnimations[self.Animation] = data
        self.Track = data
    else
        self.Track = AnimationTrack._bakedAnimations[self.Animation]
    end
end

function AnimationTrack:play()
    -- TODO biggest fucking todo i have to do right here
    -- contemplating whether to make a separate module for playing these animation tracks or something else
end

return AnimationTrack
