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

	-- If Completed Quests is empty, level still proves these story beats are behind us.
	M.STORY_DONE_AT = {
		["Introduction"] = 6,
		["Basics"] = 6,
		["Pirate Fan Letter"] = 8,
		["Gearing Up"] = 8,
		["The Hoarder"] = 12,
		["First Upgrade"] = 12,
		["Tea Party Crashers"] = 14,
		["Captain's Brat"] = 20,
		["Feral Dog"] = 24,
		["Gate of Authority"] = 26,
		["Captive Swordsman"] = 26,
		["Axe-Handed Tyrant"] = 26,
		["A Voice in a Shell"] = 26,
	}

	M.SIDES = {
		{ name = "Advanced Training", island = "Anchor Town", accept = 0, prereq = "Tea Party Crashers" },
	}

	M.REPEATS = {
		{ name = "Bullies in Suits", island = "Anchor Town", accept = 0, full_until = 12, exp = 40, prereq = "Pirate Fan Letter" },
		{ name = "Officer Termination", island = "Anchor Town", accept = 0, full_until = 30, exp = 105, prereq = "Tea Party Crashers" },
		{ name = "Granny's Nemesis", island = "Anchor Town", accept = 0, full_until = 30, exp = 157, prereq = "Captain's Brat" },
		{ name = "Tyrannical Captain", island = "Anchor Town", accept = 0, full_until = 35, exp = 771, prereq = "Axe-Handed Tyrant" },
		{ name = "This Is Personal", island = "Clown Town", accept = 30, full_until = 45, exp = 268, prereq = "A Joke Gone Too Far" },
		{ name = "Cat Problem", island = "Clown Town", accept = 30, full_until = 50, exp = 827, prereq = "Lion's Victim" },
		{ name = "Billy's Business", island = "Clown Town", accept = 30, full_until = 60, exp = 494, prereq = "Butcher's Business" },
		{ name = "Nibblebottom's Revenge", island = "Clown Town", accept = 30, full_until = 65, exp = 494, prereq = "Revenge of the Nibblebottom" },
		{ name = "Choppy The Clown", island = "Clown Town", accept = 30, full_until = 75, exp = 1582, prereq = "The Ringmaster" },
		{ name = "Clear the Road", island = "Maple Village", accept = 70, full_until = 78, exp = 878, prereq = "The Island's Protector" },
		{ name = "Peace of Mind", island = "Maple Village", accept = 70, full_until = 81, exp = 1215, prereq = "The Island's Protector" },
	}

	M.REPEAT_START = {
		["Bullies in Suits"] = {
			Status = "STARTABLE",
			Automatic = false,
			AcceptNPC = "Koro",
			TurnInNPC = "Koro",
			OtherVerifiedStartMethod = nil,
			DirectCombatVerified = false,
		},
		["Officer Termination"] = {
			Status = "STARTABLE",
			Automatic = false,
			AcceptNPC = "Maeve",
			TurnInNPC = "Maeve",
			OtherVerifiedStartMethod = nil,
			DirectCombatVerified = false,
		},
		["Granny's Nemesis"] = {
			Status = "STARTABLE",
			Automatic = false,
			AcceptNPC = "Granny Todo",
			TurnInNPC = "Granny Todo",
			OtherVerifiedStartMethod = nil,
			DirectCombatVerified = false,
		},
		["Tyrannical Captain"] = {
			Status = "UNRESOLVED_START",
			Automatic = false,
			AcceptNPC = nil,
			TurnInNPC = nil,
			OtherVerifiedStartMethod = nil,
			DirectCombatVerified = false,
		},
		["This Is Personal"] = {
			Status = "STARTABLE",
			Automatic = false,
			AcceptNPC = "Clowny D. Clown",
			TurnInNPC = "Clowny D. Clown",
			OtherVerifiedStartMethod = nil,
			DirectCombatVerified = false,
		},
		["Cat Problem"] = {
			Status = "STARTABLE",
			Automatic = false,
			AcceptNPC = "Stephon",
			TurnInNPC = "Stephon",
			OtherVerifiedStartMethod = nil,
			DirectCombatVerified = false,
		},
		["Billy's Business"] = {
			Status = "STARTABLE",
			Automatic = false,
			AcceptNPC = "Billy B.",
			TurnInNPC = "Billy B.",
			OtherVerifiedStartMethod = nil,
			DirectCombatVerified = false,
		},
		["Nibblebottom's Revenge"] = {
			Status = "STARTABLE",
			Automatic = false,
			AcceptNPC = "Johnny Nibblebottom",
			TurnInNPC = "Johnny Nibblebottom",
			OtherVerifiedStartMethod = nil,
			DirectCombatVerified = false,
		},
		["Choppy The Clown"] = {
			Status = "STARTABLE",
			Automatic = false,
			AcceptNPC = "Mayor Kiyoshi [2]",
			TurnInNPC = "Mayor Kiyoshi [2]",
			OtherVerifiedStartMethod = nil,
			DirectCombatVerified = false,
		},
		["Clear the Road"] = {
			Status = "STARTABLE",
			Automatic = false,
			AcceptNPC = "Nell",
			TurnInNPC = "Nell",
			OtherVerifiedStartMethod = nil,
			DirectCombatVerified = false,
		},
		["Peace of Mind"] = {
			Status = "STARTABLE",
			Automatic = false,
			AcceptNPC = "Gus",
			TurnInNPC = "Gus",
			OtherVerifiedStartMethod = nil,
			DirectCombatVerified = false,
		},
	}

	-- Verified Studio: world model Name / CollectionService tag.
	-- Humanoid.DisplayName of Graves [2] is "Officer Graves". RS "Officer Graves" is character-create.
	M.NPC_ALIAS = {
		["Officer Graves"] = { "Officer Graves [2]", "Graves" },
		["Officer Graves [2]"] = { "Officer Graves", "Graves" },
		["Graves"] = { "Officer Graves", "Officer Graves [2]" },
		["Granny Todo"] = { "Granny Todo [1]", "Granny Todo [2]" },
		["Granny Todo [1]"] = { "Granny Todo", "Granny Todo [2]" },
		["Granny Todo [2]"] = { "Granny Todo", "Granny Todo [1]" },
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
		["Advanced Training"] = "Officer Graves [2]",
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
	for _, e in ipairs(M.SIDES) do
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
		["Advanced Training"] = true,
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

	function M.impliedFinished(name, lv)
		if type(name) ~= "string" or name == "" then
			return false
		end
		lv = tonumber(lv) or 0
		local cut = M.STORY_DONE_AT[name]
		if cut and lv >= cut then
			return true
		end
		for _, ch in ipairs(M.CHAINS) do
			local idx
			for i, n in ipairs(ch.order) do
				if n == name then
					idx = i
					break
				end
			end
			if idx then
				for j = idx + 1, #ch.order do
					local g = M.GATES[ch.order[j]]
					if g and lv >= g then
						return true
					end
				end
				break
			end
		end
		return false
	end

	function M.prereqOk(prereq)
		if not prereq then
			return true
		end
		return GB.PlayerData.finished(prereq, true)
	end

	-- Studio QuestInfoUtilities.CreateCondition Target = { Amount, Name, RequiredAmount }
	M.MARKER_TAG = {
		["Reach Maple Village"] = "Maple Village Marker",
		["Investigate The Footsteps (1)"] = "Campsite Footsteps Marker",
		["Investigate The Footsteps (2)"] = "Campsite Footsteps Marker",
		["Investigate The Wreckage"] = "Beast Wreckage Marker",
		["Investigate The Beast's Den"] = "Beast Den Marker",
		["Investigate The Garden"] = "Mansion Garden Marker",
		["Investigate The Fountain"] = "Mansion Fountain Marker",
		["Unlock"] = "Afuaru's Gate",
	}

	M.DELIVER = {
		["Stolen Goods"] = { object = "StolenGoods", location = "Esopo Delivery" },
	}

	-- Verified semantic world object mapping used by resolver/planner.
	-- Destroy targets are CollectionService tags / world models, not Entities enemies.
	M.OBJECT_TARGETS = {
		["Marine Gate"] = {
			Island = "Anchor Town",
			Path = { "Islands", "Anchor Town", "Island", "Gate" },
			Tags = { "Marine Metal Gate", "Gate" },
			Prompts = { "Pushable Door" },
		},
		["Muggy Cannon"] = {
			Island = "Clown Town",
			Tags = { "Muggy Cannon" },
		},
		["Air Balloon"] = {
			Island = "Clown Town",
			Tags = { "Air Balloon" },
		},
		["Explosive Wooden Crate"] = {
			Island = "Clown Town",
			Tags = { "Explosive Wooden Crate" },
		},
		["Supply Crate"] = {
			Island = "Maple Village",
			Tags = { "Supply Crate" },
		},
		["North Camp Signal Fire"] = {
			Island = "Maple Village",
			Tags = { "North Camp Signal Fire" },
		},
		["South Camp Signal Fire"] = {
			Island = "Maple Village",
			Tags = { "South Camp Signal Fire" },
		},
		["Overlook Signal Fire"] = {
			Island = "Maple Village",
			Tags = { "Overlook Signal Fire" },
		},
	}

	M.QUEST_REQUIREMENTS = {
		["Gate of Authority"] = {
			Strength = 100,
			Status = "IMPLEMENTED_UNVERIFIED",
			Reason = "Gate push interaction appears strength-gated; runtime validate while quest executes.",
		},
	}

	local function copyRow(src)
		if type(src) ~= "table" then
			return nil
		end
		local out = {}
		for k, v in pairs(src) do
			out[k] = v
		end
		return out
	end

	function M.currentStage(q)
		if type(q) ~= "table" or type(q.Stages) ~= "table" then
			return nil, nil
		end
		for i, st in ipairs(q.Stages) do
			if type(st) == "table" and not M.stageComplete(st) then
				return i, st
			end
		end
		return #q.Stages, q.Stages[#q.Stages]
	end

	function M.stageComplete(st)
		if type(st) ~= "table" then
			return true
		end
		if st.Complete then
			return true
		end
		local conds = st.Conditions or st.conditions
		if type(conds) ~= "table" or #conds == 0 then
			return st.Complete == true
		end
		for _, cond in ipairs(conds) do
			if type(cond) == "table" and not M.conditionComplete(cond) then
				return false
			end
		end
		return true
	end

	function M.conditionTarget(cond)
		if type(cond) ~= "table" then
			return nil
		end
		local t = cond.Target
		if type(t) == "table" then
			local n = t.Name or t.name
			if type(n) == "string" and n ~= "" then
				return n
			end
		end
		if type(t) == "string" and t ~= "" then
			return t
		end
		return cond.target or cond.Name
	end

	function M.conditionAmount(cond)
		if type(cond) ~= "table" then
			return 1
		end
		local t = cond.Target
		if type(t) == "table" then
			return tonumber(t.RequiredAmount) or tonumber(t.requiredAmount) or 1
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
		local t = cond.Target
		if type(t) == "table" then
			return tonumber(t.Amount) or tonumber(t.Current) or 0
		end
		return tonumber(cond.Current)
			or tonumber(cond.Count)
			or tonumber(cond.Progress)
			or tonumber(cond.Value)
			or 0
	end

	function M.conditionComplete(cond)
		if type(cond) ~= "table" then
			return true
		end
		if cond.Complete then
			return true
		end
		return M.conditionCurrent(cond) >= M.conditionAmount(cond)
	end

	function M.markerOf(typ, target)
		if typ == "Unlock" then
			return target or M.MARKER_TAG.Unlock
		end
		return M.MARKER_TAG[typ] or target
	end

	function M.combatMarker(questName, stage, typ, target)
		if GB.QuestSpecs and GB.QuestSpecs.lookup then
			local spec = GB.QuestSpecs.lookup(questName, stage, typ, target)
			if spec and type(spec.marker) == "string" and spec.marker ~= "" and spec.marker ~= "\\" then
				return spec.marker
			end
		end
		return M.markerOf(typ, target)
	end

	function M.deliverSpec(target)
		return M.DELIVER[target]
	end

	function M.objectSpec(target)
		return M.OBJECT_TARGETS[target]
	end

	function M.isObjectTarget(target)
		return type(target) == "string" and M.OBJECT_TARGETS[target] ~= nil
	end

	function M.hasDestroyStage(name)
		if type(name) ~= "string" or name == "" then
			return false
		end
		if not M._destroyQuestReady then
			if not (GB.QuestSpecs and GB.QuestSpecs.STAGES) then
				return name == "Sabotage The Cannon"
					or name == "Undermine The Circus 1"
					or name == "Revenge of the Nibblebottom"
					or name == "Destroy the Signalers"
					or name == "Something Isn't Right"
			end
			M._destroyQuest = {}
			for _, spec in pairs(GB.QuestSpecs.STAGES) do
				if type(spec) == "table" and spec.quest and spec.objective == "Destroy" then
					M._destroyQuest[spec.quest] = true
				end
			end
			M._destroyQuestReady = true
		end
		return M._destroyQuest[name] == true
	end

	function M.questRequirement(name)
		return M.QUEST_REQUIREMENTS[name]
	end

	function M.islandOf(name)
		return M.QUEST_ISLAND[name]
	end

	function M.talkNpc(name)
		return M.TALK_NPC[name]
	end

	function M.repeatEntry(name)
		if type(name) ~= "string" or name == "" then
			return nil
		end
		for _, row in ipairs(M.REPEATS) do
			if row.name == name then
				return row
			end
		end
		return nil
	end

	function M.isRepeatable(name)
		return M.repeatEntry(name) ~= nil or M.REPEAT_START[name] ~= nil
	end

	function M.repeatStartSpec(name)
		local base = copyRow(M.REPEAT_START[name])
		if not base then
			local npc = M.TALK_NPC[name]
			base = {
				Status = npc and "STARTABLE" or "UNRESOLVED_START",
				Automatic = M.AUTOMATIC[name] == true,
				AcceptNPC = npc,
				TurnInNPC = npc,
				OtherVerifiedStartMethod = nil,
				DirectCombatVerified = false,
			}
		end
		if base.AcceptNPC == nil then
			local npc = M.TALK_NPC[name]
			if type(npc) == "string" and npc ~= "" then
				base.AcceptNPC = npc
			end
		end
		if base.TurnInNPC == nil and type(base.AcceptNPC) == "string" then
			base.TurnInNPC = base.AcceptNPC
		end
		if base.Automatic == nil then
			base.Automatic = M.AUTOMATIC[name] == true
		end
		if base.Status == nil then
			base.Status = (base.Automatic or (type(base.AcceptNPC) == "string" and base.AcceptNPC ~= ""))
				and "STARTABLE"
				or "UNRESOLVED_START"
		end
		if base.DirectCombatVerified == nil then
			base.DirectCombatVerified = false
		end
		return base
	end

	if GB.Resolver then
		GB.Resolver.NPC_ALIAS = M.NPC_ALIAS
	end

	return M
end
