-- Wheel boot server. Implementation lands in commit #2.
--
-- Stable export surface for hbs-mdt:
--   ApplyBoot(plate, leoCid, fine, reason) -> ok, err
--   RemoveBoot(plate, reason)              -> ok, err
--   GetBoot(plate)                          -> row | nil
--   ListBoots()                             -> rows[]

local function notImplemented()
    return false, 'hbs-tow boot system not yet implemented'
end

exports('ApplyBoot',  function(plate, leoCid, fine, reason) return notImplemented() end)
exports('RemoveBoot', function(plate, reason)               return notImplemented() end)
exports('GetBoot',    function(plate)                       return nil end)
exports('ListBoots',  function()                            return {} end)
