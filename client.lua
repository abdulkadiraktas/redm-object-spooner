local Database = {}

local Cam = nil
local Speed = Config.Speed
local AdjustSpeed = Config.AdjustSpeed
local RotateSpeed = Config.RotateSpeed
local AttachedEntity = nil
local RotateMode = 2
local AdjustMode = 4
local SpeedMode = 0
local PlaceOnGround = false
local CurrentSpawn = nil

local StoreDeleted = false
local DeletedEntities = {}

local Permissions = {}

Permissions.maxEntities = 0

Permissions.spawn = {}
Permissions.spawn.ped = false
Permissions.spawn.vehicle = false
Permissions.spawn.object = false
Permissions.spawn.propset = false
Permissions.spawn.pickup = false

Permissions.delete = {}
Permissions.delete.own = {}
Permissions.delete.own.networked = false
Permissions.delete.own.nonNetworked = false
Permissions.delete.other = {}
Permissions.delete.other.networked = false
Permissions.delete.other.nonNetworked = false

Permissions.modify = {}
Permissions.modify.own = {}
Permissions.modify.own.networked = false
Permissions.modify.own.nonNetworked = false
Permissions.modify.other = {}
Permissions.modify.other.networked = false
Permissions.modify.other.nonNetworked = false

Permissions.properties = {}
Permissions.properties.freeze = false
Permissions.properties.position = false
Permissions.properties.goTo = false
Permissions.properties.rotation = false
Permissions.properties.health = false
Permissions.properties.invincible = false
Permissions.properties.visible = false
Permissions.properties.gravity = false
Permissions.properties.collision = false
Permissions.properties.attachments = false
Permissions.properties.lights = false
Permissions.properties.registerAsNetworked = false

Permissions.properties.ped = {}
Permissions.properties.ped.changeModel = false
Permissions.properties.ped.outfit = false
Permissions.properties.ped.group = false
Permissions.properties.ped.scenario = false
Permissions.properties.ped.animation = false
Permissions.properties.ped.clearTasks = false
Permissions.properties.ped.weapon = false
Permissions.properties.ped.mount = false
Permissions.properties.ped.resurrect = false
Permissions.properties.ped.ai = false
Permissions.properties.ped.knockOffProps = false
Permissions.properties.ped.walkStyle = false
Permissions.properties.ped.cloneToTarget = false
Permissions.properties.ped.lookAtEntity = false

Permissions.properties.vehicle = {}
Permissions.properties.vehicle.repair = false
Permissions.properties.vehicle.getin = false
Permissions.properties.vehicle.engine = false
Permissions.properties.vehicle.lights = false

RegisterNetEvent('spooner:init')
RegisterNetEvent('spooner:toggle')
RegisterNetEvent('spooner:openDatabaseMenu')
RegisterNetEvent('spooner:openSaveDbMenu')
RegisterNetEvent('spooner:refreshPermissions')

function SetLightsIntensityForEntity(entity, intensity)
	Citizen.InvokeNative(0x07C0F87AAC57F2E4, entity, intensity)
end

function SetLightsColorForEntity(entity, red, green, blue)
	Citizen.InvokeNative(0x6EC2A67962296F49, entity, red, green, blue)
end

function SetLightsTypeForEntity(entity, type)
	Citizen.InvokeNative(0xAB72C67163DC4DB4, entity, type)
end

function CreatePed_2(modelHash, x, y, z, heading, isNetwork, thisScriptCheck, p7, p8)
	return Citizen.InvokeNative(0xD49F9B0955C367DE, modelHash, x, y, z, heading, isNetwork, thisScriptCheck, p7, p8)
end

function SetRandomOutfitVariation(ped, p1)
	Citizen.InvokeNative(0x283978A15512B2FE, ped, p1)
end

function BlipAddForEntity(blipHash, entity)
	return Citizen.InvokeNative(0x23F74C2FDA6E7C61, blipHash, entity)
end

function SetPedOnMount(ped, mount, seatIndex, p3)
	Citizen.InvokeNative(0x028F76B6E78246EB, ped, mount, seatIndex, p3)
end

function IsUsingKeyboard(padIndex)
	return Citizen.InvokeNative(0xA571D46727E2B718, padIndex)
end

function RequestPropset(hash)
	return Citizen.InvokeNative(0xF3DE57A46D5585E9, hash)
end

function ReleasePropset(hash)
	return Citizen.InvokeNative(0xB1964A83B345B4AB, hash)
end

function HasPropsetLoaded(hash)
	return Citizen.InvokeNative(0x48A88FC684C55FDC, hash)
end

function CreatePropset(hash, x, y, z, p4, p5, p6, p7, p8)
	return Citizen.InvokeNative(0xE65C5CBA95F0E510, hash, x, y, z, p4, p5, p6, p7, p8)
end

function DeletePropset(propSet, p1, p2)
	return Citizen.InvokeNative(0x58AC173A55D9D7B4, propSet, p1, p2)
end

function DoesPropsetExist(propSet)
	return Citizen.InvokeNative(0x7DDDCF815E650FF5, propSet)
end

function GetEntitiesFromPropset(propSet, itemSet, p2, p3, p4)
	return Citizen.InvokeNative(0x738271B660FE0695, propSet, itemSet, p2, p3, p4)
end

function IsPickupTypeValid(pickupHash)
	return Citizen.InvokeNative(0x007BD043587F7C82, pickupHash)
end

function IsEntityFrozen(entity)
	return Citizen.InvokeNative(0x083D497D57B7400F, entity)
end

function IsPedUsingScenarioHash(ped, scenarioHash)
	return Citizen.InvokeNative(0x34D6AC1157C8226C, ped, scenarioHash)
end

function EnableSpoonerMode()
	local x, y, z = table.unpack(GetGameplayCamCoord())
	local pitch, roll, yaw = table.unpack(GetGameplayCamRot(2))
	local fov = GetGameplayCamFov()
	Cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
	SetCamCoord(Cam, x, y, z)
	SetCamRot(Cam, pitch, roll, yaw, 2)
	SetCamFov(Cam, fov)
	RenderScriptCams(true, true, 500, true, true)

	SendNUIMessage({
		type = 'showSpoonerHud'
	})
end

function DisableSpoonerMode()
	if Cam then
		RenderScriptCams(false, true, 500, true, true)
		SetCamActive(Cam, false)
		DetachCam(Cam)
		DestroyCam(Cam, true)
		Cam = nil
	end

	AttachedEntity = nil

	SendNUIMessage({
		type = 'hideSpoonerHud'
	})

	SetNuiFocus(false, false)
end

function ToggleSpoonerMode()
	if Cam then
		DisableSpoonerMode()
	else
		EnableSpoonerMode()
	end
end


function OpenDatabaseMenu()
	UpdateDatabase()
	SendNUIMessage({
		type = 'openDatabase',
		database = json.encode(Database)
	})
	SetNuiFocus(true, true)
end

function OpenSaveDbMenu()
	SendNUIMessage({
		type = 'openSaveLoadDbMenu',
		databaseNames = json.encode(GetSavedDatabases())
	})
	SetNuiFocus(true, true)
end

RegisterCommand('spooner', function(source, args, raw)
	TriggerServerEvent('spooner:toggle')
end, false)

RegisterCommand('spooner_db', function(source, args, raw)
	TriggerServerEvent('spooner:openDatabaseMenu')
end, false)

RegisterCommand('spooner_savedb', function(source, args, raw)
	TriggerServerEvent('spooner:openSaveDbMenu')
end, false)

AddEventHandler('spooner:toggle', ToggleSpoonerMode)
AddEventHandler('spooner:openDatabaseMenu', OpenDatabaseMenu)
AddEventHandler('spooner:openSaveDbMenu', OpenSaveDbMenu)

AddEventHandler('spooner:init', function(permissions)
	Permissions = permissions

	SendNUIMessage({
		type = 'updatePermissions',
		permissions = json.encode(permissions)
	})
end)

AddEventHandler('spooner:refreshPermissions', function()
	TriggerServerEvent('spooner:init')
end)

function GetSpoonerEntityType(entity)
	return Database[entity] and Database[entity].type or GetEntityType(entity)
end

function GetSpoonerEntityModel(entity)
	return Database[entity] and Database[entity].model or GetEntityModel(entity)
end

function GetInView(x1, y1, z1, pitch, roll, yaw)
	local rx = -math.sin(math.rad(yaw)) * math.abs(math.cos(math.rad(pitch)))
	local ry =  math.cos(math.rad(yaw)) * math.abs(math.cos(math.rad(pitch)))
	local rz =  math.sin(math.rad(pitch))

	local x2 = x1 + rx * 10000.0
	local y2 = y1 + ry * 10000.0
	local z2 = z1 + rz * 10000.0

	local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(StartShapeTestRay(x1, y1, z1, x2, y2, z2, -1, -1, 1))

	if entityHit <= 0 then
		return endCoords, nil, 0
	end

	local entityCoords = GetEntityCoords(entityHit)

	local distance = #(vector3(x1, y1, z1) - entityCoords)

	if distance >= 100.0 then
		return endCoords, nil, distance
	end

	return endCoords, entityHit, distance
end

function GetModelName(model)
	for _, name in ipairs(Peds) do
		if model == GetHashKey(name) then
			return name
		end
	end

	for _, name in ipairs(Vehicles) do
		if model == GetHashKey(name) then
			return name
		end
	end

	for _, name in ipairs(Objects) do
		if model == GetHashKey(name) then
			return name
		end
	end

	for _, name in ipairs(Pickups) do
		if model == GetHashKey(name) then
			return name
		end
	end

	return string.format('%x', model)
end

function GetPlayerFromPed(ped)
	for _, playerId in ipairs(GetActivePlayers()) do
		if ped == GetPlayerPed(playerId) then
			return playerId
		end
	end

	return nil
end

