--[[ --TODO: has some really questionable design choices.
        figure out alternatives
        worrying amount of complexity in terms of parent/child relationship
        between entity objects and systems that actuate the entity behaviour

        if there was a better way to express this...
--]]

local SHARED_SYSTEMS_DIR = shared.Game.EntitySystems
local SERVER_SYSTEMS_DIR = _G.Server and _G.Server.Game.EntitySystems or nil


local Maid = require(shared.Common.Maid)

local Entity = require(shared.Game.Entity)

local counter = 0

---Manages active entities and networks them
---@class EntityManager
local EntityManager = {}
EntityManager.__index = EntityManager

function EntityManager.new(args)
    local self = {
        Entities = {},
        Systems = {},

        _groupCache = {},
        _cacheIndexEntity = {}
    }


    setmetatable(self, EntityManager)
    Maid.watch(self)

    return self
end

function EntityManager:add(entity, props)
    counter = counter + 1
    local newEntity = Entity.new(counter, entity, props)
    table.insert(self.Entities, newEntity)

    self:_addEntityToCacheGroupQueries(entity)
end

function EntityManager:remove(entity)
    self:_removeEntityFromCacheGroups(entity)

    for index, targetEntity in pairs(self.Entities) do
        if entity == targetEntity then
            table.remove(entity, index)
        end
    end
end

function EntityManager:_cacheEntityGroupQuery(groups)
    local cache = self._groupCache[groups] or {}
    local indexCache = self._cacheIndexEntity[groups] or {}
    local dict = {}

    for _, group in pairs(groups) do
        dict[group] = true
    end

    for _, entity in pairs(self.Entities) do
        for _, group in pairs(entity.Groups) do
            local index = #cache + 1
            local allow = dict[group]
            cache[index] = allow and entity or nil
            indexCache[entity] = allow and index or nil

            -- it's in one of the targeted groups, don't make duplicates
            break
        end
    end

    self._groupCache[groups] = cache
    self._cacheIndexEntity[groups] = indexCache

    return cache
end

function EntityManager:_addEntityToCacheGroupQueries(entity)
    for _, group in pairs(entity.Groups) do
        for groups, contents in pairs(self._groupCache) do
            local indexCache = self._cacheIndexEntity[groups] or {}
            for includedGroup, _ in pairs(groups) do
                local index = #contents + 1

                local allow = group == includedGroup
                contents[index] = allow and entity or nil
                indexCache[entity] = allow and index or nil

                break
            end
            self._cacheIndexEntity[groups] = indexCache
        end
    end
end

function EntityManager:_removeEntityFromCacheGroups(entity)
    for groups, contents in pairs(self._groupCache) do
        local indexCache = self._cacheIndexEntity[groups]
        local index = indexCache[entity]
        if index then
            contents[index] = nil
            indexCache[entity] = nil
        end

        break
    end
end

function EntityManager:getEntityGroups(groups)
    return self._groupCache[groups] or self:_cacheEntityGroupQuery(groups)
end


function EntityManager:step(dt)
    for _, system in pairs(self.Systems) do
        system:run(dt, self:getEntityGroups(system.Groups))
    end
end


return EntityManager
