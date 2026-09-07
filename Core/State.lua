-- Unified PlayerState snapshot. All decisions read this.

return function(GB)
	local M = {
		snap = {},
		prev = {},
		track = {
			LastPosition = nil,
			Level = 0,
			EXP = 0,
			Gold = 0,
			QuestProgress = "",
			Kill = 0,
			SuccessfulAction = 0,
			StateChange = 0,
			TaskStartedAt = 0,
			TaskName = nil,
		},
	}

	local STATS = { "Health", "Strength", "Agility", "Precision", "Energy", "Willpower" }

	local function readTextProp(inst)
		if inst and (inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox")) then
			local t = inst.Text
			if type(t) == "string" then
				return t
			end
		end
		return nil
	end

	-- Never index .Text on ImageButton / Frame. DialogueUI NodeFrame: text is sibling TextLabel.
	local function guiText(inst)
		if not inst then
			return nil
		end
		local direct = readTextProp(inst)
		if direct and direct ~= "" then
			return direct
		end
		local named = inst:FindFirstChild("TextLabel")
		local fromNamed = readTextProp(named)
		if fromNamed and fromNamed ~= "" then
			return fromNamed
		end
		local deep = inst:FindFirstChildWhichIsA("TextLabel", true)
		local fromDeep = readTextProp(deep)
		if fromDeep and fromDeep ~= "" then
			return fromDeep
		end
		local parent = inst.Parent
		if parent then
			local sib = readTextProp(parent:FindFirstChild("TextLabel"))
			if sib and sib ~= "" then
				return sib
			end
		end
		local attr = inst:GetAttribute("Text")
		if type(attr) == "string" and attr ~= "" then
			return attr
		end
		return direct
	end

	local function guiNum(inst)
		if not inst then
			return nil
		end
		local t
		if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
			t = inst.Text
		else
			local n = inst:FindFirstChild("StatpointText") or inst:FindFirstChildWhichIsA("TextLabel", true)
			t = n and (n:IsA("TextLabel") or n:IsA("TextButton") or n:IsA("TextBox")) and n.Text or nil
		end
		if type(t) ~= "string" then
			t = guiText(inst)
		end
		if type(t) ~= "string" then
			return nil
		end
		local n = t:gsub(",", ""):match("(%d+%.?%d*)")
		return n and tonumber(n) or nil
	end

	function M.guiText(inst)
		return guiText(inst)
	end

	function M.guiNum(inst)
		return guiNum(inst)
	end

	-- Never index .Activate / :Activate() — this executor ImageButton throws
	-- "Activate is not a valid member". DialogueHandler setupButton wires
	-- ImageButton.Activated, InputBegan(Touch), and GetAttributeChangedSignal("Clicked").
	-- Keyboard 1–7 flips Clicked on the same ImageButton.
	local function rbxSignal(inst, name)
		if not inst or type(name) ~= "string" then
			return nil
		end
		local ok, ev = pcall(function()
			return inst[name]
		end)
		if ok and typeof(ev) == "RBXScriptSignal" then
			return ev
		end
		return nil
	end

	local function fireRbxSignal(sig)
		if typeof(sig) ~= "RBXScriptSignal" then
			return false
		end
		if typeof(firesignal) == "function" then
			if pcall(firesignal, sig) then
				return true
			end
		end
		if typeof(getconnections) ~= "function" then
			return false
		end
		local ok, conns = pcall(getconnections, sig)
		if not (ok and type(conns) == "table") then
			return false
		end
		local any = false
		local seen = {}
		local function tryConn(c)
			if c == nil or seen[c] then
				return
			end
			seen[c] = true
			local fire = nil
			pcall(function()
				fire = c.Fire or c.fire
			end)
			if typeof(fire) == "function" and pcall(fire, c) then
				any = true
				return
			end
			local fn = nil
			pcall(function()
				fn = c.Function
			end)
			if typeof(fn) == "function" and pcall(fn) then
				any = true
			end
		end
		for i = 1, #conns do
			tryConn(conns[i])
		end
		for _, c in pairs(conns) do
			tryConn(c)
		end
		return any
	end

	function M.clickGui(btn)
		if not (btn and btn.Parent) then
			return false
		end
		local fired = fireRbxSignal(rbxSignal(btn, "Activated"))
		if not fired then
			fired = fireRbxSignal(rbxSignal(btn, "MouseButton1Click"))
		end
		-- Same path DialogueHandler uses for KeyCode.One on Main.1.ImageButton.
		-- u89 no-ops if Activated already ran (u12 / u48).
		local ok = pcall(function()
			btn:SetAttribute("Clicked", not btn:GetAttribute("Clicked"))
		end)
		return fired or ok
	end

	-- SkillObtained / TutorialScreen: no GuiButton. Client is UIS.InputBegan
	-- MouseButton1/Touch/ButtonX. gameProcessed=true is ignored unless ButtonX.
	-- SkillObtained.PassiveObtained connects InputBegan only after task.wait(3).
	-- ContinueButton is a TextLabel. Prefer SkillObtained over TutorialScreen
	-- (TutorialLocal WaitForClear waits for SkillObtained to close first).
	local OVERLAY_GUIS = { "SkillObtained", "TutorialScreen" }
	local SKILL_OBTAINED_LISTEN = 3.15

	local function layerOn(ui)
		if not ui then
			return false
		end
		if ui:IsA("LayerCollector") and ui.Enabled == true then
			return true
		end
		return ui:GetAttribute("Enabled") == true
	end

	local function overlayLabel(ui)
		if not ui then
			return "overlay"
		end
		if ui.Name == "TutorialScreen" then
			local title = ui:FindFirstChild("Title")
			local t = title and guiText(title)
			return "TutorialScreen " .. tostring(t or "")
		end
		if ui.Name == "SkillObtained" then
			local frame = ui:FindFirstChild("Frame")
			local sn = frame and frame:FindFirstChild("SkillName")
			return "SkillObtained " .. tostring((sn and guiText(sn)) or "")
		end
		return ui.Name
	end

	local function pressAnywhereText(t)
		if type(t) ~= "string" or t == "" then
			return false
		end
		return string.find(string.lower(t), "press anywhere", 1, true) ~= nil
	end

	function M.tutorialOverlayVisible()
		local pg = GB.lp and GB.lp.PlayerGui
		if not pg then
			return false, nil
		end
		for _, name in ipairs(OVERLAY_GUIS) do
			local ui = pg:FindFirstChild(name)
			if layerOn(ui) then
				return true, ui
			end
		end
		for _, ui in ipairs(pg:GetChildren()) do
			if ui:IsA("LayerCollector") and layerOn(ui) then
				if ui:FindFirstChild("ClickToContinue", true) or ui:FindFirstChild("ContinueButton", true) then
					return true, ui
				end
				local title = ui:FindFirstChild("Title")
				local tt = title and guiText(title)
				if pressAnywhereText(tt) or (type(tt) == "string" and string.find(tt, "Unlock Skill", 1, true)) then
					return true, ui
				end
				for _, d in ipairs(ui:GetDescendants()) do
					if (d:IsA("TextLabel") or d:IsA("TextButton")) and pressAnywhereText(d.Text) then
						return true, ui
					end
				end
			end
		end
		return false, nil
	end

	local function fireInputObject(fake, processed)
		local UIS = game:GetService("UserInputService")
		local sig = rbxSignal(UIS, "InputBegan")
		if typeof(sig) ~= "RBXScriptSignal" then
			return false
		end
		if typeof(firesignal) == "function" then
			if pcall(firesignal, sig, fake, processed) then
				return true
			end
		end
		if typeof(getconnections) ~= "function" then
			return false
		end
		local ok, conns = pcall(getconnections, sig)
		if not (ok and type(conns) == "table") then
			return false
		end
		local any = false
		for _, c in pairs(conns) do
			local fire
			pcall(function()
				fire = c.Fire or c.fire
			end)
			if typeof(fire) == "function" and pcall(fire, c, fake, processed) then
				any = true
			else
				local fn
				pcall(function()
					fn = c.Function
				end)
				if typeof(fn) == "function" and pcall(fn, fake, processed) then
					any = true
				end
			end
		end
		return any
	end

	local function firePressAnywhere()
		-- gameProcessed must be false. Real GUI click often sets it true and
		-- PassiveObtained / TutorialLocal return without closing.
		local mb1 = {
			UserInputType = Enum.UserInputType.MouseButton1,
			KeyCode = Enum.KeyCode.Unknown,
			UserInputState = Enum.UserInputState.Begin,
		}
		local btnX = {
			UserInputType = Enum.UserInputType.Keyboard,
			KeyCode = Enum.KeyCode.ButtonX,
			UserInputState = Enum.UserInputState.Begin,
		}
		local ok = fireInputObject(mb1, false)
		ok = fireInputObject(btnX, false) or ok
		return ok
	end

	local function clickContinueSurface(ui)
		if not ui then
			return false
		end
		local named = ui:FindFirstChild("ClickToContinue", true) or ui:FindFirstChild("ContinueButton", true)
		if named and named:IsA("GuiButton") then
			return M.clickGui(named)
		end
		local btn = ui:FindFirstChildWhichIsA("GuiButton", true)
		if btn then
			return M.clickGui(btn)
		end
		return false
	end

	function M.dismissTutorialOverlay()
		local vis, ui = M.tutorialOverlayVisible()
		if not vis then
			M._overlayLog = nil
			M._soSeen = nil
			M._soWaitLog = nil
			return false
		end
		local now = os.clock()
		local label = overlayLabel(ui)
		if ui.Name == "SkillObtained" then
			M._soSeen = M._soSeen or now
			local waited = now - M._soSeen
			if waited < SKILL_OBTAINED_LISTEN then
				if M._soWaitLog ~= label then
					M._soWaitLog = label
					GB.Log.log("GATE", "waiting SkillObtained listener " .. label)
				end
				return true
			end
		else
			M._soSeen = nil
			M._soWaitLog = nil
		end
		if now - (M._overlayAt or 0) < 0.45 then
			return true
		end
		M._overlayAt = now
		if M._overlayLog ~= label then
			M._overlayLog = label
			GB.Log.log("UI", "dismiss overlay " .. label)
		end
		clickContinueSurface(ui)
		firePressAnywhere()
		return true
	end

	function M.refresh()
		M.prev = M.snap
		local s = {}
		local lp = GB.lp
		local char = lp and lp.Character
		local hrp = char and (char:FindFirstChild("HumanoidRootPart") or (char:IsA("Model") and char.PrimaryPart))
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		s.Character = char
		s.HRP = hrp
		s.Humanoid = hum
		s.Alive = char and hum and hum.Health > 0
		s.Position = hrp and hrp.Position
		s.GameplayPaused = lp and lp:GetAttribute("GameplayPaused") == true

		local d = GB.PlayerData and GB.PlayerData.cache() or {}
		s.Level = d.Level or 0
		s.Exp = d.EXP or d.Exp or 0
		s.Gold = d.Gold or 0
		s.CelestialCoins = d["Celestial Coins"] or d.CelestialCoins or 0
		s.StatPoints = d.StatPoints or d["Stat Points"] or d.UnusedStatPoints or 0
		s.SkillPoints = d.SkillPoints or d["Skill Points"] or 0
		s.Stats = {}
		for _, n in ipairs(STATS) do
			s.Stats[n] = d.Stats and d.Stats[n] or 0
		end
		s.Skills = d.Skills or {}
		s.Inventory = d.Inventory or {}
		s.Backpack = d.Backpack or d.Inventory
		s.Equipment = d.Equipment or d.Equips or {}
		s.Weapon = d.Weapon
		s.FightingStyle = (lp and lp:GetAttribute("Style")) or d.FightingStyle or d.Style
		s.Fruit = (lp and lp:GetAttribute("Fruit")) or d.Fruit
		s.StoredFruits = d["Fruit Storage"] or d.FruitStorage or {}
		s.PermanentFruits = d["Permanent Fruits"] or {}
		s.Race = d.Race or (lp and lp:GetAttribute("Race"))
		s.Trait = d.Trait or d.Traits
		s.Haki = d.Haki
		s.Boat = d.Boats or d.Ships
		s.LifeSkills = d.Lifeskills or d.LifeSkills or {}
		s.Flags = d.Flags or {}
		s.Quests = d.Quests or {}
		s.Completed = d.CompletedSet or {}
		s.CurrentQuest = (GB.PlayerData and GB.PlayerData.current()) or d.CurrentQuest
		s.CurrentIsland = (GB.World and GB.World.islandFromProgress(s)) or "Anchor Town"
		local ui = {
			Blocking = false,
			TutorialActive = false,
			TutorialText = nil,
			TutorialStep = nil,
			Modal = nil,
			DialogueActive = false,
			BackpackOpen = false,
			InventoryOpen = false,
		}
		if GB.Tutorial and GB.Tutorial.snapshot then
			local snap = GB.Tutorial.snapshot()
			if type(snap) == "table" then
				ui.Blocking = snap.Blocking == true
				ui.TutorialActive = snap.TutorialActive == true
				ui.TutorialText = snap.TutorialText
				ui.TutorialStep = snap.TutorialStep
				ui.Modal = snap.Modal
				ui.DialogueActive = snap.DialogueActive == true
				ui.BackpackOpen = snap.BackpackOpen == true
				ui.InventoryOpen = snap.InventoryOpen == true
			end
		else
			local vis, overlay = M.tutorialOverlayVisible()
			ui.TutorialActive = vis
			ui.Modal = vis and overlay and overlay.Name or nil
			local pg = lp and lp.PlayerGui
			local dui = pg and pg:FindFirstChild("DialogueUI")
			ui.DialogueActive = dui and dui:IsA("LayerCollector") and dui.Enabled == true
		end
		s.UI = ui
		s.EquipmentState = nil
		if GB.Equipment and GB.Equipment.equipmentState and s.CurrentQuest then
			local qs = GB.Quest and GB.Quest.questState and GB.Quest.questState(s.CurrentQuest)
			if qs and qs.Objective and qs.Objective.Type == "Equip" then
				s.EquipmentState = GB.Equipment.equipmentState(qs.Objective.TargetName)
			end
		end
		s.PhysicalIsland = nil
		if GB.World and s.Position then
			s.PhysicalIsland = GB.World.GetIslandFromPosition(s.Position)
		end

		-- GUI fallbacks (old kaitun: StatpointText.Value lies)
		pcall(function()
			local pg = lp.PlayerGui
			local menu = pg:FindFirstChild("Menu") or pg:FindFirstChild("UI")
			if menu then
				local radar = menu:FindFirstChild("Radar", true)
				if radar then
					local st = radar:FindFirstChild("StatpointText", true)
					local n = guiNum(st)
					if n and n > 0 then
						s.StatPoints = n
					end
				end
			end
			local prog = pg:FindFirstChild("Progression")
			if prog then
				local lv = prog:FindFirstChild("Level", true)
				local n = guiNum(lv)
				if n and n > 0 then
					s.Level = n
				end
			end
		end)

		if s.Position then
			M.track.LastPosition = s.Position
		end
		if s.Level ~= M.track.Level or s.Exp ~= M.track.EXP or s.Gold ~= M.track.Gold then
			M.track.StateChange = os.clock()
		end
		M.track.Level = s.Level
		M.track.EXP = s.Exp
		M.track.Gold = s.Gold
		M.snap = s
		return s
	end

	function M.get()
		if not M.snap.Level then
			return M.refresh()
		end
		return M.snap
	end

	function M.changed(field)
		local a, b = M.snap[field], M.prev[field]
		return a ~= b
	end

	return M
end
