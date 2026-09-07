-- Rowboat purchase + spawn. Ships:FireServer("Purchase", {Type="Rowboat"})
-- Spawn: Ships:FireServer("Spawn", index) — index from owned list when available.

return function(GB)
	local M = {
		bought = false,
		spawned = false,
	}

	function M.buyRowboat()
		local gold = GB.State.get().Gold or 0
		if gold < 50 then
			GB.Log.log("TRAVEL", "Rowboat needs 50G")
			return false
		end
		local part = GB.Resolver.shopItem("Rowboat")
		if part then
			GB.World.moveTo(part, 12)
		end
		GB.Log.log("TRAVEL", "Ships Purchase Rowboat")
		M.bought = GB.Remotes.rowboatPurchase()
		return M.bought
	end

	function M.spawnRowboat()
		if not M.bought and not GB.PlayerData.hasItem("Rowboat") then
			M.buyRowboat()
			task.wait(0.4)
		end
		-- index UNKNOWN until GetShipInfo / viewer list; try 1 then 0
		GB.Log.log("TRAVEL", "Ships Spawn try 1")
		GB.Remotes.shipSpawn(1)
		M.spawned = true
		return true
	end

	function M.travelToward(island)
		M.spawnRowboat()
		local dest = GB.World.islandSpawn(island)
		if dest then
			return GB.World.moveTo(dest, 30)
		end
		return false
	end

	function M.tick()
		if not GB.Config.AutoBoat then
			return
		end
		if GB.PlayerData.live("Setting Sail") then
			if not GB.PlayerData.hasItem("Rowboat") then
				M.buyRowboat()
			else
				M.spawnRowboat()
			end
		end
	end

	return M
end
