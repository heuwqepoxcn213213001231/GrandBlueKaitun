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
	def("Debug", false)
	def("Persist", true)
	def("RuntimeDiagnostics", true)
	def("RuntimeLogMaxBytes", 450000)
	def("RuntimeLogMaxFiles", 5)
	def("PerfDebug", true)
	def("PerfReportInterval", 35)
	def("DebugResolverDeepScan", false)
	def("DebugAcquireDeepScan", false)
	def("DebugWorldDeepScan", false)

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
	def("AutoBackpack", false) -- slot-upgrade UNRESOLVED; Open/Equip still used by Tutorial/Equipment
	def("AutoFruit", true)
	def("AutoHaki", false) -- trainer UNRESOLVED
	def("AutoRaceTrait", false) -- default off; no spam reroll
	def("StoryFirst", true) -- Fruit/Haki/Race do not interrupt story
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

	-- Build: Melee | Balanced | Strength | Sword | Gun | Fruit | Hybrid
	-- StatRatio is live current totals, not a dump of unused points. 8 Str : 2 Health.
	def("Build", "Melee")
	def("StatRatio", { Strength = 8, Health = 2 })
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
	def("CombatHoverHeight", 20)
	C.CombatHoverHeight = 20
	def("DummyBeside", 3.2)
	def("ShootRange", 9)
	def("QuestMaxRetries", 5)
	def("ResolveDeepAfter", 3)
	def("DestYMin", 0)
	def("DestYMax", 260)
	def("MaxTravelHop", 800)
	def("MoveHop", 45)
	def("TweenSpeed", 95)
	def("TweenMaxDur", 1.8)
	def("StuckSeconds", 18)
	def("RecoveryCooldown", 8)
	def("CombatMode", "SAFE_FAST") -- NORMAL | SAFE_FAST
	def("CombatDashWeave", false)
	def("CombatDashWeaveGap", 0.12)
	def("CombatAttackPulse", false)
	def("CombatAttackPulseGap", 0.06)
	def("CombatSwingBypass", false)
	C.CombatDashWeave = false
	C.CombatAttackPulse = false
	C.CombatSwingBypass = false
	def("CombatDebug", false)
	def("ActionTimeout", 25)
	def("MaxRetries", 3)
	def("QuestMaxAcquireCycles", 8)
	def("DropWindow", 4)

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
