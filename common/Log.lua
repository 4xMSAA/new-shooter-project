
--TODO: load GUI if on client, print server stuff, organize better than the command line

return function(context)
    local function log(level, ...)
        local LOG_LEVEL = _G.LOG_LEVEL or 2
        assert(typeof(level) == "number", "log function must have number as first argument (got " .. typeof(level) .. ")")
        if LOG_LEVEL >= level then
            print("[" .. context .. "]:", ...)
        end
    end

    local function logwarn(level, ...)
        local LOG_LEVEL = _G.LOG_LEVEL or 2
        assert(typeof(level) == "number", "logwarn function must have number as first argument (got " .. typeof(level) .. ")")
        if LOG_LEVEL >= level then
            warn("[" .. context .. "]:", ...)
        end
    end

    local function logdebug(...)
        if (_G.DEBUG_LOG or 0) > 0 then
            print("[DEBUG][" .. context .. "]:", ...)
        end
    end

    return log, logwarn, logdebug
end
