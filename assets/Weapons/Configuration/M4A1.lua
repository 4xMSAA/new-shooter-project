local Enums = shared.Enums

local assetName = script.Name

local Configuration = {
    Name = "M4A1",
    ModelPath = assetName,
    AnimationPath = assetName,
    ActionType = Enums.GunActionType.ClosedBolt,
    RPM = 800,
    FireMode = {Enums.FireMode.Automatic, Enums.FireMode.Safety},
    EquipTime = 0.88,
    Zoom = 1.25,
    Ammo = {
        Max = 30,
        Reserve = 180,
        Eject = {
            Particle = "Gun/Casing/.30-06",
            Speed = 14
        }
    },
    Particles = {
        Fire = {Path = "Gun/Muzzle", Parent = "Rig/Muzzle"}
    },
    Sounds = {
        BoltBack = 3607477790,
        BoltForward = 3719417506,
        InsertClip = 456179899,
        ClipIn = 152206337,
        ClipOut = {SoundId = 988201742, Volume = 0.7},
        ClipFling = {SoundId = 231738531, Volume = 1},
        Fire = {SoundId = 988201742, Volume = 0.7}
    },
    Projectile = {
        Type = "Bullet",
        Velocity = 853,
        Piercing = 1,
        Amount = 1,
        Damage = {
            Multipliers = {
                Head = 1,
                Body = 0.8,
                Limbs = 0.5
            },
            Max = 90,
            Min = 20
        }
    },
    Recoil = {
        AimScale = 0.6,
        Rotation = {
            V3 = Vector3.new(0.5, 0, 0),
            Range = Vector3.new(0.3, 0.15, 0),
            AllowSignedY = true
        },
        Position = {
            V3 = Vector3.new(0, 0, 0.8),
            Range = Vector3.new(0, 0, 0.1)
        }
    },
    Offset = {
        Grip = CFrame.new(.6, -0.9, -0.8),
        Sprint = CFrame.Angles(0, 0.55, 0),
        Aim = CFrame.new(0, -0.616, -0.4)
    },
    InterpolateSpeed = {
        Aim = 1
    }
}

Configuration.Gamemode = {}
Configuration.Gamemode.Zombies = {
    FireMode = {Enums.FireMode.Automatic},
    Damage = {
        Multipliers = {
            Head = 3,
            Body = 1.5,
            Limbs = 1
        },
        Max = 200,
        Min = 20
    }
}

return Configuration
