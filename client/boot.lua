-- Wheel boot client. Maintains a local cache of booted plates and re-asserts
-- immobilization + visual prop on any nearby plate in the cache.

local bootedPlates = {} -- set: plate -> true
local bootProps    = {} -- vehicle netid -> prop entity

local function normalizePlate(p)
    if not p then return nil end
    return string.upper((tostring(p):gsub('%s+', '')))
end

local function vehiclePlate(veh)
    return normalizePlate(GetVehicleNumberPlateText(veh))
end

local function attachBootProp(veh)
    local model = Config.Boot.propModel
    if not model then return end
    local hash = type(model) == 'string' and joaat(model) or model
    if not IsModelInCdimage(hash) then return end
    if not lib.requestModel(hash, 5000) then return end

    local x, y, z = table.unpack(GetEntityCoords(veh))
    local prop = CreateObject(hash, x, y, z, false, false, false)
    local boneIndex = GetEntityBoneIndexByName(veh, 'wheel_lf')
    if boneIndex ~= -1 then
        AttachEntityToEntity(prop, veh, boneIndex, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, true, false, false, 1, true)
    else
        AttachEntityToEntity(prop, veh, 0, -1.0, 1.5, -0.4, 0.0, 90.0, 0.0, false, true, false, false, 1, true)
    end
    SetModelAsNoLongerNeeded(hash)
    return prop
end

local function ensureImmobilized(veh)
    SetVehicleUndriveable(veh, true)
    SetVehicleEngineOn(veh, false, true, true)
    SetVehicleHandbrake(veh, true)
    local netId = NetworkGetNetworkIdFromEntity(veh)
    if not bootProps[netId] or not DoesEntityExist(bootProps[netId]) then
        bootProps[netId] = attachBootProp(veh)
    end
end

local function clearImmobilization(veh)
    SetVehicleUndriveable(veh, false)
    local netId = NetworkGetNetworkIdFromEntity(veh)
    if bootProps[netId] and DoesEntityExist(bootProps[netId]) then
        DeleteObject(bootProps[netId])
    end
    bootProps[netId] = nil
end

RegisterNetEvent('hbs-tow:client:bootApplied', function(row)
    bootedPlates[normalizePlate(row.plate)] = true
end)

RegisterNetEvent('hbs-tow:client:bootRemoved', function(plate)
    local norm = normalizePlate(plate)
    bootedPlates[norm] = nil
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if vehiclePlate(veh) == norm then clearImmobilization(veh) end
    end
end)

CreateThread(function()
    Wait(2000) -- let server load cache
    local plates = lib.callback.await('hbs-tow:server:getBootedPlates', false)
    for _, p in ipairs(plates or {}) do
        bootedPlates[normalizePlate(p)] = true
    end
end)

CreateThread(function()
    while true do
        Wait((Config.Boot.cachePollSec or 2) * 1000)
        local pcoords = GetEntityCoords(cache.ped)
        local radius = Config.Boot.streamRadius or 80.0
        for _, veh in ipairs(GetGamePool('CVehicle')) do
            if #(GetEntityCoords(veh) - pcoords) < radius then
                local plate = vehiclePlate(veh)
                if plate and bootedPlates[plate] then
                    ensureImmobilized(veh)
                end
            end
        end
    end
end)

local function applyBootAction(data)
    local veh = data and data.entity or nil
    if not veh or not DoesEntityExist(veh) then
        lib.notify({ title = 'Boot', description = 'No vehicle.', type = 'error' })
        return
    end
    local plate = vehiclePlate(veh)
    if bootedPlates[plate] then
        lib.notify({ title = 'Boot', description = 'Already booted.', type = 'error' })
        return
    end
    local ok = lib.progressBar({
        duration = (Config.Boot.applySeconds or 5) * 1000,
        label = 'Applying boot...',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'amb@medic@standing@kneel@base', clip = 'base' },
    })
    if ok then
        TriggerServerEvent('hbs-tow:server:applyBoot', plate, Config.Boot.defaultFine, 'street boot')
    end
end

local function removeBootAction(data)
    local veh = data and data.entity or nil
    if not veh or not DoesEntityExist(veh) then
        lib.notify({ title = 'Boot', description = 'No vehicle.', type = 'error' })
        return
    end
    local plate = vehiclePlate(veh)
    if not bootedPlates[plate] then
        lib.notify({ title = 'Boot', description = 'Not booted.', type = 'error' })
        return
    end
    local ok = lib.progressBar({
        duration = (Config.Boot.removeSeconds or 5) * 1000,
        label = 'Removing boot...',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'amb@medic@standing@kneel@base', clip = 'base' },
    })
    if ok then
        TriggerServerEvent('hbs-tow:server:removeBoot', plate)
    end
end

-- ox_inventory item shortcut: targets nearest vehicle within 4m
exports('useWheelBoot', function()
    local pcoords = GetEntityCoords(cache.ped)
    local best, bestDist
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        local d = #(GetEntityCoords(veh) - pcoords)
        if d < 4.0 and (not bestDist or d < bestDist) then
            best, bestDist = veh, d
        end
    end
    if not best then
        lib.notify({ title = 'Boot', description = 'No vehicle nearby.', type = 'error' })
        return
    end
    local plate = vehiclePlate(best)
    if bootedPlates[plate] then
        removeBootAction({ entity = best })
    else
        applyBootAction({ entity = best })
    end
end)

CreateThread(function()
    exports.ox_target:addGlobalVehicle({
        {
            name = 'hbs_tow_apply_boot',
            icon = 'fa-solid fa-lock',
            label = 'Apply Wheel Boot',
            distance = 2.0,
            items = Config.Boot.itemName,
            canInteract = function(entity)
                local plate = vehiclePlate(entity)
                return plate and not bootedPlates[plate]
            end,
            onSelect = applyBootAction,
        },
        {
            name = 'hbs_tow_remove_boot',
            icon = 'fa-solid fa-unlock',
            label = 'Remove Wheel Boot',
            distance = 2.0,
            items = Config.Boot.itemName,
            canInteract = function(entity)
                local plate = vehiclePlate(entity)
                return plate and bootedPlates[plate]
            end,
            onSelect = removeBootAction,
        },
    })
end)
