_G.Client = script.Parent

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

-- Initialize environment variables
require(ReplicatedStorage.Source:WaitForChild("InitializeEnvironment"))

local Enums = shared.Enums

local Camera = require(_G.Client.Core.Camera).new(workspace.CurrentCamera)
local LocalCharacter = require(_G.Client.Core.LocalCharacter)
local WeaponManager = require(_G.Client.Managers.WeaponManager).new({Camera = Camera})

local pause = false

UserInputService.MouseIconEnabled = false

-- TODO: actual input binding
-- TODO: move gun test code somewhere else or make a manager/handler module for guns

local test = WeaponManager:create("M4A1", "a")

WeaponManager:register(test, test.UUID, Players.LocalPlayer)
WeaponManager:equipViewport(test)

LocalCharacter:listenPlayer(Players.LocalPlayer)
LocalCharacter:setTransparency(1)

RunService:BindToRenderStep(
    "WeaponManagerUpdate",
    500,
    function(dt)
        if pause then
            return
        end
        LocalCharacter:step(dt)
        WeaponManager:step(dt, Camera, LocalCharacter.Velocity)
    end
)

RunService:BindToRenderStep(
    "CameraUpdate",
    100,
    function(dt)
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        Camera.AttachTo = LocalCharacter:get() and LocalCharacter:get():FindFirstChild("Humanoid") or nil
        Camera:updateView(dt)
    end
)

-- temporary input binding
local function inputHandler(name, state, object)
    if name == "Aim" then
        WeaponManager:setState(test, "Aim", state == Enum.UserInputState.Begin and true or false)
    elseif name == "Fire" and state == Enum.UserInputState.Begin then
        WeaponManager:fire(test, true)
    elseif name == "Fire" and state == Enum.UserInputState.Begin then
        WeaponManager:fire(test, false)
    elseif name == "Reload" and state == Enum.UserInputState.Begin then
        WeaponManager:reload(test)
    elseif name == "Pause" and state == Enum.UserInputState.Begin then
        pause = not pause
    end
end

local function inputChangedHandler(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        Camera:moveLook(input.Delta.x, input.Delta.y)
    end
end

-- TODO: check if polling gamepad position helps

ContextActionService:BindAction("Aim", inputHandler, true, Enum.UserInputType.MouseButton2)
ContextActionService:BindAction("Fire", inputHandler, true, Enum.UserInputType.MouseButton1)
ContextActionService:BindAction("Reload", inputHandler, true, Enum.KeyCode.R)
ContextActionService:BindAction("Pause", inputHandler, true, Enum.KeyCode.P)

UserInputService.InputChanged:connect(inputChangedHandler)
