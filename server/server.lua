ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback('garage:getOwnedCars', function(source, cb)
	local ownedCars = {}
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner', { 
		['@owner'] = xPlayer.identifier
	}, function(data)
		for _,v in pairs(data) do
			local vehicle = json.decode(v.vehicle)
			table.insert(ownedCars, {vehicle = vehicle, stored = v.stored, plate = v.plate, garage = v.garage})
		end
		cb(ownedCars)
	end)
end)


RegisterServerEvent('garage:setVehicleStored')
AddEventHandler('garage:setVehicleStored', function(plate, state)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = @stored WHERE plate = @plate', {
		['@stored'] = state,
		['@plate'] = plate
	}, function(rowsChanged)

	end)
end)

RegisterServerEvent('garage:setVehicleGarage')
AddEventHandler('garage:setVehicleGarage', function(plate, g)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.execute('UPDATE owned_vehicles SET `garage` = @ga WHERE plate = @plate', {
		['@ga'] = g,
		['@plate'] = plate
	}, function(rowsChanged)

	end)
end)

RegisterServerEvent('garage:setVehicleProps')
AddEventHandler('garage:setVehicleProps', function(plate, data)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.execute('UPDATE owned_vehicles SET `data` = @props WHERE plate = @plate', {
		['@props'] = json.encode(data),
		['@plate'] = plate
	}, function(rowsChanged)

	end)
end)

ESX.RegisterServerCallback('garage:getVehicleData', function(source, cb, p)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE plate = @plate', {
		['@plate'] = p
	}, function(data)
		local vehicle = data[1]
		local vd = nil


		if data.data ~= nil then
			vd = json.decode(vehicle.data)
		end

		cb(vd)
	end)
end)


ESX.RegisterServerCallback('garage:requestPlayerCars', function(source, cb, plate)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT 1 FROM owned_vehicles WHERE owner = @owner AND plate = @plate', {
		['@owner'] = xPlayer.identifier,
		['@plate'] = plate
	}, function(result)
		cb(result[1] ~= nil)
	end)
end)

ESX.RegisterServerCallback('garage:checkMoney', function(source, cb, money)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getMoney() >= money then
		cb(true)
		xPlayer.removeMoney(money)
	else
		cb(false)
	end
end)

ESX.RegisterServerCallback('impound:checkMoney', function(source, cb, money)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getMoney() >= money then
		cb(true)
		xPlayer.removeMoney(money)
	else
		cb(false)
	end
end)