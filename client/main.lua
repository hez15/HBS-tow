local onDuty = false
local spawnedTruck = nil

function IsOnDuty() return onDuty end
function GetSpawnedTruck() return spawnedTruck end

local function setDuty(state)
    onDuty = state and true or false
    TriggerEvent('hbs-tow:client:dutyChanged', onDuty)
    lib.notify({
        title = 'Tow',
        description = onDuty and 'You are now on duty.' or 'You are now off duty.',
        type = onDuty and 'success' or 'inform',
    })
end

local function spawnTruck()
    if spawnedTruck and DoesEntityExist(spawnedTruck) then
        lib.notify({ title = 'Tow', description = 'You already have a truck out.', type = 'error' })
        return
    end
    local model = Config.Locations.depot.vehicle
    local hash = type(model) == 'string' and joaat(model) or model
    if not lib.requestModel(hash, 5000) then return end
    local sp = Config.Locations.depot.spawn
    local veh = CreateVehicle(hash, sp.x, sp.y, sp.z, sp.w, true, false)
    SetModelAsNoLongerNeeded(hash)
    SetVehicleEngineOn(veh, true, true, false)
    local plate = ('TOW%05d'):format(math.random(0, 99999))
    SetVehicleNumberPlateText(veh, plate)
    SetPedIntoVehicle(cache.ped, veh, -1)
    TriggerEvent('vehiclekeys:client:SetOwner', plate)
    spawnedTruck = veh
end

local function returnTruck()
    if not spawnedTruck or not DoesEntityExist(spawnedTruck) then
        lib.notify({ title = 'Tow', description = 'No truck to return.', type = 'error' })
        return
    end
    local pcoords = GetEntityCoords(cache.ped)
    local depot = Config.Locations.depot.duty
    if #(pcoords - depot) > 20.0 then
        lib.notify({ title = 'Tow', description = 'Bring it back to the depot first.', type = 'error' })
        return
    end
    DeleteEntity(spawnedTruck)
    spawnedTruck = nil
    lib.notify({ title = 'Tow', description = 'Truck returned.', type = 'success' })
end

CreateThread(function()
    local depot = Config.Locations.depot.duty
    exports.ox_target:addBoxZone({
        coords = depot,
        size = vec3(2.5, 2.5, 2.5),
        rotation = 0.0,
        debug = Config.Debug,
        options = {
            {
                name = 'hbs_tow_duty',
                icon = 'fa-solid fa-id-badge',
                label = 'Toggle Duty',
                onSelect = function() setDuty(not onDuty) end,
            },
            {
                name = 'hbs_tow_spawn',
                icon = 'fa-solid fa-truck-pickup',
                label = 'Take out tow truck',
                canInteract = function() return onDuty and (not spawnedTruck or not DoesEntityExist(spawnedTruck)) end,
                onSelect = spawnTruck,
            },
            {
                name = 'hbs_tow_return',
                icon = 'fa-solid fa-square-xmark',
                label = 'Return tow truck',
                canInteract = function() return spawnedTruck and DoesEntityExist(spawnedTruck) end,
                onSelect = returnTruck,
            },
        },
    })

    local blip = AddBlipForCoord(depot.x, depot.y, depot.z)
    SetBlipSprite(blip, 477)
    SetBlipColour(blip, 17)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(Config.Locations.depot.label)
    EndTextCommandSetBlipName(blip)
end)

-- ox_inventory item handler for tow_tablet
exports('useTowTablet', function()
    if not onDuty then
        lib.notify({ title = 'Tow', description = 'You must be on duty to use the tablet.', type = 'error' })
        return
    end
    TriggerEvent('hbs-tow:client:openTablet')
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    if spawnedTruck and DoesEntityExist(spawnedTruck) then
        DeleteEntity(spawnedTruck)
    end
end)
