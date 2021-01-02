--[[ ===================================================== ]]--
--[[         FiveM Real Parking Script by Akkariin         ]]--
--[[ ===================================================== ]]--

RSCore = nil

TriggerEvent("RSCore:GetObject", function(response)
	RSCore = response
end)

-- When the client request to refresh the vehicles

RegisterServerEvent('esx_realparking:refreshVehicles')
AddEventHandler('esx_realparking:refreshVehicles', function(parkingName)
	local xPlayer = RSCore.Functions.GetPlayer(source)
	RefreshVehicles(xPlayer, source, parkingName)
	print(xPlayer.PlayerData.money.cash)
end)
function tprint (tbl, indent)
	if not indent then indent = 0 end
	for k, v in pairs(tbl) do
	  formatting = string.rep("  ", indent) .. k .. ": "
	  if type(v) == "table" then
		print(formatting)
		tprint(v, indent+1)
	  elseif type(v) == 'boolean' then
		print(formatting .. tostring(v))      
	  else
		print(formatting .. v)
	  end
	end
  end
RegisterServerEvent('esx_realparking:refreshVehiclesOnStart')
AddEventHandler('esx_realparking:refreshVehiclesOnStart', function()

	local xPlayer = RSCore.Functions.GetPlayer(source)
	for k,v in pairs(Config.ParkingLocations) do
		print(k)
	RefreshVehicles(xPlayer, source, k)
	end
	print(xPlayer.PlayerData.money.cash)
end)
-- Save the car to database

RSCore.Functions.CreateCallback("esx_realparking:saveCar", function(source, cb, vehicleData)
	local xPlayer = RSCore.Functions.GetPlayer(source)
    local plate   = vehicleData.props.plate
	local isFound = false
	FindPlayerVehicles(xPlayer.PlayerData.citizenid, function(vehicles)
		for k, v in pairs(vehicles) do
			if type(v.plate) ~= 'nil' and string.trim(plate) == string.trim(v.plate) then
				isFound = true
			end		
		end
		if GetVehicleNumOfParking(vehicleData.parking) > Config.ParkingLocations[vehicleData.parking].maxcar then
			cb({
				status  = false,
				message = _U("parking_full"),
			})
		elseif isFound then
			exports['ghmattimysql']:execute("SELECT * FROM `car_parking` WHERE `owner` = '"..xPlayer.PlayerData.citizenid.."' AND plate = '"..plate.."'", function(rs)
				if type(rs) == 'table' and #rs > 0 then
					cb({
						status  = false,
						message = _U("already_parking"),  
					})
				else
					exports['ghmattimysql']:execute("INSERT INTO `car_parking` (`owner`, `plate`, `data`, `time`, `parking`) VALUES ('"..xPlayer.PlayerData.citizenid.."', '"..plate.."', '"..json.encode(vehicleData).."', '"..os.time().."', '"..vehicleData.parking.."')")

					exports['ghmattimysql']:execute("UPDATE player_vehicles SET state = 2 WHERE plate = '"..plate.."' AND citizenid = '"..xPlayer.PlayerData.citizenid.."'")
					exports['ghmattimysql']:execute("UPDATE player_vehicles SET mods = '"..json.encode(vehicleData.props).."' WHERE citizenid = '"..xPlayer.PlayerData.citizenid.."' AND plate = '"..plate.."'")
					cb({
						status  = true,
						message = _U("car_saved"),
					})
					Wait(100)
					TriggerClientEvent("esx_realparking:addVehicle", -1, {vehicle = vehicleData, plate = plate, fee = 0.0, owner = xPlayer.PlayerData.citizenid, name = xPlayer.PlayerData.charinfo.firstname})
				end
			end)
		else
			cb({
				status  = false,
				message = _U("not_your_car"),
			})
		end
	end)
end)

-- When player request to drive the car

RSCore.Functions.CreateCallback("esx_realparking:driveCar", function(source, cb, vehicleData)
	local xPlayer = RSCore.Functions.GetPlayer(source)
    local plate   = vehicleData.plate
	local isFound = false
	print(plate)
	print(tostring(vehicleData))
	FindPlayerVehicles(xPlayer.PlayerData.citizenid, function(vehicles)
		for k, v in pairs(vehicles) do
			if type(v.plate) ~= 'nil' and string.trim(plate) == string.trim(v.plate) then
				isFound = true
			end		
		end
		if isFound then
			exports['ghmattimysql']:execute("SELECT * FROM car_parking WHERE owner = '"..xPlayer.PlayerData.citizenid.."' AND plate = '"..plate.."'", function(rs)
				if type(rs) == 'table' and #rs > 0 and rs[1] ~= nil then
					
					local fee         = math.floor(((os.time() - rs[1].time) / 86400) * Config.ParkingLocations[rs[1].parking].fee)
					local playerMoney = xPlayer.PlayerData.money.cash
					local parkingCard = xPlayer.Functions.GetItemByName('id_card')
					if parkingCard.amount > 0 then
						fee = 0
					end
					if playerMoney >= fee then
						xPlayer.Functions.RemoveMoney("cash",fee)
						exports['ghmattimysql']:execute("DELETE FROM car_parking WHERE plate = '"..plate.."' AND owner = '"..xPlayer.PlayerData.citizenid.."'")
						exports['ghmattimysql']:execute("UPDATE player_vehicles SET state = 0 WHERE plate = '"..plate.."' AND citizenid = '"..xPlayer.PlayerData.citizenid.."'")
						cb({
							status  = true,
							message = string.format(_U("pay_success", fee)),
							vehData = rs[1].data,
							print(json.decode(rs[1].data))
							
						})
						TriggerClientEvent("esx_realparking:deleteVehicle", -1, {
							plate = plate
						})
					else
						cb({
							status  = false,
							message = _U("not_enough_money"),
						})
					end
				else
					cb({
						status  = false,
						message = _U("invalid_car"),
					})
				end
			end)
		else
			cb({
				status  = false,
				message = _U("not_your_car"),
			})
		end
	end)
end)

