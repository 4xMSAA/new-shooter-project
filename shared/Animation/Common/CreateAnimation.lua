local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local function createPreviewAnimation(keyframeSequence)
    local hashId = KeyframeSequenceProvider:RegisterKeyframeSequence(keyframeSequence)
    if hashId then
        local Animation = Instance.new("Animation")
        Animation.AnimationId = hashId
        return Animation
    end
    return error("KeyframeSequenceProvider failed to load " .. keyframeSequence:GetFullName())
end

return createPreviewAnimation