fx_version 'adamant'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

files {
	'ui/index.html',
	'ui/style.css',
	'ui/script.js',
	'ui/chineserocks.ttf',
	'ui/keyboard.ttf'
}

ui_page 'ui/index.html'

shared_scripts {
	'config.lua'
}

client_scripts {
	'@uiprompt/uiprompt.lua',
	'peds.lua',
	'vehicles.lua',
	'objects.lua',
	'scenarios.lua',
	'weapons.lua',
	'animations.lua',
	'propsets.lua',
	'pickups.lua',
	'bones.lua',
	'walkstyles.lua',
	'pedConfigFlags.lua',
	'client.lua'
}

server_scripts {
	'server.lua'
}
