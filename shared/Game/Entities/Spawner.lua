local Spawner = {
    Name = "Spawner",
}

function Spawner:init()
    self.Properties.SpawnerGroup = self.Properties.Instance:GetAttribute("SpawnGroup")
end

function Spawner:run()
    local inst = self.Properties.Instance

    return CFrame.new(inst.Position) * CFrame.lookAt(Vector3.new(), inst.CFrame.LookVector)
end

function Spawner:getSpawnerGroup()
    return self.Properties.SpawnerGroup
end


return Spawner
