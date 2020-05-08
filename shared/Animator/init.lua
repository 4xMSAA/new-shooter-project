--[[
    basically AnimationController
--]]

local Animator = {}
Animator.__index = Animator

function Animator.new(rig)
    self._playingTracks = {}

    setmetatable(self, Animator)
    return self
end

function Animator:_getTargetPoses()

end

function Animator:_initTrack(track)
    -- call this when Animatortrack is wanted to be played
    -- get initial frames to go to and such, then leave the rest to step
    track._currentPoses = {}
    track._targetPoses = {}
end

function Animator:_step()

    for _, track in pairs(self._playingTracks) do

    end
    --interpolate currentpose to targetpose, must know their keyframe from somewhere however
end

return Animator