function GetBoneIndex(entity, bone)
	if not bone then
		return 0
	elseif type(bone) == 'number' then
		return bone
	else
		return GetEntityBoneIndexByName(entity, bone)
	end
end

function FindBoneName(entity, boneIndex)
	for _, boneName in ipairs(Bones) do
		if GetEntityBoneIndexByName(entity, boneName) == boneIndex then
			return boneName
		end
	end

	return boneIndex
end

function GetLiveEntityProperties(entity)
	local model = GetEntityModel(entity)
	local x, y, z = table.unpack(GetEntityCoords(entity))
	local pitch, roll, yaw = table.unpack(GetEntityRotation(entity, 2))
	local isPlayer = IsPedAPlayer(entity)
	local player = isPlayer and GetPlayerFromPed(entity)

	return {
		name = GetModelName(model),
		type = GetEntityType(entity),
		model = model,
		x = x,
		y = y,
		z = z,
		pitch = pitch,
		roll = roll,
		yaw = yaw,
		health = GetEntityHealth(entity),
		outfit = -1,
		isInGroup = IsPedGroupMember(entity, GetPlayerGroup(PlayerId())),
		collisionDisabled = GetEntityCollisionDisabled(entity),
		lightsIntensity = nil,
		lightsColour = nil,
		lightsType = nil,
		animation = nil,
		scenario = nil,
		blockNonTemporaryEvents = false,
		isSelf = entity == PlayerPedId(),
		playerName = player and GetPlayerName(player),
		weapons = {},
		isFrozen = IsEntityFrozen(entity),
		isVisible = IsEntityVisible(entity),
		attachment = {
			to = GetEntityAttachedTo(entity),
			bone = nil,
			x = 0.0,
			y = 0.0,
			z = 0.0,
			pitch = 0.0,
			roll = 0.0,
			yaw = 0.0
		},
		netId = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity),
		exists = true
	}
end

function AddEntityToDatabase(entity, name, attachment)
	if not entity then
		return nil
	end

	if not name and Database[entity] then
		name = Database[entity].name
	end

	local model = Database[entity] and Database[entity].model
	local type = Database[entity] and Database[entity].type

	local outfit = Database[entity] and Database[entity].outfit or -1

	local attachBone, attachX, attachY, attachZ, attachPitch, attachRoll, attachYaw

	local lightsIntensity = Database[entity] and Database[entity].lightsIntensity or nil
	local lightsColour = Database[entity] and Database[entity].lightsColour or nil
	local lightsType = Database[entity] and Database[entity].lightsType or nil

	local animation = Database[entity] and Database[entity].animation
	local scenario = Database[entity] and Database[entity].scenario

	local blockNonTemporaryEvents = Database[entity] and Database[entity].blockNonTemporaryEvents or false

	local weapons = Database[entity] and Database[entity].weapons or {}

	local walkStyle = Database[entity] and Database[entity].walkStyle

	if attachment then
		attachBone  = attachment.bone
		attachX     = attachment.x
		attachY     = attachment.y
		attachZ     = attachment.z
		attachPitch = attachment.pitch
		attachRoll  = attachment.roll
		attachYaw   = attachment.yaw
	else
		attachBone  = (Database[entity] and Database[entity].attachment.bone)
		attachX     = (Database[entity] and Database[entity].attachment.x     or 0.0)
		attachY     = (Database[entity] and Database[entity].attachment.y     or 0.0)
		attachZ     = (Database[entity] and Database[entity].attachment.z     or 0.0)
		attachPitch = (Database[entity] and Database[entity].attachment.pitch or 0.0)
		attachRoll  = (Database[entity] and Database[entity].attachment.roll  or 0.0)
		attachYaw   = (Database[entity] and Database[entity].attachment.yaw   or 0.0)
	end

	Database[entity] = GetLiveEntityProperties(entity)

	if name then
		Database[entity].name = name
	end

	if model then
		Database[entity].model = model
	end

	if type then
		Database[entity].type = type
	end

	Database[entity].outfit = outfit

	Database[entity].attachment.bone = attachBone
	Database[entity].attachment.x = attachX
	Database[entity].attachment.y = attachY
	Database[entity].attachment.z = attachZ
	Database[entity].attachment.pitch = attachPitch
	Database[entity].attachment.roll = attachRoll
	Database[entity].attachment.yaw = attachYaw

	Database[entity].lightsIntensity = lightsIntensity
	Database[entity].lightsColour = lightsColour
	Database[entity].lightsType = lightsType

	Database[entity].animation = animation
	Database[entity].scenario = scenario

	Database[entity].blockNonTemporaryEvents = blockNonTemporaryEvents

	Database[entity].weapons = weapons

	Database[entity].walkStyle = walkStyle

	return Database[entity]
end

function RemoveEntityFromDatabase(entity)
	Database[entity] = nil
end

function GetEntityPropertiesFromDatabase(entity)
	return AddEntityToDatabase(entity)
end

function EntityIsInDatabase(entity)
	return Database[entity] ~= nil
end

function GetEntityProperties(entity)
	if EntityIsInDatabase(entity) then
		return GetEntityPropertiesFromDatabase(entity)
	else
		return GetLiveEntityProperties(entity)
	end
end

function GetDatabaseSize()
	local n = 0

	for entity, props in pairs(Database) do
		n = n + 1
	end

	return n
end

function IsDatabaseFull()
	return Permissions.maxEntities and GetDatabaseSize() >= Permissions.maxEntities
end

function LoadModel(model)
	if IsModelInCdimage(model) then
		RequestModel(model)

		while not HasModelLoaded(model) do
			Wait(0)
		end

		return true
	else
		return false
	end
end

function SetWalkStyle(ped, base, style)
	Citizen.InvokeNative(0x923583741DC87BCE, ped, base)
	Citizen.InvokeNative(0x89F5E7ADECCCB49C, ped, style)

	if Database[ped] then
		Database[ped].walkStyle = {
			base = base,
			style = style
		}
	end
end

function SpawnObject(name, model, x, y, z, pitch, roll, yaw, collisionDisabled, lightsIntensity, lightsColour, lightsType)
	if not Permissions.spawn.object then
		return nil
	end

	if IsDatabaseFull() then
		return nil
	end

	if not LoadModel(model) then
		return nil
	end

	local object = CreateObjectNoOffset(model, x, y, z, true, false, true)

	SetModelAsNoLongerNeeded(model)

	if not object or object < 1 then
		return nil
	end

	SetEntityRotation(object, pitch, roll, yaw, 2)

	FreezeEntityPosition(object, true)

	if collisionDisabled then
		SetEntityCollision(object, false, false)
	end

	if lightsIntensity then
		SetLightsIntensityForEntity(object, lightsIntensity)
	end

	if lightsColour then
		SetLightsColorForEntity(object, lightsColour.red, lightsColour.green, lightsColour.blue)
	end

	if lightsType then
		SetLightsTypeForEntity(object, lightsType)
	end

	AddEntityToDatabase(object, name)

	return object
end

function SpawnVehicle(name, model, x, y, z, pitch, roll, yaw, collisionDisabled)
	if not Permissions.spawn.vehicle then
		return nil
	end

	if IsDatabaseFull() then
		return nil
	end

	if not LoadModel(model) then
		return nil
	end

	local veh = CreateVehicle(model, x, y, z, 0.0, true, false)

	SetModelAsNoLongerNeeded(model)

	if not veh or veh < 1 then
		return nil
	end

	SetEntityRotation(veh, pitch, roll, yaw, 2)

	if collisionDisabled then
		FreezeEntityPosition(veh, true)
		SetEntityCollision(veh, false, false)
	end

	-- Weird fix for the hot air balloon, otherwise it doesn't move with the wind and only travels straight up.
	if model == GetHashKey('hotairballoon01') then
		SetVehicleAsNoLongerNeeded(veh)
	end

	AddEntityToDatabase(veh, name)

	return veh
end

function PlayAnimation(ped, anim)
	if not DoesAnimDictExist(anim.dict) then
		return false
	end

	RequestAnimDict(anim.dict)

	while not HasAnimDictLoaded(anim.dict) do
		Wait(0)
	end

	TaskPlayAnim(ped, anim.dict, anim.name, anim.blendInSpeed, anim.blendOutSpeed, anim.duration, anim.flag, anim.playbackRate, false, false, false, '', false)

	RemoveAnimDict(anim.dict)

	return true
end

function SpawnPed(name, model, x, y, z, pitch, roll, yaw, collisionDisabled, outfit, addToGroup, animation, scenario, blockNonTemporaryEvents, weapons, walkStyle)
	if not Permissions.spawn.ped then
		return nil
	end

	if IsDatabaseFull() then
		return nil
	end

	if not LoadModel(model) then
		return nil
	end

	local ped = CreatePed_2(model, x, y, z, 0.0, true, false)

	SetModelAsNoLongerNeeded(model)

	if not ped or ped < 1 then
		return nil
	end

	SetEntityRotation(ped, pitch, roll, yaw, 2)

	if collisionDisabled then
		FreezeEntityPosition(ped, true)
		SetEntityCollision(ped, false, false)
	end

	if outfit == -1 then
		SetRandomOutfitVariation(ped, true)
	else
		SetPedOutfitPreset(ped, outfit)
	end

	if addToGroup then
		AddToGroup(ped)
	end

	if animation then
		PlayAnimation(ped, animation)
	end

	if scenario then
		Wait(500)
		TaskStartScenarioInPlace(ped, GetHashKey(scenario), -1)
	end

	if blockNonTemporaryEvents then
		SetBlockingOfNonTemporaryEvents(ped, true)
	end

	if weapons then
		for _, weapon in ipairs(weapons) do
			GiveWeaponToPed_2(ped, GetHashKey(weapon), 500, true, false, 0, false, 0.5, 1.0, 0, false, 0.0, false)
		end
	end

	if walkStyle then
		SetWalkStyle(ped, walkStyle.base, walkStyle.style)
	end

	AddEntityToDatabase(ped, name)
	Database[ped].outfit = outfit
	Database[ped].animation = animation
	Database[ped].scenario = scenario
	Database[ped].blockNonTemporaryEvents = blockNonTemporaryEvents
	Database[ped].weapons = weapons
	Database[ped].walkStyle = walkStyle

	return ped
