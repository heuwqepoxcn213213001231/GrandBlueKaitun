-- Priority: Recovery → Mandatory story → Prerequisites → Level-gate farm → Story.
-- Optional Fruit/Haki/Race after story is idle.

return function(GB)
	local M = {
		goal = nil,
		task = nil,
		owner = "IDLE",
	}
	local logDoing

	local function setOwner(owner, target)
		owner = owner or "IDLE"
		local key = tostring(owner) .. "|" .. tostring(target or "-")
		if M._ownerKey == key then
			return
		end
		M._ownerKey = key
		M.owner = owner
		GB.Log.log("STATE", string.format("owner=%s target=%s", tostring(owner), tostring(target or "-")))
	end

	local function ownerForTask(taskName)
		local t = tostring(taskName or "")
		if string.find(t, "quest_accept:", 1, true) then
			return "QUEST_ACCEPT"
		end
		if string.find(t, "farm_direct:", 1, true) then
			return "COMBAT"
		end
		if string.find(t, "tutorial", 1, true) then
			return "TUTORIAL"
		end
		if string.find(t, "recovery", 1, true) then
			return "RECOVERY"
		end
		if string.find(t, "quest:", 1, true) or string.find(t, "story:", 1, true) or string.find(t, "farm:", 1, true) then
			return "QUEST_OBJECTIVE"
		end
		return "IDLE"
	end

	local function pbegin()
		return GB.Profiler and GB.Profiler.begin and GB.Profiler.begin() or nil
	end

	local function pdone(name, t0)
		if t0 and GB.Profiler and GB.Profiler.done then
			GB.Profiler.done(name, t0)
		end
	end

	local function setTask(name)
		if GB.State.track.TaskName ~= name then
			GB.State.track.TaskName = name
			GB.State.track.TaskStartedAt = os.clock()
			GB.Log.log("STATE", "task " .. tostring(name))
		end
		M.task = name
		setOwner(ownerForTask(name), name)
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
					if not GB.Config.SkipQuests[name] and not GB.PlayerData.finished(name, true) then
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

	local function repeatStartability(name)
		local start = GB.QuestData and GB.QuestData.repeatStartSpec and GB.QuestData.repeatStartSpec(name) or nil
		local qs = GB.Quest and GB.Quest.questState and GB.Quest.questState(name) or nil
		if qs and qs.IsAccepted then
			return {
				Mode = "quest",
				Status = "ACTIVE",
				StartSpec = start,
			}
		end
		local auto = start and start.Automatic == true
		local hasNpc = start and type(start.AcceptNPC) == "string" and start.AcceptNPC ~= ""
		local hasOther = start and type(start.OtherVerifiedStartMethod) == "string" and start.OtherVerifiedStartMethod ~= ""
		if auto or hasNpc or hasOther then
			return {
				Mode = "quest",
				Status = "STARTABLE",
				StartSpec = start,
			}
		end
		if start and start.DirectCombatVerified == true then
			return {
				Mode = "direct",
				Status = "DIRECT_VERIFIED",
				StartSpec = start,
			}
		end
		return {
			Mode = nil,
			Status = "UNRESOLVED_START",
			StartSpec = start,
		}
	end

	local function bestRepeat(island, lv)
		local bestQuest
		local bestDirect
		for _, e in ipairs(GB.QuestData.REPEATS) do
			if e.island == island and lv >= (e.accept or 0) and lv <= (e.full_until or 999) then
				if GB.QuestData.prereqOk(e.prereq) then
					local blockedRepeat = false
					if GB.Quest and GB.Quest.questStatus then
						local status = GB.Quest.questStatus(e.name)
						if status == "DEFERRED" or status == "BLOCKED_REQUIREMENT" then
							blockedRepeat = true
						end
					end
					if not blockedRepeat then
						local eExp = tonumber(e.exp) or 0
						local start = repeatStartability(e.name)
						if start.Mode == "quest" then
							if (not bestQuest) or eExp > (tonumber(bestQuest.Exp) or 0) then
								bestQuest = {
									Name = e.name,
									Mode = "quest",
									Exp = eExp,
									Entry = e,
									StartSpec = start.StartSpec,
								}
							end
						elseif start.Mode == "direct" then
							if (not bestDirect) or eExp > (tonumber(bestDirect.Exp) or 0) then
								bestDirect = {
									Name = e.name,
									Mode = "direct",
									Exp = eExp,
									Entry = e,
									StartSpec = start.StartSpec,
								}
							end
						elseif start.Status == "UNRESOLVED_START" then
							local key = "repeat_unresolved:" .. tostring(e.name)
							if M._repeatUnresolvedKey ~= key or os.clock() - (M._repeatUnresolvedAt or 0) > 25 then
								M._repeatUnresolvedKey = key
								M._repeatUnresolvedAt = os.clock()
								GB.Log.warn("PLANNER", "UNRESOLVED_START " .. tostring(e.name))
							end
						end
					end
				end
			end
		end
		if bestQuest then
			return bestQuest
		end
		if bestDirect then
			return bestDirect
		end
		return nil
	end

	local function activeQuestNames()
		local names = GB.PlayerData.activeNames and GB.PlayerData.activeNames() or {}
		local cur = GB.PlayerData.current and GB.PlayerData.current() or nil
		if type(cur) == "string" and cur ~= "" and not table.find(names, cur) then
			names[#names + 1] = cur
		end
		return names
	end

	local function questStatus(name)
		if GB.Quest and GB.Quest.questStatus then
			return GB.Quest.questStatus(name)
		end
		return "UNRESOLVED", "missing-status"
	end

	local function blockerList()
		return GB.Quest and GB.Quest.CurrentBlockers and GB.Quest.CurrentBlockers() or {}
	end

	local function logBlockedQuest(name, why)
		local key = tostring(name) .. "|" .. tostring(why)
		if M._blockedKey == key and os.clock() - (M._blockedAt or 0) < 8 then
			return
		end
		M._blockedKey = key
		M._blockedAt = os.clock()
		GB.Log.warn("QUEST", "defer " .. tostring(name) .. " " .. tostring(why))
	end

	local function pickReadyActive(skipName)
		local chosen
		for _, name in ipairs(activeQuestNames()) do
			if name ~= skipName and not GB.Config.SkipQuests[name] then
				local status, why = questStatus(name)
				if status == "BLOCKED_REQUIREMENT" or status == "DEFERRED" then
					logBlockedQuest(name, why)
				elseif status == "READY" or status == "IN_PROGRESS" then
					chosen = name
					break
				end
			end
		end
		return chosen
	end

	local function runFarmGoal(snap, why)
		local rep = bestRepeat(snap.CurrentIsland, snap.Level or 0)
		if not rep then
			return {
				attempted = false,
				progressed = false,
				reason = "no_repeat",
			}
		end
		local repName = rep.Name or tostring(rep)
		local blockers = blockerList()
		local note = tostring(why or "story_blocked")
		for _, b in ipairs(blockers) do
			if b.Type == "STAT_REQUIREMENT" and b.Stat == "Strength" then
				note = string.format("FarmUntilStrength(%d/%d)", tonumber(b.Current) or 0, tonumber(b.Required) or 0)
				break
			end
		end
		if M._farmNote ~= (repName .. "|" .. note) then
			M._farmNote = repName .. "|" .. note
			GB.Log.log("PLANNER", "farm goal " .. note)
			GB.Log.log("PLANNER", "next=" .. tostring(repName))
		end
		M.goal = { Type = "FARM", Quest = repName, Note = note, Mode = rep.Mode, At = os.clock() }
		if rep.Mode == "direct" and rep.StartSpec and rep.StartSpec.DirectCombatVerified and GB.Combat then
			local target = rep.StartSpec.DirectTarget
			if type(target) ~= "string" or target == "" then
				return {
					attempted = false,
					progressed = false,
					reason = "direct_target_missing",
				}
			end
			setTask("farm_direct:" .. tostring(target))
			logDoing("farm_direct", target)
			setOwner("COMBAT", target)
			local ok = false
			if GB.Combat.huntUntilDead then
				ok = select(1, GB.Combat.huntUntilDead(target, 16))
			elseif GB.Combat.attack then
				ok = GB.Combat.attack(target)
			end
			if not ok then
				GB.Log.warn("PLANNER", "direct farm miss " .. tostring(target))
			end
			return {
				attempted = true,
				progressed = ok == true,
				reason = ok and "direct_progress" or "direct_miss",
				quest = repName,
				target = target,
			}
		end
		if GB.Quest and GB.Quest.dialogueOpen and GB.Quest.dialogueOpen() then
			local acceptNpc = rep.StartSpec and rep.StartSpec.AcceptNPC or repName
			setTask("quest_accept:" .. tostring(acceptNpc))
			logDoing("quest_accept", acceptNpc)
			setOwner("QUEST_ACCEPT", acceptNpc)
			local row
			if GB.Quest.doLiveResult then
				row = GB.Quest.doLiveResult(repName)
			else
				local ok = GB.Quest.doLive(repName)
				row = { attempted = true, progressed = ok == true, reason = ok and "quest_progress" or "quest_pending" }
			end
			return {
				attempted = row.attempted ~= false,
				progressed = row.progressed == true,
				reason = row.reason or "dialogue_open",
				quest = repName,
			}
		end
		local live = GB.Quest and GB.Quest.questState and GB.Quest.questState(repName) or nil
		local acceptNpc = rep.StartSpec and rep.StartSpec.AcceptNPC
		if live and not live.IsAccepted and type(acceptNpc) == "string" and acceptNpc ~= "" then
			setTask("quest_accept:" .. tostring(acceptNpc))
			logDoing("quest_accept", acceptNpc)
			setOwner("QUEST_ACCEPT", acceptNpc)
		else
			setTask("farm:" .. repName)
			logDoing("farm", repName)
			setOwner("QUEST_OBJECTIVE", repName)
		end
		local row
		if GB.Quest.doLiveResult then
			row = GB.Quest.doLiveResult(repName)
		else
			local ok = GB.Quest.doLive(repName)
			row = { attempted = true, progressed = ok == true, reason = ok and "quest_progress" or "quest_pending" }
		end
		if row.progressed ~= true and rep.StartSpec and rep.StartSpec.Status == "STARTABLE" then
			GB.Log.warn("PLANNER", "farm quest pending accept/credit " .. tostring(repName))
			if M._farmPendingKey ~= (repName .. "|" .. tostring(row.reason)) or os.clock() - (M._farmPendingAt or 0) > 4 then
				M._farmPendingKey = repName .. "|" .. tostring(row.reason)
				M._farmPendingAt = os.clock()
				GB.Log.warn("PLANNER", string.format("farm pending %s reason=%s", tostring(repName), tostring(row.reason)))
			end
		end
		return {
			attempted = row.attempted ~= false,
			progressed = row.progressed == true,
			reason = row.reason or (row.progressed and "quest_progress" or "quest_not_progressed"),
			quest = repName,
		}
	end

	local function farmHandled(result)
		return type(result) == "table" and result.attempted == true
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

	function logDoing(doing, target)
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
		if GB.PlayerData.finished(story, true) then
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
		if name and GB.PlayerData.finished(name, true) then
			if GB.Stats and GB.Stats.markDirty then
				GB.Stats.markDirty("quest_complete")
			end
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
		if GB.PlayerData and GB.PlayerData.refreshLive then
			GB.PlayerData.refreshLive(false, "engine_cycle")
		end

		local tutSnap = snap.UI or nil
		local gate = GB.Tutorial and GB.Tutorial.GetCurrentGate and GB.Tutorial.GetCurrentGate()
		local continueOverlay = gate and gate.Type == (GB.Tutorial.GateTypes and GB.Tutorial.GateTypes.ContinueOverlay)

		-- Recovery dumps / strategy change, then resume story. Do not freeze.
		-- ContinueOverlay owns its own attempt budget — do not recycle lookup.
		if GB.Recovery.stuck() and not continueOverlay then
			setTask("recovery")
			GB.Recovery.run("engine")
			local s2 = GB.State.get and GB.State.get() or nil
			tutSnap = (s2 and s2.UI) or tutSnap
			gate = GB.Tutorial and GB.Tutorial.GetCurrentGate and GB.Tutorial.GetCurrentGate()
			continueOverlay = gate and gate.Type == (GB.Tutorial.GateTypes and GB.Tutorial.GateTypes.ContinueOverlay)
		end

		local blocking = (type(tutSnap) == "table" and (tutSnap.Blocking == true or tutSnap.TutorialActive == true))
			or (GB.Tutorial and GB.Tutorial.IsBlocking and select(1, GB.Tutorial.IsBlocking()))
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
					if GB.PlayerData and GB.PlayerData.forceQuestRefresh then
						GB.PlayerData.forceQuestRefresh("tutorial_gate")
					elseif GB.PlayerData and GB.PlayerData.refreshLive then
						GB.PlayerData.refreshLive(true, "tutorial_gate")
					end
					if GB.Planner and GB.Planner.Replan then
						GB.Planner.Replan()
					end
				end
				snap = GB.State.refresh()
				tutSnap = snap.UI or tutSnap
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

		if GB.Stats and GB.Stats.tick then
			GB.Stats.tick()
		end

		if GB.Config.AutoCodes then
			GB.Codes.tick()
		end
		if GB.Config.AutoRewards then
			GB.Rewards.tick()
		end
		-- Quest path returns before the idle ticks. Keep gear mid-story.
		if GB.Equipment and GB.Equipment.tick then
			GB.Equipment.tick()
		end

		local function otherOrFarm(skipName, reason)
			local nextQuest = pickReadyActive(skipName)
			if nextQuest then
				if M._planQuest ~= nextQuest then
					M._planQuest = nextQuest
					GB.Log.log("PLANNER", "choose " .. tostring(nextQuest))
				end
				setTask("quest:" .. nextQuest)
				logQuestDoing(nextQuest)
				GB.Quest.doLive(nextQuest)
				afterQuest(nextQuest)
				return true
			end
			if farmHandled(runFarmGoal(snap, reason or "no_ready_active")) then
				return true
			end
			return false
		end

		-- Mandatory live story
		if GB.Config.AutoTutorial or GB.Config.AutoQuest then
			local cur = GB.PlayerData.current()
			if cur and not GB.Config.SkipQuests[cur] then
				local status, why = questStatus(cur)
				if status == "BLOCKED_REQUIREMENT" or status == "DEFERRED" then
					logBlockedQuest(cur, why)
					if otherOrFarm(cur, why) then
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
					if farmHandled(runFarmGoal(snap, "FarmUntilLevel(" .. tostring(need) .. ")")) then
						return
					end
					setTask("wait_level:" .. cur)
					logDoing("wait_level", cur)
					return
				end
				setTask("quest:" .. cur)
				logQuestDoing(cur)
				GB.Quest.doLive(cur)
				afterQuest(cur)
				return
			end
			local readyActive = pickReadyActive(nil)
			if readyActive then
				if M._planQuest ~= readyActive then
					M._planQuest = readyActive
					GB.Log.log("PLANNER", "choose " .. tostring(readyActive))
				end
				setTask("quest:" .. readyActive)
				logQuestDoing(readyActive)
				GB.Quest.doLive(readyActive)
				afterQuest(readyActive)
				return
			end
			if #blockerList() > 0 and otherOrFarm(nil, "all_story_blocked") then
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

		GB.Skills.tick()
		GB.Travel.tick()
		GB.Boat.tick()

		local liveName = GB.PlayerData.current()
		if liveName and not GB.Config.SkipQuests[liveName] then
			local status, why = questStatus(liveName)
			if status == "BLOCKED_REQUIREMENT" or status == "DEFERRED" then
				logBlockedQuest(liveName, why)
			else
				setTask("quest:" .. liveName)
				logQuestDoing(liveName)
				GB.Quest.doLive(liveName)
				afterQuest(liveName)
				return
			end
		end

		local readyFallback = pickReadyActive(liveName)
		if readyFallback then
			GB.Log.log("PLANNER", "choose " .. tostring(readyFallback))
			setTask("quest:" .. readyFallback)
			logQuestDoing(readyFallback)
			GB.Quest.doLive(readyFallback)
			afterQuest(readyFallback)
			return
		end
		if #blockerList() > 0 and farmHandled(runFarmGoal(snap, "active_blocked")) then
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
				if farmHandled(runFarmGoal(snap, "FarmUntilLevel(" .. tostring(GB.QuestData.needLevel(story)) .. ")")) then
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
			farmHandled(runFarmGoal(snap, "story_idle"))
			return
		end

		runOptional()
		setTask("idle")
		logDoing("idle")
	end

	local _decideRaw = M.decide
	function M.decide()
		local t0 = pbegin()
		local out = { pcall(_decideRaw) }
		pdone("DecisionEngine.decide", t0)
		if not out[1] then
			error(out[2])
		end
		return unpack(out, 2)
	end

	return M
end
