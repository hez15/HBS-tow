-- Hook-style attach for the depot towtruck. Attaches behind the truck on the
-- chassis bone with a tuned offset; AttachEntityToEntity is rigid so the
-- target follows naturally for all clients via parented physics.

function PerformHookAttach(truck, target)
    if not truck or not target or not DoesEntityExist(truck) or not DoesEntityExist(target) then
        return false
    end
    NetworkRequestControlOfEntity(target)
    local tries = 0
    while not NetworkHasControlOfEntity(target) and tries < 20 do
        Wait(50); NetworkRequestControlOfEntity(target); tries = tries + 1
    end
    SetEntityCollision(target, false, false)
    AttachEntityToEntity(
        target, truck, GetEntityBoneIndexByName(truck, 'chassis'),
        0.0, -3.0, 1.2,   -- offset behind truck, slightly raised
        0.0, 0.0, 0.0,
        false, false, true, false, 20, true
    )
    SetVehicleHandbrake(target, false)
    SetVehicleUndriveable(target, true)
    Wait(100)
    SetEntityCollision(target, true, true)
    return true
end
