local Maid = require(shared.Common.Maid)

---A module to add sprinting to the MovementController
---@class AimWalkSpeedModule
local AimWalkSpeedModule = {}
AimWalkSpeedModule.__index = AimWalkSpeedModule

function AimWalkSpeedModule.new(controller)
   local self = {
       Controller = controller,
       LocalCharacterReference = nil,

       Aim = false,
       AimWalkSpeedModifier = -2
   }

   setmetatable(self, AimWalkSpeedModule)
   Maid.watch(self)

   return self
end
function AimWalkSpeedModule:update(dt, lookV, moveDir)
    self.Controller:setSpeedModifier("AimWalkSpeed", 0)
    self.Controller:setState("IsAiming", false)
    if self.Aim then
        self.Controller:setState("IsSprinting", false)
        self.Controller:setState("IsAiming", true)
        self.Controller:setSpeedModifier("AimWalkSpeed", self.AimWalkSpeedModifier)
    end
end

return AimWalkSpeedModule