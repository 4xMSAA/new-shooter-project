--[[
    creates viewmodel arms that can be attached to a weapon
--]]
local LEFT_ARM_PIVOT = _G.VIEWMODEL.LEFT_ARM_PIVOT
local RIGHT_ARM_PIVOT = _G.VIEWMODEL.RIGHT_ARM_PIVOT

---
---@class ViewModelArms
local ViewModelArms = {}
ViewModelArms.__index = ViewModelArms

function ViewModelArms.new(model)
    model = assert(
        typeof(model) == "string" and shared.Assets.ViewModelArms:WaitForChild(model) or model,
        "model not found (" .. tostring(model) .. ")"
    )

    local self = {}
    self.Model = model:Clone()

    self.LeftArm = self.Model.LeftArm
    self.RightArm = self.Model.RightArm

    setmetatable(self, ViewModelArms)
    self:_init()

    return self
end

function ViewModelArms:_init()
    for _, part in pairs(self.Model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
            part.CastShadow = false
            part.Anchored = false
            part.Massless = true
        end
    end
end

function ViewModelArms:attach(gun)
    local Part0 = gun.Handle
    local LeftPart1 = self.LeftArm:WaitForChild(LEFT_ARM_PIVOT)
    local RightPart1 = self.RightArm:WaitForChild(RIGHT_ARM_PIVOT)

    self.Model.Parent = gun.ViewModel

    self.LeftMotor = Instance.new("Motor6D")
    self.LeftMotor.Name = LeftPart1.Name
    self.LeftMotor.Part1 = LeftPart1
    self.LeftMotor.Part0 = Part0
    self.LeftMotor.Parent = Part0

    self.RightMotor = Instance.new("Motor6D")
    self.RightMotor.Name = RightPart1.Name
    self.RightMotor.Part1 = RightPart1
    self.RightMotor.Part0 = Part0
    self.RightMotor.Parent = Part0

end

return ViewModelArms
