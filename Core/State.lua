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
		local low = string.lower(t)
		return string.find(low, "press anywhere", 1, true) ~= nil
			or string.find(low, "click anywhere", 1, true) ~= nil
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

	local OWNER_NAMES = {
		TutorialLocal = true,
		PassiveObtained = true,
	}

	local function makeInput(kind)
		local t = {
			UserInputType = kind == "x" and Enum.UserInputType.Gamepad1 or Enum.UserInputType.MouseButton1,
			UserInputState = Enum.UserInputState.Begin,
			KeyCode = kind == "x" and Enum.KeyCode.ButtonX or Enum.KeyCode.Unknown,
			Position = Vector3.new(400, 300, 0),
			Delta = Vector3.new(0, 0, 0),
		}
		function t:IsModifierKeyDown()
			return false
		end
		return t
	end

	local function invokeFn(fn, fake, processed)
		if typeof(fn) ~= "function" then
			return false
		end
		return pcall(fn, fake, processed)
	end

	local function connOwnerName(c)
		local name
		pcall(function()
			local scr = c.Script
			if typeof(scr) == "Instance" then
				name = scr.Name
			end
		end)
		if type(name) == "string" and OWNER_NAMES[name] then
			return name
		end
		local fn
		pcall(function()
			fn = c.Function
		end)
		if typeof(fn) == "function" and typeof(getfenv) == "function" then
			pcall(function()
				local env = getfenv(fn)
				local scr = env and env.script
				if typeof(scr) == "Instance" then
					name = scr.Name
				end
			end)
		end
		if type(name) == "string" and OWNER_NAMES[name] then
			return name
		end
		return nil
	end

	local function invokeConn(c, fake, processed)
		if c == nil then
			return false
		end
		pcall(function()
			if c.Enabled == false then
				c.Enabled = true
			end
		end)
		local fire
		pcall(function()
			fire = c.Fire or c.fire
		end)
		if typeof(fire) == "function" then
			if pcall(fire, c, fake, processed) then
				return true
			end
			if pcall(function()
				c:Fire(fake, processed)
			end) then
				return true
			end
		end
		local fn
		pcall(function()
			fn = c.Function
		end)
		return invokeFn(fn, fake, processed)
	end

	-- TutorialLocal / PassiveObtained InputBegan: ButtonX + MouseButton1/Touch.
	local function overlayInputFn(fn)
		if typeof(fn) ~= "function" or typeof(getconstants) ~= "function" then
			return false
		end
		local ok, cs = pcall(getconstants, fn)
		if not (ok and type(cs) == "table") then
			return false
		end
		local hasX, hasClick = false, false
		for _, c in ipairs(cs) do
			if c == Enum.KeyCode.ButtonX or c == "ButtonX" then
				hasX = true
			end
			if c == Enum.UserInputType.MouseButton1
				or c == Enum.UserInputType.Touch
				or c == "MouseButton1"
				or c == "Touch"
			then
				hasClick = true
			end
		end
		return hasX and hasClick
	end

	local function scriptNameOfFn(fn)
		local name
		if typeof(getfenv) == "function" then
			pcall(function()
				local env = getfenv(fn)
				local scr = env and env.script
				if typeof(scr) == "Instance" then
					name = scr.Name
				end
			end)
		end
		if type(name) == "string" then
			return name
		end
		if debug and debug.info then
			pcall(function()
				local src = debug.info(fn, "s")
				if type(src) == "string" then
					name = src:match("([^\\/]+)$") or src
					name = name:match("([^%.]+)$") or name
				end
			end)
		end
		return name
	end

	local function clickViewport(vim)
		if not (vim and vim.SendMouseButtonEvent) then
			return false
		end
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
		local w = (vp and vp.X) or 800
		local h = (vp and vp.Y) or 600
		-- Background.Active=false — click the dimmer, not the card. Same as a hand click.
		local pts = {
			{ w * 0.12, h * 0.55 },
			{ w * 0.50, h * 0.92 },
			{ w * 0.88, h * 0.18 },
		}
		pcall(function()
			for _, p in ipairs(pts) do
				if vim.SendMouseMoveEvent then
					vim:SendMouseMoveEvent(p[1], p[2], game)
				end
				vim:SendMouseButtonEvent(p[1], p[2], 0, true, game, 1)
				task.wait(0.02)
				vim:SendMouseButtonEvent(p[1], p[2], 0, false, game, 1)
				task.wait(0.04)
			end
		end)
		return true
	end

	-- Highest visible numbered stage under Tutorials/<Title>. AdvanceStage does not hide prior stages.
	function M.overlayStage(ui)
		if not ui then
			return nil, 0, 0
		end
		local tutorials = ui:FindFirstChild("Tutorials")
		if not tutorials then
			return nil, 0, 0
		end
		local title = ui:FindFirstChild("Title")
		local name = title and guiText(title)
		local folder = (type(name) == "string" and name ~= "" and tutorials:FindFirstChild(name)) or nil
		if not folder then
			for _, ch in ipairs(tutorials:GetChildren()) do
				if ch:IsA("GuiObject") and ch.Visible then
					folder = ch
					name = ch.Name
					break
				end
			end
		end
		if not folder then
			return name, 0, 0
		end
		local maxVis, total = 0, 0
		for _, ch in ipairs(folder:GetChildren()) do
			local n = tonumber(ch.Name)
			if n then
				total = total + 1
				local vis = false
				if ch:IsA("GuiObject") and ch.Visible then
					vis = true
				end
				if not vis then
					for _, d in ipairs(ch:GetDescendants()) do
						if d:IsA("GuiObject") and d.Visible then
							vis = true
							break
						end
					end
				end
				if vis and n > maxVis then
					maxVis = n
				end
			end
		end
		return name, maxVis, total
	end

	-- Invoke TutorialLocal / PassiveObtained InputBegan only. Never hide GUI.
	-- Do not walk all UIS.InputBegan connections — CorePackages Scheduler ModuleScripts
	-- throw `_src` on this executor and abort the engine tick.
	function M.invokeContinueInput(ui, _strategy)
		local fakeMb = makeInput("mb1")
		local fakeX = makeInput("x")
		local method, invoked = nil, 0
		local UIS = game:GetService("UserInputService")
		local sig = rbxSignal(UIS, "InputBegan")
		local want = (ui and ui.Name == "SkillObtained") and "PassiveObtained" or "TutorialLocal"

		local function hitOwner(fn)
			if typeof(fn) ~= "function" then
				return false
			end
			local sn = scriptNameOfFn(fn)
			if sn ~= want then
				return false
			end
			if not overlayInputFn(fn) then
				return false
			end
			if invokeFn(fn, fakeX, false) or invokeFn(fn, fakeX, true) or invokeFn(fn, fakeMb, false) then
				invoked = invoked + 1
				method = "InputBegan:" .. tostring(sn)
				return true
			end
			return false
		end

		-- 1) Direct owner fn via getgc (name-gated). Same path that closed SkillObtained.
		if typeof(getgc) == "function" then
			local ok, gc = pcall(getgc, false)
			if not ok then
				ok, gc = pcall(getgc)
			end
			if ok and type(gc) == "table" then
				for _, fn in ipairs(gc) do
					if invoked >= 2 then
						break
					end
					pcall(hitOwner, fn)
				end
			end
		end

		-- 2) Name-gated connection only. Never fingerprint CorePackages.
		if invoked == 0 and typeof(getconnections) == "function" and typeof(sig) == "RBXScriptSignal" then
			local ok, conns = pcall(getconnections, sig)
			if ok and type(conns) == "table" then
				for _, c in pairs(conns) do
					if invoked >= 2 then
						break
					end
					pcall(function()
						local sn = connOwnerName(c)
						if sn ~= want then
							return
						end
						if invokeConn(c, fakeX, false) or invokeConn(c, fakeX, true) or invokeConn(c, fakeMb, false) then
							invoked = invoked + 1
							method = method or ("InputBegan:" .. sn)
						end
					end)
				end
			end
		end

		-- 3) firesignal — some executors no-op; still try.
		if typeof(firesignal) == "function" and typeof(sig) == "RBXScriptSignal" then
			pcall(firesignal, sig, fakeX, false)
			pcall(firesignal, sig, fakeX, true)
			pcall(firesignal, sig, fakeMb, false)
			method = method or "InputBegan:firesignal"
		end

		-- 4) Real input. ButtonX is the only key accepted when gameProcessed=true.
		--    Mouse on Background (Active=false) is gameProcessed=false — hand-click path.
		local vim = game:GetService("VirtualInputManager")
		if vim and vim.SendKeyEvent then
			pcall(function()
				vim:SendKeyEvent(true, Enum.KeyCode.ButtonX, false, game)
				task.wait(0.03)
				vim:SendKeyEvent(false, Enum.KeyCode.ButtonX, false, game)
			end)
			method = method or "VirtualInput:ButtonX"
		end
		if clickViewport(vim) then
			method = method or "VirtualInput:Mouse1"
		end
		if typeof(mouse1click) == "function" then
			pcall(mouse1click)
			method = method or "mouse1click"
		end

		return invoked > 0 or method ~= nil, method or "none", invoked
	end

	function M.overlayStillOn(ui)
		return layerOn(ui)
	end

	function M.dumpOverlayTree(ui)
		local rows = {}
		if not ui then
			return rows
		end
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
		local area = (vp and vp.X > 0 and vp.Y > 0) and (vp.X * vp.Y) or 0
		local function add(inst, depth)
			if #rows >= 24 then
				return
			end
			local row = {
				Name = inst.Name,
				Class = inst.ClassName,
				Depth = depth,
			}
			pcall(function()
				local attrs = inst:GetAttributes()
				if type(attrs) == "table" and next(attrs) then
					row.Attrs = attrs
				end
			end)
			if inst:IsA("LayerCollector") then
				row.Enabled = inst.Enabled
				row.AttrEnabled = inst:GetAttribute("Enabled")
			elseif inst:IsA("GuiObject") then
				row.Visible = inst.Visible
				row.Active = inst.Active
				row.Selectable = inst.Selectable
				row.ZIndex = inst.ZIndex
				local sz = inst.AbsoluteSize
				row.Abs = { math.floor(sz.X + 0.5), math.floor(sz.Y + 0.5) }
				if area > 0 then
					row.Cover = math.floor((sz.X * sz.Y) / area * 1000) / 10
				end
			end
			if inst:IsA("GuiButton") then
				row.Button = true
				row.Activated = rbxSignal(inst, "Activated") ~= nil
			end
			if inst:IsA("TextLabel") or inst:IsA("TextButton") then
				local t = inst.Text
				if type(t) == "string" and #t > 0 and #t < 80 then
					row.Text = t
				end
			end
			rows[#rows + 1] = row
			for _, ch in ipairs(inst:GetChildren()) do
				add(ch, depth + 1)
			end
		end
		add(ui, 0)
		local ranked = {}
		for _, r in ipairs(rows) do
			if type(r.Cover) == "number" then
				ranked[#ranked + 1] = r
			end
		end
		table.sort(ranked, function(a, b)
			return (a.Cover or 0) > (b.Cover or 0)
		end)
		if GB.Log then
			GB.Log.warn("GATE", string.format("overlay tree %s nodes=%d path=%s", tostring(ui.Name), #rows, ui:GetFullName()))
			for i = 1, math.min(#ranked, 8) do
				local r = ranked[i]
				GB.Log.warn(
					"GATE",
					string.format(
						"cover=%.1f%% %s %s vis=%s active=%s btn=%s text=%s",
						r.Cover or 0,
						tostring(r.Class),
						tostring(r.Name),
						tostring(r.Visible),
						tostring(r.Active),
						tostring(r.Button),
						tostring(r.Text or "")
					)
				)
			end
		end
		return rows
	end

	function M.skillNameOf(ui)
		if not ui then
			return nil
		end
		local frame = ui:FindFirstChild("Frame")
		local sn = frame and frame:FindFirstChild("SkillName")
		return sn and guiText(sn)
	end

	-- Attempt only. Caller must validate overlay actually closed.
	function M.dismissTutorialOverlay()
		local vis, ui = M.tutorialOverlayVisible()
		if not vis then
			M._overlayLog = nil
			M._soSeen = nil
			M._soWaitLog = nil
			M._tsSeen = nil
			return false, nil, "gone"
		end
		local now = os.clock()
		local label = overlayLabel(ui)
		if ui.Name == "SkillObtained" then
			M._soSeen = M._soSeen or now
			if now - M._soSeen < SKILL_OBTAINED_LISTEN then
				if M._soWaitLog ~= label then
					M._soWaitLog = label
					GB.Log.log("GATE", "waiting SkillObtained listener " .. label)
				end
				return false, ui, "wait_listener"
			end
		elseif ui.Name == "TutorialScreen" then
			M._soSeen = nil
			M._soWaitLog = nil
			M._tsSeen = M._tsSeen or now
			-- OpenGUI ShowContinue(0.75) then u6=true. First press after that.
			if now - M._tsSeen < 0.85 then
				if M._soWaitLog ~= label then
					M._soWaitLog = label
					GB.Log.log("GATE", "waiting TutorialScreen continue " .. label)
				end
				return false, ui, "wait_listener"
			end
		else
			M._soSeen = nil
			M._soWaitLog = nil
			M._tsSeen = nil
		end
		if now - (M._overlayAt or 0) < 0.4 then
			return false, ui, "rate"
		end
		M._overlayAt = now
		local pok, ok, method, n = pcall(M.invokeContinueInput, ui, M._continueStrategy or "owner")
		if not pok then
			if GB.Log then
				GB.Log.warn("GATE", "continue invoke " .. tostring(ok))
			end
			return false, ui, "err", 0
		end
		return ok, ui, method, n
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
				ui.GateType = snap.GateType
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

	M.Refresh = M.refresh

	function M.changed(field)
		local a, b = M.snap[field], M.prev[field]
		return a ~= b
	end

	return M
end
