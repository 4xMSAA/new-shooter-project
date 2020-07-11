---Server-side weapon manager to handle routing of all weapons
---@class ServerWeaponManager
local ServerWeaponManager = {}
ServerWeaponManager.__index = ServerWeaponManager

function ServerWeaponManager.new()
    local self = {}


    setmetatable(self, ServerWeaponManager)
    return self
end