
fx_version 'cerulean'
game 'gta5'

name 'qbx_density'
description 'semi-loopless population management with admin menu'
repository 'https://github.com/Qbox-project/qbx_density'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua'
}

client_scripts {
    'client/main.lua',
    'client/menu.lua'
}

server_scripts {
    'server/permissions.lua',
    'server/storage.lua'
}

files {
    'config/client.lua'
}

-- Dependencies
dependencies {
    'ox_lib'
}

-- Export functions
exports {
    'SetDensity',
    'ResetToDefaults',
    'GetStatus',
    'StartDensityControl',
    'StopDensityControl'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'