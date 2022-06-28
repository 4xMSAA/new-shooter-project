local SYSTEMS_DIR = shared.Common.

local Maid = require(shared.Common.Maid)
local counter = 0

---Manages active entities and networks them
---@class EntityManager
local EntityManager = {
    __groupCache = {}
}
EntityManager.__index = EntityManager

function EntityManager.new(args)
    local self = {
        Entities = {},
        Systems = {}
    }


    setmetatable(self, EntityManager)
    Maid.watch(self)

    return self
end

function EntityManager:add(entity)
    counter = counter + 1
    local newEntity = entity.new(counter)
    table.insert(self.Entities, newEntity)

end

function EntityManager:_cacheEntityGroupQuery(groups)

end

function EntityManager:getEntityGroups(groups)

end


function EntityManager:step(dt)
    for _, system in pairs(self.Systems) do
        system:run(dt, self:getEntityGroups(system.Groups))
    end
end


return EntityManager
