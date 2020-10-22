_G.Client = script.Parent

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

-- Initialize environment variables
require(ReplicatedStorage.Source:WaitForChild("InitializeEnvironment"))

-- load dependancies
local Enums = shared.Enums

local NetworkLib = require(shared.Common.NetworkLib)
local Maid = require(shared.Common.Maid)

local LocalCharacter = require(_G.Client.Core.LocalCharacter)
local Movement = require(_G.Client.Game.Movement)

local Camera = require(_G.Client.Core.Camera).new(workspace.CurrentCamera)
local WeaponManager = require(_G.Client.Managers.WeaponManager).new({Camera = Camera})

local debugPause = false
local spawned = false

UserInputService.MouseIconEnabled = false

-- TODO: actual input binding
-- TODO: move gun test code somewhere else or make a manager/handler module for guns
local function spawn(character)
    spawned = true
    local test = WeaponManager:create("M4A1", "a")

    WeaponManager:register(test, test.UUID, Players.LocalPlayer)
    WeaponManager:equipViewport(test)

    LocalCharacter:listenPlayer(Players.LocalPlayer)
    LocalCharacter:setTransparency(1)

    LocalCharacter.Controller = Movement.new(character)

    -- temporary input binding
    local function inputHandler(name, state, object)
        if name == "Aim" then
            WeaponManager:setState(test, "Aim", state == Enum.UserInputState.Begin and true or false)
        elseif name == "Fire" and state == Enum.UserInputState.Begin then
            WeaponManager:fire(test, true)
        elseif name == "Fire" and state == Enum.UserInputState.End then
            WeaponManager:fire(test, false)
        elseif name == "Reload" and state == Enum.UserInputState.Begin then
            WeaponManager:reload(test)
        elseif name == "debugPause" and state == Enum.UserInputState.Begin then
            debugPause = not debugPause
        end
    end

    local function inputChangedHandler(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            Camera:moveLook(input.Delta.x, input.Delta.y)
        end
    end

    ContextActionService:BindAction("Aim", inputHandler, true, Enum.UserInputType.MouseButton2)
    ContextActionService:BindAction("Fire", inputHandler, true, Enum.UserInputType.MouseButton1)
    ContextActionService:BindAction("Reload", inputHandler, true, Enum.KeyCode.R)
    ContextActionService:BindAction("debugPause", inputHandler, true, Enum.KeyCode.P)

    UserInputService.InputChanged:connect(inputChangedHandler)

    RunService.Stepped:connect(
        function(dt)
            LocalCharacter.Controller:update(dt, Camera.CFrame.LookVector)
        end
    )
end

-- network binds
NetworkLib:listenFor(
    Enums.PacketType.PlayerSpawn,
    function(id, char)
        if id == Players.LocalPlayer.UserId then
            spawn(char)
        end
    end
)

-- runservice binds
RunService:BindToRenderStep(
    "WeaponManagerUpdate",
    500,
    function(dt)
        if debugPause or not spawned then
            return
        end
        debug.profilebegin("game-character")
        LocalCharacter:step(dt)
        debug.profileend("game-character")

        debug.profilebegin("game-weaponmanager")
        WeaponManager:step(dt, Camera, LocalCharacter.Velocity)
        debug.profilebegin("game-weaponmanager")
    end
)

RunService:BindToRenderStep(
    "CameraUpdate",
    100,
    function(dt)
        if not spawned then
            return
        end
        debug.profilebegin("game-camera")
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        Camera.AttachTo = LocalCharacter:get() and LocalCharacter:get():FindFirstChild("Humanoid") or nil
        Camera:updateView(dt)
        debug.profileend("game-camera")
    end
)
