local Lighting = game:GetService("Lighting")

local ServerScene = require(_G.Server.Game.ServerScene)

local Maid = require(shared.Common.Maid)

---A class description
---@class SceneLoader
local SceneLoader = {}
SceneLoader.__index = SceneLoader

function SceneLoader.new(entityManager)
    assert(typeof(entityManager) == "table", "SceneLoader needs EntityManager as #1 argument")
    local self = {
        EntityManager = entityManager,
        ActiveScene = nil,

        SpawnGroups = {},

    }


    setmetatable(self, SceneLoader)
    Maid.watch(self)

    return self
end

function SceneLoader:load(sceneName)
    assert(not self.ActiveScene, "an active scene is already present")

    local scene = ServerScene.new(sceneName)
    self.ActiveScene = scene
    scene.Model.Parent = _G.Path.Scene

    self:_loadEntities(scene)
    self:_loadLighting(scene)
end

function SceneLoader:unload()
    local scene = self.ActiveScene

end

function SceneLoader:_loadEntities(scene)
    -- self.EntityManager
end

function SceneLoader:_loadLighting(scene)
    scene._tracking.Lighting = {}

    scene._tracking.Lighting.BeforeProperties = {}
    local settings = scene.Setup.Lighting:WaitForChild("Settings", 5)
    if settings then
        for property, value in pairs(require(settings)) do
            scene._tracking.Lighting.BeforeProperties[property] = Lighting[property]
            Lighting[property] = value
        end
    end

    scene._tracking.Lighting.Instances = {}
    for _, inst in pairs(scene.Setup.Lighting:GetChildren()) do
        if not inst:IsA("Script") and not inst:IsA("ModuleScript") then
            local trackedInst = inst:Clone()
            trackedInst.Parent = Lighting
            scene._tracking.Lighting.Instances = trackedInst
        end
    end
end

function SceneLoader:getPlayerSpawn()
    for _, entity in pairs(self.EntityManager:getEntityGroups({"Spawner"})) do
        if entity:getSpawnerGroup() == "Player" then
            return entity:run()
        end
    end

    -- give up and spawn player at 0, 50, 0
    return nil
end


return SceneLoader
