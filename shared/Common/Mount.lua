--[[
    Mount instance paths to string with a separator

    TODO: cache stupid mount paths that already have the same location
--]]

local SmallUtils = require(shared.Common.SmallUtils)
local Mount = {}

Mount.__call = function(self, path, sep)
    assert(path, "path argument (1) is nil")
    sep = sep or "/"

    local splitPath = SmallUtils.split(path, sep)

    local head = self.Location
    for _, fileName in ipairs(splitPath) do
        -- print(path, ":", fileName)
        if typeof(head) == "table" then
            head = head[fileName] or error("path does not exist:", fileName, "from", path)
        elseif typeof(head) == "Instance" then
            -- print("traversing from", head:GetFullName())
            head =
                head:FindFirstChild(fileName) or
                error("path does not exist: " .. fileName .. " from " .. head:GetFullName())
        end
    end

    -- print("final:", head)

    return head
end

Mount.__index = function()
    return error("cannot index virtual mount point - call mount point with desired path string instead", 2)
end

---
---@param location any Any possible indexable table/object
function Mount.new(location)
    local self = {}

    self.Location = location

    setmetatable(self, Mount)

    return self
end

return Mount.new
