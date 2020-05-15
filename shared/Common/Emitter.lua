--[[
    Events but without the headache of
    "Cannot convert mixed or non-array tables: keys must be strings"
    when working with BindableEvents as signals (looking at stravant's CreateSignal utility)
--]]


local Listener = {}
function Listener.new(emitter, func)
    local self = {}
    self.run = func
    self.emitter = emitter

    function self:close()
        self.emitter.listeners[self] = nil
    end

    self.disconnect = self.close
    self.Disconnect = self.close

    return self
end

---Roblox-style signals
---@class Emitter
local Emitter = {}
function Emitter.new()
    local self = {}
    self.listeners = {}

    -- Used to create the wait method of an emitter without Lua-side magickityjiggitywhatever
    local waitHack = Instance.new("BindableEvent")

    function self:listen(listener)
        if type(listener) ~= "function" then
            error("expected function for argument #1, got " .. type(listener), 2)
        end

        local conn = Listener.new(self, listener)
        self.listeners[conn] = true

        return conn
    end

    function self:closeAll()
        for listener,_ in pairs(self.listeners) do
            listener:close()
        end
    end

    ---Waits until the signal is fired again
    function self:wait()
        return waitHack:Wait()
    end

    function self:emit(...)
        waitHack:Fire()
        for listener,_ in pairs(self.listeners) do
            listener.run(...)
        end
    end

    self.connect = self.listen
    self.Connect = self.listen

    self.Wait = self.Wait

    self.fire = self.emit
    self.Fire = self.emit
    self.Emit = self.emit

    return self
end

return Emitter