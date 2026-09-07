-- Grand Blue Kaitun — Config
-- Override via getgenv().GBConfig before load, or mutate after.

return function(GB)
	local C = getgenv().GBConfig
	if type(C) ~= "table" then
		C = {}
		getgenv().GBConfig = C
	end

	local function def(k, v)
		if C[k] == nil then
			C[k] = v
		end
	end

	def("Enabled", true)
	def("Tick", 0.4)
	def("LogLevel", "INFO") -- DEBUG INFO WARN ERROR
	def("Persist", true)

	-- Auto flags
	def("AutoQuest", true)
	def("AutoLevel", true)
	def("AutoCombat", true)
	def("AutoStats", true)
	def("AutoSkills", true)
	def("AutoEquip", true)
	def("AutoShop", true)
	def("AutoTravel", true)
	def("AutoBoat", true)
	def("AutoInventory", true)
	def("AutoBackpack", false) -- upgrade path UNRESOLVED
	def("AutoFruit", true)
	def("AutoHaki", false) -- trainer UNRESOLVED
	def("AutoRaceTrait", false) -- default off; no spam reroll
	def("AutoBoss", true)
	def("AutoChest", true)
	def("AutoTreasure", true)
	def("AutoMining", true)
	def("AutoFishing", true)
	def("AutoFarming", true)
	def("AutoCooking", true)
	def("AutoCodes", true)
	def("AutoRewards", true)
	def("AutoTutorial", true)

	-- Build: Balanced | Strength | Sword | Gun | Fruit | Hybrid
	def("Build", "Balanced")
	def("FruitMode", "KEEP_CURRENT") -- KEEP_CURRENT | DesiredFruits
	def("DesiredFruits", { "Flame", "Darkness", "Light", "Chop" })

	def("Codes", {
		"Release!",
		"HappySunday",
		"TwitterGoalReached",
		"SorryForBreakingGame",
		"10KCCU",
		"WorldBossBroke",
		"NewYouNewCrew",
		"FruitBasket",
	})

	def("TalkRange", 14)
	def("TalkOffset", 5)
	def("CombatRange", 5.5)
	def("DummyBeside", 3.2)
	def("QuestMaxRetries", 5)
	def("ResolveDeepAfter", 3)
	def("DestYMin", 8)
	def("DestYMax", 180)
	def("MoveHop", 45)
	def("StuckSeconds", 18)
	def("RecoveryCooldown", 8)
	def("ActionTimeout", 25)
	def("MaxRetries", 3)

	-- HARD: do not skip these after RE
	def("NeverSkip", {
		["Escort The Mayor"] = true,
		["The Wandering Hypnotist"] = true,
	})

	-- Skip test / archived / empty stubs
	def("SkipQuests", {
		["Debug Quest"] = true,
		["Debug Quest 2"] = true,
		["Daily Quest Test"] = true,
		["Weekly Quest Test"] = true,
		["Jack's Daily Haul"] = true,
		["Kim Wu's Daily Quota"] = true,
		["Joe's Daily Chores"] = true,
		["Remy's Daily Order"] = true,
		["The Stolen Tip Jar"] = true,
		["Officer Investigation"] = true,
		["Leveling Skill"] = true,
		["Aim Training"] = true,
	})

	return C
end