end

function SpawnPropset(name, model, x, y, z, heading)
	if not Permissions.spawn.propset then
		return nil
	end

	if IsDatabaseFull() then
		return nil
	end

	RequestPropset(model)
	while not HasPropsetLoaded(model) do
		Wait(0)
	end

	local propset = CreatePropset(model, x, y, z, 0, heading, 0.0, true, false)

	ReleasePropset(hash)

	if not propset or propset < 1 then
		return nil
	end

	-- FIXME: Eventually, individual objects from the propset should be stored in the DB instead of the propset itself, but I'm not sure how to use GetEntitiesFromPropset properly so that it works consistently.
	AddEntityToDatabase(propset, name)
	Database[propset].type = 4

	return propset

	--local itemset = CreateItemset(true)
	--GetEntitiesFromPropset(propset, itemset, 0, false, false)
	--local size = GetItemsetSize(itemset)

	--if size == 0 then
	--	DeletePropset(propset, true, true)
	--else
	--	for i = 0, size - 1 do
	--		AddEntityToDatabase(GetIndexedItemInItemset(i, itemset))
	--	end
	--end
	--DeletePropset(propset, false, false)
	--
	--return nil
end

function SpawnPickup(name, model, x, y, z)
	if not Permissions.spawn.pickup then
		return nil
	end

	if IsDatabaseFull() then
		return nil
	end

	if not IsPickupTypeValid(model) then
		return nil
	end

	local pickup = CreatePickup(model, x, y, z, 0, 0, false, 0, 0, 0.0, 0)

	if not pickup or pickup < 1 then
		return nil
	end

	AddEntityToDatabase(pickup, name)
	Database[pickup].model = model
	Database[pickup].type = 5

	return pickup
end

function RequestControl(entity)
	local type = GetEntityType(entity)

	if type < 1 or type > 3 then
		return
	end

	NetworkRequestControlOfEntity(entity)
end

function CanDeleteEntity(entity)
	if EntityIsInDatabase(entity) then
		if NetworkGetEntityIsNetworked(entity) then
			return Permissions.delete.own.networked
		else
			return Permissions.delete.own.nonNetworked
		end
	else
		if NetworkGetEntityIsNetworked(entity) then
			return Permissions.delete.other.networked
		else
			return Permissions.delete.other.nonNetworked
		end
	end
end

function StoreDeletedEntity(entity)
	local props = GetLiveEntityProperties(entity)

	table.insert(DeletedEntities, {
		x = props.x,
		y = props.y,
		z = props.z,
		model = props.model,
	})
end

function RemoveEntity(entity)
	if not CanDeleteEntity(entity) then
		return
	end

	if IsPedAPlayer(entity) then
		return
	end

	local entityType = GetSpoonerEntityType(entity)

	if entityType == 4 then
		DeletePropset(entity)
	elseif entityType == 5 then
		RemovePickup(entity)
	else
		if StoreDeleted and not EntityIsInDatabase(entity) then
			StoreDeletedEntity(entity)
		end

		RequestControl(entity)
		SetEntityAsMissionEntity(entity, true, true)
		DeleteEntity(entity)
	end

	RemoveEntityFromDatabase(entity)
end

function RemoveAllFromDatabase()
	local entities = {}
	for handle, info in pairs(Database) do
		table.insert(entities, handle)
	end
	for _, handle in ipairs(entities) do
		RemoveEntity(handle)
	end
end

function SaveDatabaseInKvs(name, db)
	SetResourceKvp('DB_' .. name, json.encode(db))
end

function LoadDatabaseFromKvs(name)
	return json.decode(GetResourceKvpString('DB_' .. name))
end

AddEventHandler('onResourceStop', function(resourceName)
	if GetCurrentResourceName() == resourceName then
		DisableSpoonerMode()

		if Config.CleanUpOnStop then
			RemoveAllFromDatabase();
		end
	end
end)

RegisterNUICallback('closeSpawnMenu', function(data, cb)
	SetNuiFocus(false, false)
	cb({})
end)

function Contains(list, item)
	for _, value in ipairs(list) do
		if value == item then
			return true
		end
	end
	return false
end

RegisterNUICallback('closePedMenu', function(data, cb)
	if data.modelName and (Permissions.spawn.byName or Contains(Peds, data.modelName)) then
		CurrentSpawn = {
			modelName = data.modelName,
			type = 1
		}
	end
	SetNuiFocus(false, false)
	cb({})
end)

RegisterNUICallback('closeVehicleMenu', function(data, cb)
	if data.modelName and (Permissions.spawn.byName or Contains(Vehicles, data.modelName)) then
		CurrentSpawn = {
			modelName = data.modelName,
			type = 2
		}
	end
	SetNuiFocus(false, false)
	cb({})
end)

RegisterNUICallback('closeObjectMenu', function(data, cb)
	if data.modelName and (Permissions.spawn.byName or Contains(Objects, data.modelName)) then
		CurrentSpawn = {
			modelName = data.modelName,
			type = 3
		}
	end
	SetNuiFocus(false, false)
	cb({})
end)

RegisterNUICallback('closePropsetMenu', function(data, cb)
	if data.modelName and (Permissions.spawn.byName or Contains(Propsets, data.modelName)) then
		CurrentSpawn = {
			modelName = data.modelName,
			type = 4
		}
	end
	SetNuiFocus(false, false)
	cb({})
end)

RegisterNUICallback('closePickupMenu', function(data, cb)
	if data.modelName and (Permissions.spawn.byName or Contains(Pickups, data.modelName)) then
		CurrentSpawn = {
			modelName = data.modelName,
			type = 5
		}
	end
	SetNuiFocus(false, false)
	cb({})
end)

RegisterNUICallback('closeDatabase', function(data, cb)
	SetNuiFocus(false, false)
	cb({})
end)

RegisterNUICallback('deleteEntity', function(data, cb)
	RemoveEntity(data.handle)
	cb({
		database = json.encode(Database)
	})
end)

RegisterNUICallback('removeAllFromDatabase', function(data, cb)
	RemoveAllFromDatabase();
	cb({})
end)

RegisterNUICallback('closePropertiesMenu', function(data, cb)
	SetNuiFocus(false, false)
	cb({})
end)

RegisterNUICallback('closeSaveLoadDbMenu', function(data, cb)
	SetNuiFocus(false, false)
	cb({})
end)

RegisterNUICallback('addEntityToDatabase', function(data, cb)
	AddEntityToDatabase(data.handle)
	cb({})
end)

RegisterNUICallback('removeEntityFromDatabase', function(data, cb)
	if not Permissions.maxEntities and Permissions.modify.other then
		RemoveEntityFromDatabase(data.handle)
	end
	cb({})
end)

RegisterNUICallback('freezeEntity', function(data, cb)
	if Permissions.properties.freeze and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		FreezeEntityPosition(data.handle, true)
	end
	cb({})
end)

RegisterNUICallback('unfreezeEntity', function(data, cb)
	if Permissions.properties.freeze and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		FreezeEntityPosition(data.handle, false)
	end
	cb({})
end)

RegisterNUICallback('setEntityRotation', function(data, cb)
	if Permissions.properties.rotation and CanModifyEntity(data.handle) then
		local pitch = data.pitch and data.pitch * 1.0 or 0.0
		local roll  = data.roll  and data.roll  * 1.0 or 0.0
		local yaw   = data.yaw   and data.yaw   * 1.0 or 0.0

		RequestControl(data.handle)
		SetEntityRotation(data.handle, pitch, roll, yaw, 2)
	end

	cb({})
end)

RegisterNUICallback('setEntityCoords', function(data, cb)
	if Permissions.properties.position and CanModifyEntity(data.handle) then
		local x = data.x and data.x * 1.0 or 0.0
		local y = data.y and data.y * 1.0 or 0.0
		local z = data.z and data.z * 1.0 or 0.0

		RequestControl(data.handle)
		SetEntityCoordsNoOffset(data.handle, x, y, z)
	end

	cb({})
end)

RegisterNUICallback('resetRotation', function(data, cb)
	if Permissions.properties.rotation and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetEntityRotation(data.handle, 0.0, 0.0, 0.0, 2)
	end
	cb({})
end)

function UpdateDatabase()
	local entities = {}
	local propsets = {}
	local pickups = {}

	for entity, properties in pairs(Database) do
		if properties.type == 4 then
			table.insert(propsets, entity)
		elseif properties.type == 5 then
			table.insert(pickups, entity)
		else
			table.insert(entities, entity)
		end
	end

	for _, entity in ipairs(entities) do
		if DoesEntityExist(entity) then
			AddEntityToDatabase(entity)
		elseif Database[entity].isSelf then
			RemoveEntityFromDatabase(entity)
		else
			Database[entity].exists = false
		end
	end

	for _, propset in ipairs(propsets) do
		if DoesPropsetExist(propset) then
			AddEntityToDatabase(propset)
		else
			Database[propset].exists = false
		end
	end

	for _, pickup in ipairs(pickups) do
		if DoesPickupExist(pickup) then
			AddEntityToDatabase(pickup)
		else
			Database[pickup].exists = false
		end
	end
end

function CanModifyEntity(entity)
	if EntityIsInDatabase(entity) then
		if NetworkGetEntityIsNetworked(entity) then
			return Permissions.modify.own.networked
		else
			return Permissions.modify.own.nonNetworked
		end
	else
		if NetworkGetEntityIsNetworked(entity) then
			return Permissions.modify.other.networked
		else
			return Permissions.modify.other.nonNetworked
		end
	end
end

