fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'hbs-tow'
description 'Towing job, rope item, and wheel boot system for QBX'
author 'hbs'
version '0.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/locations.lua',
}

client_scripts {
    'client/main.lua',
    'client/job.lua',
    'client/tablet.lua',
    'client/attach.lua',
    'client/rope.lua',
    'client/boot.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/job.lua',
    'server/tablet.lua',
    'server/boot.lua',
}

ui_page 'web-build/index.html'

files {
    'web-build/index.html',
    'web-build/**/*',
}

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'oxmysql',
}
