local SPAWN_GROUP_RUNNER = {
    ["Zombie"] = function(self)

    end,

    ["Player"] = function(self)
        local inst = self.Properties.Instance

        return CFrame.new(inst.Position) * CFrame.lookAt(Vector3.new(), inst.CFrame.LookVector)
    end
}


local Spawner = {
    Name = "Spawner",
}

function Spawner:run()
    return SPAWN_GROUP_RUNNER[self:getSpawnerGroup()](self)
end

function Spawner:getSpawnerGroup()
    return self.Properties.SpawnerGroup
end


return Spawner
