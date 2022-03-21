local Maid = require(shared.Common.Maid)

---Loads a Scene with references to entities and spawns found in the scene, and
---can load the references with the specified gamemode.  
---The gamemode's modules or "plug-ins" will be used for loading the references 
---@class SceneLoader
local SceneLoader = {}
SceneLoader.__index = SceneLoader

function SceneLoader.new(sceneName, gamemode1)
   local self = {}
   --TODO: load scene

   setmetatable(self, SceneLoader)
   Maid.watch(self)

   return self
end

function SceneLoader:_loadEntities()
end