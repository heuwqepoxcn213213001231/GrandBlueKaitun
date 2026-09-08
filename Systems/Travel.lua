-- World graph. Walk / boat / verified travel. No stale tele.

return function(GB)
	local M = {}

	function M.goIsland(name)
		local snap = GB.State.get()
		if snap.PhysicalIsland == name then
			return true
		end
		local dest = GB.World.islandSpawn(name)
		if dest and GB.World.posSane and GB.World.posSane(dest) then
			GB.Log.log("TRAVEL", "walk/hop " .. name)
			if GB.World.destOk(dest) then
				return GB.World.moveTo(dest, 20)
			end
			return GB.World.setPos(dest, { AllowFar = true })
		end
		if name == "Clown Town" and not GB.PlayerData.finished("Setting Sail", true) then
			return false
		end
		if name == "Maple Village" and not GB.PlayerData.finished("Journey to Maple Village", true) then
			if GB.PlayerData.live("Journey to Maple Village") then
				return GB.Boat.travelToward("Maple Village")
			end
			return false
		end
		if name ~= snap.CurrentIsland then
			GB.Log.log("TRAVEL", "need progress gate for " .. name)
		end
		return false
	end

	function M.tick()
		if not GB.Config.AutoTravel then
			return
		end
		local snap = GB.State.get()
		if snap.PhysicalIsland and snap.CurrentIsland and snap.PhysicalIsland ~= snap.CurrentIsland then
			M.goIsland(snap.CurrentIsland)
		end
	end

	return M
end
