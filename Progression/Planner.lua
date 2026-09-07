-- Goal + acquisition plan. Subgoal stack. No ObjectiveType-only dispatch for Collect.

return function(GB)
	local M = {
		last = nil,
		seen = {},
	}

	local function objOf(qs)
		return qs and qs.Objective
	end

	function M.build(qs)
		if not qs or not qs.Objective then
			M.last = nil
			return nil
		end
		local o = qs.Objective
		local spec = GB.QuestSpecs and GB.QuestSpecs.lookup(qs.Name, qs.StageIndex, o.Type, o.TargetName)
		local itemSpec = o.TargetName and GB.QuestSpecs and GB.QuestSpecs.itemOf(o.TargetName)
		local goal = (spec and spec.goal) or o.Type
		local method = spec and spec.acquire
		if not method and itemSpec then
			method = itemSpec.method
		end
		if o.Type == "Collect" or o.Type == "CollectLocal" or o.Type == "CollectLocalItem" or o.Type == "Loot" then
			goal = "AcquireItem"
		end
		local stack = GB.QuestSpecs and GB.QuestSpecs.subgoalsOf(qs.Name)
		local plan = {
			Quest = qs.Name,
			Stage = qs.StageIndex,
			Goal = goal,
			Target = o.TargetName,
			Amount = o.Amount or 1,
			Current = o.Current or 0,
			Method = method,
			Source = (spec and spec.source) or (itemSpec and itemSpec.source),
			Location = (spec and spec.location) or qs.Island,
			Marker = spec and spec.marker,
			Type = o.Type,
			Subgoals = stack,
			Handler = spec and spec.handler,
		}
		M.last = plan
		return plan
	end

	local function subgoalDone(step)
		if not step then
			return true
		end
		if step.goal == "HaveGold" then
			local gold = GB.State.get().Gold or 0
			return gold >= (step.amount or 0)
		end
		if step.goal == "AcquireItem" then
			local ok, n = GB.PlayerData.hasItem(step.item)
			return ok and (n or 1) >= (step.amount or 1)
		end
		if step.goal == "Upgrade" then
			local qs = GB.Quest.questState("First Upgrade")
			if not qs or qs.IsComplete then
				return true
			end
			local o = qs.Objective
			return not o or o.Type ~= "Upgrade"
		end
		return false
	end

	function M.executeSubgoals(qs, plan)
		local stack = plan.Subgoals
		if type(stack) ~= "table" then
			return false
		end
		local qkey = qs.Name
		if not M.seen[qkey] then
			M.seen[qkey] = {}
		end
		local o = objOf(qs)
		for i, step in ipairs(stack) do
			local id = tostring(step.goal) .. "|" .. tostring(step.item or i)
			if M.seen[qkey][id] and M.seen[qkey][id] > 12 then
				GB.Log.warn("PLAN", "CYCLE " .. qs.Name .. " " .. id)
				return false
			end
			if not subgoalDone(step) then
				M.seen[qkey][id] = (M.seen[qkey][id] or 0) + 1
				if step.goal == "HaveGold" then
					GB.Log.log("PLAN", "Need gold " .. tostring(step.amount))
					return false
				end
				if step.goal == "AcquireItem" then
					if o and o.Type == "Collect" and o.TargetName and o.TargetName ~= step.item then
						-- live condition is a later item; skip only if owned
					end
					return GB.Acquire.AcquireItem(step.item, step.amount or 1, {
						Quest = qs.Name,
						Stage = qs.StageIndex,
						Type = o and o.Type,
						Method = step.method,
					})
				end
				if step.goal == "Upgrade" then
					return GB.Equipment.upgradeNamed(step.item)
				end
				return false
			end
		end
		return true
	end

	function M.execute(qs, plan)
		if not (qs and plan) then
			return false
		end
		if plan.Goal == "AcquireItem" and plan.Target then
			if plan.Subgoals and qs.Name == "First Upgrade" then
				local o = objOf(qs)
				if o and (o.Type == "Collect" or o.Type == "Smelt" or o.Type == "Upgrade") then
					return M.executeSubgoals(qs, plan)
				end
			end
			local beforeCur = plan.Current or 0
			local beforeSig = GB.Quest.signature(qs)
			local ok = GB.Acquire.AcquireItem(plan.Target, plan.Amount or 1, {
				Quest = qs.Name,
				Stage = qs.StageIndex,
				Type = plan.Type,
				Method = plan.Method,
				Source = plan.Source,
				Marker = plan.Marker,
			})
			if ok and GB.Quest.waitProgress then
				local progressed = GB.Quest.waitProgress(qs.Name, beforeSig, 2.4)
				if progressed then
					local after = GB.Quest.questState(qs.Name)
					local nextCur = plan.Amount
					if after.StageIndex == qs.StageIndex and after.Objective then
						nextCur = after.Objective.Current
					end
					GB.Log.log(
						"QUEST",
						string.format("%s/%s -> %s/%s", tostring(beforeCur), tostring(plan.Amount), tostring(nextCur), tostring(plan.Amount))
					)
					GB.Quest.noteOk(qs.Name)
					if GB.Acquire.clearCycles then
						GB.Acquire.clearCycles(qs.Name)
					end
					return true
				end
			end
			if ok then
				return true
			end
			GB.Quest.noteFail(qs.Name, "acquire " .. tostring(plan.Target))
			return false
		end
		return GB.Quest.handleCondition(qs.Name, qs.Objective.Raw, qs.Stage)
	end

	return M
end
