return {
    LOADING = {
        TIMEOUT = 30,
    },

    WEAPON = {
        SWAY_AMPLIFY = 0.025,
        SWAY_SPEED = 0.8,
        ADS_SWAY_MODIFIER = 0.06,

        MOVEMENT_AMPLIFY = 0.05,
        MOVEMENT_SPEED = 8,
        MOVEMENT_RECOVERY_SPEED = 0.7,

        ADS_MOVEMENT_MODIFIER = 0.2,

        AIM_SPEED = 4,
        AIM_STYLE = "sine",

        INERTIA_MODIFIER = 0.6,
        INERTIA_RECOVERY_SPEED = 1.5,

        RECOIL_POSITION_DAMPENING = 1.8,
        RECOIL_POSITION_SPEED = 1,

        RECOIL_ANGULAR_DAMPENING = 2,
        RECOIL_ANGULAR_SPEED = 1.5,


    },
    VIEWMODEL = {
        LEFT_ARM_PIVOT = "LeftHand",
        RIGHT_ARM_PIVOT = "RightHand",

        DEFAULT_ARMS = "Default"
    },

    CAMERA = {
        LIMIT_YAW = 87,
        RECOIL_ANGULAR_DAMPENING = 2,
        RECOIL_ANGULAR_SPEED = 1.5,
    },

    PROJECTILE = {
        GRAVITY_MODIFIER = 1/60,
        VELOCITY_MODIFIER = 0.6,

        ITERATION_PRECISION = 1/20,
        MAX_ITERATIONS_PER_FRAME = 5
    },

    MOVEMENT = {
        FRICTION = 0.15,
        ACCELERATION_SPEED = 1/0.4
    }
}
