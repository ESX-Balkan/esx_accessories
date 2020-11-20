local HasAlreadyEnteredMarker, isDead, CurrentActionData, ESX = false, false, {}, nil
local LastZone, CurrentAction, CurrentActionMsg
CreateThread(function()
	while ESX == nil do TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end) Wait(0) end
end)

function OpenAccessoryMenu()
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'set_unset_accessory', {
		title = _U('set_unset'),
		align = 'top-left',
		elements = {{label = _U('helmet'), value = 'Helmet'},{label = _U('ears'), value = 'Ears'},{label = _U('mask'), value = 'Mask'},{label = _U('glasses'), value = 'Glasses'}}}, 
		function(data, menu)
		menu.close()
		SetUnsetAccessory(data.current.value)
	end, function(data, menu)
		menu.close()
	end)
end
function SetUnsetAccessory(accessory)
	ESX.TriggerServerCallback('esx_accessories:get', function(hasAccessory, accessorySkin)
		local _accessory = string.lower(accessory)
		if hasAccessory then
			TriggerEvent('skinchanger:getSkin', function(skin)
				local mAccessory, mColor = -1, 0
				if _accessory == "mask" then
					mAccessory = 0
				end
				if skin[_accessory .. '_1'] == mAccessory then
					mAccessory = accessorySkin[_accessory .. '_1']
					mColor = accessorySkin[_accessory .. '_2']
				end
				local accessorySkin = {}
				accessorySkin[_accessory .. '_1'] = mAccessory
				accessorySkin[_accessory .. '_2'] = mColor
				TriggerEvent('skinchanger:loadClothes', skin, accessorySkin)
			end)
		else
			ESX.ShowNotification(_U('no_' .. _accessory))
		end
	end, accessory)
end

function OpenShopMenu(accessory)
	local _accessory = string.lower(accessory)
	local restrict = {}
	restrict = { _accessory .. '_1', _accessory .. '_2' }
	TriggerEvent('esx_skin:openRestrictedMenu', function(data, menu)
		menu.close()
		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'shop_confirm', {
			title = _U('valid_purchase'),
			align = 'top-left',
			elements = {
				{label = _U('no'), value = 'no'},
				{label = _U('yes', ESX.Math.GroupDigits(Config.Price)), value = 'yes'}
			}}, function(data, menu)
			menu.close()
			if data.current.value == 'yes' then
				ESX.TriggerServerCallback('esx_accessories:checkMoney', function(hasEnoughMoney)
					if hasEnoughMoney then
						TriggerServerEvent('esx_accessories:pay')
						TriggerEvent('skinchanger:getSkin', function(skin)
							TriggerServerEvent('esx_accessories:save', skin, accessory)
						end)
					else
						TriggerEvent('esx_skin:getLastSkin', function(skin)
							TriggerEvent('skinchanger:loadSkin', skin)
						end)
						ESX.ShowNotification(_U('not_enough_money'))
					end
				end)
			end
			if data.current.value == 'no' then
				local player = PlayerPedId()
				TriggerEvent('esx_skin:getLastSkin', function(skin)
					TriggerEvent('skinchanger:loadSkin', skin)
				end)
				if accessory == "Ears" then
					ClearPedProp(player, 2)
				elseif accessory == "Mask" then
					SetPedComponentVariation(player, 1, 0 ,0, 2)
				elseif accessory == "Helmet" then
					ClearPedProp(player, 0)
				elseif accessory == "Glasses" then
					SetPedPropIndex(player, 1, -1, 0, 0)
				end
			end
			CurrentAction = 'shop_menu'
			CurrentActionMsg  = _U('press_access')
			CurrentActionData = {}
		end, function(data, menu)
			menu.close()
			CurrentAction = 'shop_menu'
			CurrentActionMsg = _U('press_access')
			CurrentActionData = {}
		end)
	end, function(data, menu)
		menu.close()
		CurrentAction  = 'shop_menu'
		CurrentActionMsg = _U('press_access')
		CurrentActionData = {}
	end, restrict)
end
AddEventHandler('esx:onPlayerSpawn', function() isDead = false end)
AddEventHandler('esx:onPlayerDeath', function() isDead = true end)
AddEventHandler('esx_accessories:hasEnteredMarker', function(zone)
	CurrentAction = 'shop_menu'
	CurrentActionMsg  = _U('press_access')
	CurrentActionData = { accessory = zone }
end)
AddEventHandler('esx_accessories:hasExitedMarker', function(zone)
	ESX.UI.Menu.CloseAll()
	CurrentAction = nil
end)
-- Napravi blipove --
CreateThread(function()
	for k,v in pairs(Config.ShopsBlips) do
		if v.Pos ~= nil then
			for i=1, #v.Pos, 1 do
				local blip = AddBlipForCoord(v.Pos[i])
				SetBlipSprite(blip, v.Blip.sprite)
				SetBlipDisplay(blip, 4)
				SetBlipScale(blip, 1.0)
				SetBlipColour(blip, v.Blip.color)
				SetBlipAsShortRange(blip, true)
				BeginTextCommandSetBlipName('STRING')
				AddTextComponentString(_U('shop', _U(string.lower(k))))
				EndTextCommandSetBlipName(blip)
			end
		end
	end
end)
-- Pokazi markere
CreateThread(function()
	local igrac = PlayerPedId()
	while true do
		Wait(6)
		local playerCoords, isInMarker, currentZone, letSleep = GetEntityCoords(igrac), nil, nil, true
		for k,v in pairs(Config.Zones) do
			for i = 1, #v.Pos, 1 do
				local distance = #(playerCoords - (v.Pos[i]) )
				if distance < Config.DrawDistance then
					letSleep = false
					DrawMarker(Config.Type, v.Pos[i].x, v.Pos[i].y, v.Pos[i].z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, Config.Size.x, Config.Size.y, Config.Size.z, Config.Color.r, Config.Color.g, Config.Color.b, 100, false, true, 2, false, false, false, false)
					if distance < 1.5 then
						isInMarker, currentZone = true, k
					end
				end
			end
		end
		if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
			HasAlreadyEnteredMarker = true
			LastZone = currentZone
			TriggerEvent('esx_accessories:hasEnteredMarker', currentZone)
		end
		if not isInMarker and HasAlreadyEnteredMarker then
			HasAlreadyEnteredMarker = false
			TriggerEvent('esx_accessories:hasExitedMarker', LastZone)
		end
		if letSleep then Wait(1000) end
	end
end)
-- Kontrole
CreateThread(function()
	while true do
		Wait(5)
		if CurrentAction then
			ESX.ShowHelpNotification(CurrentActionMsg)
			if IsControlJustReleased(0, 38) and CurrentActionData.accessory then
				OpenShopMenu(CurrentActionData.accessory)
				CurrentAction = nil
			end
		elseif CurrentAction and not Config.EnableControls then
			Citizen.Wait(500)
		end
		if Config.EnableControls then
			if IsControlJustReleased(0, 311) and IsInputDisabled(0) and not isDead then
				OpenAccessoryMenu()
			end
		end
	end
end)