function OpenPropertiesMenuForEntity(entity)
	if not CanModifyEntity(entity) then
		SetNuiFocus(false, false)
		return
	end

	SendNUIMessage({
		type = 'openPropertiesMenu',
		entity = entity
	})
	SetNuiFocus(true, true)
end

RegisterNUICallback('openPropertiesMenuForEntity', function(data, cb)
	OpenPropertiesMenuForEntity(data.entity)
	cb({})
end)

RegisterNUICallback('updatePropertiesMenu', function(data, cb)
	cb({
		entity = data.handle,
		properties = json.encode(GetEntityProperties(data.handle)),
		inDb = EntityIsInDatabase(data.handle),
		hasNetworkControl = NetworkHasControlOfEntity(data.handle)
	})
end)

RegisterNUICallback('invincibleOn', function(data, cb)
	if Permissions.properties.invincible and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetEntityInvincible(data.handle, true)
	end
	cb({})
end)

RegisterNUICallback('invincibleOff', function(data, cb)
	if Permissions.properties.invincible and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetEntityInvincible(data.handle, false)
	end
	cb({})
end)

function PlacePedOnGroundProperly(ped)
	local x, y, z = table.unpack(GetEntityCoords(ped))
	local found, groundz, normal = GetGroundZAndNormalFor_3dCoord(x, y, z)
	if found then
		SetEntityCoordsNoOffset(ped, x, y, groundz + normal.z, true)
	end
end

function PlaceOnGroundProperly(entity)
	local entityType = GetEntityType(entity)

	local r1 = GetEntityRotation(entity, 2)

	if entityType == 1 then
		PlacePedOnGroundProperly(entity)
	elseif entityType == 2 then
		SetVehicleOnGroundProperly(entity)
	elseif entityType == 3 then
		PlaceObjectOnGroundProperly(entity)
	end

	local r2 = GetEntityRotation(entity, 2)

	SetEntityRotation(entity, r2.x, r2.y, r1.z, 2)
end

RegisterNUICallback('placeEntityHere', function(data, cb)
	if Permissions.properties.position and CanModifyEntity(data.handle) then
		local x, y, z = table.unpack(GetCamCoord(Cam))
		local pitch, roll, yaw = table.unpack(GetCamRot(Cam, 2))

		local spawnPos, entity, distance = GetInView(x, y, z, pitch, roll, yaw)

		RequestControl(data.handle)
		SetEntityCoordsNoOffset(data.handle, spawnPos.x, spawnPos.y, spawnPos.z)
		PlaceOnGroundProperly(data.handle)

		x, y, z = table.unpack(GetEntityCoords(data.handle))
		pitch, roll, yaw = table.unpack(GetEntityRotation(data.handle, 2))

		cb({
			x = x,
			y = y,
			z = z,
			pitch = pitch,
			roll = roll,
			yaw = yaw
		})
	else
		cb({})
	end
end)

function PrepareDatabaseForSave()
	local db = json.decode(json.encode(Database))
	local ped = PlayerPedId()

	for entity, props in pairs(db) do
		if props.attachment.to == ped then
			props.attachment.to = -1
		end
	end

	db[tostring(ped)] = nil

	return {
		spawn = db,
		delete = DeletedEntities
	}
end

function SaveDatabase(name)
	UpdateDatabase()
	SaveDatabaseInKvs(name, PrepareDatabaseForSave())
end

function RemoveDeletedEntity(x, y, z, hash)
	local handle = GetClosestObjectOfType(x, y, z, 1.0, hash, false, false, false)

	if handle ~= 0 then
		DeleteEntity(handle)
	end
end

function AttachEntity(from, to, bone, x, y, z, pitch, roll, yaw)
	local boneIndex = GetBoneIndex(to, bone)

	AttachEntityToEntity(from, to, boneIndex, x, y, z, pitch, roll, yaw, false, false, true, false, 0, true, false, false)

	if EntityIsInDatabase(from) then
		AddEntityToDatabase(from, nil, {
			to = to,
			bone = bone,
			x = x,
			y = y,
			z = z,
			pitch = pitch,
			roll = roll,
			yaw = yaw
		})
	end
end

function LoadDatabase(db, relative, replace)
	if replace then
		RemoveAllFromDatabase()
	end

	local ax = 0.0
	local ay = 0.0
	local az = 0.0

	local spawns = {}
	local handles = {}

	-- For backwards compatibility with older DB format
	if not (db.spawn and db.delete) then
		db = {spawn = db, delete = {}}
	end

	if StoreDeleted then
		for _, deleted in pairs(db.delete) do
			RemoveDeletedEntity(deleted.x, deleted.y, deleted.z, deleted.model)
			table.insert(DeletedEntities, deleted)
		end
	end

	for entity, props in pairs(db.spawn) do
		if relative then
			ax = ax + props.x
			ay = ay + props.y
			az = az + props.z
		end

		table.insert(spawns, {entity = tonumber(entity), props = props})
	end

	local dx, dy, dz

	local rot = GetCamRot(Cam, 2)

	if relative then
		ax = ax / #spawns
		ay = ay / #spawns
		az = az / #spawns

		local pos = GetCamCoord(Cam)
		local spawnPos, entity, distance = GetInView(pos.x, pos.y, pos.z, rot.x, rot.y, rot.z)

		dx = spawnPos.x - ax
		dy = spawnPos.y - ay
		dz = spawnPos.z - az
	end

	local r = math.rad(rot.z)
	local cosr = math.cos(r)
	local sinr = math.sin(r)

	for _, spawn in ipairs(spawns) do
		local entity

		local x, y, z, pitch, roll, yaw

		if relative then
			x = (((spawn.props.x - ax) * cosr - (spawn.props.y - ay) * sinr + ax) + dx) * 1.0
			y = (((spawn.props.y - ay) * cosr + (spawn.props.x - ax) * sinr + ay) + dy) * 1.0
			z = (spawn.props.z + dz) * 1.0
			pitch = spawn.props.pitch * 1.0
			roll = spawn.props.roll * 1.0
			yaw = (spawn.props.yaw + rot.z) * 1.0
		else
			x = spawn.props.x * 1.0
			y = spawn.props.y * 1.0
			z = spawn.props.z * 1.0
			pitch = spawn.props.pitch * 1.0
			roll = spawn.props.roll * 1.0
			yaw = spawn.props.yaw * 1.0
		end

		if spawn.props.type == 1 then
			entity = SpawnPed(spawn.props.name, spawn.props.model, x, y, z, pitch, roll, yaw, spawn.props.collisionDisabled, spawn.props.outfit, spawn.props.isInGroup, spawn.props.animation, spawn.props.scenario, spawn.props.blockNonTemporaryEvents, spawn.props.weapons, spawn.props.walkStyle)
		elseif spawn.props.type == 2 then
			entity = SpawnVehicle(spawn.props.name, spawn.props.model, x, y, z, pitch, roll, yaw, spawn.props.collisionDisabled)
		elseif spawn.props.type == 5 then
			entity = SpawnPickup(spawn.props.name, spawn.props.model, x, y, z)
		else
			entity = SpawnObject(spawn.props.name, spawn.props.model, x, y, z, pitch, roll, yaw, spawn.props.collisionDisabled, spawn.props.lightsIntensity, spawn.props.lightsColour, spawn.props.lightsType)
		end

		if entity and relative then
			PlaceOnGroundProperly(entity)
		end

		handles[spawn.entity] = entity
	end

	for _, spawn in ipairs(spawns) do
		if spawn.props.attachment and spawn.props.attachment.to ~= 0 then
			local from  = handles[spawn.entity]
			local to    = spawn.props.attachment.to == -1 and PlayerPedId() or handles[spawn.props.attachment.to]
			local bone  = spawn.props.attachment.bone
			local x     = spawn.props.attachment.x * 1.0
			local y     = spawn.props.attachment.y * 1.0
			local z     = spawn.props.attachment.z * 1.0
			local pitch = spawn.props.attachment.pitch * 1.0
			local roll  = spawn.props.attachment.roll * 1.0
			local yaw   = spawn.props.attachment.yaw * 1.0

			if type(bone) == 'number' then
				bone = FindBoneName(to, bone)
			end

			AttachEntity(from, to, bone, x, y, z, pitch, roll, yaw)

			AddEntityToDatabase(from, nil, {
				to = to,
				bone = bone,
				x = x,
				y = y,
				z = z,
				pitch = pitch,
				roll = roll,
				yaw = yaw
			})
		end
	end
end

function LoadSavedDatabase(name, relative, replace)
	local db = LoadDatabaseFromKvs(name)

	if db then
		LoadDatabase(db, relative, replace)
	end
end

function GetSavedDatabases()
	local dbs = {}

	local handle = StartFindKvp('DB_')

	while true do
		local kvp = FindKvp(handle)

		if kvp then
			table.insert(dbs, string.sub(kvp, 4))
		else
			break
		end
	end

	EndFindKvp(handle)

	table.sort(dbs)

	return dbs
end

function DeleteDatabase(name)
	DeleteResourceKvp('DB_' .. name)
end

RegisterNUICallback('saveDb', function(data, cb)
	SaveDatabase(data.name)
	cb(json.encode(GetSavedDatabases()))
end)

RegisterNUICallback('loadDb', function(data, cb)
	LoadSavedDatabase(data.name, data.relative, data.replace)
	cb({})
end)

RegisterNUICallback('deleteDb', function(data, cb)
	DeleteDatabase(data.name)
	cb({})
end)

function GetFavourites()
	local content = GetResourceKvpString('favourites')

	if content then
		return json.decode(content)
	end
end