-- When the police impound the car, support for esx_policejob

RSCore.Functions.CreateCallback("esx_realparking:impoundVehicle", function(source, cb, vehicleData)
	local xPlayer = RSCore.Functions.GetPlayer(source)
    local plate   = vehicleData.plate
	exports['ghmattimysql']:execute("SELECT * FROM car_parking WHERE plate = '"..plate.."'", function(rs)
		if type(rs) == 'table' and #rs > 0 and rs[1] ~= nil then
			print("Police impound the vehicle: ", vehicleData.plate, rs[1].owner)
			exports['ghmattimysql']:execute("DELETE FROM car_parking WHERE plate = '"..plate.."' AND owner = '"..rs[1].owner.."'", {
				["@plate"]      = plate,
				["@identifier"] = rs[1].owner
			})
			exports['ghmattimysql']:execute("UPDATE player_vehicles SET state = 0 WHERE plate = '"..plate.."' AND citizenid = '"..rs[1].owner.."'")
			cb({
				status  = true,
			})
			TriggerClientEvent("esx_realparking:deleteVehicle", -1, {
				plate = plate
			})
		else
			cb({
				status  = false,
				message = _U("invalid_car"),
			})
		end
	end)
end)

-- Send the identifier to client

RSCore.Functions.CreateCallback("esx_realparking:getPlayerIdentifier", function(source, cb)
	local xPlayer  = RSCore.Functions.GetPlayer(source)
	local playerId = xPlayer.PlayerData.citizenid
	if type(playerId) ~= 'nil' then
		cb(playerId)
	else
		print("[RealParking][ERROR] Failed to get the player identifier!")
	end
end)

-- Refresh client local vehicles entity

function RefreshVehicles(xPlayer, src, parkingName)
	if src == nil then
		src = -1
	end
	local vehicles = {}
	local nameList = {}
	if Config.UsingOldESX then
		local nrs = exports['ghmattimysql']:execute("SELECT citizenid, name FROM players")
		if type(nrs) == 'table' then
			for k, v in pairs(nrs) do
				nameList[v.citizenid] = v.name
			end
		end
	end
	local querySQL = "SELECT * FROM car_parking"
	local queryArg = {}
	if parkingName ~= nil then
		querySQL = "SELECT * FROM car_parking WHERE parking = '"..parkingName.."'"
		queryArg = {
			['@parkingName'] = parkingName
		}
	end
	exports['ghmattimysql']:execute(querySQL, queryArg, function(rs) 
		for k, v in pairs(rs) do
			local vehicle = json.decode(v.data)
			local plate   = v.plate
			local fee     = math.floor(((os.time() - v.time) / 86400) * Config.ParkingLocations[v.parking].fee)
			if fee < 0 then
				fee = 0
			end
			table.insert(vehicles, {vehicle = vehicle, plate = plate, fee = fee, owner = v.owner, name = nameList[v.owner]})
		end
		TriggerClientEvent("esx_realparking:refreshVehicles", src, vehicles)
	end)
end

-- Get the number of the vehicles

function GetVehicleNumOfParking(name)
	local rs = exports['ghmattimysql']:execute("SELECT id FROM car_parking WHERE parking = '"..name.."'")
	if type(rs) == 'table' then
		return #rs
	else
		return 0
	end
end

-- Get all vehicles the player owned

function FindPlayerVehicles(id, cb)
	local vehicles = {}
	exports['ghmattimysql']:execute("SELECT * FROM player_vehicles WHERE citizenid = '"..id.."'", function(rs)
		for k, v in pairs(rs) do
			local vehicle = json.decode(v.vehicle)
			local plate = v.plate
			table.insert(vehicles, {vehicle = vehicle, plate = plate})
		end
		cb(vehicles)
	end)
end

-- Clear the text

string.trim = function(text)
	if text ~= nil then
		return text:match("^%s*(.-)%s*$")
	else
		return nil
	end
end
