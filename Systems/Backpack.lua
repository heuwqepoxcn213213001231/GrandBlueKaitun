-- Backpack UI open/select/equip. Slot-upgrade remote still UNRESOLVED.

return function(GB)
	local M = {
		disabled = false,
		reason = nil,
		lastOpen = 0,
	}

	local function pg()
		return GB.lp and GB.lp.PlayerGui
	end

	local function backpackRoot()
		local ui = pg()
		local bp = ui and ui:FindFirstChild("Backpack")
		return bp and bp:FindFirstChild("Backpack")
	end

	function M.storageFrame()
		local root = backpackRoot()
		if not root then
			return nil
		end
		local frame = root:FindFirstChild("BackpackFrame")
		local scale = frame and frame:FindFirstChild("Scale")
		return scale and scale:FindFirstChild("Storage")
	end

	function M.equipsSlots()
		local root = backpackRoot()
		if not root then
			return nil
		end
		local frame = root:FindFirstChild("BackpackFrame")
		local scale = frame and frame:FindFirstChild("Scale")
		local equips = scale and scale:FindFirstChild("Equips")
		local slots = equips and equips:FindFirstChild("Slots")
		return slots
	end

	function M.isOpen()
		local storage = M.storageFrame()
		return storage ~= nil and storage.Visible == true
	end

	function M.topbarButton()
		local ui = pg()
		if not ui then
			return nil
		end
		local tb = ui:FindFirstChild("TopbarStandard")
		local holders = tb and tb:FindFirstChild("Holders")
		local left = holders and holders:FindFirstChild("Left")
		return left and left:FindFirstChild("Backpack")
	end

	function M.open()
		if M.isOpen() then
			return true
		end
		if os.clock() - M.lastOpen < 0.4 then
			return M.isOpen()
		end
		M.lastOpen = os.clock()
		GB.Log.log("UI", "Opening backpack")
		if GB.Remotes.backpackToggle then
			GB.Remotes.backpackToggle(true)
		end
		local btn = M.topbarButton()
		if btn then
			if btn:IsA("GuiButton") then
				GB.State.clickGui(btn)
			else
				local child = btn:FindFirstChildWhichIsA("GuiButton", true)
				if child then
					GB.State.clickGui(child)
				else
					GB.State.clickGui(btn)
				end
			end
		end
		local t0 = os.clock()
		while os.clock() - t0 < 1.2 do
			if M.isOpen() then
				return true
			end
			task.wait(0.08)
		end
		return M.isOpen()
	end

	function M.close()
		if not M.isOpen() then
			return true
		end
		if GB.Remotes.backpackToggle then
			GB.Remotes.backpackToggle(false)
		end
		return not M.isOpen()
	end

	local function titleOf(inst)
		if not inst then
			return nil
		end
		local t = inst:FindFirstChild("Title")
		if t and (t:IsA("TextLabel") or t:IsA("TextButton") or t:IsA("TextBox")) then
			return t.Text
		end
		return GB.State and GB.State.guiText(inst)
	end

	function M.findItemFrame(name)
		local storage = M.storageFrame()
		local sf = storage and storage:FindFirstChild("ScrollingFrame")
		if sf then
			for _, child in ipairs(sf:GetChildren()) do
				if child:IsA("Frame") and titleOf(child) == name then
					return child
				end
			end
		end
		local root = backpackRoot()
		local frame = root and root:FindFirstChild("BackpackFrame")
		local scale = frame and frame:FindFirstChild("Scale")
		local bars = scale and scale:FindFirstChild("Bars")
		local bscale = bars and bars:FindFirstChild("Scale")
		local hotbar = bscale and bscale:FindFirstChild("Hotbar")
		if hotbar then
			for _, slot in ipairs(hotbar:GetChildren()) do
				if slot:IsA("Frame") then
					for _, child in ipairs(slot:GetChildren()) do
						if child:IsA("Frame") and titleOf(child) == name then
							return child
						end
					end
				end
			end
		end
		return nil
	end

	function M.isGearEquipped(name)
		local slots = M.equipsSlots()
		if not slots then
			return false
		end
		for _, slot in ipairs(slots:GetChildren()) do
			if slot:IsA("Frame") then
				if titleOf(slot) == name then
					return true
				end
				for _, child in ipairs(slot:GetDescendants()) do
					if (child:IsA("TextLabel") or child:IsA("TextButton")) and child.Name == "Title" and child.Text == name then
						return true
					end
				end
			end
		end
		return false
	end

	function M.tick()
		if not GB.Config.AutoBackpack then
			return
		end
	end

	return M
end
