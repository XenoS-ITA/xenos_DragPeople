local dragging_data = {
	InProgress = false,
	target = -1,
	Anim = {
		dict = "combat@drag_ped@",
		start = "injured_pickup_back_",
		loop = "injured_drag_",
		ending = "injured_putdown_"
	}
}

-- dragging start anim: combat@drag_ped@ / injured_pickup_back_plyr
-- dragging during anim: combat@drag_ped@ / injured_drag_plyr
-- dragging ending anim: combat@drag_ped@ / injured_putdown_plyr

-- dragged start anim: combat@drag_ped@ / injured_pickup_back_ped
-- dragged during anim: combat@drag_ped@ / injured_drag_ped
-- dragged ending anim: combat@drag_ped@ / injured_putdown_ped

--// Function 
local function HelpNotification(text)
    SetTextComponentFormat("STRING")
    AddTextComponentString(text)
    DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

local function Notification(text)
	AddTextEntry('notify', text)
    SetNotificationTextEntry('notify')
    DrawNotification(false, true)
end

local function GetClosestPlayer(radius)
    local players = GetActivePlayers()
    local closestDistance = -1
    local closestPlayer = -1
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    for _,playerId in ipairs(players) do
        local targetPed = GetPlayerPed(playerId)
        if targetPed ~= playerPed then
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(targetCoords-playerCoords)
            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = playerId
                closestDistance = distance
            end
        end
    end
	if closestDistance ~= -1 and closestDistance <= radius then
		return closestPlayer
	else
		return nil
	end
end

local function LoadAnimDict(animDict)
    if not HasAnimDictLoaded(animDict) then
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(0)
        end        
    end
    return animDict
end

--// Override TaskPlayAnim to unload the animation after whe have use it
local old_TaskPlayAnim
function TaskPlayAnim(ped, animDictionary, animationName, blendInSpeed, blendOutSpeed, duration , flag, playbackRate, lockX, lockY, lockZ)
	old_TaskPlayAnim(ped, animDictionary, animationName, blendInSpeed, blendOutSpeed, duration , flag, playbackRate, lockX, lockY, lockZ)
	RemoveAnimDict(animDictionary)
	return
end

function PlayAnim(type, desinence)
	--// Desinence //--

	-- plyr = player that dragging 
	-- ped  = player that been dragged

	local duration = nil
	if type == "loop" then duration = -1 elseif type == "start" then duration = 6000 elseif type == "ending" then duration = 5000 end

	LoadAnimDict(dragging_data.Anim.dict)
	TaskPlayAnim(PlayerPedId(), dragging_data.Anim.dict, dragging_data.Anim[type]..desinence, 8.0, -8.0, duration, 33, 0, 0, 0, 0)

	if duration ~= -1 then
		Wait(duration)
		ClearPedTasks(PlayerPedId())
	end
end

function WaitControlsInteractions()
	Citizen.CreateThread(function()
		while true do
			HelpNotification("~INPUT_VEH_DUCK~ to drop the body")
			if IsControlJustPressed(0, 77) then -- X
				DragClosest()
				return
			end
			Wait(5)
		end
	end)
end	

FreezeEntityPosition(PlayerPedId(), false)
SetEntityCollision(PlayerPedId(), true, true)
ClearPedTasks(PlayerPedId())
DetachEntity(PlayerPedId(), true, false)

RegisterCommand("drag", function()
	DragClosest()
end)

function DragClosest()
	local player = PlayerPedId()

	if not dragging_data.InProgress then --// Dont have any drag animation started
		local closestPlayer = GetClosestPlayer(1)
		if closestPlayer and GetEntityHealth(closestPlayer) == 0 then
			local target = GetPlayerServerId(closestPlayer)
			if target ~= -1 then
				dragging_data.InProgress = true
				dragging_data.target = target

				--// Play anim [start]
				TriggerServerEvent("xenos_DragPeople:sync",target) --// Request to the other client (the closest player) to sync the animation with that client
				PlayAnim("start", "plyr")
				PlayAnim("loop", "plyr")
				WaitControlsInteractions()
			else
				Notification("~r~No one nearby to drag!")
			end
		else
			Notification("~r~No one nearby to drag!")
		end
	else --// Have a drag animation started
		local target_ped = GetPlayerPed(GetPlayerFromServerId(dragging_data.target))

		TriggerServerEvent("xenos_DragPeople:stop",dragging_data.target) --// Request to the other client (the closest player) to stop the animation with that client
		
		DetachEntity(PlayerPedId(), true, false)
		PlayAnim("ending", "plyr")
		ClearPedTasks(target_ped) --// Added this to prevent multiple ending animation

		-- Reset all data
		dragging_data.InProgress = false
		dragging_data.target = 0
	end
end

--// This is the trigger that get the call from the other client to sync the animation
RegisterNetEvent("xenos_DragPeople:syncTarget")
AddEventHandler("xenos_DragPeople:syncTarget", function(target)
	local target_ped = GetPlayerPed(GetPlayerFromServerId(target))
	local player 	 = PlayerPedId()

	dragging_data.InProgress = true

	SetEntityCoords(player, GetOffsetFromEntityInWorldCoords(target_ped, 0.0, 1.4, -1.0)) --// Set the player in front of the other
	SetEntityHeading(player, GetEntityHeading(target_ped)) --// Set same heading
	PlayAnim("start", "ped")
	ClearPedTasks(player) --// Added this to prevent multiple ending animation

	--                                       Bone		   X    Y    Z    rX   rY   rZ
	AttachEntityToEntity(player, target_ped, 1816, 4103, 0.48, 0.0, 0.0, 0.0, 0.0, 0.0)
	PlayAnim("loop", "ped")
end)

--// Trigger that get call from the other client to stop the animation
RegisterNetEvent("xenos_DragPeople:cl_stop")
AddEventHandler("xenos_DragPeople:cl_stop", function(_target)
	_target = GetPlayerPed(GetPlayerFromServerId(_target))
	dragging_data.InProgress = false

	DetachEntity(PlayerPedId(), true, false)
	SetEntityCoords(PlayerPedId(), GetOffsetFromEntityInWorldCoords(_target, 0.0, 0.4, -1.0))
	PlayAnim("ending", "ped")
end)