-- Mining: Ore prompt EquipAndActivateBindable("Pickaxe") VERIFIED.
-- PickaxeHit args computed by tool — do not invent.
-- Fishing/Farm/Cook: move + prompt only; timing windows UNKNOWN.

return function(GB)
	local RS = game:GetService("ReplicatedStorage")
	local M = {}

	local function fireActivate(kind)
		local b = RS:FindFirstChild("Events") and RS.Events:FindFirstChild("EquipAndActivateBindable")
		if b then
			pcall(function()
				b:Fire(kind)
			end)
			return true
		end
		return false
	end

	function M.mineToward(target)
		if not GB.Config.AutoMining then
			return false
		end
		if GB.PlayerData.hasItem("Rusty Pickaxe") then
			GB.Equipment.equipNamed("Rusty Pickaxe")
		end
		local ore = GB.Resolver.byName(target) or GB.Resolver.ore()
		if not ore then
			GB.Log.warn("MINING", "ore miss " .. tostring(target))
			return false
		end
		if GB.World.ToInteractable then
			GB.World.ToInteractable(ore, 6)
		else
			GB.World.moveTo(ore, 7)
		end
		fireActivate("Pickaxe")
		GB.Log.log("MINING", "activate at " .. ore.Name)
		return true
	end

	function M.smeltToward(target)
		local station = (GB.Resolver.taggedAny and GB.Resolver.taggedAny("Furnace")) or GB.Resolver.byName("Furnace")
		if not station then
			GB.Log.warn("SMELT", "furnace miss " .. tostring(target))
			return false
		end
		if GB.World.interact then
			GB.World.interact(station, 8)
		else
			GB.World.moveTo(station, 8)
		end
		GB.Log.log("SMELT", tostring(target) .. " at Furnace")
		return true
	end

	function M.fishToward(target)
		if not GB.Config.AutoFishing then
			return false
		end
		local rod = GB.PlayerData.hasItem("Carbon Rod") and "Carbon Rod" or (GB.PlayerData.hasItem("Wooden Rod") and "Wooden Rod")
		if rod then
			GB.Equipment.equipNamed(rod)
		end
		local shop = GB.Resolver.byName("Anchor Town Fishing Shop") or GB.Resolver.shopItem("Wooden Rod")
		if shop then
			GB.World.moveTo(shop, 12)
		end
		GB.Log.log("FISHING", "at water for " .. tostring(target) .. " (cast remote args UNRESOLVED)")
		return true
	end

	function M.farmToward(typ, target)
		if not GB.Config.AutoFarming then
			return false
		end
		local obj = GB.Resolver.byName(target) or GB.Resolver.byName("Seed")
		if obj then
			GB.World.moveTo(obj, 8)
			local pr = GB.Resolver.prompt(obj)
			if pr then
				GB.World.firePrompt(pr)
			end
			return true
		end
		GB.Log.warn("FARMING", typ .. " miss " .. tostring(target))
		return false
	end

	function M.cookToward(target)
		if not GB.Config.AutoCooking then
			return false
		end
		local obj = GB.Resolver.byName(target) or GB.Resolver.byName("Remy")
		if obj then
			GB.World.moveTo(obj, 8)
			return true
		end
		return false
	end

	function M.tick()
	end

	return M
end
