-- return an AnimationTrack-like object
-- https://developer.roblox.com/en-us/api-reference/class/AnimationTrack
-- this cannot be created standalone and requires a host animation controller

-- i need to make it so animation tracks are playable but i'm a bit unsure how to handle it
-- so everything is on one line
-- i need to get every keyframe on that track
-- they all have their poses
-- some don't have pose data
-- so i have to keep in memory the next pose it knows
-- and create it's own intermediate interpolation value

local Emitter = require(shared.Common.Emitter)

local AnimationParser = require(script.Parent.Common.AnimationParser)

---@class AnimationTrack
local AnimationTrack = {}
AnimationTrack.__index = AnimationTrack

-- TODO: clear cache over time if not used to prevent memory growing too big
-- only implement if this actually becomes a performance concern
AnimationTrack._cache = {}

---
---@param keyframeSequence userdata
---@param map function A keyframe mapping function for remapping Motor6Ds
function AnimationTrack.new(host, keyframeSequence, map)
    local self = {
        Name = keyframeSequence.Name,

        Animation = keyframeSequence,
        IsPlaying = false,
        IsBaked = false,

        JointMap = map,

        Loop = keyframeSequence.Loop,
        Priority = keyframeSequence.Priority,
        Speed = 1,
        TimePosition = 0,
        Length = AnimationParser.getLastKeyframe(keyframeSequence).Time,

        Looped = Emitter.new(),
        Stopped = Emitter.new(),
        MarkerReached = Emitter.new(),
        _TrackedMarkers = {},

        _Host = host
    }

    setmetatable(self, AnimationTrack)

    return self
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
    if not AnimationTrack._cache[self.Animation] then
        local keyframes = AnimationParser.createTrack(self.Animation, model, self.JointMap)
        AnimationTrack._cache[self.Animation] = keyframes
        self.Keyframes = keyframes
    else
        self.Keyframes = AnimationTrack._cache[self.Animation]
    end
end

--- Tells the host Animator to play the track on the rig
function AnimationTrack:play()

    -- TODO: tell host Animator that we want to play the animation
    self.IsPlaying = true
    self._Host:addPlayingTrack(self)

end

return AnimationTrack
