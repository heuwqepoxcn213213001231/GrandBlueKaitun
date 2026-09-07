-- Resolve remotes. Fire only verified arg shapes.

return function(GB)
	local RS = game:GetService("ReplicatedStorage")
	local M = {
		failed = {},
	}

	local function ev(name)
		local e = RS:FindFirstChild("Events")
		return e and e:FindFirstChild(name)
	end

	function M.get(name)
		return ev(name)
	end

	function M.fire(name, gap, ...)
		if not GB.Retry.rateOk("re:" .. name, gap or 0.55) then
			return false, "rate"
		end
		local r = ev(name)
		if not r then
			GB.Log.warn("ERROR", "remote missing " .. name)
			M.failed[name] = "missing"
			return false, "missing"
		end
		local ok, err = pcall(function(...)
			r:FireServer(...)
		end, ...)
		if not ok then
			GB.Log.err("ERROR", name .. " FireServer " .. tostring(err))
			GB.Persist.failRemote(name, err)
			return false, err
		end
		return true
	end

	function M.invoke(name, ...)
		if not GB.Retry.rateOk("rf:" .. name, 0.4) then
			return nil, "rate"
		end
		local r = ev(name)
		if not r then
			return nil, "missing"
		end
		local ok, res = pcall(function(...)
			return r:InvokeServer(...)
		end, ...)
		if not ok then
			GB.Persist.failRemote(name, res)
			return nil, res
		end
		return res
	end

	-- VERIFIED wrappers
	function M.talk(displayName)
		return M.fire("ClientQuest", 0.8, "Talk", displayName)
	end

	function M.autoTalk(displayName)
		return M.fire("ClientQuest", 0.8, "Automatic Talk", displayName)
	end

	function M.beginAutomatic(questName)
		-- Logbook path. NOT BeginQuest.
		return M.fire("ClientQuest", 1.0, "BeginAutomatic", questName)
	end

	function M.closetVisit()
		return M.fire("ClientQuest", 1.2, "Closet", "Visit")
	end

	function M.dialogueConfig(config)
		local b = RS:FindFirstChild("Events") and RS.Events:FindFirstChild("DialogueBindable")
		if not (b and config) then
			return false
		end
		if not GB.Retry.rateOk("dialogue", 0.7) then
			return false
		end
		return pcall(function()
			b:Fire(config)
		end)
	end

	function M.statInvest(stat, n)
		local r = ev("StatPoints")
		if not r then
			GB.Log.warn("ERROR", "remote missing StatPoints")
			return false
		end
		if not r:IsA("RemoteEvent") then
			GB.Log.warn("ERROR", "StatPoints type " .. tostring(r.ClassName))
			return false, "type"
		end
		n = math.max(1, math.floor(tonumber(n) or 1))
		if not GB.Retry.rateOk("re:StatPoints", 0.2) then
			return false, "rate"
		end
		local ok, err = pcall(function()
			r:FireServer("Invest", tostring(stat), n)
		end)
		if not ok then
			GB.Log.err("ERROR", "StatPoints FireServer " .. tostring(err))
			return false, err
		end
		return true
	end

	function M.describeStatInvest()
		local r = ev("StatPoints")
		local p = "ReplicatedStorage.Events.StatPoints"
		return {
			Path = p,
			Type = r and r.ClassName or "missing",
			Method = "FireServer",
			Args = { "Invest", "<StatName>", "<Amount:number>" },
			Callsite = "MenuHandler.Activated",
		}
	end

	function M.statReplicate()
		local r = ev("StatReplication")
		if r then
			pcall(function()
				r:FireServer()
			end)
			return true
		end
		return false
	end

	function M.shopPurchase(part, qty)
		return M.fire("Shop", 0.7, "Purchase", part, qty or 1)
	end

	function M.rotatingPurchase(index, qty)
		return M.fire("RotatingShop", 0.7, "Purchase", index, qty or 1)
	end

	function M.rowboatPurchase()
		return M.fire("Ships", 1.0, "Purchase", { Type = "Rowboat" })
	end

	function M.shipSpawn(index)
		return M.fire("Ships", 1.2, "Spawn", index)
	end

	function M.heldEquip(id)
		return M.fire("HeldItem", 0.4, "Equip", id)
	end

	-- BackpackLocal.MoveToolToSlot → SaveOrder(slot, key)
	function M.saveOrder(slot, key)
		return M.fire("SaveOrder", 0.35, slot, key)
	end

	-- BindableEvent. BackpackLocal: Fire(true) selects topbar → OpenStorage.
	function M.backpackToggle(open)
		local ev = RS:FindFirstChild("Events")
		local b = ev and ev:FindFirstChild("BackpackToggle")
		if not b then
			return false
		end
		if not GB.Retry.rateOk("be:BackpackToggle", 0.35) then
			return false
		end
		local ok = pcall(function()
			if open == nil then
				b:Fire()
			else
				b:Fire(open and true or false)
			end
		end)
		return ok
	end

	function M.heldUnequip()
		return M.fire("HeldItem", 0.4, "Unequip")
	end

	function M.sell(key, amount)
		if amount then
			return M.fire("SellItem", 0.6, key, amount)
		end
		return M.fire("SellItem", 0.6, key)
	end

	function M.upgrade(key)
		return M.fire("Upgrade", 0.8, "Upgrade", key)
	end

	function M.pickupFruit(fruitId)
		return M.fire("PickupDF", 0.8, fruitId)
	end

	function M.storeFruit(name, force)
		if name then
			return M.fire("PermanentFruit", 0.8, "Store Fruit", name, force and true or nil)
		end
		return M.fire("PermanentFruit", 0.8, "Store Fruit")
	end

	function M.equipPermanentFruit(name, force)
		return M.fire("PermanentFruit", 0.8, "Equip Permanent Fruit", name, force and true or nil)
	end

	function M.changeStyle(name)
		return M.fire("ChangeFightingStyle", 0.8, name)
	end

	function M.promptSkillEquip(name)
		return M.fire("PromptSkillEquip", 0.6, name)
	end

	-- SkillHandler ToggleEquip: Events.Skill:FireServer("Equip"|"Unequip", skillName)
	function M.skillEquip(name)
		return M.fire("Skill", 0.55, "Equip", name)
	end

	function M.skillUnequip(name)
		return M.fire("Skill", 0.55, "Unequip", name)
	end

	-- ScrollFrameSlide ButtonPressed: ConsumeSkillScroll:FireServer(nil). Server reads HeldItem.
	function M.consumeSkillScroll()
		return M.fire("ConsumeSkillScroll", 0.7, nil)
	end

	-- ForceOpenLogbook after Tutorial/Controls sequence
	function M.openLogbookHelp()
		local ev = RS:FindFirstChild("Events")
		local folder = ev and ev:FindFirstChild("QuestEvents")
		local r = folder and folder:FindFirstChild("OpenLogbookHelp")
		if not r then
			GB.Log.warn("ERROR", "remote missing OpenLogbookHelp")
			return false, "missing"
		end
		if not GB.Retry.rateOk("re:OpenLogbookHelp", 1.0) then
			return false, "rate"
		end
		r:FireServer()
		return true
	end

	-- StarterPlayer Zones: ClientQuest(zoneName, "Enter Zone")
	function M.enterZone(zoneName)
		return M.fire("ClientQuest", 0.8, zoneName, "Enter Zone")
	end

	-- QuestInfo client + QuestLocal LoadQuests
	function M.getQuests()
		local r = ev("GetData")
		if not r then
			GB.Log.warn("ERROR", "remote missing GetData")
			return nil, nil
		end
		if not GB.Retry.rateOk("rf:GetDataQuests", 0.35) then
			return nil, nil
		end
		local ok, a, b = pcall(r.InvokeServer, r, "Quests", "Completed Quests")
		if not ok then
			GB.Log.err("ERROR", "GetData Quests " .. tostring(a))
			return nil, nil
		end
		return a, b
	end

	function M.code(str)
		return M.fire("Codes", 0.55, str)
	end

	function M.codeProg(...)
		return M.fire("CodeProg", 0.5, ...)
	end

	function M.getData(key)
		return M.invoke("GetData", key)
	end

	function M.getStats()
		local r = ev("GetStats")
		if not r then
			return nil, nil
		end
		if not r:IsA("RemoteFunction") then
			GB.Log.warn("ERROR", "GetStats type " .. tostring(r.ClassName))
			return nil, nil
		end
		if not GB.Retry.rateOk("rf:GetStats", 0.45) then
			return nil, nil
		end
		local ok, a, b = pcall(r.InvokeServer, r)
		if not ok then
			GB.Persist.failRemote("GetStats", a)
			return nil, nil
		end
		return a, b
	end

	function M.getEquip()
		return M.invoke("GetEquip")
	end

	function M.neverBeginQuest()
		-- rules.never_fire_beginquest
		return false
	end

	return M
end
