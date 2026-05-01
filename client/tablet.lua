-- NUI bridge for tow_tablet. Implemented in commit #5.

local tabletOpen = false

RegisterNetEvent('hbs-tow:client:openTablet', function()
    if tabletOpen then return end
    tabletOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
end)

RegisterNUICallback('close', function(_, cb)
    tabletOpen = false
    SetNuiFocus(false, false)
    cb({ ok = true })
end)
