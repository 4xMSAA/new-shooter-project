local Enums = shared.Enums

local assetName = script.Name

local Configuration = {
    Name = "M1 Garand",
    ModelPath = assetName,
    AnimationPath = assetName,
    ActionType = Enums.GunActionType.ClosedBolt,
    RPM = 444,
    FireMode = {Enums.FireMode.Single},
    EquipTime = 0.88,
    Zoom = 1.45,
    Ammo = {
        Max = 8,
        Reserve = 120,
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
        Amount = 1
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
    CameraRecoil = {
        V3 = Vector3.new(0.6, 0, 0),
        Range = Vector3.new(0.1, 0.3, 0),
        ForceModifier = 1,
        SpeedModifier = 1
    },
    Offset = {
        Grip = CFrame.new(0.6, -1, -0.8),
        Sprint = CFrame.Angles(0, 0.5, 0),
        Aim = CFrame.new(0, -0.46, -0.6)
    },
    InterpolateSpeed = {
        Aim = 1
    }
}

Configuration.Gamemode = {}
Configuration.Gamemode.PvP = {
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
Configuration.Gamemode.Zombies = {
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

Configuration.On = {}
Configuration.On.Empty = function(self)
    self:playSound("ClipFling")
end

return Configuration
