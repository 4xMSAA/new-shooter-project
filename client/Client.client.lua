_G.Client = script.Parent

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
require(ReplicatedStorage.Source:WaitForChild("Environment"))

local NETWORK_CAMERA_UPDATE_INTERVAL = _G.INTERVALS.NETWORK.CAMERA_UPDATE

local GameEnum = shared.GameEnum

local NetworkLib = require(shared.Common.NetworkLib)
local Maid = require(shared.Common.Maid)
local Timer = require(shared.Common.Timer)

local DefaultSettings = shared.DefaultSettings

local Input = require(_G.Client.Core.Input)
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
local EquipManager = require(_G.Client.Game.Managers.EquipManager).new()

local debugPause = false
local spawned = false
local timers = {
    cameraNetworkUpdate = Timer.new(NETWORK_CAMERA_UPDATE_INTERVAL)
}


UserInputService.MouseIconEnabled = false
LocalCharacter.listenPlayer(Players.LocalPlayer)

-- TODO: actual input binding
local function spawn(character, lookAt)
    LocalCharacter.setTransparency(1)
    if lookAt then
        Camera:setUserLook(lookAt)
    end

    LocalCharacter.Controller = Movement.new(character)
    local SprintModule = LocalCharacter.Controller:loadModule(Movement.Modules.Sprint)
    local AimModule = LocalCharacter.Controller:loadModule(Movement.Modules.ADS)



    local function mouseMove(_, _, delta)
        Camera:moveLook(delta.x, delta.y)
    end
    local function aim(_, state, _, object)
        WeaponManager:setState(WeaponManager.ViewportWeapon, "Aim", state)
    end
    local function fire(_, state)
        WeaponManager:fire(WeaponManager.ViewportWeapon, state)
    end
    local function reload(_, state)
        if not state then return end
        WeaponManager:reload(WeaponManager.ViewportWeapon)
    end
    local function sprint(_, state)
        SprintModule.Sprint = state
    end
    local function debugPauseKey(_, state)
        if not state then return end
        debugPause = not debugPause
    end
    local function debugLog(_, state)
        if not state then return end
        Maid.info()
    end

    local Settings = DefaultSettings
    Input.bind("camera.move", Enum.UserInputType.MouseMovement).listenFor("camera.move", mouseMove)
    Input.bind("movement.sprint", Settings.Controls.Movement.Sprint).listenFor("movement.sprint", sprint)
    
    Input.bind("combat.aim", Settings.Controls.Combat.Aim).listenFor("combat.aim", aim)
    Input.bind("combat.reload", Settings.Controls.Combat.Reload).listenFor("combat.reload", reload)
    Input.bind("combat.fire", Settings.Controls.Combat.Fire).listenFor("combat.fire", fire)
    Input.bind("debug.pause", Settings.Controls.Debug.Pause).listenFor("debug.pause", debugPauseKey)

    for slot, inputs in pairs(Settings.Controls.Action) do
        Input.bind("action." .. tostring(slot):lower(), inputs)
    end
    
    -- probably tell the client which binds they have or something? idk...
    local weaponOrder = {
        GameEnum.BindingSlot.Primary, GameEnum.BindingSlot.Secondary
    }

    local weapons = WeaponManager:getByOwner(Players.LocalPlayer)
    local i = 0
    for uuid, weapon in pairs(weapons) do
        i = i + 1
        EquipManager:bind(WeaponManager:makeEquipable(weapon), weaponOrder[i])
    end
    
    EquipManager:listen()

    RunService.Stepped:connect(
        function(_, dt)
            LocalCharacter.Controller:update(dt, Camera.CFrame.LookVector)
        end
    )

    spawned = true
end

-- network binds
local function route(packetType, ...)
    WeaponManager:route(packetType, ...)
end

NetworkLib:listenFor(
    GameEnum.PacketType.PlayerSpawn,
    function(id, char, lookAt)
        if id == Players.LocalPlayer.UserId then
            spawn(char, lookAt)
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

        debug.profilebegin("game-weaponmanager")
        WeaponManager:step(dt, Camera, LocalCharacter.Controller)
        debug.profileend("game-weaponmanager")
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
            NetworkLib:send(GameEnum.PacketType.Look, Camera.User.LookVector)
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
