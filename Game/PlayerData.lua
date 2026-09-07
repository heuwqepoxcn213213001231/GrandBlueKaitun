-- Live quest truth: GetData("Quests","Completed Quests") + PlayerGui.Quests tracker.
-- ClientCache.Quests is a boot snapshot. QuestBegan/QuestDeleted/QuestStageUpdated are empty.

return function(GB)
	local RS = game:GetService("ReplicatedStorage")
	local M = {
		_cache = nil,
		_stat = nil,
		_live = {},
		_order = {},
		_done = {},
		_at = 0,
		_tracker = nil,
		_trackerAt = 0,
		_trackerCache = nil,
		_current = nil,
		_hooked = false,
		_questDirty = true,
		_questDirtyAt = 0,
		_unusedPts = nil,
		_unusedPtsAt = 0,
		_liveStats = nil,
		_statsSource = nil,
		_statsAt = 0,
		_lastQuestFetchAt = 0,
	}

	local LIVE_SAFETY_TTL = 5.4
	local TRACKER_TTL = 0.75
	local UNUSED_TTL = 2.8
	local STAT_NAMES = { "Health", "Strength", "Agility", "Precision", "Energy", "Willpower", "Level" }

	local function pbegin()
		return GB.Profiler and GB.Profiler.begin and GB.Profiler.begin() or nil
	end

	local function pdone(name, t0)
		if t0 and GB.Profiler and GB.Profiler.done then
			GB.Profiler.done(name, t0)
		end
	end

	local function perfCount(name, n)
		if GB.Profiler and GB.Profiler.count then
			GB.Profiler.count(name, n or 1)
		end
	end

	local STAGE_HINT = {
		["Equip your new skill"] = "Basics",
		["Equip Skill: Strong Punch"] = "Basics",
		["Cast the skill"] = "Basics",
		["Use Skill: Strong Punch"] = "Basics",
		["Invest your stat"] = "Basics",
		["Invest Stat Points"] = "Basics",
		["Open the logbook"] = "Basics",
		["Open your logbook"] = "Basics",
		["Select the 'Strong Punch'"] = "Basics",
		["Select the \"Strong Punch\""] = "Basics",
		["Walk up to a dummy"] = "Introduction",
		["Press Q to perform a dash"] = "Introduction",
		["Hold F to perform a block"] = "Introduction",
		["Talk to Officer Graves to get started"] = "Introduction",
	}

	local function loadMods()
		if not M._cache then
			M._cache = require(RS.Modules.ClientCache)
		end
		if not M._stat then
			M._stat = require(RS.Modules.StatSystem)
		end
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

	local function questActive(q)
		if type(q) ~= "table" then
			return false
		end
		if q.Complete == true or q.State == "Complete" then
			return false
		end
		local stages = q.Stages
		if type(stages) ~= "table" then
			return true
		end
		for _, st in ipairs(stages) do
			if type(st) == "table" and not st.Complete then
				local conds = st.Conditions or st.conditions
				if type(conds) ~= "table" or #conds == 0 then
					return true
				end
				for _, cond in ipairs(conds) do
					if type(cond) == "table" then
						if not GB.QuestData then
							return true
						end
						if not GB.QuestData.conditionComplete(cond) then
							return true
						end
					end
				end
			end
		end
		return false
	end

	local function hintQuest(text)
		if type(text) ~= "string" or text == "" then
			return nil
		end
		for needle, name in pairs(STAGE_HINT) do
			if string.find(text, needle, 1, true) then
				return name
			end
		end
		if GB.QuestData then
			for _, ch in ipairs(GB.QuestData.CHAINS) do
				for _, name in ipairs(ch.order) do
					if text == name or string.find(text, name, 1, true) then
						return name
					end
				end
			end
			for _, e in ipairs(GB.QuestData.REPEATS) do
				if text == e.name then
					return e.name
				end
			end
		end
		return nil
	end

	local function readTracker()
		local now = os.clock()
		if M._trackerCache and now - (M._trackerAt or 0) < TRACKER_TTL then
			return M._trackerCache
		end
		local lp = GB.lp
		local pg = lp and lp.PlayerGui
		if not pg then
			M._trackerCache = nil
			M._trackerAt = now
			return nil
		end
		local gui = pg:FindFirstChild("Quests")
		if not gui then
			M._trackerCache = nil
			M._trackerAt = now
			return nil
		end
		local det = gui:FindFirstChild("QuestDetails")
		if det then
			local attr = det:GetAttribute("QuestName")
			if type(attr) == "string" and attr ~= "" then
				M._trackerCache = attr
				M._trackerAt = now
				return attr
			end
			local qn = det:FindFirstChild("QuestName")
			local t = qn and GB.State and GB.State.guiText(qn)
			local hinted = hintQuest(t)
			if hinted then
				M._trackerCache = hinted
				M._trackerAt = now
				return hinted
			end
		end
		local qf = gui:FindFirstChild("Quest")
		local sf = qf and qf:FindFirstChild("ScrollingFrame")
		if not sf then
			M._trackerCache = nil
			M._trackerAt = now
			return nil
		end
		local function scanNode(root, depth, budget)
			if not (root and budget > 0 and depth >= 0) then
				return nil, budget
			end
			for _, d in ipairs(root:GetChildren()) do
				if budget <= 0 then
					break
				end
				local attr = d:GetAttribute("QuestName") or d:GetAttribute("QuestId")
				if type(attr) == "string" and attr ~= "" and hintQuest(attr) then
					return hintQuest(attr) or attr, budget
				end
				if d:IsA("TextLabel") or d:IsA("TextButton") then
					local hinted = hintQuest(d.Text)
					if hinted then
						return hinted, budget
					end
				end
				if depth > 0 then
					local hit
					hit, budget = scanNode(d, depth - 1, budget - 1)
					if hit then
						return hit, budget
					end
				end
			end
			return nil, budget
		end
		local hit = select(1, scanNode(sf, 3, 70))
		if hit then
			M._trackerCache = hit
			M._trackerAt = now
			return hit
		end
		local overlay = pg:FindFirstChild("ScreenShadow") or pg:FindFirstChild("Tutorial")
		if overlay then
			local ov = select(1, scanNode(overlay, 2, 40))
			if ov then
				M._trackerCache = ov
				M._trackerAt = now
				return ov
			end
			for _, d in ipairs(overlay:GetChildren()) do
				if d:IsA("TextLabel") or d:IsA("TextButton") then
					local hinted = hintQuest(d.Text)
					if hinted then
						M._trackerCache = hinted
						M._trackerAt = now
						return hinted
					end
				end
			end
		end
		M._trackerCache = nil
		M._trackerAt = now
		return nil
	end

	local function ingestList(list)
		local live, order = {}, {}
		if type(list) ~= "table" then
			return live, order
		end
		local function add(name, q)
			if type(name) ~= "string" or name == "" then
				return
			end
			if M._done[name] and not (GB.QuestData and GB.QuestData.isRepeatable and GB.QuestData.isRepeatable(name)) then
				return
			end
			if not questActive(q) then
				return
			end
			if not live[name] then
				live[name] = q
				order[#order + 1] = name
			end
		end
		if list[1] ~= nil then
			for _, q in ipairs(list) do
				if type(q) == "table" then
					add(q.Name or q.name, q)
				end
			end
			return live, order
		end
		for k, q in pairs(list) do
			if type(q) == "table" then
				add(q.Name or k, q)
			end
		end
		return live, order
	end

	local function pickCurrent()
		local tr = M._tracker
		if tr and M._live[tr] then
			return tr
		end
		if tr and not M._done[tr] then
			return tr
		end
		if GB.QuestData then
			for _, ch in ipairs(GB.QuestData.CHAINS) do
				for _, name in ipairs(ch.order) do
					if M._live[name] then
						return name
					end
				end
			end
			local best, bestExp
			for _, e in ipairs(GB.QuestData.REPEATS) do
				if M._live[e.name] and (not best or e.exp > bestExp) then
					best, bestExp = e.name, e.exp
				end
			end
			if best then
				return best
			end
		end
		local ck = GB.Persist and GB.Persist.data and GB.Persist.data.checkpoint
		if ck and type(ck.quest) == "string" and M._live[ck.quest] then
			return ck.quest
		end
		return M._order[1]
	end

	local function markQuestDirty(why)
		M._questDirty = true
		M._questDirtyAt = os.clock()
		M._at = 0
		if why and (not M._dirtyLogAt or os.clock() - M._dirtyLogAt > 1.5) then
			M._dirtyLogAt = os.clock()
			GB.Log.log("STATE", "quest dirty " .. tostring(why))
		end
	end

	function M.invalidateLive(why)
		markQuestDirty(why or "invalidate")
	end

	function M.questDirty()
		return M._questDirty == true
	end

	function M.forceQuestRefresh(why)
		markQuestDirty(why or "force")
		return M.refreshLive(true, why or "force")
	end

	function M.refreshLive(force, why)
		local t0 = pbegin()
		loadMods()
		local now = os.clock()
		M._tracker = readTracker()
		local stale = now - (M._lastQuestFetchAt or 0) >= LIVE_SAFETY_TTL
		if not force and not M._questDirty and not stale and (next(M._live) or M._tracker or M._current) then
			M._current = pickCurrent()
			pdone("PlayerData.refreshLive", t0)
			return M._live
		end
		perfCount("PlayerDataRefresh", 1)
		local quests, done = GB.Remotes.getQuests()
		if quests == nil and done == nil then
			local snap = M._cache and M._cache.Data
			if snap then
				quests = snap.Quests
				done = snap["Completed Quests"] or snap.CompletedQuests
			end
		end
		if quests ~= nil or done ~= nil then
			M._done = completedSet(done)
			M._live, M._order = ingestList(quests)
			M._at = now
			M._lastQuestFetchAt = now
			M._questDirty = false
			M._tracker = readTracker() or M._tracker
			local prev = M._current
			M._current = pickCurrent()
			if M._current and M._current ~= prev then
				GB.Log.log("STATE", "live quest " .. M._current)
				if GB.Combat and GB.Combat.stopLock then
					GB.Combat.stopLock()
				end
				if GB.Persist and GB.Persist.checkpoint then
					GB.Persist.checkpoint("quest", M._current)
				end
			end
		elseif force or stale then
			-- Keep dirty=true so next safety poll/event will retry.
			M._questDirty = true
			if why and os.clock() - (M._refreshWarnAt or 0) > 6 then
				M._refreshWarnAt = os.clock()
				GB.Log.warn("STATE", "quest refresh miss " .. tostring(why))
			end
		end
		pdone("PlayerData.refreshLive", t0)
		return M._live
	end

	function M.hookQuestEvents()
		if M._hooked then
			return
		end
		M._hooked = true
		local ev = RS:FindFirstChild("Events")
		if not ev then
			return
		end
		local function bump(why)
			markQuestDirty(why)
			M._trackerAt = 0
			M._trackerCache = nil
			if GB.State and GB.State.track then
				GB.State.track.StateChange = os.clock()
			end
		end
		local beginQ = ev:FindFirstChild("BeginQuest")
		if beginQ then
			GB.conns[#GB.conns + 1] = beginQ.OnClientEvent:Connect(function(q)
				local name = type(q) == "table" and q.Name or q
				bump("BeginQuest " .. tostring(name))
				if type(q) == "table" and q.Name then
					M._done[q.Name] = nil
					M._live[q.Name] = q
					M._order[#M._order + 1] = q.Name
					M._current = q.Name
				end
				if GB.Stats and GB.Stats.markDirty then
					GB.Stats.markDirty("quest_begin")
				end
			end)
		end
		local clearQ = ev:FindFirstChild("ClearQuest")
		if clearQ then
			GB.conns[#GB.conns + 1] = clearQ.OnClientEvent:Connect(function(name)
				bump("ClearQuest " .. tostring(name))
				if type(name) == "string" then
					M._live[name] = nil
					M._done[name] = true
					if M._current == name then
						M._current = nil
					end
				end
				if GB.Stats and GB.Stats.markDirty then
					GB.Stats.markDirty("quest_clear")
				end
			end)
		end
		local prog = ev:FindFirstChild("QuestProgress")
		if prog then
			GB.conns[#GB.conns + 1] = prog.OnClientEvent:Connect(function()
				bump("QuestProgress")
			end)
		end
		local upd = ev:FindFirstChild("UpdateQuestState")
		if upd then
			GB.conns[#GB.conns + 1] = upd.OnClientEvent:Connect(function(name, state)
				if state == "Complete" and type(name) == "string" then
					M._live[name] = nil
					M._done[name] = true
					if M._current == name then
						M._current = nil
					end
					if GB.Stats and GB.Stats.markDirty then
						GB.Stats.markDirty("quest_complete")
					end
				end
				bump("UpdateQuestState " .. tostring(name))
			end)
		end
		local cc = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("ClientCache")
		local ch = cc and cc:FindFirstChild("QuestsChanged")
		if ch then
			GB.conns[#GB.conns + 1] = ch.Event:Connect(function()
				bump("QuestsChanged")
			end)
		end
		local st = ev:FindFirstChild("StatPoints")
		if st then
			GB.conns[#GB.conns + 1] = st.OnClientEvent:Connect(function(stats, pts)
				if type(stats) == "table" then
					M._liveStats = stats
					M._statsSource = "StatPointsEvent"
					M._statsAt = os.clock()
				end
				if type(pts) == "number" then
					M._unusedPts = pts
					M._unusedPtsAt = os.clock()
					M._statsSource = M._statsSource or "StatPointsEvent"
					M._statsAt = os.clock()
					if GB.Stats and GB.Stats.markDirty then
						GB.Stats.markDirty("stat_points_event")
					end
				end
				if GB.State and GB.State.track then
					GB.State.track.StateChange = os.clock()
				end
			end)
		end
		task.spawn(function()
			M.pullStats()
		end)
	end

	function M.raw()
		loadMods()
		return M._cache and M._cache.Data or {}
	end

	function M.cache()
		loadMods()
		M.refreshLive()
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
			if out.Level <= 0 and M._stat and M._stat.GetValue then
				local n = M._stat.GetValue(char, "Level")
				if type(n) == "number" then
					out.Level = n
				end
			end
		end
		out.EXP = tonumber(d.EXP) or tonumber(d.Exp) or 0
		out.Gold = tonumber(d.Gold) or 0
		out.StatPoints = tonumber(M._unusedPts)
		if out.StatPoints == nil then
			out.StatPoints = tonumber(d.StatPoints) or tonumber(d["Stat Points"]) or tonumber(d.UnusedStatPoints) or 0
		end
		out.Stats = {}
		if char and M._stat and M._stat.GetBaseValue then
			for _, n in ipairs({ "Health", "Strength", "Agility", "Precision", "Energy", "Willpower" }) do
				local v = M._stat.GetBaseValue(char, n)
				out.Stats[n] = type(v) == "number" and v or 0
			end
		end
		out.CompletedSet = M._done
		out.Quests = M._live
		out.Inventory = d.Inventory or {}
		out.Skills = d.Skills or {}
		out.Fruit = d.Fruit
		out["Fruit Storage"] = d["Fruit Storage"]
		out["Permanent Fruits"] = d["Permanent Fruits"]
		out.CurrentQuest = M._current
		return out
	end

	function M.finished(name, skipRefresh)
		if not skipRefresh then
			M.refreshLive()
		end
		return name and M._done[name] == true
	end

	function M.live(name)
		if not name then
			return nil
		end
		M.refreshLive()
		if M._done[name] and not (GB.QuestData and GB.QuestData.isRepeatable and GB.QuestData.isRepeatable(name)) then
			return nil
		end
		return M._live[name]
	end

	function M.current()
		M.refreshLive()
		return M._current
	end

	function M.activeNames()
		M.refreshLive()
		local out = {}
		for _, n in ipairs(M._order) do
			if M._live[n] then
				out[#out + 1] = n
			end
		end
		return out
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
			if type(v) == "table" and (v.Name == name or v.Key == name or v.Value == name) then
				return true, tonumber(v.Amount) or 1
			end
		end
		return false, 0
	end

	function M.skillOwned(name)
		local skills = M.cache().Skills
		if type(skills) ~= "table" or not name then
			return false, false
		end
		local row = skills[name]
		if type(row) == "table" then
			return row.Owned == true or row.Equipped == true, row.Equipped == true
		end
		return false, false
	end

	function M.pullStats()
		local t0 = pbegin()
		local a, b = GB.Remotes.getStats()
		local stats
		local pts
		if type(a) == "table" then
			stats = a
		elseif type(b) == "table" then
			stats = b
		end
		if type(a) == "number" then
			pts = a
		end
		if type(b) == "number" then
			pts = b
		end
		if type(stats) == "table" then
			local packed = {}
			for _, name in ipairs(STAT_NAMES) do
				packed[name] = tonumber(stats[name]) or 0
			end
			M._liveStats = packed
			M._statsSource = "GetStats"
			M._statsAt = os.clock()
		end
		if type(pts) == "number" then
			M._unusedPts = pts
			M._unusedPtsAt = os.clock()
			M._statsSource = M._statsSource or "GetStats"
			M._statsAt = os.clock()
		end
		pdone("PlayerData.pullStats", t0)
		return a, b
	end

	function M.unusedStatPoints(force)
		if force or type(M._unusedPts) ~= "number" or os.clock() - (M._unusedPtsAt or 0) > UNUSED_TTL then
			M.pullStats()
		end
		return tonumber(M._unusedPts)
	end

	function M.latestStats()
		return M._liveStats, tonumber(M._unusedPts), M._statsSource, M._statsAt
	end

	function M.refreshStats()
		GB.Remotes.statReplicate()
		return M.pullStats()
	end

	return M
end
