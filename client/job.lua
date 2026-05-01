-- Tow mission state machine. States:
--   IDLE           : no mission
--   HEADING_PICKUP : blip on pickup
--   AT_PICKUP      : within proximity of pickup; ox_target on target adds Hook option
--   HOOKED         : target attached to towtruck; blip on impound
--   AT_IMPOUND     : ox_target on towtruck adds Detach & Complete option

local STATE = { IDLE='IDLE', HEADING_PICKUP='HEADING_PICKUP', AT_PICKUP='AT_PICKUP', HOOKED='HOOKED', AT_IMPOUND='AT_IMPOUND' }

local state    = STATE.IDLE
local mission  = nil
local blip     = nil
local targetTargets = nil
local truckTargets  = nil

function GetActiveMission() return mission end
function GetMissionState()  return state end

local function clearBlip()
    if blip and DoesBlipExist(blip) then RemoveBlip(blip) end
    blip = nil
end

local function setBlip(coords, label, sprite, colour)
    clearBlip()
    blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite or 1)
    SetBlipColour(blip, colour or 5)
    SetBlipRoute(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label or 'Tow')
    EndTextCommandSetBlipName(blip)
end

local function clearTargetTargets()
    if targetTargets then
        for _, name in ipairs(targetTargets.names) do
            exports.ox_target:removeLocalEntity(targetTargets.entity, name)
        end
    end
    targetTargets = nil
end

local function clearTruckTargets()
    if truckTargets then
        for _, name in ipairs(truckTargets.names) do
            exports.ox_target:removeLocalEntity(truckTargets.entity, name)
        end
    end
    truckTargets = nil
end

local function attachToTruck(target)
    local truck = GetSpawnedTruck and GetSpawnedTruck() or nil
    if not truck or not DoesEntityExist(truck) then
        lib.notify({ title = 'Tow', description = 'Bring your tow truck closer.', type = 'error' })
        return false
    end
    if #(GetEntityCoords(target) - GetEntityCoords(truck)) > (Config.Job.attachDistance or 4.0) + 4.0 then
        lib.notify({ title = 'Tow', description = 'Park the tow truck closer to the vehicle.', type = 'error' })
        return false
    end
    NetworkRequestControlOfEntity(target)
    local tries = 0
    while not NetworkHasControlOfEntity(target) and tries < 20 do
        Wait(50); NetworkRequestControlOfEntity(target); tries = tries + 1
    end
    if PerformHookAttach then return PerformHookAttach(truck, target) end
    AttachEntityToEntity(target, truck, 0, 0.0, -5.0, 1.0, 0.0, 0.0, 0.0, false, false, true, false, 20, true)
    return true
end

local function setupTargetOnVehicle(targetEntity)
    exports.ox_target:addLocalEntity(targetEntity, {
        {
            name = 'hbs_tow_hook',
            icon = 'fa-solid fa-link',
            label = 'Hook to Tow Truck',
            distance = 3.0,
            onSelect = function(data)
                local entity = data and data.entity or targetEntity
                local ok = lib.progressBar({
                    duration = 3500,
                    label = 'Hooking up...',
                    canCancel = false,
                    disable = { move = true, car = true, combat = true },
                    anim = { dict = 'amb@medic@standing@kneel@base', clip = 'base' },
                })
                if ok and attachToTruck(entity) then
                    state = STATE.HOOKED
                    clearTargetTargets()
                    setBlip(Config.Locations.impound.point, 'Central Impound', 67, 5)
                    setupTargetOnTruck(GetSpawnedTruck())
                end
            end,
        },
    })
    targetTargets = { entity = targetEntity, names = { 'hbs_tow_hook' } }
end

