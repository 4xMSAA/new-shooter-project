local SWAY_SPEED = _G.WEAPON.SWAY_SPEED
local SWAY_AMPLIFY = _G.WEAPON.SWAY_AMPLIFY

local ADS_SWAY_MODIFIER = _G.WEAPON.ADS_SWAY_MODIFIER

local AIM_SPEED = _G.WEAPON.AIM_SPEED
local AIM_STYLE = _G.WEAPON.AIM_STYLE

local SPRINT_SPEED = _G.WEAPON.SPRINT_SPEED
local SPRINT_STYLE = _G.WEAPON.SPRINT_STYLE

local MOVEMENT_AMPLIFY = _G.WEAPON.MOVEMENT_AMPLIFY
local MOVEMENT_SPEED = _G.WEAPON.MOVEMENT_SPEED
local MOVEMENT_RECOVERY_SPEED = _G.WEAPON.MOVEMENT_RECOVERY_SPEED
local ADS_MOVEMENT_MODIFIER = _G.WEAPON.ADS_MOVEMENT_MODIFIER

local INERTIA_MODIFIER = _G.WEAPON.INERTIA_MODIFIER
local INERTIA_RECOVERY_SPEED = _G.WEAPON.INERTIA_RECOVERY_SPEED

local RECOIL_POSITION_DAMPENING = _G.WEAPON.RECOIL_POSITION_DAMPENING
local RECOIL_POSITION_SPEED = _G.WEAPON.RECOIL_POSITION_SPEED

local RECOIL_ANGULAR_DAMPENING = _G.WEAPON.RECOIL_ANGULAR_DAMPENING
local RECOIL_ANGULAR_SPEED = _G.WEAPON.RECOIL_ANGULAR_SPEED


-- micro-optimization for blank CFrames
local CF000 = CFrame.new()

-- make mount points so we can find things by string (separator is /)
local mount = require(shared.Common.Mount)
local PATH = {
    PARTICLES = mount(shared.Assets.Particles),
    WEAPON_MODELS = mount(shared.Assets.Weapons.Models),
    WEAPON_ANIMATIONS = mount(shared.Assets.Weapons.Animations),
    WEAPON_CONFIGURATIONS = mount(shared.Assets.Weapons.Configuration)
}

local Enums = shared.Enums

local Animator = require(shared.Source.Animator)
local Particle = require(shared.Common.Particle) -- TODO: change particle to particlemanager
local Sound = require(shared.Common.Sound)
local Spring = require(shared.Common.Spring)
local Styles = require(shared.Common.Styles)
local Emitter = require(shared.Common.Emitter)
local SmallUtils = require(shared.Common.SmallUtils)
local TableUtils = require(shared.Common.TableUtils)

local Maid = require(shared.Common.Maid)

local lerp = SmallUtils.lerp

---Uses a value and makes a range based on v0 -+ range
---@param v0 number
---@param range number
local function springRange(v0, range)
    return SmallUtils.randomFloatRange(v0 - range, v0 + range)
end

---does pew pew
---
---@class Gun
local Gun = {}
Gun.__index = Gun

