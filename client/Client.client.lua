local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Initialize environment variables
require(ReplicatedStorage.Source:WaitForChild("InitializeEnvironment"))

-- TODO: actual input binding
-- TODO: move gun test code somewhere else or make a manager/handler module for guns
local Gun = require(script.Parent.Core.Gun)

local test = Gun.new("M1Garand", "Zombies")
test.ViewModel.Parent = shared.Path.ClientViewmodel

RunService:BindToRenderStep(
    "GunUpdate",
    1000,
    function(dt)
        test:update(dt, workspace.CurrentCamera.CFrame)
    end
)

coroutine.wrap(
    function()
        while wait(0.5) do
            test:fire()
        end
    end
)()

while wait(3) do
    test:setState("Aim", not test.State.Aim)
end
