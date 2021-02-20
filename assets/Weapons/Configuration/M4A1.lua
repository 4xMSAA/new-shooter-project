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
        Reserve = 180
    },
    Particles = {
        Fire = {Path = "Gun/Muzzle", Parent = "Rig/Muzzle"},
        -- Eject = {Path = "Gun/Casing/5.56x9mm", Speed = 14}
    },
    Sounds = {
        BoltForward = 5104015522,
        MagIn = 5104152875,
        MagOut = {SoundId = 268445237, Volume = 0.7},
        -- Fire = {SoundId = 988203005, Volume = 0.4},
        Fire = {SoundId = 300537398, Volume = 0.4},
        DistantFire = 4788389522
    },
    Projectile = {
        Type = "Bullet",
        Velocity = 853,
        Piercing = 1,
        Amount = 1
    },
    Recoil = {
        AimScale = 0.8,
        Rotation = {
            V3 = Vector3.new(0.4, 0, 0),
            Range = Vector3.new(0.1, 0.3, 0),
            AllowSignedY = true
        },
        Position = {
            V3 = Vector3.new(0, 0, 1.2),
            Range = Vector3.new(0, 0, 0.3)
        }
    },
    CameraRecoil = {
        V3 = Vector3.new(0.6, 0, 0),
        Range = Vector3.new(0.1, 0.3, 0),
        ForceModifier = 1,
        SpeedModifier = 1
    },
    Offset = {
        Grip = CFrame.new(0.6, -0.9, -0.8),
        Sprint = CFrame.Angles(0, 0.55, 0),
        Aim = CFrame.new(0, -0.61, -0.4)
    },
    InterpolateSpeed = {
        Aim = 1
    }
}

Configuration.Gamemode = {}
Configuration.Gamemode.PvP = {
    Projectile = {
        Damage = {
            Multipliers = {
                Head = 1,
                Body = 0.8,
                Limbs = 0.5
            },
            Max = 90,
            Min = 20
        }
    }
}
Configuration.Gamemode.Zombies = {
    FireMode = {Enums.FireMode.Automatic},
    Projectile = {
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
}

return Configuration
