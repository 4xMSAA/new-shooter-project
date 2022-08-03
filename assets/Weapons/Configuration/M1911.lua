local GameEnum = shared.GameEnum

local assetName = script.Name

local Configuration = {
    Name = "M1911",
    ModelPath = assetName,
    AnimationPath = assetName,
    ActionType = GameEnum.GunActionType.ClosedBolt,
    RPM = 700,
    FireMode = {GameEnum.FireMode.Single, GameEnum.FireMode.Safety},
    EquipTime = 0.56,
    Zoom = 1.1,
    Ammo = {
        Max = 7,
        Reserve = 56
    },
    Particles = {
        Fire = {Path = "Gun/Muzzle", Parent = "Rig/Muzzle"},
        -- Eject = {Path = "Gun/Casing/.45ACP", Speed = 14}
    },
    Sounds = {
        SlideForward = 330005730,
        MagIn = 1181037138,
        MagOut = {SoundId = 295387403, Volume = 0.5},
        Fire = {SoundId = 744979172, Volume = 0.4},
        DistantFire = 4788389522
    },
    Projectile = {
        Type = "Bullet",
        Velocity = 253,
        Piercing = 1,
        Amount = 1
    },
    Recoil = {
        AimScale = 0.9,
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
        ForceModifier = 3,
        SpeedModifier = 1
    },
    Offset = {
        Grip = CFrame.new(0.25, -0.7, -1.5),
        Sprint = CFrame.Angles(0.42, 0, 0),
        Aim = CFrame.new(0, -0.4825, -1.2)
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
            Max = 40,
            Min = 20
        }
    }
}
Configuration.Gamemode.Zombies = {
    FireMode = {GameEnum.FireMode.Single},
    Projectile = {
        Damage = {
            Multipliers = {
                Head = 1,
                Body = 0.75,
                Limbs = 0.2
            },
            Max = 20,
            Min = 10
        }
    }
}

return Configuration
