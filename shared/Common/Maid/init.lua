local RunService = game:GetService("RunService")

local TableUtils = require(shared.Common.TableUtils)

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
            totalTracked = totalTracked + 1
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
    object._maidMetadata = {}

    --  attach top-level Object properties that apply to self
    for property, value in pairs(Object) do
        if rawget(object, property) then
            object._maidMetadata[property] = value
        end
        if typeof(value) == "function" then
            rawset(object, property, value)
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
        "Watching " .. TableUtils.count(Maid._tracked) .. " active objects. " ..
        "Total of " .. totalTracked .. " watched objects.\n" ..
        "Called from: \n|- " ..
        debug.traceback():gsub("\n$",""):gsub("\n", "\n|- ")
    )
end

if not RunService:IsStudio() then
    Maid.info(true)
end

return Maid