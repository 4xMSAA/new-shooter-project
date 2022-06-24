local Maid = require(shared.Common.Maid)
local counter = 0

---Manages active entities and networks them
---@class EntityManager
local EntityManager = {}
EntityManager.__index = EntityManager

function EntityManager.new(args)
    local self = {
        Entities = {}
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

function EntityManager:step(dt)
    for _, entity in pairs(self.Entities) do
        -- do something i guess
    end
end


return EntityManager
