local dragging = {}
local dragged = {}

RegisterServerEvent("xenos_DragPeople:sync")
AddEventHandler("xenos_DragPeople:sync", function(targetSrc)
	local sourceEntity = GetPlayerPed(source)
	local targetEntity = GetPlayerPed(targetSrc)
	local distanceBetweenPlayers =  #(GetEntityCoords(sourceEntity) - GetEntityCoords(targetEntity))
	if targetSrc > 0 and distanceBetweenPlayers < 20.0 then
        if Config.ReloadDeath then
            TriggerClientEvent("reload_death:stopAnim", targetSrc)
        end
        TriggerClientEvent("xenos_DragPeople:syncTarget", targetSrc, source)
        dragging[source] = targetSrc
        dragged[targetSrc] = source
    end
end)

RegisterServerEvent("xenos_DragPeople:stop")
AddEventHandler("xenos_DragPeople:stop", function(targetSrc)
	local source = source

	if dragging[source] then
	    TriggerClientEvent("xenos_DragPeople:cl_stop", targetSrc, source)

	    if Config.ReloadDeath then
	    Citizen.Wait(5100)
			TriggerClientEvent("reload_death:startAnim", targetSrc)
		end
		dragging[source] = nil
		dragged[targetSrc] = nil
	end
end)

AddEventHandler('playerDropped', function(reason)
	local source = source
	dragging[source] = nil
	dragged[source]  = nil
end)
