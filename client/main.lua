ESX = nil
local PlayerData = {}
local wait = true
local MyVehicles = {}
Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	PlayerData = xPlayer 
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
	
	Citizen.Wait(10)
end)

-- Create blips
Citizen.CreateThread(function()
	for k,v in pairs(Config.Garages) do
		local blip = AddBlipForCoord(v.loc[1],v.loc[2],v.loc[3])

		SetBlipSprite (blip, 357)
		SetBlipDisplay(blip, 2)
		SetBlipScale  (blip, 0.7)
		SetBlipColour (blip, 67)
		SetBlipAsShortRange(blip, true)

		BeginTextCommandSetBlipName('STRING')
		AddTextComponentSubstringPlayerName('Garage | ' .. v.garage)
		EndTextCommandSetBlipName(blip)
	end

	for k,v in pairs(Config.Impound) do
		local blip = AddBlipForCoord(v.loc[1],v.loc[2],v.loc[3])

		SetBlipSprite (blip, 67)
		SetBlipDisplay(blip, 2)
		SetBlipScale  (blip, 0.7)
		SetBlipColour (blip, 64)
		SetBlipAsShortRange(blip, true)

		BeginTextCommandSetBlipName('STRING')
		AddTextComponentSubstringPlayerName('Impound')
		EndTextCommandSetBlipName(blip)
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(1)

		-- Impound
		for k,v in pairs(Config.Impound) do
			local d = Vdist2(GetEntityCoords(GetPlayerPed(-1)), v.loc[1],v.loc[2],v.loc[3])
			if d < 500 then
			DrawMarker(20,v.loc[1],v.loc[2],v.loc[3]-0.3,0,0,0,0,0,0,0.701,1.0001,0.3001,255,0, 0,60,0,0,0,0)
			end
			if d < 2 then
				ESX.ShowHelpNotification('Press ~INPUT_CONTEXT~ to open the ~y~Impound~s~.')
				if IsControlJustPressed(0,38) then
					Impound()
				end
			end
		end

		-- Menu
		for k,v in pairs(Config.Garages) do
			local d = Vdist2(GetEntityCoords(GetPlayerPed(-1)), v.loc[1],v.loc[2],v.loc[3])
			if d < 500 then
			DrawMarker(20,v.loc[1],v.loc[2],v.loc[3]-0.3,0,0,0,0,0,0,0.701,1.0001,0.3001,0,0, 255,60,0,0,0,0)
			end
			if d < 2 and not IsPedInAnyVehicle(GetPlayerPed(-1)) then
				ESX.ShowHelpNotification('Press ~INPUT_CONTEXT~ to open the ~y~Garage~s~.')
				if IsControlJustPressed(0,38) then
				Menu(v.garage)
				end
			end
		end

		-- Store Vehicle
		for k,v in pairs(Config.Garages) do
			if IsPedInAnyVehicle(GetPlayerPed(-1)) then
			local d = Vdist2(GetEntityCoords(GetPlayerPed(-1)), v.spawn[1],v.spawn[2],v.spawn[3])
			if d < 500 then
			DrawMarker(20,v.spawn[1],v.spawn[2],v.spawn[3]+0.5,0,0,0,0,0,0,0.701,1.0001,0.3001,255,0, 0,60,0,0,0,0)
			end
			if d < 5 then
				local playerPed = GetPlayerPed(-1)
				local veh = GetVehiclePedIsIn(playerPed, false)
				local vehicleProps = ESX.Game.GetVehicleProperties(veh)
				local hashVehicule = GetEntityModel(veh)
				local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
				local vehicleName = GetLabelText(aheadVehName)
				if Config.ModelLabels[aheadVehName] ~= nil then
					vehicleName = Config.ModelLabels[aheadVehName]
				end
				ESX.ShowHelpNotification('Press ~INPUT_CONTEXT~ to store ~y~' .. vehicleName .. '~s~ for ~y~$' .. Config.StorePrice .. '~s~')
				if IsControlJustPressed(0,38) then
					ESX.TriggerServerCallback('garage:requestPlayerCars', function(isOwnedVehicle)
						if isOwnedVehicle then

							ESX.TriggerServerCallback('garage:checkMoney', function(hasEnoughMoney)
								if hasEnoughMoney then
									StoreVehicle(veh, vehicleProps,v.garage)
									TriggerEvent('notification', 'You have stored ' .. vehicleName .. ' for $' .. Config.StorePrice .. '.',1)
								else
									TriggerEvent('notification', 'You do not have enough money.', 2)
								end
							end, Config.StorePrice)

						else
							TriggerEvent('notification', 'You can not store this vehicle.', 2)
						end
					end, vehicleProps.plate)
				end
			end
		end
		end
	end
end)

