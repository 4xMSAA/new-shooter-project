local Debris = game:GetService("Debris")

local function cfgRandom(range)
    return type(range) == "number" and range or math.random(range[1], range[2])
end

local function scheduleDelete(obj, time)
    wait(time)
    obj:Destroy()
    print("a")
end

return {
    ParticleEmitter = function(inst, config)
        inst:Emit(
            config.Specification[inst.Name] and cfgRandom(config.Specification[inst.Name].Amount)
            or cfgRandom(config.Default[inst.ClassName].Amount)
        )
    end,

    PointLight = function(inst, config)
        local light = inst:Clone()
        light.Enabled = true
        light.Parent = inst.Parent
        coroutine.wrap(scheduleDelete)(light, config.Specification[inst.Name].Lifetime)
    end
}