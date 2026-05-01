-- tow_rope item. Rigid AttachEntityToEntity (puller-owner client) + local
-- chain prop visual. Item toggles: re-using while linked detaches.

local activeLinks = {} -- pullerNet -> { target = targetNet, prop = propEntity }

local function findRopeTarget(puller)
    local pcoords = GetEntityCoords(puller)
    local best, bestDist
    local maxDist = Config.Rope.searchDistance or 6.0
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if veh ~= puller then
            local d = #(GetEntityCoords(veh) - pcoords)
            if d < maxDist and (not bestDist or d < bestDist) then
                best, bestDist = veh, d
            end
        end
    end
    return best
end

local function spawnRopeProp(puller)
    local model = Config.Rope.propModel
    if not model then return end
    local hash = type(model) == 'string' and joaat(model) or model
    if not IsModelInCdimage(hash) then return end
    if not lib.requestModel(hash, 5000) then return end

    local x, y, z = table.unpack(GetEntityCoords(puller))
    local prop = CreateObject(hash, x, y, z, false, false, false)
    local off = Config.Rope.propOffset or vec3(0.0, -2.5, 0.0)
    AttachEntityToEntity(prop, puller, 0, off.x, off.y, off.z, 0.0, 0.0, 0.0, false, true, false, false, 1, true)
    SetModelAsNoLongerNeeded(hash)
    return prop
end

local function performRigidAttach(puller, target)
    NetworkRequestControlOfEntity(target)
    local tries = 0
    while not NetworkHasControlOfEntity(target) and tries < 20 do
        Wait(50)
        NetworkRequestControlOfEntity(target)
        tries = tries + 1
    end
    local off = Config.Rope.attachOffset or vec3(0.0, -5.0, 0.5)
    AttachEntityToEntity(target, puller, 0, off.x, off.y, off.z, 0.0, 0.0, 0.0, false, false, true, false, 20, true)
end

RegisterNetEvent('hbs-tow:client:ropeAttached', function(pullerNet, targetNet)
    local puller = NetworkGetEntityFromNetworkId(pullerNet)
    local target = NetworkGetEntityFromNetworkId(targetNet)
    if puller == 0 or target == 0 then return end

    local ped = cache.ped
    if GetVehiclePedIsIn(ped, false) == puller and GetPedInVehicleSeat(puller, -1) == ped then
        performRigidAttach(puller, target)
    end

    activeLinks[pullerNet] = { target = targetNet, prop = spawnRopeProp(puller) }
end)

RegisterNetEvent('hbs-tow:client:ropeDetached', function(pullerNet, targetNet)
    local link = activeLinks[pullerNet]
    local target = NetworkGetEntityFromNetworkId(targetNet)
    if target ~= 0 then
        local ped = cache.ped
        local puller = NetworkGetEntityFromNetworkId(pullerNet)
        if puller ~= 0 and GetVehiclePedIsIn(ped, false) == puller then
            NetworkRequestControlOfEntity(target)
        end
        DetachEntity(target, true, true)
    end
    if link and link.prop and DoesEntityExist(link.prop) then
        DeleteObject(link.prop)
    end
    activeLinks[pullerNet] = nil
end)

-- Speed cap (puller-owner enforces while linked)
CreateThread(function()
    while true do
        Wait(500)
        local ped = cache.ped
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            local pullerNet = NetworkGetNetworkIdFromEntity(veh)
            if activeLinks[pullerNet] then
                local maxSpd = Config.Rope.maxSpeed or 18.0
                if GetEntitySpeed(veh) > maxSpd then
                    SetVehicleForwardSpeed(veh, maxSpd)
                end
            end
        end
    end
end)

-- Item toggle
exports('useTowRope', function()
    local ped = cache.ped
    local puller = GetVehiclePedIsIn(ped, false)
    if puller == 0 or GetPedInVehicleSeat(puller, -1) ~= ped then
        lib.notify({ title = 'Rope', description = 'You must be driving.', type = 'error' })
        return
    end
    local pullerNet = NetworkGetNetworkIdFromEntity(puller)
    if activeLinks[pullerNet] then
        TriggerServerEvent('hbs-tow:server:detachRope', pullerNet)
        return
    end
    local target = findRopeTarget(puller)
    if not target then
        lib.notify({ title = 'Rope', description = 'No vehicle within range.', type = 'error' })
        return
    end
    TriggerServerEvent('hbs-tow:server:attachRope', pullerNet, NetworkGetNetworkIdFromEntity(target))
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    for _, link in pairs(activeLinks) do
        if link.prop and DoesEntityExist(link.prop) then DeleteObject(link.prop) end
    end
end)
