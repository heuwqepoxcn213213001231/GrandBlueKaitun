-- Generic executor: GetLiveQuest → Stage → ParseObjective → Resolve → Execute → Validate.
-- Talk: ClientQuest("Talk", DisplayName) + DialogueBindable(Configuration). Never BeginQuest.

return function(GB)
	local M = {
		lastTalk = {},
		track = {},
		unknown = {},
		lastSig = {},
	}

	local DECLINE = {
		Decline = true,
		["Good luck with"] = true,
		Bye = true,
		No = true,
		Cancel = true,
	}

	local HANDLED = {
		Talk = true,
		["Automatic Talk"] = true,
		Kill = true,
		Defeat = true,
		Hit = true,
		Destroy = true,
		Shoot = true,
		Purchase = true,
		Sell = true,
		Equip = true,
		Upgrade = true,
		EquipSkill = true,
		Cast = true,
		Required = true,
		Collect = true,
		CollectLocal = true,
		CollectLocalItem = true,
		Loot = true,
		Mine = true,
		Smelt = true,
		Fish = true,
		Plant = true,
		Harvest = true,
		Water = true,
		Fertilize = true,
		Cook = true,
		["Perfect Cook"] = true,
		Craft = true,
		Deliver = true,
		Donate = true,
		GiveItemTo = true,
		Interact = true,
		Investigate = true,
		Wake = true,
		["Check On"] = true,
		Open = true,
		Free = true,
		Visit = true,
		Reach = true,
		Spawn = true,
		Escort = true,
		Dash = true,
		Block = true,
		Travel = true,
		Boss = true,
	}

	local function clickAccept()
		local pg = GB.lp and GB.lp.PlayerGui
		local ui = pg and pg:FindFirstChild("DialogueUI")
		if not ui then
			return false
		end
		local function try(btn)
			if not btn or not btn:IsA("GuiButton") then
				return false
			end
			local t = btn.Text or (btn:FindFirstChild("TextLabel") and btn.TextLabel.Text) or btn.Name
			if type(t) ~= "string" then
				return false
			end
			for bad in pairs(DECLINE) do
				if string.find(t, bad, 1, true) then
					return false
				end
			end
			if string.find(t, "Accept") or string.find(t, "Thank") or string.find(t, "Yes") or t == "1" then
				btn:Activate()
				return true
			end
			return false
		end
		for _, d in ipairs(ui:GetDescendants()) do
			if try(d) then
				return true
			end
		end
		for _, d in ipairs(ui:GetDescendants()) do
			if d:IsA("GuiButton") and (d.Name == "1" or d.Name == "Option1") then
				d:Activate()
				return true
			end
		end
		return false
	end

	local function openLogbook()
		local pg = GB.lp and GB.lp.PlayerGui
		if not pg then
			return false
		end
		local lb = pg:FindFirstChild("Logbook")
		if lb and lb:IsA("LayerCollector") then
			lb.Enabled = true
			return true
		end
		local menu = pg:FindFirstChild("Menu")
		if menu then
			for _, d in ipairs(menu:GetDescendants()) do
				if d:IsA("GuiButton") and (d.Name == "Logbook" or d.Name == "Log Book" or d.Name == "LogbookButton") then
					d:Activate()
					return true
				end
			end
		end
		return false
	end

	function M.condProgress(cond)
		return GB.QuestData.conditionCurrent(cond), GB.QuestData.conditionAmount(cond)
	end

	function M.questState(name)
		local live = GB.PlayerData.live(name)
		local island = GB.QuestData.islandOf(name)
		local npc = GB.QuestData.talkNpc(name)
		if not live then
			return {
				Name = name,
				IsAccepted = false,
				IsComplete = GB.PlayerData.finished(name),
				CanTurnIn = false,
				Automatic = GB.QuestData.AUTOMATIC[name] == true,
				NPC = npc,
				Island = island,
				StageIndex = nil,
				Objective = nil,
			}
		end
		local si, st = GB.QuestData.currentStage(live)
		local obj
		if st then
			local conds = st.Conditions or st.conditions or {}
			for _, cond in ipairs(conds) do
				if type(cond) == "table" and not cond.Complete then
					local typ = cond.Type or cond.type
					local target = GB.QuestData.conditionTarget(cond)
					if typ == "Kill" or typ == "Defeat" then
						target = GB.QuestData.killName(name, target)
					end
					local cur, amt = M.condProgress(cond)
					obj = {
						Type = typ,
						TargetName = target,
						Current = cur,
						Amount = amt,
						Complete = cond.Complete == true,
						Raw = cond,
						Automatic = typ == "Automatic Talk",
					}
					break
				end
			end
		end
		local allDone = st and st.Complete == true
		if si and live.Stages and si >= #live.Stages and allDone then
			allDone = true
		end
		local canTurn = false
		if st and not obj then
			canTurn = true
		end
		return {
			Name = name,
			Live = live,
			IsAccepted = true,
			IsComplete = GB.PlayerData.finished(name),
			CanTurnIn = canTurn,
			Automatic = GB.QuestData.AUTOMATIC[name] == true,
			NPC = npc,
			Island = island,
			StageIndex = si,
			Stage = st,
			Objective = obj,
		}
	end

	function M.signature(qs)
		local o = qs.Objective
		if not o then
			return qs.Name .. "|turn|" .. tostring(qs.StageIndex)
		end
		return string.format("%s|%s|%s|%s/%s", qs.Name, tostring(qs.StageIndex), tostring(o.Type), tostring(o.Current), tostring(o.Amount))
	end

	function M.trackOf(name)
		local t = M.track[name]
		if not t then
			t = { AttemptCount = 0, LastError = nil, NextRetryAt = 0, LastDump = 0 }
			M.track[name] = t
		end
		return t
	end

	function M.clearTrack(name)
		M.track[name] = nil
	end

	function M.noteFail(name, err)
		local t = M.trackOf(name)
		local now = os.clock()
		if now < t.NextRetryAt then
			return t
		end
		t.AttemptCount = t.AttemptCount + 1
		t.LastError = err
		t.NextRetryAt = now + 1.5
		GB.Log.warn("QUEST", string.format("%s fail #%d %s", name, t.AttemptCount, tostring(err)))
		if t.AttemptCount == 3 then
			GB.Cache.invalidate()
			local qs = M.questState(name)
			local target = qs.Objective and qs.Objective.TargetName or qs.NPC
			if target then
				GB.Resolver.dumpNearby(target, { Island = qs.Island, DisplayName = target })
				t.LastDump = now
			end
			if qs.Island and GB.World.pullStream then
				GB.World.pullStream(qs.Island)
			end
		end
		if t.AttemptCount >= 5 then
			GB.Log.err("QUEST", "STUCK " .. name .. " " .. tostring(err))
			GB.Recovery.run("quest " .. name)
			t.AttemptCount = 0
			t.NextRetryAt = now + 4
		end
		return t
	end

	function M.noteOk(name)
		M.clearTrack(name)
		GB.Recovery.markSuccess()
	end

	local function talkName(pack, fallback)
		if pack and pack.DisplayName and pack.DisplayName ~= "" then
			return pack.DisplayName
		end
		if fallback and fallback ~= "" then
			return fallback
		end
		return pack and pack.InternalName
	end

	function M.talk(request, automatic, opts)
		opts = opts or {}
		local qsName = opts.Quest
		local island = opts.Island or (qsName and GB.QuestData.islandOf(qsName))
		local key = tostring(request)
		if os.clock() - (M.lastTalk[key] or 0) < 1.8 then
			return false, "rate"
		end

		local pack = GB.Resolver.resolveNPC(request, {
			DisplayName = opts.DisplayName or request,
			InternalName = opts.InternalName,
			QuestName = qsName,
			Island = island,
			ExpectedRole = "npc",
			deep = opts.deep,
		})
		if not pack then
			if island then
				local snap = GB.State.get()
				if snap.PhysicalIsland and snap.PhysicalIsland ~= island then
					if GB.Travel then
						GB.Travel.goIsland(island)
					end
				else
					GB.World.pullStream(island)
				end
				local names = GB.Resolver.namesFor(request, opts)
				local t0 = os.clock()
				while not pack and os.clock() - t0 < 2.6 do
					for _, tag in ipairs(names) do
						local inst = GB.Resolver.waitTagged(tag, 0.35)
						if inst then
							pack = GB.Resolver.pack(inst, request)
							break
						end
					end
					if not pack then
						pack = GB.Resolver.resolveNPC(request, {
							DisplayName = request,
							Island = island,
							ExpectedRole = "npc",
							deep = true,
						})
					end
				end
			end
		end
		if not pack then
			if qsName then
				M.noteFail(qsName, "NPC miss " .. tostring(request))
			else
				GB.Log.warn("QUEST", "NPC miss " .. tostring(request))
			end
			return false, "resolve"
		end

		local shown = talkName(pack, request)
		if pack.Island and island and pack.Island ~= island and GB.Travel then
			GB.Travel.goIsland(island)
		end
		if not GB.World.ToNPC(pack, GB.Config.TalkOffset or 5) then
			if not GB.World.moveTo(pack.Instance, GB.Config.TalkRange or 14) then
				return false, "travel"
			end
		end
		GB.World.waitUnpause()
		task.wait(0.2)

		GB.Log.log("QUEST", "Talking " .. tostring(shown))
		if automatic then
			GB.Remotes.autoTalk(shown)
		else
			GB.Remotes.talk(shown)
		end
		local cfg = GB.Resolver.dialogueConfig(pack.Instance)
		if cfg then
			GB.Remotes.dialogueConfig(cfg)
		end
		task.wait(0.35)
		clickAccept()
		M.lastTalk[key] = os.clock()
		return true, shown
	end

	function M.waitProgress(name, beforeSig, timeout)
		timeout = timeout or 2.8
		local t0 = os.clock()
		while os.clock() - t0 < timeout do
			task.wait(0.2)
			if GB.PlayerData.finished(name) then
				return true, "done"
			end
			local qs = M.questState(name)
			local sig = M.signature(qs)
			if sig ~= beforeSig then
				return true, sig
			end
		end
		return false, "timeout"
	end

	function M.ensureItem(name)
		local spec = GB.QuestData.NEED_ITEM[name]
		if GB.PlayerData.hasItem(name) then
			return true
		end
		if spec and spec.gold then
			local gold = GB.State.get().Gold or 0
			if gold < spec.gold then
				GB.Log.warn("QUEST", string.format("need %s %dG have %d", name, spec.gold, gold))
				return false
			end
		end
		return GB.Shop.buy(name)
	end

	function M.handleCondition(questName, cond, stage)
		if type(cond) ~= "table" then
			return false
		end
		if cond.Complete then
			return true
		end
		local typ = cond.Type or cond.type
		local target = GB.QuestData.conditionTarget(cond)
		if typ == "Kill" or typ == "Defeat" then
			target = GB.QuestData.killName(questName, target)
		end
		if not typ then
			return false
		end
		if not HANDLED[typ] then
			if not M.unknown[questName .. typ] then
				M.unknown[questName .. typ] = true
				GB.Log.err("QUEST", "UNKNOWN_OBJECTIVE " .. tostring(typ) .. " " .. tostring(target))
			end
			return false
		end

		if typ == "Talk" or typ == "Automatic Talk" then
			local qs = M.questState(questName)
			local before = M.signature(qs)
			local ok = M.talk(target, typ == "Automatic Talk", {
				Quest = questName,
				Island = qs.Island,
				DisplayName = target,
			})
			if ok then
				local progressed, sig = M.waitProgress(questName, before)
				if progressed then
					local after = M.questState(questName)
					local prev = qs.Objective
					if prev then
						local nextCur = prev.Amount
						if after.StageIndex == qs.StageIndex and after.Objective and not after.IsComplete then
							nextCur = after.Objective.Current
						end
						GB.Log.log(
							"QUEST",
							string.format(
								"%s %s/%s -> %s/%s",
								questName,
								tostring(prev.Current),
								tostring(prev.Amount),
								tostring(nextCur),
								tostring(prev.Amount)
							)
						)
					end
					M.noteOk(questName)
					return true
				end
				M.noteFail(questName, "talk not credited " .. tostring(target))
			end
			return false
		end
		if typ == "Kill" or typ == "Defeat" or typ == "Hit" or typ == "Destroy" or typ == "Shoot" then
			local before = M.questState(questName)
			local ok = GB.Combat.attack(target or "Training Dummy", questName)
			task.wait(0.4)
			local after = M.questState(questName)
			if before.Objective and after.Objective then
				if after.Objective.Current <= before.Objective.Current and after.StageIndex == before.StageIndex then
					local mob = GB.Combat.lockMob
					if not mob or not mob.Parent then
						GB.Log.warn("QUEST", "Kill not credited " .. tostring(target))
					end
				else
					M.noteOk(questName)
				end
			end
			return ok
		end
		if typ == "Purchase" then
			return M.ensureItem(target) or GB.Shop.buy(target)
		end
		if typ == "Sell" then
			return GB.Shop.sellNamed(target)
		end
		if typ == "Equip" then
			if not GB.PlayerData.hasItem(target) then
				M.ensureItem(target)
			end
			return GB.Equipment.equipNamed(target)
		end
		if typ == "Upgrade" then
			return GB.Equipment.upgradeNamed(target)
		end
		if typ == "EquipSkill" or typ == "Cast" then
			return GB.Skills.ensure(target)
		end
		if typ == "Required" and target == "TotalStatPoints" then
			return GB.Stats.investMinimum(1)
		end
		if typ == "Required" and target == "Level" then
			return false
		end
		if typ == "Collect" or typ == "CollectLocal" or typ == "CollectLocalItem" or typ == "Loot" then
			if target and (string.find(target, "Ore") or target == "Copper Bar") then
				return GB.LifeSkills.mineToward(target)
			end
			local obj = GB.Resolver.byName(target)
			if obj then
				GB.World.ToInteractable(obj, 8)
				local pr = GB.Resolver.prompt(obj)
				if pr then
					fireproximityprompt(pr)
				end
				return true
			end
			GB.Log.warn("QUEST", "collect miss " .. tostring(target))
			return false
		end
		if typ == "Mine" or typ == "Smelt" then
			if not GB.PlayerData.hasItem("Rusty Pickaxe") then
				M.ensureItem("Rusty Pickaxe")
			end
			return GB.LifeSkills.mineToward(target)
		end
		if typ == "Fish" then
			return GB.LifeSkills.fishToward(target)
		end
		if typ == "Plant" or typ == "Harvest" or typ == "Water" or typ == "Fertilize" then
			return GB.LifeSkills.farmToward(typ, target)
		end
		if typ == "Cook" or typ == "Perfect Cook" then
			return GB.LifeSkills.cookToward(target)
		end
		if typ == "Craft" then
			GB.Log.warn("QUEST", "UNKNOWN_OBJECTIVE Craft " .. tostring(target))
			return false
		end
		if typ == "Spawn" and target == "Rowboat" then
			if not GB.PlayerData.hasItem("Rowboat") then
				M.ensureItem("Rowboat")
			end
			return GB.Boat.spawnRowboat()
		end
		if typ == "Reach" or typ == "Travel" then
			return GB.Travel.goIsland(target or "Maple Village")
		end
		if typ == "Visit" and target == "Closet" then
			local c = GB.Resolver.byName("Closet")
			if c then
				GB.World.ToInteractable(c, 10)
				GB.Remotes.closetVisit()
				return true
			end
			return false
		end
		if typ == "Open" and target == "Logbook" then
			return openLogbook()
		end
		if typ == "Open" or typ == "Interact" or typ == "Investigate" or typ == "Wake" or typ == "Check On" or typ == "Free" then
			local obj = GB.Resolver.byName(target)
			if obj then
				GB.World.ToInteractable(obj, 8)
				local pr = GB.Resolver.prompt(obj)
				if pr then
					fireproximityprompt(pr)
				end
				return true
			end
			return false
		end
		if typ == "Deliver" or typ == "Donate" or typ == "GiveItemTo" then
			return M.talk(target, false, { Quest = questName, DisplayName = target })
		end
		if typ == "Escort" then
			GB.Log.warn("QUEST", "Escort " .. tostring(target) .. " NeverSkip — follow only")
			local pack = GB.Resolver.resolveNPC(target, {
				Island = GB.QuestData.islandOf(questName),
				ExpectedRole = "npc",
			})
			if pack then
				GB.World.moveTo(pack.Instance, 8)
				return true
			end
			return false
		end
		if typ == "Dash" or typ == "Block" then
			GB.Combat.attack("Training Dummy", questName)
			return true
		end
		GB.Log.err("QUEST", "UNKNOWN_OBJECTIVE " .. tostring(typ) .. " " .. tostring(target))
		return false
	end

	function M.doLive(name)
		if GB.Config.SkipQuests[name] then
			return false
		end
		local qs = M.questState(name)
		local t = M.trackOf(name)
		if os.clock() < t.NextRetryAt and t.LastError then
			return false
		end

		if not qs.IsAccepted then
			if qs.IsComplete then
				return true
			end
			if qs.Automatic then
				GB.Remotes.beginAutomatic(name)
			end
			if qs.NPC then
				return M.talk(qs.NPC, false, { Quest = name, Island = qs.Island, DisplayName = qs.NPC })
			end
			return false
		end

		local sig = M.signature(qs)
		if M.lastSig[name] ~= sig then
			M.lastSig[name] = sig
			GB.Log.log("QUEST", string.format("%s stage=%s", name, tostring(qs.StageIndex or "-")))
			if qs.Objective then
				GB.Log.log(
					"QUEST",
					string.format("Objective %s %s", string.upper(tostring(qs.Objective.Type or "?")), tostring(qs.Objective.TargetName or ""))
				)
			end
		end

		if qs.IsComplete then
			M.noteOk(name)
			return true
		end

		if qs.Objective then
			local typ = qs.Objective.Type
			if typ and not HANDLED[typ] then
				if not M.unknown[name .. tostring(typ)] then
					M.unknown[name .. tostring(typ)] = true
					GB.Log.err("QUEST", "UNKNOWN_OBJECTIVE " .. tostring(typ) .. " " .. tostring(qs.Objective.TargetName))
				end
				t.NextRetryAt = os.clock() + 6
				return false
			end
			return M.handleCondition(name, qs.Objective.Raw, qs.Stage)
		end

		if qs.NPC then
			return M.talk(qs.NPC, false, { Quest = name, Island = qs.Island, DisplayName = qs.NPC })
		end
		return false
	end

	return M
end
