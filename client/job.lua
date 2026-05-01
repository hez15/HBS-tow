-- Tow job state machine. Implemented in commit #4.

local activeMission = nil

function GetActiveMission()
    return activeMission
end

RegisterNetEvent('hbs-tow:client:missionAccepted', function(mission)
    activeMission = mission
end)

RegisterNetEvent('hbs-tow:client:missionEnded', function()
    activeMission = nil
end)
