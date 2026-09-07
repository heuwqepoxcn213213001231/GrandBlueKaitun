-- ClientCache + GetData + StatSystem. Live wins over persist.

return function(GB)
	local RS = game:GetService("ReplicatedStorage")
	local M = {
		_cache = nil,
		_stat = nil,
	}

	local function loadMods()
		if not M._cache then
			pcall(function()
				M._cache = require(RS.Modules.ClientCache)
			end)
		end
		if not M._stat then
			pcall(function()
				M._stat = require(RS.Modules.StatSystem)
			end)
		end
	end

	function M.raw()
		loadMods()
		return M._cache and M._cache.Data or {}
	end

	local function completedSet(done)
		local set = {}
		if type(done) ~= "table" then
			return set
		end
		if done[1] ~= nil then
			for _, v in ipairs(done) do
				if type(v) == "string" then
					set[v] = true
				elseif type(v) == "table" and v.Name then
					set[v.Name] = true
				end
			end
			return set
		end
		for k, v in pairs(done) do
			if v == true then
				set[k] = true
			elseif type(v) == "string" then
				set[v] = true
				set[k] = true
			elseif type(v) == "table" then
				set[v.Name or k] = true
			end
		end
		return set
	end

	function M.cache()
		loadMods()
		local d = M._cache and M._cache.Data or {}
		local out = {}
		for k, v in pairs(d) do
			out[k] = v
		end
		out.Level = tonumber(d.Level) or tonumber(d.level) or 0
		if out.Level <= 0 and d.Stats then
			out.Level = tonumber(d.Stats.Level) or 0
		end
		local lp = GB.lp
		local char = lp and lp.Character
		if out.Level <= 0 and char then
			out.Level = tonumber(char:GetAttribute("Level")) or 0
			if out.Level <= 0 and M._stat then
				local ok, n = pcall(M._stat.GetValue, char, "Level")
				if ok and type(n) == "number" then
					out.Level = n
				end
			end
		end
		out.EXP = tonumber(d.EXP) or tonumber(d.Exp) or 0
		out.Gold = tonumber(d.Gold) or 0
		out.StatPoints = tonumber(d.StatPoints) or tonumber(d["Stat Points"]) or tonumber(d.UnusedStatPoints) or 0
		out.Stats = {}
		if char and M._stat then
			for _, n in ipairs({ "Health", "Strength", "Agility", "Precision", "Energy", "Willpower" }) do
				local ok, v = pcall(M._stat.GetBaseValue, char, n)
				out.Stats[n] = (ok and type(v) == "number") and v or 0
			end
		end
		out.CompletedSet = completedSet(d["Completed Quests"] or d.CompletedQuests)
		out.Quests = d.Quests or {}
		out.Inventory = d.Inventory or {}
		out.Fruit = d.Fruit
		out["Fruit Storage"] = d["Fruit Storage"]
		out["Permanent Fruits"] = d["Permanent Fruits"]
		out.CurrentQuest = nil
		local liveBest
		for k, q in pairs(out.Quests) do
			if type(q) == "table" then
				local name = q.Name or k
				if not liveBest then
					liveBest = name
				end
			end
		end
		out.CurrentQuest = liveBest
		return out
	end

	function M.finished(name)
		return M.cache().CompletedSet[name] == true
	end

	function M.live(name)
		local q = M.cache().Quests
		if type(q) ~= "table" then
			return nil
		end
		if q[name] then
			return q[name]
		end
		for k, v in pairs(q) do
			if type(v) == "table" and (v.Name == name or k == name) then
				return v
			end
		end
		return nil
	end

	function M.hasItem(name)
		local inv = M.cache().Inventory
		if type(inv) ~= "table" then
			return false, 0
		end
		if inv[name] then
			local row = inv[name]
			if type(row) == "table" then
				return true, tonumber(row.Amount) or 1
			end
			return true, 1
		end
		for _, v in pairs(inv) do
			if type(v) == "table" and (v.Name == name or v.Key == name) then
				return true, tonumber(v.Amount) or 1
			end
		end
		return false, 0
	end

	function M.refreshStats()
		GB.Remotes.statReplicate()
		local st = GB.Remotes.getStats()
		return st
	end

	return M
end
