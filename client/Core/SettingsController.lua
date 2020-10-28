local Maid = require(shared.Common.Maid)

---Watches over configurable settings and updates the values associated with the setting
---@class SettingsController
local SettingsController = {}
SettingsController.__index = SettingsController

---@param tree table A settings tree to watch over
function SettingsController.new(tree)
    local self = {}


    setmetatable(self, SettingsController)
    Maid.watch(self)
    return self
end