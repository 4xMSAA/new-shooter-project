local RunService = game:GetService("RunService")

local ASCII = require(script.ASCII)

local totalTracked = 0

local Maid = {}
Maid._tracked = {}

local Object = require(script.Object)(Maid)

function Maid.watch(...)
    for _, object in pairs({...}) do
        if not Maid._tracked[object] then
            Maid.attachMetadata(object)
            Maid._tracked[object] = true
        else
            warn(
                "already watching address " .. object .. " from: \n" ..
                debug.traceback()
            )
        end
    end
end

---Creates metadata about how to clear the object
function Maid.attachMetadata(object)
    object._MaidMetadata = {}

    --  attach top-level Object properties that apply to self
    for property, value in pairs(Object) do
        if typeof(value) == "function" then
            object[property] = value
        end
    end
end

---FLush all watched objects
function Maid.flush(noDelete)
    for _, object in pairs(Maid._tracked) do
        object:destroy()
    end
end

function Maid.info(showASCII)
    print(
        "---- MAID INFO ----\n" ..
        (showASCII and ASCII or "\n")..
        "Watching " .. #Maid._tracked .. " active objects. " ..
        "Total of " .. totalTracked .. " watched objects.\n" ..
        "Called from: \n" ..
        debug.traceback()
    )
end

if not RunService:IsStudio() then
    Maid.info(true)
end

return Maid