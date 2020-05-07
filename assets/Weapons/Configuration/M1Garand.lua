local Enums = shared.Enums

local assetName = script.Name

local Configuration = {
    Name = "M1 Garand",
    ModelPath = assetName,

    RPM = 444,
    FireMode = {Enums.FireMode.Single, Enums.FireMode.Safety},
    Ammo = {
        Max = 8,
        Reserve = 120
    },
    Projectile = {
        Type = "Bullet",
        Velocity = 853,
        Piercing = 1,
        Amount = 1,
        Damage = {
            Multipliers = {
                Head = 3,
                Body = 1.5,
                Limbs = 1
            },
            Max = 200,
            Min = 20
        }
    },
    Recoil = {
        AimScale = 0.6,
        Rotation = {
            V3 = Vector3.new(0.5, 0, 0),
            Range = Vector3.new(0.3, 2, 0),
            AllowSignedY = true
        },
        Position = {
            V3 = Vector3.new(0, 0, 0.8),
            Range = Vector3.new(0, 0, 0.1)
        }
    },
    Offset = {
        Grip = CFrame.new(.6, -1, -0.8),
        Sprint = CFrame.Angles(0, 0.5, 0),
        Aim = CFrame.new(0, -0.46, -0.6)
    },

    InterpolateSpeed = {
        Aim = 1
    },
}

Configuration.ZombiesOverride = {

    FireMode = {Enums.FireMode.Single},
    Damage = {
        Multipliers = {
            Head = 3,
            Body = 1.5,
            Limbs = 1
        },
        Max = 200,
        Min = 20
    },
}

return Configuration
