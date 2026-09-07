-- AutoStats. VERIFIED: StatPoints:FireServer("Invest", statName, n)
-- Default 8 Strength : 2 Health on current totals, not a dump of unused points.

return function(GB)
	local M = {}

	local PROFILES = {
		Melee = { Strength = 8, Health = 2 },
		Balanced = { Strength = 8, Health = 2 },
		Strength = { Strength = 8, Health = 2 },
		Sword = { Strength = 3, Agility = 2, Health = 2, Precision = 1 },
		Gun = { Precision = 4, Agility = 2, Health = 1, Energy = 1 },
		Fruit = { Energy = 3, Willpower = 3, Health = 2, Strength = 1 },
		Hybrid = { Strength = 2, Energy = 2, Health = 2, Willpower = 1, Agility = 1 },
	}

	local ORDER = { "Strength", "Health", "Willpower", "Agility", "Precision", "Energy" }

	local function live()
		local s = GB.State.get()
		local st = (s and s.Stats) or {}
		local out = {}
		for _, name in ipairs(ORDER) do
			out[name] = tonumber(st[name]) or 0
		end
		return out
	end

	local function profile()
		local r = GB.Config and GB.Config.StatRatio
		if type(r) == "table" then
			local any = false
			for _, w in pairs(r) do
				if tonumber(w) and tonumber(w) > 0 then
					any = true
					break
				end
			end
			if any then
				return r
			end
		end
		return PROFILES[GB.Config and GB.Config.Build] or PROFILES.Melee
	end

	-- Lowest current/weight. Tie → ORDER (Strength before Health).
	local function pick(cur, prof)
		local bestName, bestScore = nil, math.huge
		for _, name in ipairs(ORDER) do
			local w = tonumber(prof[name])
			if w and w > 0 then
				local score = (tonumber(cur[name]) or 0) / w
				if score < bestScore - 1e-9 then
					bestScore = score
					bestName = name
				end
			end
		end
		return bestName
	end

	local function plan(cur, prof, pts)
		local alloc = {}
		local sim = {}
		for _, name in ipairs(ORDER) do
			sim[name] = tonumber(cur[name]) or 0
		end
		for _ = 1, pts do
			local name = pick(sim, prof)
			if not name then
				break
			end
			alloc[name] = (alloc[name] or 0) + 1
			sim[name] = sim[name] + 1
		end
		return alloc
	end

	function M.unused()
		local s = GB.State.get()
		return tonumber(s.StatPoints) or 0
	end

	function M.investMinimum(n)
		n = math.max(1, math.floor(tonumber(n) or 1))
		local pts = M.unused()
		local cur = live()
		local prof = profile()
		local name = pick(cur, prof) or "Strength"
		local amt = pts >= 1 and math.min(n, pts) or 1
		return GB.Remotes.statInvest(name, amt)
	end

	function M.tick()
		if not GB.Config.AutoStats then
			return
		end
		local pts = M.unused()
		if pts < 1 then
			return
		end
		local cur = live()
		local prof = profile()
		local alloc = plan(cur, prof, pts)
		local name, n = nil, 0
		for _, stat in ipairs(ORDER) do
			local a = alloc[stat] or 0
			if a > n then
				name, n = stat, a
			end
		end
		if not name or n < 1 then
			return
		end
		if not GB.Remotes.statInvest(name, n) then
			return
		end
		local after = (cur[name] or 0) + n
		local sw = tonumber(prof.Strength) or 8
		local hw = tonumber(prof.Health) or 2
		GB.Log.log(
			"STAT",
			string.format(
				"Invest %s x%d now Str=%d Hp=%d target %d:%d",
				name,
				n,
				name == "Strength" and after or (cur.Strength or 0),
				name == "Health" and after or (cur.Health or 0),
				sw,
				hw
			)
		)
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

	return M
end
