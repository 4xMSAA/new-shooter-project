local Emitter = require(shared.Common.Emitter)

local HALF_PI = math.pi/2
local MOVEMENT_FRICTION = _G.MOVEMENT.FRICTION
local MOVEMENT_ACCELERATION_SPEED = _G.MOVEMENT.ACCELERATION_SPEED

local COLLISION_CAPSULE = shared.Assets.Collision.Capsule

local loadedMovementModules = {}
for _, module in pairs(script.Modules:GetChildren()) do
    if module:IsA("ModuleScript") then
        loadedMovementModules[module.Name] = require(module)
    end
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Blacklist
rayParams.FilterDescendantsInstances = {
    _G.Path.Ignore,
    _G.Path.Players,
    _G.Path.ClientViewmodel,
    _G.Path.RayIgnore,
    workspace.CurrentCamera
}
rayParams.IgnoreWater = true

local function reachTargetValue(current, target, step)
    if current < target then
        current = math.min(current + step, target)
    else
        current = math.max(target, current - step)
    end
    return current
end

local function rotate3DVectorXZ(v1, theta)
    theta = math.rad(theta)
    return Vector3.new(
        v1.X * math.cos(theta) - v1.Z * math.sin(theta),
        v1.Y,
        v1.X * math.sin(theta) + v1.Z * math.cos(theta)
    )
end

---Handles movement of a LocalCharacter
---@class Movement
local Movement = {}
Movement.__index = Movement
Movement.Modules = loadedMovementModules

function Movement.new(character)
    local self = {
        Character = character,
        RootPart = character.PrimaryPart,
        Humanoid = character:WaitForChild("Humanoid"),
        Velocity = Vector3.new(),
        PhysicsVelocity = Vector3.new(),
        Location = CFrame.new(),
        Acceleration = Vector3.new(),
        MoveAcceleration = Vector3.new(),
        CollisionCapsule = COLLISION_CAPSULE:Clone(),

        Changed = Emitter.new(),
        
        _speedModifiers = {},
        _movementModules = {}
    }

    local weldConstraint = Instance.new("WeldConstraint")
    self.CollisionCapsule.CFrame = self.RootPart.CFrame
    weldConstraint.Part0 = self.RootPart
    weldConstraint.Part1 = self.CollisionCapsule
    weldConstraint.Parent = self.CollisionCapsule
    self.CollisionCapsule.Parent = _G.Path.Collisions

    
    self._originalSpeed = self.Humanoid.WalkSpeed
    self.Speed = self._originalSpeed
    self.JumpPower = self.Humanoid.JumpPower
    
    self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
    self.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
    
    setmetatable(self, Movement)
    return self
end

function Movement:loadModule(module)
    local instancedModule = module.new(self)
    table.insert(self._movementModules, instancedModule)
    return instancedModule
end

function Movement:setState(property, value)
    if self[property] and self[property] ~= value then
        self.Changed:emit(property, self[property])
    end

    self[property] = value
end

function Movement:setSpeedModifier(name, value)
    self._speedModifiers[name] = value
end

