local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local function createPreviewAnimation(keyframeSequence)
    local hashId = KeyframeSequenceProvider:RegisterKeyframeSequence(keyframeSequence)
    if hashId then
        local Animation = Instance.new("Animation")
        Animation.AnimationId = hashId
        return Animation
    end
end

local anim = createPreviewAnimation(game.ReplicatedStorage.MoonAnimatorExport.test_R15)

wait(5)
print'should have played by now'
while wait(3) do
    workspace.R15.Humanoid:LoadAnimation(anim):Play()
end