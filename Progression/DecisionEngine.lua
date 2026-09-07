-- Priority: Recovery → Mandatory story → Prerequisites → Level-gate farm → Story.
-- Optional Fruit/Haki/Race after story is idle.

return function(GB)
	local M = {
		goal = nil,
		task = nil,
	}

	local function setTask(name)
		if GB.State.track.TaskName ~= name then
			GB.State.track.TaskName = name
			GB.State.track.TaskStartedAt = os.clock()
			GB.Log.log("STATE", "task " .. tostring(name))
		end
		M.task = name
	end

	local function picker()
		local P = getgenv()._GBPicker
		if P and P.pick then
			local ok, r = pcall(P.pick)
			if ok then
				return r
			end
		end
		return nil
	end

	local function isStory(name)
		if not name or not GB.QuestData then
			return false
		end
		for _, ch in ipairs(GB.QuestData.CHAINS) do
			for _, n in ipairs(ch.order) do
				if n == name then
					return true
				end
			end
		end
		return false
	end

	local function nextStory(island, lv)
		for _, ch in ipairs(GB.QuestData.CHAINS) do
			if ch.island == island then
				for _, name in ipairs(ch.order) do
					if not GB.Config.SkipQuests[name] and not GB.PlayerData.finished(name) then
						if GB.PlayerData.live(name) then
							return name
						end
						local need = GB.QuestData.needLevel(name)
						if lv >= need then
							return name
						end
					end
				end
			end
		end
	end

	local function bestRepeat(island, lv)
		local best
		for _, e in ipairs(GB.QuestData.REPEATS) do
			if e.island == island and lv >= (e.accept or 0) and lv <= (e.full_until or 999) then
				if GB.QuestData.prereqOk(e.prereq) then
					if not best or e.exp > best.exp then
						best = e
					end
				end
			end
		end
		return best and best.name
	end

	function M.optionalOk()
		if GB.Config.StoryFirst == false then
			return true
		end
		local cur = GB.PlayerData.current()
		if cur and isStory(cur) and not GB.Config.SkipQuests[cur] then
			return false
		end
		if M.task and string.find(tostring(M.task), "quest:", 1, true) then
			return false
		end
		if M.task and string.find(tostring(M.task), "story:", 1, true) then
			return false
		end
		return true
	end

	local function runOptional()
		if not M.optionalOk() then
			return
		end
		GB.Boss.tick()
		GB.Fruit.tick()
		GB.Haki.tick()
		GB.RaceTrait.tick()
		GB.Treasure.tick()
		GB.Chest.tick()
		GB.Backpack.tick()
	end

	local function logDoing(doing, target)
		local key = tostring(doing) .. "|" .. tostring(target or "-")
		if M._doingKey == key then
			return
		end
		M._doingKey = key
		GB.Log.log("STATE", string.format("doing=%s target=%s", tostring(doing), tostring(target or "-")))
	end

	local function logQuestDoing(name)
		local mob = GB.Combat and GB.Combat.lockMob
		if mob and GB.Combat.IsEnemyAlive and GB.Combat.IsEnemyAlive(mob) then
			logDoing("combat", mob.Name)
			return
		end
		local qs = name and GB.Quest.questState(name)
		local o = qs and qs.Objective
		if o then
			local typ = tostring(o.Type or "quest")
			if typ == "Collect" or typ == "Kill" or typ == "Defeat" or typ == "Hit" or typ == "Shoot" then
				logDoing("combat", o.TargetName or (GB.Acquire and GB.Acquire.lastSource) or "-")
			elseif typ == "Talk" or typ == "Automatic Talk" then
				logDoing("talk", o.TargetName)
			else
				logDoing(string.lower(typ), o.TargetName)
			end
			return
		end
		logDoing("quest", name)
	end

	local function acceptNextStory(island, lv)
		local story = nextStory(island, lv)
		if not story then
			return false
		end
		if GB.PlayerData.finished(story) then
			return false
		end
		setTask("story:" .. story)
		logDoing("accept", story)
		GB.Quest.doLive(story)
		return true
	end

	local function afterQuest(name)
		if GB.Tutorial and GB.Tutorial.IsBlocking and select(1, GB.Tutorial.IsBlocking()) then
			return
		end
		if name and GB.PlayerData.finished(name) then
			if GB.Combat then
				GB.Combat.stopLock()
			end
			local snap = GB.State.get()
			acceptNextStory(snap.CurrentIsland, snap.Level or 0)
			return
		end
		logQuestDoing(name)
	end

	function M.decide()
		local snap = GB.State.refresh()
		if not snap.Alive then
			setTask("wait_spawn")
			logDoing("wait_spawn")
			return
		end

		if GB.Stats and GB.Stats.tick then
			GB.Stats.tick()
		end

		local gate = GB.Tutorial and GB.Tutorial.GetCurrentGate and GB.Tutorial.GetCurrentGate()
		local continueOverlay = gate and gate.Type == (GB.Tutorial.GateTypes and GB.Tutorial.GateTypes.ContinueOverlay)

		-- Recovery dumps / strategy change, then resume story. Do not freeze.
		-- ContinueOverlay owns its own attempt budget — do not recycle lookup.
		if GB.Recovery.stuck() and not continueOverlay then
			setTask("recovery")
			GB.Recovery.run("engine")
			gate = GB.Tutorial and GB.Tutorial.GetCurrentGate and GB.Tutorial.GetCurrentGate()
			continueOverlay = gate and gate.Type == (GB.Tutorial.GateTypes and GB.Tutorial.GateTypes.ContinueOverlay)
		end

		local blocking = GB.Tutorial and GB.Tutorial.IsBlocking and select(1, GB.Tutorial.IsBlocking())
		if GB.Recovery.outcome == "BLOCKING_UI" or GB.Recovery.outcome == "BLOCKING_GATE_UNRESOLVED" or blocking then
			if GB.Recovery.outcome == "BLOCKING_GATE_UNRESOLVED" and GB.Tutorial and GB.Tutorial.unresolved then
				return
			end
			setTask("tutorial")
			logDoing("tutorial", gate and (gate.Id .. ":" .. tostring(gate.Payload or gate.Type)) or (snap.UI and snap.UI.TutorialStep))
			if GB.Combat then
				GB.Combat.stopLock()
			end
			local cleared = false
			if GB.Tutorial and GB.Tutorial.ExecuteGate then
				cleared = GB.Tutorial.ExecuteGate(gate)
			elseif GB.Tutorial and GB.Tutorial.ExecuteCurrentStep then
				cleared = GB.Tutorial.ExecuteCurrentStep()
			end
			if cleared and GB.Tutorial and not select(1, GB.Tutorial.IsBlocking()) then
				GB.Recovery.outcome = nil
				M._doingKey = nil
				if GB.Tutorial.refreshAfterGate then
					GB.Tutorial.refreshAfterGate()
				else
					if GB.PlayerData and GB.PlayerData.refreshLive then
						GB.PlayerData.refreshLive(true)
					end
					if GB.Planner and GB.Planner.Replan then
						GB.Planner.Replan()
					end
				end
				snap = GB.State.refresh()
				-- fall through to quest this tick
			else
				return
			end
		end

		if snap.GameplayPaused then
			setTask("wait_unpause")
			logDoing("wait_unpause")
			if GB.State.dismissTutorialOverlay then
				GB.State.dismissTutorialOverlay()
			end
			GB.World.waitUnpause()
			return
		end

		if GB.Config.AutoCodes then
			GB.Codes.tick()
		end
		if GB.Config.AutoRewards then
			GB.Rewards.tick()
		end
		-- Quest path returns before the idle ticks. Spend points / keep gear mid-story.
		if GB.Stats and GB.Stats.tick then
			GB.Stats.tick()
		end
		if GB.Equipment and GB.Equipment.tick then
			GB.Equipment.tick()
		end

		local function otherOrFarm(skipName)
			local names = GB.PlayerData.activeNames and GB.PlayerData.activeNames() or {}
			for _, name in ipairs(names) do
				if name ~= skipName and not GB.Config.SkipQuests[name] then
					local d2 = GB.Quest.deferred and select(1, GB.Quest.deferred(name))
					if not d2 then
						setTask("quest:" .. name)
						logQuestDoing(name)
						GB.Quest.doLive(name)
						afterQuest(name)
						return true
					end
				end
			end
			local rep = bestRepeat(snap.CurrentIsland, snap.Level or 0)
			if rep then
				setTask("farm:" .. rep)
				logDoing("farm", rep)
				GB.Quest.doLive(rep)
				return true
			end
			return false
		end

		-- Mandatory live story
		if GB.Config.AutoTutorial or GB.Config.AutoQuest then
			local cur = GB.PlayerData.current()
			if cur and not GB.Config.SkipQuests[cur] then
				local def, why = false, nil
				if GB.Quest.deferred then
					def, why = GB.Quest.deferred(cur)
				end
				if def then
					if M._deferKey ~= cur then
						M._deferKey = cur
						GB.Log.warn("QUEST", "defer " .. tostring(cur) .. " " .. tostring(why))
					end
					if otherOrFarm(cur) then
						return
					end
					setTask("defer:" .. cur)
					logDoing("defer", cur)
					return
				end
				local qs = GB.Quest.questState(cur)
				local obj = qs and qs.Objective
				local gated = obj and obj.Type == "Required" and obj.TargetName == "Level"
				local need = gated and (obj.Amount or GB.QuestData.needLevel(cur)) or 0
				if gated and (snap.Level or 0) < need then
					setTask("wait_level:" .. cur)
					local island = snap.CurrentIsland
					local rep = bestRepeat(island, snap.Level or 0)
					if rep then
						setTask("farm:" .. rep)
						GB.Quest.doLive(rep)
					end
					return
				end
				setTask("quest:" .. cur)
				logQuestDoing(cur)
				GB.Quest.doLive(cur)
				afterQuest(cur)
				return
			end
		end

		-- Prerequisites / progression shop (Flintlock, pickaxe, snail, boat)
		if GB.Config.AutoShop then
			GB.Shop.tick()
		end

		if GB.Inventory.full() then
			GB.Log.warn("STATE", "inventory many items — UNKNOWN kept")
		end

		GB.Equipment.tick()
		GB.Stats.tick()
		GB.Skills.tick()
		GB.Travel.tick()
		GB.Boat.tick()

		local liveName = GB.PlayerData.current()
		if liveName and not GB.Config.SkipQuests[liveName] then
			setTask("quest:" .. liveName)
			logQuestDoing(liveName)
			GB.Quest.doLive(liveName)
			afterQuest(liveName)
			return
		end

		local pick = picker()
		if pick and pick.name then
			setTask("pick:" .. pick.name)
			logDoing("pick", pick.name)
			GB.Quest.doLive(pick.name)
			afterQuest(pick.name)
			return
		end

		local island = snap.CurrentIsland
		local lv = snap.Level or 0
		local story = nextStory(island, lv)
		if story then
			if lv < GB.QuestData.needLevel(story) then
				local rep = bestRepeat(island, lv)
				if rep then
					setTask("farm:" .. rep)
					logDoing("farm", rep)
					GB.Quest.doLive(rep)
					return
				end
				setTask("wait_level:" .. story)
				logDoing("wait_level", story)
				return
			end
			setTask("story:" .. story)
			logDoing("accept", story)
			GB.Quest.doLive(story)
			afterQuest(story)
			return
		end

		local rep = bestRepeat(island, lv)
		if rep then
			setTask("repeat:" .. rep)
			logDoing("repeat", rep)
			GB.Quest.doLive(rep)
			return
		end

		runOptional()
		setTask("idle")
		logDoing("idle")
	end

	return M
end
