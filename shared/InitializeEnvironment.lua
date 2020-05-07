local RunService = game:GetService("RunService")

function _G.create(class, properties)
    local inst = Instance.new(class)
    for prop, value in pairs(properties) do
        inst[prop] = value
    end
    return inst
end

if RunService:IsServer() then
    _G.Storage = game:GetService("ServerStorage")
    _G.Source = game:GetService("ServerScriptService"):WaitForChild("Source")
    _G.Assets = _G.Storage:WaitForChild("Assets")
end

shared.Storage = game:GetService("ReplicatedStorage")
shared.Source = shared.Storage:WaitForChild("Source")
shared.Common = shared.Source:WaitForChild("Common")
shared.Assets = shared.Storage:WaitForChild("Assets")

for key, data in pairs(require(shared.Source:WaitForChild("Configuration"))) do
    print(key, data)
    _G[key] = data
end

shared.Enums = {}
for _, enumModule in pairs(shared.Source:WaitForChild("Enums"):GetChildren()) do
    shared.Enums[enumModule.Name] = require(enumModule)
end

shared.Path = {
    ClientViewmodel = _G.create("Folder", {Name = "ViewModel", Parent = workspace.CurrentCamera})
}

_G.Workspace =
    (RunService:IsServer() and _G.create("Folder", {Name = "GameFolder", Parent = workspace})) or
    workspace:WaitForChild("GameFolder", 5) or
    error("GameFolder does not exist on client")

return true
