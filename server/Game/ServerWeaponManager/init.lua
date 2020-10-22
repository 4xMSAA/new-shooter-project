---Server-side weapon manager to handle routing of all weapons
---@class ServerWeaponManager
local Maid = require(shared.Common.Maid)
local ServerWeaponManager = {}
ServerWeaponManager.__index = ServerWeaponManager

function ServerWeaponManager.new()
    local self = {}


    setmetatable(self, ServerWeaponManager)
    Maid.watch(self)
    return self
end