RegisterNUICallback('init', function(data, cb)
	cb({
		peds = json.encode(Peds),
		vehicles = json.encode(Vehicles),
		objects = json.encode(Objects),
		scenarios = json.encode(Scenarios),
		weapons = json.encode(Weapons),
		animations = json.encode(Animations),
		propsets = json.encode(Propsets),
		pickups = json.encode(Pickups),
		bones = json.encode(Bones),
		walkStyleBases = json.encode(WalkStyleBases),
		walkStyles = json.encode(WalkStyles),
		adjustSpeed = AdjustSpeed,
		rotateSpeed = RotateSpeed,
		favourites = GetFavourites()
	})

	-- FIXME:
	-- This shouldn't be necessary, but RedM doesn't appear to free the
	-- memory allocated for NUI messages, so eventually it causes resource
	-- memory warnings.
	collectgarbage()
end)

RegisterNUICallback('setAdjustSpeed', function(data, cb)
	AdjustSpeed = data.speed * 1.0
	cb({})
end)

RegisterNUICallback('setRotateSpeed', function(data, cb)
	RotateSpeed = data.speed * 1.0
	cb({})
end)

function GetTeleportTarget()
	local ped = PlayerPedId()
	local veh = GetVehiclePedIsIn(ped, false)
	local mnt = GetMount(ped)
	return (veh == 0 and (mnt == 0 and ped or mnt) or veh)
end

function TeleportToCoords(x, y, z, h)
	local ent = GetTeleportTarget()
	FreezeEntityPosition(ent, true)
	SetEntityCoords(ent, x, y, z, 0, 0, 0, 0, 0)
	SetEntityHeading(ent, h)
	FreezeEntityPosition(ent, false)
end

RegisterNUICallback('goToEntity', function(data, cb)
	if Permissions.properties.goTo then
		DisableSpoonerMode()
		local x, y, z = table.unpack(GetEntityCoords(data.handle))
		TeleportToCoords(x, y, z, 0.0)
	end
	cb({})
end)

function CloneEntity(entity)
	local props = GetEntityProperties(entity)
	local clone = nil

	if props.type == 1 then
		clone = SpawnPed(props.name, props.model, props.x, props.y, props.z, props.pitch, props.roll, props.yaw, props.collisionDisabled, props.outfit, props.isInGroup, props.animation, props.scenario, props.blockNonTemporaryEvents, props.weapons, props.walkStyle)
	elseif props.type == 2 then
		clone = SpawnVehicle(props.name, props.model, props.x, props.y, props.z, props.pitch, props.roll, props.yaw, props.collisionDisabled)
	elseif props.type == 3 then
		clone = SpawnObject(props.name, props.model, props.x, props.y, props.z, props.pitch, props.roll, props.yaw, props.collisionDisabled, props.lightsIntensity, props.lightsColour, props.lightsType)
	elseif props.type == 5 then
		clone = SpawnPickup(props.name, props.model, props.x, props.y, props.z)
	else
		return nil
	end

	if clone and props.attachment and props.attachment.to ~= 0 then
		AttachEntity(clone, props.attachment.to, props.attachment.bone, props.attachment.x, props.attachment.y, props.attachment.z, props.attachment.pitch, props.attachment.roll, props.attachment.yaw)
	end

	return clone
end

RegisterNUICallback('cloneEntity', function(data, cb)
	local clone = CloneEntity(data.handle)

	if clone then
		OpenPropertiesMenuForEntity(clone)
	end

	cb({})
end)

RegisterNUICallback('closeHelpMenu', function(data, cb)
	SetNuiFocus(false, false)
	cb({})
end)

RegisterNUICallback('getIntoVehicle', function(data, cb)
	if Permissions.properties.vehicle.getin then
		DisableSpoonerMode()
		RequestControl(data.handle)
		TaskWarpPedIntoVehicle(PlayerPedId(), data.handle, -1)
	end
	cb({})
end)

RegisterNUICallback('repairVehicle', function(data, cb)
	if Permissions.properties.vehicle.repair and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetVehicleFixed(data.handle)
	end
	cb({})
end)

function ConvertDatabaseToMapEditorXml(creator, database)
	local xml = '<Map>\n\t<MapMeta Creator="' .. creator .. '"/>\n'

	for _, properties in ipairs(database.delete) do
		xml = xml .. string.format('\t<DeletedObject Hash="%s" Position_x="%s" Position_y="%s" Position_z="%s"/>\n', properties.model, properties.x, properties.y, properties.z)
	end

	for entity, properties in pairs(database.spawn) do
		if properties.type == 1 then
			xml = xml .. string.format('\t<Ped Hash="%s" Position_x="%s" Position_y="%s" Position_z="%s" Rotation_x="%s" Rotation_y="%s" Rotation_z="%s" Preset="%d"/>\n', properties.model, properties.x, properties.y, properties.z, properties.pitch, properties.roll, properties.yaw, properties.outfit)
		elseif properties.type == 2 then
			xml = xml .. string.format('\t<Vehicle Hash="%s" Position_x="%s" Position_y="%s" Position_z="%s" Rotation_x="%s" Rotation_y="%s" Rotation_z="%s"/>\n', properties.model, properties.x, properties.y, properties.z, properties.pitch, properties.roll, properties.yaw)
		else
			xml = xml .. string.format('\t<Object Hash="%s" Position_x="%s" Position_y="%s" Position_z="%s" Rotation_x="%s" Rotation_y="%s" Rotation_z="%s"/>\n', properties.model, properties.x, properties.y, properties.z, properties.pitch, properties.roll, properties.yaw)
		end
	end

	xml = xml .. '</Map>'

	return xml
end

function ToQuaternion(pitch, roll, yaw)
	local cp = math.cos(pitch * 0.5)
	local sp = math.sin(pitch * 0.5)
	local cr = math.cos(pitch * 0.5)
	local sr = math.sin(pitch * 0.5)
	local cy = math.cos(pitch * 0.5)
	local sy = math.sin(pitch * 0.5)

	return {
		w = cr * cp * cy + sr * sp * sy,
		x = sr * cp * cy - cr * sp * sy,
		y = cr * sp * cy + sr * cp * sy,
		z = cr * cp * sy - sr * sp * cy
	}
end

function ConvertDatabaseToYmap(database)
	local minX, maxX, minY, maxY, minZ, maxZ

	local entitiesXml = '\t<entities>\n'

	for entity, properties in pairs(database.spawn) do
		local q = ToQuaternion(properties.pitch, properties.roll, properties.yaw)

		if not minX or properties.x < minX then
			minX = properties.x
		end
		if not maxX or properties.x > maxX then
			maxX = properties.x
		end
		if not minY or properties.y < minY then
			minY = properties.y
		end
		if not maxY or properties.y > maxY then
			maxY = properties.y
		end
		if not minZ or properties.z < minZ then
			minZ = properties.z
		end
		if not maxZ or properties.z > maxZ then
			maxZ = properties.z
		end

		entitiesXml = entitiesXml .. string.format('\t\t<Item type="CEntityDef">\n\t\t\t<archetypeName>%s</archetypeName>\n\t\t\t<position x="%f" y="%f" z="%f"/>\n\t\t\t<rotation w="%f" x="%f" y="%f" z="%f"/>\n\t\t</Item>\n', properties.name, properties.x, properties.y, properties.z, q.w, q.x, q.y, q.z)
	end

	entitiesXml = entitiesXml .. '\t</entities>\n'

	local xml = '<CMapData>\n'

	xml = xml .. string.format('\t<streamingExtentsMin x="%f" y="%f" z="%f"/>\n', minX - 400, minY - 400, minZ - 400)
	xml = xml .. string.format('\t<streamingExtentsMax x="%f" y="%f" z="%f"/>\n', maxX + 400, maxY + 400, maxZ + 400)
	xml = xml .. string.format('\t<entitiesExtentsMin x="%f" y="%f" z="%f"/>\n', minX, minY, minZ)
	xml = xml .. string.format('\t<entitiesExtentsMax x="%f" y="%f" z="%f"/>\n', maxX, maxY, maxZ)

	xml = xml .. entitiesXml

	xml = xml .. '</CMapData>'

	return xml
end

function ConvertDatabaseToPropPlacerJson(database)
	local props = {}

	for entity, properties in pairs(database.spawn) do
		props[properties.yaw .. '-' .. properties.x] = {
			prophash = properties.model,
			x = properties.x,
			y = properties.y,
			z = properties.z,
			heading = properties.yaw
		}
	end

	return json.encode(props)
end

function BackupDbs()
	local dbs = {}

	for _, name in ipairs(GetSavedDatabases()) do
		dbs[name] = LoadDatabaseFromKvs(name)
	end

	return json.encode(dbs)
end

function RestoreDbs(content)
	local dbs = json.decode(content)

	for name, db in pairs(dbs) do
		SaveDatabaseInKvs(name, db)
	end
end

function ExportDatabase(format)
	UpdateDatabase()

	local db = PrepareDatabaseForSave()

	if format == 'spooner-db-json' then
		return json.encode(db)
	elseif format == 'map-editor-xml' then
		return ConvertDatabaseToMapEditorXml(GetPlayerName(), db)
	elseif format == 'ymap' then
		return ConvertDatabaseToYmap(db)
	elseif format == 'propplacer' then
		return ConvertDatabaseToPropPlacerJson(db)
	elseif format == 'backup' then
		return BackupDbs()
	end
end

function ImportDatabase(format, content)
	if format == 'spooner-db-json' then
		local db = json.decode(content)

		if db then
			LoadDatabase(db, false, false)
		end
	elseif format == 'backup' then
		RestoreDbs(content)
	end
end

RegisterNUICallback('exportDb', function(data, cb)
	cb(ExportDatabase(data.format))
end)

RegisterNUICallback('importDb', function(data, cb)
	ImportDatabase(data.format, data.content)
	cb({})
end)

RegisterNUICallback('closeImportExportDbWindow', function(data, cb)
	SetNuiFocus(false, false)
	cb({})
end)

RegisterNUICallback('requestControl', function(data, cb)
	if CanModifyEntity(data.handle) then
		RequestControl(data.handle)
	end
	cb({})
end)

