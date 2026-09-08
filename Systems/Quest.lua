-- Generic executor: GetLiveQuest → Stage → ParseObjective → Resolve → Execute → Validate.
-- Talk: ClientQuest("Talk", DisplayName) + DialogueBindable(Configuration). Never BeginQuest.

return function(GB)
	local M = {
		lastTalk = {},
		lastClick = 0,
		track = {},
		unknown = {},
		lastSig = {},
		diagByFingerprint = {},
		detailByFingerprint = {},
		deferUntil = {},
		deferReason = {},
		acceptState = {},
	}

	M.STATUS = {
		READY = "READY",
		IN_PROGRESS = "IN_PROGRESS",
		BLOCKED_REQUIREMENT = "BLOCKED_REQUIREMENT",
		DEFERRED = "DEFERRED",
		COMPLETE = "COMPLETE",
		UNRESOLVED = "UNRESOLVED",
	}

	local DETAIL_DUMP_GAP = 45
	local DIAG_DUMP_GAP = 45
	local TRACK_LIMIT = 96
	local FAIL_FINGERPRINT_GAP = 1.2
	local FAIL_DEFER_GAP = 30

	local function respawnBusy()
		return GB.Respawn and GB.Respawn.isBusy and GB.Respawn.isBusy() == true
	end

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

	local DECLINE_EXACT = {
		["no"] = true,
		["decline"] = true,
		["cancel"] = true,
		["bye"] = true,
		["goodbye"] = true,
		["never mind"] = true,
		["not now"] = true,
	}

	local DECLINE_PHRASES = {
		["good luck with that"] = true,
	}

	local COMMAND_HINT_KEYS = {
		"Command",
		"DialogueCommand",
		"Action",
		"Response",
		"ResponseType",
		"ChoiceType",
		"NodeType",
		"QuestName",
		"QuestId",
		"Quest",
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

	local function normalizeChoiceText(t)
		if type(t) ~= "string" then
			return "", ""
		end
		local low = string.lower(t)
		low = low:gsub("[%c\r\n\t]+", " ")
		low = low:gsub("%s+", " ")
		low = low:gsub("^%s+", "")
		low = low:gsub("%s+$", "")
		local compact = low:gsub("[%p]+", "")
		compact = compact:gsub("%s+", " ")
		compact = compact:gsub("^%s+", "")
		compact = compact:gsub("%s+$", "")
		return low, compact
	end

	local function isAcceptText(t)
		if type(t) ~= "string" then
			return false
		end
		local low = string.lower(t)
		if string.find(low, "accept", 1, true) then
			return true
		end
		if string.find(low, "thank", 1, true) then
			return true
		end
		if string.find(low, "yes", 1, true) then
			return true
		end
		if string.find(low, "yeah", 1, true) then
			return true
		end
		if string.find(low, "i can help change that", 1, true) then
			return true
		end
		if string.find(low, "upgrade my flintlock", 1, true) then
			return true
		end
		if string.find(low, "i need you", 1, true) then
			return true
		end
		return false
	end

	local function collectCommandHints(frame, btn)
		local hints = {}
		local function push(v)
			if type(v) ~= "string" then
				return
			end
			local low, compact = normalizeChoiceText(v)
			if low ~= "" then
				hints[low] = true
			end
			if compact ~= "" then
				hints[compact] = true
			end
		end
		local function scanInst(inst)
			if not inst then
				return
			end
			for _, key in ipairs(COMMAND_HINT_KEYS) do
				push(inst:GetAttribute(key))
			end
			local n = 0
			for _, c in ipairs(inst:GetChildren()) do
				if c:IsA("StringValue") then
					local key = string.lower(c.Name or "")
					if string.find(key, "command", 1, true)
						or string.find(key, "action", 1, true)
						or string.find(key, "choice", 1, true)
						or string.find(key, "quest", 1, true)
						or string.find(key, "node", 1, true)
					then
						push(c.Value)
						n = n + 1
						if n >= 8 then
							break
						end
					end
				end
			end
		end
		scanInst(frame)
		scanInst(btn)
		return hints
	end

	local function hintsContain(hints, token)
		if type(hints) ~= "table" or type(token) ~= "string" or token == "" then
			return false
		end
		for hint in pairs(hints) do
			if string.find(hint, token, 1, true) then
				return true
			end
		end
		return false
	end

	local function isVerifiedDecline(choice)
		if not choice then
			return false
		end
		if choice.glow or choice.commandAccept then
			return false
		end
		if choice.commandDecline and not choice.questLinked then
			return true
		end
		if DECLINE_EXACT[choice.textNorm] or DECLINE_EXACT[choice.textPlain] then
			return true
		end
		if DECLINE_PHRASES[choice.textNorm] or DECLINE_PHRASES[choice.textPlain] then
			return true
		end
		return false
	end

	local function guiShown(inst, stopAt)
		if not inst then
			return false
		end
		local cur = inst
		local hops = 0
		while cur and hops < 20 do
			hops = hops + 1
			if cur:IsA("LayerCollector") and cur.Enabled ~= true then
				return false
			end
			if cur:IsA("GuiObject") then
				if cur.Visible ~= true then
					return false
				end
				if cur.AbsoluteSize.X <= 1 or cur.AbsoluteSize.Y <= 1 then
					return false
				end
			end
			if cur == stopAt then
				break
			end
			cur = cur.Parent
		end
		return true
	end

	local function dialogueCandidates(opts)
		opts = opts or {}
		local expectQuest = type(opts.QuestName) == "string" and string.lower(opts.QuestName) or nil
		local pg = GB.lp and GB.lp.PlayerGui
		local ui = pg and pg:FindFirstChild("DialogueUI")
		if not ui then
			return {}, nil, nil
		end
		if ui:IsA("LayerCollector") and ui.Enabled ~= true then
			return {}, ui, nil
		end
		local main = ui:FindFirstChild("Main")
		if not main or not guiShown(main, ui) then
			return {}, ui, main
		end
		local candidates = {}
		for _, frame in ipairs(main:GetChildren()) do
			if frame:IsA("Frame") and guiShown(frame, ui) then
				local btn = frame:FindFirstChild("ImageButton")
				if btn and btn:IsA("GuiButton") and guiShown(btn, ui) then
					local t = guiText(frame) or guiText(btn) or ""
					local tn, tp = normalizeChoiceText(t)
					local num = frame:FindFirstChild("Number")
					local ntext = ""
					if num and (num:IsA("TextLabel") or num:IsA("TextButton") or num:IsA("TextBox")) then
						ntext = num.Text
					end
					local hints = collectCommandHints(frame, btn)
					local questLinked = frame:FindFirstChild("Quest Glow") ~= nil
						or hintsContain(hints, "quest")
						or (expectQuest and string.find(tn, expectQuest, 1, true) ~= nil)
					local row = {
						btn = btn,
						frame = frame,
						text = t,
						textNorm = tn,
						textPlain = tp,
						first = frame.Name == "1" or frame.Name == 1 or (type(ntext) == "string" and string.sub(ntext, 1, 1) == "1"),
						glow = frame:FindFirstChild("Quest Glow") ~= nil,
						questLinked = questLinked,
						commandAccept = hintsContain(hints, "accept")
							or hintsContain(hints, "begin")
							or hintsContain(hints, "start"),
						commandDecline = hintsContain(hints, "decline")
							or hintsContain(hints, "cancel")
							or hintsContain(hints, "close"),
					}
					row.verifiedDecline = isVerifiedDecline(row)
					candidates[#candidates + 1] = row
				end
			end
		end
		return candidates, ui, main
	end

	local function dialogueOpen()
		local rows = dialogueCandidates({})
		return #rows > 0
	end

	-- Choices live in DialogueUI.Main as cloned NodeFrames. ImageButton has no .Text;
	-- label is sibling TextLabel. Template under DialogueHandler.NodeFrame is not clickable.
	local function clickAccept(opts)
		opts = opts or {}
		local candidates = dialogueCandidates(opts)
		local function scoreChoice(c)
			if not c then
				return -1
			end
			local t = tostring(c.textNorm or "")
			local score = 0
			if c.commandAccept then
				score = score + 900
			end
			if c.glow then
				score = score + 700
			end
			if c.questLinked then
				score = score + 420
			end
			if c.commandDecline then
				score = score - 350
			end
			if c.verifiedDecline then
				score = score - 1400
			end
			if string.find(t, "i can help change that", 1, true) then
				score = score + 280
			end
			if string.find(t, "accept", 1, true) then
				score = score + 240
			end
			if string.find(t, "thank", 1, true) then
				score = score + 220
			end
			if string.find(t, "yes", 1, true) then
				score = score + 180
			end
			if string.find(t, "yeah", 1, true) then
				score = score + 170
			end
			if c.first then
				score = score + 80
			end
			if isAcceptText(t) then
				score = score + 40
			end
			return score
		end
		local pick, best = nil, -1e9
		for _, c in ipairs(candidates) do
			if c.verifiedDecline then
				continue
			end
			local s = scoreChoice(c)
			if s > best then
				best = s
				pick = c
			end
		end
		if not pick then
			for _, c in ipairs(candidates) do
				if c.first and not c.verifiedDecline then
					pick = c
					break
				end
			end
		end
		if not pick then
			for _, c in ipairs(candidates) do
				if not c.verifiedDecline then
					pick = c
					break
				end
			end
		end
		if not pick then
			return false
		end
		local shown = pick.text
		if shown == "" then
			shown = pick.btn.Name
		end
		GB.Log.log("QUEST", "choice \"" .. tostring(shown) .. "\"")
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

	local function rememberUnknown(key, line)
		if M.unknown[key] then
			return
		end
		M.unknown[key] = { at = os.clock() }
		local count = 0
		local dropKey
		local dropAt
		for k, v in pairs(M.unknown) do
			count = count + 1
			local at = type(v) == "table" and (v.at or 0) or 0
			if not dropAt or at < dropAt then
				dropAt = at
				dropKey = k
			end
		end
		if count > TRACK_LIMIT and dropKey then
			M.unknown[dropKey] = nil
		end
		GB.Log.err("QUEST", line)
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

	local function gateRequirement()
		local req = GB.QuestData and GB.QuestData.questRequirement and GB.QuestData.questRequirement("Gate of Authority")
		local need = tonumber(req and req.Strength) or 100
		return need, req
	end

	local function readStrength()
		if GB.Stats and GB.Stats.ReadStatState then
			local st = GB.Stats.ReadStatState()
			return tonumber(st and st.Strength) or 0
		end
		local snap = GB.State.get()
		return tonumber((snap and snap.Stats and snap.Stats.Strength) or 0)
	end

	local function resolveMarineGate()
		local pack = GB.Resolver.resolveObject and GB.Resolver.resolveObject("Marine Gate", {
			Island = "Anchor Town",
		})
		if pack and pack.Instance then
			local pr = GB.Resolver.prompt(pack.Instance, "Pushable Door") or GB.Resolver.prompt(pack.Instance)
			return pack.Instance, pr
		end
		local islands = workspace:FindFirstChild("Islands")
		local anchorTown = islands and islands:FindFirstChild("Anchor Town")
		local island = anchorTown and anchorTown:FindFirstChild("Island")
		local gate = island and island:FindFirstChild("Gate")
		if gate then
			local pr = GB.Resolver.prompt(gate, "Pushable Door") or GB.Resolver.prompt(gate)
			return gate, pr
		end
		return nil, nil
	end

	local function gateBlocker()
		local need = gateRequirement()
		local str = readStrength()
		if str < need then
			return true, string.format("Strength %d/%d", str, need), {
				Goal = "Gate of Authority",
				Type = "STAT_REQUIREMENT",
				Stat = "Strength",
				Required = need,
				Current = str,
				Status = M.STATUS.BLOCKED_REQUIREMENT,
			}
		end
		return false, nil, nil
	end

	-- Gate objective can be credit-on-open while nearby. Interact if possible, otherwise hold near the gate.
	local function waitAtMarineGate(questName, inst)
		local blocked, _, blocker = gateBlocker()
		if blocked then
			GB.Log.warn(
				"QUEST",
				string.format("Gate of Authority BLOCKED Strength=%d/%d", blocker.Current, blocker.Required)
			)
			return false, "blocked"
		end
		local qs = M.questState(questName)
		local before = M.signature(qs)
		local anchor = inst:FindFirstChild("Anchor")
		local stand = (anchor and anchor:IsA("BasePart") and anchor.Position)
			or select(1, GB.Resolver.promptAnchor(inst))
		if stand and GB.World.tweenTo then
			GB.World.tweenTo(stand, nil, { wait = true, range = 6 })
		elseif stand then
			GB.World.setPos(stand, { MaxGroundY = stand.Y + 8 })
		else
			GB.World.ToInteractable(inst, 6)
		end
		local pr = GB.Resolver.prompt(inst, "Pushable Door") or GB.Resolver.prompt(inst)
		if pr then
			GB.World.firePrompt(pr, pr.HoldDuration or 0, inst)
		elseif GB.World.interact then
			GB.World.interact(inst, 6)
		end
		if M.waitProgress(questName, before, 7.5) then
			M._gateWaitUntil = nil
			M.noteOk(questName)
			return true
		end
		M._gateWaitUntil = os.clock() + 18
		if not M._gateSealAt or os.clock() - M._gateSealAt > 8 then
			M._gateSealAt = os.clock()
			GB.Log.log("QUEST", "Gate still sealed, defer and run other goals")
		end
		return false
	end

	function M.keepTrying(name, err)
		if type(name) ~= "string" or name == "" then
			return false
		end
		if GB.QuestData and GB.QuestData.isRepeatable and GB.QuestData.isRepeatable(name) then
			return true
		end
		if GB.QuestData and GB.QuestData.hasDestroyStage and GB.QuestData.hasDestroyStage(name) then
			return true
		end
		if GB.QuestData and GB.QuestData.isHiddenKill and GB.QuestData.isHiddenKill(name) then
			return true
		end
		local qs = M.questState(name)
		local o = qs and qs.Objective
		if o and o.Type == "Destroy" then
			return true
		end
		if o and o.TargetName and GB.QuestData and GB.QuestData.isObjectTarget and GB.QuestData.isObjectTarget(o.TargetName) then
			return true
		end
		local miss = string.find(tostring(err or ""), "resolve miss", 1, true)
		if miss and GB.PlayerData and GB.PlayerData.live and GB.PlayerData.live(name) then
			return true
		end
		return false
	end

	function M.deferred(name)
		local untilAt = M.deferUntil[name]
		if untilAt and untilAt > os.clock() then
			local lastErr = M.track[name] and M.track[name].LastError
			if M.keepTrying(name, lastErr) then
				M.deferUntil[name] = nil
				M.deferReason[name] = nil
				return false
			end
			return true, M.deferReason[name] or "deferred_after_fail"
		end
		if name == "Gate of Authority" then
			local blocked, why = gateBlocker()
			if blocked then
				return true, why
			end
			if (M._gateWaitUntil or 0) > os.clock() then
				return true, "gate sealed waiting window"
			end
		end
		return false
	end

	function M.CurrentBlockers()
		local out = {}
		local names = GB.PlayerData.activeNames and GB.PlayerData.activeNames() or {}
		local cur = GB.PlayerData.current and GB.PlayerData.current() or nil
		if type(cur) == "string" and cur ~= "" and not table.find(names, cur) then
			names[#names + 1] = cur
		end
		for _, name in ipairs(names) do
			if name == "Gate of Authority" then
				local blocked, _, blocker = gateBlocker()
				if blocked and blocker then
					out[#out + 1] = blocker
				end
			end
		end
		return out
	end

	function M.questStatus(name)
		local qs = M.questState(name)
		if not qs then
			return M.STATUS.UNRESOLVED, "missing"
		end
		if qs.IsComplete and not qs.Repeatable then
			return M.STATUS.COMPLETE, nil
		end
		local blocked, why = M.deferred(name)
		if blocked then
			if why == "gate sealed waiting window" or why == "deferred_after_fail" then
				return M.STATUS.DEFERRED, why
			end
			return M.STATUS.BLOCKED_REQUIREMENT, why
		end
		if qs.IsAccepted then
			return M.STATUS.IN_PROGRESS, nil
		end
		return M.STATUS.READY, nil
	end

	function M.condProgress(cond)
		return GB.QuestData.conditionCurrent(cond), GB.QuestData.conditionAmount(cond)
	end

	local function collectGuiText(root, out, budget)
		if not (root and out and budget and budget > 0) then
			return budget or 0
		end
		for _, c in ipairs(root:GetChildren()) do
			if budget <= 0 then
				break
			end
			if (c:IsA("TextLabel") or c:IsA("TextButton") or c:IsA("TextBox")) and type(c.Text) == "string" and c.Text ~= "" then
				out[#out + 1] = c.Text
				budget = budget - 1
			end
			budget = collectGuiText(c, out, budget)
		end
		return budget
	end

	local function inferObjective(name)
		local now = os.clock()
		if M._inferName == name and M._inferObj and now - (M._inferAt or 0) < 1.1 then
			return M._inferObj
		end
		perfCount("QuestGuiScan", 1)
		local pg = GB.lp and GB.lp.PlayerGui
		if not pg then
			return nil
		end
		local gui = pg:FindFirstChild("Quests")
		if not gui then
			return nil
		end
		local blob = {}
		local details = gui:FindFirstChild("QuestDetails")
		local list = gui:FindFirstChild("Quest")
		local sf = list and list:FindFirstChild("ScrollingFrame")
		local budget = 90
		budget = collectGuiText(details, blob, budget)
		budget = collectGuiText(sf, blob, budget)
		budget = collectGuiText(gui:FindFirstChild("Frame"), blob, budget)
		local text = table.concat(blob, "\n")
		if name == "Basics" then
			if string.find(text, "skill scroll", 1, true) or string.find(text, "Equip Skill", 1, true) or string.find(text, "Equip your new skill", 1, true) or string.find(text, "Equip the skill", 1, true) then
				M._inferName = name
				M._inferAt = now
				M._inferObj = { Type = "EquipSkill", TargetName = "Strong Punch", Current = 0, Amount = 1, Complete = false, Raw = { Type = "EquipSkill", Target = { Name = "Strong Punch", Amount = 0, RequiredAmount = 1 } } }
				return M._inferObj
			end
			if string.find(text, "Use Skill", 1, true) or string.find(text, "Cast the skill", 1, true) or string.find(text, "Use your Strong Punch", 1, true) then
				M._inferName = name
				M._inferAt = now
				M._inferObj = { Type = "Cast", TargetName = "Strong Punch", Current = 0, Amount = 1, Complete = false, Raw = { Type = "Cast", Target = { Name = "Strong Punch", Amount = 0, RequiredAmount = 1 } } }
				return M._inferObj
			end
			if string.find(text, "Invest", 1, true) and string.find(text, "stat", 1, true) then
				M._inferName = name
				M._inferAt = now
				M._inferObj = { Type = "Required", TargetName = "TotalStatPoints", Current = 0, Amount = 1, Complete = false, Raw = { Type = "Required", Target = { Name = "TotalStatPoints", Amount = 0, RequiredAmount = 1 } } }
				return M._inferObj
			end
			if string.find(text, "logbook", 1, true) or string.find(text, "Logbook", 1, true) then
				M._inferName = name
				M._inferAt = now
				M._inferObj = { Type = "Open", TargetName = "Logbook", Current = 0, Amount = 1, Complete = false, Raw = { Type = "Open", Target = { Name = "Logbook", Amount = 0, RequiredAmount = 1 } } }
				return M._inferObj
			end
		end
		if name == "Introduction" then
			if string.find(text, "Press Q", 1, true) then
				M._inferName = name
				M._inferAt = now
				M._inferObj = { Type = "Dash", TargetName = "", Current = 0, Amount = 2, Complete = false, Raw = { Type = "Dash", Target = { Name = "", Amount = 0, RequiredAmount = 2 } } }
				return M._inferObj
			end
			if string.find(text, "Hold F", 1, true) then
				M._inferName = name
				M._inferAt = now
				M._inferObj = { Type = "Block", TargetName = "", Current = 0, Amount = 1, Complete = false, Raw = { Type = "Block", Target = { Name = "", Amount = 0, RequiredAmount = 1 } } }
				return M._inferObj
			end
			if string.find(text, "dummy", 1, true) or string.find(text, "Dummy", 1, true) then
				M._inferName = name
				M._inferAt = now
				M._inferObj = { Type = "Hit", TargetName = "Training Dummy", Current = 0, Amount = 4, Complete = false, Raw = { Type = "Hit", Target = { Name = "Training Dummy", Amount = 0, RequiredAmount = 4 } } }
				return M._inferObj
			end
		end
		local dest = string.match(text, "Destroy%s+([%w %'%-%\"]+)%s*%(")
		if dest then
			dest = string.gsub(dest, "%s+$", "")
			if dest ~= "" then
				M._inferName = name
				M._inferAt = now
				M._inferObj = {
					Type = "Destroy",
					TargetName = dest,
					Current = 0,
					Amount = 1,
					Complete = false,
					Raw = { Type = "Destroy", Target = { Name = dest, Amount = 0, RequiredAmount = 1 } },
				}
				return M._inferObj
			end
		end
		M._inferName = name
		M._inferAt = now
		M._inferObj = nil
		return nil
	end

	local function isRepeatable(name)
		return GB.QuestData and GB.QuestData.isRepeatable and GB.QuestData.isRepeatable(name) == true
	end

	function M.questState(name)
		local t0 = pbegin()
		local live = GB.PlayerData.live(name)
		local island = GB.QuestData.islandOf(name)
		local npc = GB.QuestData.talkNpc(name)
		local repeatable = isRepeatable(name)
		if not live then
			local inferred = GB.PlayerData.current() == name and inferObjective(name)
			if inferred then
				local out = {
					Name = name,
					IsAccepted = true,
					IsComplete = false,
					CanTurnIn = false,
					Automatic = GB.QuestData.AUTOMATIC[name] == true,
					Repeatable = repeatable,
					NPC = npc,
					Island = island,
					StageIndex = inferred.Type,
					Objective = inferred,
				}
				pdone("Quest.questState", t0)
				return out
			end
			local out = {
				Name = name,
				IsAccepted = false,
				IsComplete = (not repeatable) and GB.PlayerData.finished(name, true) or false,
				CanTurnIn = false,
				Automatic = GB.QuestData.AUTOMATIC[name] == true,
				Repeatable = repeatable,
				NPC = npc,
				Island = island,
				StageIndex = nil,
				Objective = nil,
			}
			pdone("Quest.questState", t0)
			return out
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
		local out = {
			Name = name,
			Live = live,
			IsAccepted = true,
			IsComplete = (not repeatable) and GB.PlayerData.finished(name, true) or false,
			CanTurnIn = canTurn,
			Automatic = GB.QuestData.AUTOMATIC[name] == true,
			Repeatable = repeatable,
			NPC = npc,
			Island = island,
			StageIndex = si,
			Stage = st,
			Objective = obj,
		}
		pdone("Quest.questState", t0)
		return out
	end

	function M.signature(qs)
		local o = qs.Objective
		if not o then
			return qs.Name .. "|turn|" .. tostring(qs.StageIndex)
		end
		return string.format("%s|%s|%s|%s/%s", qs.Name, tostring(qs.StageIndex), tostring(o.Type), tostring(o.Current), tostring(o.Amount))
	end

	local function capMap(map, maxN)
		local n = 0
		local dropKey
		local dropAt
		for k, v in pairs(map) do
			n = n + 1
			local at = 0
			if type(v) == "table" then
				at = tonumber(v.LastAt or v.LastDump or v.LastFingerprintAt or v.at) or 0
			else
				at = tonumber(v) or 0
			end
			if not dropAt or at < dropAt then
				dropAt = at
				dropKey = k
			end
		end
		if n > maxN and dropKey ~= nil then
			map[dropKey] = nil
		end
	end

	function M.trackOf(name)
		local t = M.track[name]
		if not t then
			t = {
				AttemptCount = 0,
				LastError = nil,
				NextRetryAt = 0,
				LastDump = 0,
				LastFingerprint = nil,
				LastFingerprintAt = 0,
				LastAt = os.clock(),
			}
			M.track[name] = t
			capMap(M.track, TRACK_LIMIT)
		end
		t.LastAt = os.clock()
		return t
	end

	function M.clearTrack(name)
		M.track[name] = nil
	end

	local function scopedResolveInvalidate(qs)
		if not GB.Cache then
			return
		end
		local invalidatePrefix = GB.Cache.invalidatePrefix
		if type(invalidatePrefix) ~= "function" then
			if GB.Cache.invalidate then
				GB.Cache.invalidate()
			end
			return
		end
		local o = qs and qs.Objective
		if not o then
			invalidatePrefix("res:")
			return
		end
		local typ = tostring(o.Type or "")
		if typ == "Talk" or typ == "Automatic Talk" then
			invalidatePrefix("res:npc:")
			return
		end
		if typ == "Kill" or typ == "Defeat" or typ == "Hit" or typ == "Shoot" then
			invalidatePrefix("res:enemy:")
			return
		end
		if typ == "Purchase" or typ == "Sell" then
			invalidatePrefix("shop:")
			return
		end
		invalidatePrefix("res:any:")
	end

	function M.noteFail(name, err)
		local t = M.trackOf(name)
		local now = os.clock()
		if now < t.NextRetryAt then
			return t
		end
		local qs = M.questState(name)
		local stage = qs and qs.StageIndex or "-"
		local action = qs and qs.Objective and qs.Objective.Type or "-"
		local fp = string.format("%s|%s|%s|%s", tostring(name), tostring(stage), tostring(action), tostring(err))
		if t.LastFingerprint == fp and now - (t.LastFingerprintAt or 0) < FAIL_FINGERPRINT_GAP then
			return t
		end
		t.LastFingerprint = fp
		t.LastFingerprintAt = now
		t.AttemptCount = t.AttemptCount + 1
		t.LastError = err
		t.NextRetryAt = now + 1.5
		GB.Log.warn("QUEST", string.format("%s fail #%d %s", name, t.AttemptCount, tostring(err)))
		local stay = M.keepTrying(name, err)
		if t.AttemptCount == 3 and not stay then
			scopedResolveInvalidate(qs)
			local target = qs and qs.Objective and qs.Objective.TargetName or (qs and qs.NPC)
			local lastDetail = M.detailByFingerprint[fp] or 0
			if now - lastDetail >= DETAIL_DUMP_GAP then
				M.detailByFingerprint[fp] = now
				capMap(M.detailByFingerprint, 192)
				if target then
					GB.Resolver.dumpNearby(target, { Island = qs and qs.Island, DisplayName = target })
					t.LastDump = now
				end
				if qs and qs.Island and GB.World.pullStream then
					GB.World.pullStream(qs.Island)
				end
			end
		end
		if stay and GB.Combat and GB.Combat.approachMarker then
			local target = qs and qs.Objective and qs.Objective.TargetName
			if target then
				GB.Combat.approachMarker({
					Marker = GB.QuestData and GB.QuestData.combatMarker and GB.QuestData.combatMarker(
						name,
						qs and qs.StageIndex,
						qs.Objective.Type,
						target
					) or target,
					Island = qs and qs.Island,
				}, target)
			end
		end
		if t.AttemptCount >= 2 and not isRepeatable(name) and not stay then
			local live = GB.PlayerData and GB.PlayerData.live and GB.PlayerData.live(name)
			if not live and GB.PlayerData and GB.PlayerData.markLocalDone then
				GB.PlayerData.markLocalDone(name, err)
			end
		end
		if t.AttemptCount >= 5 then
			if stay then
				t.AttemptCount = 0
				t.NextRetryAt = now + 1.1
				if not M._stayLog or M._stayLog ~= name or now - (M._stayAt or 0) > 8 then
					M._stayLog = name
					M._stayAt = now
					GB.Log.log("QUEST", "stay " .. tostring(name))
				end
				return t
			end
			local lastDiag = M.diagByFingerprint[fp] or 0
			if now - lastDiag >= DIAG_DUMP_GAP then
				M.diagByFingerprint[fp] = now
				capMap(M.diagByFingerprint, 192)
				GB.Log.err("QUEST", "STUCK " .. name .. " " .. tostring(err))
				GB.Recovery.run("quest:" .. name)
				if GB.DumpRuntimeIssue then
					GB.DumpRuntimeIssue()
				end
			end
			M.deferUntil[name] = now + FAIL_DEFER_GAP
			M.deferReason[name] = "deferred_after_fail"
			t.AttemptCount = 0
			t.NextRetryAt = now + 4
		end
		return t
	end

	function M.noteOk(name)
		if name == "Gate of Authority" then
			M._gateBlockedKey = nil
		end
		M.deferUntil[name] = nil
		M.deferReason[name] = nil
		M.acceptState[name] = nil
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

	local function setAcceptState(name, state, detail)
		if type(name) ~= "string" or name == "" then
			return
		end
		local key = tostring(state) .. "|" .. tostring(detail or "")
		if M.acceptState[name] == key then
			return
		end
		M.acceptState[name] = key
		GB.Log.log("QUEST", string.format("%s accept_state=%s", tostring(name), tostring(state)))
	end

	function M.talk(request, automatic, opts)
		opts = opts or {}
		local force = opts.Force == true
		local qsName = opts.Quest
		local island = opts.Island or (qsName and GB.QuestData.islandOf(qsName))
		local key = tostring(request)

		local openRows = dialogueCandidates(opts)
		if #openRows > 0 then
			if (not force) and os.clock() - (M.lastClick or 0) < 0.45 then
				return false, "rate"
			end
			local clicked = clickAccept(opts)
			if clicked then
				M.lastClick = os.clock()
				return true, "advance"
			end
			if not qsName then
				return false, "waiting"
			end
			local staleKey = tostring(qsName) .. "|" .. tostring(request)
			if M._dialogueStaleKey ~= staleKey or os.clock() - (M._dialogueStaleAt or 0) > 2.2 then
				M._dialogueStaleKey = staleKey
				M._dialogueStaleAt = os.clock()
				GB.Log.warn("QUEST", string.format("%s dialogue stale; re-open talk", tostring(qsName)))
			end
		end

		if (not force) and os.clock() - (M.lastTalk[key] or 0) < 1.8 then
			return false, "rate"
		end

		local function pushUnique(out, seen, v)
			if type(v) ~= "string" then
				return
			end
			v = string.gsub(v, "^%s+", "")
			v = string.gsub(v, "%s+$", "")
			if v == "" or seen[v] then
				return
			end
			seen[v] = true
			out[#out + 1] = v
		end

		local function talkNameList(base, pack)
			local out, seen = {}, {}
			pushUnique(out, seen, base)
			if pack then
				pushUnique(out, seen, pack.DisplayName)
				pushUnique(out, seen, pack.InternalName)
			end
			if GB.Resolver and GB.Resolver.baseName then
				pushUnique(out, seen, GB.Resolver.baseName(base))
				if pack then
					pushUnique(out, seen, GB.Resolver.baseName(pack.DisplayName))
					pushUnique(out, seen, GB.Resolver.baseName(pack.InternalName))
				end
			end
			if GB.Resolver and GB.Resolver.namesFor then
				for _, alt in ipairs(GB.Resolver.namesFor(base, opts) or {}) do
					pushUnique(out, seen, alt)
				end
			end
			return out
		end

		local function fireTalkVariants(names, cfg)
			local lastWhy = "none"
			for _, who in ipairs(names or {}) do
				GB.Log.log("QUEST", "Talking " .. tostring(who))
				local okTalk, whyTalk
				if automatic then
					okTalk, whyTalk = GB.Remotes.autoTalk(who)
				else
					okTalk, whyTalk = GB.Remotes.talk(who)
				end
				lastWhy = tostring(whyTalk or (okTalk and "sent" or "unknown"))
				if cfg then
					GB.Remotes.dialogueConfig(cfg)
				end
				local waitFor = okTalk and 1.8 or ((whyTalk == "rate") and 0.9 or 0.45)
				local untilAt = os.clock() + waitFor
				while os.clock() < untilAt do
					if respawnBusy() then
						return nil, "respawn"
					end
					if dialogueOpen() then
						return who, lastWhy
					end
					task.wait(0.1)
				end
			end
			return nil, lastWhy
		end

		local function findDialogueNpcPack(name, islandHint)
			if not (GB.Resolver and GB.Resolver.namesFor and GB.Resolver.pack and GB.Resolver.nameMatches) then
				return nil
			end
			local aa = workspace:FindFirstChild("AA IMPORTANT")
			local dlg = (aa and aa:FindFirstChild("DialogueNPCs")) or workspace:FindFirstChild("DialogueNPCs")
			if not dlg then
				return nil
			end
			local names = GB.Resolver.namesFor(name, opts) or { name }
			local roots = {}
			if type(islandHint) == "string" and islandHint ~= "" then
				local folder = dlg:FindFirstChild(islandHint)
				if folder then
					roots[#roots + 1] = folder
				end
			end
			roots[#roots + 1] = dlg
			local visited = {}
			local function walk(root, maxDepth)
				local queue = { { inst = root, depth = 0 } }
				local head = 1
				while head <= #queue do
					local row = queue[head]
					head = head + 1
					local inst = row.inst
					local depth = row.depth
					if inst ~= root and not visited[inst] then
						visited[inst] = true
						local shapeOk = inst:IsA("Model") or inst:IsA("Folder") or inst:IsA("BasePart")
						if shapeOk then
							local dialogLike = inst:GetAttribute("Interaction") == "Dialogue"
								or inst:FindFirstChild("Dialogue") ~= nil
								or inst:FindFirstChildOfClass("Humanoid") ~= nil
							if dialogLike and GB.Resolver.nameMatches(inst, names) then
								return GB.Resolver.pack(inst, name)
							end
						end
					end
					if depth < maxDepth then
						for _, ch in ipairs(inst:GetChildren()) do
							queue[#queue + 1] = { inst = ch, depth = depth + 1 }
						end
					end
				end
				return nil
			end
			for _, root in ipairs(roots) do
				local hit = walk(root, 6)
				if hit then
					return hit
				end
			end
			return nil
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
							deep = false,
						})
					end
				end
			end
		end
		if not pack then
			-- Island tags can be inconsistent for dialogue roots; retry without island filter.
			pack = GB.Resolver.resolveNPC(request, {
				DisplayName = opts.DisplayName or request,
				InternalName = opts.InternalName,
				QuestName = qsName,
				ExpectedRole = "npc",
				deep = false,
			})
		end
		if not pack and island and GB.Resolver and GB.World then
			local markerName = GB.QuestData and GB.QuestData.markerOf and GB.QuestData.markerOf("Talk", request) or request
			local marker = GB.Resolver.marker and GB.Resolver.marker(markerName, { Island = island }) or nil
			if marker then
				GB.Log.log("TRAVEL", "marker " .. tostring(markerName))
				GB.World.moveTo(marker, 10)
				if GB.World.pullStream then
					GB.World.pullStream(island)
				end
				pack = GB.Resolver.resolveNPC(request, {
					DisplayName = opts.DisplayName or request,
					InternalName = opts.InternalName,
					QuestName = qsName,
					Island = island,
					ExpectedRole = "npc",
					deep = false,
				})
			end
		end
		if not pack then
			pack = findDialogueNpcPack(request, island)
		end
		if not pack then
			local spoken, whyTalk = fireTalkVariants(talkNameList(request), nil)
			if spoken then
				task.wait(0.2)
				if clickAccept(opts) then
					M.lastClick = os.clock()
				end
				M.lastTalk[key] = os.clock()
				return true, spoken
			end
			if qsName then
				M.noteFail(qsName, "NPC miss " .. tostring(request))
			else
				GB.Log.warn("QUEST", "NPC miss " .. tostring(request))
			end
			return false, "resolve:" .. tostring(whyTalk or "none")
		end

		local shown = talkName(pack, request)
		if pack.Island and island and pack.Island ~= island and GB.Travel then
			GB.Travel.goIsland(island)
		end
		local alreadyThere = GB.World.atTalk and GB.World.atTalk(pack, GB.Config.TalkRange or 14)
		if not alreadyThere then
			if not GB.World.ToNPC(pack, GB.Config.TalkOffset or 5) then
				if not GB.World.moveTo(pack.Instance, GB.Config.TalkRange or 14) then
					return false, "travel"
				end
			end
			GB.World.waitUnpause()
			task.wait(0.25)
		end
		local cfg = GB.Resolver.dialogueConfig(pack.Instance)
		local spoken, whyTalk = fireTalkVariants(talkNameList(shown, pack), cfg)
		if not spoken then
			local lingerUntil = os.clock() + 2.4
			while os.clock() < lingerUntil do
				if dialogueOpen() then
					spoken = shown
					break
				end
				if clickAccept(opts) then
					spoken = shown
					M.lastClick = os.clock()
					break
				end
				task.wait(0.12)
			end
		end
		if not spoken and GB.World and GB.World.interact then
			GB.World.interact(pack.Instance, GB.Config.TalkRange or 14)
			task.wait(0.35)
			spoken, whyTalk = fireTalkVariants(talkNameList(shown, pack), cfg)
		end
		if not spoken then
			M.lastTalk[key] = os.clock()
			return false, "talk_no_dialogue:" .. tostring(whyTalk or "none")
		end
		task.wait(0.35)
		if clickAccept(opts) then
			M.lastClick = os.clock()
		end
		M.lastTalk[key] = os.clock()
		return true, spoken
	end

	local function questAcceptedNow(name)
		if type(name) ~= "string" or name == "" then
			return false
		end
		local live = GB.PlayerData and GB.PlayerData.live and GB.PlayerData.live(name)
		if live then
			return true
		end
		local qs = M.questState(name)
		return qs and qs.IsAccepted == true
	end

	local function waitQuestAccepted(name, timeout)
		timeout = timeout or 5.4
		local t0 = os.clock()
		local nextRefreshAt = 0
		while os.clock() - t0 < timeout do
			if respawnBusy() then
				return false, "respawn"
			end
			if questAcceptedNow(name) then
				return true, "accepted"
			end
			if dialogueOpen() and os.clock() - (M.lastClick or 0) >= 0.45 then
				if clickAccept({ QuestName = name, Action = "accept" }) then
					M.lastClick = os.clock()
				end
			end
			if os.clock() >= nextRefreshAt then
				nextRefreshAt = os.clock() + 0.9
				if GB.PlayerData and GB.PlayerData.forceQuestRefresh then
					GB.PlayerData.forceQuestRefresh("accept_wait:" .. tostring(name))
				elseif GB.PlayerData and GB.PlayerData.refreshLive then
					GB.PlayerData.refreshLive(true, "accept_wait:" .. tostring(name))
				end
			end
			task.wait(0.18)
		end
		return questAcceptedNow(name), "timeout"
	end

	function M.waitProgress(name, beforeSig, timeout)
		timeout = timeout or 2.8
		local t0 = os.clock()
		while os.clock() - t0 < timeout do
			if respawnBusy() then
				return false, "respawn"
			end
			task.wait(0.2)
			if (not isRepeatable(name)) and GB.PlayerData.finished(name, true) then
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

	local function waitTalkProgress(name, beforeSig, timeout)
		timeout = timeout or 5.6
		local t0 = os.clock()
		local lastClick = 0
		while os.clock() - t0 < timeout do
			if (not isRepeatable(name)) and GB.PlayerData.finished(name, true) then
				return true, "done"
			end
			local qs = M.questState(name)
			local sig = M.signature(qs)
			if sig ~= beforeSig then
				return true, sig
			end
			if dialogueOpen() and os.clock() - lastClick >= 0.55 then
				if clickAccept({ QuestName = name, Action = "progress" }) then
					lastClick = os.clock()
					M.lastClick = lastClick
				end
			end
			task.wait(0.18)
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

	local function pushTarget(list, seen, target)
		if type(target) ~= "string" or target == "" or target == "\\" then
			return
		end
		if seen[target] then
			return
		end
		seen[target] = true
		list[#list + 1] = target
	end

	local function unfinishedKillTargets(questName, stage, preferred)
		local out = {}
		local seen = {}
		pushTarget(out, seen, preferred)
		local conds = stage and (stage.Conditions or stage.conditions) or {}
		for _, row in ipairs(conds) do
			if type(row) == "table" and not GB.QuestData.conditionComplete(row) then
				local typ = row.Type or row.type
				if typ == "Kill" or typ == "Defeat" or typ == "Hit" or typ == "Destroy" then
					local name = GB.QuestData.conditionTarget(row)
					if typ == "Kill" or typ == "Defeat" then
						name = GB.QuestData.killName(questName, name)
					end
					pushTarget(out, seen, name)
				end
			end
		end
		return out
	end

	local function pickAvailableKillTarget(questName, stage, preferred)
		local targets = unfinishedKillTargets(questName, stage, preferred)
		if #targets <= 1 then
			return targets[1] or preferred, targets
		end
		for _, name in ipairs(targets) do
			local list = GB.Resolver and GB.Resolver.enemies and GB.Resolver.enemies(name)
			if type(list) == "table" and #list > 0 then
				return name, targets
			end
		end
		return targets[1], targets
	end

	function M.killTargetsFor(name)
		local qs = M.questState(name)
		if not (qs and qs.IsAccepted) then
			return {}
		end
		local preferred = qs.Objective and qs.Objective.TargetName
		return unfinishedKillTargets(name, qs.Stage, preferred)
	end

	function M.retryOpen(name)
		local t = M.track[name]
		return t ~= nil and t.LastError ~= nil and os.clock() < (t.NextRetryAt or 0)
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
			rememberUnknown(questName .. typ, "UNKNOWN_OBJECTIVE " .. tostring(typ) .. " " .. tostring(target))
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
				local progressed = waitTalkProgress(questName, before)
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
			if GB.PlayerData and GB.PlayerData.forceQuestRefresh then
				GB.PlayerData.forceQuestRefresh("shoot_credit")
			elseif GB.PlayerData and GB.PlayerData.refreshLive then
				GB.PlayerData.refreshLive(true, "shoot_credit")
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
			if dialogueOpen() then
				if GB.Combat and GB.Combat.stopLock then
					GB.Combat.stopLock()
				end
				if os.clock() - (M.lastClick or 0) >= 0.45 then
					if clickAccept({ QuestName = questName, Action = "progress" }) then
						M.lastClick = os.clock()
						M._afterDialogueAt = os.clock()
					end
				end
				return true
			end
			if M._afterDialogueAt and os.clock() - M._afterDialogueAt < 1.3 then
				return true
			end
			local before = M.questState(questName)
			local beforeCur = before.Objective and before.Objective.Current or 0
			local picked, targets = pickAvailableKillTarget(questName, stage, target)
			if picked and picked ~= target then
				GB.Log.log("QUEST", string.format("switch target %s -> %s", tostring(target), tostring(picked)))
			end
			local marker = GB.QuestData and GB.QuestData.combatMarker and GB.QuestData.combatMarker(
				questName,
				before.StageIndex,
				typ,
				picked or target
			) or nil
			local targetPlan = {
				Quest = questName,
				Target = picked or target or "Training Dummy",
				Island = before.Island,
				Marker = marker,
				Stage = before.StageIndex,
				ObjectiveType = typ,
				Alternatives = targets,
				SkipStream = true,
			}
			if GB.Combat and GB.Combat.lockMob and GB.Combat.IsEnemyAlive and GB.Combat.IsEnemyAlive(GB.Combat.lockMob) then
				if (not GB.Combat.lockMatchesNames) or GB.Combat.lockMatchesNames(targets) or GB.Combat.lockMatchesNames({ targetPlan.Target }) then
					return true
				end
			end
			local ok, why = false, nil
			if GB.Combat.hunt then
				ok = GB.Combat.hunt(targetPlan.Target, questName, targetPlan)
				why = ok and "engaged" or "no_enemy"
			elseif GB.Combat.attack then
				ok = GB.Combat.attack(targetPlan.Target, questName)
			end
			if not ok then
				if typ == "Destroy" then
					if GB.Combat and GB.Combat.approachMarker then
						GB.Combat.approachMarker(targetPlan, targetPlan.Target)
					end
				else
					local pos = GB.Resolver.lastDummyPos and GB.Resolver.lastDummyPos()
					local misses = GB.Resolver.dummyMissCount and GB.Resolver.dummyMissCount() or 0
					if misses >= 3 then
						if pos and GB.World.destOk(pos) then
							GB.World.setPos(pos + Vector3.new(GB.Config.DummyBeside or 3.2, 0, 0))
						elseif before.Island then
							GB.World.pullStream(before.Island)
						end
					end
				end
				if why ~= "dead" then
					M.noteFail(questName, "resolve miss " .. tostring(targetPlan.Target))
				end
				return false
			end
			if GB.PlayerData and GB.PlayerData.forceQuestRefresh then
				GB.PlayerData.forceQuestRefresh("kill_credit")
			elseif GB.PlayerData and GB.PlayerData.refreshLive then
				GB.PlayerData.refreshLive(true, "kill_credit")
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
			local spec = GB.QuestSpecs and GB.QuestSpecs.lookup(questName, nil, typ, target)
			if spec and spec.acquire == "ShopPurchase" then
				return GB.Shop.buy(target, GB.QuestData.conditionAmount(cond) or 1)
			end
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
			rememberUnknown(questName .. "Defend", "UNKNOWN_OBJECTIVE Defend " .. tostring(target) .. " — skip")
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
			if target == "Marine Gate" or questName == "Gate of Authority" then
				local blocked, _, blocker = gateBlocker()
				if blocked and blocker then
					local key = tostring(blocker.Current) .. "/" .. tostring(blocker.Required)
					if M._gateBlockedKey ~= key then
						M._gateBlockedKey = key
						GB.Log.warn(
							"QUEST",
							string.format("Gate of Authority BLOCKED Strength=%d/%d", blocker.Current, blocker.Required)
						)
						GB.Log.warn("QUEST", "deferring blocked quest")
					end
					return false
				end
				local gate = resolveMarineGate()
				if not gate then
					M.noteFail(questName, "gate unresolved")
					return false
				end
				return waitAtMarineGate(questName, gate)
			end
			local spec = GB.QuestSpecs and GB.QuestSpecs.lookup(questName, nil, typ, target)
			local tag = (spec and (spec.marker or spec.source)) or GB.QuestData.markerOf(typ, target) or target
			local objPack = GB.Resolver.resolveObject and GB.Resolver.resolveObject(tag, { Island = GB.QuestData.islandOf(questName) }) or nil
			local obj = objPack and objPack.Instance
			if not obj and target and target ~= tag then
				objPack = GB.Resolver.resolveObject and GB.Resolver.resolveObject(target, { Island = GB.QuestData.islandOf(questName) }) or nil
				obj = objPack and objPack.Instance
			end
			if not obj then
				obj = (GB.Resolver.taggedAny and GB.Resolver.taggedAny(tag))
					or GB.Resolver.byName(tag)
					or GB.Resolver.byName(target)
			end
			if not obj then
				M.noteFail(questName, "resolve miss " .. tostring(target))
				return false
			end
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

	local function resultRow(name, attempted, progressed, reason)
		local row = {
			quest = name,
			attempted = attempted == true,
			progressed = progressed == true,
			reason = reason,
		}
		M._lastResult = row
		return row
	end

	local function doLiveRaw(name)
		if respawnBusy() then
			return resultRow(name, true, false, "respawn")
		end
		if GB.Config.SkipQuests[name] then
			return resultRow(name, false, false, "skip")
		end
		local qs = M.questState(name)
		local t = M.trackOf(name)
		if os.clock() < t.NextRetryAt and t.LastError then
			if qs and not qs.IsAccepted then
				-- Keep trying acceptance flow; retry-window should not hard-stall accept travel/talk.
			else
				-- Keep attempted=true so farm engine does not drop to wait_level/idle.
				return resultRow(name, true, false, "retry_window")
			end
		end
		local blocked, why = M.deferred(name)
		if blocked and M.keepTrying(name, t.LastError) then
			M.deferUntil[name] = nil
			M.deferReason[name] = nil
			blocked = false
		end
		if blocked then
			if M._deferQuest ~= name or os.clock() - (M._deferAt or 0) > 8 then
				M._deferQuest = name
				M._deferAt = os.clock()
				GB.Log.warn("QUEST", "defer " .. tostring(name) .. " " .. tostring(why))
			end
			t.NextRetryAt = os.clock() + 2.5
			return resultRow(name, false, false, "deferred")
		end

		if not qs.IsAccepted then
			if not (qs.Repeatable or isRepeatable(name)) and GB.PlayerData.finished(name, true) then
				return resultRow(name, false, false, "already_complete")
			end
			if qs.IsComplete and not (qs.Repeatable or isRepeatable(name)) then
				return resultRow(name, true, true, "already_complete")
			end
			if qs.Automatic then
				setAcceptState(name, "NOT_ACCEPTED", "automatic")
				GB.Remotes.beginAutomatic(name)
			end
			if qs.NPC then
				local movePack = GB.Resolver.resolveNPC(qs.NPC, {
					DisplayName = qs.NPC,
					QuestName = name,
					Island = qs.Island,
					ExpectedRole = "npc",
					deep = false,
				}) or GB.Resolver.resolveNPC(qs.NPC, {
					DisplayName = qs.NPC,
					QuestName = name,
					ExpectedRole = "npc",
					deep = false,
				})
				local atNpc = movePack and GB.World and GB.World.atTalk and GB.World.atTalk(movePack, GB.Config.TalkRange or 14)
				if (not atNpc) and qs.Island and (not movePack) and GB.World and GB.World.pullStream then
					if os.clock() - (M._acceptStreamAt or 0) >= 6 then
						M._acceptStreamAt = os.clock()
						GB.World.pullStream(qs.Island)
					end
				end
				if not M._acceptLogAt or os.clock() - M._acceptLogAt > 2 then
					M._acceptLogAt = os.clock()
					GB.Log.log("QUEST", "Opening " .. tostring(name))
					GB.Log.log("QUEST", string.format("accepting %s via %s", tostring(name), tostring(qs.NPC)))
				end
				setAcceptState(name, "RESOLVE_ACCEPT_NPC", qs.NPC)
				-- Force only when not already at the NPC; parked = stay and talk, no re-tele.
				local ok, talkReason = M.talk(qs.NPC, false, {
					Quest = name,
					Island = qs.Island,
					DisplayName = qs.NPC,
					QuestName = name,
					Action = "accept",
					Force = not atNpc,
				})
				if ok then
					setAcceptState(name, "WAIT_ACTIVE_VALIDATION", qs.NPC)
					local active, reason = waitQuestAccepted(name, 5.6)
					if active then
						setAcceptState(name, "ACTIVE", qs.NPC)
						GB.Log.log("QUEST", tostring(name) .. " ACTIVE")
						M.noteOk(name)
						return resultRow(name, true, true, "accepted")
					end
					M.noteFail(name, "accept_not_active " .. tostring(reason))
					return resultRow(name, true, false, "accept_not_active")
				end
				local reasonText = tostring(talkReason or "")
				local parked = atNpc
					or (movePack and GB.World and GB.World.atTalk and GB.World.atTalk(movePack, GB.Config.TalkRange or 14))
				if parked
					or string.find(reasonText, "talk_no_dialogue", 1, true)
					or reasonText == "rate"
					or reasonText == "waiting"
				then
					setAcceptState(name, "WAIT_ACTIVE_VALIDATION", qs.NPC)
					local active, reason = waitQuestAccepted(name, 6.2)
					if active then
						setAcceptState(name, "ACTIVE", qs.NPC)
						GB.Log.log("QUEST", tostring(name) .. " ACTIVE")
						M.noteOk(name)
						return resultRow(name, true, true, "accepted")
					end
					if string.find(reasonText, "resolve", 1, true) or string.find(reasonText, "travel", 1, true) then
						M.noteFail(name, "accept_" .. tostring(talkReason))
					elseif reason ~= "timeout" then
						M.noteFail(name, "accept_" .. tostring(talkReason or reason))
					end
					return resultRow(name, true, false, "accept_" .. tostring(talkReason or "pending"))
				end
				if string.find(reasonText, "resolve", 1, true)
					or string.find(reasonText, "travel", 1, true)
					or string.find(reasonText, "talk_no_dialogue", 1, true)
				then
					M.noteFail(name, "accept_" .. tostring(talkReason))
				end
				return resultRow(name, true, false, "accept_" .. tostring(talkReason or "pending"))
			end
			setAcceptState(name, "UNRESOLVED_START")
			return resultRow(name, true, false, "unresolved_start")
		end

		M.acceptState[name] = nil
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

		if qs.IsComplete and not (qs.Repeatable or isRepeatable(name)) then
			M.noteOk(name)
			return resultRow(name, true, true, "complete")
		end

		if dialogueOpen() then
			if GB.Combat and GB.Combat.stopLock then
				GB.Combat.stopLock()
			end
			if os.clock() - (M.lastClick or 0) >= 0.45 and clickAccept({ QuestName = name, Action = "progress" }) then
				M.lastClick = os.clock()
				M._afterDialogueAt = os.clock()
			end
			return resultRow(name, true, true, "dialogue_open")
		end
		if M._afterDialogueAt and os.clock() - M._afterDialogueAt < 1.3 then
			return resultRow(name, true, true, "dialogue_settle")
		end

		if qs.Objective then
			if GB.State.tutorialOverlayVisible() then
				GB.State.dismissTutorialOverlay()
				return resultRow(name, true, false, "dismiss_overlay")
			end
			if GB.Tutorial and GB.Tutorial.IsBlocking and select(1, GB.Tutorial.IsBlocking()) then
				local ok = GB.Tutorial.ExecuteCurrentStep()
				return resultRow(name, true, ok == true, ok and "tutorial_progress" or "tutorial_block")
			end
			local typ = qs.Objective.Type
			if typ and not HANDLED[typ] then
				rememberUnknown(
					name .. tostring(typ),
					"UNKNOWN_OBJECTIVE " .. tostring(typ) .. " " .. tostring(qs.Objective.TargetName)
				)
				t.NextRetryAt = os.clock() + 6
				return resultRow(name, true, false, "unknown_objective")
			end
			if GB.Planner then
				local plan = GB.Planner.build(qs)
				if plan then
					local ok = GB.Planner.execute(qs, plan)
					return resultRow(name, true, ok == true, ok and "planner_progress" or "planner_pending")
				end
			end
			local ok = M.handleCondition(name, qs.Objective.Raw, qs.Stage)
			return resultRow(name, true, ok == true, ok and "condition_progress" or "condition_pending")
		end

		if qs.NPC then
			if GB.State.tutorialOverlayVisible() then
				GB.State.dismissTutorialOverlay()
				return resultRow(name, true, false, "dismiss_overlay")
			end
			local ok = M.talk(qs.NPC, false, { Quest = name, Island = qs.Island, DisplayName = qs.NPC, QuestName = name })
			return resultRow(name, true, ok == true, ok and "talk_progress" or "talk_pending")
		end
		return resultRow(name, true, false, "idle")
	end

	function M.doLiveResult(name)
		local t0 = pbegin()
		local out = { pcall(doLiveRaw, name) }
		pdone("Quest.doLive", t0)
		if not out[1] then
			error(out[2])
		end
		return out[2]
	end

	function M.doLive(name)
		local row = M.doLiveResult(name)
		return type(row) == "table" and row.progressed == true
	end

	function M.Refresh()
		if GB.PlayerData and GB.PlayerData.forceQuestRefresh then
			GB.PlayerData.forceQuestRefresh("Quest.Refresh")
		elseif GB.PlayerData and GB.PlayerData.refreshLive then
			GB.PlayerData.refreshLive(true, "Quest.Refresh")
		end
		local cur = GB.PlayerData and GB.PlayerData.current and GB.PlayerData.current()
		return cur and M.questState(cur) or nil
	end

	M.dialogueOpen = dialogueOpen

	return M
end