function Movement:update(dt, lookV)
    local moveDir = self.Humanoid.MoveDirection
    for _, module in pairs(self._movementModules) do
        module:update(dt, lookV, moveDir)
    end

    self.Speed = self._originalSpeed
    for _, value in pairs(self._speedModifiers) do
        self.Speed = self.Speed + value
    end

    dt = math.min(dt, 1)

    self.RootPart.CFrame =
        CFrame.new(self.RootPart.Position, self.RootPart.Position + lookV - Vector3.new(0, lookV.Y, 0))

    -- we can still extract MoveDirection even if WalkSpeed is 0
    self.Humanoid.WalkSpeed = 0
    self.Humanoid.JumpPower = self.JumpPower

    self.Location = self.RootPart.CFrame

    -- TODO: make into object space acceleration rather than world space
    -- character is standing on ground according to roblox
    if self.Humanoid.FloorMaterial ~= Enum.Material.Air then
        self.MoveAcceleration =
            Vector3.new(
            reachTargetValue(self.MoveAcceleration.X, self.Speed * moveDir.X, dt*MOVEMENT_ACCELERATION_SPEED),
            0,
            reachTargetValue(self.MoveAcceleration.Z, self.Speed * moveDir.Z, dt*MOVEMENT_ACCELERATION_SPEED)
        )
    end

    local updateVelocity = (self.Velocity + self.Acceleration) * (1 - MOVEMENT_FRICTION)
    self.Velocity =
        updateVelocity +
        (self.MoveAcceleration * -math.min(0, updateVelocity.magnitude - self.MoveAcceleration.magnitude) / self.Speed)

    if self.Velocity:FuzzyEq(Vector3.new(), 0.05) then
        self.Velocity = Vector3.new()
    end

    -- if self.Humanoid.FloorMaterial == Enum.Material.Air then
    --     -- roblox kinda handles the fall part,
    --     -- we just want to do precise-ish simulation for jumping
    --     -- self.Velocity = Vector3.new(self.Velocity.X, self.Velocity.Y - workspace.Gravity / 196.2, self.Velocity.Z)
    -- else
    --     self.Velocity =
    --         Vector3.new(self.Velocity.X, math.max(0, self.Velocity.Y - workspace.Gravity / 196.2), self.Velocity.Z)
    -- end

    -- -- check if user is in air
    -- if self.Humanoid.FloorMaterial == Enum.Material.Air then
    local xzVelocity = Vector3.new(self.Velocity.x, 0, self.Velocity.z)
    -- raycast to prevent wallslamming
    local raycastLeft =
        workspace:Raycast(
        self.Location.Position - Vector3.new(0, 0.4, 0),
        rotate3DVectorXZ(xzVelocity, -60).unit * 1.75,
        rayParams
    )
    local raycastMid =
        workspace:Raycast(self.Location.Position - Vector3.new(0, 0.4, 0), xzVelocity.unit * 1.75, rayParams)
    local raycastRight =
        workspace:Raycast(
        self.Location.Position - Vector3.new(0, 0.4, 0),
        rotate3DVectorXZ(xzVelocity, 60).unit * 1.75,
        rayParams
    )

    -- negate velocity in the direction the wall is oriented at
    if raycastLeft then
        local xzNormal = raycastLeft.Normal - Vector3.new(0, raycastLeft.Normal.Y, 0)
        self.Velocity =
            self.Velocity +
            (xzNormal * xzVelocity.magnitude / HALF_PI) * math.min(1, (1 - xzVelocity.unit:Dot(xzNormal)))
    elseif raycastRight then
        local xzNormal = raycastRight.Normal - Vector3.new(0, raycastRight.Normal.Y, 0)
        self.Velocity =
            self.Velocity +
            (xzNormal * xzVelocity.magnitude / HALF_PI) * math.min(1, (1 - xzVelocity.unit:Dot(xzNormal)))
    elseif raycastMid then
        local xzNormal = raycastMid.Normal - Vector3.new(0, raycastMid.Normal.Y, 0)
        self.Velocity =
            self.Velocity +
            (xzNormal * xzVelocity.magnitude) * math.min(1, (1 - xzVelocity.unit:Dot(xzNormal)))
    end

    self.PhysicsVelocity = Vector3.new(self.Velocity.x, self.RootPart.Velocity.y + self.Velocity.y, self.Velocity.z)
    self.RootPart.Velocity = self.PhysicsVelocity
end

-- function Movement:jump()
--     if
--         self.Humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and
--         self.Humanoid.FloorMaterial ~= Enum.Material.Air
--      then
--         self.Humanoid:ChangeState("Jumping")
--         self.RootPart.Velocity = self.RootPart.Velocity + Vector3.new(0, self.JumpPower, 0)
--     end
-- end

return Movement
