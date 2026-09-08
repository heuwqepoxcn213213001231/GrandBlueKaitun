-- Runtime GameKnowledge over GeneratedData. Research → generated tables → live plan.

return function(GB)
	local M = {
		_ctx = nil,
		_ctxAt = 0,
	}

	local function data()
		return GB.GeneratedData
	end

	function M.quest(name)
		local d = data()
		return d and d.quest and d.quest(name) or nil
	end

	function M.npc(name)
		local d = data()
		return d and d.npc and d.npc(name) or nil
	end

	function M.item(name)
		local d = data()
		return d and d.item and d.item(name) or nil
	end

	function M.skill(name)
		local d = data()
		return d and d.skill and d.skill(name) or nil
	end

	function M.stage(quest, stage, typ, target)
		local d = data()
		if d and d.stage then
			return d.stage(quest, stage, typ, target)
		end
		return GB.QuestSpecs and GB.QuestSpecs.lookup and GB.QuestSpecs.lookup(quest, stage, typ, target)
	end

	function M.startKind(name)
		local q = M.quest(name)
		if q and q.Start then
			return q.Start
		end
		local rs = GB.QuestData and GB.QuestData.REPEAT_START and GB.QuestData.REPEAT_START[name]
		if rs then
			if rs.Automatic then
				return "AUTOMATIC"
			end
			if rs.AcceptNPC then
				return "NPC_START"
			end
			return rs.Status == "STARTABLE" and "NPC_START" or "UNRESOLVED_START"
		end
		if GB.QuestData and GB.QuestData.AUTOMATIC and GB.QuestData.AUTOMATIC[name] then
			return "AUTOMATIC"
		end
		return "UNRESOLVED_START"
	end

	function M.itemPolicy(name)
		local it = M.item(name)
		if not it then
			return "UNKNOWN", true
		end
		return it.Policy or "UNKNOWN", it.Keep ~= false
	end

	function M.shouldKeepItem(name)
		local _, keep = M.itemPolicy(name)
		return keep
	end

	function M.actionResult(opts)
		opts = opts or {}
		return {
			attempted = opts.attempted == true,
			localSuccess = opts.localSuccess == true,
			progressionSuccess = opts.progressionSuccess == true,
			before = opts.before,
			after = opts.after,
			reason = opts.reason,
		}
	end

	function M.remoteAllowed(action)
		local d = data()
		if d and d.remoteAllowed then
			return d.remoteAllowed(action)
		end
		return action ~= "BeginQuest"
	end

	function M.dialogueDeclineExact()
		local d = data()
		local set = {}
		local list = d and d.Dialogue and d.Dialogue.DeclineExact
		if type(list) == "table" then
			for _, s in ipairs(list) do
				set[s] = true
			end
		end
		return set
	end

	function M.currentBlockers()
		local out = {}
		local name = GB.PlayerData and GB.PlayerData._current
		if not name then
			return out
		end
		local typ = GB.PlayerData.liveObjectiveType and GB.PlayerData.liveObjectiveType(name)
		local q = M.quest(name)
		local snap = GB.State and GB.State.get and GB.State.get() or {}
		if typ == "Required" then
			local qs = GB.Quest and GB.Quest.questState and GB.Quest.questState(name)
			local o = qs and qs.Objective
			if o and o.TargetName == "Level" then
				out[#out + 1] = {
					Type = "LEVEL_REQUIREMENT",
					Quest = name,
					Current = tonumber(snap.Level) or 0,
					Required = tonumber(o.Amount) or (q and q.NeedLevel) or 0,
				}
			elseif o and o.TargetName == "TotalStatPoints" then
				out[#out + 1] = {
					Type = "STAT_REQUIREMENT",
					Stat = "Unused",
					Quest = name,
					Current = tonumber(snap.StatPoints) or 0,
					Required = tonumber(o.Amount) or 1,
				}
			end
		end
		if name == "Gate of Authority" then
			local st = GB.Stats and GB.Stats.ReadStatState and GB.Stats.ReadStatState()
			local str = st and st.Strength or 0
			if str < 100 then
				out[#out + 1] = {
					Type = "STAT_REQUIREMENT",
					Stat = "Strength",
					Quest = name,
					Current = str,
					Required = 100,
				}
			end
		end
		if q and (tonumber(snap.Level) or 0) < (tonumber(q.NeedLevel) or 0) then
			out[#out + 1] = {
				Type = "LEVEL_REQUIREMENT",
				Quest = name,
				Current = tonumber(snap.Level) or 0,
				Required = q.NeedLevel,
			}
		end
		return out
	end

	function M.buildContext()
		local now = os.clock()
		if M._ctx and now - M._ctxAt < 0.12 then
			return M._ctx
		end
		local name = GB.PlayerData and GB.PlayerData._current
		local qs = name and GB.Quest and GB.Quest.questState and GB.Quest.questState(name)
		local unfinished = name and GB.Quest and GB.Quest.unfinishedConditions and GB.Quest.unfinishedConditions(name) or {}
		local conds = {}
		for i, cond in ipairs(unfinished) do
			conds[i] = {
				Type = cond.Type or cond.type,
				Target = cond.TargetName or cond.Target or cond.target,
				Current = cond.Current or cond.current,
				Amount = cond.Amount or cond.amount,
				Complete = cond.Complete == true,
			}
		end
		local ctx = {
			State = GB.State and GB.State.get and GB.State.get() or {},
			QuestName = name,
			QuestState = qs,
			QuestSpec = name and M.quest(name),
			Unfinished = conds,
			TutorialGate = GB.Tutorial and GB.Tutorial.GetCurrentGate and GB.Tutorial.GetCurrentGate() or nil,
			Stats = GB.Stats and GB.Stats.GetSnapshot and GB.Stats.GetSnapshot() or nil,
			Blockers = M.currentBlockers(),
			StartKind = name and M.startKind(name) or nil,
			At = now,
		}
		M._ctx = ctx
		M._ctxAt = now
		return ctx
	end

	function M.invalidateContext()
		M._ctx = nil
		M._ctxAt = 0
	end

	return M
end
