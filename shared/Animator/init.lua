--[[
    basically AnimationController

    this is more memory-oriented so maybe it will bloat the script something
--]]
local TableUtil = require(shared.Common.TableUtil)
local Styles = require(shared.Common.Styles)

local AnimationTrack = require(script.AnimationTrack)

local Animator = {}
Animator.__index = Animator

---
---@param rig userdata A model with Motor6D's to animate
function Animator.new(rig)
    local self = {}
    self._playingTracks = {}
    self._hostedTracks = {}
    self.Rig = rig

    setmetatable(self, Animator)
    return self
end

---gets the next pose instances that are equal or above target time
---@private
---@param keyframes table
---@param time any
function Animator:_getNextPose(keyframes, time)
    local currentPoses, nextPoses, newEntry = {}, {}, false
    for _, keyframe in pairs(keyframes) do
        for motor6d, pose in pairs(keyframe.Poses) do
            -- we check if pose is something that is weighted in the keyframe
            -- then if it's not equal to the current pose, make sure it's
            -- not already written in the next pose list and finally,
            -- make sure we're not iterating over poses in the past

            if
                pose.Weight > 0 and currentPoses[motor6d] ~= pose and not nextPoses[motor6d] and
                    keyframe.Time > (time or 0)
             then
                nextPoses[motor6d] = pose
                newEntry = true
            elseif pose.Weight > 0 and keyframe.Time <= (time or 0) then
                currentPoses[motor6d] = pose
            end
        end
    end

    if newEntry == false then
        return currentPoses, currentPoses
    end

    return currentPoses, nextPoses
end

---creates a pose to keyframe time map
---@param track table
function Animator:_bakeTimeMap(track)
    local timeMap = {}
    for _, keyframe in pairs(track) do
        for _, pose in pairs(keyframe.Poses) do
            timeMap[pose] = keyframe.Time
        end
    end
    return timeMap
end

---
---@private
---@param track AnimationTrack
function Animator:_initTrack(track)
    -- call this when Animatortrack is wanted to be played
    -- get initial frames to go to and such, then leave the rest to step
    local timeMap = self:_bakeTimeMap(track.Keyframes)
    track._timeMap = timeMap
end

---
---@private
function Animator:_step(dt)
    for track, _ in pairs(self._playingTracks) do
        track.TimePosition = math.min(track.Length, track.TimePosition + dt)

        self:seek(track, track.TimePosition)
        if track.Loop and track.TimePosition == track.Length then
            track.TimePosition = 0
            track.Looped:emit()
        elseif track.TimePosition == track.Length then
            track.TimePosition = 0
            track.IsPlaying = false
            self._playingTracks[track] = nil
        end
    end

    -- TODO: handle keyframe markers and the events
    -- TODO: handle looped keyframes
    -- TODO: handle animations stopping
    -- TODO: make animations blend from one animation to another (if neccessary)
    -- TODO: handle priority system
end

function Animator:seek(track, time)
    track.TimePosition = time
    local currentPoses, nextPoses = self:_getNextPose(track.Keyframes, track.TimePosition)

    for motor6d, pose in pairs(currentPoses) do
        -- determine easing style from pose
        local easingStyle = Styles[pose.EasingStyle.Name:lower()]
        easingStyle =
            pose.EasingDirection == Enum.EasingDirection.InOut and
            Styles.chain(easingStyle, Styles.out(easingStyle)) or
            pose.EasingDirection == Enum.EasingDirection.Out and Styles.out(easingStyle) or
            easingStyle

        -- create intermediate time scales between frames
        local intermediateTime =
            math.min(
            1,
            easingStyle(track.TimePosition - track._timeMap[currentPoses[motor6d]]) / track._timeMap[pose]
        )

        -- interpolate currentpose to targetpose
        if nextPoses[motor6d] then
            motor6d.Transform = pose.CFrame:lerp(nextPoses[motor6d].CFrame, intermediateTime)
        end
    end
end

function Animator:loadAnimation(keyframeSequence, mapper)
    local animTrack = AnimationTrack.new(self, keyframeSequence, mapper)
    animTrack:bake(self.Rig)

    self._hostedTracks[animTrack] = true

    return animTrack
end

function Animator:addPlayingTrack(track)
    if not self._hostedTracks[track] then
        error("track " .. track.Name .. " is not hosted by this Animator (" .. self.Rig:GetFullName() .. ")")
    end
    self:_initTrack(track)
    self._playingTracks[track] = true
    track.TimePosition = 0

    for motor6d, pose in pairs(track.Keyframes[1].Poses) do
        motor6d.Transform = pose.CFrame
    end
end

return Animator
