_G.Client = script.Parent

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")


-- Initialize environment variables
require(ReplicatedStorage.Source:WaitForChild("InitializeEnvironment"))

local WeaponManager = require(_G.Client.Managers.WeaponManager).new()

local pause = false

UserInputService.MouseIconEnabled = false
-- TODO: actual input binding
-- TODO: move gun test code somewhere else or make a manager/handler module for guns

local test = WeaponManager:create("M4A1", "a")

WeaponManager:register(test, test.UUID, Players.LocalPlayer)
WeaponManager:equipViewport(test)

repeat
    wait()
until game.Players.LocalPlayer.Character
local hrp = game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")

RunService:BindToRenderStep(
    "WeaponManagerUpdate",
    900,
    function(dt)
        if pause then return end
        WeaponManager:step(dt, workspace.CurrentCamera, hrp.Velocity.magnitude)
    end
)

local function inputHandler(name, state, object)
    if name == "Aim" then
        WeaponManager:setState(test, "Aim", state == Enum.UserInputState.Begin and true or false)
    elseif name == "Fire" and state == Enum.UserInputState.Begin then
        WeaponManager:fire(test)
    elseif name == "Reload" and state == Enum.UserInputState.Begin then
        WeaponManager:reload(test)
    elseif name == "Pause" and state == Enum.UserInputState.Begin then
        pause = not pause
    end
end

ContextActionService:BindAction("Aim", inputHandler, true, Enum.UserInputType.MouseButton2)
ContextActionService:BindAction("Fire", inputHandler, true, Enum.UserInputType.MouseButton1)
ContextActionService:BindAction("Reload", inputHandler, true, Enum.KeyCode.R)
ContextActionService:BindAction("Pause", inputHandler, true, Enum.KeyCode.P)