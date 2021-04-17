local dragging = {}
local dragged = {}

RegisterServerEvent("xenos_DragPeople:sync")
AddEventHandler("xenos_DragPeople:sync", function(targetSrc)
	TriggerClientEvent("xenos_DragPeople:syncTarget", targetSrc, source)
	dragging[source] = targetSrc
	dragged[targetSrc] = source
end)

RegisterServerEvent("xenos_DragPeople:stop")
AddEventHandler("xenos_DragPeople:stop", function(targetSrc)
	local source = source

	if dragging[source] then
		TriggerClientEvent("xenos_DragPeople:cl_stop", targetSrc, source)
		dragging[source] = nil
		dragged[targetSrc] = nil
	end
end)

AddEventHandler('playerDropped', function(reason)
	local source = source
	dragging[source] = nil
	dragged[source]  = nil
end)