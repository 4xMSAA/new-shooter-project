local log, logwarn = require(shared.Common.Log)(script:GetFullName())
local Emitter = require(shared.Common.Emitter)
local Maid = require(shared.Common.Maid)

---Base class for all things interactable, moving or still. Is added into the game at runtime.
---@class Entity
local Entity = {}
Entity.__index = Entity

function Entity.new(id, entityType, props)
    local self = {
        ID = id,
        Name = "BaseEntity",
        Type = entityType,
        Properties = props,
        State = {},

        Changed = Emitter.new()
    }

    for key, value in pairs(entityType) do
        self[key] = value
    end

    if typeof(self.init) == "function" then
        self:init(props)
    end

    setmetatable(self, Entity)
    Maid.watch(self)

    self:_setupEvents()

    return self
end

function Entity:_setupEvents()

end

function Entity:run()
    logwarn(1, ("entity %s of type %s has no run behaviour"):format(self.Name, self.Type))
end


return Entity
