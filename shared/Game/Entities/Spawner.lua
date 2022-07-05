local Spawner = {
    Name = "Spawner",
    Groups = {"Spawner"}
}

function Spawner:init()
    self.Properties.SpawnerGroup = self.Properties.SpawnGroup
end

function Spawner:run()
    local inst = self.Properties.Instance
    local offset = CFrame.new()

    if self.Properties.RandomizeOnArea then
        offset = CFrame.new((math.random() - 0.5) * inst.Size.X, 0, (math.random() - 0.5) * inst.Size.Z/2)
    end

    return CFrame.new(inst.Position) * CFrame.lookAt(Vector3.new(), inst.CFrame.LookVector) * offset
end

function Spawner:getSpawnerGroup()
    return self.Properties.SpawnerGroup
end


return Spawner
