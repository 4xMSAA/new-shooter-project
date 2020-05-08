--[[
    description and purpose here
--]]
local SWAY_SPEED = _G.WEAPON.SWAY_SPEED
local SWAY_AMPLIFY = _G.WEAPON.SWAY_AMPLIFY
local ADS_SWAY_MODIFIER = _G.WEAPON.ADS_SWAY_MODIFIER
local AIM_SPEED = _G.WEAPON.AIM_SPEED

local CF000 = CFrame.new()

local Spring = require(shared.Common.Spring)
local SmallUtils = require(shared.Common.SmallUtils)

local lerp = SmallUtils.lerp

local function springRange(v0, range)
    if v0 == 0 then
        return 0
    end
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
        weapon = assert(shared.Assets.Weapons.Configuration:WaitForChild(weapon, 5), "did not find weapon " .. weapon)
    end

    local config = require(weapon)
    local model = shared.Assets.Weapons.Models:WaitForChild(config.ModelPath, 5):Clone()

    local self = {}
    -- properties
    self.ViewModel = model
    self.Handle = self.ViewModel.PrimaryPart
    self.Configuration = config

    -- states
    self.State = {
        Equipped = false,
        Aim = false,
        Obstructed = false,
        Cycling = false,
        Walk = false,
        Movement = 0
    }

    self.ActiveFireMode = config.FireMode[1]
    self.Ammo = {
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
    self._InterpolateSpeed = {
        Aim = (self.Configuration.InterpolateSpeed.Aim or 1) * AIM_SPEED
    }

    self._Springs = {
        ModelPositionRecoil = Spring.new(),
        ModelRotationRecoil = Spring.new(),
        Movement = Spring.new()
    }

    self.AssetAnimations = shared.Assets.Weapons.Animations:FindFirstChild(config.AnimationPath)
    -- Additional property data
    self.Animations = {} -- populate this table with our AnimationTrack class

    setmetatable(self, Gun)
    self:_init()

    return self
end

function Gun:_init()
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

    local posRange = self.Configuration.Recoil.Position.Range
    local posV = self.Configuration.Recoil.Position.V3
    local x, y, z =
        springRange(posV.x, posRange.x),
        springRange(posV.y, posRange.y),
        springRange(posV.z, posRange.z)

    local rotRange = self.Configuration.Recoil.Rotation.Range
    local rotV = self.Configuration.Recoil.Rotation.V3
    local pitch, yaw, roll =
        springRange(rotV.x, rotRange.x),
        springRange(rotV.y, rotRange.y),
        springRange(rotV.z, rotRange.z)

    if self.Configuration.Recoil.Rotation.AllowSignedY then
        yaw = math.random() > 0.5 and -yaw or yaw
    end

    self._Springs.ModelPositionRecoil:shove(x, y, z)
    self._Springs.ModelRotationRecoil:shove(pitch, yaw, roll)

    self:setState("Cycling", false)
end

function Gun:update(dt, pivot)
    local cfg = self.Configuration

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
        cfg.Offset.Grip:lerp(CF000, self._InterpolateState.Aim) * CF000:lerp(cfg.Offset.Aim, self._InterpolateState.Aim)

    -- bunch of CFrames

    local posRecoil = self._Springs.ModelPositionRecoil.Position
    local rotRecoil = self._Springs.ModelRotationRecoil.Position

    local renderCF =
        pivot * gripCF * swayCF * CFrame.new(posRecoil) * CFrame.Angles(rotRecoil.x, rotRecoil.y, rotRecoil.z)

    self.ViewModel:SetPrimaryPartCFrame(renderCF)

    return renderCF
end

return Gun
