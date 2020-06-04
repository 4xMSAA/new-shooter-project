local TableUtil = require(shared.Common.TableUtil)

local Enums = {
    {"Animation", "Affected by animating the camera"},
    {"Recoil", "Affected by weapon recoil"}
}

return TableUtil.toEnumList(script.Parent.Name, Enums)
