local Enums = shared.Enums

local Ready = {
    Priority = Enums.Priority.Last
}

function Ready.Run(client)
    -- perform additional checks if player is ready

    client.IsReady = true
end

return Ready
