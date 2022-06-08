local Lighting = game:GetService("Lighting")

local Maid = require(shared.Common.Maid)

local function wfc(i, s)
    return i:WaitForChild(s, 5)
end

---Loads a scene with references to entities and spawns found in the scene
---Only one scene should be active at once
---@class ServerScene
local ServerScene = {}
ServerScene.__index = ServerScene

function ServerScene.new(sceneName)
    local model = wfc(_G.Assets.Scenes, sceneName)
    assert(model, "could not find scene named " .. tostring(sceneName))

    model = model:Clone()
    local self = {
        Model = model,
        Setup = {
            Lighting = wfc(model, "Lighting"),
            Entities = wfc(model, "Entities"),
            Ignore = wfc(model, "Ignore"),
            Design = wfc(model, "Design")
        },

        _tracking = {}
    }


    setmetatable(self, ServerScene)
    Maid.watch(self)

    return self
end

function ServerScene:load()
    self.Model.Parent = _G.Path.Scene
    self:_loadEntities()
    self:_loadLighting()
end

function ServerScene:_loadEntities()
end

function ServerScene:_loadLighting()
    self._tracking.Lighting = {}

    self._tracking.Lighting.BeforeProperties = {}
    local settings = wfc(self.Setup.Lighting, "Settings")
    if settings then
        for property, value in pairs(require(settings)) do
            self._tracking.Lighting.BeforeProperties[property] = Lighting[property]
            Lighting[property] = value
        end
    end

    self._tracking.Lighting.Instances = {}
    for _, inst in pairs(self.Setup.Lighting:GetChildren()) do
        if not inst:IsA("Script") and not inst:IsA("ModuleScript") then
            local trackedInst = inst:Clone()
            trackedInst.Parent = Lighting
            self._tracking.Lighting.Instances = trackedInst
        end
    end
end

function ServerScene:destroy()
    -- clean up after ourselves
    for _, inst in pairs(self._tracking.Lighting.Instances) do
        inst:Destroy()
    end
    for property, value in pairs(self._tracking.Lighting.BeforeProperties) do
        Lighting[property] = value
    end
end


return ServerScene