RegisterNUICallback('getDatabase', function(data, cb)
	UpdateDatabase()
	cb({
		properties = json.encode(GetEntityProperties(data.handle)),
		database = json.encode(Database)
	})
end)

RegisterNUICallback('attachTo', function(data, cb)
	if Permissions.properties.attachments and CanModifyEntity(data.from) then
		local from = data.from
		local to = data.to
		local bone = data.bone

		if not to then
			local props = GetEntityProperties(from)

			if props.attachment.to ~= 0 then
				to = props.attachment.to
			else
				cb({})
				return
			end
		end

		local x, y, z, pitch, roll, yaw

		if data.keepPos then
			local x1, y1, z1 = table.unpack(GetEntityCoords(from))
			x, y, z = table.unpack(GetOffsetFromEntityGivenWorldCoords(to, x1, y1, z1))
			pitch, roll, yaw = table.unpack(GetEntityRotation(from, 2) - GetEntityRotation(to, 2))
		else
			x = data.x and data.x * 1.0 or 0.0
			y = data.y and data.y * 1.0 or 0.0
			z = data.z and data.z * 1.0 or 0.0
			pitch = data.pitch and data.pitch * 1.0 or 0.0
			roll = data.roll and data.roll * 1.0 or 0.0
			yaw = data.yaw and data.yaw * 1.0 or 0.0
		end

		if type(bone) == 'number' then
			bone = FindBoneName(to, bone)
		end

		RequestControl(from)
		AttachEntity(from, to, bone, x, y, z, pitch, roll, yaw)
	end

	cb({})
end)

RegisterNUICallback('closeMenu', function(data, cb)
	SetNuiFocus(false, false)
	cb({})
end)

RegisterNUICallback('detach', function(data, cb)
	if Permissions.properties.attachments and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		DetachEntity(data.handle, false, true)

		if EntityIsInDatabase(data.handle) then
			AddEntityToDatabase(data.handle, nil, {
				to = 0,
				bone = nil,
				x = 0.0,
				y = 0.0,
				z = 0.0,
				pitch = 0.0,
				roll = 0.0,
				yaw = 0.0
			})
		end
	end

	cb({})
end)

RegisterNUICallback('setEntityHealth', function(data, cb)
	if Permissions.properties.health and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetEntityHealth(data.handle, data.health, 0)
	end
	cb({})
end)

RegisterNUICallback('setEntityVisible', function(data, cb)
	if Permissions.properties.visible and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetEntityVisible(data.handle, true)
	end
	cb({})
end)

RegisterNUICallback('setEntityInvisible', function(data, cb)
	if Permissions.properties.visible and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetEntityVisible(data.handle, false)
	end
	cb({})
end)

RegisterNUICallback('gravityOn', function(data, cb)
	if Permissions.properties.gravity and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetEntityHasGravity(data.handle, true)
	end
	cb({})
end)

RegisterNUICallback('gravityOff', function(data, cb)
	if Permissions.properties.gravity and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetEntityHasGravity(data.handle, false)
	end
	cb({})
end)

RegisterNUICallback('performScenario', function(data, cb)
	if Permissions.properties.ped.scenario and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		TaskStartScenarioInPlace(data.handle, GetHashKey(data.scenario), 0, true)

		if Database[data.handle] then
			Database[data.handle].animation = nil
			Database[data.handle].scenario = data.scenario
		end
	end

	cb({})
end)

RegisterNUICallback('clearPedTasks', function(data, cb)
	if Permissions.properties.ped.clearTasks and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		ClearPedTasks(data.handle)

		if Database[data.handle] then
			Database[data.handle].scenario = nil
			Database[data.handle].animation = nil
		end
	end

	cb({})
end)

RegisterNUICallback('clearPedTasksImmediately', function(data, cb)
	if Permissions.properties.ped.clearTasks and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		ClearPedTasksImmediately(data.handle)

		if Database[data.handle] then
			Database[data.handle].scenario = nil
			Database[data.handle].animation = nil
		end
	end

	cb({})
end)

RegisterNUICallback('setOutfit', function(data, cb)
	if Permissions.properties.ped.outfit and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetPedOutfitPreset(data.handle, data.outfit)

		if EntityIsInDatabase(data.handle) then
			Database[data.handle].outfit = data.outfit
		end
	end

	cb({})
end)

function AddToGroup(ped)
	local group = GetPlayerGroup(PlayerId())
	SetPedAsGroupMember(ped, group)
	SetGroupSeparationRange(group, -1)
	SetPedCanTeleportToGroupLeader(ped, group, true)
	BlipAddForEntity(Config.GroupMemberBlipSprite, ped)
end

RegisterNUICallback('addToGroup', function(data, cb)
	if Permissions.properties.ped.group and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		AddToGroup(data.handle)
	end
	cb({})
end)

RegisterNUICallback('removeFromGroup', function(data, cb)
	if Permissions.properties.ped.group and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		RemovePedFromGroup(data.handle)
		RemoveBlip(GetBlipFromEntity(data.handle))
	end
	cb({})
end)

RegisterNUICallback('collisionOn', function(data, cb)
	if Permissions.properties.collision and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetEntityCollision(data.handle, true, true)
	end
	cb({})
end)

RegisterNUICallback('collisionOff', function(data, cb)
	if Permissions.properties.collision and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetEntityCollision(data.handle, false, false)
	end
	cb({})
end)

RegisterNUICallback('giveWeapon', function(data, cb)
	if Permissions.properties.ped.weapon and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		GiveWeaponToPed_2(data.handle, GetHashKey(data.weapon), 500, true, false, 0, false, 0.5, 1.0, 0, false, 0.0, false)

		if Database[data.handle] then
			table.insert(Database[data.handle].weapons, data.weapon)
		end
	end
	cb({})
end)

RegisterNUICallback('removeAllWeapons', function(data, cb)
	if Permissions.properties.ped.weapon and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		RemoveAllPedWeapons(data.handle, true, true)

		if Database[data.handle] then
			Database[data.handle].weapons = {}
		end
	end
	cb({})
end)

RegisterNUICallback('resurrectPed', function(data, cb)
	if Permissions.properties.ped.resurrect and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		ResurrectPed(data.handle)
	end
	cb({})
end)

RegisterNUICallback('setOnMount', function(data, cb)
	if Permissions.properties.ped.mount and CanModifyEntity(data.handle) then
		SetPedOnMount(data.handle, data.entity, -1, false)
	end
	cb({})
end)

RegisterNUICallback('engineOn', function(data, cb)
	if Permissions.properties.vehicle.engine and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetVehicleEngineOn(data.handle, true, true)
	end
	cb({})
end)

RegisterNUICallback('engineOff', function(data, cb)
	if Permissions.properties.vehicle.engine and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetVehicleEngineOn(data.handle, false, true)
	end
	cb({})
end)

RegisterNUICallback('setLightsIntensity', function(data, cb)
	if Permissions.properties.lights and CanModifyEntity(data.handle) then
		local intensity = data.intensity and data.intensity * 1.0 or 0.0

		RequestControl(data.handle)
		SetLightsIntensityForEntity(data.handle, intensity)

		if EntityIsInDatabase(data.handle) then
			Database[data.handle].lightsIntensity = intensity
		end
	end

	cb({})
end)

RegisterNUICallback('setLightsColour', function(data, cb)
	if Permissions.properties.lights and CanModifyEntity(data.handle) then
		local red = data.red and data.red or 0
		local green = data.green and data.green or 0
		local blue = data.blue and data.blue or 0

		RequestControl(data.handle)
		SetLightsColorForEntity(data.handle, red, green, blue)

		if EntityIsInDatabase(data.handle) then
			Database[data.handle].lightsColour = {
				red = red,
				green = green,
				blue = blue
			}
		end
	end

	cb({})
end)

RegisterNUICallback('setLightsType', function(data, cb)
	if Permissions.properties.lights and CanModifyEntity(data.handle) then
		local type = data.type and data.type or 0

		RequestControl(data.handle)
		SetLightsTypeForEntity(data.handle, type)

		if EntityIsInDatabase(data.handle) then
			Database[data.handle].lightsType = type
		end
	end

	cb({})
end)

RegisterNUICallback('setVehicleLightsOn', function(data, cb)
	if Permissions.properties.vehicle.lights and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetVehicleLights(data.handle, false)
	end
	cb({})
end)

RegisterNUICallback('setVehicleLightsOff', function(data, cb)
	if Permissions.properties.vehicle.lights and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetVehicleLights(data.handle, true)
	end
	cb({})
end)

RegisterNUICallback('aiOn', function(data, cb)
	if Permissions.properties.ped.ai and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetBlockingOfNonTemporaryEvents(data.handle, false)

		if Database[data.handle] then
			Database[data.handle].blockNonTemporaryEvents = false
		end
	end

	cb({})
end)

RegisterNUICallback('aiOff', function(data, cb)
	if Permissions.properties.ped.ai and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetBlockingOfNonTemporaryEvents(data.handle, true)

		if Database[data.handle] then
			Database[data.handle].blockNonTemporaryEvents = true
		end
	end

	cb({})
end)

RegisterNUICallback('setPlayerModel', function(data, cb)
	if Permissions.properties.ped.changeModel and data.modelName then
		local model = GetHashKey(data.modelName)

		if LoadModel(model) then
			SetPlayerModel(PlayerId(), model, true)
		end
	end
	cb({
		handle = PlayerPedId()
	})
end)

