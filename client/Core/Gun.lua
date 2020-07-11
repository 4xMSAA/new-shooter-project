--[[
    description and purpose here

    please don't format document
--]]

local SWAY_SPEED = _G.WEAPON.SWAY_SPEED
local SWAY_AMPLIFY = _G.WEAPON.SWAY_AMPLIFY

local ADS_SWAY_MODIFIER = _G.WEAPON.ADS_SWAY_MODIFIER

local AIM_SPEED = _G.WEAPON.AIM_SPEED
local AIM_STYLE = _G.WEAPON.AIM_STYLE

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

local Animator = require(shared.Source.Animator)
local Particle = require(shared.Common.Particle)
local Sound = require(shared.Common.Sound)
local Spring = require(shared.Common.Spring)
local Styles = require(shared.Common.Styles)
local Emitter = require(shared.Common.Emitter)
local SmallUtils = require(shared.Common.SmallUtils)

local lerp = SmallUtils.lerp

---Uses a value and makes a range based on v0 -+ range
---@param v0 number
---@param range number
local function springRange(v0, range)
    return SmallUtils.randomRange(v0 - range, v0 + range)
end

---does pew pew
---
---@class Gun
local Gun = {}
Gun.__index = Gun

---Creates a new Gun class
---@param weapon any A string or ModuleScript instance of a gun configuration
---@param gamemode string configuration to use specific to a gamemode (zombies, PvP)
function Gun.new(weapon, gamemode)
    -- make string to config by search or use config directly
    -- TODO: load gamemode configurations if specified
    if typeof(weapon) == "string" then
        weapon = assert(PATH.WEAPON_CONFIGURATIONS(weapon), "did not find weapon " .. weapon)
    end

    local config = require(weapon)
    local model = PATH.WEAPON_MODELS(config.ModelPath):Clone()

    local self = {}

    -- properties
    self._assetName = weapon
    self.ViewModel = model
    self.Handle = self.ViewModel.PrimaryPart
    self.Configuration = config

    self.ActiveFireMode = config.FireMode[1]

    -- states
    self.State = {
        InitialEquip = true,
        Equipped = false,
        Aim = false,
        Cycling = false,
        Walk = false,
        Crouch = false,
        Prone = false,
        Obstructed = false,
        Movement = 0,

        Loaded = config.Ammo.Max,
        Max = config.Ammo.Max,
        Reserve = config.Ammo.Reserve
    }

    -- private states
    -- all states range from 0 to 1 for linear interpolation purposes
    self._InterpolateState = {
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
        Aim = (self.Configuration.InterpolateSpeed.Aim or 1) * AIM_SPEED
    }
    -- default spring values: 5, 50, 4, 4
    -- mass, force, dampening, speed
    self._Springs = {
        ModelPositionRecoil = Spring.new(5, 150, 4*RECOIL_POSITION_DAMPENING, 4*RECOIL_POSITION_SPEED),
        ModelRotationRecoil = Spring.new(5, 150, 4*RECOIL_ANGULAR_DAMPENING, 4*RECOIL_ANGULAR_SPEED),
        Movement = Spring.new(20, 50, 4, 4*MOVEMENT_RECOVERY_SPEED),
        Inertia = Spring.new(5, 50, 4, 4*INERTIA_RECOVERY_SPEED)
    }
    self._Emitter = {
        Equip = Emitter.new(),
        Unequip = Emitter.new(),
        Fired = Emitter.new(),
    }
    self._Particles = {}
    self._Sounds = {}
    self._Lock = {}
    self._Connnections = {}

    -- additional property data
    self.Animations = {}

    setmetatable(self, Gun)
    self:_init()

    return self
end

