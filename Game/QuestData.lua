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
		["Stephon's Tormentor"] = "Stephon",
		["The Island's Protector"] = "Captain Esopo",
		["The Wandering Hypnotist"] = "Captain Esopo",
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

	return M
end