function setupTargetOnTruck(truck)
    if not truck or not DoesEntityExist(truck) then return end
    exports.ox_target:addLocalEntity(truck, {
        {
            name = 'hbs_tow_drop',
            icon = 'fa-solid fa-flag-checkered',
            label = 'Detach & Complete',
            distance = 3.0,
            canInteract = function() return state == STATE.AT_IMPOUND end,
            onSelect = function()
                local target = mission and NetworkGetEntityFromNetworkId(mission.targetNet) or 0
                if target ~= 0 then
                    NetworkRequestControlOfEntity(target)
                    DetachEntity(target, true, true)
                end
                TriggerServerEvent('hbs-tow:server:completeCall')
            end,
        },
    })
    truckTargets = { entity = truck, names = { 'hbs_tow_drop' } }
end

local function polishExtra(ex, targetNet)
    CreateThread(function()
        local tries = 0
        while tries < 60 do
            local entity = NetworkGetEntityFromNetworkId(ex.netId)
            if entity ~= 0 and DoesEntityExist(entity) then
                if ex.type == 'driver' then
                    TaskStartScenarioInPlace(entity, 'WORLD_HUMAN_HANG_OUT_STREET', 0, true)
                elseif ex.type == 'ticket' then
                    local target = NetworkGetEntityFromNetworkId(targetNet)
                    if target ~= 0 then
                        NetworkRequestControlOfEntity(entity)
                        AttachEntityToEntity(
                            entity, target, 0,
                            0.4, 0.7, 0.6,
                            0.0, 0.0, 0.0,
                            false, true, false, false, 1, true
                        )
                    end
                end
                return
            end
            Wait(1000)
            tries = tries + 1
        end
    end)
end

RegisterNetEvent('hbs-tow:client:missionAccepted', function(call)
    if state ~= STATE.IDLE then return end
    mission = call
    state   = STATE.HEADING_PICKUP
    setBlip(call.coords, ('Tow: %s'):format(call.label), 67, 5)
    lib.notify({
        title = 'Tow',
        description = ('New job: %s in %s'):format(call.label, call.district or 'LS'),
        type = 'inform',
    })
    if call.extras then
        for _, ex in ipairs(call.extras) do polishExtra(ex, call.targetNet) end
    end
end)

RegisterNetEvent('hbs-tow:client:missionEnded', function()
    state = STATE.IDLE
    mission = nil
    clearBlip()
    clearTargetTargets()
    clearTruckTargets()
end)

RegisterNetEvent('hbs-tow:client:missionCompleted', function(result)
    state = STATE.IDLE
    mission = nil
    clearBlip()
    clearTargetTargets()
    clearTruckTargets()
    lib.notify({
        title = 'Tow Complete',
        description = ('+$%d  +%d XP'):format(result.pay, result.xp),
        type = 'success',
    })
end)

CreateThread(function()
    while true do
        Wait(1000)
        if state == STATE.HEADING_PICKUP and mission then
            local pcoords = GetEntityCoords(cache.ped)
            if #(pcoords - vector3(mission.coords.x, mission.coords.y, mission.coords.z)) < 50.0 then
                local target = NetworkGetEntityFromNetworkId(mission.targetNet)
                if target ~= 0 and DoesEntityExist(target) then
                    state = STATE.AT_PICKUP
                    setupTargetOnVehicle(target)
                end
            end
        elseif state == STATE.HOOKED then
            local pcoords = GetEntityCoords(cache.ped)
            if #(pcoords - Config.Locations.impound.point) < (Config.Job.detachAtImpound or 8.0) + 6.0 then
                state = STATE.AT_IMPOUND
            end
        elseif state == STATE.AT_IMPOUND then
            local pcoords = GetEntityCoords(cache.ped)
            if #(pcoords - Config.Locations.impound.point) > 30.0 then
                state = STATE.HOOKED
            end
        end
    end
end)

RegisterCommand('towabandon', function()
    if state == STATE.IDLE then return end
    TriggerServerEvent('hbs-tow:server:abandonCall')
end, false)
TriggerEvent('chat:addSuggestion', '/towabandon', 'Abandon your active tow mission')