function StoreVehicle(vehicle, vehicleProps,garage)
	ESX.Game.DeleteVehicle(vehicle)
	local data = {
		bodyh = GetVehicleBodyHealth(vehicle),
		engineh = GetVehicleEngineHealth(vehicle),
		fuel = GetVehicleFuelLevel(vehicle),
		dirty = GetVehicleDirtLevel(vehicle),
	}
	TriggerServerEvent('garage:setVehicleProps', vehicleProps.plate, data)
	TriggerServerEvent('garage:setVehicleStored', vehicleProps.plate, true)
	TriggerServerEvent('garage:setVehicleGarage', vehicleProps.plate, garage)
end


function DrawText3D(x,y,z, text)

    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    local px,py,pz=table.unpack(GetGameplayCamCoords())
    
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
    local factor = (string.len(text)) / 370
    DrawRect(_x,_y+0.0125, 0.015+ factor, 0.03, 41, 11, 41, 68)
end


-- List Owned Cars Menu
function Menu(garage)
	
	ESX.TriggerServerCallback('garage:getOwnedCars', function(cars)
		local elements = {}
		for _,v in pairs(cars) do
		local hashVehicule = v.vehicle.model
		local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
		local vehicleName = GetLabelText(aheadVehName)
		local plate = v.plate

		if Config.ModelLabels[aheadVehName] ~= nil then
			vehicleName = Config.ModelLabels[aheadVehName]
		end

		if v.stored and v.garage == garage then
			table.insert(elements, { label = vehicleName .. ' | ' .. plate, name = vehicleName,value = v})
		end
		end

		if #elements == 0 then
			table.insert(elements, { label = 'You dont have any vehicles here', value = 'none'})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'owned_vehicles', {
			title    = 'Garage ' .. garage,
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			if data.current.value ~= 'none' then
				menu.close()
				SpawnVehicle(data.current.value.vehicle, data.current.value.plate, garage,data.current.name)
			end
		end, function(data, menu)
			menu.close()
		end)
	end)
end

function SpawnVehicle(vehicle, plate,garage,name)
	local coords = {
		x = Config.Garages[garage].spawn[1],
		y = Config.Garages[garage].spawn[2],
		z = Config.Garages[garage].spawn[3],
	}
	if ESX.Game.IsSpawnPointClear(coords, 2) then
	ESX.Game.SpawnVehicle(vehicle.model, coords, 100, function(spawn_vehicle)
			ESX.Game.SetVehicleProperties(spawn_vehicle, vehicle)
			SetVehRadioStation(spawn_vehicle, "OFF")
			SetVehicleUndriveable(spawn_vehicle, false)
			SetVehicleEngineOn(spawn_vehicle, true, true)
			--SetVehicleEngineHealth(spawn_vehicle, 1000) -- Might not be needed
			--SetVehicleBodyHealth(spawn_vehicle, 1000) -- Might not be needed
			--TaskWarpPedIntoVehicle(GetPlayerPed(-1), spawn_vehicle, -1)
			TriggerEvent('notification', 'You have spawned ' .. name .. ' from the garage.', 1)
			table.insert(MyVehicles,{ plate = plate, veh = spawn_vehicle, label = name})
	end)
	for k,v in pairs(MyVehicles) do
		if v.plate == plate then
			ESX.Game.DeleteVehicle(v.veh)
		end
	end
	TriggerServerEvent('garage:setVehicleStored', plate, false, '')
else
	TriggerEvent('notification', 'Please clear the spawn point.', 2)
end
end


-- List Owned Cars Menu
function Impound()
	
	ESX.TriggerServerCallback('garage:getOwnedCars', function(cars)
		local elements = {}
		for _,v in pairs(cars) do
		local hashVehicule = v.vehicle.model
		local aheadVehName = GetDisplayNameFromVehicleModel(hashVehicule)
		local vehicleName = GetLabelText(aheadVehName)
		local plate = v.plate

		if Config.ModelLabels[aheadVehName] ~= nil then
			vehicleName = Config.ModelLabels[aheadVehName]
		end

		if not v.stored then
			table.insert(elements, { label = vehicleName .. ' | ' .. plate, name = vehicleName,value = v, garage = v.garage})
		end
		end

		if #elements == 0 then
			table.insert(elements, { label = 'You dont have any vehicles in the impound.', value = 'none'})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'impound', {
			title    = 'Impound',
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			if data.current.value ~= 'none' then
				ESX.TriggerServerCallback('impound:checkMoney', function(hasBuy)
					if hasBuy then
						menu.close()
						GetFromImpound(data.current.value.plate, data.current.garage, garage,data.current.name)
					else
						TriggerEvent('notification', 'You do not have enough money.', 2)
					end
				end, Config.ImpoundPrice)
			end
		end, function(data, menu)
			menu.close()
		end)
	end)
end

function GetFromImpound(plate,garage,name)
	TriggerEvent('notification', 'Your vehicle is in garage ' .. garage .. '.', 1)
	TriggerServerEvent('garage:setVehicleStored', plate, true)
end