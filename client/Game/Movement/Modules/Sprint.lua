local Maid = require(shared.Common.Maid)

local SPRINTING_ANGLE = math.rad(40)/(math.pi/2)

---A module to add sprinting to the MovementController
---@class SprintModule
local SprintModule = {}
SprintModule.__index = SprintModule

function SprintModule.new(controller)
   local self = {
       Controller = controller,

       Sprint = false,
       SprintSpeedModifier = 10
   }

   setmetatable(self, SprintModule)
   Maid.watch(self)

   return self
end
function SprintModule:update(dt, lookV, moveDir)
    self.Controller:setState("IsSprinting", false)
    self.Controller:setSpeedModifier("SprintSpeed", 0)
    if self.Sprint and not self.Controller.IsAiming then
        if self.Controller.Velocity.magnitude > 0.1 and Vector3.new(lookV.x, 0, lookV.z).unit:Dot(moveDir) > SPRINTING_ANGLE then
            self.Controller:setState("IsSprinting", true)
            self.Controller:setSpeedModifier("SprintSpeed", self.SprintSpeedModifier)
        end
    end
end

return SprintModule
