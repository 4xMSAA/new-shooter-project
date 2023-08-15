local GameEnum = shared.GameEnum
local Maid = require(shared.Common.Maid)
local NetworkLib = require(shared.Common.NetworkLib)
local log, logwarn = require(shared.Common.Log)(script:GetFullName())
local SmallUtils = require(shared.Common.SmallUtils)

local Input = require(_G.Client.Core.Input)

---All equipables should have a function for equip and unequipping them
---@class EquipManager
local EquipManager = {}
EquipManager.__index = EquipManager

EquipManager.SlotToBinding = {
    [GameEnum.BindingSlot.Primary] = "action.primary",
    [GameEnum.BindingSlot.Secondary] = "action.secondary",
    [GameEnum.BindingSlot.Tertiary] = "action.tertiary",
    [GameEnum.BindingSlot.Melee] = "action.melee",
    [GameEnum.BindingSlot.Grenade] = "action.throwable",
    [GameEnum.BindingSlot.UtilityGrenade] = "action.utilityThrowable",
}

function EquipManager.new()
    local self = {
        _connections = {},
        Equipables = {}
    }

    setmetatable(self, EquipManager)
    Maid.watch(self)
    return self
end

function EquipManager:destroy()
    
end

function EquipManager:bind(equipable, slot)
    if self.Equipables[slot] then 
        log(2, "overwriting slot " .. slot.Name .. " with " .. equipable)
    end

    self.Equipables[slot] = equipable
end

function EquipManager:clear()
    for slot, item in pairs(self.Equipables) do
        self.Equipables[slot] = nil
    end
    for _, conn in pairs(self._connections) do
        conn:disconnect()
    end
end

function EquipManager:equip(slot)
    if not self.Equipables[slot] then error("no equipable on slot " .. tostring(slot), 2) end
    log(2, "equipping", self.Equipables[slot], "in slot", slot)
    self.Equipables[slot]:equip()
end

function EquipManager:listen()
    for slot, bind in pairs(EquipManager.SlotToBinding) do
        local conn = Input.listenFor(bind, function(_, state) if state then self:equip(slot) end end)
        table.insert(self._connections, conn)
    end
end


return EquipManager
