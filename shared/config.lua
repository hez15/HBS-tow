Config = {}

Config.Debug = false

-- Resource integrations
Config.MDTResource = 'hbs-mdt'
Config.XPResource  = 'nonstop-xp'
Config.XPTrack     = 'towing'
Config.PayoutPerk  = 'jobPayoutMult'

-- Theme (mirrored in NUI for consistency)
Config.Theme = {
    primary = '#e35203',
}

-- Tow job
Config.Job = {
    requiredJob     = 'tow',         -- qbx job name required to be on duty / accept calls
    maxActiveCalls  = 3,
    callTTLSeconds  = 600,
    spawnRadiusMin  = 100.0,
    spawnRadiusMax  = 200.0,
    attachDistance  = 4.0,
    detachAtImpound = 8.0,
}

-- Tow rope item (utility, any player). Tool, not consumed on use.
Config.Rope = {
    itemName       = 'tow_rope',
    maxSpeed       = 18.0,
    searchDistance = 6.0,
    attachOffset   = vec3(0.0, -5.0, 0.5),
    propModel      = 'prop_air_chain_01a',
    propOffset     = vec3(0.0, -2.5, 0.0),
}

-- Wheel boot (police)
Config.Boot = {
    itemName      = 'wheel_boot',
    applySeconds  = 5,
    removeSeconds = 5,
    defaultFine   = 500,
    propModel     = 'imp_prop_impexp_wheel_clamp_01a',
    policeJobs    = { 'police', 'sasp', 'sheriff' },
    cachePollSec  = 2,
    streamRadius  = 80.0,
}
