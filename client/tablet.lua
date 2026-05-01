-- NUI bridge for tow_tablet. Translates fetch() calls from the React app
-- to ox_lib server callbacks and forwards mission acceptance into the
-- client mission state machine.

local tabletOpen = false

RegisterNetEvent('hbs-tow:client:openTablet', function()
    if tabletOpen then return end
    tabletOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open' })
end)

local function closeTablet()
    tabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNUICallback('close', function(_, cb)
    closeTablet()
    cb({ ok = true })
end)

RegisterNUICallback('getCalls', function(_, cb)
    cb(lib.callback.await('hbs-tow:server:listCalls', false) or {})
end)

RegisterNUICallback('getStats', function(_, cb)
    cb(lib.callback.await('hbs-tow:server:getStats', false) or {})
end)

RegisterNUICallback('getActive', function(_, cb)
    cb(lib.callback.await('hbs-tow:server:getActive', false))
end)

RegisterNUICallback('getHistory', function(_, cb)
    cb(lib.callback.await('hbs-tow:server:getHistory', false) or {})
end)

RegisterNUICallback('acceptCall', function(data, cb)
    local ok, payload = lib.callback.await('hbs-tow:server:acceptCall', false, data and data.id)
    if ok then
        TriggerEvent('hbs-tow:client:missionAccepted', payload)
    end
    cb({ ok = ok, error = (not ok) and payload or nil })
end)

RegisterNUICallback('abandon', function(_, cb)
    TriggerServerEvent('hbs-tow:server:abandonCall')
    cb({ ok = true })
end)
