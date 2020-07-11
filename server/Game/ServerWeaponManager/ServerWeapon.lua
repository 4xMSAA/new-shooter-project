---Serverside Weapon class for server-enforcement
---@class ServerWeapon
local ServerWeapon = {}
ServerWeapon.__index = ServerWeapon

function ServerWeapon.new(weaponModule)
    local self = {}


    setmetatable(self, ServerWeapon)
    return self
end