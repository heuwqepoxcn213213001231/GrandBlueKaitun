-- Generic executor: GetLiveQuest → Stage → ParseObjective → Resolve → Execute → Validate.
-- Talk: ClientQuest("Talk", DisplayName) + DialogueBindable(Configuration). Never BeginQuest.

return function(GB)
	local M = {
		lastTalk = {},
		lastClick = 0,
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
		Unlock = true,
		["Deliver Object"] = true,
		["Reach Maple Village"] = true,
		["Investigate The Footsteps (1)"] = true,
		["Investigate The Footsteps (2)"] = true,
		["Investigate The Wreckage"] = true,
		["Investigate The Beast's Den"] = true,
		["Investigate The Garden"] = true,
		["Investigate The Fountain"] = true,
		Defend = true,
	}

	local function guiText(inst)
		return GB.State.guiText(inst)
	end

	local function isDecline(t)
		if type(t) ~= "string" then
			return false
		end
		for bad in pairs(DECLINE) do
			if string.find(t, bad, 1, true) then
				return true
			end
		end
		return false
	end

	local function isAcceptText(t)
		if type(t) ~= "string" then
			return false
		end
		if string.find(t, "Accept", 1, true) then
			return true
		end
		if string.find(t, "Thank", 1, true) then
			return true
		end
		if string.find(t, "Yes", 1, true) then
			return true
		end
		-- Officer Graves Dialogue.Definition FirstAgree — Introduction first node
		if string.find(t, "I can help change that", 1, true) then
			return true
		end
		return false
	end

	local function dialogueOpen()
		local pg = GB.lp and GB.lp.PlayerGui
		local ui = pg and pg:FindFirstChild("DialogueUI")
		if not ui then
			return false
		end
		if ui:IsA("LayerCollector") and ui.Enabled ~= true then
			return false
		end
		local main = ui:FindFirstChild("Main")
		if main then
			for _, frame in ipairs(main:GetChildren()) do
				if frame:IsA("Frame") and frame:FindFirstChildWhichIsA("GuiButton", true) then
					return true
				end
			end
		end
		return ui:IsA("LayerCollector") and ui.Enabled == true
	end

	-- Choices live in DialogueUI.Main as cloned NodeFrames. ImageButton has no .Text;
	-- label is sibling TextLabel. Template under DialogueHandler.NodeFrame is not clickable.
	local function clickAccept()
		local pg = GB.lp and GB.lp.PlayerGui
		local ui = pg and pg:FindFirstChild("DialogueUI")
		if not ui then
			return false
		end
		local main = ui:FindFirstChild("Main")
		if not main then
			return false
		end
		local candidates = {}
		for _, frame in ipairs(main:GetChildren()) do
			if frame:IsA("Frame") then
				local btn = frame:FindFirstChild("ImageButton")
				if btn and btn:IsA("GuiButton") then
					local t = guiText(frame) or guiText(btn) or ""
					if not isDecline(t) then
						local num = frame:FindFirstChild("Number")
						local ntext = ""
						if num and (num:IsA("TextLabel") or num:IsA("TextButton") or num:IsA("TextBox")) then
							ntext = num.Text
						end
						candidates[#candidates + 1] = {
							btn = btn,
							text = t,
							first = frame.Name == "1" or frame.Name == 1 or (type(ntext) == "string" and string.sub(ntext, 1, 1) == "1"),
							glow = frame:FindFirstChild("Quest Glow") ~= nil,
						}
					end
				end
			end
		end
		local pick
		for _, c in ipairs(candidates) do
			if isAcceptText(c.text) or c.glow then
				pick = c
				break
			end
		end
		if not pick then
			for _, c in ipairs(candidates) do
				if c.first then
					pick = c
					break
				end
			end
		end
		pick = pick or candidates[1]
		if not pick then
			return false
		end
		local shown = pick.text
		if shown == "" then
			shown = pick.btn.Name
		end
		GB.Log.log("QUEST", "Click " .. tostring(shown))
		return GB.State.clickGui(pick.btn)
	end

	local function clickPlayerGuiPath(path)
		local pg = GB.lp and GB.lp.PlayerGui
		if not (pg and type(path) == "string") then
			return false
		end
		local cur = pg
		for part in string.gmatch(path, "[^%.]+") do
			cur = cur:FindFirstChild(part)
			if not cur then
				return false
			end
		end
		if cur:IsA("GuiButton") then
			return GB.State.clickGui(cur)
		end
		local btn = cur:FindFirstChildWhichIsA("GuiButton", true)
		return btn and GB.State.clickGui(btn)
	end

	local function layerOn(name)
		local pg = GB.lp and GB.lp.PlayerGui
		local ui = pg and pg:FindFirstChild(name)
		return ui and ui:IsA("LayerCollector") and ui.Enabled == true
	end

	-- ForceOpenLogbook sequence + OpenLogbookHelp:FireServer
	local function openLogbook()
		if not layerOn("Menu") then
			clickPlayerGuiPath("TopbarStandard.Holders.Left.Menu")
			task.wait(0.2)
		end
		if not layerOn("Logbook") then
			clickPlayerGuiPath("Menu.ContainerFrame.Icons.Logbook")
			task.wait(0.25)
		end
		clickPlayerGuiPath("Logbook.Frame.IndexContainer.ScrollingFrame.Tutorial")
		task.wait(0.2)
		clickPlayerGuiPath("Logbook.Frame.Left.Tutorial.Controls")
		task.wait(0.15)
		local ok = GB.Remotes.openLogbookHelp()
		GB.Log.log("QUEST", "Open Logbook")
		return ok or layerOn("Logbook")
	end

	local function goTagged(tag, dist)
		if not tag or tag == "" then
			return false
		end
		local inst = GB.Resolver.taggedAny and GB.Resolver.taggedAny(tag)
		if not inst then
			inst = GB.Resolver.waitTagged(tag, 0.8)
		end
		if not inst then
			inst = GB.Resolver.byName(tag)
		end
		if not inst then
			GB.Log.warn("QUEST", "marker miss " .. tostring(tag))
			return false
		end
		if GB.World.interact then
			GB.World.interact(inst, dist or 10)
		else
			GB.World.ToInteractable(inst, dist or 10)
			local pr = GB.Resolver.prompt(inst)
			if pr then
				GB.World.firePrompt(pr)
			end
		end
		GB.Remotes.enterZone(tag)
		return true
	end

	function M.condProgress(cond)
		return GB.QuestData.conditionCurrent(cond), GB.QuestData.conditionAmount(cond)
	end

	local function inferObjective(name)
		local pg = GB.lp and GB.lp.PlayerGui
		if not pg then
			return nil
		end
		local blob = {}
		for _, d in ipairs(pg:GetDescendants()) do
			if (d:IsA("TextLabel") or d:IsA("TextButton")) and type(d.Text) == "string" and d.Text ~= "" then
				blob[#blob + 1] = d.Text
			end
		end
		local text = table.concat(blob, "\n")
		if name == "Basics" then
			if string.find(text, "skill scroll", 1, true) or string.find(text, "Equip Skill", 1, true) or string.find(text, "Equip your new skill", 1, true) or string.find(text, "Equip the skill", 1, true) then
				return { Type = "EquipSkill", TargetName = "Strong Punch", Current = 0, Amount = 1, Complete = false, Raw = { Type = "EquipSkill", Target = { Name = "Strong Punch", Amount = 0, RequiredAmount = 1 } } }
			end
			if string.find(text, "Use Skill", 1, true) or string.find(text, "Cast the skill", 1, true) or string.find(text, "Use your Strong Punch", 1, true) then
				return { Type = "Cast", TargetName = "Strong Punch", Current = 0, Amount = 1, Complete = false, Raw = { Type = "Cast", Target = { Name = "Strong Punch", Amount = 0, RequiredAmount = 1 } } }
			end
			if string.find(text, "Invest", 1, true) and string.find(text, "stat", 1, true) then
				return { Type = "Required", TargetName = "TotalStatPoints", Current = 0, Amount = 1, Complete = false, Raw = { Type = "Required", Target = { Name = "TotalStatPoints", Amount = 0, RequiredAmount = 1 } } }
			end
			if string.find(text, "logbook", 1, true) or string.find(text, "Logbook", 1, true) then
				return { Type = "Open", TargetName = "Logbook", Current = 0, Amount = 1, Complete = false, Raw = { Type = "Open", Target = { Name = "Logbook", Amount = 0, RequiredAmount = 1 } } }
			end
		end
		if name == "Introduction" then
			if string.find(text, "Press Q", 1, true) then
				return { Type = "Dash", TargetName = "", Current = 0, Amount = 2, Complete = false, Raw = { Type = "Dash", Target = { Name = "", Amount = 0, RequiredAmount = 2 } } }
			end
			if string.find(text, "Hold F", 1, true) then
				return { Type = "Block", TargetName = "", Current = 0, Amount = 1, Complete = false, Raw = { Type = "Block", Target = { Name = "", Amount = 0, RequiredAmount = 1 } } }
			end
			if string.find(text, "dummy", 1, true) or string.find(text, "Dummy", 1, true) then
				return { Type = "Hit", TargetName = "Training Dummy", Current = 0, Amount = 4, Complete = false, Raw = { Type = "Hit", Target = { Name = "Training Dummy", Amount = 0, RequiredAmount = 4 } } }
			end
		end
		return nil
	end

	function M.questState(name)
		local live = GB.PlayerData.live(name)
		local island = GB.QuestData.islandOf(name)
		local npc = GB.QuestData.talkNpc(name)
		if not live then
			local inferred = GB.PlayerData.current() == name and inferObjective(name)
			if inferred then
				return {
					Name = name,
					IsAccepted = true,
					IsComplete = false,
					CanTurnIn = false,
					Automatic = GB.QuestData.AUTOMATIC[name] == true,
					NPC = npc,
					Island = island,
					StageIndex = inferred.Type,
					Objective = inferred,
				}
			end
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
			GB.Recovery.run("quest:" .. name)
			if GB.DumpRuntimeIssue then
				GB.DumpRuntimeIssue()
			end
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

		if dialogueOpen() then
			if os.clock() - (M.lastClick or 0) < 0.7 then
				return false, "rate"
			end
			local clicked = clickAccept()
			if clicked then
				M.lastClick = os.clock()
			end
			return clicked, clicked and "advance" or "waiting"
		end

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
		if clickAccept() then
			M.lastClick = os.clock()
		end
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
		if typ == "Shoot" then
			local before = M.questState(questName)
			local beforeCur = before.Objective and before.Objective.Current or 0
			local ok, why = GB.Combat.shootUntilCredit(target or "Training Dummy", questName, 24)
			if GB.PlayerData.invalidateLive then
				GB.PlayerData.invalidateLive()
			end
			local after = M.questState(questName)
			if after.IsComplete or (after.Objective and after.Objective.Current and after.Objective.Current > beforeCur) or after.StageIndex ~= before.StageIndex then
				M.noteOk(questName)
				return true
			end
			if why == "quest_done" then
				M.noteOk(questName)
				return true
			end
			if not ok then
				local pos = GB.Resolver.lastDummyPos and GB.Resolver.lastDummyPos()
				if pos and GB.World.destOk(pos) then
					GB.World.setPos(pos + Vector3.new(GB.Config.ShootRange or 9, 0, 0))
				elseif before.Island then
					GB.World.pullStream(before.Island)
				end
				M.noteFail(questName, "shoot miss " .. tostring(target))
			end
			return false
		end
		if typ == "Kill" or typ == "Defeat" or typ == "Hit" or typ == "Destroy" then
			local before = M.questState(questName)
			local beforeCur = before.Objective and before.Objective.Current or 0
			local ok, why = false, nil
			if GB.Combat.huntUntilDead then
				ok, why = GB.Combat.huntUntilDead(target or "Training Dummy", 16, questName)
			else
				ok = GB.Combat.attack(target or "Training Dummy", questName)
			end
			if not ok then
				local pos = GB.Resolver.lastDummyPos and GB.Resolver.lastDummyPos()
				local misses = GB.Resolver.dummyMissCount and GB.Resolver.dummyMissCount() or 0
				if misses >= 3 then
					if pos and GB.World.destOk(pos) then
						GB.World.setPos(pos + Vector3.new(GB.Config.DummyBeside or 3.2, 0, 0))
					elseif before.Island then
						GB.World.pullStream(before.Island)
					end
				end
				if why ~= "dead" then
					M.noteFail(questName, "resolve miss " .. tostring(target))
				end
				return false
			end
			if GB.PlayerData.invalidateLive then
				GB.PlayerData.invalidateLive()
			end
			local after = M.questState(questName)
			if after.IsComplete or (after.Objective and after.Objective.Current and after.Objective.Current > beforeCur) or after.StageIndex ~= before.StageIndex then
				M.noteOk(questName)
				return true
			end
			if why == "quest_done" then
				M.noteOk(questName)
				return true
			end
			if why == "dead" then
				return true
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
			local qs = M.questState(questName)
			local before = M.signature(qs)
			if GB.Tutorial and GB.Tutorial.IsBlocking and select(1, GB.Tutorial.IsBlocking()) then
				GB.Tutorial.ExecuteCurrentStep()
				local progressed = M.waitProgress(questName, before, 2.2)
				if progressed then
					M.noteOk(questName)
					return true
				end
				return false
			end
			local st = GB.Equipment.equipmentState and GB.Equipment.equipmentState(target)
			if st and (st.Held or st.Equipped) and not st.QuestCredited then
				GB.Log.log("EQUIP", tostring(target) .. " equipped but quest not credited")
				GB.Log.log("GATE", "Inspecting tutorial state")
				if GB.Tutorial and GB.Tutorial.ExecuteCurrentStep then
					GB.Tutorial.ExecuteCurrentStep()
				elseif GB.Equipment.equipViaBackpack then
					GB.Equipment.equipViaBackpack(target)
				end
				local progressed = M.waitProgress(questName, before, 2.2)
				if progressed then
					M.noteOk(questName)
					return true
				end
				return false
			end
			local needUi = GB.Equipment.needsGearSlot and GB.Equipment.needsGearSlot(target)
			local ok = GB.Equipment.equipNamed(target, { QuestEquip = needUi, Mode = needUi and "UI_EQUIP" or "DIRECT_EQUIP" })
			if ok then
				local progressed = M.waitProgress(questName, before, 2.4)
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
								"Equip %s %s/%s -> %s/%s",
								tostring(target),
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
				GB.Log.log("EQUIP", "action ok quest not credited " .. tostring(target))
				if GB.Tutorial and GB.Tutorial.IsBlocking and select(1, GB.Tutorial.IsBlocking()) then
					GB.Log.log("GATE", "Inspecting tutorial state")
					return false
				end
			end
			return ok
		end
		if typ == "Upgrade" then
			GB.Combat.stopLock()
			local qs = M.questState(questName)
			local before = M.signature(qs)
			local anvil = GB.Resolver.taggedAny("Anvil") or GB.Resolver.byName("Anvil")
			if anvil and GB.World.interact then
				GB.World.interact(anvil, 8)
			end
			clickPlayerGuiPath("Blacksmith.Blacksmith.ScrollingFrame.FlintlockHolder.Flintlock")
			task.wait(0.15)
			clickPlayerGuiPath("Blacksmith.Blacksmith.Upgrade.UpgradeButton")
			local ok = GB.Equipment.upgradeNamed(target)
			if ok then
				local progressed = M.waitProgress(questName, before, 2.4)
				if progressed then
					M.noteOk(questName)
					return true
				end
			end
			return ok
		end
		if typ == "EquipSkill" then
			GB.Combat.stopLock()
			if GB.State.tutorialOverlayVisible() then
				GB.State.dismissTutorialOverlay()
				return false
			end
			local qs = M.questState(questName)
			local before = M.signature(qs)
			local ok = GB.Skills.equip(target)
			if ok then
				local progressed = M.waitProgress(questName, before, 2.4)
				if progressed then
					M.noteOk(questName)
					return true
				end
				if GB.State.tutorialOverlayVisible() then
					GB.State.dismissTutorialOverlay()
					return false
				end
				M.noteFail(questName, "equipskill not credited " .. tostring(target))
			end
			return ok
		end
		if typ == "Cast" then
			GB.Combat.stopLock()
			if GB.State.tutorialOverlayVisible() then
				GB.State.dismissTutorialOverlay()
				return false
			end
			local qs = M.questState(questName)
			local before = M.signature(qs)
			local ok = GB.Skills.cast(target)
			if ok then
				local progressed = M.waitProgress(questName, before, 2.4)
				if progressed then
					M.noteOk(questName)
					return true
				end
				if GB.State.tutorialOverlayVisible() then
					GB.State.dismissTutorialOverlay()
					return false
				end
				M.noteFail(questName, "cast not credited " .. tostring(target))
			end
			return ok
		end
		if typ == "Required" and target == "TotalStatPoints" then
			return GB.Stats.investMinimum(1)
		end
		if typ == "Required" and target == "Level" then
			return false
		end
		if typ == "Loot" then
			GB.Combat.stopLock()
			local qs = M.questState(questName)
			local before = M.signature(qs)
			local need = GB.QuestData.conditionAmount(cond) or 5
			GB.Log.log("QUEST", "Loot " .. tostring(target))
			local ok = GB.Chest and GB.Chest.lootUntil and GB.Chest.lootUntil(questName, need)
			if ok then
				M.waitProgress(questName, before, 1.2)
				local after = M.questState(questName)
				if after.IsComplete or after.StageIndex ~= qs.StageIndex then
					M.noteOk(questName)
					return true
				end
				if after.Objective and (after.Objective.Current or 0) > ((qs.Objective and qs.Objective.Current) or 0) then
					M.noteOk(questName)
					return true
				end
			end
			M.noteFail(questName, "loot miss " .. tostring(target))
			return false
		end
		if typ == "Collect" or typ == "CollectLocal" or typ == "CollectLocalItem" then
			if GB.Planner and GB.Planner.execute then
				local qs = M.questState(questName)
				local plan = GB.Planner.build(qs)
				if plan and plan.Goal == "AcquireItem" then
					return GB.Planner.execute(qs, plan)
				end
			end
			if GB.Acquire then
				return GB.Acquire.AcquireItem(target, GB.QuestData.conditionAmount(cond), {
					Quest = questName,
					Type = typ,
				})
			end
			GB.Log.warn("QUEST", "collect miss " .. tostring(target))
			return false
		end
		if typ == "Mine" then
			if not GB.PlayerData.hasItem("Rusty Pickaxe") then
				M.ensureItem("Rusty Pickaxe")
			end
			return GB.LifeSkills.mineToward(target)
		end
		if typ == "Smelt" then
			GB.Combat.stopLock()
			local qs = M.questState(questName)
			local before = M.signature(qs)
			local ok = GB.LifeSkills.smeltToward and GB.LifeSkills.smeltToward(target)
			if ok then
				clickPlayerGuiPath("Crafting.Frame.Recipes.Inventory.Scroll.Copper Bar")
				task.wait(0.15)
				clickPlayerGuiPath("Crafting.Frame.Ingredients.Craft")
				local progressed = M.waitProgress(questName, before, 2.4)
				if progressed then
					M.noteOk(questName)
					return true
				end
			end
			return ok
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
		if typ == "Reach" or typ == "Travel" or (type(typ) == "string" and string.sub(typ, 1, 6) == "Reach ") then
			local island = target
			if typ == "Reach Maple Village" or island == "" or not island then
				island = "Maple Village"
			end
			local tag = GB.QuestData.markerOf(typ, target)
			if tag and tag ~= island then
				goTagged(tag, 16)
			end
			return GB.Travel.goIsland(island)
		end
		if typ == "Unlock" then
			GB.Combat.stopLock()
			local tag = GB.QuestData.markerOf(typ, target) or target
			local qs = M.questState(questName)
			local before = M.signature(qs)
			local beforeCur = (qs.Objective and qs.Objective.Current) or 0
			local inst = GB.Resolver.taggedAny and GB.Resolver.taggedAny(tag)
			if not inst then
				inst = GB.Resolver.waitTagged and GB.Resolver.waitTagged(tag, 0.8)
			end
			if not inst then
				inst = GB.Resolver.byName(tag)
			end
			if not inst then
				M.noteFail(questName, "unlock miss " .. tostring(tag))
				return false
			end
			local keyName = inst:GetAttribute("Key")
			if keyName and not GB.PlayerData.hasItem(keyName) then
				M.noteFail(questName, "need key " .. tostring(keyName))
				return false
			end
			GB.Log.log("QUEST", "Unlock " .. tostring(target))
			local fired = GB.World.interact and GB.World.interact(inst, 4)
			if not fired then
				GB.World.ToInteractable(inst, 4)
				local pr = GB.Resolver.prompt(inst)
				if pr then
					GB.World.firePrompt(pr, pr.HoldDuration or 0, inst)
					fired = true
				end
			end
			local progressed = M.waitProgress(questName, before, 2.8)
			if not progressed then
				local pr = GB.Resolver.prompt(inst)
				if pr then
					GB.World.firePrompt(pr, pr.HoldDuration or 0, inst)
					progressed = M.waitProgress(questName, before, 1.6)
				end
			end
			if progressed then
				local after = M.questState(questName)
				local nextCur = beforeCur
				if after.IsComplete or after.StageIndex ~= qs.StageIndex then
					nextCur = (qs.Objective and qs.Objective.Amount) or 1
				elseif after.Objective then
					nextCur = after.Objective.Current or nextCur
				end
				GB.Log.log("QUEST", string.format("Unlock credited %s/1 -> %s/1", tostring(beforeCur), tostring(nextCur)))
				M.noteOk(questName)
				return true
			end
			M.noteFail(questName, "unlock not credited " .. tostring(target))
			return false
		end
		if typ == "Deliver Object" then
			GB.Combat.stopLock()
			local spec = GB.QuestData.deliverSpec(target)
			if spec then
				goTagged(spec.object, 12)
				task.wait(0.3)
				return goTagged(spec.location, 12)
			end
			return goTagged(target, 12)
		end
		if type(typ) == "string" and string.sub(typ, 1, 11) == "Investigate" then
			GB.Combat.stopLock()
			return goTagged(GB.QuestData.markerOf(typ, target) or target, 10)
		end
		if typ == "Defend" then
			if not M.unknown[questName .. "Defend"] then
				M.unknown[questName .. "Defend"] = true
				GB.Log.err("QUEST", "UNKNOWN_OBJECTIVE Defend " .. tostring(target) .. " — skip")
			end
			return false
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
				if GB.World.interact then
					GB.World.interact(obj, 8)
				else
					GB.World.ToInteractable(obj, 8)
					local pr = GB.Resolver.prompt(obj)
					if pr then
						GB.World.firePrompt(pr)
					end
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
		if typ == "Dash" then
			GB.Combat.stopLock()
			local qs = M.questState(questName)
			local before = M.signature(qs)
			local ok = GB.Combat.dash()
			if ok then
				local progressed = M.waitProgress(questName, before, 2.2)
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
				M.noteFail(questName, "dash not credited")
			else
				M.noteFail(questName, "dash blocked")
			end
			return false
		end
		if typ == "Block" then
			GB.Combat.stopLock()
			local qs = M.questState(questName)
			local before = M.signature(qs)
			local ok = GB.Combat.block(0.7)
			if ok then
				local progressed = M.waitProgress(questName, before, 2.2)
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
				M.noteFail(questName, "block not credited")
			else
				M.noteFail(questName, "block blocked")
			end
			return false
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
			if GB.Persist and GB.Persist.checkpoint then
				GB.Persist.checkpoint("quest", name)
				GB.Persist.checkpoint("stage", qs.StageIndex)
			end
			GB.Log.log("QUEST", string.format("%s stage=%s", name, tostring(qs.StageIndex or "-")))
			if qs.Objective then
				GB.Log.log(
					"QUEST",
					string.format("Objective %s %s", string.upper(tostring(qs.Objective.Type or "?")), tostring(qs.Objective.TargetName or ""))
				)
				local ot = qs.Objective.Type
				if ot == "Dash" or ot == "Block" or ot == "EquipSkill" or ot == "Cast" or ot == "Required" or ot == "Open" then
					GB.Combat.stopLock()
				end
			end
		end

		if qs.IsComplete then
			M.noteOk(name)
			return true
		end

		if qs.Objective then
			if GB.State.tutorialOverlayVisible() then
				GB.State.dismissTutorialOverlay()
				return false
			end
			if GB.Tutorial and GB.Tutorial.IsBlocking and select(1, GB.Tutorial.IsBlocking()) then
				return GB.Tutorial.ExecuteCurrentStep()
			end
			local typ = qs.Objective.Type
			if typ and not HANDLED[typ] then
				if not M.unknown[name .. tostring(typ)] then
					M.unknown[name .. tostring(typ)] = true
					GB.Log.err("QUEST", "UNKNOWN_OBJECTIVE " .. tostring(typ) .. " " .. tostring(qs.Objective.TargetName))
				end
				t.NextRetryAt = os.clock() + 6
				return false
			end
			if GB.Planner then
				local plan = GB.Planner.build(qs)
				if plan then
					return GB.Planner.execute(qs, plan)
				end
			end
			return M.handleCondition(name, qs.Objective.Raw, qs.Stage)
		end

		if qs.NPC then
			if GB.State.tutorialOverlayVisible() then
				GB.State.dismissTutorialOverlay()
				return false
			end
			return M.talk(qs.NPC, false, { Quest = name, Island = qs.Island, DisplayName = qs.NPC })
		end
		return false
	end

	function M.Refresh()
		if GB.PlayerData and GB.PlayerData.refreshLive then
			GB.PlayerData.refreshLive(true)
		end
		local cur = GB.PlayerData and GB.PlayerData.current and GB.PlayerData.current()
		return cur and M.questState(cur) or nil
	end

	return M
end
