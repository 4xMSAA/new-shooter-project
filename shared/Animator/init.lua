--[[
    basically AnimationController

    this is more memory-oriented so maybe it will bloat the script something
--]]
local Styles = require(shared.Common.Styles)

local EasingDirectionMap = require(script.Common.EasingDirectionMap)
local AnimationTrack = require(script.AnimationTrack)

---helper function in _getNextPose
local function seekBackwards(keyframes, index, motor6d, time)
    local result
    local hopIndex = index
    repeat
        hopIndex = hopIndex - 1
        if keyframes[hopIndex] and keyframes[hopIndex].Time < time then
            result = keyframes[hopIndex].Poses[motor6d]
            if result and result.Weight <= 0 then
                result = nil
            end
        end -- print(index, hopIndex, result)
    until result or hopIndex <= 1

    return result
end

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

    self.Rig.DescendantAdded:connect(
        function(obj)
            if obj:IsA("Motor6D") then
                print(obj)
                self:_rebakeAll()
            end
        end
    )

    return self
end

---gets the next pose instances that are equal or above target time
---@private
---@param keyframes table
---@param time any
function Animator:_getNextPose(keyframes, time)
    local currentPoses, nextPoses, newEntry = {}, {}, false
    for index, keyframe in pairs(keyframes) do
        for motor6d, pose in pairs(keyframe.Poses) do
            -- we check if pose is something that is weighted in the keyframe
            -- not already written in the next pose list and finally,
            -- make sure we're not iterating over poses in the past

            if pose.Weight > 0 and not nextPoses[motor6d] and keyframe.Time >= (time or 0) then
                nextPoses[motor6d] = pose
                -- seek backwards from this found pose
                currentPoses[motor6d] = seekBackwards(keyframes, index, motor6d, time)
            end
        end
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
    if not track._timeMap then
        -- get initial frames to go to and such, then leave the rest to step
        local timeMap = self:_bakeTimeMap(track.Keyframes)
        track._timeMap = timeMap
    end
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
    -- TODO: handle animations stopping
    -- TODO: make animations blend from one animation to another (if neccessary)
    -- TODO: handle priority system
end

function Animator:seek(track, time)
    track.TimePosition = time
    local currentPoses, nextPoses = self:_getNextPose(track.Keyframes, track.TimePosition)

    for motor6d, pose in pairs(currentPoses) do
        local targetPose = nextPoses[motor6d]
        -- determine easing style from pose
        local easingStyle = Styles[targetPose.EasingStyle:lower()]
        local easing = EasingDirectionMap[targetPose.EasingDirection](easingStyle)
        -- print(pose.EasingStyle,  pose.EasingDirection)

        -- create intermediate time scales between frames
        local intermediateTime =
            math.min(
            1,
            (track.TimePosition - track._timeMap[pose]) / (track._timeMap[targetPose] - track._timeMap[pose])
        )

        -- print(
        --     "intermediate:",
        --     intermediateTime,
        --     "\toffset:",
        --     track.TimePosition - track._timeMap[pose],
        --     "\ttime at:",
        --     track.TimePosition,
        --     "\tpose time:",
        --     track._timeMap[pose],
        --     "\tpose target time:",
        --     track._timeMap[targetPose],
        --     "\tpose from to target:",
        --     pose.Instance,
        --     targetPose.Instance
        -- )

        -- interpolate currentpose to targetpose
        if targetPose then
            motor6d.Transform = pose.CFrame:lerp(targetPose.CFrame, easing(intermediateTime))
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

function Animator:_rebakeAll()
    for track, _ in pairs(self._hostedTracks) do
        track._timeMap = nil
        track._rebake = true
        track:bake(self.Rig)
    end
end

return Animator
