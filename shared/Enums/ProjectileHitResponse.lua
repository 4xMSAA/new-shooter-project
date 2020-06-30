local TableUtil = require(shared.Common.TableUtil)

local Enums = {
    {"Stop", "Default behaviour. Stops further simulation for the projectile"},
    {"Continue", "Projectile can continue simulating"}
}

return TableUtil.toEnumList(script.Parent.Name, Enums)