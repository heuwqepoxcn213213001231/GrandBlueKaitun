-- Blocking tutorial / UI gates. Complete the real client action; never hide GUI.
-- Source: QuestInfo.Functions.TutorialFolder + ScreenShadow + QuestOverlay.

return function(GB)
	local M = {
		lastStep = nil,
		lastAt = 0,
		lastAction = nil,
		attempts = 0,
		owner = nil,
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
	}

	local function guiText(inst)
		return GB.State and GB.State.guiText(inst)
	end

	local function overlayText()
		local pg = GB.lp and GB.lp.PlayerGui
		if not pg then
			return nil
		end
		local qo = pg:FindFirstChild("QuestOverlay")
		if qo then
			local msg = qo:FindFirstChild("QuestMessage") or qo:FindFirstChildWhichIsA("TextLabel", true)
			local t = guiText(msg)
			if type(t) == "string" and t ~= "" then
				return t, "QuestOverlay"
			end
		end
		local ss = pg:FindFirstChild("ScreenShadow")
		if ss then
			for _, d in ipairs(ss:GetDescendants()) do
				if d:IsA("TextLabel") or d:IsA("TextButton") then
					local t = d.Text
					if type(t) == "string" and #t > 4 and #t < 80 then
						local low = string.lower(t)
						if string.find(low, "backpack", 1, true)
							or string.find(low, "drag", 1, true)
							or string.find(low, "open the", 1, true)
							or string.find(low, "select", 1, true)
							or string.find(low, "invest", 1, true)
							or string.find(low, "sell", 1, true)
						then
							return t, "ScreenShadow"
						end
					end
				end
			end
		end
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
		local overlayVis = GB.State and GB.State.tutorialOverlayVisible and select(1, GB.State.tutorialOverlayVisible())
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
		end
		return {
			Blocking = blocking,
			TutorialActive = blocking or overlayVis == true,
			TutorialText = text,
			TutorialStep = (row and row.id) or needle,
			TutorialSource = src,
			Modal = overlayVis and "TutorialScreen" or nil,
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

		-- Press-anywhere / Unlock Skill only. Do not dismiss QuestOverlay backpack coach.
		if s.Modal and not string.find(low, "backpack", 1, true) and not string.find(low, "weapon slot", 1, true) and not string.find(low, "drag", 1, true) then
			if GB.State.dismissTutorialOverlay then
				GB.State.dismissTutorialOverlay()
				task.wait(0.2)
				return M.ValidateTransition(before)
			end
		end

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

	return M
end
