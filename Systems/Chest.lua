-- Afuaru loot + opportunistic nearby chests. No far junk travel.

return function(GB)
	local M = {}

	local function chestPos(chest)
		return GB.Resolver.positionOf(chest)
	end

	function M.openOne(chest)
		if not chest then
			return false
		end
		if chest:GetAttribute("Opened") == true then
			return false
		end
		local root = GB.World.hrp()
		local pos = chestPos(chest)
		if not (root and pos) then
			return false
		end
		if (root.Position - pos).Magnitude > 80 then
			if not GB.PlayerData.live("The Hoarder") then
				return false
			end
		end
		if GB.World.interact then
			GB.World.interact(chest, 6)
		else
			GB.World.moveTo(chest, 6)
			local pr = GB.Resolver.prompt(chest)
			if pr then
				GB.World.firePrompt(pr)
			end
		end
		GB.Log.log("CHEST", "loot " .. chest.Name)
		return true
	end

	function M.openNearby()
		if not GB.Config.AutoChest then
			return false
		end
		local chest = GB.Resolver.chest()
		return M.openOne(chest)
	end

	function M.lootUntil(questName, amount)
		amount = amount or 5
		local t0 = os.clock()
		local hits = 0
		while os.clock() - t0 < 18 do
			if questName and GB.Quest then
				if GB.PlayerData.refreshLive then
					GB.PlayerData.refreshLive(false, "chest_probe")
				end
				if (GB.PlayerData.cycleFinished and GB.PlayerData.cycleFinished(questName, true))
					or ((not GB.PlayerData.cycleFinished) and GB.PlayerData.finished(questName, true))
				then
					return true
				end
				local qs = GB.Quest.questState(questName)
				if qs and (qs.IsComplete or qs.StageIndex and qs.Objective and qs.Objective.Type ~= "Loot") then
					return true
				end
				if qs and qs.Objective and (qs.Objective.Current or 0) >= amount then
					return true
				end
			end
			local list = GB.Resolver.chests and GB.Resolver.chests() or {}
			local chest = list[1] or GB.Resolver.chest()
			if not chest then
				task.wait(0.35)
			else
				if M.openOne(chest) then
					hits = hits + 1
					if GB.PlayerData and GB.PlayerData.forceQuestRefresh then
						GB.PlayerData.forceQuestRefresh("chest_loot")
					end
				end
				task.wait(0.4)
			end
			if hits >= amount then
				return true
			end
		end
		return hits > 0
	end

	function M.tick()
		if GB.PlayerData.live("The Hoarder") then
			local qs = GB.Quest and GB.Quest.questState("The Hoarder")
			if qs and qs.Objective and qs.Objective.Type == "Loot" then
				M.openNearby()
			end
		end
	end

	return M
end
