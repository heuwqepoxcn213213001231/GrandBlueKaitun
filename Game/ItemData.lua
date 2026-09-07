-- KEEP / EQUIP / STORE / SELL / USE / QUEST_ITEM / UNKNOWN.
-- UNKNOWN = KEEP. Never sell rare / quest / fruit / progression.

return function(GB)
	local M = {}

	M.KEEP = {
		["Stolen Watch"] = "QUEST_ITEM",
		["Flintlock"] = "EQUIP",
		["Rusty Pickaxe"] = "EQUIP",
		["Rusty Shovel"] = "KEEP",
		["Transponder Snail"] = "EQUIP",
		["Rowboat"] = "KEEP",
		["Afuaru's Key"] = "QUEST_ITEM",
		["Pirate Fan Letter"] = "QUEST_ITEM",
		["Pirate's Ruby"] = "QUEST_ITEM",
		["Treasure Map (Easy)"] = "KEEP",
		["Treasure Map (Medium)"] = "KEEP",
		["Treasure Map (Hard)"] = "KEEP",
		["Treasure Map (Expert)"] = "KEEP",
		["Carbon Rod"] = "EQUIP",
		["Wooden Rod"] = "EQUIP",
		["Terry's Hat"] = "EQUIP",
		["Joe's Overalls (Outfit)"] = "EQUIP",
		["Chef Apron (Outfit)"] = "EQUIP",
		["Stone Ring"] = "KEEP",
		["Handle"] = "KEEP",
		["Telescope"] = "KEEP",
		["Muggy Ball"] = "KEEP",
		["Slingshot"] = "KEEP",
		["Strong Punch"] = "KEEP",
		["King's Punch"] = "KEEP",
		["[50%] Smuggler's Coupon"] = "KEEP",
		["Calvin's Treasure"] = "KEEP",
		["Worm"] = "USE",
		["Copper Ore"] = "KEEP",
		["Copper Bar"] = "KEEP",
		["Iron Ore"] = "KEEP",
		["Lead Ore"] = "KEEP",
		["Lead"] = "KEEP",
		["Lead Ball"] = "KEEP",
		["Gunpowder"] = "KEEP",
		["Cutlass"] = "EQUIP",
	}

	M.FRUITS = {
		Flame = true,
		Darkness = true,
		Invisibility = true,
		Spin = true,
		Chop = true,
		Bomb = true,
		Wolf = true,
		Clothing = true,
		Strength = true,
		Swim = true,
		Weight = true,
		Spike = true,
		Cannon = true,
		Drain = true,
		Light = true,
	}

	M.SHOP = {
		["Flintlock"] = { gold = 150, need = "Gearing Up" },
		["Cutlass"] = { gold = 200 },
		["Rowboat"] = { gold = 50, need = "Setting Sail", via = "Ships" },
		["Transponder Snail"] = { gold = 100, need = "A Voice in a Shell" },
		["Rusty Pickaxe"] = { gold = 25, need = "First Upgrade" },
		["Rusty Shovel"] = { gold = 25 },
		["Wooden Rod"] = { gold = 75 },
		["Worm"] = { gold = 5 },
		["Apple"] = { gold = 5 },
		["Lemon"] = { gold = 5 },
		["Banana"] = { gold = 5 },
		["Carrot"] = { gold = 5 },
		["Potato"] = { gold = 5 },
		["Eggplant"] = { gold = 5 },
		["Pet Food"] = { gold = 100 },
	}

	M.PROGRESS_BUY = { "Flintlock", "Rusty Pickaxe", "Transponder Snail", "Rowboat" }

	function M.kind(name)
		if not name then
			return "UNKNOWN"
		end
		if M.FRUITS[name] or string.find(name, "Fruit") then
			return "KEEP"
		end
		if M.KEEP[name] then
			return M.KEEP[name]
		end
		if string.find(name, "Recipe") or string.find(name, "Map") then
			return "KEEP"
		end
		if string.find(name, "Rep Punch") then
			return "KEEP"
		end
		return "UNKNOWN"
	end

	function M.canSell(name)
		local k = M.kind(name)
		if k == "UNKNOWN" or k == "KEEP" or k == "QUEST_ITEM" or k == "EQUIP" then
			return false
		end
		return k == "SELL"
	end

	function M.shopPrice(name)
		local r = M.SHOP[name]
		return r and r.gold
	end

	return M
end
