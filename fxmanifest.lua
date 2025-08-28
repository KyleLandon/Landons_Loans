fx_version 'cerulean'
game 'gta5'

name 'LandonsLoans'
author 'Landon\'s Loans Development'
description 'Comprehensive Credit & Loan System for QBCore'
version '1.0.1'

shared_scripts {
    'shared/config.lua'
}

client_scripts {
    'client/main.lua',
    'client/ui.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/credit.lua',
    'server/loans.lua',
    'server/payments.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'qb-core',
    'qb-target',
    'oxmysql'
}