---Creates a new Gun class
---@param weapon any A string or ModuleScript instance of a gun configuration
---@param gamemode string use configuration specific to a gamemode
function Gun.new(weapon, gamemode)
    assert(type(gamemode) == "string", "gamemode must be specified on creation for object by name of " .. weapon)

    -- make string to config by search or use config directly
    if typeof(weapon) == "string" then
        weapon = assert(PATH.WEAPON_CONFIGURATIONS(weapon), "did not find weapon " .. weapon)
    end

    local config = require(weapon:Clone()) -- don't alter the original module
    local model = PATH.WEAPON_MODELS(config.ModelPath):Clone()

    -- overwrite config values with gamemode specific ones
    assert(config.Gamemode[gamemode], "gamemode " .. gamemode .. " is not a valid configuration for this weapon")
    TableUtils.recursiveOverwrite(config.Gamemode[gamemode], config)


    local self = {}

    -- properties
    self._assetName = weapon.Name
    self.ViewModel = model
    self.Handle = self.ViewModel.PrimaryPart
    self.Configuration = config
    self.ActiveFireMode = config.FireMode[1]

    self.StateChanged = Emitter.new()

    -- states
    self.State = {
        InitialEquip = true,
        Equipped = false,
        Aim = false,
        Cycling = false,
        Sprint = false,
        Walk = false,
        Crouch = false,
        Prone = false,
        Obstructed = false,
        Movement = 0,

        Loaded = config.Ammo.Max,
        Max = config.Ammo.Max,
        Reserve = config.Ammo.Reserve,
        Chambered = false
    }

    -- private states
    -- all states range from 0 to 1 for linear interpolation purposes
    self._InterpolateState = {
        Sprint = 0,
        Aim = 0,
        Equip = 0,
        Unequip = 0,
        Crouch = 0,
        Prone = 0,
        Obstructed = 0
    }
    -- prioritized state overrides that don't affect the inputted state
    self._StateOverride = {}

    self._InterpolateSpeed = {
        Aim = (self.Configuration.InterpolateSpeed.Aim or 1) * AIM_SPEED,
        Sprint = (self.Configuration.InterpolateSpeed.Sprint or 1) * SPRINT_SPEED
    }
    

    -- default spring values: 5, 50, 4, 4
    -- mass, force, dampening, speed
    self._Springs = {
        ModelPositionRecoil = Spring.new(5, 150, 4*RECOIL_POSITION_DAMPENING, 4*RECOIL_POSITION_SPEED),
        ModelRotationRecoil = Spring.new(5, 150, 4*RECOIL_ANGULAR_DAMPENING, 4*RECOIL_ANGULAR_SPEED),
        Movement = Spring.new(20, 50, 4, 4*MOVEMENT_RECOVERY_SPEED),
        Inertia = Spring.new(5, 50, 4, 4*INERTIA_RECOVERY_SPEED)
    }

    self.Events = {
        Equip = Emitter.new(),
        Unequip = Emitter.new(),
        Fired = Emitter.new(),
    }

    self._Particles = {}
    self._Sounds = {}
    self._Lock = {}
    self._Connections = {}

    -- additional property data
    self.Animations = {}

    setmetatable(self, Gun)

    Maid.watch(self)

    return self:_init()
end

