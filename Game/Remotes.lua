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
		return M.fire("StatPoints", 0.45, "Invest", stat, n or 1)
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
		return M.invoke("GetStats")
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
