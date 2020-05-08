local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Initialize environment variables
require(ReplicatedStorage.Source:WaitForChild("InitializeEnvironment"))

local Animator = require(shared.Source.Animator)
local ViewModelArms = require(script.Parent.Core.ViewModelArms)

-- TODO: actual input binding
-- TODO: move gun test code somewhere else or make a manager/handler module for guns
local Gun = require(script.Parent.Core.Gun)

local test = Gun.new("M1Garand", "Zombies")
test.ViewModel.Parent = shared.Path.ClientViewmodel

local arms = ViewModelArms.new(_G.VIEWMODEL.DEFAULT_ARMS)
arms:attach(test)

local gunAnimator = Animator.new(test.ViewModel)
local track = gunAnimator:loadAnimation(test.AssetAnimations.Idle)
track:play()

local firing = gunAnimator:loadAnimation(test.AssetAnimations.Fire)

RunService:BindToRenderStep(
    "GunUpdate",
    900,
    function(dt)
        test:update(dt, workspace.CurrentCamera.CFrame)
    end
)
RunService:BindToRenderStep(
    "AnimatorUpdate",
    901,
    function(dt)
        gunAnimator:_step(dt)
    end
)

coroutine.wrap(
    function()
        while wait(1) do
            test:fire()
            firing:play()
        end
    end
)()

while wait(3) do
    test:setState("Aim", not test.State.Aim)
end
