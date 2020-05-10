--[[
    description and purpose here

    please don't format document
--]]

local SWAY_SPEED = _G.WEAPON.SWAY_SPEED
local SWAY_AMPLIFY = _G.WEAPON.SWAY_AMPLIFY
local ADS_SWAY_MODIFIER = _G.WEAPON.ADS_SWAY_MODIFIER
local AIM_SPEED = _G.WEAPON.AIM_SPEED
local INERTIA_MODIFIER = _G.WEAPON.INERTIA_MODIFIER

-- micro-optimization for blank CFrames
local CF000 = CFrame.new()

-- make mount points so we can find things by string
local mount = require(shared.Common.Mount)
local PATH = {
    PARTICLES = mount(shared.Assets.Particles),
    WEAPON_MODELS = mount(shared.Assets.Weapons.Models),
    WEAPON_ANIMATIONS = mount(shared.Assets.Weapons.Animations),
    WEAPON_CONFIGURATIONS = mount(shared.Assets.Weapons.Configuration)
}

local Particle = require(shared.Common.Particle)
local Sound = require(shared.Common.Sound)
local Spring = require(shared.Common.Spring)
local Styles = require(shared.Common.Styles)
local SmallUtils = require(shared.Common.SmallUtils)

local lerp = SmallUtils.lerp

---Uses a value and makes a range based on v0 -+ range
---@param v0 number
---@param range number
local function springRange(v0, range)
    return SmallUtils.randomRange(v0 - range, v0 + range)
end

---@class Gun
local Gun = {}
Gun.__index = Gun

---Creates a new Gun class
---@param weapon any A string or ModuleScript instance of a gun configuration
function Gun.new(weapon, gamemode)
    -- make string to config by search or use config directly
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
    self.Ammo = {
        Loaded = config.Ammo.Max,
        Max = config.Ammo.Max,
        Reserve = config.Ammo.Reserve
    }

    self.AssetAnimations = PATH.WEAPON_ANIMATIONS(config.AnimationPath)

    -- states
    self.State = {
        Equipped = false,
        Aim = false,
        Cycling = false,
        Walk = false,
        Crouch = false,
        Prone = false,
        Obstructed = false,
        Movement = 0
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
    self._InterpolateSpeed = {
        Aim = (self.Configuration.InterpolateSpeed.Aim or 1) * AIM_SPEED
    }
    self._Springs = {
        ModelPositionRecoil = Spring.new(5, 100, 4),
        ModelRotationRecoil = Spring.new(5, 100, 4),
        Movement = Spring.new(),
        Inertia = Spring.new()
    }
    self._Particles = {}
    self._Sounds = {}

    -- Additional property data
    self.Animations = {} -- populate this table with our AnimationTrack class

    setmetatable(self, Gun)
    self:_init()

    return self
end

function Gun:_init()
    local modelMount = mount(self.ViewModel)
    for name, data in pairs(self.Configuration.Particles) do
        self._Particles[name] = Particle.new(PATH.PARTICLES(data.Path), modelMount(data.Parent))
    end

    for name, data in pairs(self.Configuration.Sounds) do
        self._Sounds[name] = Sound.new(data, {IsGlobal = true})
    end

    for _, part in pairs(self.ViewModel:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CastShadow = false
            part.Anchored = false
            part.Massless = true
        end
    end

    self.Handle.RootPriority = 100
    self.Handle.Anchored = true
end

---
---@param name string
function Gun:emitParticle(name)
    if not self._Particles[name] then
        warn("no particle called " .. name .. " in " .. self.Configuration.Name)
        return
    end

    self._Particles[name]:emit()
end

---
---@param name string
---@param range number
function Gun:playSound(name, range)
    if not self._Sounds[name] then
        warn("no sound called " .. name .. " in " .. self.Configuration.Name)
        return
    end

    -- TODO: fix dumb thing about having to refer to Instance itself

    -- if we have a "how many times can sound play at once" then use the
    -- playMultiple function instead
    if not range then
        self._Sounds[name].Instance:Play()
    else
        self._Sounds[name]:playMultiple(range)
    end
end

function Gun:setState(statesOrKey, state)
    if typeof(statesOrKey) == "string" then
        self.State[statesOrKey] = state
        return self.State
    end
    for key, value in pairs(statesOrKey) do
        self.State[key] = value
    end
    return self.State
end

function Gun:fire()
    if self.State.Cycling then
        return
    end

    self:setState("Cycling", true)
    self:emitParticle("Fire")
    self:playSound("Fire")

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

    self._Springs.ModelPositionRecoil:shove(x, y, z)
    self._Springs.ModelRotationRecoil:shove(pitch, yaw, roll)

    self:setState("Cycling", false)
end

function Gun:update(dt, pivot)
    local cfg = self.Configuration

    -- i want to add camera movement sway like when turning and stopping, inertia ig
    local inertiaX, inertiaY, inertiaZ = (
        CF000:lerp((self._lastPivot or pivot) * pivot:inverse(), INERTIA_MODIFIER)):ToOrientation()

    self._lastPivot = pivot
    self._Springs.Inertia:shove(inertiaX, inertiaY, inertiaZ)

    -- self._Springs.Walk:shove(
    --             math.sin(elapsedTime()*SWAY_SPEED)*SWAY_AMPLIFY,
    --             math.sin(elapsedTime()*SWAY_SPEED*2)*SWAY_AMPLIFY,
    --             0
    --         )

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
        spring:update(dt)
    end

    local swayCF =
        CFrame.new(
        math.sin(elapsedTime() * SWAY_SPEED) * SWAY_AMPLIFY * (lerp(1, ADS_SWAY_MODIFIER, self._InterpolateState.Aim)),
        math.sin(elapsedTime() * SWAY_SPEED * 2) * SWAY_AMPLIFY *
            (lerp(1, ADS_SWAY_MODIFIER, self._InterpolateState.Aim)),
        0
    )

    -- decide between aim down sight cf and grip CF
    local gripCF =
        cfg.Offset.Grip:lerp(CF000, Styles.quad(self._InterpolateState.Aim)) *
        CF000:lerp(cfg.Offset.Aim, Styles.quad(self._InterpolateState.Aim))

    -- bunch of CFrames

    local posRecoil = self._Springs.ModelPositionRecoil.Position
    local rotRecoil = self._Springs.ModelRotationRecoil.Position
    local inertia =  self._Springs.Inertia.Position

    local renderCF =
        pivot
        * gripCF
        * swayCF
        * CFrame.new(posRecoil)
        * CFrame.Angles(rotRecoil.x, rotRecoil.y, rotRecoil.z)
        * CFrame.Angles(inertia.X, inertia.Y, inertia.Z)

    self.ViewModel:SetPrimaryPartCFrame(renderCF)

    return renderCF
end

return Gun
