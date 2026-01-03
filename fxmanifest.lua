fx_version 'cerulean'
game 'gta5'

author 'RP-Alpha'
description 'RP-Alpha Shop System'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

shared_script 'config.lua'
client_script 'client/main.lua'
server_script 'server/main.lua'

lua54 'yes'