RegisterNUICallback('playAnimation', function(data, cb)
	if Permissions.properties.ped.animation and CanModifyEntity(data.handle) then
		local blendInSpeed = data.blendInSpeed and data.blendInSpeed * 1.0 or 1.0
		local blendOutSpeed = data.blendOutSpeed and data.blendOutSpeed * 1.0 or 1.0
		local duration = data.duration and data.duraction or -1
		local flag = data.flag and data.flag or 1
		local playbackRate = data.playbackRate and data.playbackRate * 1.0 or 1.0

		RequestControl(data.handle)

		local animation = {
			dict = data.dict,
			name = data.name,
			blendInSpeed = blendInSpeed,
			blendOutSpeed = blendOutSpeed,
			duration = duration,
			flag = flag,
			playbackRate = playbackRate
		}

		if PlayAnimation(data.handle, animation) and Database[data.handle] then
			Database[data.handle].animation = animation
			Database[data.handle].scenario = nil
		end
	end

	cb({})
end)

RegisterNUICallback('loadPermissions', function(data, cb)
	cb(json.encode(Permissions))
end)

RegisterNUICallback('knockOffProps', function(data, cb)
	if Permissions.properties.ped.knockOffProps and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		KnockOffPedProp(data.handle, true, true, true, true)
	end

	cb({})
end)

RegisterNUICallback('setWalkStyle', function(data, cb)
	if Permissions.properties.ped.walkStyle and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		SetWalkStyle(data.handle, data.base, data.style)
	end

	cb({})
end)

RegisterNUICallback('setStoreDeleted', function(data, cb)
	if StoreDeleted then
		StoreDeleted = false
		DeletedEntities = {}
	else
		StoreDeleted = true
	end

	cb({})
end)

RegisterNUICallback('clonePedToTarget', function(data, cb)
	if Permissions.properties.ped.cloneToTarget and CanModifyEntity(data.target) then
		RequestControl(data.target)
		ClonePedToTarget(data.handle, data.target)
	end

	cb({})
end)

RegisterNUICallback('lookAtEntity', function(data, cb)
	if Permissions.properties.ped.lookAtEntity and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		TaskLookAtEntity(data.handle, data.target, -1)
	end

	cb({})
end)

RegisterNUICallback('clearLookAt', function(data, cb)
	if Permissions.properties.ped.lookAtEntity and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		TaskClearLookAt(data.handle)
	end

	cb({})
end)

RegisterNUICallback('registerAsNetworked', function(data, cb)
	if Permissions.properties.registerAsNetworked and CanModifyEntity(data.handle) then
		NetworkRegisterEntityAsNetworked(data.handle)
	end

	cb({})
end)

RegisterNUICallback('saveFavourites', function(data, cb)
	SetResourceKvp('favourites', json.encode(data.favourites))
	cb({})
end)

RegisterNUICallback('cleanPed', function(data, cb)
	if Permissions.properties.ped.clean and CanModifyEntity(data.handle) then
		RequestControl(data.handle)
		ClearPedEnvDirt(data.handle)
		ClearPedDamageDecalByZone(data.handle, 10, "ALL")
		ClearPedBloodDamage(data.handle)
	end
	cb({})
end)

-- Temporary function to migrate old kvs keys of DBs to the new kvs key format
function MigrateOldSavedDbs()
	local handle = StartFindKvp("")

	while true do
		local kvp = FindKvp(handle)

		if kvp then
			if kvp ~= 'favourites' and string.sub(kvp, 1, 3) ~= 'DB_' and not GetResourceKvpString('DB_' .. kvp) then
				SetResourceKvp('DB_' .. kvp, GetResourceKvpString(kvp))
				print('Migrated old DB: ' .. kvp)
				DeleteResourceKvp(kvp)
			end
		else
			break
		end
	end

	EndFindKvp(handle)
end
RegisterCommand('spooner_migrate_old_dbs', function(source, args, raw)
	MigrateOldSavedDbs()
end)

function CheckControls(func, pad, controls)
	if type(controls) == 'number' then
		return func(pad, controls)
	end

	for _, control in ipairs(controls) do
		if func(pad, control) then
			return true
		end
	end

	return false
end

