--[[
    Handle new incoming connections
--]]
local Enums = shared.Enums

local Players = game:GetService("Players")

local Client = require(script.Client)

local JOIN_PROCEDURES_FOLDER = script.JoinProcedures
local LEAVE_PROCEDURES_FOLDER = script.LeaveProcedures

---Orders all modules by their priority value (lower is more critical)
---@param moduleList table A list of modules with a Priority property to order
---                        with
local function orderModulesByPriority(moduleList)
    local orderedList = {}
    for pass = 1, #Enums.Priority do
        for _, module in pairs(moduleList) do
            if module.Priority == Enums.Priority(pass) then
                table.insert(orderedList, module)
            end
        end
    end
    return orderedList
end

---Handles incoming connections and leaving users
---@class ClientManager
local ClientManager = {}
ClientManager.__index = ClientManager

--- Constructs a new ClientManager
---@param joinProcedures table A table with Procedure data
---@param leaveProcedures table A table with Procedure data
---@return ClientManager
function ClientManager.new(joinProcedures, leaveProcedures)
    local self = {
        Clients = {},
        LeaveProcedures = {},
        JoinProcedures = {}
    }

    if not joinProcedures then
        local procedureModules = {}
        for _, procedure in pairs(JOIN_PROCEDURES_FOLDER:GetChildren()) do
            table.insert(procedureModules, require(procedure))
        end
        self.JoinProcedures = orderModulesByPriority(procedureModules)
    else
        self.JoinProcedures = joinProcedures
    end

    if not leaveProcedures then
        local procedureModules = {}
        for _, procedure in pairs(LEAVE_PROCEDURES_FOLDER:GetChildren()) do
            table.insert(procedureModules, require(procedure))
        end
        self.LeaveProcedures = orderModulesByPriority(procedureModules)
    else
        self.LeaveProcedures = leaveProcedures
    end

    setmetatable(self, ClientManager)
    return self
end

--- Initializes extra features in ClientManager (events, connections)
function ClientManager:init()
    self._PlayerAdded =
        Players.PlayerAdded:connect(
        function(player)
            self:addClientByPlayer(player)
        end
    )
    self._PlayerRemoving =
        Players.PlayerRemoving:connect(
        function(player)
            self:removeClientByPlayer(player)
        end
    )

    -- studio hack (still have to do this in 2020 KEKW)
    for _, player in pairs(Players:GetPlayers()) do
        self:addClientByPlayer(player)
    end
end

---
---@param player userdata
function ClientManager:getClientByPlayer(player)
    for _, client in pairs(self.Clients) do
        if client.PlayerInstance == player then
            return client
        end
    end
end

---
---@param client Client
function ClientManager:addClient(client)
    -- run them through modules in JoinProcedures
    -- they have been sorted by priority
    for _, module in pairs(self.JoinProcedures) do
        module.Run(client)
    end

    table.insert(self.Clients, client)

    return client
end

---
---@param player userdata
function ClientManager:addClientByPlayer(player)
    local client = Client.new(player)

    return self:addClient(client)
end

---
---@param client Client
function ClientManager:removeClient(client)
    -- run them through modules in LeaveProcedures
    for _, module in pairs(self.JoinProcedures) do
        module.Run(client)
    end

    for index, listClient in pairs(self.Clients) do
        if client == listClient then
            table.remove(self.Clients, index)
        end
    end
end

---
---@param player userdata
function ClientManager:removeClientByPlayer(player)
    local client = self:getClientByPlayer(player)
    -- run them through modules in LeaveProcedures
    self:removeClient(client)
end

--- Removes all clients but keeps connections and the object
function ClientManager:flush()
    for _, client in pairs(self.Clients) do
        self:removeClient(client)
    end
end

--- Leaves the ClientManageer to garbage collection
function ClientManager:destroy()
    self._PlayerAdded:disconnect()
    self._PlayerRemoving:disconnect()

    for property, _ in pairs(self) do
        self[property] = nil
    end
end

return ClientManager
