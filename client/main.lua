local onDuty = false

function IsOnDuty()
    return onDuty
 end

function SetOnDuty(state)
    onDuty = state and true or false
    TriggerEvent('hbs-tow:client:dutyChanged', onDuty)
end

RegisterNetEvent('hbs-tow:client:setDuty', function(state)
    SetOnDuty(state)
end)

-- ox_inventory item handler for tow_tablet
exports('useTowTablet', function()
    if not onDuty then
        lib.notify({ title = 'Tow', description = 'You must be on duty to use the tablet.', type = 'error' })
        return
    end
    TriggerEvent('hbs-tow:client:openTablet')
end)
