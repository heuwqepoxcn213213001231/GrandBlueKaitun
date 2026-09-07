-- AutoStats. VERIFIED: StatPoints:FireServer("Invest", statName, n)
-- Cost: 1 unused point per n (UI). Cap / grant curve UNKNOWN.
-- Profiles. Conservative default Balanced.

return function(GB)
	local M = {}

	local PROFILES = {
		Balanced = { Strength = 2, Health = 2, Agility = 1, Willpower = 1, Precision = 1, Energy = 1 },
		Strength = { Strength = 5, Health = 2, Willpower = 1 },
		Sword = { Strength = 3, Agility = 2, Health = 2, Precision = 1 },
		Gun = { Precision = 4, Agility = 2, Health = 1, Energy = 1 },
		Fruit = { Energy = 3, Willpower = 3, Health = 2, Strength = 1 },
		Hybrid = { Strength = 2, Energy = 2, Health = 2, Willpower = 1, Agility = 1 },
	}

	local ORDER = { "Strength", "Health", "Willpower", "Agility", "Precision", "Energy" }

	function M.unused()
		local s = GB.State.get()
		return tonumber(s.StatPoints) or 0
	end

	function M.investMinimum(n)
		n = n or 1
		if M.unused() < 1 then
			-- still fire 1 Strength if Basics is waiting; server no-ops if 0
			return GB.Remotes.statInvest("Strength", 1)
		end
		return GB.Remotes.statInvest("Strength", math.min(n, M.unused()))
	end

	function M.tick()
		if not GB.Config.AutoStats then
			return
		end
		local pts = M.unused()
		if pts < 1 then
			return
		end
		local prof = PROFILES[GB.Config.Build] or PROFILES.Balanced
		local spent = 0
		for _, stat in ipairs(ORDER) do
			local w = prof[stat]
			if w and pts > 0 then
				local n = math.min(w, pts)
				if GB.Remotes.statInvest(stat, n) then
					GB.Log.log("STAT", "Invest " .. stat .. " x" .. n)
					pts = pts - n
					spent = spent + n
				end
			end
		end
		if spent > 0 then
			task.wait(0.2)
			local before = GB.State.snap.StatPoints
			GB.PlayerData.refreshStats()
			GB.State.refresh()
			if GB.State.snap.StatPoints == before then
				GB.Log.warn("STAT", "invest fired, points unchanged")
			else
				GB.Recovery.markSuccess()
			end
		end
	end

	return M
end
