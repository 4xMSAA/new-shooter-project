_G.Client = script.Parent

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
require(ReplicatedStorage.Source:WaitForChild("InitializeEnvironment"))

local NETWORK_CAMERA_UPDATE_INTERVAL = _G.INTERVALS.NETWORK.CAMERA_UPDATE

local Enums = shared.Enums

local NetworkLib = require(shared.Common.NetworkLib)
local Maid = require(shared.Common.Maid)
local Timer = require(shared.Common.Timer)

local LocalCharacter = require(_G.Client.Core.LocalCharacter)
local Movement = require(_G.Client.Game.Movement)

local Camera = require(_G.Client.Core.Camera).new(workspace.CurrentCamera)
local ProjectileManager = require(_G.Client.Game.Managers.ProjectileManager).new()
local WeaponManager =
    require(_G.Client.Game.Managers.WeaponManager).new(
    {
        Camera = Camera,
        ProjectileManager = ProjectileManager,
        GameMode = "Zombies"
    }
)

local debugPause = false
local spawned = false
local timers = {
    cameraNetworkUpdate = Timer.new(NETWORK_CAMERA_UPDATE_INTERVAL)
}

local isSprinting = false

UserInputService.MouseIconEnabled = false

-- TODO: actual input binding
local function spawn(character)
    spawned = true

    LocalCharacter:listenPlayer(Players.LocalPlayer)
    LocalCharacter:setTransparency(1)

    LocalCharacter.Controller = Movement.new(character)

    -- temporary input binding
    local function inputHandler(name, state, object)
        local boolState = state == Enum.UserInputState.Begin and true or false
        if name == "Aim" then
            WeaponManager:setState(WeaponManager.ViewportWeapon, "Aim", boolState)
        elseif name == "Fire" then
            WeaponManager:fire(WeaponManager.ViewportWeapon, boolState)
        elseif name == "Reload" and boolState then
            WeaponManager:reload(WeaponManager.ViewportWeapon)
        elseif name == "Sprint" then
            isSprinting = boolState
        elseif name == "debugPause" and boolState then
            debugPause = not debugPause
        elseif name == "debugLog" and boolState then
            Maid.info()
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
    ContextActionService:BindAction("Sprint", inputHandler, true, Enum.KeyCode.LeftShift)
    ContextActionService:BindAction("debugPause", inputHandler, true, Enum.KeyCode.P)
    ContextActionService:BindAction("debugLog", inputHandler, true, Enum.KeyCode.O)

    UserInputService.InputChanged:connect(inputChangedHandler)

    RunService.Stepped:connect(
        function(dt)
            LocalCharacter.Controller:update(dt, Camera.CFrame.LookVector)
        end
    )
end

-- network binds
local function route(packetType, ...)
    WeaponManager:route(packetType, ...)
end

NetworkLib:listenFor(
    Enums.PacketType.PlayerSpawn,
    function(id, char)
        if id == Players.LocalPlayer.UserId then
            spawn(char)
        end
    end
)

NetworkLib:listen(route)

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
        WeaponManager:step(dt, Camera, LocalCharacter.Velocity, isSprinting)
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
        if timers.cameraNetworkUpdate:tick(dt) then
            NetworkLib:send(Enums.PacketType.Look, Camera.User.LookVector)
        end
        debug.profilebegin("game-camera")
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        Camera.AttachTo = LocalCharacter:get() and LocalCharacter:get():FindFirstChild("Humanoid") or nil
        Camera:updateView(dt)
        debug.profileend("game-camera")
    end
)

RunService.Heartbeat:connect(function(dt)
    if debugPause then
        return
    end
    debug.profilebegin("game-projectilemanager")
    ProjectileManager:step(dt)
    debug.profilebegin("game-projectilemanager")
end)
