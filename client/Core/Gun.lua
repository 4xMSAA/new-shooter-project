--[[
    Make
]]

---@class Gun
local Gun = {}
Gun.__index = Gun


---
---@param weapon any A string or ModuleScript instance of a gun configuration
function Gun.new(weapon)
    -- make string to config by search or use config directly
    if typeof(weapon) == "string" then
        weapon = assert(
            shared.Assets.Weapons.Configuration:FindFirstChild(weapon),
            "did not find weapon " .. weapon
        )
    end

    local config = require(weapon)
    local model = shared.Assets.Weapons.Models:FindFirstChild(config.ModelPath)

    local self = {}

    -- properties
    self.ViewModel = model:Clone()
    self.Configuration = config

    -- states
    self.Equipped = false

    self.FireMode = config.FireMode[1]
    self.Ammo = {
        Loaded = config.Ammo.Max,
        Max = config.Ammo.Max,
        Reserve = config.Ammo.Reserve
    }

    -- private states
    -- all states range from 0 to 1 for linear interpolation purposes
    self._InterpolateStates = {}
    self._InterpolateStates.Aim = 0
    self._InterpolateStates.Equip = 0
    self._InterpolateStates.Unequip = 0
    self._InterpolateStates.Crouch = 0
    self._InterpolateStates.Prone = 0
    self._InterpolateStates.Obstruct = 0

    self._Springs = {}

    -- Additional property data
    self.Animations = {} -- populate this table with our AnimationTrack class

    setmetatable(self, Gun)
    return self
end