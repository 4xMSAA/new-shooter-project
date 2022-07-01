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

function ServerScene:getPlayerSpawn()

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
