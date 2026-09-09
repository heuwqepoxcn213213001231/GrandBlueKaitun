-- Studio-backed names for UI classification only.
-- No stats, prices, drops, or action support are inferred from these lists.

return function(GB)
	local M = {
		Status = "STATIC_VERIFIED_NAMES_ONLY",
		Islands = { "Anchor Town", "Clown Town", "Maple Village" },
		Fruits = {
			"Flame", "Darkness", "Invisibility", "Spin", "Chop", "Bomb", "Wolf",
			"Clothing", "Strength", "Swim", "Weight", "Spike", "Cannon", "Drain", "Light",
		},
		Weapons = {
			"Cutlass", "Sandai Kitetsu", "Axe-Hand", "Katana", "Saw Blade", "Musket",
			"Iron Mace", "Slingshot", "Battle Axe", "Yoru", "Cat Claws", "Captain's Claws",
			"Sturdy Stick", "Broken Ritual Dagger", "Killer Knife", "Last Laugh",
			"Gilded Sabre", "Black Briar", "Willow Blade",
		},
		Subweapons = {
			"Flammable Liquid", "Small Hammer", "Flintlock", "Muggy Ball",
			"Clown Knives", "Hypnotist Chakram", "Show Stopper", "Daddy's Gift",
		},
		Hats = {
			"Scrap Metal Jaw", "Marine Cap", "Kuro's Spectacles", "Choppy's Hat",
			"Hypnotist Fedora", "Captain Esopo's Hat", "Nyaban Ears", "Terry's Hat", "Bear Head",
		},
		Pickaxes = {
			"Rusty Pickaxe", "Steel Pickaxe", "Obsidian Pickaxe", "Silver Pickaxe",
			"Golden Pickaxe", "Emerald Pickaxe", "Diamond Pickaxe",
		},
		FishingRods = {
			"Carbon Rod", "Wooden Rod", "Fiberglass Rod", "Silverline Rod",
			"Deep-Sea Rod", "Terry's Trusted Rod", "Celestial Rod",
		},
		Ores = {
			"Copper Ore", "Diamond Ore", "Emerald Ore", "Gold Ore",
			"Iron Ore", "Silver Ore", "Lead Ore", "Obsidian",
		},
		Bars = { "Iron Bar", "Silver Bar", "Gold Bar", "Copper Bar", "Lead" },
		Gems = { "Emerald", "Diamond", "Ruby", "Sapphire", "Quartz", "Topaz" },
		Fish = {
			"Goldfish", "Sardine", "Tuna", "Clownfish", "Salmon", "Turtle", "Yang Koi", "Yin Koi",
			"Rock", "Shoe", "Carp", "Skipjack Tuna", "Red Seahorse", "Green Seahorse",
			"Tomato Clownfish", "Darwin Clownfish", "Pink Skunk Clownfish", "Blue Tang",
			"Powder Blue Tang", "Flame Angelfish", "Wyoming White Clownfish", "Queen Angelfish",
			"Moorish Idol", "Spotted Eagle Ray", "Manta Ray", "Pink Dolphin", "Bluebanded Goby",
			"Greenbanded Goby", "Kaudern's Cardinalfish", "Golden Dottyback", "Fire Goby",
			"Black Seahorse", "Lobster", "Blackcap Basslet", "Blue Lobster", "Pygmy Seahorse",
			"Candy Basslet", "Juggalo Clownfish",
		},
		TreasureMaps = {
			"Treasure Map (Easy)", "Treasure Map (Medium)",
			"Treasure Map (Hard)", "Treasure Map (Expert)",
		},
		WorldBossChests = {
			"World Boss Chest (Logan)", "World Boss Chest (Choppy)", "World Boss Chest (Kuro)",
		},
	}

	M.Category = {}
	for category, values in pairs({
		Weapon = M.Weapons,
		Subweapon = M.Subweapons,
		Hat = M.Hats,
		Pickaxe = M.Pickaxes,
		FishingRod = M.FishingRods,
		Fruit = M.Fruits,
		Ore = M.Ores,
		Bar = M.Bars,
		Gem = M.Gems,
		Fish = M.Fish,
		TreasureMap = M.TreasureMaps,
		WorldBossChest = M.WorldBossChests,
	}) do
		for _, name in ipairs(values) do
			M.Category[name] = category
		end
	end

	function M.categoryOf(name)
		return M.Category[name] or "UNKNOWN"
	end

	function M.isEquipment(name)
		local category = M.categoryOf(name)
		return category == "Weapon"
			or category == "Subweapon"
			or category == "Hat"
			or category == "Pickaxe"
			or category == "FishingRod"
	end

	return M
end
