local RunService = game:GetService("RunService")

local Enums = shared.Enums

local remotes = _G.Path.Remotes

local NetworkLib = {}
NetworkLib._activeListeners = {}

function NetworkLib:_toEnum(id)
    return Enums.PacketType(id)
end

function NetworkLib:_listenHandler(ev, callback, listenFor)
    local signal

    -- bad spaghetti that will handle server-client communication in one module
    if RunService:IsClient() then
        signal =
            ev:connect(
            function(id, ...)
                local receivedEnum = NetworkLib:_toEnum(id)
                if not listenFor then
                    callback(receivedEnum, ...)
                elseif listenFor and receivedEnum == listenFor then
                    callback(...)
                end
            end
        )
    elseif RunService:IsServer() then
        signal =
            ev:connect(
            function(player, id, ...)
                local receivedEnum = NetworkLib:_toEnum(id)
                if not listenFor then
                    callback(player, receivedEnum, ...)
                elseif listenFor and receivedEnum == listenFor then
                    callback(player, ...)
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
    if RunService:IsClient() then
        return NetworkLib:_listenHandler(remotes.Signal.OnClientEvent, callback)
    elseif RunService:IsServer() then
        return NetworkLib:_listenHandler(remotes.Signal.OnServerEvent, callback)
    end
end

---Listen for specific signals with their marked enumerator
---@param enum userdata Enumerable to filter for
---@param callback function Executed whenever a signal is received
---@return userdata RbxScriptSignal
function NetworkLib:listenFor(enum, callback)
    if RunService:IsClient() then
        return NetworkLib:_listenHandler(remotes.Signal.OnClientEvent, callback, enum)
    elseif RunService:IsServer() then
        return NetworkLib:_listenHandler(remotes.Signal.OnServerEvent, callback, enum)
    end
end