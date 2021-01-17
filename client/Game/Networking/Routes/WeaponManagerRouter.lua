local Players = game:GetService("Players")

local Enums = shared.Enums

return function(router, manager)
    router:on(
        Enums.PacketType.WeaponRegister,
        function(assetName, uuid, player)
            local gun = manager:create(assetName, uuid)
            manager:register(gun, uuid, player)
        end
    ):on(
        Enums.PacketType.WeaponEquip,
        function(uuid, player)
            if player == Players.LocalPlayer then
                manager:equipViewport(uuid, true)
            else
                manager:equip(uuid, player)
            end
        end
    ):on(
        Enums.PacketType.WeaponReload,
        function(uuid, player)
            manager:reload()
        end
    )
end
