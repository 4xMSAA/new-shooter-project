--[[
    Ease the burden of writing different method names and signal handling

--]]
local RunService = game:GetService("RunService")

local GameEnum = shared.GameEnum
local log, logwarn = require(shared.Common.Log)(script:GetFullName())

local remotes = _G.Path.Remotes
local isClient = RunService:IsClient()
local isServer = RunService:IsServer()
---
---@class NetworkLib
local NetworkLib = {}
NetworkLib._activeListeners = {}

function NetworkLib:_toEnum(id)
    return GameEnum.PacketType(id)
end

function NetworkLib:_toInstance(object)
    return typeof(object) == "table" and object.Instance or object
end

---Scans through data and if entries contain a table with a :serialize() method,
---changes the entry into the serialized variant
function NetworkLib:_autoSerialize(...)
    local result = {}

    log(2, "SERIALIZE: automatically serializing contents:", ...)
    for key, value in pairs({...}) do
        log(2, "SERIALIZE: GOT", key, "=", value)

        if typeof(value) == "table" and value["serialize"] then
            value = value:serialize()
        elseif typeof(value) == "table" then
            logwarn(2, "no serialize function on object: " .. tostring(value) .. "\n" .. debug.traceback())
        end

        log(2, "SERIALIZE: ASSIGN", key, "=", value)
        result[key] = value
    end

    log(2, "SERIALIZE: serialized contents:", unpack(result))

    return unpack(result)
end

function NetworkLib:_listenHandler(ev, callback, listenFor)
    local signal

    -- bad spaghetti that will handle server-client communication in one module
    if isClient then
        signal =
            ev:connect(
            function(id, ...)
                local receivedEnum = NetworkLib:_toEnum(id)
                log(1, "LISTEN: enum: ", receivedEnum and receivedEnum.Name or "nil", "contents:", ...)
                if listenFor and receivedEnum == listenFor then
                    callback(...)
                else
                    callback(receivedEnum, ...)
                end
            end
        )
    elseif isServer then
        signal =
            ev:connect(
            function(player, id, ...)
                local receivedEnum = NetworkLib:_toEnum(id)
                log(1, "LISTEN: from:", player, "enum: ", receivedEnum and receivedEnum.Name or "nil", "contents:", ...)
                if listenFor and receivedEnum == listenFor then
                    callback(player, ...)
                else
                    callback(player, receivedEnum, ...)
                end
            end
        )
    end

    -- register the signal
    NetworkLib._activeListeners[signal] = true

    -- TODO: figure out how to handle disconnnects, observe behaviour if
    -- disconnect makes signal nil or keeps reference?

    return signal
end

---Catch-all signal
---@param callback function Executed whenever a signal is received
---@return userdata RbxScriptSignal
function NetworkLib:listen(callback)
    if isClient then
        return NetworkLib:_listenHandler(remotes.Signal.OnClientEvent, callback)
    elseif isServer then
        return NetworkLib:_listenHandler(remotes.Signal.OnServerEvent, callback)
    end
end

---Listen for specific signals with their marked enumerator
---@param enum userdata Enumerable to filter for
---@param callback function Executed whenever a signal is received
---@return userdata RbxScriptSignal
function NetworkLib:listenFor(enum, callback)
    if isClient then
        return NetworkLib:_listenHandler(remotes.Signal.OnClientEvent, callback, enum)
    elseif isServer then
        return NetworkLib:_listenHandler(remotes.Signal.OnServerEvent, callback, enum)
    end
end

---On client, sends to server
---On server, sends to all clients
---@param enum PacketType
function NetworkLib:send(enum, ...)
    if isClient then
        log(1, "CLIENT SEND:", enum.Name, ..., "\n", debug.traceback())
        remotes.Signal:FireServer(enum.ID, NetworkLib:_autoSerialize(...))
    elseif isServer then
        log(1, "SERVER SEND:", enum.Name, ..., "\n", debug.traceback())
        remotes.Signal:FireAllClients(enum.ID, NetworkLib:_autoSerialize(...))
    end
end

---
---@param player userdata
---@param enum PacketType
function NetworkLib:sendTo(player, enum, ...)
    if isClient then
        error("cannot send to player on client", 2)
    end
    log(1, "SERVER SEND TO:", enum.Name, ...)
    remotes.Signal:FireClient(NetworkLib:_toInstance(player), enum, NetworkLib:_autoSerialize(...))
end

return NetworkLib