---
---@private
---@return Gun Returns itself. Useful for chaining
function Gun:_init()

    -- load the animations
    self.Animator = Animator.new(self.ViewModel)
    self._cameraJoint = Instance.new("Motor6D")
    self._gripJoint = Instance.new("Motor6D")

    local jointRemap = function(joint, pose)
        if pose.Name == "Handle" then
            return self._gripJoint, pose
        elseif pose.Name == "Camera" then
            return self._cameraJoint, pose
        end
        -- not returning anything defaults behaviour
    end

    local animations = PATH.WEAPON_ANIMATIONS(self.Configuration.AnimationPath)
    for _, animation in pairs(animations:GetChildren()) do
        self.Animations[animation.Name] = self.Animator:loadAnimation(animation, jointRemap)
    end

    -- mount the model to apply particle effects
    local modelMount = mount(self.ViewModel)
    for name, data in pairs(self.Configuration.Particles) do
        self._Particles[name] = Particle.new(PATH.PARTICLES(data.Path), modelMount(data.Parent))
    end

    -- give sounds
    for name, data in pairs(self.Configuration.Sounds) do
        self._Sounds[name] = Sound.new(data, {IsGlobal = true})
    end

    -- hook sounds to animations
    self._Connnections.Reload = self.Animations.Reload.MarkerReached:connect(function(markerName, ...)
        if self._Sounds[markerName] then
            self:playSound(markerName)
        end
    end)

    -- in case we forget to prepare the model, do some preparing ourselves
    for _, part in pairs(self.ViewModel:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CastShadow = false
            part.Anchored = false
            part.Massless = true
        end
    end

    -- joints are weird, so rootpriority helps decide which is the real "pivot"
    self.Handle.RootPriority = 100
    self.Handle.Anchored = true

    return self
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

---
---@param name string
---@param range number
function Gun:playSound(name, range)
    if not self._Sounds[name] then
        warn("no sound named " .. name .. " in " .. self.Configuration.Name)
        return self
    end

    -- TODO: fix dumb sound thing about having to refer to Instance itself

    -- if we have a "how many times can sound play at once" then use the
    -- playMultiple function instead
    if not range then
        self._Sounds[name].Instance:Play()
    else
        self._Sounds[name]:playMultiple(range)
    end
    return self
end

function Gun:setState(statesOrKey, state)
    if typeof(statesOrKey) == "string" then
        self.State[statesOrKey] = state
        return self
    end
    for key, value in pairs(statesOrKey) do
        self.State[key] = value
    end
    return self
end

---
function Gun:equip()
    self:setState("Equipped", true)
    self.Animations.Idle:play()
end

---
---@return Emitter An emitter to listen to for "done" event
function Gun:unequip()
    self:setState("Equipped", false)
    return self._Emitter.Unequip
end

---
function Gun:reload()
    if self._Lock.Reload then return end

    self._Lock.Reload = true
    self.Animations.Reload:play()

    self.Animations.Reload.MarkerReached:once("Reload", function()
        -- TODO: actual ammo counting and subtraction
        self:setState("Loaded", self.State.Max)
    end)

    self.Animations.Reload.Stopped:once(nil, function()
        self._Lock.Reload = false
    end)
end

---
---@return boolean Did the gun fire or not?
function Gun:fire()
    if (self._Lock.Fire or 0) + 60/self.Configuration.RPM > elapsedTime() then return end
    if self.State.Cycling or self.State.Loaded <= 0 then return end
    if self._Lock.Reload then return end

    self._Emitter.Fired:emit("success")


    self._Lock.Fire = elapsedTime()

    self:setState("Cycling", true):emitParticle("Fire"):playSound("Fire")

    self:setState("Loaded", self.State.Loaded - 1)

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

    return true
end

---Returns the Camera's expected CFrame from an animation
function Gun:getExpectedCameraCFrame()
    return self._cameraJoint.Transform
end

---
---@param dt number Delta time since last frame
---@param pivot userdata CFrame  at which the gun should be located at
function Gun:update(dt, pivot)
    local cfg = self.Configuration

    -- update spring forces
    local inertiaX, inertiaY, inertiaZ = (
        CF000:lerp((self._lastPivot or pivot) * pivot:inverse(), INERTIA_MODIFIER)):ToOrientation()

        self._lastPivot = pivot
        self._Springs.Inertia:shove(inertiaX, inertiaY, inertiaZ)

        self._Springs.Movement:shove(
            math.sin(elapsedTime()*MOVEMENT_SPEED)*MOVEMENT_AMPLIFY*math.min(1, self.State.Movement),
            math.sin(elapsedTime()*MOVEMENT_SPEED*2)*MOVEMENT_AMPLIFY*math.min(1, self.State.Movement),
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

    -- update InterpolateStates and Springs
    for state, value in pairs(self.State) do
        if self._InterpolateState[state] then
            -- clamp value between 0 and 1 with max and min selectors
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
    for _, spring in pairs(self._Springs) do
        spring:update(math.min(1, dt))
    end

    -- update special events
    if self._InterpolateState.Equipped == 0 then
        self._Emitter.Unequip:emit("done")
    elseif self._InterpolateState.Equipped == 1 then
        self._Emitter.Equip:emit("done")
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

    -- position the weapon
    local renderCF =
        pivot
        * gripCF
        * CFrame.new(inertia.Y/3, inertia.X/3, 0)
        * self._gripJoint.Transform
        * swayCF
        * movementCF
        * CFrame.new(posRecoil)
        * CFrame.Angles(rotRecoil.x, rotRecoil.y, rotRecoil.z)
        * CFrame.Angles(-inertia.X, inertia.Y, 0)

    self.ViewModel:SetPrimaryPartCFrame(renderCF)

    return renderCF
end

return Gun
