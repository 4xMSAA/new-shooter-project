local Debris = game:GetService("Debris")

local function cfgRandom(range)
    return type(range) == "number" and range or math.random(range[1], range[2])
end

local function disable(obj, time)
    Debris:AddItem(obj, time)
end


return {
    ParticleEmitter = function(inst, config)
        if config.Chance and config.Chance[inst.Name] and math.random() > config.Chance[inst.Name] then return end

        inst:Emit(
            config.Specification[inst.Name] and cfgRandom(config.Specification[inst.Name].Amount)
            or cfgRandom(config.Default[inst.ClassName].Amount)
        )
        disable(inst, inst.Lifetime.Max)
    end,

    PointLight = function(inst, config)
        if config.Chance and config.Chance[inst.Name] and math.random() > config.Chance[inst.Name] then return end

        inst.Enabled = true
        disable(inst, config.Specification[inst.Name].Lifetime)
    end
}