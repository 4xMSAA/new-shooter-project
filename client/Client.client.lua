local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local pause = false

UserInputService.MouseIconEnabled = false

-- Initialize environment variables
require(ReplicatedStorage.Source:WaitForChild("InitializeEnvironment"))

local ViewModelArms = require(script.Parent.Core.ViewModelArms)

-- TODO: actual input binding
-- TODO: move gun test code somewhere else or make a manager/handler module for guns
-- TODO: move animator to gun class you fuck

local Gun = require(script.Parent.Core.Gun)

local test = Gun.new("M1Garand", "Zombies")
test.ViewModel.Parent = _G.Path.ClientViewmodel

local arms = ViewModelArms.new(_G.VIEWMODEL.DEFAULT_ARMS)
arms:attach(test)

test.Animations.Idle:play()

repeat
    wait()
until game.Players.LocalPlayer.Character
local hrp = game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")

RunService:BindToRenderStep(
    "GunUpdate",
    900,
    function(dt)
        if pause then return end

        test:setState("Movement", hrp.Velocity.magnitude)
        test.Animator:_step(dt)
        test:update(dt, workspace.CurrentCamera.CFrame)
    end
)

local function inputHandler(name, state, object)
    if name == "Aim" then
        test:setState("Aim", state == Enum.UserInputState.Begin and true or false)
    elseif name == "Fire" and state == Enum.UserInputState.Begin then
        test:fire()
    elseif name == "Reload" and state == Enum.UserInputState.Begin then
        test:reload()
    elseif name == "Pause" and state == Enum.UserInputState.Begin then
        pause = not pause
    end
end

ContextActionService:BindAction("Aim", inputHandler, true, Enum.UserInputType.MouseButton2)
ContextActionService:BindAction("Fire", inputHandler, true, Enum.UserInputType.MouseButton1)
ContextActionService:BindAction("Reload", inputHandler, true, Enum.KeyCode.R)
ContextActionService:BindAction("Pause", inputHandler, true, Enum.KeyCode.P)

-- coroutine.wrap(
--     function()
--         while wait(1) do
--             test:fire()
--             firing:play()
--         end
--     end
-- )()
