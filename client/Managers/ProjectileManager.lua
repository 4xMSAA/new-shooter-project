local Maid = require(shared.Common.Maid)

---A class description
---@class ProjectileManager
local ProjectileManager = {}
ProjectileManager.__index = ProjectileManager

function ProjectileManager.new()
    local self = {}


    setmetatable(self, ProjectileManager)
    Maid.watch(self)
    return self
end