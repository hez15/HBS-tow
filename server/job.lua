-- Tow job server: mission generation, claim/payout, XP, stats.

local nextCallId    = 1
local activeCalls   = {}    -- callId -> call
local playerMission = {}    -- src -> callId

local function getDriverLevel(src)
    if GetResourceState(Config.XPResource) ~= 'started' then return 0 end
    local track = exports[Config.XPResource]:GetTrack(src, Config.XPTrack)
    return (track and track.level) or 0
end

local function weightedPick(variants, level)
    local pool = {}
    for key, v in pairs(variants) do
        if (v.minLevel or 0) <= level then
            for _ = 1, (v.weight or 1) do pool[#pool+1] = key end
        end
    end
    if #pool == 0 then return nil end
    return pool[math.random(#pool)]
 end

local function generateCall()
    -- Generate against the highest tier so all variants appear in the pool;
    -- per-player gating happens at accept time.
    local variantKey = weightedPick(Config.MissionVariants, 100)
    if not variantKey then return nil end
    local variant = Config.MissionVariants[variantKey]
    local spawn = Config.MissionSpawns[math.random(#Config.MissionSpawns)]
    local pool = Config.MissionVehicles[variantKey] or { 'sultan' }
    local model = pool[math.random(#pool)]

    local id = nextCallId; nextCallId = nextCallId + 1
    local call = {
        id        = id,
        variant   = variantKey,
        label     = variant.label,
        model     = model,
        coords    = spawn.coords,
        district  = spawn.district,
        basePay   = variant.basePay,
        xp        = variant.xp,
        minLevel  = variant.minLevel,
        claimedBy = nil,
        expiresAt = os.time() + (Config.Job.callTTLSeconds or 600),
    }
    activeCalls[id] = call
    return call
end

local function pruneAndRefill()
    local now = os.time()
    for id, c in pairs(activeCalls) do
        if c.expiresAt <= now and not c.claimedBy then activeCalls[id] = nil end
    end
    local count = 0
    for _, c in pairs(activeCalls) do
        if not c.claimedBy then count = count + 1 end
    end
    while count < (Config.Job.maxActiveCalls or 3) do
        if not generateCall() then break end
        count = count + 1
    end
end

CreateThread(function()
    while true do
        pruneAndRefill()
        Wait(30000)
    end
end)

local function listAvailableForPlayer(src)
    local now = os.time()
    local level = getDriverLevel(src)
    local out = {}
    for _, c in pairs(activeCalls) do
        if c.expiresAt > now and not c.claimedBy then
            out[#out+1] = {
                id       = c.id,
                variant  = c.variant,
                label    = c.label,
                model    = c.model,
                coords   = c.coords,
                district = c.district,
                basePay  = c.basePay,
                xp       = c.xp,
                minLevel = c.minLevel,
                locked   = (c.minLevel or 0) > level,
            }
        end
    end
    return out
end

lib.callback.register('hbs-tow:server:listCalls', function(src)
    return listAvailableForPlayer(src)
end)

local function decorateForVariant(entity, variant)
    SetVehicleDoorsLocked(entity, 2)
    if variant == 'abandoned' then
        SetVehicleDirtLevel(entity, 12.0)
        SetVehicleTyreBurst(entity, 0, true, 1000.0)
    elseif variant == 'accident' then
        SetVehicleEngineHealth(entity, 200.0)
        SetVehicleBodyHealth(entity, 350.0)
        SetVehicleDirtLevel(entity, 6.0)
    elseif variant == 'illegal_parking' then
        SetVehicleDirtLevel(entity, 2.0)
    elseif variant == 'vip_recovery' then
        SetVehicleDirtLevel(entity, 0.0)
    end
end

local function spawnTarget(call)
    local hash = joaat(call.model)
    local entity = CreateVehicleServerSetter(hash, 'automobile', call.coords.x, call.coords.y, call.coords.z, call.coords.w)
    if not entity or entity == 0 then return nil end
    decorateForVariant(entity, call.variant)
    return entity
end

lib.callback.register('hbs-tow:server:acceptCall', function(src, callId)
    local call = activeCalls[callId]
    if not call or call.claimedBy then return false, 'unavailable' end
    if (call.minLevel or 0) > getDriverLevel(src) then return false, 'level too low' end
    if playerMission[src] then return false, 'already on a job' end

    local entity = spawnTarget(call)
    if not entity then return false, 'spawn failed' end
    call.targetEntity = entity
    call.targetNetId  = NetworkGetNetworkIdFromEntity(entity)
    call.claimedBy    = src
    playerMission[src] = callId

    return true, {
        id        = call.id,
        variant   = call.variant,
        label     = call.label,
        model     = call.model,
        coords    = call.coords,
        district  = call.district,
        basePay   = call.basePay,
        xp        = call.xp,
        targetNet = call.targetNetId,
        impound   = Config.Locations.impound.point,
    }
end)

local function releaseCall(callId, deleteEntity)
    local call = activeCalls[callId]
    if not call then return end
    if deleteEntity and call.targetEntity and DoesEntityExist(call.targetEntity) then
        DeleteEntity(call.targetEntity)
    end
    activeCalls[callId] = nil
end

RegisterNetEvent('hbs-tow:server:abandonCall', function()
    local src = source
    local callId = playerMission[src]
    if not callId then return end
    releaseCall(callId, true)
    playerMission[src] = nil
    TriggerClientEvent('hbs-tow:client:missionEnded', src)
end)

RegisterNetEvent('hbs-tow:server:completeCall', function()
    local src = source
    local callId = playerMission[src]
    if not callId then return end
    local call = activeCalls[callId]
    if not call then return end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local pcoords = GetEntityCoords(ped)
    if #(pcoords - Config.Locations.impound.point) > 30.0 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Tow', description = 'You must be at the impound to complete.', type = 'error' })
        return
    end

    local mult = 1.0
    if GetResourceState(Config.XPResource) == 'started' then
        mult = exports[Config.XPResource]:GetPerk(src, Config.XPTrack, Config.PayoutPerk) or 1.0
    end
    local pay = math.floor(call.basePay * mult)

    local player = exports.qbx_core:GetPlayer(src)
    if player then
        player.Functions.AddMoney('cash', pay, ('tow_%s'):format(call.variant))
    end

    if GetResourceState(Config.XPResource) == 'started' then
        exports[Config.XPResource]:AddXP(src, call.xp, 'tow_'..call.variant, Config.XPTrack)
    end

    local cid = player and player.PlayerData.citizenid
    if cid then
        MySQL.query.await([[
            INSERT INTO hbs_tow_stats (citizenid, jobs_completed, total_earned)
            VALUES (?, 1, ?)
            ON DUPLICATE KEY UPDATE jobs_completed = jobs_completed + 1, total_earned = total_earned + VALUES(total_earned)
        ]], { cid, pay })
    end

    releaseCall(callId, true)
    playerMission[src] = nil
    TriggerClientEvent('hbs-tow:client:missionCompleted', src, { pay = pay, xp = call.xp })
end)

AddEventHandler('playerDropped', function()
    local src = source
    local callId = playerMission[src]
    if callId then
        releaseCall(callId, true)
        playerMission[src] = nil
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    for id, c in pairs(activeCalls) do
        if c.targetEntity and DoesEntityExist(c.targetEntity) then
            DeleteEntity(c.targetEntity)
        end
    end
end)
