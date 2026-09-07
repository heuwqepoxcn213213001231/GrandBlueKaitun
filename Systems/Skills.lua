-- EquipSkill: scroll overlay → ConsumeSkillScroll(nil) → Skill("Equip", name).
-- Cast: hotbar ToolFrame Title == name. PromptSkillEquip only for Tool obtain popup.

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
		if os.clock() - (M.lastEquip[name] or 0) < 0.9 then
			return false
		end
		M.lastEquip[name] = os.clock()
		GB.Combat.stopLock()

		if skillEquipped(name) then
			GB.Log.log("SKILL", name .. " already equipped")
			GB.Recovery.markSuccess()
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
			GB.Recovery.markSuccess()
			return true
		end
		GB.Log.warn("SKILL", "equip not confirmed " .. name)
		return false
	end

	function M.cast(name)
		if not name then
			return false
		end
		if os.clock() - (M.lastCast[name] or 0) < 0.7 then
			return false
		end
		M.lastCast[name] = os.clock()
		GB.Combat.stopLock()
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
			GB.Recovery.markSuccess()
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
