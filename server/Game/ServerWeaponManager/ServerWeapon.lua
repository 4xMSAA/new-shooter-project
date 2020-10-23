local Maid = require(shared.Common.Maid)

---Serverside Weapon class for server-enforcement
---@class ServerWeapon
local ServerWeapon = {}
ServerWeapon.__index = ServerWeapon

function ServerWeapon.new(weaponModule)
    local self = {}


    setmetatable(self, ServerWeapon)
    Maid.watch(self)
    return self
end