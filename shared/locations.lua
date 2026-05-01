Config = Config or {}

Config.Locations = {
    depot = {
        label   = 'Tow Depot',
        duty    = vec3(409.7, -1622.8, 29.3),
        spawn   = vec4(412.5, -1623.4, 29.3, 230.0),
        vehicle = 'towtruck',
    },
    impound = {
        label = 'Central Impound',
        point = vec3(403.7588, -1632.9202, 29.292),
        drop  = vec4(405.0, -1635.0, 29.3, 320.0),
    },
}

-- Mission spawn pool. Designer-editable; expand freely.
Config.MissionSpawns = {
    { coords = vec4(-178.4, -1573.9, 34.3, 90.0),  district = 'Strawberry' },
    { coords = vec4(263.7, -361.7, 44.0, 340.0),   district = 'Pillbox' },
    { coords = vec4(-1037.1, -2735.6, 13.7, 50.0), district = 'LSIA' },
    { coords = vec4(1175.5, -1440.4, 34.6, 0.0),   district = 'El Burro' },
    { coords = vec4(-1517.9, 137.3, 55.5, 215.0),  district = 'Morningwood' },
    { coords = vec4(102.4, 6624.7, 31.8, 270.0),   district = 'Paleto' },
}

Config.MissionVehicles = {
    abandoned       = { 'sultan', 'asea', 'baller', 'futo', 'blista' },
    illegal_parking = { 'asbo', 'kanjo', 'panto', 'issi3' },
    accident        = { 'sultan', 'tailgater', 'oracle', 'fugitive' },
    vip_recovery    = { 'cognoscenti', 'schafter5', 'baller3', 'xls' },
}

-- Variants are gated by XP track 'driving' minLevel.
Config.MissionVariants = {
    abandoned = {
        label    = 'Abandoned Vehicle',
        minLevel = 0,
        basePay  = 250,
        xp       = 15,
        weight   = 50,
    },
    illegal_parking = {
        label    = 'Illegal Parking',
        minLevel = 5,
        basePay  = 325,
        xp       = 20,
        weight   = 25,
    },
    accident = {
        label    = 'Accident Scene',
        minLevel = 10,
        basePay  = 450,
        xp       = 30,
        weight   = 18,
    },
    vip_recovery = {
        label    = 'VIP Recovery',
        minLevel = 15,
        basePay  = 700,
        xp       = 50,
        weight   = 7,
    },
}
