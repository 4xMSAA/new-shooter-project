local Maid = require(shared.Common.Maid)
local NetworkLib = require(shared.Common.NetworkLib)

---A class description
---@class Router
local Router = {}
Router.__index = Router

function Router.new(targetObject)
    local self = {
        Active = false,
        Target = targetObject,
        Listeners = {}
    }

    setmetatable(self, Router)
    Maid.watch(self)
    return self
end

function Router:createWrapperFor(module)
    local this = self
    local wrapper = {}
    wrapper.moduleName = module
    function wrapper:on(packetType, runnable)
        this:on(module, packetType, runnable)
    end
end

function Router:init()
    -- listen for all from networklib and decide where to send

    NetworkLib:listen(
        function(packetType, ...)
            if not self.Active then
                return
            end

            for _, module in pairs(self.Listeners) do
                for _, listener in pairs(module) do
                    if packetType == listener.PacketType then
                        listener.Runnable(...)
                    end
                end
            end
        end
    )

    return self
end

function Router:on(module, packetType, runnable)
    if not self.Listeners[module] then
        self.Listeners[module] = {}
    end

    table.insert(self.Listeners, {PacketType = packetType, Runnable = runnable})
    return self
end

function Router:enable()
    self.Active = true
    return self
end

function Router:disable()
    self.Active = false
    return self
end
