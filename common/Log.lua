local LOG_LEVEL = _G.LOG_LEVEL or 2

--TODO: load GUI if on client

return function(context)
    local function log(level, ...)
        if LOG_LEVEL >= level then
            print("[" + context + "]:", ...)
        end
    end

    return log
end