function MainSpoonerUpdates()
	local playerPed = PlayerPedId()

	if not EntityIsInDatabase(playerPed) then
		AddEntityToDatabase(playerPed)
	end

	if IsUsingKeyboard(0) and CheckControls(IsDisabledControlJustPressed, 0, Config.ToggleControl) then
		TriggerServerEvent('spooner:toggle')
	end

	if Cam then
		DisableAllControlActions(0)
		EnableControlAction(0, 0x4A903C11)
		EnableControlAction(0, 0x9720fcee)

		local x1, y1, z1 = table.unpack(GetCamCoord(Cam))
		local pitch1, roll1, yaw1 = table.unpack(GetCamRot(Cam, 2))

		local x2 = x1
		local y2 = y1
		local z2 = z1
		local pitch2 = pitch1
		local roll2 = roll1
		local yaw2 = yaw1

		local spawnPos, entity, distance = GetInView(x2, y2, z2, pitch2, roll2, yaw2)

		if AttachedEntity then
			entity = AttachedEntity
		end

		SendNUIMessage({
			type = 'updateSpoonerHud',
			entity = entity,
			netId = NetworkGetEntityIsNetworked(entity) and ObjToNet(entity),
			entityType = GetSpoonerEntityType(entity),
			modelName = GetModelName(GetSpoonerEntityModel(entity)),
			attachedEntity = AttachedEntity,
			speed = string.format('%.2f', Speed),
			currentSpawn = CurrentSpawn and CurrentSpawn.modelName,
			rotateMode = RotateMode,
			adjustMode = AdjustMode,
			speedMode = SpeedMode,
			placeOnGround = PlaceOnGround,
			adjustSpeed = AdjustSpeed,
			rotateSpeed = RotateSpeed,
			cursorX = string.format('%.2f', spawnPos.x),
			cursorY = string.format('%.2f', spawnPos.y),
			cursorZ = string.format('%.2f', spawnPos.z),
			camX = string.format('%.2f', x2),
			camY = string.format('%.2f', y2),
			camZ = string.format('%.2f', z2),
			camHeading = string.format('%.2f', yaw2)
		})

		if CheckControls(IsDisabledControlPressed, 0, Config.IncreaseSpeedControl) then
			if SpeedMode == 0 then
				Speed = Speed + Config.SpeedIncrement
			elseif SpeedMode == 1 then
				AdjustSpeed = AdjustSpeed + Config.AdjustSpeedIncrement
			elseif SpeedMode == 2 then
				RotateSpeed = RotateSpeed + Config.RotateSpeedIncrement
			end
		end

		if CheckControls(IsDisabledControlPressed, 0, Config.DecreaseSpeedControl) then
			if SpeedMode == 0 then
				Speed = Speed - Config.SpeedIncrement
			elseif SpeedMode == 1 then
				AdjustSpeed = AdjustSpeed - Config.AdjustSpeedIncrement
			elseif SpeedMode == 2 then
				RotateSpeed = RotateSpeed - Config.RotateSpeedIncrement
			end
		end

		if Speed < Config.MinSpeed then
			Speed = Config.MinSpeed
		elseif Speed > Config.MaxSpeed then
			Speed = Config.MaxSpeed
		end

		if AdjustSpeed < Config.MinAdjustSpeed then
			AdjustSpeed = Config.MinAdjustSpeed
		elseif AdjustSpeed > Config.MaxAdjustSpeed then
			AdjustSpeed = Config.MaxAdjustSpeed
		end

		if RotateSpeed < Config.MinRotateSpeed then
			RotateSpeed = Config.MinRotateSpeed
		elseif RotateSpeed > Config.MaxRotateSpeed then
			RotateSpeed = Config.MaxRotateSpeed
		end

		if CheckControls(IsDisabledControlPressed, 0, Config.UpControl) then
			z2 = z2 + Speed
		end

		if CheckControls(IsDisabledControlPressed, 0, Config.DownControl) then
			z2 = z2 - Speed
		end

		local axisX = GetDisabledControlNormal(0, 0xA987235F)
		local axisY = GetDisabledControlNormal(0, 0xD2047988)

		if axisX ~= 0.0 or axisY ~= 0.0 then
			yaw2 = yaw2 + axisX * -1.0 * Config.SpeedUd
			pitch2 = math.max(math.min(89.9, pitch2 + axisY * -1.0 * Config.SpeedLr), -89.9)
		end

		local r1 = -yaw2 * math.pi / 180
		local dx1 = Speed * math.sin(r1)
		local dy1 = Speed * math.cos(r1)

		local r2 = math.floor(yaw2 + 90.0) % 360 * -1.0 * math.pi / 180
		local dx2 = Speed * math.sin(r2)
		local dy2 = Speed * math.cos(r2)

		if CheckControls(IsDisabledControlPressed, 0, Config.ForwardControl) then
			x2 = x2 + dx1
			y2 = y2 + dy1
		end

		if CheckControls(IsDisabledControlPressed, 0, Config.BackwardControl) then
			x2 = x2 - dx1
			y2 = y2 - dy1
		end

		if CheckControls(IsDisabledControlPressed, 0, Config.LeftControl) then
			x2 = x2 + dx2
			y2 = y2 + dy2
		end

		if CheckControls(IsDisabledControlPressed, 0, Config.RightControl) then
			x2 = x2 - dx2
			y2 = y2 - dy2
		end

		if CheckControls(IsDisabledControlJustPressed, 0, Config.SpawnControl) and CurrentSpawn then
			local entity

			if CurrentSpawn.type == 1 then
				entity = SpawnPed(CurrentSpawn.modelName, GetHashKey(CurrentSpawn.modelName), spawnPos.x, spawnPos.y, spawnPos.z, 0.0, 0.0, yaw2, false, -1, false, nil, nil, false, nil, nil)
			elseif CurrentSpawn.type == 2 then
				entity = SpawnVehicle(CurrentSpawn.modelName, GetHashKey(CurrentSpawn.modelName), spawnPos.x, spawnPos.y, spawnPos.z, 0.0, 0.0, yaw2, false)
			elseif CurrentSpawn.type == 3 then
				entity = SpawnObject(CurrentSpawn.modelName, GetHashKey(CurrentSpawn.modelName), spawnPos.x, spawnPos.y, spawnPos.z, 0.0, 0.0, yaw2, false, nil, nil, nil)
			elseif CurrentSpawn.type == 4 then
				entity = SpawnPropset(CurrentSpawn.modelName, GetHashKey(CurrentSpawn.modelName), spawnPos.x, spawnPos.y, spawnPos.z, yaw2)
			elseif CurrentSpawn.type == 5 then
				entity = SpawnPickup(CurrentSpawn.modelName, GetHashKey(CurrentSpawn.modelName), spawnPos.x, spawnPos.y, spawnPos.z)
			end

			if entity then
				PlaceOnGroundProperly(entity)
			end
		end

		if CheckControls(IsDisabledControlJustPressed, 0, Config.SelectControl) then
			if AttachedEntity then
				AttachedEntity = nil
			elseif entity and CanModifyEntity(entity) then
				if IsEntityAttached(entity) then
					AttachedEntity = GetEntityAttachedTo(entity)
				else
					AttachedEntity = entity
				end
			end
		end

		if CheckControls(IsDisabledControlJustPressed, 0, Config.DeleteControl) and entity then
			if AttachedEntity then
				RemoveEntity(AttachedEntity)
				AttachedEntity = nil
			else
				RemoveEntity(entity)
			end
		end

		if CheckControls(IsDisabledControlJustReleased, 0, Config.ObjectMenuControl) then
			SendNUIMessage({
				type = 'openSpawnMenu'
			})
			SetNuiFocus(true, true)
		end

		if CheckControls(IsDisabledControlJustReleased, 0, Config.DbMenuControl) then
			OpenDatabaseMenu()
		end

		if CheckControls(IsDisabledControlJustReleased, 0, Config.SaveLoadDbMenuControl) then
			OpenSaveDbMenu()
		end

		if CheckControls(IsDisabledControlJustReleased, 0, Config.HelpMenuControl) then
			SendNUIMessage({
				type = 'openHelpMenu'
			})
			SetNuiFocus(true, true)
		end

		if CheckControls(IsDisabledControlJustPressed, 0, Config.RotateModeControl) then
			RotateMode = (RotateMode + 1) % 3
		end

		if CheckControls(IsDisabledControlJustPressed, 0, Config.AdjustModeControl) then
			if AdjustMode < 4 then
				AdjustMode = (AdjustMode + 1) % 4
			else
				AdjustMode = 0
			end
		end

		if CheckControls(IsDisabledControlJustPressed, 0, Config.FreeAdjustModeControl) then
			AdjustMode = 4
		end

		if CheckControls(IsDisabledControlJustPressed, 0, Config.AdjustOffControl) then
			AdjustMode = 5
		end

		if CheckControls(IsDisabledControlJustPressed, 0, Config.SpeedModeControl) then
			SpeedMode = (SpeedMode + 1) % 3
		end

		if CheckControls(IsDisabledControlJustPressed, 0, Config.PlaceOnGroundControl) then
			PlaceOnGround = not PlaceOnGround
		end

		if entity and CanModifyEntity(entity) then
			local posChanged = false
			local rotChanged = false

			if CheckControls(IsDisabledControlJustReleased, 0, Config.PropMenuControl) then
				OpenPropertiesMenuForEntity(entity)
			end

			if CheckControls(IsDisabledControlJustPressed, 0, Config.CloneControl) then
				AttachedEntity = CloneEntity(entity)
			end

			local ex1, ey1, ez1, epitch1, eroll1, eyaw1

			if Database[entity] and Database[entity].attachment.to > 0 then
				ex1 = Database[entity].attachment.x
				ey1 = Database[entity].attachment.y
				ez1 = Database[entity].attachment.z
				epitch1 = Database[entity].attachment.pitch
				eroll1 = Database[entity].attachment.roll
				eyaw1 = Database[entity].attachment.yaw
			else
				ex1, ey1, ez1 = table.unpack(GetEntityCoords(entity))
				epitch1, eroll1, eyaw1 = table.unpack(GetEntityRotation(entity, 2))
			end

			local ex2 = ex1
			local ey2 = ey1
			local ez2 = ez1
			local epitch2 = epitch1
			local eroll2 = eroll1
			local eyaw2 = eyaw1

			local edx1, edy1, edx2, edy2

			if Database[entity] and Database[entity].attachment.to > 0 then
				edx1 = 0
				edy1 = AdjustSpeed
				edx2 = AdjustSpeed
				edy2 = 0
			else
				edx1 = AdjustSpeed * math.sin(r1)
				edy1 = AdjustSpeed * math.cos(r1)
				edx2 = AdjustSpeed * math.sin(r2)
				edy2 = AdjustSpeed * math.cos(r2)
			end

			if CheckControls(IsDisabledControlPressed, 0, Config.RotateLeftControl) then
				if RotateMode == 0 then
					epitch2 = epitch2 + RotateSpeed
				elseif RotateMode == 1 then
					eroll2 = eroll2 + RotateSpeed
				else
					eyaw2 = eyaw2 + RotateSpeed
				end

				rotChanged = true
			end

			if CheckControls(IsDisabledControlPressed, 0, Config.RotateRightControl) then
				if RotateMode == 0 then
					epitch2 = epitch2 - RotateSpeed
				elseif RotateMode == 1 then
					eroll2 = eroll2 - RotateSpeed
				else
					eyaw2 = eyaw2 - RotateSpeed
				end

				rotChanged = true
			end

			if CheckControls(IsDisabledControlPressed, 0, Config.AdjustUpControl) then
				ez2 = ez2 + AdjustSpeed
				posChanged = true
			end

			if CheckControls(IsDisabledControlPressed, 0, Config.AdjustDownControl) then
				ez2 = ez2 - AdjustSpeed
				posChanged = true
			end

			if CheckControls(IsDisabledControlPressed, 0, Config.AdjustForwardControl) then
				ex2 = ex2 + edx1
				ey2 = ey2 + edy1
				posChanged = true
			end

			if CheckControls(IsDisabledControlPressed, 0, Config.AdjustBackwardControl) then
				ex2 = ex2 - edx1
				ey2 = ey2 - edy1
				posChanged = true
			end

			if CheckControls(IsDisabledControlPressed, 0, Config.AdjustLeftControl) then
				ex2 = ex2 + edx2
				ey2 = ey2 + edy2
				posChanged = true
			end

			if CheckControls(IsDisabledControlPressed, 0, Config.AdjustRightControl) then
				ex2 = ex2 - edx2
				ey2 = ey2 - edy2
				posChanged = true
			end

			if AttachedEntity or posChanged or rotChanged then
				RequestControl(entity)

				if Database[entity] and Database[entity].attachment.to > 0 then
					AttachEntity(entity, Database[entity].attachment.to, bone, ex2, ey2, ez2, epitch2, eroll2, eyaw2)
				else
					if posChanged then
						SetEntityCoordsNoOffset(entity, ex2, ey2, ez2)
					end

					if rotChanged then
						SetEntityRotation(entity, epitch2, eroll2, eyaw2, 2)
					end
				end

				if AttachedEntity then
					if AdjustMode < 4 then
						x2 = x1
						y2 = y1
						z2 = z1
						pitch2 = pitch1
						yaw2 = yaw1

						if AdjustMode == 0 then
							SetEntityCoordsNoOffset(AttachedEntity, ex2 - axisX, ey2, ez2)
						elseif AdjustMode == 1 then
							SetEntityCoordsNoOffset(AttachedEntity, ex2, ey2 - axisX, ez2)
						elseif AdjustMode == 2 then
							SetEntityCoordsNoOffset(AttachedEntity, ex2, ey2, ez2 - axisY)
						elseif AdjustMode == 3 then
							if RotateMode == 0 then
								SetEntityRotation(AttachedEntity, epitch2 - axisX * Config.SpeedLr, eroll2, eyaw2)
							elseif RotateMode == 1 then
								SetEntityRotation(AttachedEntity, epitch2, eroll2 - axisX * Config.SpeedLr, eyaw2)
							else
								SetEntityRotation(AttachedEntity, epitch2, eroll2, eyaw2 - axisX * Config.SpeedLr)
							end
						end
					elseif AdjustMode == 4 then
						SetEntityCoordsNoOffset(AttachedEntity, spawnPos.x, spawnPos.y, spawnPos.z)
					end

					if PlaceOnGround or AdjustMode == 4 then
						PlaceOnGroundProperly(AttachedEntity)
					end
				end
			end
		end

		SetCamCoord(Cam, x2, y2, z2)
		SetCamRot(Cam, pitch2, 0.0, yaw2)
	end
end

CreateThread(function()
	TriggerEvent('chat:addSuggestion', '/spooner', 'Toggle spooner mode', {})

	TriggerServerEvent('spooner:init')

	while true do
		Wait(0)
		MainSpoonerUpdates()
	end
end)

function UpdateDbEntities()
	for entity, properties in pairs(Database) do
		if not NetworkGetEntityIsNetworked(entity) then
			NetworkRegisterEntityAsNetworked(entity)
		end

		if properties.scenario then
			local hash = GetHashKey(properties.scenario)

			if not IsPedUsingScenarioHash(entity, hash) then
				TaskStartScenarioInPlace(entity, hash, -1)
			end
		end

		if properties.animation then
			if not IsEntityPlayingAnim(entity, properties.animation.dict, properties.animation.name, properties.animation.flag) then
				PlayAnimation(entity, properties.animation)
			end
		end
	end
end

CreateThread(function()
	while true do
		Wait(1000)
		UpdateDbEntities()
	end
end)

-- FIXME:
-- This shouldn't be necessary, but RedM doesn't appear to free the memory
-- allocated for NUI messages, so eventually it causes resource memory
-- warnings.
CreateThread(function()
	while true do
		if collectgarbage("count") > 50000 then
			print("Collecting garbage...")
			collectgarbage()
		end
		Wait(10000)
	end
end)
