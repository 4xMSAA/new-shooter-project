local Maid = require(shared.Common.Maid)

---Manages active entities and networks them
---@class EntityManager
local EntityManager = {}
EntityManager.__index = EntityManager

function EntityManager.new(args)
    local self = {}


    setmetatable(self, EntityManager)
    Maid.watch(self)

    return self
end


return EntityManager
