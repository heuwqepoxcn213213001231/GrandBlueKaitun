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

	local function guiUnused()
		if M._guiN and os.clock() - (M._guiAt or 0) < 0.45 then
			return M._guiN
		end
		local n
		pcall(function()
			local lp = GB.lp
			local pg = lp and lp.PlayerGui
			if not pg then
				return
			end
			local menu = pg:FindFirstChild("Menu")
			local radar = menu and menu:FindFirstChild("Radar", true)
			local st = radar and radar:FindFirstChild("StatpointText", true)
			if GB.State and GB.State.guiNum then
				n = GB.State.guiNum(st)
			end
			if not n or n < 1 then
				for _, d in ipairs(pg:GetDescendants()) do
					if (d:IsA("TextLabel") or d:IsA("TextButton")) and type(d.Text) == "string" then
						local v = d.Text:match("Stat Points:%s*(%d+)")
						if v then
							n = tonumber(v)
							break
						end
					end
				end
			end
		end)
		M._guiAt = os.clock()
		M._guiN = tonumber(n)
		return M._guiN
	end

	function M.unused()
		local best = 0
		if GB.PlayerData and GB.PlayerData.unusedStatPoints then
			local n = GB.PlayerData.unusedStatPoints()
			if type(n) == "number" and n > best then
				best = n
			end
		end
		local g = guiUnused()
		if type(g) == "number" and g > best then
			best = g
		end
		local s = GB.State.get()
		local c = tonumber(s and s.StatPoints)
		if type(c) == "number" and c > best then
			best = c
		end
		return best
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
			if not M._zeroAt or os.clock() - M._zeroAt > 12 then
				M._zeroAt = os.clock()
				GB.Log.log("STAT", "unused=0 (no invest)")
			end
			return
		end
		if not M._usedAt or os.clock() - M._usedAt > 8 then
			M._usedAt = os.clock()
			GB.Log.log("STAT", "unused=" .. tostring(pts))
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