---
---@private
---@return Gun Returns itself. Useful for chaining
function Gun:_init()

    -- load the animation necessities
    self.Animator = Animator.new(self.ViewModel)
    self._cameraJoint = Instance.new("Motor6D")
    self._gripJoint = Instance.new("Motor6D")

    local animations = PATH.WEAPON_ANIMATIONS(self.Configuration.AnimationPath)
    for _, animation in pairs(animations:GetChildren()) do
        self.Animations[animation.Name] = self.Animator:loadAnimation(animation, function(_, pose)
            -- remap some vital joint names to our alternatives
            if pose.Name == "Handle" then
                return self._gripJoint, pose
            elseif pose.Name == "Camera" then
                return self._cameraJoint, pose
            end
            -- not returning anything defaults behaviour
        end)
    end

    -- mount the model to apply particle effects
    self._ModelMount = mount(self.ViewModel)
    for name, data in pairs(self.Configuration.Particles) do
        assert(data.Path, "path to particle does not exist for " .. tostring(name) .. " in " .. tostring(self._assetName))
        self._Particles[name] = Particle.new(PATH.PARTICLES(data.Path), self._ModelMount(data.Parent))
    end

    -- give sounds
    for name, data in pairs(self.Configuration.Sounds) do
        self._Sounds[name] = Sound.new(data, {IsGlobal = true})
    end

    -- hook sounds to animations
    local function markerToSound(markerName, ...)
        if self._Sounds[markerName] then
            self:playSound(markerName)
        end
    end

    local function connectAnimationEvents(name)
        if not self.Animations[name] then 
            warn("Missing animation " .. name .. " from " .. self.Configuration.Name .. " for function connectAnimationEvents") 
            return 
        end

        self._Connections[name] = self.Animations[name].MarkerReached:connect(markerToSound)
    end

    local function reloadEvents(name)
        if not self.Animations[name] then 
            warn("Missing animation " .. name .. " from " .. self.Configuration.Name .. " for function reloadEvents") 
            return 
        end

        self.Animations[name].MarkerReached:on("Reload", function()
            -- TODO: actual ammo counting and subtraction

            local subtractAmmo = self.State.Max - self.State.Loaded

            self:setState("Loaded", self.State.Max)
        end)

        self.Animations[name].MarkerReached:on("Chamber", function()
            self:setState("Chambered", true)
        end)
    
        self.Animations[name].Stopped:on(nil, function()
            self._Lock.Reload = false
        end)
    end

    connectAnimationEvents("Reload")
    connectAnimationEvents("DryReload")
    connectAnimationEvents("Equip")
    connectAnimationEvents("Unequip")

    reloadEvents("Reload")
    reloadEvents("DryReload")


    -- in case we forget to prepare the model in the editor,
    -- do some preparing ourselves
    for _, part in pairs(self.ViewModel:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CastShadow = false
            part.Anchored = false
            part.Massless = true
        end
    end

    -- joints are weird, so RootPriority helps decide which is the real "pivot"
    self.Handle.RootPriority = 100
    self.Handle.Anchored = true

    return self
end

---
---@param gun Gun
---@param emitter Emitter
local function unequipGun(gun, emitter)
    emitter:emit("DONE")
end

---
function Gun:equip()
    self:setState("Equipped", true)
    self.Animations.Idle:play()
end

---
---@return Emitter UnequipEmitter An emitter to listen to for "done" event
function Gun:unequip()
    self:setState("Equipped", false)
    coroutine.wrap(unequipGun)(self, self.Events.Unequip)
    return self.Events.Unequip
end

---
---@param name string
function Gun:emitParticle(name)
    if not self._Particles[name] then
        warn("no particle named " .. name .. " in " .. self.Configuration.Name)
        return
    end

    self._Particles[name]:emit()
    return self
end

---Play a sound that was given from the Configuration module of the gun
---@param name string Name of the sound to be played
---@param range number How many instances of the same sound can play at the same time
function Gun:playSound(name, range)
    if not self._Sounds[name] then
        warn("no sound named " .. name .. " in " .. self.Configuration.Name)
        return self
    end

    if not range then
        self._Sounds[name]:play()
    else
        self._Sounds[name]:playMultiple(range)
    end
    return self
end

function Gun:setState(property, value)
    if self.State[property] and self.State[property] ~= value then
        self.StateChanged:emit(property, self.State[property])
    end

    self.State[property] = value
    return self
end


---
function Gun:reload()
    if self._Lock.Reload then return end

    self._Lock.Reload = true
    
    local reloadType = self.Chambered and "Reload" or "DryReload"
    self.Animations[reloadType]:play()
end

---Fires the gun and emits `FIRE` on success or `SAFETY`, `CYCLING`, 
---`EMPTY` or `RELOADING` on failure.  
---@return boolean DidFire, string Reason Returns whether the gun fire or not.
function Gun:fire()
    if self.ActiveFireMode == Enums.FireMode.Safety then
        self.Events.Fired:emit("SAFETY")
        return false, "SAFETY"
    end

    if (self._Lock.Fire or 0) + 60/self.Configuration.RPM > elapsedTime() or self.State.Cycling then
        self.Events.Fired:emit("CYCLING")
        return false, "CYCLING"
    end
    if self.State.Loaded <= 0 then
        self.Events.Fired:emit("EMPTY")
        return false, "EMPTY"
    end
    if self._Lock.Reload then
        self.Events.Fired:emit("RELOADING")
        return false, "RELOADING"
    end

    self.Events.Fired:emit("FIRE")

    self._Lock.Fire = elapsedTime()

    self:setState("Cycling", true):emitParticle("Fire"):playSound("Fire", 7)

    self:setState("Loaded", math.max(0, self.State.Loaded - 1))

    -- viewmodel recoil
    local recoil = self.Configuration.Recoil
    local posRange = recoil.Position.Range
    local posV = recoil.Position.V3
    local x, y, z =
        springRange(posV.x, posRange.x),
        springRange(posV.y, posRange.y),
        springRange(posV.z, posRange.z)
    local rotRange = recoil.Rotation.Range
    local rotV = recoil.Rotation.V3
    local pitch, yaw, roll =
        springRange(rotV.x, rotRange.x),
        springRange(rotV.y, rotRange.y),
        springRange(rotV.z, rotRange.z)

    if recoil.Rotation.AllowSignedY then
        yaw = (math.random() > 0.5 and -yaw) or yaw
    end

    -- apply spring updates
    self._Springs.ModelPositionRecoil:shove(x, y, z)
    self._Springs.ModelRotationRecoil:shove(pitch, yaw, roll)

    self.Animations.Fire:play()

    self:setState("Cycling", false)

    if self.State.Loaded == 0 then
        self:setState("Chambered", false)
    end

    return true
end

---Returns the Camera's expected CFrame from an animation
function Gun:getExpectedCameraCFrame()
    return self._cameraJoint.Transform
end

---
---@param dt number Delta time since last frame
---@param pivot userdata CFrame at which the gun should be located at
function Gun:update(dt, pivot)
    local cfg = self.Configuration

    -- update spring forces
    local inertiaX, inertiaY, inertiaZ = (
        CF000:lerp((self._lastPivot or pivot) * pivot:inverse(), INERTIA_MODIFIER)):ToOrientation()

        self._lastPivot = pivot
        self._Springs.Inertia:shove(inertiaX, inertiaY, inertiaZ)

        self._Springs.Movement:shove(
            math.sin(elapsedTime()*MOVEMENT_SPEED)*MOVEMENT_AMPLIFY*math.min(1, self.State.Movement/12)*(dt*60),
            math.sin(elapsedTime()*MOVEMENT_SPEED*2)*MOVEMENT_AMPLIFY*math.min(1, self.State.Movement/12)*(dt*60),
            0
        )

    local swayCF =
        CFrame.new(
            math.sin(elapsedTime() * SWAY_SPEED) * SWAY_AMPLIFY * (lerp(1, ADS_SWAY_MODIFIER, self._InterpolateState.Aim)),
            math.sin(elapsedTime() * SWAY_SPEED * 2) * SWAY_AMPLIFY *
                lerp(1, ADS_SWAY_MODIFIER, Styles[AIM_STYLE](self._InterpolateState.Aim)),
            0
        )
    local inertia = self._Springs.Inertia.Position

    -- update InterpolateStates
    for state, value in pairs(self.State) do
        if self._InterpolateState[state] then
            self._InterpolateState[state] =
                math.min(
                    1,
                math.max(
                    0,
                    self._InterpolateState[state] + (value and dt or -dt) * (self._InterpolateSpeed[state] or 1)
                )
            )
        end
    end

    -- update springs
    for _, spring in pairs(self._Springs) do
        spring:update(math.min(1, dt))
    end

    -- update special events
    if self._InterpolateState.Equipped == 0 then
        self.Events.Unequip:emit("done")
    elseif self._InterpolateState.Equipped == 1 then
        self.Events.Equip:emit("done")
    end

    -- decide between aim down sight cf and grip CF
    local gripCF =
        cfg.Offset.Grip:lerp(CF000, Styles[AIM_STYLE](self._InterpolateState.Aim)) *
        CF000:lerp(cfg.Offset.Aim, Styles[AIM_STYLE](self._InterpolateState.Aim))

    local movementCF =
        CF000:lerp(
            CFrame.new(self._Springs.Movement.Position),
            lerp(1, ADS_MOVEMENT_MODIFIER, Styles[AIM_STYLE](self._InterpolateState.Aim))
        )

    -- bunch of recoil CFrames
    local posRecoil = self._Springs.ModelPositionRecoil.Position * (lerp(1,  cfg.Recoil.AimScale, self._InterpolateState.Aim))
    local rotRecoil = self._Springs.ModelRotationRecoil.Position * (lerp(1,  cfg.Recoil.AimScale, self._InterpolateState.Aim))

    local sprintCF =
        CF000:lerp(
            cfg.Offset.Sprint,
            Styles[SPRINT_STYLE](self._InterpolateState.Sprint)
    )

    -- position the weapon
    local renderCF =
        pivot
        * gripCF
        * CFrame.new(inertia.Y/3, inertia.X/3, 0)
        * self._gripJoint.Transform
        * swayCF
        * movementCF
        * sprintCF
        * CFrame.new(posRecoil)
        * CFrame.Angles(rotRecoil.x, rotRecoil.y, rotRecoil.z)
        * CFrame.Angles(-inertia.X, inertia.Y, 0)

    self.ViewModel:SetPrimaryPartCFrame(renderCF)

    return renderCF
end

return Gun
