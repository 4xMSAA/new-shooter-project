local Object = {}
local Maid -- attain context from runtime

function Object.destroy(self)
    if self.flush then
        self:flush()
    end
    if self.destroy then
        self:destroy()
    end

    Maid._tracked[self] = false
    for key, value in pairs(self) do
        key = nil
    end
    setmetatable(self, nil)
end

return function(Maid)
    Maid = Maid
    return Object
end