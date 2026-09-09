-- Grand Blue — picker theo level + Completed Quests. Rules inline (not readfile).
-- P.pick() → {kind, name, island, why} hoặc nil
-- Stop: không loop farm; chỉ chọn quest.

local RS = game:GetService("ReplicatedStorage")
local lp = game:GetService("Players").LocalPlayer
local Cache = require(RS.Modules.ClientCache)
local Stat = require(RS.Modules.StatSystem)

local P = {}

local SKIP = {
	["Debug Quest"] = true,
	["Debug Quest 2"] = true,
	["Daily Quest Test"] = true,
	["Weekly Quest Test"] = true,
}

local CHAINS = {
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

local ENTRIES = {{
  name = "A Voice in a Shell",
  kind = "story",
  island = "Anchor Town",
  need_level = 0,
  accept_level = 0,
  level_gates = {},
  prerequisites = {"Axe-Handed Tyrant"},
  unlocks_next = "Setting Sail",
  automatic = true,
  exp = 385
}, {
  name = "Advanced Training",
  kind = "story",
  island = "Anchor Town",
  need_level = 0,
  accept_level = 0,
  level_gates = {},
  prerequisites = {"Tea Party Crashers"},
  unlocks_next = nil,
  automatic = true,
  exp = 20
}, {
  name = "Axe-Handed Tyrant",
  kind = "story",
  island = "Anchor Town",
  need_level = 0,
  accept_level = 0,
  level_gates = {},
  prerequisites = {"Captive Swordsman"},
  unlocks_next = "A Voice in a Shell",
  automatic = false,
  exp = 1065
}, {
  name = "Basics",
  kind = "story",
  island = "Anchor Town",
  need_level = 0,
  accept_level = 0,
  level_gates = {},
  prerequisites = {"Introduction"},
  unlocks_next = "Pirate Fan Letter",
  automatic = true,
  exp = 10
}, {
  name = "Captain's Brat",
  kind = "story",
  island = "Anchor Town",
  need_level = 15,
  accept_level = 0,
  level_gates = {15},
  prerequisites = {"Tea Party Crashers"},
  unlocks_next = "Feral Dog",
  automatic = true,
  exp = 207
}, {
  name = "Captive Swordsman",
  kind = "story",
  island = "Anchor Town",
  need_level = 0,
  accept_level = 0,
  level_gates = {},
  prerequisites = {"Gate of Authority"},
  unlocks_next = nil,
  automatic = true,
  exp = 325
}, {
  name = "Feral Dog",
  kind = "story",
  island = "Anchor Town",
  need_level = 20,
  accept_level = 0,
  level_gates = {20},
  prerequisites = {"Captain's Brat"},
  unlocks_next = "Gate of Authority",
  automatic = true,
  exp = 20
}, {
  name = "First Upgrade",
  kind = "story",
  island = "Anchor Town",
  need_level = 0,
  accept_level = 0,
  level_gates = {},
  prerequisites = {"The Hoarder"},
  unlocks_next = "Tea Party Crashers",
  automatic = true,
  exp = 20
}, {
  name = "Gate of Authority",
  kind = "story",
  island = "Anchor Town",
  need_level = 0,
  accept_level = 0,
  level_gates = {},
  prerequisites = {"Feral Dog"},
  unlocks_next = nil,
  automatic = true,
  exp = 310
}, {
  name = "Gearing Up",
  kind = "story",
  island = "Anchor Town",
  need_level = 0,
  accept_level = 0,
  level_gates = {},
  prerequisites = {"Pirate Fan Letter"},
  unlocks_next = "The Hoarder",
  automatic = true,
  exp = 43
}, {
  name = "Introduction",
  kind = "story",
  island = "Anchor Town",
  need_level = 0,
  accept_level = 0,
  level_gates = {},
  prerequisites = {},
  unlocks_next = "Basics",
  automatic = true,
  exp = 10
}, {
  name = "Pirate Fan Letter",
  kind = "story",
  island = "Anchor Town",
  need_level = 0,
  accept_level = 0,
  level_gates = {},
  prerequisites = {"Basics"},
  unlocks_next = "Gearing Up",
  automatic = true,
  exp = 31
}, {
  name = "Setting Sail",
  kind = "story",
  island = "Anchor Town",
  need_level = 0,
  accept_level = 0,
  level_gates = {},
  prerequisites = {"A Voice in a Shell"},
  unlocks_next = nil,
  automatic = true,
  exp = 432
}, {
  name = "Tea Party Crashers",
  kind = "story",
  island = "Anchor Town",
  need_level = 0,
  accept_level = 0,
  level_gates = {},
  prerequisites = {"First Upgrade"},
  unlocks_next = "Captain's Brat",
  automatic = true,
  exp = 20
}, {
  name = "The Hoarder",
  kind = "story",
  island = "Anchor Town",
  need_level = 7,
  accept_level = 0,
  level_gates = {7},
  prerequisites = {"Gearing Up"},
  unlocks_next = "First Upgrade",
  automatic = true,
  exp = 95
}, {
  name = "Bullies in Suits",
  kind = "repeatable",
  island = "Anchor Town",
  accept_level = 0,
  full_until = 12,
  exp = 40,
  prerequisites = {"Pirate Fan Letter"},
  accept_npc = "Koro",
  turnin_npc = "Koro",
  automatic = false
}, {
  name = "Granny's Nemesis",
  kind = "repeatable",
  island = "Anchor Town",
  accept_level = 0,
  full_until = 30,
  exp = 157,
  prerequisites = {"Captain's Brat"},
  accept_npc = "Granny Todo",
  turnin_npc = "Granny Todo",
  automatic = false
}, {
  name = "Officer Termination",
  kind = "repeatable",
  island = "Anchor Town",
  accept_level = 0,
  full_until = 30,
  exp = 105,
  prerequisites = {"Tea Party Crashers"},
  accept_npc = "Maeve",
  turnin_npc = "Maeve",
  automatic = false
}, {
  name = "Tyrannical Captain",
  kind = "repeatable",
  island = "Anchor Town",
  accept_level = 0,
  full_until = 35,
  exp = 771,
  prerequisites = {"Axe-Handed Tyrant"},
  accept_npc = nil,
  turnin_npc = nil,
  automatic = false
}, {
  name = "A Joke Gone Too Far",
  kind = "story",
  island = "Clown Town",
  need_level = 30,
  accept_level = 30,
  level_gates = {},
  prerequisites = {},
  unlocks_next = "Sabotage The Cannon",
  automatic = false,
  exp = 346
}, {
  name = "Butcher's Business",
  kind = "story",
  island = "Clown Town",
  need_level = 45,
  accept_level = 30,
  level_gates = {45},
  prerequisites = {"Stephon's Tormentor"},
  unlocks_next = "Circus Suppliers",
  automatic = true,
  exp = 534
}, {
  name = "Circus Suppliers",
  kind = "story",
  island = "Clown Town",
  need_level = 50,
  accept_level = 30,
  level_gates = {50},
  prerequisites = {"Butcher's Business"},
  unlocks_next = "Clown Captives",
  automatic = true,
  exp = 899
}, {
  name = "Clown Captives",
  kind = "story",
  island = "Clown Town",
  need_level = 30,
  accept_level = 30,
  level_gates = {},
  prerequisites = {"Circus Suppliers"},
  unlocks_next = "Revenge of the Nibblebottom",
  automatic = true,
  exp = 626
}, {
  name = "Clown Town's Militia",
  kind = "story",
  island = "Clown Town",
  need_level = 30,
  accept_level = 30,
  level_gates = {},
  prerequisites = {"Mayor's Stache"},
  unlocks_next = nil,
  automatic = true,
  exp = 611
}, {
  name = "Escort The Mayor",
  kind = "story",
  island = "Clown Town",
  need_level = 58,
  accept_level = 30,
  level_gates = {58},
  prerequisites = {"Revenge of the Nibblebottom"},
  unlocks_next = "Mayor's Stache",
  automatic = true,
  exp = 705
}, {
  name = "Journey to Maple Village",
  kind = "story",
  island = "Clown Town",
  need_level = 30,
  accept_level = 30,
  level_gates = {},
  prerequisites = {"The Ringmaster"},
  unlocks_next = nil,
  automatic = true,
  exp = 2594
}, {
  name = "Lion's Victim",
  kind = "story",
  island = "Clown Town",
  need_level = 40,
  accept_level = 30,
  level_gates = {40},
  prerequisites = {"Sabotage The Cannon"},
  unlocks_next = "Stephon's Tormentor",
  automatic = true,
  exp = 942
}, {
  name = "Mayor's Stache",
  kind = "story",
  island = "Clown Town",
  need_level = 30,
  accept_level = 30,
  level_gates = {},
  prerequisites = {"Escort The Mayor"},
  unlocks_next = "Clown Town's Militia",
  automatic = true,
  exp = 611
}, {
  name = "Revenge of the Nibblebottom",
  kind = "story",
  island = "Clown Town",
  need_level = 30,
  accept_level = 30,
  level_gates = {},
  prerequisites = {"Clown Captives"},
  unlocks_next = "Escort The Mayor",
  automatic = true,
  exp = 665
}, {
  name = "Sabotage The Cannon",
  kind = "story",
  island = "Clown Town",
  need_level = 35,
  accept_level = 30,
  level_gates = {35},
  prerequisites = {"A Joke Gone Too Far"},
  unlocks_next = "Lion's Victim",
  automatic = true,
  exp = 407
}, {
  name = "Stephon's Tormentor",
  kind = "story",
  island = "Clown Town",
  need_level = 43,
  accept_level = 30,
  level_gates = {43},
  prerequisites = {"Lion's Victim"},
  unlocks_next = "Butcher's Business",
  automatic = true,
  exp = 509
}, {
  name = "The Ringmaster",
  kind = "story",
  island = "Clown Town",
  need_level = 60,
  accept_level = 30,
  level_gates = {60},
  prerequisites = {"Clown Town's Militia"},
  unlocks_next = nil,
  automatic = true,
  exp = 2193
}, {
  name = "Billy's Business",
  kind = "repeatable",
  island = "Clown Town",
  accept_level = 30,
  full_until = 60,
  exp = 494,
  prerequisites = {"Butcher's Business"},
  accept_npc = "Billy B.",
  turnin_npc = "Billy B.",
  automatic = false
}, {
  name = "Cat Problem",
  kind = "repeatable",
  island = "Clown Town",
  accept_level = 30,
  full_until = 50,
  exp = 827,
  prerequisites = {"Lion's Victim"},
  accept_npc = "Stephon",
  turnin_npc = "Stephon",
  automatic = false
}, {
  name = "Choppy The Clown",
  kind = "repeatable",
  island = "Clown Town",
  accept_level = 30,
  full_until = 75,
  exp = 1582,
  prerequisites = {"The Ringmaster"},
  accept_npc = "Mayor Kiyoshi [2]",
  turnin_npc = "Mayor Kiyoshi [2]",
  automatic = false
}, {
  name = "Nibblebottom's Revenge",
  kind = "repeatable",
  island = "Clown Town",
  accept_level = 30,
  full_until = 65,
  exp = 494,
  prerequisites = {"Revenge of the Nibblebottom"},
  accept_npc = "Johnny Nibblebottom",
  turnin_npc = "Johnny Nibblebottom",
  automatic = false
}, {
  name = "This Is Personal",
  kind = "repeatable",
  island = "Clown Town",
  accept_level = 30,
  full_until = 45,
  exp = 268,
  prerequisites = {"A Joke Gone Too Far"},
  accept_npc = "Clowny D. Clown",
  turnin_npc = "Clowny D. Clown",
  automatic = false
}, {
  name = "Destroy the Signalers",
  kind = "story",
  island = "Maple Village",
  need_level = 70,
  accept_level = 70,
  level_gates = {},
  prerequisites = {"Stocked for a Siege"},
  unlocks_next = "The Black Noir Raid",
  automatic = true,
  exp = 946
}, {
  name = "Expose the Butler",
  kind = "story",
  island = "Maple Village",
  need_level = 70,
  accept_level = 70,
  level_gates = {},
  prerequisites = {"Missing Servants"},
  unlocks_next = "Raid Preparations",
  automatic = true,
  exp = 932
}, {
  name = "Missing Servants",
  kind = "story",
  island = "Maple Village",
  need_level = 70,
  accept_level = 70,
  level_gates = {},
  prerequisites = {"The Beast of Maple Village"},
  unlocks_next = "Expose the Butler",
  automatic = true,
  exp = 918
}, {
  name = "Pirate Instructions",
  kind = "story",
  island = "Maple Village",
  need_level = 70,
  accept_level = 70,
  level_gates = {},
  prerequisites = {"Something Isn't Right"},
  unlocks_next = "The Wandering Hypnotist",
  automatic = true,
  exp = 891
}, {
  name = "Proof of Pirates",
  kind = "story",
  island = "Maple Village",
  need_level = 70,
  accept_level = 70,
  level_gates = {},
  prerequisites = {"The Island's Protector"},
  unlocks_next = "Something Isn't Right",
  automatic = true,
  exp = 878
}, {
  name = "Raid Preparations",
  kind = "story",
  island = "Maple Village",
  need_level = 70,
  accept_level = 70,
  level_gates = {},
  prerequisites = {"Expose the Butler"},
  unlocks_next = "Stocked for a Siege",
  automatic = true,
  exp = 932
}, {
  name = "Something Isn't Right",
  kind = "story",
  island = "Maple Village",
  need_level = 70,
  accept_level = 70,
  level_gates = {},
  prerequisites = {"Proof of Pirates"},
  unlocks_next = "Pirate Instructions",
  automatic = true,
  exp = 891
}, {
  name = "Stocked for a Siege",
  kind = "story",
  island = "Maple Village",
  need_level = 70,
  accept_level = 70,
  level_gates = {},
  prerequisites = {"Raid Preparations"},
  unlocks_next = "Destroy the Signalers",
  automatic = true,
  exp = 932
}, {
  name = "The Beast of Maple Village",
  kind = "story",
  island = "Maple Village",
  need_level = 70,
  accept_level = 70,
  level_gates = {},
  prerequisites = {"The Wandering Hypnotist"},
  unlocks_next = "Missing Servants",
  automatic = true,
  exp = 905
}, {
  name = "The Black Noir Raid",
  kind = "story",
  island = "Maple Village",
  need_level = 70,
  accept_level = 70,
  level_gates = {},
  prerequisites = {"Destroy the Signalers"},
  unlocks_next = nil,
  automatic = true,
  exp = 959
}, {
  name = "The Island's Protector",
  kind = "story",
  island = "Maple Village",
  need_level = 70,
  accept_level = 70,
  level_gates = {},
  prerequisites = {},
  unlocks_next = "Proof of Pirates",
  automatic = false,
  exp = 865
}, {
  name = "The Wandering Hypnotist",
  kind = "story",
  island = "Maple Village",
  need_level = 70,
  accept_level = 70,
  level_gates = {},
  prerequisites = {"Pirate Instructions"},
  unlocks_next = "The Beast of Maple Village",
  automatic = true,
  exp = 891
}, {
  name = "Clear the Road",
  kind = "repeatable",
  island = "Maple Village",
  accept_level = 70,
  full_until = 78,
  exp = 878,
  prerequisites = {"The Island's Protector"},
  accept_npc = "Nell",
  turnin_npc = "Nell",
  automatic = false
}, {
  name = "Peace of Mind",
  kind = "repeatable",
  island = "Maple Village",
  accept_level = 70,
  full_until = 81,
  exp = 1215,
  prerequisites = {"The Island's Protector"},
  accept_npc = "Gus",
  turnin_npc = "Gus",
  automatic = false
}}

local byName = {}
for _, e in ipairs(ENTRIES) do
	byName[e.name] = e
end

function P.level()
	local d = Cache.Data
	local v = d and (tonumber(d.Level) or tonumber(d.level) or (d.Stats and (tonumber(d.Stats.Level) or tonumber(d.Stats.level))))
	if v and v > 0 then
		return v
	end
	local c = lp.Character
	if c then
		v = tonumber(c:GetAttribute("Level"))
		if v and v > 0 then
			return v
		end
		local ok, n = pcall(Stat.GetValue, c, "Level")
		if ok and type(n) == "number" and n > 0 then
			return n
		end
	end
	return 0
end

function P.completedSet()
	local set = {}
	local d = Cache.Data
	local done = d and (d["Completed Quests"] or d.CompletedQuests)
	if type(done) ~= "table" then
		return set
	end
	if done[1] ~= nil then
		for _, v in ipairs(done) do
			if type(v) == "string" then
				set[v] = true
			elseif type(v) == "table" and v.Name then
				set[v.Name] = true
			end
		end
		return set
	end
	for k, v in pairs(done) do
		if v == true then
			set[k] = true
		elseif type(v) == "string" then
			set[v] = true
			set[k] = true
		elseif type(v) == "table" then
			set[v.Name or k] = true
		end
	end
	return set
end

function P.finished(name)
	local GB = rawget(getgenv(), "GBKaitun")
	if GB and GB.PlayerData then
		return GB.PlayerData.finished(name, true)
	end
	return name and P.completedSet()[name] == true
end

function P.live(name)
	local GB = rawget(getgenv(), "GBKaitun")
	if GB and GB.PlayerData and GB.PlayerData.live then
		return GB.PlayerData.live(name)
	end
	-- Cache only. Never InvokeServer here — boot used to stall ~30s walking ENTRIES.
	local q = Cache.Data and Cache.Data.Quests
	if type(q) ~= "table" then
		return
	end
	if q[name] then
		if P.finished(name) then
			return
		end
		return q[name]
	end
	for k, v in pairs(q) do
		if type(v) == "table" and (v.Name == name or k == name) then
			if P.finished(name) then
				return
			end
			return v
		end
	end
end

function P.needLevel(e)
	if e.need_level then
		return e.need_level
	end
	local n = e.accept_level or 0
	for _, g in ipairs(e.level_gates or {}) do
		n = math.max(n, g)
	end
	return n
end

function P.prereqsMet(e)
	for _, pre in ipairs(e.prerequisites or {}) do
		if not P.finished(pre) then
			return false
		end
	end
	return true
end

function P.inRepeatBand(e, lv)
	if e.kind ~= "repeatable" then
		return false
	end
	if lv < (e.accept_level or 0) then
		return false
	end
	if e.full_until and lv > e.full_until then
		return false
	end
	return true
end

function P.canStory(e, lv)
	if SKIP[e.name] or e.kind ~= "story" then
		return false
	end
	if P.finished(e.name) or P.live(e.name) then
		return false
	end
	if lv < P.needLevel(e) then
		return false
	end
	return P.prereqsMet(e)
end

function P.canRepeat(e, lv)
	if SKIP[e.name] or e.kind ~= "repeatable" then
		return false
	end
	if not P.inRepeatBand(e, lv) then
		return false
	end
	return P.prereqsMet(e)
end

function P.island()
	if not P.finished("Setting Sail") then
		return "Anchor Town"
	end
	if not P.finished("Journey to Maple Village") then
		return "Clown Town"
	end
	return "Maple Village"
end

function P.nextStory(island, lv)
	for _, ch in ipairs(CHAINS) do
		if ch.island == island then
			for _, name in ipairs(ch.order) do
				local e = byName[name]
				if e and P.canStory(e, lv) then
					return e
				end
			end
		end
	end
end

function P.bestRepeat(island, lv)
	local best
	for _, e in ipairs(ENTRIES) do
		if e.kind == "repeatable" and e.island == island and P.canRepeat(e, lv) then
			if not best or (e.exp or 0) > (best.exp or 0) then
				best = e
			end
		end
	end
	return best
end

function P.pick()
	local lv = P.level()
	local island = P.island()
	-- live first
	local liveBest, liveExp
	for _, e in ipairs(ENTRIES) do
		if not SKIP[e.name] and P.live(e.name) then
			if e.kind == "repeatable" and not P.inRepeatBand(e, lv) then
				-- hết band — bỏ, lấy cái khác
			else
				local exp = e.exp or 0
				if not liveBest or exp > liveExp then
					liveBest, liveExp = e, exp
				end
			end
		end
	end
	if liveBest then
		return { kind = liveBest.kind, name = liveBest.name, island = liveBest.island, why = "live", level = lv }
	end
	local story = P.nextStory(island, lv)
	if story then
		return { kind = "story", name = story.name, island = island, why = "story", level = lv }
	end
	local rep = P.bestRepeat(island, lv)
	if rep then
		return { kind = "repeatable", name = rep.name, island = island, why = "repeat", level = lv }
	end
	return { kind = "none", name = nil, island = island, why = "wait level/prereq", level = lv }
end

getgenv().GBPick = P.pick
getgenv()._GBPicker = P
return P
