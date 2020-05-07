local TableUtil = require(shared.Common.TableUtil)

local AnimationParser = {}

---
---@param pose userdata
---@param joints userdata
function AnimationParser.lookupJointByPose(pose, joints)
    -- roblox poses find the right part by the Pose instance's name
    -- on top of that, Part1's name of a joint is linked with the Pose's name
    -- why did roblox do that? no fuckin idea

    for _, joint in pairs(joints) do
        if joint.Part1.Name == pose.Name then
            return joint
        end
    end
end

---Map all poses to their respective joint instances
---@param keyframe userdata
---@param model userdata
---@param map function A function that returns key and value for the keyframe and pose provided
function AnimationParser.keyframeToJoints(keyframe, model, map)
    local result = {}

    -- find all joints
    local joints = {}
    for i, joint in pairs(model:GetDescendants()) do
        joints[#joints + 1] = joint
    end

    -- map pose to joint
    local poses = keyframe:GetDescendants()
    for _, pose in pairs(poses) do
        if pose:IsA("Pose") then
            if map then
                local joint, pose = map(keyframe, pose)
                result[joint] = pose
            else
                local joint = AnimationParser.lookupJointByPose(pose, joints)
                result[joint] = pose
            end
        end
    end

    return result
end

---Create a track where keyframes are ordered in an array by Time property
---along with their Pose
---@param keyframeSequence userdata
---@param model userdata
---@param keyframeMap function A function that returns key and value for the keyframe and pose provided
function AnimationParser.createTrack(keyframeSequence, model, keyframeMap)
    local track = {}

    -- make all keyframes, but they're unsorted
    for _, keyframe in pairs(keyframeSequence:GetChildren()) do
        track[#track + 1] = {
            Time = keyframe.Time,
            Instance = keyframe,
            Poses = AnimationParser.keyframeToJoints(keyframe, model, keyframeMap),
            Markers = keyframe:GetMarkers()
        }
    end

    -- sort them by Time property
    return TableUtil.valueBubblesort(track, "Time")
end

function AnimationParser.getLastKeyframe(keyframeSequence)
    local resultKeyframe, x = 0
    for _, keyframe in pairs(keyframeSequence:GetChildren()) do
        if keyframe.Time > x then
            x = keyframe.Time
            resultKeyframe = keyframe
        end
    end

    return resultKeyframe, x
end

return AnimationParser
