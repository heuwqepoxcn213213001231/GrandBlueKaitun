-- Blocking tutorial / UI gates. Complete the real client action; never hide GUI.
-- Source: QuestInfo.Functions.TutorialFolder + ScreenShadow + QuestOverlay.

return function(GB)
	local M = {
		lastStep = nil,
		lastAt = 0,
		lastAction = nil,
		attempts = 0,
		owner = nil,
		lastGate = nil,
		lastMethod = nil,
		lastTransition = nil,
		continueAttempts = 0,
		unresolved = nil,
		dumpedTree = nil,
		_overlayText = nil,
		_overlayTextSrc = nil,
		_overlayTextAt = 0,
	}

	M.GateTypes = {
		ContinueOverlay = "ContinueOverlay",
		ActionRequired = "ActionRequired",
		Dialogue = "Dialogue",
		UISelection = "UISelection",
		EquipRequired = "EquipRequired",
		InputRequired = "InputRequired",
	}
	local OVERLAY_TEXT_TTL = 0.65

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

	-- Studio-verified fullscreen continue overlays (no GuiButton).
	M.CONTINUE_OVERLAYS = {
		SkillObtained = {
			script = "PassiveObtained",
			continuation = "UIS.InputBegan",
			listenDelay = 3.15,
			event = true,
		},
		TutorialScreen = {
			script = "TutorialLocal",
			continuation = "UIS.InputBegan",
			listenDelay = 0.75,
			event = false,
		},
	}

	-- Verified TutorialFolder modules (Studio place 118635363908336)
	M.REGISTRY = {
		{
			id = "EquipFlintlock",
			quest = "Gearing Up",
			texts = {
				"Open the backpack.",
				"Hold and drag the Flintlock to the weapon slot.",
				"Drop it on the weapon slot.",
			},
		},
		{
			id = "EquipStrongPunch",
			quest = "Basics",
			texts = {
				"Select the 'Strong Punch' skill scroll",
				"Press the button to unlock the skill",
			},
		},
		{
			id = "CastStrongPunch",
			quest = "Basics",
			texts = {},
		},
		{
			id = "InvestStats",
			quest = "Basics",
			texts = {
				"Open the menu",
				"Invest a point in to a stat",
			},
		},
		{
			id = "ForceOpenLogbook",
			quest = "Basics",
			texts = {
				"Open the Logbook",
				"Open the Tutorial",
				"Read the first tutorial page",
			},
		},
		{
			id = "SellWatch",
			quest = "Gearing Up",
			texts = {
				"Ask to sell your goods",
				"Sell the Stolen Watch",
				"Sell it!",
			},
		},
		{
			id = "UpgradeFlintlock",
			quest = "First Upgrade",
			texts = {
				"Select Flintlock",
				"Click Upgrade",
			},
		},
		{
			id = "EquippedWeapon",
			quest = "First Upgrade",
			texts = {
				"Select Flintlock",
				"Click Upgrade",
			},
		},
		{
			id = "SmeltTutorial",
			quest = "First Upgrade",
			texts = {
				"Select Copper Bar",
				"Click Craft",
			},
		},
		{
			id = "UnsheathWeapon",
			quest = nil,
			texts = {
				"Toggle your weapon",
			},
		},
		{
			id = "CraftStoneRing",
			quest = "Miners Stone Ring",
			texts = {
				"Open your backpack",
				"Select the 'Stone Ring Recipe' scroll",
				"Press the button to learn the recipe",
			},
		},
		{
			id = "PunchTraining",
			quest = "Introduction",
			texts = {},
		},
		{
			id = "UpgradeSkill",
			quest = nil,
			texts = {},
		},
		{
			id = "Pets",
			quest = nil,
			texts = {},
		},
		{
			id = "SkillObtained",
			quest = nil,
			texts = {
				"PRESS ANYWHERE TO CONTINUE",
				"Press anywhere to continue",
			},
		},
	}

	local function guiText(inst)
		return GB.State and GB.State.guiText(inst)
	end

	local function overlayKeyword(t)
		if type(t) ~= "string" or #t < 5 or #t > 90 then
			return false
		end
		local low = string.lower(t)
		return string.find(low, "backpack", 1, true)
			or string.find(low, "drag", 1, true)
			or string.find(low, "open the", 1, true)
			or string.find(low, "select", 1, true)
			or string.find(low, "invest", 1, true)
			or string.find(low, "sell", 1, true)
	end

	local function collectOverlayText(root, budget)
		if not (root and budget and budget > 0) then
			return nil, budget or 0
		end
		for _, d in ipairs(root:GetChildren()) do
			if budget <= 0 then
				break
			end
			if d:IsA("TextLabel") or d:IsA("TextButton") then
				local t = d.Text
				if overlayKeyword(t) then
					return t, budget
				end
				budget = budget - 1
			end
			local hit
			hit, budget = collectOverlayText(d, budget)
			if hit then
				return hit, budget
			end
		end
		return nil, budget
	end

	local function overlayText()
		local now = os.clock()
		if now - (M._overlayTextAt or 0) < OVERLAY_TEXT_TTL then
			if M._overlayText == false then
				return nil, nil
			end
			return M._overlayText, M._overlayTextSrc
		end
		perfCount("QuestGuiScan", 1)
		local pg = GB.lp and GB.lp.PlayerGui
		if not pg then
			M._overlayText = false
			M._overlayTextSrc = nil
			M._overlayTextAt = now
			return nil
		end
		local qo = pg:FindFirstChild("QuestOverlay")
		if qo then
			local msg = qo:FindFirstChild("QuestMessage") or qo:FindFirstChildWhichIsA("TextLabel", true)
			local t = guiText(msg)
			if type(t) == "string" and t ~= "" then
				M._overlayText = t
				M._overlayTextSrc = "QuestOverlay"
				M._overlayTextAt = now
				return t, "QuestOverlay"
			end
		end
		local ss = pg:FindFirstChild("ScreenShadow")
		if ss then
			local hit = collectOverlayText(ss, 120)
			if hit then
				M._overlayText = hit
				M._overlayTextSrc = "ScreenShadow"
				M._overlayTextAt = now
				return hit, "ScreenShadow"
			end
		end
		M._overlayText = false
		M._overlayTextSrc = nil
		M._overlayTextAt = now
		return nil, nil
	end

	local function matchRegistry(text, quest)
		if type(text) == "string" then
			for _, row in ipairs(M.REGISTRY) do
				for _, needle in ipairs(row.texts) do
					if text == needle or string.find(text, needle, 1, true) then
						return row, needle
					end
				end
			end
		end
		if quest then
			for _, row in ipairs(M.REGISTRY) do
				if row.quest == quest then
					return row, nil
				end
			end
		end
		return nil, nil
	end

	function M.readInstruction()
		return overlayText()
	end

	function M.snapshot()
		local text, src = overlayText()
		local cur = GB.PlayerData and GB.PlayerData.current and GB.PlayerData.current()
		local qs = cur and GB.Quest and GB.Quest.questState(cur)
		local obj = qs and qs.Objective
		local row, needle = matchRegistry(text, nil)
		if not row and obj and obj.Type == "Equip" then
			row = matchRegistry(nil, cur)
		end
		local backpackOpen = GB.Backpack and GB.Backpack.isOpen and GB.Backpack.isOpen()
		local dialogue = false
		local pg = GB.lp and GB.lp.PlayerGui
		local dui = pg and pg:FindFirstChild("DialogueUI")
		if dui and dui:IsA("LayerCollector") and dui.Enabled == true then
			dialogue = true
		end
		local overlayVis, overlayUi = false, nil
		if GB.State and GB.State.tutorialOverlayVisible then
			overlayVis, overlayUi = GB.State.tutorialOverlayVisible()
		end
		local modalName = overlayUi and overlayUi.Name or nil
		local blocking = false
		if text then
			local low = string.lower(text)
			if string.find(low, "open the backpack", 1, true)
				or string.find(low, "open your backpack", 1, true)
				or string.find(low, "drag the flintlock", 1, true)
				or string.find(low, "weapon slot", 1, true)
			then
				blocking = true
				row = row or matchRegistry(text, cur)
			end
		end
		if obj and obj.Type == "Equip" and obj.TargetName == "Flintlock" then
			local geared = GB.Backpack and GB.Backpack.isGearEquipped and GB.Backpack.isGearEquipped("Flintlock")
			if not geared then
				blocking = true
				row = row or { id = "EquipFlintlock" }
			end
		end
		if overlayVis then
			blocking = true
			if modalName == "SkillObtained" then
				row = { id = "SkillObtained" }
				if overlayUi and GB.State.skillNameOf then
					text = GB.State.skillNameOf(overlayUi) or text
					src = "SkillObtained"
				end
			elseif modalName == "TutorialScreen" then
				row = row or { id = "UnlockSkill" }
			end
		elseif M.lastStep and string.find(tostring(M.lastStep), "SkillObtained", 1, true) then
			if M.lastTransition ~= "cleared" then
				GB.Log.log("GATE", "SkillObtained cleared")
			end
			M.releaseTutorial("cleared")
		end
		return {
			Blocking = blocking,
			TutorialActive = blocking or overlayVis == true,
			TutorialText = text,
			TutorialStep = (row and row.id) or needle,
			TutorialSource = src,
			Modal = modalName,
			GateType = overlayVis and M.GateTypes.ContinueOverlay or (blocking and M.GateTypes.ActionRequired or nil),
			DialogueActive = dialogue,
			BackpackOpen = backpackOpen == true,
			InventoryOpen = backpackOpen == true,
			Quest = cur,
			Objective = obj and obj.Type,
			Target = obj and obj.TargetName,
		}
	end

	function M.GetActiveStep()
		local s = M.snapshot()
		return s.TutorialStep, s
	end

	function M.IsBlocking()
		local s = M.snapshot()
		return s.Blocking == true, s
	end

	function M.GetCurrentGate()
		local vis, ui = false, nil
		if GB.State and GB.State.tutorialOverlayVisible then
			vis, ui = GB.State.tutorialOverlayVisible()
		end
		if vis and ui then
			local payload = nil
			if ui.Name == "SkillObtained" and GB.State.skillNameOf then
				payload = GB.State.skillNameOf(ui)
			elseif ui.Name == "TutorialScreen" then
				local title = ui:FindFirstChild("Title")
				payload = GB.State.guiText and GB.State.guiText(title) or nil
			end
			local spec = M.CONTINUE_OVERLAYS[ui.Name]
			return {
				Type = M.GateTypes.ContinueOverlay,
				Id = ui.Name,
				Payload = payload,
				Instance = ui,
				ContinuationMethod = spec and spec.continuation or "UIS.InputBegan",
				ListenDelay = spec and spec.listenDelay,
				EventOnly = spec and spec.event == true,
			}
		end
		local s = M.snapshot()
		if s.Blocking then
			local typ = M.GateTypes.ActionRequired
			if s.Objective == "Equip" then
				typ = M.GateTypes.EquipRequired
			elseif s.DialogueActive then
				typ = M.GateTypes.Dialogue
			end
			return {
				Type = typ,
				Id = s.TutorialStep,
				Payload = s.Target or s.TutorialText,
				Instance = nil,
				ContinuationMethod = "action",
			}
		end
		return nil
	end

	function M.ValidateGateCompleted(gate)
		if not gate then
			return true
		end
		if gate.Type == M.GateTypes.ContinueOverlay then
			if gate.Instance and GB.State.overlayStillOn and GB.State.overlayStillOn(gate.Instance) then
				return false
			end
			local vis = GB.State.tutorialOverlayVisible and select(1, GB.State.tutorialOverlayVisible())
			return vis ~= true
		end
		local after = M.snapshot()
		return after.Blocking ~= true or after.TutorialStep ~= gate.Id
	end

	function M.DumpTutorialState()
		local gate = M.GetCurrentGate()
		local vis, ui = false, nil
		if GB.State and GB.State.tutorialOverlayVisible then
			vis, ui = GB.State.tutorialOverlayVisible()
		end
		local dump = {
			DetectedGate = gate and gate.Id or nil,
			GateType = gate and gate.Type or nil,
			Payload = gate and gate.Payload or nil,
			GuiPath = ui and ui:GetFullName() or nil,
			ContinuationMethod = gate and gate.ContinuationMethod or M.lastMethod,
			Attempt = M.continueAttempts,
			LastTransition = M.lastTransition,
			LastAction = M.lastAction,
			CachedState = M.lastStep,
			ActualVisibleState = vis == true,
			Owner = M.owner,
			Unresolved = M.unresolved,
			Tree = (ui and GB.State.dumpOverlayTree and GB.State.dumpOverlayTree(ui)) or nil,
		}
		GB.Log.warn("GATE", string.format("DumpTutorialState id=%s type=%s payload=%s visible=%s", tostring(dump.DetectedGate), tostring(dump.GateType), tostring(dump.Payload), tostring(dump.ActualVisibleState)))
		return dump
	end

	local STRATS = { "owner", "consts", "getgc", "synth" }

	function M.releaseTutorial(why)
		M.owner = nil
		M.lastStep = nil
		M.continueAttempts = 0
		M.unresolved = nil
		M.lastTransition = why or "cleared"
		if GB.Recovery and GB.Recovery.outcome == "BLOCKING_UI" then
			GB.Recovery.outcome = nil
		end
	end

	function M.refreshAfterGate()
		if GB.PlayerData and GB.PlayerData.forceQuestRefresh then
			GB.PlayerData.forceQuestRefresh("tutorial_gate")
		elseif GB.PlayerData and GB.PlayerData.refreshLive then
			GB.PlayerData.refreshLive(true, "tutorial_gate")
		end
		if GB.State and GB.State.refresh then
			GB.State.refresh()
		end
		if GB.Planner and GB.Planner.Replan then
			GB.Planner.Replan()
		end
		if GB.Stats and GB.Stats.markDirty then
			GB.Stats.markDirty("tutorial_gate")
		end
		if GB.Recovery and GB.Recovery.markSuccess then
			GB.Recovery.markSuccess()
		end
	end

	function M.HandleContinuationOverlay(gate)
		gate = gate or M.GetCurrentGate()
		if not (gate and gate.Type == M.GateTypes.ContinueOverlay) then
			return false
		end
		local key = gate.Id .. "|" .. tostring(gate.Payload)
		if M.unresolved == key then
			return false
		end
		if GB.Combat and GB.Combat.stopLock then
			GB.Combat.stopLock()
		end
		M.owner = "Tutorial"
		M.lastGate = gate
		if M.lastStep ~= key then
			M.lastStep = key
			M.continueAttempts = 0
			M.dumpedTree = nil
			GB.Log.log("GATE", string.format("detected ContinueOverlay %s payload=%s", tostring(gate.Id), tostring(gate.Payload)))
			GB.Log.log("GATE", "continuation=" .. tostring(gate.ContinuationMethod))
			if GB.Config and GB.Config.Debug == true and GB.State.dumpOverlayTree then
				GB.State.dumpOverlayTree(gate.Instance)
			end
		end
		GB.State._continueStrategy = STRATS[(M.continueAttempts % #STRATS) + 1]
		local stageName, stageBefore, stageTotal = nil, 0, 0
		if GB.State.overlayStage then
			stageName, stageBefore, stageTotal = GB.State.overlayStage(gate.Instance)
		end
		local _, _, method = GB.State.dismissTutorialOverlay()
		if method == "wait_listener" or method == "rate" then
			return false
		end
		if method == "gone" then
			M.releaseTutorial("cleared")
			GB.Log.log("GATE", tostring(gate.Id) .. " cleared")
			GB.Log.log("STATE", "tutorial complete")
			M.refreshAfterGate()
			return true
		end
		M.lastMethod = method
		M.lastAction = "ContinueOverlay"
		M.continueAttempts = M.continueAttempts + 1
		local ver = ""
		pcall(function()
			ver = tostring(getgenv().GB_VERSION or "")
		end)
		GB.Log.log(
			"UI",
			string.format(
				"continue %s %s via %s ver=%s",
				tostring(gate.Id),
				tostring(gate.Payload or stageName or ""),
				tostring(method),
				ver
			)
		)
		local linger = 0.55
		if stageTotal > 0 and stageBefore >= stageTotal then
			linger = 0.9
		end
		local t0 = os.clock()
		while os.clock() - t0 < linger do
			if M.ValidateGateCompleted(gate) then
				M.releaseTutorial("cleared")
				GB.Log.log("GATE", tostring(gate.Id) .. " cleared")
				GB.Log.log("STATE", "tutorial complete")
				M.refreshAfterGate()
				return true
			end
			task.wait(0.08)
		end
		if GB.State.overlayStage then
			local _, stageAfter = GB.State.overlayStage(gate.Instance)
			if type(stageAfter) == "number" and stageAfter > (stageBefore or 0) then
				GB.Log.log(
					"GATE",
					string.format(
						"%s %s stage %d->%d",
						tostring(gate.Id),
						tostring(gate.Payload or stageName or ""),
						stageBefore or 0,
						stageAfter
					)
				)
				M.continueAttempts = 0
			end
		end
		if M.continueAttempts >= 2 and M.dumpedTree ~= key then
			M.dumpedTree = key
			M.DumpTutorialState()
		end
		if M.continueAttempts >= 12 then
			M.unresolved = key
			if GB.Recovery then
				GB.Recovery.outcome = "BLOCKING_GATE_UNRESOLVED"
			end
			GB.Log.warn("GATE", "BLOCKING_GATE_UNRESOLVED " .. key)
			GB.Log.warn(
				"GATE",
				string.format(
					"id=%s payload=%s method=%s before=Enabled after=still",
					tostring(gate.Id),
					tostring(gate.Payload),
					tostring(method)
				)
			)
			M.DumpTutorialState()
			if GB.DumpRuntimeIssue then
				GB.DumpRuntimeIssue()
			end
		end
		return false
	end

	function M.ExecuteGate(gate)
		gate = gate or M.GetCurrentGate()
		if not gate then
			M.owner = nil
			return false
		end
		if gate.Type == M.GateTypes.ContinueOverlay then
			return M.HandleContinuationOverlay(gate)
		end
		return M.ExecuteCurrentStep()
	end

	function M.needsGearEquip(name)
		local s = M.snapshot()
		if s.TutorialStep == "EquipFlintlock" then
			return true
		end
		if s.TutorialText and string.find(string.lower(s.TutorialText), "backpack", 1, true) then
			return true
		end
		if s.TutorialText and string.find(string.lower(s.TutorialText), "drag", 1, true) then
			return true
		end
		return name == "Flintlock" and s.Objective == "Equip"
	end

	local function logGate(s)
		if s.TutorialStep and M.lastStep ~= s.TutorialStep .. "|" .. tostring(s.TutorialText) then
			M.lastStep = s.TutorialStep .. "|" .. tostring(s.TutorialText)
			GB.Log.log("GATE", "Tutorial detected " .. tostring(s.TutorialStep))
			if s.TutorialText then
				GB.Log.log("GATE", "Instruction: " .. tostring(s.TutorialText))
			end
		end
	end

	function M.ValidateTransition(before)
		local after = M.snapshot()
		if before and after then
			if before.Modal and before.Modal ~= after.Modal then
				GB.Log.log(
					"GATE",
					string.format("Tutorial advanced %s -> %s", tostring(before.Modal), tostring(after.Modal or "none"))
				)
				M.attempts = 0
				return true, after
			end
			if before.TutorialText ~= after.TutorialText then
				GB.Log.log(
					"GATE",
					string.format("Tutorial advanced %s -> %s", tostring(before.TutorialStep or before.TutorialText), tostring(after.TutorialStep or after.TutorialText))
				)
				M.attempts = 0
				return true, after
			end
			if before.BackpackOpen ~= after.BackpackOpen then
				M.attempts = 0
				return true, after
			end
		end
		return false, after
	end

	function M.ExecuteCurrentStep()
		local gate = M.GetCurrentGate()
		if gate and gate.Type == M.GateTypes.ContinueOverlay then
			return M.HandleContinuationOverlay(gate)
		end
		local blocking, s = M.IsBlocking()
		if not blocking then
			M.owner = nil
			return false
		end
		if GB.Combat and GB.Combat.stopLock then
			GB.Combat.stopLock()
		end
		M.owner = "Tutorial"
		logGate(s)
		local text = s.TutorialText or ""
		local low = string.lower(text)
		local before = s

		if string.find(low, "open the backpack", 1, true) or string.find(low, "open your backpack", 1, true) or (s.TutorialStep == "EquipFlintlock" and not s.BackpackOpen) then
			M.lastAction = "OpenBackpack"
			if GB.Backpack then
				GB.Backpack.open()
			end
			task.wait(0.2)
			return select(1, M.ValidateTransition(before))
		end

		if string.find(low, "drag", 1, true) or string.find(low, "weapon slot", 1, true) or string.find(low, "drop it", 1, true) then
			M.lastAction = "EquipGear"
			local target = s.Target or "Flintlock"
			if GB.Equipment and GB.Equipment.equipViaBackpack then
				GB.Equipment.equipViaBackpack(target)
			end
			task.wait(0.25)
			return select(1, M.ValidateTransition(before))
		end

		if s.Objective == "Equip" and s.Target then
			M.lastAction = "EquipGear"
			if not s.BackpackOpen and GB.Backpack then
				GB.Backpack.open()
				task.wait(0.15)
			end
			if GB.Equipment and GB.Equipment.equipViaBackpack then
				GB.Equipment.equipViaBackpack(s.Target)
			end
			task.wait(0.25)
			return select(1, M.ValidateTransition(before))
		end

		if string.find(low, "open the menu", 1, true) then
			M.lastAction = "OpenMenu"
			if GB.Quest and GB.State.clickGui then
				local pg = GB.lp and GB.lp.PlayerGui
				local tb = pg and pg:FindFirstChild("TopbarStandard")
				local left = tb and tb:FindFirstChild("Holders") and tb.Holders:FindFirstChild("Left")
				local menu = left and left:FindFirstChild("Menu")
				if menu then
					local btn = menu:IsA("GuiButton") and menu or menu:FindFirstChildWhichIsA("GuiButton", true)
					if btn then
						GB.State.clickGui(btn)
					end
				end
			end
			return select(1, M.ValidateTransition(before))
		end

		if string.find(low, "invest", 1, true) then
			M.lastAction = "Invest"
			if GB.Stats and GB.Stats.investMinimum then
				GB.Stats.investMinimum(1)
			end
			return select(1, M.ValidateTransition(before))
		end

		if string.find(low, "logbook", 1, true) or string.find(low, "tutorial page", 1, true) then
			M.lastAction = "OpenLogbook"
			return false
		end

		M.attempts = M.attempts + 1
		if M.attempts >= 6 then
			GB.Log.warn("GATE", "unchanged after attempts step=" .. tostring(s.TutorialStep))
			if GB.DumpRuntimeIssue then
				GB.DumpRuntimeIssue()
			end
			M.attempts = 0
		end
		return false
	end

	function M.ResolveCurrentGate()
		return M.ExecuteCurrentStep()
	end

	function M.dump()
		return M.snapshot()
	end

	local _snapshotRaw = M.snapshot
	function M.snapshot()
		local t0 = pbegin()
		local out = { pcall(_snapshotRaw) }
		pdone("Tutorial.snapshot", t0)
		if not out[1] then
			error(out[2])
		end
		return unpack(out, 2)
	end

	local _getCurrentGateRaw = M.GetCurrentGate
	function M.GetCurrentGate()
		local t0 = pbegin()
		local out = { pcall(_getCurrentGateRaw) }
		pdone("Tutorial.GetCurrentGate", t0)
		if not out[1] then
			error(out[2])
		end
		return unpack(out, 2)
	end

	local _continuationRaw = M.HandleContinuationOverlay
	function M.HandleContinuationOverlay(gate)
		local t0 = pbegin()
		local out = { pcall(_continuationRaw, gate) }
		pdone("Tutorial continuation", t0)
		if not out[1] then
			error(out[2])
		end
		return unpack(out, 2)
	end

	return M
end
