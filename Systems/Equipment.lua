-- HeldItem Equip/Unequip VERIFIED. Gear Equip RF args UNKNOWN — do not invent Invoke.

return function(GB)
	local M = {}

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
			if type(v) == "table" and v.Name == name then
				return v.Key or k or name
			end
		end
		return name
	end

	function M.equipNamed(name)
		if not name then
			return false
		end
		local key = findInvKey(name)
		GB.Log.log("EQUIP", "HeldItem Equip " .. tostring(key))
		return GB.Remotes.heldEquip(key)
	end

	function M.upgradeNamed(name)
		local key = findInvKey(name or "Flintlock")
		GB.Log.log("EQUIP", "Upgrade " .. tostring(key))
		local before = GB.PlayerData.hasItem(name or "Flintlock")
		local ok = GB.Remotes.upgrade(key)
		task.wait(0.3)
		return ok
	end

	function M.tick()
		if not GB.Config.AutoEquip then
			return
		end
		-- story-forced only; rarity ≠ better
		if GB.PlayerData.live("Gearing Up") or GB.PlayerData.live("First Upgrade") then
			if GB.PlayerData.hasItem("Flintlock") then
				M.equipNamed("Flintlock")
			end
		end
		if GB.PlayerData.live("A Voice in a Shell") and GB.PlayerData.hasItem("Transponder Snail") then
			M.equipNamed("Transponder Snail")
		end
		if GB.PlayerData.live("First Upgrade") and GB.PlayerData.hasItem("Rusty Pickaxe") then
			M.equipNamed("Rusty Pickaxe")
		end
	end

	return M
end
