-- Tablet data fetching for the NUI. Mission ops live in server/job.lua.

lib.callback.register('hbs-tow:server:getStats', function(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return nil end
    local cid = player.PlayerData.citizenid
    local row = MySQL.single.await(
        'SELECT jobs_completed, total_earned FROM hbs_tow_stats WHERE citizenid = ?',
        { cid }
    )
    local track
    if GetResourceState(Config.XPResource) == 'started' then
        track = exports[Config.XPResource]:GetTrack(src, Config.XPTrack)
    end
    return {
        jobs        = (row and row.jobs_completed) or 0,
        earned      = (row and row.total_earned) or 0,
        level       = (track and track.level) or 0,
        xp          = (track and track.xp) or 0,
        xpIntoLevel = (track and track.xpIntoLevel) or 0,
        xpForNext   = (track and track.xpForNext) or 0,
    }
end)
