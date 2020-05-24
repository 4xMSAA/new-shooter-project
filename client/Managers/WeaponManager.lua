local Emitter = require(shared.Common.Emitter)

---Manages all weapons in a single container
---@class WeaponManager
local WeaponManager = {}
WeaponManager.__index = WeaponManager

function WeaponManager.new()
    local self = {}
    self.Weapons = {}

    self.Connections = {}
    self.Connections.Characters = {}
    self.Connections.Viewport = nil

    setmetatable(self, WeaponManager)
end

function WeaponManager:register(weapon)
    table.insert(self.ActiveWeapons, weapon)
    return WeaponManager
end
