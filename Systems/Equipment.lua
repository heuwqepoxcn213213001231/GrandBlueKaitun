-- DIRECT_EQUIP = HeldItem Equip (hotbar hold).
-- UI_EQUIP = backpack open + SaveOrder(slot, key) — same path as drag-to-gear.
-- Gearing Up Equip Flintlock is UI_EQUIP: HeldItem does not credit the quest.

return function(GB)
	local M = {
		lastUi = 0,
		lastDirect = 0,
		lastStrategy = nil,
	}

	local WEAPON_ITEMS = {
		Flintlock = true,
		Cutlass = true,
	}

	local function findInvKey(name)
		local inv = GB.PlayerData.cache().Inventory
		if type(inv) ~= "table" then
			return name
		end
		if inv[name] then
			local row = inv[name]
			return (type(row) == "table" and (row.Key or row.Name)) or name
		end
		for k, v in pairs(inv) do
			if type(v) == "table" and (v.Name == name or v.Key == name) then
				return v.Key or k or name
			end
		end
		return name
	end

	function M.heldName()
		local char = GB.World and GB.World.char and GB.World.char()
		if not char then
			return nil
		end
		local tool = char:FindFirstChildOfClass("Tool")
		if tool then
			return tool:GetAttribute("ItemName") or tool.Name
		end
		return nil
	end

	function M.equipmentState(name)
		local owned, amt = GB.PlayerData.hasItem(name)
		local equipped = GB.Backpack and GB.Backpack.isGearEquipped and GB.Backpack.isGearEquipped(name)
		local held = M.heldName() == name
		local qs = GB.Quest and GB.PlayerData.current and GB.Quest.questState(GB.PlayerData.current())
		local credited = false
		if qs and qs.Objective and qs.Objective.Type == "Equip" and qs.Objective.TargetName == name then
			credited = (qs.Objective.Current or 0) >= (qs.Objective.Amount or 1) or qs.Objective.Complete == true
		elseif qs and qs.IsComplete then
			credited = true
		end
		return {
			Owned = owned == true,
			Amount = amt or 0,
			Selected = held,
			Equipped = equipped == true,
			Held = held,
			QuestCredited = credited,
		}
	end

	function M.needsGearSlot(name)
		if WEAPON_ITEMS[name] then
			return true
		end
		local kind = GB.ItemData and GB.ItemData.kind and GB.ItemData.kind(name)
		return kind == "EQUIP" and name ~= "Transponder Snail" and name ~= "Rusty Pickaxe" and name ~= "Rusty Shovel"
	end

	function M.equipViaBackpack(name)
		if not name then
			return false
		end
		if os.clock() - M.lastUi < 0.9 then
			return false
		end
		M.lastUi = os.clock()
		M.lastStrategy = "UI_EQUIP"
		if GB.Combat and GB.Combat.stopLock then
			GB.Combat.stopLock()
		end
		if GB.Backpack and not GB.Backpack.isOpen() then
			GB.Backpack.open()
			task.wait(0.15)
		end
		if GB.Backpack and GB.Backpack.isGearEquipped(name) then
			return true
		end
		local key = findInvKey(name)
		local slot = WEAPON_ITEMS[name] and "Weapon2" or "Weapon2"
		if name == "Cutlass" then
			slot = "Weapon1"
		end
		GB.Log.log("EQUIP", string.format("Selecting %s", tostring(name)))
		GB.Log.log("EQUIP", string.format("Equipping %s slot=%s", tostring(key), tostring(slot)))
		local ok = GB.Remotes.saveOrder(slot, key)
		if WEAPON_ITEMS[name] then
			task.wait(0.2)
			if GB.Backpack and not GB.Backpack.isGearEquipped(name) then
				GB.Remotes.saveOrder("Weapon1", key)
			end
		end
		task.wait(0.25)
		return ok or (GB.Backpack and GB.Backpack.isGearEquipped(name))
	end

	function M.equipDirect(name)
		if not name then
			return false
		end
		if os.clock() - M.lastDirect < 0.7 then
			return false
		end
		M.lastDirect = os.clock()
		M.lastStrategy = "DIRECT_EQUIP"
		local key = findInvKey(name)
		GB.Log.log("EQUIP", "HeldItem Equip " .. tostring(key))
		return GB.Remotes.heldEquip(key)
	end

	function M.equipNamed(name, opts)
		opts = opts or {}
		if not name then
			return false
		end
		if not GB.PlayerData.hasItem(name) then
			return false
		end
		local st = M.equipmentState(name)
		if st.QuestCredited then
			return true
		end
		local gate = GB.Tutorial and GB.Tutorial.IsBlocking and GB.Tutorial.IsBlocking()
		local mode = opts.Mode
		if not mode then
			if opts.QuestEquip or gate or M.needsGearSlot(name) then
				mode = "UI_EQUIP"
			else
				mode = "DIRECT_EQUIP"
			end
		end
		if st.Equipped and not st.QuestCredited then
			GB.Log.log("EQUIP", tostring(name) .. " equipped but quest not credited")
			if gate and GB.Tutorial and GB.Tutorial.ExecuteCurrentStep then
				return GB.Tutorial.ExecuteCurrentStep()
			end
			if mode ~= "UI_EQUIP" then
				mode = "UI_EQUIP"
			end
		elseif st.Held and not st.Equipped and not st.QuestCredited and M.needsGearSlot(name) then
			GB.Log.log("EQUIP", tostring(name) .. " equipped but quest not credited")
			mode = "UI_EQUIP"
		end
		if mode == "UI_EQUIP" then
			return M.equipViaBackpack(name)
		end
		return M.equipDirect(name)
	end

	function M.upgradeNamed(name)
		local key = findInvKey(name or "Flintlock")
		local anvil = GB.Resolver.taggedAny and GB.Resolver.taggedAny("Anvil") or GB.Resolver.byName("Anvil")
		if anvil and GB.World.ToInteractable then
			GB.World.ToInteractable(anvil, 8)
			local pr = GB.Resolver.prompt(anvil)
			if pr then
				GB.World.firePrompt(pr)
			end
		end
		GB.Log.log("EQUIP", "Upgrade " .. tostring(key))
		local ok = GB.Remotes.upgrade(key)
		task.wait(0.3)
		return ok
	end

	function M.tick()
		if not GB.Config.AutoEquip then
			return
		end
		if GB.Tutorial and GB.Tutorial.IsBlocking and GB.Tutorial.IsBlocking() then
			return
		end
		if GB.PlayerData.live("A Voice in a Shell") and GB.PlayerData.hasItem("Transponder Snail") then
			local st = M.equipmentState("Transponder Snail")
			if not (st.Held or st.Equipped or st.QuestCredited) then
				M.equipDirect("Transponder Snail")
			end
		end
		if GB.PlayerData.live("First Upgrade") and GB.PlayerData.hasItem("Rusty Pickaxe") then
			local st = M.equipmentState("Rusty Pickaxe")
			if not (st.Held or st.Equipped) then
				M.equipDirect("Rusty Pickaxe")
			end
		end
	end

	return M
end
