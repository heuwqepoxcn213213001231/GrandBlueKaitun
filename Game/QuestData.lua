-- Planner tables from data.json / picker. Kill-name fixes from Studio modules.

return function(GB)
	local M = {}

	M.CHAINS = {
		{
			island = "Anchor Town",
			order = {
				"Introduction", "Basics", "Pirate Fan Letter", "Gearing Up", "The Hoarder",
				"First Upgrade", "Tea Party Crashers", "Captain's Brat", "Feral Dog",
				"Gate of Authority", "Captive Swordsman", "Axe-Handed Tyrant",
				"A Voice in a Shell", "Setting Sail",
			},
		},
		{
			island = "Clown Town",
			order = {
				"A Joke Gone Too Far", "Sabotage The Cannon", "Lion's Victim", "Stephon's Tormentor",
				"Butcher's Business", "Circus Suppliers", "Clown Captives", "Revenge of the Nibblebottom",
				"Escort The Mayor", "Mayor's Stache", "Clown Town's Militia", "The Ringmaster",
				"Journey to Maple Village",
			},
		},
		{
			island = "Maple Village",
			order = {
				"The Island's Protector", "Proof of Pirates", "Something Isn't Right", "Pirate Instructions",
				"The Wandering Hypnotist", "The Beast of Maple Village", "Missing Servants",
				"Expose the Butler", "Raid Preparations", "Stocked for a Siege", "Destroy the Signalers",
				"The Black Noir Raid",
			},
		},
	}

	-- Studio: CreateCondition(v5, "Kill", "\"Barrel Clown\" Binki")
	-- Studio: CreateCondition(v7, "Kill", "\"Hypnotist\" Mango", 1)
	M.KILL_FIX = {
		["\\"] = nil,
	}

	M.KILL_BY_QUEST = {
		["Stephon's Tormentor"] = "\"Barrel Clown\" Binki",
		["The Wandering Hypnotist"] = "\"Hypnotist\" Mango",
	}

	M.GATES = {
		["The Hoarder"] = 7,
		["Captain's Brat"] = 15,
		["Feral Dog"] = 20,
		["Setting Sail"] = 30,
		["A Joke Gone Too Far"] = 30,
		["Sabotage The Cannon"] = 35,
		["Lion's Victim"] = 40,
		["Stephon's Tormentor"] = 43,
		["Butcher's Business"] = 45,
		["Circus Suppliers"] = 50,
		["Escort The Mayor"] = 58,
		["The Ringmaster"] = 60,
		["Journey to Maple Village"] = 70,
		["The Island's Protector"] = 70,
	}

	M.REPEATS = {
		{ name = "Bullies in Suits", island = "Anchor Town", accept = 0, full_until = 12, exp = 40, prereq = "Pirate Fan Letter" },
		{ name = "Officer Termination", island = "Anchor Town", accept = 0, full_until = 20, exp = 105, prereq = "Tea Party Crashers" },
		{ name = "Granny's Nemesis", island = "Anchor Town", accept = 0, full_until = 25, exp = 157, prereq = "Captain's Brat" },
		{ name = "Tyrannical Captain", island = "Anchor Town", accept = 0, full_until = 35, exp = 771, prereq = "Axe-Handed Tyrant" },
		{ name = "This Is Personal", island = "Clown Town", accept = 30, full_until = 45, exp = 268, prereq = "A Joke Gone Too Far" },
		{ name = "Cat Problem", island = "Clown Town", accept = 30, full_until = 50, exp = 827, prereq = "Lion's Victim" },
		{ name = "Billy's Business", island = "Clown Town", accept = 30, full_until = 60, exp = 494, prereq = "Butcher's Business" },
		{ name = "Nibblebottom's Revenge", island = "Clown Town", accept = 30, full_until = 65, exp = 494, prereq = "Revenge of the Nibblebottom" },
		{ name = "Choppy The Clown", island = "Clown Town", accept = 30, full_until = 75, exp = 1582, prereq = "The Ringmaster" },
		{ name = "Clear the Road", island = "Maple Village", accept = 70, full_until = 78, exp = 878, prereq = "The Island's Protector" },
		{ name = "Peace of Mind", island = "Maple Village", accept = 70, full_until = 81, exp = 1215, prereq = "The Island's Protector" },
	}

	-- Verified Studio: world model Name / CollectionService tag.
	-- Humanoid.DisplayName of Graves [2] is "Officer Graves". RS "Officer Graves" is character-create.
	M.NPC_ALIAS = {
		["Officer Graves"] = { "Officer Graves [2]", "Graves" },
		["Officer Graves [2]"] = { "Officer Graves", "Graves" },
		["Graves"] = { "Officer Graves", "Officer Graves [2]" },
	}

	M.TALK_NPC = {
		["Introduction"] = "Officer Graves",
		["Basics"] = "Officer Graves",
		["Pirate Fan Letter"] = "Officer Graves",
		["The Hoarder"] = "Troubled Civilian",
		["First Upgrade"] = "Blacksmith Shinozaki",
		["Tea Party Crashers"] = "Maeve",
		["Captain's Brat"] = "Granny Todo",
		["Captive Swordsman"] = "Captive Swordsman",
		["A Voice in a Shell"] = "Officer Graves",
		["Setting Sail"] = "Officer Graves",
		["A Joke Gone Too Far"] = "Clowny D. Clown",
		["Sabotage The Cannon"] = "Clowny D. Clown",
		["Lion's Victim"] = "Stephon",
		["Stephon's Tormentor"] = "Stephon",
		["Butcher's Business"] = "Billy B.",
		["Circus Suppliers"] = "Mayor Kiyoshi",
		["Clown Captives"] = "Mayor Kiyoshi",
		["Revenge of the Nibblebottom"] = "Johnny Nibblebottom",
		["Escort The Mayor"] = "Mayor Kiyoshi",
		["Mayor's Stache"] = "Mayor Kiyoshi [2]",
		["Clown Town's Militia"] = "Mayor Kiyoshi [2]",
		["The Ringmaster"] = "Mayor Kiyoshi [2]",
		["Journey to Maple Village"] = "Mayor Kiyoshi",
		["The Island's Protector"] = "Captain Esopo",
		["Proof of Pirates"] = "Captain Esopo",
		["Something Isn't Right"] = "Farmer Joe",
		["Pirate Instructions"] = "Captain Esopo",
		["The Wandering Hypnotist"] = "Captain Esopo",
		["The Beast of Maple Village"] = "Barry",
		["Missing Servants"] = "Kuro",
		["Expose the Butler"] = "Frightened Servant",
		["Raid Preparations"] = "Remy",
		["Stocked for a Siege"] = "Captain Esopo",
		["Destroy the Signalers"] = "Captain Esopo",
		["The Black Noir Raid"] = "Lady Maia",
		["Bullies in Suits"] = "Koro",
		["Officer Termination"] = "Maeve",
		["Granny's Nemesis"] = "Granny Todo",
		["This Is Personal"] = "Clowny D. Clown",
		["Cat Problem"] = "Stephon",
		["Billy's Business"] = "Billy B.",
		["Nibblebottom's Revenge"] = "Johnny Nibblebottom",
		["Choppy The Clown"] = "Mayor Kiyoshi [2]",
		["Clear the Road"] = "Nell",
		["Peace of Mind"] = "Gus",
	}

	M.QUEST_ISLAND = {}
	for _, ch in ipairs(M.CHAINS) do
		for _, name in ipairs(ch.order) do
			M.QUEST_ISLAND[name] = ch.island
		end
	end
	for _, e in ipairs(M.REPEATS) do
		M.QUEST_ISLAND[e.name] = e.island
	end

	M.AUTOMATIC = {
		["Introduction"] = true,
		["Basics"] = true,
		["Pirate Fan Letter"] = true,
		["Gearing Up"] = true,
		["The Hoarder"] = true,
		["First Upgrade"] = true,
		["Tea Party Crashers"] = true,
		["Captain's Brat"] = true,
		["Feral Dog"] = true,
		["Gate of Authority"] = true,
		["Captive Swordsman"] = true,
		["Axe-Handed Tyrant"] = true,
		["A Voice in a Shell"] = true,
		["Setting Sail"] = true,
		["A Joke Gone Too Far"] = true,
		["Sabotage The Cannon"] = true,
		["Lion's Victim"] = true,
		["Stephon's Tormentor"] = true,
		["Butcher's Business"] = true,
		["Circus Suppliers"] = true,
		["Clown Captives"] = true,
		["Revenge of the Nibblebottom"] = true,
		["Escort The Mayor"] = true,
		["Mayor's Stache"] = true,
		["Clown Town's Militia"] = true,
		["The Ringmaster"] = true,
		["Journey to Maple Village"] = true,
		["The Island's Protector"] = true,
		["Proof of Pirates"] = true,
		["Something Isn't Right"] = true,
		["Pirate Instructions"] = true,
		["The Wandering Hypnotist"] = true,
		["The Beast of Maple Village"] = true,
		["Missing Servants"] = true,
		["Expose the Butler"] = true,
		["Raid Preparations"] = true,
		["Stocked for a Siege"] = true,
		["Destroy the Signalers"] = true,
		["The Black Noir Raid"] = true,
	}

	M.NEED_ITEM = {
		["Flintlock"] = { gold = 150, quest = "Gearing Up" },
		["Rusty Pickaxe"] = { gold = 25, quest = "First Upgrade" },
		["Transponder Snail"] = { gold = 100, quest = "A Voice in a Shell" },
		["Rowboat"] = { gold = 50, quest = "Setting Sail" },
	}

	function M.killName(questName, raw)
		if M.KILL_BY_QUEST[questName] then
			return M.KILL_BY_QUEST[questName]
		end
		if raw == "\\" or raw == "" then
			return nil
		end
		return raw
	end

	function M.needLevel(name)
		return M.GATES[name] or 0
	end

	function M.prereqOk(prereq)
		if not prereq then
			return true
		end
		return GB.PlayerData.finished(prereq)
	end

	function M.currentStage(q)
		if type(q) ~= "table" or type(q.Stages) ~= "table" then
			return nil, nil
		end
		for i, st in ipairs(q.Stages) do
			if not st.Complete then
				return i, st
			end
		end
		return #q.Stages, q.Stages[#q.Stages]
	end

	function M.conditionTarget(cond)
		if type(cond) ~= "table" then
			return nil
		end
		local t = cond.Target
		if type(t) == "table" then
			return t.Name or t.name
		end
		if type(t) == "string" then
			return t
		end
		return cond.target or cond.Name
	end

	function M.conditionAmount(cond)
		if type(cond) ~= "table" then
			return 1
		end
		return tonumber(cond.Amount) or tonumber(cond.amount) or 1
	end

	function M.conditionCurrent(cond)
		if type(cond) ~= "table" then
			return 0
		end
		if cond.Complete then
			return M.conditionAmount(cond)
		end
		return tonumber(cond.Current)
			or tonumber(cond.Count)
			or tonumber(cond.Progress)
			or tonumber(cond.Value)
			or 0
	end

	function M.islandOf(name)
		return M.QUEST_ISLAND[name]
	end

	function M.talkNpc(name)
		return M.TALK_NPC[name]
	end

	if GB.Resolver then
		GB.Resolver.NPC_ALIAS = M.NPC_ALIAS
	end

	return M
end
