-- Wheel boot server.
-- Exports for hbs-mdt:
--   ApplyBoot(plate, leoCid, fine, reason) -> ok, err
--   RemoveBoot(plate, reason)              -> ok, err
--   GetBoot(plate)                          -> row | nil
--   ListBoots()                             -> rows[]

local boots = {} -- normalized plate -> row

local function normalizePlate(p)
    if not p then return nil end
    return string.upper((tostring(p):gsub('%s+', '')))
end

local function listPlates()
    local out = {}
    for p in pairs(boots) do out[#out+1] = p end
    return out
end

local function loadBoots()
    local rows = MySQL.query.await('SELECT plate, applied_by, applied_at, fine, reason FROM hbs_tow_boots') or {}
    for _, row in ipairs(rows) do
        boots[normalizePlate(row.plate)] = row
    end
    print(('[hbs-tow] loaded %d active boots'):format(#rows))
end

CreateThread(loadBoots)

local function applyBoot(plate, leoCid, fine, reason)
    plate = normalizePlate(plate)
    if not plate or plate == '' then return false, 'invalid plate' end
    if boots[plate] then return false, 'already booted' end

    local row = {
        plate      = plate,
        applied_by = leoCid or 'system',
        applied_at = os.date('%Y-%m-%d %H:%M:%S'),
        fine       = tonumber(fine) or 0,
        reason     = reason,
    }
    MySQL.insert.await(
        'INSERT INTO hbs_tow_boots (plate, applied_by, fine, reason) VALUES (?, ?, ?, ?)',
        { row.plate, row.applied_by, row.fine, row.reason }
    )
    boots[plate] = row
    TriggerClientEvent('hbs-tow:client:bootApplied', -1, row)
    TriggerEvent('hbs-tow:server:bootApplied', row.plate, row.applied_by, row.fine)
    return true
end

local function removeBoot(plate, reason)
    plate = normalizePlate(plate)
    if not plate or not boots[plate] then return false, 'not booted' end
    MySQL.query.await('DELETE FROM hbs_tow_boots WHERE plate = ?', { plate })
    boots[plate] = nil
    TriggerClientEvent('hbs-tow:client:bootRemoved', -1, plate)
    TriggerEvent('hbs-tow:server:bootRemoved', plate, reason)
    return true
end

exports('ApplyBoot',  function(plate, leoCid, fine, reason) return applyBoot(plate, leoCid, fine, reason) end)
exports('RemoveBoot', function(plate, reason)               return removeBoot(plate, reason) end)
exports('GetBoot',    function(plate)                       return boots[normalizePlate(plate)] end)
exports('ListBoots',  function()
    local out = {}
    for _, row in pairs(boots) do out[#out+1] = row end
    return out
end)

local function isLeo(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return false end
    local job = player.PlayerData.job
    if job.type == 'leo' then return true end
    for _, name in ipairs(Config.Boot.policeJobs or {}) do
        if job.name == name then return true end
    end
    return false
end

local function getCitizenId(src)
    local player = exports.qbx_core:GetPlayer(src)
    return player and player.PlayerData.citizenid or nil
end

RegisterNetEvent('hbs-tow:server:applyBoot', function(plate, fine, reason)
    local src = source
    if not isLeo(src) then return end

    local removed = exports.ox_inventory:RemoveItem(src, Config.Boot.itemName, 1)
    if not removed then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Boot', description = 'You don\'t have a wheel boot.', type = 'error' })
        return
    end

    local ok, err = applyBoot(plate, getCitizenId(src), fine or Config.Boot.defaultFine, reason or 'LEO action')
    if not ok then
        exports.ox_inventory:AddItem(src, Config.Boot.itemName, 1)
        TriggerClientEvent('ox_lib:notify', src, { title = 'Boot', description = err or 'failed', type = 'error' })
        return
    end
    TriggerClientEvent('ox_lib:notify', src, { title = 'Boot', description = ('Applied to %s'):format(plate), type = 'success' })
end)

RegisterNetEvent('hbs-tow:server:removeBoot', function(plate)
    local src = source
    if not isLeo(src) then return end
    local ok, err = removeBoot(plate, 'LEO removal')
    if not ok then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Boot', description = err or 'failed', type = 'error' })
        return
    end
    exports.ox_inventory:AddItem(src, Config.Boot.itemName, 1)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Boot', description = ('Removed from %s'):format(plate), type = 'success' })
end)

lib.callback.register('hbs-tow:server:getBootedPlates', function(_)
    return listPlates()
end)
