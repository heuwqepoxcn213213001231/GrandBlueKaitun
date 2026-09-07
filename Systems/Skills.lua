-- EquipSkill: scroll overlay → ConsumeSkillScroll(nil) → Skill("Equip", name).
-- Cast: dismiss TutorialScreen/SkillObtained first, then hotbar ToolFrame Title == name.
-- PromptSkillEquip only for Tool obtain popup.

return function(GB)
	local M = {
		lastEquip = {},
		lastCast = {},
	}

	local function pg()
		return GB.lp and GB.lp.PlayerGui
	end

	local function guiEnabled(name)
		local ui = pg() and pg():FindFirstChild(name)
		if not ui then
			return false
		end
		if ui:IsA("LayerCollector") then
			return ui.Enabled == true
		end
		return true
	end

	local function clickPath(path)
		local root = pg()
		if not (root and type(path) == "string") then
			return false
		end
		local cur = root
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
		if btn then
			return GB.State.clickGui(btn)
		end
		return false
	end

	local function hotbar()
		local ui = pg()
		if not ui then
			return nil
		end
		local cur = ui:FindFirstChild("Backpack")
		for _, n in ipairs({ "Backpack", "BackpackFrame", "Scale", "Bars", "Scale", "Hotbar" }) do
			cur = cur and cur:FindFirstChild(n)
		end
		return cur
	end

	local function hotbarSlot(title)
		local bar = hotbar()
		if not bar then
			return nil, nil
		end
		for _, child in ipairs(bar:GetChildren()) do
			local tf = child:FindFirstChild("ToolFrame")
			local lab = tf and tf:FindFirstChild("Title")
			if lab and (lab:IsA("TextLabel") or lab:IsA("TextButton")) and lab.Text == title then
				return tf, child
			end
		end
		return nil, nil
	end

	local function skillInStorage(name)
		local skills = pg() and pg():FindFirstChild("Skills")
		if not skills then
			return nil
		end
		local sf = skills:FindFirstChild("ScrollingFrame")
		local storage = sf and sf:FindFirstChild("Storage")
		return storage and storage:FindFirstChild(name)
	end

	local function skillEquipped(name)
		local owned, eq = GB.PlayerData.skillOwned(name)
		if eq then
			return true
		end
		if hotbarSlot(name) then
			return true
		end
		return owned and skillInStorage(name) == nil and hotbarSlot(name) ~= nil
	end

	local function overlayMessage()
		local ui = pg()
		if not ui then
			return ""
		end
		for _, d in ipairs(ui:GetDescendants()) do
			if (d:IsA("TextLabel") or d:IsA("TextButton")) and type(d.Text) == "string" then
				if string.find(d.Text, "skill scroll", 1, true) or string.find(d.Text, "unlock the skill", 1, true) then
					return d.Text
				end
			end
		end
		return ""
	end

	local function findScrollKey(name)
		local inv = GB.PlayerData.cache().Inventory
		if type(inv) ~= "table" then
			return nil
		end
		local want = { "Skill: " .. name, "Skill Scroll", name }
		for _, w in ipairs(want) do
			if inv[w] then
				local row = inv[w]
				return (type(row) == "table" and (row.Key or row.Name)) or w
			end
		end
		for k, v in pairs(inv) do
			if type(v) == "table" then
				local nm = v.Name or k
				if nm == "Skill Scroll" and (v.Value == name or v.Skill == name) then
					return v.Key or k
				end
				if nm == "Skill: " .. name or nm == name then
					return v.Key or k
				end
			end
		end
		return nil
	end

	local function consumeScroll(name)
		local scrollUi = pg() and pg():FindFirstChild("SkillScroll")
		if scrollUi then
			local frame = scrollUi:FindFirstChild("Frame")
			local btn = frame and frame:FindFirstChild("ImageButton")
			if btn and btn:IsA("GuiButton") then
				GB.Log.log("SKILL", "click SkillScroll unlock")
				GB.State.clickGui(btn)
			end
		end
		GB.Remotes.consumeSkillScroll()
		return true
	end

	local function openSkillsMenu()
		if guiEnabled("Skills") then
			return true
		end
		if not guiEnabled("Menu") then
			clickPath("TopbarStandard.Holders.Left.Menu")
			task.wait(0.2)
		end
		clickPath("Menu.ContainerFrame.Icons.Skills")
		task.wait(0.25)
		return guiEnabled("Skills")
	end

	local function closeMenus()
		if guiEnabled("Skills") then
			clickPath("Skills.TopBar.BackButton")
			task.wait(0.15)
		end
		if guiEnabled("Menu") then
			clickPath("Menu.ContainerFrame.Icons.Close")
			task.wait(0.15)
		end
	end

	function M.equip(name)
		if not name then
			return false
		end
		if GB.State.tutorialOverlayVisible() then
			GB.State.dismissTutorialOverlay()
			return false
		end
		if os.clock() - (M.lastEquip[name] or 0) < 0.9 then
			return false
		end
		M.lastEquip[name] = os.clock()
		GB.Combat.stopLock()

		if skillEquipped(name) then
			GB.Log.log("SKILL", name .. " already equipped")
			return true
		end

		local msg = overlayMessage()
		local scrollSlot = hotbarSlot("Skill: " .. name)
		local scrollUi = pg() and pg():FindFirstChild("SkillScroll")
		local lastTool = scrollUi and scrollUi:GetAttribute("LastToolName")

		if scrollSlot or (type(msg) == "string" and string.find(msg, "skill scroll", 1, true)) or lastTool then
			GB.Log.log("SKILL", "scroll flow " .. name)
			if scrollSlot and not lastTool then
				GB.State.clickGui(scrollSlot:FindFirstChildWhichIsA("GuiButton", true) or scrollSlot)
				task.wait(0.25)
			end
			local key = findScrollKey(name)
			if key then
				GB.Remotes.heldEquip(key)
				task.wait(0.25)
			end
			consumeScroll(name)
			task.wait(0.35)
		end

		if skillInStorage(name) or GB.PlayerData.skillOwned(name) then
			GB.Log.log("SKILL", "Skill Equip " .. name)
			GB.Remotes.skillEquip(name)
			if openSkillsMenu() then
				local icon = skillInStorage(name)
				if icon then
					local btn = icon:IsA("GuiButton") and icon or icon:FindFirstChildWhichIsA("GuiButton", true)
					if btn then
						GB.State.clickGui(btn)
						task.wait(0.2)
					end
				end
				clickPath("Skills.RightFrame.InfoFrame.Equip Button")
				clickPath("Skills.Frame.Equip Button")
			end
		elseif GB.Remotes.promptSkillEquip(name) then
			GB.Log.log("SKILL", "PromptSkillEquip " .. name)
		end

		task.wait(0.3)
		if skillEquipped(name) then
			return true
		end
		GB.Log.warn("SKILL", "equip not confirmed " .. name)
		return false
	end

	local SLOT_KEYS = {
		Enum.KeyCode.One,
		Enum.KeyCode.Two,
		Enum.KeyCode.Three,
		Enum.KeyCode.Four,
		Enum.KeyCode.Five,
		Enum.KeyCode.Six,
		Enum.KeyCode.Seven,
		Enum.KeyCode.Eight,
		Enum.KeyCode.Nine,
		Enum.KeyCode.Zero,
	}

	local function skillInfo(name)
		local ok, SI = pcall(function()
			return require(game:GetService("ReplicatedStorage").Modules.SkillInformation)
		end)
		if not (ok and type(SI) == "table" and SI.GetSkillInfo) then
			return nil
		end
		local ok2, info = pcall(SI.GetSkillInfo, name)
		if ok2 and type(info) == "table" then
			return info
		end
		return nil
	end

	local function chargeHoldSec(name)
		local info = skillInfo(name)
		if not (info and info.ChargeInfo) then
			return nil
		end
		local base = info.BaseInfo or {}
		local ok, ci = pcall(info.ChargeInfo, base)
		if ok and type(ci) == "table" and type(ci.minimumDuration) == "number" then
			return ci.minimumDuration
		end
		return type(base.Windup) == "number" and base.Windup or 0.35
	end

	function M.isHoldSkill(name)
		if chargeHoldSec(name) then
			return true
		end
		local tf = select(1, hotbarSlot(name))
		if not tf then
			return false
		end
		local extra = tf:FindFirstChild("ExtraText", true)
		if extra and (extra:IsA("TextLabel") or extra:IsA("TextButton")) then
			return string.upper(tostring(extra.Text or "")) == "HOLD"
		end
		return false
	end

	function M.hotbarIndex(title)
		local _, child = hotbarSlot(title)
		if not child then
			return nil
		end
		local n = tonumber(child.Name)
		if n then
			return n
		end
		if type(child.LayoutOrder) == "number" and child.LayoutOrder > 0 then
			return child.LayoutOrder
		end
		return nil
	end

	function M.resolveShootSkill()
		if hotbarSlot("Gunshot") then
			return "Gunshot"
		end
		local bar = hotbar()
		if bar then
			for _, child in ipairs(bar:GetChildren()) do
				local tf = child:FindFirstChild("ToolFrame")
				local extra = tf and tf:FindFirstChild("ExtraText", true)
				local lab = tf and tf:FindFirstChild("Title")
				if extra and (extra:IsA("TextLabel") or extra:IsA("TextButton")) and string.upper(tostring(extra.Text or "")) == "HOLD" then
					if lab and (lab:IsA("TextLabel") or lab:IsA("TextButton")) and type(lab.Text) == "string" and lab.Text ~= "" then
						return lab.Text
					end
				end
			end
		end
		return "Gunshot"
	end

	local function backpackEnv()
		if typeof(getsenv) ~= "function" then
			return nil
		end
		local ui = pg()
		local bp = ui and ui:FindFirstChild("Backpack")
		if not bp then
			return nil
		end
		local ls = bp:FindFirstChild("BackpackLocal", true)
		if not (ls and ls:IsA("LocalScript")) then
			for _, d in ipairs(bp:GetDescendants()) do
				if d:IsA("LocalScript") and d.Name == "BackpackLocal" then
					ls = d
					break
				end
			end
		end
		if not ls then
			return nil
		end
		local ok, env = pcall(getsenv, ls)
		if ok and type(env) == "table" then
			return env
		end
		return nil
	end

	local function pressSlot(idx, down)
		local key = SLOT_KEYS[idx]
		if not key then
			return false
		end
		local ev = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
		local pk = ev and ev:FindFirstChild("PressKey")
		if not pk then
			return false
		end
		if down == false then
			return pcall(function()
				pk:Fire(key, Enum.UserInputType.Keyboard, false)
			end)
		end
		return pcall(function()
			pk:Fire(key, Enum.UserInputType.Keyboard)
		end)
	end

	function M.aimAt(target)
		if typeof(target) ~= "Instance" then
			return false
		end
		local part = GB.Resolver and GB.Resolver.part and GB.Resolver.part(target)
		if not (part and part:IsA("BasePart")) then
			local hrp = target:FindFirstChild("HumanoidRootPart")
			part = (hrp and hrp:IsA("BasePart") and hrp) or (target.PrimaryPart and target.PrimaryPart:IsA("BasePart") and target.PrimaryPart)
		end
		local root = GB.World and GB.World.hrp and GB.World.hrp()
		if not (part and part:IsA("BasePart") and root) then
			return false
		end
		local dest = root.Position
		root.CFrame = CFrame.new(dest, Vector3.new(part.Position.X, dest.Y, part.Position.Z))
		local cam = workspace.CurrentCamera
		if cam then
			local origin = dest + Vector3.new(0, 1.5, 0)
			pcall(function()
				cam.CFrame = CFrame.new(origin, part.Position)
			end)
			local sp, on = cam:WorldToViewportPoint(part.Position)
			if on then
				local vim = game:GetService("VirtualInputManager")
				if vim and vim.SendMouseMoveEvent then
					pcall(function()
						vim:SendMouseMoveEvent(sp.X, sp.Y, game)
					end)
				end
			end
		end
		return true
	end

	function M.castHold(name, opts)
		opts = opts or {}
		if not name then
			return false
		end
		if GB.State.tutorialOverlayVisible() then
			GB.State.dismissTutorialOverlay()
			return false
		end
		local cd = opts.cooldown or 6.2
		if os.clock() - (M.lastCast[name] or 0) < cd then
			return false
		end
		if not opts.keepLock and GB.Combat and GB.Combat.stopLock then
			GB.Combat.stopLock()
		end
		if not skillEquipped(name) then
			M.equip(name)
			task.wait(0.2)
		end
		closeMenus()
		if opts.target then
			M.aimAt(opts.target)
		end
		local idx = M.hotbarIndex(name) or 5
		local hold = opts.hold or ((chargeHoldSec(name) or 0.35) + 0.12)
		local env = backpackEnv()
		local method = nil
		if env and type(env.UseTool) == "function" then
			if pcall(env.UseTool, idx, true) then
				method = "UseTool"
			end
		end
		if not method then
			if pressSlot(idx, true) then
				method = "PressKey"
			end
		end
		if not method then
			GB.Log.warn("SKILL", "hold press miss " .. name)
			return false
		end
		M.lastCast[name] = os.clock()
		GB.Log.log("SKILL", string.format("hold %s slot=%s %.2fs via %s", name, tostring(idx), hold, method))
		task.wait(hold)
		if opts.target then
			M.aimAt(opts.target)
		end
		if method == "UseTool" and env and type(env.ReleaseTool) == "function" then
			pcall(env.ReleaseTool, idx)
		else
			pressSlot(idx, false)
		end
		GB.Log.log("SKILL", "release " .. name)
		return true
	end

	function M.cast(name, opts)
		if M.isHoldSkill(name) then
			return M.castHold(name, opts)
		end
		if not name then
			return false
		end
		if GB.State.tutorialOverlayVisible() then
			GB.State.dismissTutorialOverlay()
			return false
		end
		if os.clock() - (M.lastCast[name] or 0) < 0.7 then
			return false
		end
		M.lastCast[name] = os.clock()
		if not (opts and opts.keepLock) and GB.Combat then
			GB.Combat.stopLock()
		end
		if not skillEquipped(name) then
			M.equip(name)
			task.wait(0.2)
		end
		closeMenus()
		local slot = hotbarSlot(name)
		if slot then
			GB.Log.log("SKILL", "cast hotbar " .. name)
			local btn = slot:FindFirstChildWhichIsA("GuiButton", true) or slot
			GB.State.clickGui(btn)
			local char = GB.World.char()
			local tool = char and char:FindFirstChild(name)
			if tool and tool:IsA("Tool") and tool.Activate then
				tool:Activate()
			end
			return true
		end
		local ev = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
		local pk = ev and ev:FindFirstChild("PressKey")
		if pk then
			pk:Fire(Enum.KeyCode.One)
			GB.Log.log("SKILL", "cast PressKey One " .. name)
			return true
		end
		GB.Log.warn("SKILL", "cast miss hotbar " .. name)
		return false
	end

	function M.ensure(name)
		return M.equip(name)
	end

	function M.tick()
		if not GB.Config.AutoSkills then
			return
		end
		local cur = GB.PlayerData.current()
		if not cur then
			return
		end
		local qs = GB.Quest.questState(cur)
		local obj = qs and qs.Objective
		if not obj then
			return
		end
		if obj.Type == "EquipSkill" then
			M.equip(obj.TargetName)
		elseif obj.Type == "Cast" then
			M.cast(obj.TargetName)
		end
	end

	return M
end
