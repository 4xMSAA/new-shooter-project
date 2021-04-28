local CONFIGURATION = {
    ENTITIES = {
        MAX_ENTITIES = 32,

        SPAWN_TIMER = 120/60,
        SPAWN_TIMER_FUNCTION = function(wave, x) return x - (x * (wave - 1) * 0.3) end,
        MIN_SPAWN_TIMER = 5/60,

        ZOMBIE = {
            HEALTH = 50,
            HEALTH_FUNCTION = function(wave, x) return x + (x * (wave - 1) * 2) end,

            SPEED = 4,
            SPEED_FUNCTION = function(wave, x) return x + (x * (wave - 1) * 1.25) end,
            MAX_SPEED = 14,

            ECONOMY = {
                REWARD_HEADSHOT_KILL = 100,
                REWARD_TORSO_KILL = 80,
                REWARD_LIMB_KILL = 70,

                REWARD_HIT = 10
            }
        }
    },

    ECONOMY = {
        REWARD_BARRICADE_BUILD = 10,
        REWARD_PERKMACHINE_PRONE_SECRET = 10
    },

    POWERUP = {
        LIFETIME = 30,
        LIFETIME_WARNING = 15,
        LIFETIME_WARNING_FAST = 5,

        POWERUP_ACTIVE_TIME = {
            INSTAKILL = 30,
            DOUBLE_POINTS = 30,
            FIRE_SALE = 60,
            DEATH_MACHINE = 60
        }
    }
}

return CONFIGURATION