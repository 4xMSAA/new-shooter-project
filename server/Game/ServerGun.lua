local Maid = require(shared.Common.Maid)
local Emitter = require(shared.Common.Emitter)

-- make mount points so we can find things by string (separator is /)
local mount = require(shared.Common.Mount)
local PATH = {
    WEAPON_MODELS = mount(shared.Assets.Weapons.Models),
    WEAPON_ANIMATIONS = mount(shared.Assets.Weapons.Animations),
    WEAPON_CONFIGURATIONS = mount(shared.Assets.Weapons.Configuration)
}

local GameEnum = shared.GameEnum

---Serverside Weapon class for server-enforcement
---@class ServerGun
local ServerGun = {}
ServerGun.__index = ServerGun

function ServerGun.new(weapon, gamemode)
    assert(type(gamemode) == "string", "gamemode must be specified on creation for object by name of " .. weapon)

    -- make string to config by search or use config directly
    if typeof(weapon) == "string" then
        weapon = assert(PATH.WEAPON_CONFIGURATIONS(weapon), "did not find weapon " .. weapon)
    end

    local config = require(weapon:Clone())

    local self = {}

    -- properties
    self.AssetName = weapon.Name
    self.Configuration = config

    self.State = {
        Loaded = config.Ammo.Max,
        Max = config.Ammo.Max,
        Reserve = config.Ammo.Reserve,
        Chambered = false
    }

    self.Events = {
        Equip = Emitter.new(),
        Unequip = Emitter.new(),
        Fired = Emitter.new(),
    }

    setmetatable(self, ServerGun)
    Maid.watch(self)
    return self
end


function ServerGun:setState(statesOrKey, state)
    if typeof(statesOrKey) == "string" then
        self.State[statesOrKey] = state
        return self
    end
    for key, value in pairs(statesOrKey) do
        self.State[key] = value
    end
    return self
end


function ServerGun:fire(dt)

    if  self.State.Loaded <= 0 then
        self.Events.Fired:emit("EMPTY")
        return false
    end
    if self._Lock.Reload then
        self.Events.Fired:emit("RELOADING")
        return false
    end

    self.Events.Fired:emit("FIRE")

    self._Lock.Fire = elapsedTime()

    self:setState("Cycling", true):emitParticle("Fire"):playSound("Fire", 7)

    self:setState("Loaded", self.State.Loaded - 1)

    self:setState("Cycling", false)

end

return ServerGun