Config = {}

Config.Debug = false

-- Resource integrations
Config.MDTResource = 'hbs-mdt'
Config.XPResource  = 'nonstop-xp'
Config.XPTrack     = 'driving'
Config.PayoutPerk  = 'jobPayoutMult'

-- Theme (mirrored in NUI for consistency)
Config.Theme = {
    primary = '#e35203',
}

-- Tow job
Config.Job = {
    maxActiveCalls  = 3,
    callTTLSeconds  = 600,
    spawnRadiusMin  = 100.0,
    spawnRadiusMax  = 200.0,
    attachDistance  = 4.0,
    detachAtImpound = 8.0,
}

-- Tow rope item (utility, any player)
Config.Rope = {
    itemName    = 'tow_rope',
    maxSpeed    = 18.0,
    breakDamage = 600.0,
    propModel   = 'prop_rope_01',
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
