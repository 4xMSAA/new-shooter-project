local Debris = game:GetService("Debris")

local function cfgRandom(range)
    return type(range) == "number" and range or math.random(range[1], range[2])
end

return {
    ParticleEmitter = function(inst, config)
        inst:Emit(
            cfgRandom(config.Specification[inst.Name].Amount)
            or cfgRandom(config.Default[inst.ClassName])
        )
    end,

    PointLight = function(inst, config)
        local light = inst:Clone()
        light.Enabled = true
        light.Parent = inst.Parent
        Debris:AddItem(light, config.Specification[inst.Name].Lifetime)
    end
}