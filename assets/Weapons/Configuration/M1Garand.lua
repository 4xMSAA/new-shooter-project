local Enums = shared.Enums

local assetName = script.Parent.Name

local Configuration = {
    Name = "M1 Garand",
    ModelPath = assetName,

    RPM = 444,
    FireMode = {Enums.FireMode.Single, Enums.FireMode.Safety},

}

return Configuration