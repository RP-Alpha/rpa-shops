fx_version 'cerulean'
game 'gta5'

author 'RP-Alpha'
description 'RP-Alpha Shop System - Categories, player-owned, in-game management'
version '2.0.0'

dependency 'rpa-lib'

shared_script 'config.lua'

client_scripts {
    '@ox_lib/init.lua',
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

lua54 'yes'
