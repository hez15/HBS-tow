-- Tow rope server. Authoritative state for puller<->target links.

local links = {}        -- pullerNet -> { puller, target, ownerSrc, ts }
local targetIndex = {}  -- targetNet -> pullerNet

local function isLinked(net)
    return links[net] ~= nil or targetIndex[net] ~= nil
end

RegisterNetEvent('hbs-tow:server:attachRope', function(pullerNet, targetNet)
    local src = source
    if not pullerNet or not targetNet or pullerNet == targetNet then return end
    if isLinked(pullerNet) or isLinked(targetNet) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Rope', description = 'Already linked.', type = 'error' })
        return
    end

    if (exports.ox_inventory:GetItemCount(src, Config.Rope.itemName) or 0) < 1 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Rope', description = 'You don\'t have a tow rope.', type = 'error' })
        return
    end

    local target = NetworkGetEntityFromNetworkId(targetNet)
    if target == 0 then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Rope', description = 'Target unavailable.', type = 'error' })
        return
    end

    local plate = GetVehicleNumberPlateText(target)
    if plate and exports['hbs-tow']:GetBoot((plate:gsub('%s+', ''):upper())) then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Rope', description = 'That vehicle is booted.', type = 'error' })
        return
    end

    links[pullerNet] = {
        puller = pullerNet,
        target = targetNet,
        ownerSrc = src,
        ts = os.time(),
    }
    targetIndex[targetNet] = pullerNet
    TriggerClientEvent('hbs-tow:client:ropeAttached', -1, pullerNet, targetNet)
end)

local function clearLink(pullerNet)
    local link = links[pullerNet]
    if not link then return end
    links[pullerNet] = nil
    targetIndex[link.target] = nil
    TriggerClientEvent('hbs-tow:client:ropeDetached', -1, link.puller, link.target)
end

RegisterNetEvent('hbs-tow:server:detachRope', function(pullerNet)
    local src = source
    local link = links[pullerNet]
    if not link or link.ownerSrc ~= src then return end
    clearLink(pullerNet)
end)

AddEventHandler('playerDropped', function()
    local src = source
    for net, link in pairs(links) do
        if link.ownerSrc == src then clearLink(net) end
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    for net in pairs(links) do clearLink(net) end
end)
