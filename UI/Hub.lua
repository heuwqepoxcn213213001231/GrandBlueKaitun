return function(GB)
	if type(GB) ~= "table" then
		error("[GrandBlue UI] runtime table missing")
	end

	local UILib = GB.UIAdapter
	local Controller = GB.UIController
	if type(UILib) ~= "table" or type(UILib.CreateWindow) ~= "function" then
		error("[GrandBlue UI] GB.UIAdapter is unavailable")
	end
	if type(Controller) ~= "table" or type(Controller.enqueue) ~= "function" then
		error("[GrandBlue UI] GB.UIController is unavailable")
	end

	local Players = game:GetService("Players")
	local HttpService = game:GetService("HttpService")
	local VirtualUser = game:GetService("VirtualUser")

	local CONFIG_PATH = "GBKaitun/UIConfig.json"
	local CONFIG_SCHEMA = 1
	local STATUS_INTERVAL = 0.33
	local Catalog = type(GB.UICatalog) == "table" and GB.UICatalog or {}
	local PHYSICAL_ISLANDS = type(Catalog.Islands) == "table"
		and Catalog.Islands
		or { "Anchor Town", "Clown Town", "Maple Village" }
	local STAT_NAMES = { "Strength", "Health", "Willpower", "Agility", "Precision", "Energy" }
	local OWNER = Controller.OWNER or {
		IDLE = "IDLE",
		FULL_AUTO = "FULL_AUTO",
		MANUAL_QUEST = "MANUAL_QUEST",
		MANUAL_MOB = "MANUAL_MOB",
		MANUAL_BOSS = "MANUAL_BOSS",
		MANUAL_CHEST = "MANUAL_CHEST",
	}

	local Generated = type(GB.GeneratedData) == "table" and GB.GeneratedData or {}
	local QuestSpecs = type(GB.QuestSpecs) == "table" and GB.QuestSpecs or {}
	local Config = type(GB.Config) == "table" and GB.Config or {}
	local M = {
		Window = nil,
		Controls = {},
		Connections = {},
		Tasks = {},
		_destroyed = false,
		_actionHandles = {},
		_notifyAt = {},
		_configStatus = "Not loaded",
	}
	local UI
	local applyAutoModeFlags
	local triggerAutoCodesOnce
	local updateStoppedStatus

	local function runtimeDead()
		if M._destroyed then
			return true
		end
		if type(GB.dead) == "function" then
			local ok, value = pcall(GB.dead)
			if ok and value == true then
				return true
			end
		end
		return false
	end

	local function schedulerRunning()
		return type(GB.Scheduler) == "table" and GB.Scheduler._running == true
	end

	local function trim(value)
		if type(value) ~= "string" then
			return nil
		end
		local out = string.gsub(value, "^%s+", "")
		out = string.gsub(out, "%s+$", "")
		return out ~= "" and out or nil
	end

	local function clampNumber(value, minimum, maximum, fallback)
		local number = tonumber(value)
		if not number or number ~= number then
			number = fallback
		end
		number = tonumber(number) or minimum
		return math.max(minimum, math.min(maximum, number))
	end

	local function copyArray(source, maximum)
		local out = {}
		local limit = math.max(0, math.floor(tonumber(maximum) or 128))
		if type(source) ~= "table" then
			return out
		end
		for _, value in ipairs(source) do
			if #out >= limit then
				break
			end
			out[#out + 1] = value
		end
		return out
	end

	local function copyMap(source)
		local out = {}
		if type(source) ~= "table" then
			return out
		end
		for key, value in pairs(source) do
			out[key] = value
		end
		return out
	end

	local function join(values, separator, empty)
		if type(values) ~= "table" or #values == 0 then
			return empty or "None"
		end
		local out = {}
		for _, value in ipairs(values) do
			out[#out + 1] = tostring(value)
		end
		return table.concat(out, separator or ", ")
	end

	local function addUnique(list, seen, value)
		value = trim(value)
		if not value then
			return
		end
		local key = string.lower(value)
		if seen[key] then
			return
		end
		seen[key] = true
		list[#list + 1] = value
	end

	local function sortStrings(list)
		table.sort(list, function(a, b)
			local left = string.lower(tostring(a))
			local right = string.lower(tostring(b))
			if left ~= right then
				return left < right
			end
			return tostring(a) < tostring(b)
		end)
		return list
	end

	local function contains(list, wanted)
		for _, value in ipairs(list or {}) do
			if value == wanted then
				return true
			end
		end
		return false
	end

	local function instanceName(instance)
		if typeof(instance) ~= "Instance" then return nil end
		local name
		pcall(function()
			name = instance:GetAttribute("NPCName")
				or instance:GetAttribute("DisplayName")
				or instance:GetAttribute("EnemyName")
				or instance.Name
		end)
		return trim(name)
	end

	local function resultText(value)
		if type(value) ~= "table" then
			return tostring(value)
		end
		local keys = {}
		for key in pairs(value) do
			keys[#keys + 1] = key
		end
		table.sort(keys, function(a, b)
			return tostring(a) < tostring(b)
		end)
		local rows = {}
		for index = 1, math.min(#keys, 24) do
			local key = keys[index]
			local child = value[key]
			if type(child) == "table" then
				local parts = {}
				for nestedKey, nestedValue in pairs(child) do
					if type(nestedValue) ~= "table" then
						parts[#parts + 1] = tostring(nestedKey) .. "=" .. tostring(nestedValue)
					end
				end
				sortStrings(parts)
				rows[#rows + 1] = tostring(key) .. ": " .. join(parts, ", ", "{}")
			else
				rows[#rows + 1] = tostring(key) .. ": " .. tostring(child)
			end
		end
		if #keys > 24 then
			rows[#rows + 1] = string.format("... %d more", #keys - 24)
		end
		return join(rows, "\n", "No data")
	end

	function M.Notify(first, second, third, fourth)
		if M._destroyed then
			return nil
		end
		if first == M then
			first, second, third = second, third, fourth
		end
		local options
		local gap
		if type(first) == "table" then
			options = {
				Title = first.Title or "Grand Blue",
				Text = first.Text or "",
				Type = first.Type or "info",
				Duration = first.Duration or 4,
			}
			gap = tonumber(first.Gap) or 0.9
		else
			options = {
				Title = tostring(first or "Grand Blue"),
				Text = tostring(second or ""),
				Type = tostring(third or "info"),
				Duration = 4,
			}
			gap = 0.9
		end
		local key = table.concat({
			tostring(options.Type),
			tostring(options.Title),
			tostring(options.Text),
		}, "\0")
		local now = os.clock()
		if now - (M._notifyAt[key] or 0) < gap then
			return nil
		end
		M._notifyAt[key] = now
		local ok, toast = pcall(UILib.Notify, UILib, options)
		return ok and toast or nil
	end

	local function guard(label, callback)
		return function(...)
			if runtimeDead() then
				return
			end
			local arguments = table.pack(...)
			local ok, result, detail = pcall(callback, table.unpack(arguments, 1, arguments.n))
			if not ok then
				M.Notify({ Title = label, Text = tostring(result), Type = "error", Gap = 1.5 })
				return
			end
			if result == false and detail and detail ~= "duplicate" then
				M.Notify({ Title = label, Text = tostring(detail), Type = "warning", Gap = 1.2 })
			end
		end
	end

	local function queueAction(label, key, callback, options)
		if runtimeDead() or Config.Enabled ~= true or not schedulerRunning() then
			return false, "runtime stopped"
		end
		options = type(options) == "table" and copyMap(options) or {}
		options.key = key
		local ok, accepted, detail = pcall(
			Controller.enqueue,
			Controller,
			label,
			function(runtime, controller, handle)
				local actionOk, result, reason = pcall(callback, runtime or GB, controller or Controller, handle)
				if not actionOk then
					error(result)
				end
				return result, reason
			end,
			options
		)
		if not ok then
			M.Notify(label, tostring(accepted), "error")
			return false, tostring(accepted)
		end
		if accepted then
			M._actionHandles[key] = detail
			if options.quiet == true then
				M._quietLabels = M._quietLabels or {}
				M._quietLabels[label] = true
			else
				M.Notify({ Title = "Queued", Text = label, Type = "info", Gap = 0.75 })
			end
			return true, detail
		end
		if detail ~= "duplicate" then
			M.Notify(label, tostring(detail or "queue rejected"), "warning")
		end
		return false, detail
	end

	local function controllerCall(method, ...)
		local fn = Controller[method]
		if type(fn) ~= "function" then
			return false, method .. " unavailable"
		end
		local ok, result, detail = pcall(fn, Controller, ...)
		if not ok then
			return false, tostring(result)
		end
		return result ~= false, detail or result
	end

	local function controllerOwner()
		if type(Controller.getOwner) == "function" then
			local ok, value = pcall(Controller.getOwner, Controller)
			if ok and value then
				return value
			end
		end
		return Controller.owner or OWNER.IDLE
	end

	local function controllerSnapshot()
		if type(Controller.getSnapshot) == "function" then
			local ok, value = pcall(Controller.getSnapshot, Controller)
			if ok and type(value) == "table" then
				return value
			end
		end
		return {
			owner = controllerOwner(),
			paused = Controller.paused == true,
			status = Controller.status,
			statusReason = Controller.statusReason,
			progress = Controller.progress,
		}
	end

	local function stopOwner(reason)
		local ok, detail = controllerCall("stop", reason or "ui_stop")
		if not ok then
			M.Notify("Stop", tostring(detail), "error")
		end
		return ok, detail
	end

	local function startOwner(mode, reason)
		Config.Enabled = true
		if GB.Scheduler and type(GB.Scheduler.start) == "function" then
			pcall(GB.Scheduler.start)
		end
		local ok, detail = controllerCall("setOwner", mode, reason or "ui_start")
		if ok and mode == OWNER.FULL_AUTO then
			if applyAutoModeFlags then applyAutoModeFlags(UI and UI.autoMode or "Story First") end
			if UI then
				UI.autoEquip = Config.AutoEquip == true
				UI.autoStats = Config.AutoStats == true
				Config.AutoRewards = UI.autoRewards == true
				Config.CombatMode = UI.safeFastAttack and "SAFE_FAST" or "NORMAL"
			end
			if GB.Engine and type(GB.Engine.markContextDirty) == "function" then
				GB.Engine.markContextDirty("ui_full_auto_profile")
			end
		end
		if ok and triggerAutoCodesOnce and UI and UI.autoCodesOnJoin then triggerAutoCodesOnce() end
		if not ok then
			M.Notify("Start", tostring(detail), "error")
		end
		return ok, detail
	end

	local function normalizeStage(row)
		if type(row) ~= "table" then
			return nil
		end
		return {
			quest = row.Q or row.quest,
			index = tonumber(row.S or row.stage) or 0,
			objective = row.T or row.objective or "",
			goal = row.G or row.goal or "",
			target = row.A or row.target or "",
			amount = tonumber(row.N or row.amount) or 0,
			method = row.M or row.acquire,
			source = row.Src or row.source,
			island = row.Loc or row.location or row.island,
			marker = row.Mk or row.marker,
			handler = row.H or row.handler,
			status = row.St or row.status or "UNKNOWN",
		}
	end

	local allQuests, storyQuests, repeatQuests = {}, {}, {}
	local questSet, storySet, repeatSet, storyMembership = {}, {}, {}, {}
	local skipQuest = {}
	for name, value in pairs(type(Generated.Skip) == "table" and Generated.Skip or {}) do
		if value == true then skipQuest[name] = true end
	end
	for name, value in pairs(type(Config.SkipQuests) == "table" and Config.SkipQuests or {}) do
		if value == true then skipQuest[name] = true end
	end
	for _, name in ipairs(type(Generated.Story) == "table" and Generated.Story.Main or {}) do
		storyMembership[name] = true
	end
	for name, row in pairs(type(Generated.Quests) == "table" and Generated.Quests or {}) do
		local questName = trim(type(row) == "table" and row.Name or name)
		if questName then
			addUnique(allQuests, questSet, questName)
			local onMainStory = storyMembership[questName]
				or (next(storyMembership) == nil and type(row) == "table" and row.Type == "Story")
			if onMainStory and not skipQuest[questName] then
				addUnique(storyQuests, storySet, questName)
			end
			if type(row) == "table" and row.Repeatable == true and not skipQuest[questName] then
				addUnique(repeatQuests, repeatSet, questName)
			end
		end
	end
	sortStrings(allQuests)
	sortStrings(storyQuests)
	sortStrings(repeatQuests)

	local npcNames, npcSet = {}, {}
	for name, row in pairs(type(Generated.NPCs) == "table" and Generated.NPCs or {}) do
		local npcName = type(row) == "table" and row.Name or name
		if npcName ~= "\\" then
			addUnique(npcNames, npcSet, npcName)
		end
	end
	sortStrings(npcNames)

	local baseItemNames, baseItemSet = {}, {}
	for name, row in pairs(type(Generated.Items) == "table" and Generated.Items or {}) do
		addUnique(baseItemNames, baseItemSet, type(row) == "table" and row.Name or name)
	end
	for name in pairs(type(Catalog.Category) == "table" and Catalog.Category or {}) do
		addUnique(baseItemNames, baseItemSet, name)
	end
	sortStrings(baseItemNames)

	local baseSkillNames, baseSkillSet = {}, {}
	for name, row in pairs(type(Generated.Skills) == "table" and Generated.Skills or {}) do
		addUnique(baseSkillNames, baseSkillSet, type(row) == "table" and row.Name or name)
	end
	sortStrings(baseSkillNames)

	local shopNames, shopSet = {}, {}
	for name in pairs(type(Generated.Shops) == "table" and Generated.Shops or {}) do
		addUnique(shopNames, shopSet, name)
	end
	for name in pairs(GB.ItemData and type(GB.ItemData.SHOP) == "table" and GB.ItemData.SHOP or {}) do
		addUnique(shopNames, shopSet, name)
	end
	sortStrings(shopNames)

	local fruitNames, fruitSet = {}, {}
	for name in pairs(GB.ItemData and type(GB.ItemData.FRUITS) == "table" and GB.ItemData.FRUITS or {}) do
		addUnique(fruitNames, fruitSet, name)
	end
	for _, name in ipairs(type(Catalog.Fruits) == "table" and Catalog.Fruits or {}) do
		addUnique(fruitNames, fruitSet, name)
	end
	sortStrings(fruitNames)

	local stagesByQuest, mobNames, mobSet, bossMap, upgradeTargets, itemStageStatus = {}, {}, {}, {}, {}, {}
	local lifeTargets = { Mining = {}, Fishing = {}, Farming = {}, Cooking = {} }
	local lifeSeen = { Mining = {}, Fishing = {}, Farming = {}, Cooking = {} }
	local locationMap, locationNames, locationSeen = {}, {}, {}

	local function addLocation(kind, name, island, target)
		name = trim(name)
		if not name then
			return
		end
		local label = kind .. ": " .. name .. (island and island ~= "" and (" [" .. tostring(island) .. "]") or "")
		local unique = string.lower(label)
		if locationSeen[unique] then
			return
		end
		locationSeen[unique] = true
		locationNames[#locationNames + 1] = label
		locationMap[label] = { kind = kind, name = name, island = island, target = target or name }
	end

	local function bossEntry(name)
		local entry = bossMap[name]
		if entry then
			return entry
		end
		entry = {
			name = name,
			single = 0,
			multi = 0,
			defeat = 0,
			bossDrop = 0,
			known = false,
			quests = {},
			questSeen = {},
			markers = {},
			markerSeen = {},
			islands = {},
			islandSeen = {},
			drops = {},
			dropSeen = {},
		}
		bossMap[name] = entry
		return entry
	end

	local rawStages = type(Generated.Stages) == "table" and Generated.Stages or QuestSpecs.STAGES or {}
	for _, raw in pairs(rawStages) do
		local stage = normalizeStage(raw)
		if stage and trim(stage.quest) then
			stagesByQuest[stage.quest] = stagesByQuest[stage.quest] or {}
			stagesByQuest[stage.quest][#stagesByQuest[stage.quest] + 1] = stage
			local objective, target, source, method = tostring(stage.objective or ""), trim(stage.target), trim(stage.source), trim(stage.method)
			if stage.marker and stage.status ~= "UNRESOLVED" and stage.status ~= "DISABLED" then
				addLocation("Marker", stage.marker, stage.island, stage.marker)
			end
			if target and (objective == "Kill" or objective == "Defeat" or objective == "Hit" or objective == "Shoot") then
				addUnique(mobNames, mobSet, target)
			end
			if source and (method == "EnemyDrop" or method == "BossDrop") then
				addUnique(mobNames, mobSet, source)
			end
			if target and objective == "Upgrade" then
				upgradeTargets[target] = true
			end
			if target and (itemStageStatus[target] == nil or stage.status == "IMPLEMENTED" or stage.status == "RUNTIME_VERIFIED") then
				itemStageStatus[target] = stage.status
			end
			if method and lifeTargets[method] and target then
				addUnique(lifeTargets[method], lifeSeen[method], target)
			end
			if target and (objective == "Kill" or objective == "Defeat") then
				local entry = bossEntry(target)
				if stage.amount == 1 then entry.single = entry.single + 1 elseif stage.amount > 1 then entry.multi = entry.multi + 1 end
				if objective == "Defeat" then entry.defeat = entry.defeat + 1 end
				addUnique(entry.quests, entry.questSeen, stage.quest)
				addUnique(entry.markers, entry.markerSeen, stage.marker)
				addUnique(entry.islands, entry.islandSeen, stage.island)
			end
			if method == "BossDrop" and source then
				local entry = bossEntry(source)
				entry.bossDrop = entry.bossDrop + 1
				addUnique(entry.quests, entry.questSeen, stage.quest)
				addUnique(entry.markers, entry.markerSeen, stage.marker)
				addUnique(entry.islands, entry.islandSeen, stage.island)
				addUnique(entry.drops, entry.dropSeen, target)
			end
		end
	end
	for _, rows in pairs(stagesByQuest) do
		table.sort(rows, function(a, b)
			if a.index ~= b.index then return a.index < b.index end
			if a.objective ~= b.objective then return tostring(a.objective) < tostring(b.objective) end
			return tostring(a.target) < tostring(b.target)
		end)
	end
	sortStrings(mobNames)
	if type(QuestSpecs.STAGES) == "table" then
		local verifiedTargets = { Mining = {}, Fishing = {}, Farming = {}, Cooking = {} }
		local verifiedSeen = { Mining = {}, Fishing = {}, Farming = {}, Cooking = {} }
		for _, raw in pairs(QuestSpecs.STAGES) do
			local stage = normalizeStage(raw)
			if stage and verifiedTargets[stage.method]
				and stage.status ~= "UNRESOLVED"
				and stage.status ~= "DISABLED"
			then
				addUnique(verifiedTargets[stage.method], verifiedSeen[stage.method], stage.target)
			end
		end
		for kind, values in pairs(verifiedTargets) do
			if #values > 0 then lifeTargets[kind] = values end
		end
	end
	for kind, values in pairs(lifeTargets) do
		sortStrings(values)
		if kind == "Mining" and #values == 0 then
			for name, spec in pairs(QuestSpecs.ITEMS or {}) do
				if type(spec) == "table" and spec.method == "Mining" then
					addUnique(values, lifeSeen.Mining, name)
				end
			end
			sortStrings(values)
		end
	end
	for name, row in pairs(type(Generated.NPCs) == "table" and Generated.NPCs or {}) do
		addLocation("NPC", type(row) == "table" and row.Name or name, type(row) == "table" and row.Islands and row.Islands[1] or nil)
	end
	for _, name in ipairs(shopNames) do
		local item = Generated.Items and Generated.Items[name]
		addLocation("Shop", name, type(item) == "table" and item.Location or nil)
	end
	sortStrings(locationNames)

	if GB.Boss and type(GB.Boss.list) == "function" then
		local ok, rows = pcall(GB.Boss.list)
		if ok and type(rows) == "table" then
			for _, row in pairs(rows) do
				if type(row) == "table" then
					local evidence = type(row.Evidence) == "table" and row.Evidence or {}
					local defeat = tonumber(row.Defeat) or ((row.Defeat == true or evidence.Defeat == true) and 1 or 0)
					local bossDrop = tonumber(row.BossDrop) or ((row.BossDrop == true or evidence.BossDrop == true) and 1 or 0)
					local known = row.KnownMapping == true
						or row.KnownBoss == true
						or row.Known == true
						or row.known == true
						or evidence.KnownMapping == true
					local name = trim(row.Target or row.Name or row.name)
					if name and (defeat > 0 or bossDrop > 0 or known) then
						local entry = bossEntry(name)
						entry.defeat = math.max(entry.defeat, defeat)
						entry.bossDrop = math.max(entry.bossDrop, bossDrop)
						entry.single = math.max(entry.single, tonumber(row.Single) or 0)
						entry.multi = math.max(entry.multi, tonumber(row.Multi) or 0)
						entry.known = entry.known or known
						for _, quest in ipairs(type(row.Quests) == "table" and row.Quests or {}) do
							addUnique(entry.quests, entry.questSeen, quest)
						end
						addUnique(entry.quests, entry.questSeen, row.Quest)
						for _, island in ipairs(type(row.Islands) == "table" and row.Islands or {}) do
							addUnique(entry.islands, entry.islandSeen, island)
						end
						addUnique(entry.islands, entry.islandSeen, row.Island)
						for _, marker in ipairs(type(row.Markers) == "table" and row.Markers or {}) do
							addUnique(entry.markers, entry.markerSeen, marker)
						end
						addUnique(entry.markers, entry.markerSeen, row.Marker)
						for _, drop in ipairs(type(row.Drops) == "table" and row.Drops or {}) do
							addUnique(entry.drops, entry.dropSeen, drop)
						end
					end
				end
			end
		end
	end

	local bossNames, bossSet = {}, {}
	for name, entry in pairs(bossMap) do
		if entry.defeat > 0 or entry.bossDrop > 0 or entry.known == true then
			addUnique(bossNames, bossSet, name)
		end
		sortStrings(entry.quests)
		sortStrings(entry.markers)
		sortStrings(entry.islands)
		sortStrings(entry.drops)
	end
	sortStrings(bossNames)
	print(string.format("[GBUI] %d quests", #allQuests))
	print(string.format("[GBUI] %d mobs", #mobNames))
	print(string.format("[GBUI] %d items", #baseItemNames))

	local function verifiedQuestItemSpec(name)
		if not name then return nil end
		if type(QuestSpecs.itemOf) == "function" then
			local ok, value = pcall(QuestSpecs.itemOf, name)
			if ok and type(value) == "table" then return value end
		end
		if type(QuestSpecs.ITEMS) == "table" and type(QuestSpecs.ITEMS[name]) == "table" then return QuestSpecs.ITEMS[name] end
		return nil
	end

	local function itemSpec(name)
		if not name then return nil end
		local verified = verifiedQuestItemSpec(name)
		if verified then return verified end
		if type(Generated.Items) == "table" and type(Generated.Items[name]) == "table" then return Generated.Items[name] end
		return nil
	end

	local function itemActionAllowed(name)
		local spec = verifiedQuestItemSpec(name)
		local method = spec and (spec.method or spec.Method)
		if not method or string.upper(tostring(method)) == "UNKNOWN" then return false, "Acquisition method is UNKNOWN" end
		local directCapabilities = {
			WorldPickup = {},
			Interactable = {},
			OtherVerified = {},
			EnemyDrop = { flag = "AutoLevel" },
			BossDrop = { flag = "AutoBoss" },
			Shop = { flag = "AutoShop" },
			ShopPurchase = { flag = "AutoShop" },
			Mining = { flag = "AutoMining" },
			Crafting = { flag = "AutoMining", item = "Copper Bar" },
		}
		local capability = directCapabilities[method]
		if not capability then
			return false, tostring(method) .. " is not a direct Acquire capability; use its dedicated controls"
		end
		if capability.item and capability.item ~= name then
			return false, "General Crafting is UNRESOLVED; use the verified Life Skills controls"
		end
		if not (GB.Acquire and type(GB.Acquire.AcquireItem) == "function") then return false, "Acquire handler unavailable" end
		return true, method, capability.flag
	end

	local function withRequiredAuto(requiredFlag, callback)
		local previous = requiredFlag and Config[requiredFlag]
		if requiredFlag then Config[requiredFlag] = true end
		local ok, result, detail = pcall(callback)
		if requiredFlag then Config[requiredFlag] = previous end
		if not ok then return false, tostring(result) end
		return result, detail
	end

	local function runItemAcquire(name, amount, context, requiredFlag)
		return withRequiredAuto(requiredFlag, function()
			return GB.Acquire.AcquireItem(name, amount, context)
		end)
	end

	local function questRow(name)
		return name and type(Generated.Quests) == "table" and Generated.Quests[name] or nil
	end

	local function questState(name)
		if not (name and GB.Quest and type(GB.Quest.questState) == "function") then return nil end
		local ok, value = pcall(GB.Quest.questState, name)
		return ok and type(value) == "table" and value or nil
	end

	local function questStatus(name)
		if not (name and GB.Quest and type(GB.Quest.questStatus) == "function") then return "UNKNOWN", nil end
		local ok, status, reason = pcall(GB.Quest.questStatus, name)
		return ok and (status or "UNKNOWN") or "UNKNOWN", ok and reason or tostring(status)
	end

	local function describeBlocker(name)
		if not (name and type(Controller.describeBlocker) == "function") then return nil, nil, nil end
		local ok, kind, reason, data = pcall(Controller.describeBlocker, Controller, name)
		return ok and kind or "UNKNOWN", ok and reason or tostring(kind), ok and data or nil
	end

	local function primaryNpcIsland(name)
		local row = type(Generated.NPCs) == "table" and Generated.NPCs[name] or nil
		if type(row) == "table" and type(row.Islands) == "table" and row.Islands[1] then return row.Islands[1] end
		if type(row) == "table" then
			for _, field in ipairs({ "Accept", "TurnIn", "Talk", "Markers" }) do
				for _, questName in ipairs(type(row[field]) == "table" and row[field] or {}) do
					local quest = questRow(questName)
					if quest and quest.Island then return quest.Island end
				end
			end
		end
		return nil
	end

	local function npcRelatedQuests(name)
		local row = type(Generated.NPCs) == "table" and Generated.NPCs[name] or nil
		local out, seen = {}, {}
		if type(row) == "table" then
			for _, field in ipairs({ "Accept", "TurnIn", "Talk", "Markers" }) do
				for _, questName in ipairs(type(row[field]) == "table" and row[field] or {}) do addUnique(out, seen, questName) end
			end
		end
		return sortStrings(out)
	end

	local function resolveInstance(value)
		if typeof(value) == "Instance" then return value end
		if type(value) == "table" and typeof(value.Instance) == "Instance" then return value.Instance end
		return nil
	end

	local function stateSnapshot()
		if GB.State and type(GB.State.get) == "function" then
			local ok, value = pcall(GB.State.get)
			if ok and type(value) == "table" then return value end
		end
		return {}
	end

	local function teleportNpc(name, island)
		if not name then return false, "Select an NPC" end
		island = island or primaryNpcIsland(name)
		local state = stateSnapshot()
		if island and state.PhysicalIsland ~= island and GB.Travel and type(GB.Travel.goIsland) == "function" then
			local moved = GB.Travel.goIsland(island)
			if moved then return true, "traveling to " .. island end
		end
		if not (GB.Resolver and type(GB.Resolver.resolveNPC) == "function") then return false, "NPC resolver unavailable" end
		local resolved = GB.Resolver.resolveNPC(name, {
			DisplayName = name,
			Island = island,
			ExpectedRole = "npc",
			deep = false,
		})
		if not resolved then return false, "NPC is not currently indexed" end
		if GB.World and type(GB.World.ToNPC) == "function" then return GB.World.ToNPC(resolved, Config.TalkOffset or 5) end
		local instance = resolveInstance(resolved)
		if instance and GB.World and type(GB.World.moveTo) == "function" then return GB.World.moveTo(instance, Config.TalkOffset or 5) end
		return false, "movement handler unavailable"
	end

	local function teleportLocation(label)
		local descriptor = locationMap[label]
		if not descriptor then return false, "Select an indexed location" end
		local state = stateSnapshot()
		if descriptor.island and state.PhysicalIsland ~= descriptor.island and GB.Travel and type(GB.Travel.goIsland) == "function" then
			local moved = GB.Travel.goIsland(descriptor.island)
			if moved then return true, "traveling to " .. descriptor.island end
		end
		if descriptor.kind == "NPC" then return teleportNpc(descriptor.name, descriptor.island) end
		local resolved
		if descriptor.kind == "Shop" and GB.Resolver and type(GB.Resolver.shopItem) == "function" then
			resolved = GB.Resolver.shopItem(descriptor.target)
		elseif GB.Resolver and type(GB.Resolver.resolveMarker) == "function" then
			resolved = GB.Resolver.resolveMarker(descriptor.target, { Island = descriptor.island, ExpectedRole = "marker", deep = false })
		end
		if not resolved and GB.Resolver and type(GB.Resolver.findPlace) == "function" then resolved = GB.Resolver.findPlace(descriptor.target, descriptor.island) end
		local instance = resolveInstance(resolved) or resolved
		if typeof(instance) ~= "Instance" then return false, "Location is not currently indexed" end
		if GB.World and type(GB.World.goPlace) == "function" then return GB.World.goPlace(instance) end
		if GB.World and type(GB.World.moveTo) == "function" then return GB.World.moveTo(instance, 10) end
		return false, "movement handler unavailable"
	end

	local function stageForObjective(name, state)
		local rows, objective = stagesByQuest[name] or {}, state and state.Objective
		for _, stage in ipairs(rows) do
			if not objective or (stage.index == (tonumber(state.StageIndex) or stage.index) and stage.objective == objective.Type and (stage.target == objective.TargetName or objective.TargetName == nil)) then
				return stage
			end
		end
		return rows[1]
	end

	local function teleportQuestEndpoint(name, turnIn)
		local row, state = questRow(name) or {}, questState(name)
		if turnIn then return teleportNpc(row.TurnInNPC or (state and state.NPC), row.Island or (state and state.Island)) end
		local objective = state and state.Objective
		if objective and (objective.Type == "Talk" or objective.Type == "Automatic Talk") then return teleportNpc(objective.TargetName, state.Island or row.Island) end
		local stage = stageForObjective(name, state)
		local island = (stage and stage.island) or row.Island or (state and state.Island)
		local snapshot = stateSnapshot()
		if island and snapshot.PhysicalIsland ~= island and GB.Travel and type(GB.Travel.goIsland) == "function" then
			local moved = GB.Travel.goIsland(island)
			if moved then return true, "traveling to " .. island end
		end
		local target = objective and objective.TargetName
		if target and GB.Resolver and type(GB.Resolver.enemy) == "function" then
			local enemy = GB.Resolver.enemy(target)
			if enemy and GB.World and type(GB.World.ToEnemy) == "function" then return GB.World.ToEnemy(enemy, Config.CombatRange or 5.5) end
		end
		if stage and stage.marker and GB.Resolver and type(GB.Resolver.resolveMarker) == "function" then
			local resolved = GB.Resolver.resolveMarker(stage.marker, { Island = island, ExpectedRole = "marker", deep = false })
			local instance = resolveInstance(resolved)
			if instance and GB.World and type(GB.World.goPlace) == "function" then return GB.World.goPlace(instance) end
		end
		local npc = row.AcceptNPC or (state and state.NPC)
		if npc then return teleportNpc(npc, island) end
		return false, "No verified objective endpoint is indexed"
	end

	local function inventoryRows()
		if GB.Inventory and type(GB.Inventory.list) == "function" then
			local ok, rows = pcall(GB.Inventory.list)
			if ok and type(rows) == "table" then return rows end
		end
		return {}
	end

	local function inventoryCount(name)
		if GB.PlayerData and type(GB.PlayerData.hasItem) == "function" then
			local ok, owned, amount = pcall(GB.PlayerData.hasItem, name)
			if ok then return owned == true, tonumber(amount) or 0 end
		end
		return false, 0
	end

	local function activeQuestNames(usePublic)
		if usePublic and GB.PlayerData and type(GB.PlayerData.activeNames) == "function" then
			local ok, values = pcall(GB.PlayerData.activeNames)
			if ok and type(values) == "table" then return values end
		end
		local out, seen = {}, {}
		local order, live = GB.PlayerData and GB.PlayerData._order, GB.PlayerData and GB.PlayerData._live
		for _, name in ipairs(type(order) == "table" and order or {}) do
			if type(live) == "table" and live[name] then addUnique(out, seen, name) end
		end
		addUnique(out, seen, stateSnapshot().CurrentQuest)
		return out
	end

	local function completedQuestNames()
		local out = {}
		if not (GB.PlayerData and type(GB.PlayerData.finished) == "function") then
			return out
		end
		for _, name in ipairs(allQuests) do
			local ok, finished = pcall(GB.PlayerData.finished, name, true)
			if ok and finished == true then
				out[#out + 1] = name
			end
		end
		return out
	end

	local function enemyAlive(instance)
		if GB.Combat and type(GB.Combat.IsEnemyAlive) == "function" then
			local ok, value = pcall(GB.Combat.IsEnemyAlive, instance)
			return ok and value == true
		end
		return instance ~= nil and instance.Parent ~= nil
	end

	local function enemyDistance(instance, snapshot)
		if not (instance and GB.Resolver and type(GB.Resolver.positionOf) == "function") then return nil end
		local ok, position = pcall(GB.Resolver.positionOf, instance)
		if not ok or position == nil or snapshot.Position == nil then return nil end
		if GB.World and type(GB.World.planarDist) == "function" then
			local distOk, distance = pcall(GB.World.planarDist, snapshot.Position, position)
			if distOk then return tonumber(distance) end
		end
		local distOk, distance = pcall(function() return (snapshot.Position - position).Magnitude end)
		return distOk and distance or nil
	end

	local function enemiesFor(name)
		if not (name and GB.Resolver and type(GB.Resolver.enemies) == "function") then return {} end
		local ok, values = pcall(GB.Resolver.enemies, name)
		return ok and type(values) == "table" and values or {}
	end

	UI = {
		storyQuest = storyQuests[1], allQuest = allQuests[1], detailQuest = storyQuests[1] or allQuests[1],
		repeatQuest = repeatQuests[1], repeatables = {}, repeatMode = "ONE", targetLevel = nil,
		resumeFullAuto = false, storyContinuous = false, repeatContinuous = false, activeQuest = nil,
		completedQuest = nil,
		mobs = {}, mobMode = "NEAREST", mobContinuous = false,
		bosses = {}, bossFocus = bossNames[1], bossAuto = false, bossWait = false,
		island = PHYSICAL_ISLANDS[1], npc = npcNames[1], location = locationNames[1],
		item = baseItemNames[1], equipment = nil, preferredEquipment = nil, autoPreferredEquipment = false,
		skill = baseSkillNames[1], linkedQuest = nil, statPreset = "Custom", statSelected = STAT_NAMES[1], statWeights = {},
		mining = {}, autoMining = false, fishing = lifeTargets.Fishing[1], farming = lifeTargets.Farming[1], cooking = lifeTargets.Cooking[1],
		fruit = fruitNames[1], fruitConfirm = false, fruitAutoPickup = Config.AutoFruit == true,
		rerollConfirm = false, traitSlot = 1,
		shop = shopNames[1], quickShop = shopNames[1], shopQuantity = 1,
		chestMap = "CURRENT", autoChest = false,
		code = type(Config.Codes) == "table" and Config.Codes[1] or nil, manualCode = "", autoCodesOnJoin = Config.AutoCodes == true,
		autoRewards = Config.AutoRewards == true, autoMode = "Story First", resumeActions = false,
		autoRespawn = Config.AutoRespawn ~= false, safeFastAttack = Config.CombatMode == "SAFE_FAST",
		autoEquip = Config.AutoEquip == true, autoStats = Config.AutoStats == true, antiAFK = false,
		combatRange = clampNumber(Config.CombatRange, 2, 30, 5.5),
		tweenSpeed = clampNumber(Config.TweenSpeed, 20, 300, 95),
		stickiness = clampNumber(Config.TargetStickiness, 0, 30, 2),
		switchDistance = clampNumber(Config.TargetSwitchDistance, 10, 300, 55),
	}
	local initialStatTotal = 0
	for _, stat in ipairs(STAT_NAMES) do
		UI.statWeights[stat] = clampNumber(Config.StatRatio and Config.StatRatio[stat], 0, 100, 0)
		initialStatTotal = initialStatTotal + UI.statWeights[stat]
	end
	if initialStatTotal <= 0 then
		for _, stat in ipairs(STAT_NAMES) do UI.statWeights[stat] = 0 end
		UI.statWeights.Strength, UI.statWeights.Health = 8, 2
		Config.StatRatio = copyMap(UI.statWeights)
		M._initialStatRatioSanitized = true
	end
	Config.AutoCodes = false

	applyAutoModeFlags = function(mode)
		local keys = {
			"StoryFirst", "AutoQuest", "AutoLevel", "AutoCombat", "AutoStats", "AutoSkills",
			"AutoEquip", "AutoShop", "AutoTravel", "AutoBoat", "AutoInventory", "AutoBackpack",
			"AutoFruit", "AutoHaki", "AutoRaceTrait", "AutoBoss", "AutoChest", "AutoTreasure",
			"AutoMining", "AutoFishing", "AutoFarming", "AutoCooking", "AutoCodes",
			"AutoRewards", "AutoTutorial",
		}
		local modes = {
			["Story First"] = {
				StoryFirst = true, AutoQuest = true, AutoLevel = true, AutoCombat = true,
				AutoShop = true, AutoMining = true, AutoEquip = true, AutoStats = true, AutoSkills = true,
				AutoBoss = true, AutoChest = true, AutoTreasure = true,
				AutoTravel = true, AutoBoat = true, AutoInventory = true, AutoTutorial = true,
				AutoFishing = true, AutoFarming = true, AutoCooking = true, AutoFruit = true,
			},
			Balanced = {
				StoryFirst = false, AutoQuest = true, AutoLevel = true, AutoCombat = true,
				AutoShop = true, AutoMining = true, AutoEquip = true, AutoStats = true, AutoSkills = true,
				AutoBoss = true, AutoChest = true, AutoTreasure = true,
				AutoTravel = true, AutoBoat = true, AutoInventory = true, AutoTutorial = true,
				AutoFishing = true, AutoFarming = true, AutoCooking = true, AutoFruit = true,
			},
			["Level Rush"] = {
				StoryFirst = true, AutoQuest = true, AutoLevel = true, AutoCombat = true,
				AutoShop = true, AutoMining = true, AutoEquip = true, AutoStats = true, AutoSkills = true,
				AutoTravel = true, AutoBoat = true, AutoInventory = true, AutoTutorial = true,
			},
			["Manual Requirements"] = {
				StoryFirst = true, AutoQuest = true, AutoCombat = true,
				AutoEquip = true, AutoStats = true, AutoSkills = true,
				AutoTravel = true, AutoBoat = true, AutoInventory = true, AutoTutorial = true,
			},
		}
		local selected = modes[mode] or modes["Story First"]
		for _, key in ipairs(keys) do Config[key] = selected[key] == true end
		Config.AutoRewards = UI and UI.autoRewards == true or false
		Config.AutoCodes = false
	end

	local function register(group, key, control)
		M.Controls[group] = M.Controls[group] or {}
		M.Controls[group][key] = control
		M.Controls[group .. key] = control
		if M.Controls[key] == nil then M.Controls[key] = control end
		return control
	end

	local function setControl(group, key, value)
		local control = M.Controls[group] and M.Controls[group][key]
		if control and type(control.Set) == "function" then pcall(control.Set, control, value, true) end
	end

	local function setOptions(group, key, options, selected)
		local control = M.Controls[group] and M.Controls[group][key]
		if not control then return end
		if type(control.SetOptions) == "function" then pcall(control.SetOptions, control, options, true) end
		if selected ~= nil and type(control.Set) == "function" then pcall(control.Set, control, selected, true) end
	end

	local function trackConnection(connection)
		if not connection then return nil end
		if not contains(M.Connections, connection) then M.Connections[#M.Connections + 1] = connection end
		GB.conns = type(GB.conns) == "table" and GB.conns or {}
		GB.Connections = GB.conns
		if not contains(GB.conns, connection) then GB.conns[#GB.conns + 1] = connection end
		return connection
	end

	local function untrackConnection(connection)
		for index = #M.Connections, 1, -1 do
			if M.Connections[index] == connection then table.remove(M.Connections, index) end
		end
		local connections = type(GB.conns) == "table" and GB.conns or {}
		for index = #connections, 1, -1 do
			if connections[index] == connection then table.remove(connections, index) end
		end
	end

	local function releaseAntiAFKButton()
		if not M._antiAFKButtonHeld then return end
		M._antiAFKButtonHeld = false
		local camera = workspace.CurrentCamera
		pcall(function()
			VirtualUser:Button2Up(Vector2.new(0, 0), camera and camera.CFrame or CFrame.new())
		end)
	end

	local function disconnectAntiAFK()
		releaseAntiAFKButton()
		local connection = M._antiAFKConnection
		if connection then
			pcall(function() connection:Disconnect() end)
			untrackConnection(connection)
			M._antiAFKConnection = nil
		end
	end

	local function quiesce(reason)
		if M._quiescing then return true end
		M._quiescing = true
		Config.Enabled = false
		if UI then
			UI.storyContinuous, UI.repeatContinuous, UI.resumeFullAuto = false, false, false
			UI.mobContinuous, UI.bossAuto, UI.bossWait, UI.autoChest = false, false, false, false
			UI.autoMining, UI.autoPreferredEquipment, UI.fruitAutoPickup = false, false, false
			UI.autoCodesOnJoin, UI.autoRewards = false, false
			UI.autoEquip, UI.autoStats, UI.autoRespawn, UI.antiAFK = false, false, false, false
		end
		Config.AutoMining, Config.AutoFishing, Config.AutoFarming, Config.AutoCooking = false, false, false, false
		Config.AutoFruit, Config.AutoCodes, Config.AutoRewards = false, false, false
		Config.AutoEquip, Config.AutoStats, Config.AutoRespawn = false, false, false
		M._codesQueueProgress = nil
		controllerCall("setUtilityAuto", "AutoEquip", false)
		controllerCall("setUtilityAuto", "AutoStats", false)
		controllerCall("setUtilityAuto", "AutoCodes", false)
		controllerCall("setResumeFullAuto", false)
		controllerCall("setWaitBoss", false)
		controllerCall("setBossKillLimit", nil)
		controllerCall("setChestAutoLoop", false)
		if GB.Codes and type(GB.Codes.stop) == "function" then pcall(GB.Codes.stop) end
		disconnectAntiAFK()
		for _, handle in pairs(M._actionHandles) do
			if handle and type(handle.Cancel) == "function" then pcall(handle.Cancel, handle, reason or "ui_quiesce") end
		end
		M._actionHandles = {}
		pcall(Controller.stop, Controller, reason or "ui_quiesce")
		if GB.World and type(GB.World.cancelTween) == "function" then pcall(GB.World.cancelTween) end
		if GB.Combat and type(GB.Combat.stopLock) == "function" then pcall(GB.Combat.stopLock) end
		if GB.Scheduler and type(GB.Scheduler.stop) == "function" then pcall(GB.Scheduler.stop) end
		setControl("Quests", "AutoComplete", false)
		setControl("Quests", "RepeatContinuous", false)
		setControl("Quests", "ResumeFullAuto", false)
		setControl("Mobs", "Continuous", false)
		setControl("Bosses", "AutoFarm", false)
		setControl("Bosses", "WaitSpawn", false)
		setControl("Chest", "Auto", false)
		setControl("LifeSkills", "AutoMining", false)
		setControl("Equipment", "AutoPreferred", false)
		setControl("Fruit", "AutoPickup", false)
		setControl("Codes", "AutoJoin", false)
		setControl("Codes", "AutoRewards", false)
		setControl("Home", "AutoRespawn", false)
		setControl("Home", "AutoEquip", false)
		setControl("Home", "AutoStats", false)
		setControl("Stats", "AutoStats", false)
		setControl("Home", "AntiAFK", false)
		setControl("Auto", "Master", false)
		setControl("Home", "FullAuto", false)
		M._quiescing = false
		return true
	end

	local function addTab(name, icon)
		return M.Window:AddTab({ Name = name, Icon = icon })
	end

	local updateHome, updateQuestDetails, updateActiveQuestDetails, updateMobStatus, updateBossDetails
	local updateNpcDetails, updateItemDetails, updateEquipmentDetails, updateSkillDetails, updateStatsStatus
	local updateLifeStatus, updateFruitStatus, updateHakiStatus, updateShopStatus, updateChestStatus
	local updateCodeStatus, updateAutoStatus, updateDebugStatus, refreshDynamicOptions, syncControls

	pcall(Controller.stop, Controller, "ui_boot_idle")
	M.Window = UILib:CreateWindow({
		Title = "Grand Blue Kaitun",
		Subtitle = "IDLE | v" .. tostring(GB.Version or Generated.Version or "unknown"),
		Size = Vector2.new(860, 610),
		MinSize = Vector2.new(620, 420),
		ToggleKeybind = Enum.KeyCode.RightShift,
		Draggable = true,
		Resizable = true,
	})

	local homeTab = addTab("Home", "home")
	local autoTab = addTab("Auto Progress", "star")
	local questsTab = addTab("Quests", "quest")
	local mobsTab = addTab("Mobs", "target")
	local bossesTab = addTab("Bosses", "sword")
	local teleportTab = addTab("Teleport", "teleport")
	local chestTab = addTab("Chest / Treasure", "box")
	local itemsTab = addTab("Items", "package")
	local equipmentTab = addTab("Equipment", "box")
	local statsTab = addTab("Stats", "star")
	local skillsTab = addTab("Skills", "zap")
	local lifeTab = addTab("Life Skills", "pickaxe")
	local fruitTab = addTab("Fruit", "apple")
	local shopTab = addTab("Shop", "store")
	local codesTab = addTab("Codes / Rewards", "code")
	local hakiTab = addTab("Misc", "user")
	local settingsTab = addTab("Settings", "settings")
	local debugTab = addTab("Debug", "debug")
	homeTab:AddSection("Runtime")
	register("Home", "Status", homeTab:AddParagraph({
		Title = "Live Status",
		Text = "Initializing cached runtime status...",
	}))
	register("Home", "FullAuto", homeTab:AddToggle({
		Text = "Full Auto",
		Description = "Assign or release exclusive FULL_AUTO. Same DecisionEngine as Auto Progress.",
		Default = false,
		Callback = guard("Full Auto", function(value)
			local ok
			if value == true then
				ok = startOwner(OWNER.FULL_AUTO, "ui_home_full_auto")
			elseif controllerOwner() == OWNER.FULL_AUTO then
				ok = stopOwner("ui_home_full_auto_off")
			else
				ok = true
			end
			setControl("Auto", "Master", value == true)
			return ok
		end),
	}))
	register("Home", "Resume", homeTab:AddButton({
		Text = "Resume",
		Description = "Resume a paused owner. Does not invent a new farm mode.",
		Callback = guard("Resume", function()
			Config.Enabled = true
			if GB.Scheduler and type(GB.Scheduler.start) == "function" then pcall(GB.Scheduler.start) end
			local snap = controllerSnapshot()
			if snap.paused and snap.owner ~= OWNER.IDLE then return controllerCall("resume", "ui_home_resume") end
			return false, "Nothing paused"
		end),
	}))
	register("Home", "Pause", homeTab:AddButton({
		Text = "Pause",
		Description = "Pause the active owner and cancel movement/combat.",
		Callback = guard("Pause", function() return controllerCall("pause", "ui_home_pause") end),
	}))
	register("Home", "StopCurrent", homeTab:AddButton({
		Text = "Stop Current",
		Description = "Return the controller to IDLE and clear its current work.",
		Callback = guard("Stop Current", function()
			UI.autoMining = false
			Config.AutoMining = false
			setControl("LifeSkills", "AutoMining", false)
			return stopOwner("ui_home_stop_current")
		end),
	}))
	register("Home", "StopAll", homeTab:AddButton({
		Text = "Stop All",
		Description = "Stop controller work and suspend runtime jobs; keep this UI open.",
		Callback = guard("Stop All", function()
			quiesce("ui_home_stop_all")
			updateStoppedStatus()
			M.Notify("Runtime stopped", "Use Full Auto or Resume to restart.", "warning")
			return true
		end),
	}))
	register("Home", "Refresh", homeTab:AddButton({
		Text = "Refresh",
		Description = "Refresh asynchronous caches and every dropdown without rebuilding.",
		Callback = guard("Refresh", function()
			return M.Refresh()
		end),
	}))
	register("Home", "SelfCheck", homeTab:AddButton({
		Text = "Self Check",
		Description = "Run the current runtime diagnostic self-check.",
		Callback = guard("Self Check", function()
			if type(GB.SelfCheck) ~= "function" then return false, "SelfCheck unavailable" end
			return queueAction("Runtime self check", "ui:self_check", function()
				local result = GB.SelfCheck()
				setControl("Home", "SelfCheckResult", resultText(result))
				M.Notify("Self Check", "Diagnostic snapshot updated.", "success")
				return true
			end, { cancelActive = false })
		end),
	}))
	register("Home", "SelfCheckResult", homeTab:AddParagraph({
		Title = "Self Check Result",
		Text = "Not run in this session.",
	}))
	homeTab:AddSection("Safe Automation")
	register("Home", "AutoRespawn", homeTab:AddToggle({
		Text = "Auto Respawn",
		Description = "Set the runtime respawn policy flag.",
		Default = UI.autoRespawn,
		Callback = guard("Auto Respawn", function(value)
			UI.autoRespawn = value == true
			Config.AutoRespawn = UI.autoRespawn
			return true
		end),
	}))
	register("Home", "SafeFastAttack", homeTab:AddToggle({
		Text = "Safe Fast Attack",
		Description = "Use SAFE_FAST; off restores NORMAL combat mode.",
		Default = UI.safeFastAttack,
		Callback = guard("Safe Fast Attack", function(value)
			UI.safeFastAttack = value == true
			Config.CombatMode = UI.safeFastAttack and "SAFE_FAST" or "NORMAL"
			return true
		end),
	}))
	register("Home", "AutoEquip", homeTab:AddToggle({
		Text = "Auto Equip",
		Description = "Allow the existing Equipment handler.",
		Default = UI.autoEquip,
		Callback = guard("Auto Equip", function(value)
			UI.autoEquip = value == true
			Config.AutoEquip = UI.autoEquip
			controllerCall("setUtilityAuto", "AutoEquip", UI.autoEquip)
			return true
		end),
	}))
	register("Home", "AutoStats", homeTab:AddToggle({
		Text = "Auto Stats",
		Description = "Allow validated one-step investment through Stats.",
		Default = UI.autoStats,
		Callback = guard("Auto Stats", function(value)
			UI.autoStats = value == true
			Config.AutoStats = UI.autoStats
			controllerCall("setUtilityAuto", "AutoStats", UI.autoStats)
			if UI.autoStats and GB.Stats and type(GB.Stats.markDirty) == "function" then GB.Stats.markDirty("ui_toggle") end
			return true
		end),
	}))
	register("Home", "AntiAFK", homeTab:AddToggle({
		Text = "Anti AFK",
		Description = "Send a local idle acknowledgement only while enabled.",
		Default = false,
		Callback = guard("Anti AFK", function(value)
			UI.antiAFK = value == true
			if UI.antiAFK and not M._antiAFKConnection then
				local player = GB.lp or Players.LocalPlayer
				if not player then
					UI.antiAFK = false
					setControl("Home", "AntiAFK", false)
					return false, "LocalPlayer unavailable"
				end
				M._antiAFKConnection = player.Idled:Connect(function()
					if not UI.antiAFK or runtimeDead() then return end
					releaseAntiAFKButton()
					local down = pcall(function()
						VirtualUser:CaptureController()
						local camera = workspace.CurrentCamera
						VirtualUser:Button2Down(Vector2.new(0, 0), camera and camera.CFrame or CFrame.new())
					end)
					if down then
						M._antiAFKButtonHeld = true
						task.delay(0.05, releaseAntiAFKButton)
					end
				end)
				trackConnection(M._antiAFKConnection)
			elseif not UI.antiAFK and M._antiAFKConnection then
				disconnectAntiAFK()
			end
			return true
		end),
	}))

	questsTab:AddSection("Story and All Quests")
	register("Quests", "Story", questsTab:AddDropdown({
		Text = "Story Quest",
		Description = string.format("%d generated story quests; type to search.", #storyQuests),
		Options = storyQuests,
		Default = UI.storyQuest,
		Callback = guard("Story Quest", function(value)
			UI.storyQuest, UI.detailQuest = value, value
			controllerCall("setSelectedQuest", value)
			updateQuestDetails()
			return true
		end),
	}))
	register("Quests", "All", questsTab:AddDropdown({
		Text = "All Quest Lookup",
		Description = string.format("%d generated story, side, and progression quests.", #allQuests),
		Options = allQuests,
		Default = UI.allQuest,
		Callback = guard("All Quest Lookup", function(value)
			UI.allQuest, UI.detailQuest = value, value
			updateQuestDetails()
			return true
		end),
	}))
	register("Quests", "Details", questsTab:AddParagraph({ Title = "Selected Quest Details", Text = "Select a quest." }))
	register("Quests", "Blocker", questsTab:AddParagraph({ Title = "Availability / Blocker", Text = "No blocker evaluated." }))
	register("Quests", "TeleportNPC", questsTab:AddButton({
		Text = "Teleport to Quest NPC",
		Description = "Use centralized Travel, Resolver, and World controllers.",
		Callback = guard("Quest NPC", function()
			local name = UI.detailQuest
			return queueAction("Quest NPC: " .. tostring(name), "quest:npc:" .. tostring(name), function()
				local row, state = questRow(name) or {}, questState(name)
				local npc = state and state.IsAccepted and (row.TurnInNPC or state.NPC) or row.AcceptNPC
				return teleportNpc(npc, row.Island or (state and state.Island))
			end)
		end),
	}))
	register("Quests", "Accept", questsTab:AddButton({
		Text = "Accept Selected",
		Description = "Use Quest state handling; unresolved starts are blocked.",
		Callback = guard("Accept Quest", function()
			local name, row = UI.detailQuest, questRow(UI.detailQuest)
			if not name or not row then return false, "Select a generated quest" end
			if row.Start == "UNRESOLVED_START" then return false, "Quest start is UNRESOLVED" end
			if not (GB.Quest and type(GB.Quest.doLiveResult) == "function") then return false, "Quest handler unavailable" end
			return queueAction("Accept " .. name, "quest:accept:" .. name, function() return GB.Quest.doLiveResult(name) end)
		end),
	}))
	register("Quests", "RunOnce", questsTab:AddButton({
		Text = "Run Selected Once",
		Description = "Run one current Quest handler step.",
		Callback = guard("Run Quest Once", function()
			local name = UI.detailQuest
			if not (name and GB.Quest and type(GB.Quest.doLiveResult) == "function") then return false, "Quest handler unavailable" end
			return queueAction("Quest step: " .. name, "quest:once:" .. name, function() return GB.Quest.doLiveResult(name) end)
		end),
	}))
	register("Quests", "AutoComplete", questsTab:AddToggle({
		Text = "Auto Complete Selected",
		Description = "Assign MANUAL_QUEST until completion or stop.",
		Default = false,
		Callback = guard("Auto Complete Quest", function(value)
			UI.storyContinuous = value == true
			if UI.storyContinuous then
				local name = UI.detailQuest
				if not name then
					UI.storyContinuous = false
					setControl("Quests", "AutoComplete", false)
					return false, "Select a quest"
				end
				UI.repeatContinuous = false
				setControl("Quests", "RepeatContinuous", false)
				controllerCall("setSelectedQuest", name)
				return startOwner(OWNER.MANUAL_QUEST, "ui_story_continuous")
			end
			if controllerOwner() == OWNER.MANUAL_QUEST and not UI.repeatContinuous then return stopOwner("ui_story_stop") end
			return true
		end),
	}))
	register("Quests", "Stop", questsTab:AddButton({
		Text = "Stop Quest Automation",
		Callback = guard("Stop Quest", function()
			UI.storyContinuous, UI.repeatContinuous = false, false
			setControl("Quests", "AutoComplete", false)
			setControl("Quests", "RepeatContinuous", false)
			if controllerOwner() == OWNER.MANUAL_QUEST then return stopOwner("ui_quest_stop") end
			return true
		end),
	}))
	questsTab:AddSection("Repeatable Quests")
	register("Quests", "RepeatSingle", questsTab:AddDropdown({
		Text = "Repeatable Quest",
		Description = string.format("%d generated repeatable quests.", #repeatQuests),
		Options = repeatQuests,
		Default = UI.repeatQuest,
		Callback = guard("Repeatable Quest", function(value)
			UI.repeatQuest, UI.detailQuest = value, value
			controllerCall("setSelectedQuest", value)
			updateQuestDetails()
			return true
		end),
	}))
	register("Quests", "RepeatMulti", questsTab:AddDropdown({
		Text = "Repeatable Multi-Select",
		Description = "Choose a searchable rotation pool.",
		Options = repeatQuests,
		MultiSelect = true,
		Default = {},
		Callback = guard("Repeatable Selection", function(values)
			UI.repeatables = copyArray(values, 64)
			return controllerCall("setSelectedRepeatables", UI.repeatables)
		end),
	}))
	register("Quests", "RepeatMode", questsTab:AddDropdown({
		Text = "Repeat Mode",
		Options = { "ONE", "ROTATE", "BEST", "NEAREST" },
		Default = UI.repeatMode,
		Callback = guard("Repeat Mode", function(value)
			UI.repeatMode = value
			return controllerCall("setRepeatMode", value)
		end),
	}))
	register("Quests", "TargetLevel", questsTab:AddTextbox({
		Text = "Target Level",
		Description = "Blank disables; valid range 1-100000.",
		Placeholder = "Blank",
		Default = "",
		Callback = guard("Target Level", function(text)
			local clean = trim(text)
			if not clean then
				UI.targetLevel = nil
				return controllerCall("setFarmUntilLevel", nil)
			end
			local level = tonumber(clean)
			if not level or level < 1 or level > 100000 then
				setControl("Quests", "TargetLevel", UI.targetLevel and tostring(UI.targetLevel) or "")
				return false, "Enter a level from 1 to 100000"
			end
			UI.targetLevel = math.floor(level)
			setControl("Quests", "TargetLevel", tostring(UI.targetLevel))
			return controllerCall("setFarmUntilLevel", UI.targetLevel)
		end),
	}))
	register("Quests", "ResumeFullAuto", questsTab:AddToggle({
		Text = "Resume Auto Progress at Target",
		Default = false,
		Callback = guard("Resume Auto", function(value)
			UI.resumeFullAuto = value == true
			return controllerCall("setResumeFullAuto", UI.resumeFullAuto)
		end),
	}))
	register("Quests", "RepeatContinuous", questsTab:AddToggle({
		Text = "Continuous Repeat",
		Description = "Assign MANUAL_QUEST with the selected pool and mode.",
		Default = false,
		Callback = guard("Continuous Repeat", function(value)
			UI.repeatContinuous = value == true
			if UI.repeatContinuous then
				local values = copyArray(UI.repeatables, 64)
				if #values == 0 and UI.repeatQuest then values[1] = UI.repeatQuest end
				if #values == 0 then
					UI.repeatContinuous = false
					setControl("Quests", "RepeatContinuous", false)
					return false, "Select at least one repeatable quest"
				end
				UI.storyContinuous = false
				setControl("Quests", "AutoComplete", false)
				controllerCall("setSelectedQuest", values[1])
				controllerCall("setSelectedRepeatables", values)
				controllerCall("setRepeatMode", UI.repeatMode)
				controllerCall("setFarmUntilLevel", UI.targetLevel)
				controllerCall("setResumeFullAuto", UI.resumeFullAuto)
				return startOwner(OWNER.MANUAL_QUEST, "ui_repeat_continuous")
			end
			if controllerOwner() == OWNER.MANUAL_QUEST and not UI.storyContinuous then return stopOwner("ui_repeat_stop") end
			return true
		end),
	}))
	questsTab:AddSection("Active Quests")
	register("Quests", "Active", questsTab:AddDropdown({
		Text = "Active Quest",
		Description = "Refreshed from all PlayerData.activeNames entries.",
		Options = {},
		Callback = guard("Active Quest", function(value)
			UI.activeQuest = value
			updateActiveQuestDetails()
			return true
		end),
	}))
	register("Quests", "ActiveDetails", questsTab:AddParagraph({ Title = "Active Quest Conditions", Text = "No active quest selected." }))
	register("Quests", "RunActive", questsTab:AddButton({
		Text = "Run Active Quest",
		Callback = guard("Run Active Quest", function()
			if not UI.activeQuest then return false, "Select an active quest" end
			controllerCall("setSelectedQuest", UI.activeQuest)
			return startOwner(OWNER.MANUAL_QUEST, "ui_active_quest")
		end),
	}))
	register("Quests", "TurnInActive", questsTab:AddButton({
		Text = "Run / Turn In Active",
		Description = "Run one Quest step; its state machine decides turn-in.",
		Callback = guard("Turn In Quest", function()
			local name = UI.activeQuest
			if not (name and GB.Quest and type(GB.Quest.doLiveResult) == "function") then return false, "Active quest handler unavailable" end
			return queueAction("Turn in: " .. name, "quest:turnin:" .. name, function() return GB.Quest.doLiveResult(name) end)
		end),
	}))
	register("Quests", "TeleportObjective", questsTab:AddButton({
		Text = "Teleport to Objective",
		Callback = guard("Quest Objective", function()
			local name = UI.activeQuest
			return queueAction("Objective: " .. tostring(name), "quest:objective:" .. tostring(name), function()
				return teleportQuestEndpoint(name, false)
			end)
		end),
	}))
	register("Quests", "TeleportTurnIn", questsTab:AddButton({
		Text = "Teleport to Turn-In",
		Callback = guard("Quest Turn-In", function()
			local name = UI.activeQuest
			return queueAction("Turn-in NPC: " .. tostring(name), "quest:turnin_npc:" .. tostring(name), function()
				return teleportQuestEndpoint(name, true)
			end)
		end),
	}))
	questsTab:AddSection("Completed / Known Quests")
	register("Quests", "Completed", questsTab:AddDropdown({
		Text = "Completed Quest",
		Description = "Cache-only completed list; archived and skipped rows remain available in All Quest Lookup.",
		Options = {},
		Callback = guard("Completed Quest", function(value)
			UI.completedQuest = value
			UI.detailQuest = value
			updateQuestDetails()
			return true
		end),
	}))
	register("Quests", "CompletedStatus", questsTab:AddParagraph({
		Title = "Completed Quest Cache",
		Text = "Refresh State to populate completed quests.",
	}))

	mobsTab:AddSection("Target Pool")
	register("Mobs", "Targets", mobsTab:AddDropdown({
		Text = "Mob Targets",
		Description = string.format("%d generated targets plus a shallow live snapshot when available.", #mobNames),
		Options = mobNames,
		MultiSelect = true,
		Default = {},
		Callback = guard("Mob Targets", function(values)
			UI.mobs = copyArray(values, 64)
			return controllerCall("setSelectedMobs", UI.mobs)
		end),
	}))
	register("Mobs", "Mode", mobsTab:AddDropdown({
		Text = "Farm Mode",
		Options = { "NEAREST", "ROUND_ROBIN", "FINISH_GROUP", "PRIORITY" },
		Default = UI.mobMode,
		Callback = guard("Mob Mode", function(value)
			UI.mobMode = value
			return controllerCall("setMobMode", value)
		end),
	}))
	register("Mobs", "Continuous", mobsTab:AddToggle({
		Text = "Continuous Mob Farm",
		Description = "Assign MANUAL_MOB to the selected pool.",
		Default = false,
		Callback = guard("Mob Farm", function(value)
			UI.mobContinuous = value == true
			if UI.mobContinuous then
				if #UI.mobs == 0 then
					UI.mobContinuous = false
					setControl("Mobs", "Continuous", false)
					return false, "Select at least one mob"
				end
				controllerCall("setSelectedMobs", UI.mobs)
				controllerCall("setMobMode", UI.mobMode)
				return startOwner(OWNER.MANUAL_MOB, "ui_mob_continuous")
			end
			if controllerOwner() == OWNER.MANUAL_MOB then return stopOwner("ui_mob_stop") end
			return true
		end),
	}))
	register("Mobs", "Stop", mobsTab:AddButton({
		Text = "Stop Mob Farm",
		Callback = guard("Stop Mob Farm", function()
			UI.mobContinuous = false
			setControl("Mobs", "Continuous", false)
			if controllerOwner() == OWNER.MANUAL_MOB then return stopOwner("ui_mob_stop") end
			return true
		end),
	}))
	register("Mobs", "RefreshLive", mobsTab:AddButton({
		Text = "Refresh Shallow Live List",
		Description = "Merge Resolver.enemySnapshot when present. No deep scan.",
		Callback = guard("Live Mob List", function()
			refreshDynamicOptions(true)
			updateMobStatus()
			return true
		end),
	}))
	register("Mobs", "Status", mobsTab:AddParagraph({ Title = "Selected Mob Counts", Text = "Select one or more targets." }))
	mobsTab:AddSection("Combat Settings")
	register("Mobs", "CombatRange", mobsTab:AddSlider({
		Text = "Combat Range",
		Min = 2,
		Max = 30,
		Increment = 0.5,
		Default = UI.combatRange,
		Suffix = " studs",
		Callback = guard("Combat Range", function(value)
			UI.combatRange = clampNumber(value, 2, 30, 5.5)
			Config.CombatRange = UI.combatRange
			return controllerCall("setCombatRange", UI.combatRange)
		end),
	}))
	register("Mobs", "TweenSpeed", mobsTab:AddSlider({
		Text = "Tween Speed",
		Min = 20,
		Max = 300,
		Increment = 5,
		Default = UI.tweenSpeed,
		Suffix = " studs/s",
		Callback = guard("Tween Speed", function(value)
			UI.tweenSpeed = clampNumber(value, 20, 300, 95)
			Config.TweenSpeed = UI.tweenSpeed
			return true
		end),
	}))
	register("Mobs", "Stickiness", mobsTab:AddSlider({
		Text = "Target Stickiness",
		Description = "Bounded preference interval shared with Config/controller state.",
		Min = 0,
		Max = 30,
		Increment = 0.5,
		Default = UI.stickiness,
		Suffix = "s",
		Callback = guard("Target Stickiness", function(value)
			UI.stickiness = clampNumber(value, 0, 30, 2)
			Config.TargetStickiness = UI.stickiness
			if type(Controller.setTargetStickiness) == "function" then
				pcall(Controller.setTargetStickiness, Controller, UI.stickiness)
			else
				Controller.targetStickiness = UI.stickiness
			end
			return true
		end),
	}))
	register("Mobs", "SwitchDistance", mobsTab:AddSlider({
		Text = "Target Switch Distance",
		Description = "After stickiness expires, switch only when the current target is farther than this.",
		Min = 10,
		Max = 300,
		Increment = 5,
		Default = UI.switchDistance,
		Suffix = " studs",
		Callback = guard("Target Switch Distance", function(value)
			UI.switchDistance = clampNumber(value, 10, 300, 55)
			Config.TargetSwitchDistance = UI.switchDistance
			return controllerCall("setTargetSwitchDistance", UI.switchDistance)
		end),
	}))

	bossesTab:AddSection("Generated Boss Evidence")
	register("Bosses", "Targets", bossesTab:AddDropdown({
		Text = "Boss Multi-Select",
		Description = string.format("%d targets backed by Defeat, BossDrop, or explicit known-boss metadata.", #bossNames),
		Options = bossNames,
		MultiSelect = true,
		Default = {},
		Callback = guard("Boss Targets", function(values)
			UI.bosses = copyArray(values, 64)
			if #UI.bosses > 0 and not contains(UI.bosses, UI.bossFocus) then
				UI.bossFocus = UI.bosses[1]
				setControl("Bosses", "Focus", UI.bossFocus)
			end
			updateBossDetails()
			return controllerCall("setSelectedBosses", UI.bosses)
		end),
	}))
	register("Bosses", "Focus", bossesTab:AddDropdown({
		Text = "Focused Boss",
		Description = "Used by teleport and one-kill actions.",
		Options = bossNames,
		Default = UI.bossFocus,
		Callback = guard("Focused Boss", function(value)
			UI.bossFocus = value
			updateBossDetails()
			return true
		end),
	}))
	register("Bosses", "Details", bossesTab:AddParagraph({ Title = "Boss Status", Text = "Select a data-derived boss." }))
	register("Bosses", "Teleport", bossesTab:AddButton({
		Text = "Teleport to Focused Boss",
		Description = "Use a live indexed enemy, then verified marker/island evidence.",
		Callback = guard("Boss Teleport", function()
			local name = UI.bossFocus
			return queueAction("Boss location: " .. tostring(name), "boss:teleport:" .. tostring(name), function()
				if not name then return false, "Select a boss" end
				for _, instance in ipairs(enemiesFor(name)) do
					if enemyAlive(instance) and GB.World and type(GB.World.ToEnemy) == "function" then
						return GB.World.ToEnemy(instance, Config.CombatRange or 5.5)
					end
				end
				local evidence = bossMap[name] or {}
				local island = evidence.islands and evidence.islands[1]
				if island and stateSnapshot().PhysicalIsland ~= island and GB.Travel and type(GB.Travel.goIsland) == "function" then
					local moved = GB.Travel.goIsland(island)
					if moved then return true, "traveling to " .. island end
				end
				local marker = evidence.markers and evidence.markers[1]
				if marker and GB.Resolver and type(GB.Resolver.resolveMarker) == "function" then
					local resolved = GB.Resolver.resolveMarker(marker, { Island = island, ExpectedRole = "marker", deep = false })
					local instance = resolveInstance(resolved)
					if instance and GB.World and type(GB.World.goPlace) == "function" then return GB.World.goPlace(instance) end
				end
				return false, "Boss is not alive and no verified marker is loaded"
			end)
		end),
	}))
	register("Bosses", "KillOnce", bossesTab:AddButton({
		Text = "Kill Focused Boss Once",
		Description = "Assign MANUAL_BOSS for one confirmed target death, then return to IDLE.",
		Callback = guard("Kill Boss", function()
			local name = UI.bossFocus
			if not name then return false, "Select a boss" end
			UI.bossAuto, UI.bossWait = false, false
			setControl("Bosses", "AutoFarm", false)
			setControl("Bosses", "WaitSpawn", false)
			UI.bosses = { name }
			controllerCall("setSelectedBosses", UI.bosses)
			controllerCall("setWaitBoss", false)
			controllerCall("setBossKillLimit", 1)
			return startOwner(OWNER.MANUAL_BOSS, "ui_boss_once")
		end),
	}))
	register("Bosses", "WaitSpawn", bossesTab:AddToggle({
		Text = "Wait at Verified Spawn",
		Description = "Respawn duration is UNKNOWN; indexed liveness and markers only.",
		Default = false,
		Callback = guard("Boss Spawn Wait", function(value)
			UI.bossWait = value == true
			controllerCall("setWaitBoss", UI.bossWait)
			if UI.bossWait then
				local selected = #UI.bosses > 0 and UI.bosses or (UI.bossFocus and { UI.bossFocus } or {})
				if #selected == 0 then
					UI.bossWait = false
					setControl("Bosses", "WaitSpawn", false)
					return false, "Select at least one boss"
				end
				controllerCall("setSelectedBosses", selected)
				controllerCall("setBossKillLimit", nil)
				return startOwner(OWNER.MANUAL_BOSS, "ui_boss_wait")
			end
			if controllerOwner() == OWNER.MANUAL_BOSS and not UI.bossAuto then return stopOwner("ui_boss_wait_off") end
			return true
		end),
	}))
	register("Bosses", "AutoFarm", bossesTab:AddToggle({
		Text = "Auto Farm Selected Bosses",
		Description = "Assign MANUAL_BOSS to the full selected set.",
		Default = false,
		Callback = guard("Boss Farm", function(value)
			UI.bossAuto = value == true
			if UI.bossAuto then
				local selected = #UI.bosses > 0 and UI.bosses or (UI.bossFocus and { UI.bossFocus } or {})
				if #selected == 0 then
					UI.bossAuto = false
					setControl("Bosses", "AutoFarm", false)
					return false, "Select at least one boss"
				end
				UI.bosses = selected
				controllerCall("setSelectedBosses", selected)
				controllerCall("setWaitBoss", UI.bossWait)
				controllerCall("setBossKillLimit", nil)
				return startOwner(OWNER.MANUAL_BOSS, "ui_boss_auto")
			end
			if controllerOwner() == OWNER.MANUAL_BOSS and not UI.bossWait then return stopOwner("ui_boss_stop") end
			return true
		end),
	}))
	register("Bosses", "Stop", bossesTab:AddButton({
		Text = "Stop Boss Automation",
		Callback = guard("Stop Boss Farm", function()
			UI.bossAuto, UI.bossWait = false, false
			setControl("Bosses", "AutoFarm", false)
			setControl("Bosses", "WaitSpawn", false)
			controllerCall("setWaitBoss", false)
			controllerCall("setBossKillLimit", nil)
			if controllerOwner() == OWNER.MANUAL_BOSS then return stopOwner("ui_boss_stop") end
			return true
		end),
	}))

	teleportTab:AddSection("Physical Islands")
	register("Teleport", "Island", teleportTab:AddDropdown({
		Text = "Physical Map",
		Description = "Only Anchor Town, Clown Town, and Maple Village.",
		Options = PHYSICAL_ISLANDS,
		Default = UI.island,
		Callback = guard("Physical Map", function(value) UI.island = value return true end),
	}))
	register("Teleport", "GoIsland", teleportTab:AddButton({
		Text = "Go to Selected Map",
		Description = "Travel.goIsland owns movement and progression gates.",
		Callback = guard("Map Travel", function()
			local island = UI.island
			return queueAction("Travel: " .. tostring(island), "travel:island:" .. tostring(island), function()
				if not (GB.Travel and type(GB.Travel.goIsland) == "function") then return false, "Travel handler unavailable" end
				return GB.Travel.goIsland(island)
			end)
		end),
	}))
	for _, islandName in ipairs(PHYSICAL_ISLANDS) do
		local island = islandName
		register("Teleport", "Go" .. island:gsub("%s+", ""), teleportTab:AddButton({
			Text = "Go to " .. island,
			Description = "Verified physical island route through Travel.goIsland.",
			Callback = guard("Map Travel", function()
				UI.island = island
				setControl("Teleport", "Island", island)
				return queueAction("Travel: " .. island, "travel:island:" .. island, function()
					if not (GB.Travel and type(GB.Travel.goIsland) == "function") then return false, "Travel handler unavailable" end
					return GB.Travel.goIsland(island)
				end)
			end),
		}))
	end
	teleportTab:AddSection("NPC Index")
	register("Teleport", "NPC", teleportTab:AddDropdown({
		Text = "NPC",
		Description = string.format("%d generated names; searchable.", #npcNames),
		Options = npcNames,
		Default = UI.npc,
		Callback = guard("NPC", function(value)
			UI.npc = value
			updateNpcDetails()
			return true
		end),
	}))
	register("Teleport", "NPCDetails", teleportTab:AddParagraph({ Title = "NPC Related Quests", Text = "Select an NPC." }))
	register("Teleport", "GoNPC", teleportTab:AddButton({
		Text = "Go to Selected NPC",
		Callback = guard("NPC Travel", function()
			local name = UI.npc
			return queueAction("NPC: " .. tostring(name), "travel:npc:" .. tostring(name), function()
				return teleportNpc(name, primaryNpcIsland(name))
			end)
		end),
	}))
	teleportTab:AddSection("Important Locations")
	register("Teleport", "Location", teleportTab:AddDropdown({
		Text = "Indexed Location",
		Description = "Generated stage markers, NPCs, and shop endpoints.",
		Options = locationNames,
		Default = UI.location,
		Callback = guard("Location", function(value) UI.location = value return true end),
	}))
	register("Teleport", "GoLocation", teleportTab:AddButton({
		Text = "Go to Selected Location",
		Callback = guard("Location Travel", function()
			local label = UI.location
			return queueAction("Location: " .. tostring(label), "travel:location:" .. tostring(label), function()
				return teleportLocation(label)
			end)
		end),
	}))
	register("Teleport", "Cancel", teleportTab:AddButton({
		Text = "Cancel Movement",
		Callback = guard("Cancel Movement", function()
			if GB.World and type(GB.World.cancelTween) == "function" then GB.World.cancelTween() return true end
			return false, "Movement controller unavailable"
		end),
	}))
	teleportTab:AddSection("Rowboat")
	register("Teleport", "BuyRowboat", teleportTab:AddButton({
		Text = "Buy Rowboat",
		Description = "Verified Ships purchase path; 50 gold.",
		Callback = guard("Buy Rowboat", function()
			return queueAction("Buy Rowboat", "boat:buy", function()
				if not (GB.Boat and type(GB.Boat.buyRowboat) == "function") then return false, "Boat purchase unavailable" end
				return GB.Boat.buyRowboat()
			end)
		end),
	}))
	register("Teleport", "SpawnRowboat", teleportTab:AddButton({
		Text = "Spawn Rowboat",
		Description = "Use the current Boat spawn handler.",
		Callback = guard("Spawn Rowboat", function()
			return queueAction("Spawn Rowboat", "boat:spawn", function()
				if not (GB.Boat and type(GB.Boat.spawnRowboat) == "function") then return false, "Boat spawn unavailable" end
				return GB.Boat.spawnRowboat()
			end)
		end),
	}))

	itemsTab:AddSection("Generated and Live Inventory")
	register("Items", "Item", itemsTab:AddDropdown({
		Text = "Item",
		Description = "Generated item sources merged with current inventory.",
		Options = baseItemNames,
		Default = UI.item,
		Callback = guard("Item", function(value)
			UI.item = value
			updateItemDetails()
			return true
		end),
	}))
	register("Items", "Details", itemsTab:AddParagraph({ Title = "Item Source / Status", Text = "Select an item." }))
	register("Items", "Acquire", itemsTab:AddButton({
		Text = "Acquire Selected Item",
		Description = "Runs one allowlisted direct step; success requires ownership or quest credit.",
		Callback = guard("Acquire Item", function()
			local name = UI.item
			local allowed, method, requiredFlag = itemActionAllowed(name)
			if not allowed then updateItemDetails() return false, method end
			local spec = itemSpec(name) or {}
			return queueAction("Acquire: " .. name, "item:acquire:" .. name, function()
				return runItemAcquire(name, 1, {
					Method = method,
					Source = spec.source or spec.Source,
					Location = spec.location or spec.Location,
				}, requiredFlag)
			end)
		end),
	}))
	register("Items", "Inventory", itemsTab:AddParagraph({ Title = "Live Inventory", Text = "Inventory cache is empty." }))
	itemsTab:AddParagraph({
		Title = "Unresolved Inventory Features",
		Text = "Pets and bank deposit/withdraw remain UNRESOLVED. No actions are exposed.",
	})

	equipmentTab:AddSection("Owned Equipment")
	register("Equipment", "Owned", equipmentTab:AddDropdown({
		Text = "Owned Item",
		Description = "Live owned items with generated equipment evidence.",
		Options = {},
		Callback = guard("Equipment", function(value)
			UI.equipment = value
			updateEquipmentDetails()
			return true
		end),
	}))
	register("Equipment", "Details", equipmentTab:AddParagraph({ Title = "Equipment State", Text = "No owned equipment indexed." }))
	register("Equipment", "Equip", equipmentTab:AddButton({
		Text = "Equip Selected",
		Description = "Use Equipment.equipNamed and its validated strategy.",
		Callback = guard("Equip Item", function()
			local name = UI.equipment
			if not (name and GB.Equipment and type(GB.Equipment.equipNamed) == "function") then return false, "Select owned equipment" end
			return queueAction("Equip: " .. name, "equipment:equip:" .. name, function()
				return GB.Equipment.equipNamed(name, { Manual = true })
			end)
		end),
	}))
	register("Equipment", "UnequipHeld", equipmentTab:AddButton({
		Text = "Unequip Held Item",
		Description = "Use the verified HeldItem unequip path; gear-slot removal remains unresolved.",
		Callback = guard("Unequip Held", function()
			if not (GB.Remotes and type(GB.Remotes.heldUnequip) == "function") then
				return false, "HeldItem unequip unavailable"
			end
			return queueAction("Unequip held item", "equipment:unequip_held", function()
				return GB.Remotes.heldUnequip()
			end)
		end),
	}))
	register("Equipment", "Upgrade", equipmentTab:AddButton({
		Text = "Upgrade Selected",
		Description = "Runs only when generated Upgrade-stage evidence exists.",
		Callback = guard("Upgrade Item", function()
			local name = UI.equipment
			if not name or upgradeTargets[name] ~= true then return false, "No generated Upgrade-stage support for this item" end
			if not (GB.Equipment and type(GB.Equipment.upgradeNamed) == "function") then return false, "Upgrade handler unavailable" end
			return queueAction("Upgrade: " .. name, "equipment:upgrade:" .. name, function() return GB.Equipment.upgradeNamed(name) end)
		end),
	}))
	equipmentTab:AddSection("Explicit Preference")
	register("Equipment", "Preferred", equipmentTab:AddDropdown({
		Text = "Preferred Owned Item",
		Description = "Explicit user choice only; no invented ranking.",
		Options = {},
		Callback = guard("Preferred Equipment", function(value) UI.preferredEquipment = value return true end),
	}))
	register("Equipment", "AutoPreferred", equipmentTab:AddToggle({
		Text = "Auto Equip Preferred",
		Description = "Queue the explicit choice when it is not equipped.",
		Default = false,
		Callback = guard("Auto Equip Preferred", function(value)
			UI.autoPreferredEquipment = value == true
			if UI.autoPreferredEquipment and not UI.preferredEquipment then
				UI.autoPreferredEquipment = false
				setControl("Equipment", "AutoPreferred", false)
				return false, "Select preferred owned equipment"
			end
			return true
		end),
	}))

	skillsTab:AddSection("Generated Skills")
	register("Skills", "Skill", skillsTab:AddDropdown({
		Text = "Skill",
		Description = "Generated skills merged with live player skill names.",
		Options = baseSkillNames,
		Default = UI.skill,
		Callback = guard("Skill", function(value)
			UI.skill = value
			local row = Generated.Skills and Generated.Skills[value]
			UI.linkedQuest = type(row) == "table" and row.Quests and row.Quests[1] or nil
			setOptions("Skills", "LinkedQuest", type(row) == "table" and row.Quests or {}, UI.linkedQuest)
			updateSkillDetails()
			return true
		end),
	}))
	register("Skills", "Details", skillsTab:AddParagraph({ Title = "Skill Details", Text = "Select a generated skill." }))
	register("Skills", "Equip", skillsTab:AddButton({
		Text = "Equip Selected Skill",
		Callback = guard("Equip Skill", function()
			local name = UI.skill
			if not (name and GB.Skills and type(GB.Skills.equip) == "function") then return false, "Skill equip handler unavailable" end
			return queueAction("Equip skill: " .. name, "skill:equip:" .. name, function() return GB.Skills.equip(name) end)
		end),
	}))
	register("Skills", "Cast", skillsTab:AddButton({
		Text = "Cast Selected Skill",
		Description = "Use the existing equipped/hotbar-validated cast path.",
		Callback = guard("Cast Skill", function()
			local name = UI.skill
			if not (name and GB.Skills and type(GB.Skills.cast) == "function") then return false, "Skill cast handler unavailable" end
			return queueAction("Cast skill: " .. name, "skill:cast:" .. name, function()
				return GB.Skills.cast(name, { Manual = true })
			end)
		end),
	}))
	register("Skills", "LinkedQuest", skillsTab:AddDropdown({
		Text = "Linked Quest",
		Description = "Only quests listed by GeneratedData.Skills.",
		Options = {},
		Callback = guard("Linked Quest", function(value) UI.linkedQuest = value return true end),
	}))
	register("Skills", "RunLinkedQuest", skillsTab:AddButton({
		Text = "Progress Linked Quest",
		Description = "Assign MANUAL_QUEST to the generated link.",
		Callback = guard("Linked Quest", function()
			if not UI.linkedQuest then return false, "No linked quest selected" end
			controllerCall("setSelectedQuest", UI.linkedQuest)
			return startOwner(OWNER.MANUAL_QUEST, "ui_skill_linked_quest")
		end),
	}))
	skillsTab:AddParagraph({
		Title = "Fighting Style Status",
		Text = "Purchase/unlock stages without a verified runtime method remain status-only.",
	})

	statsTab:AddSection("Live Stat State")
	register("Stats", "Status", statsTab:AddParagraph({ Title = "Six Stats", Text = "Waiting for the cached stat snapshot." }))
	register("Stats", "Preset", statsTab:AddDropdown({
		Text = "Stat Preset",
		Description = "Updates Config.StatRatio; Stats validates every investment.",
		Options = { "Balanced", "Strength", "Sword", "Gun", "Fruit", "Hybrid", "Custom" },
		Default = UI.statPreset,
		Callback = guard("Stat Preset", function(value)
			UI.statPreset = value
			local presets = {
				Balanced = { Strength = 1, Health = 1, Willpower = 1, Agility = 1, Precision = 1, Energy = 1 },
				Strength = { Strength = 8, Health = 2 },
				Sword = { Strength = 6, Health = 2, Agility = 2 },
				Gun = { Precision = 6, Health = 2, Agility = 2 },
				Fruit = { Willpower = 6, Health = 2, Energy = 2 },
				Hybrid = { Strength = 3, Health = 2, Willpower = 2, Agility = 1, Precision = 2, Energy = 1 },
			}
			local chosen = presets[value]
			if chosen then
				for _, stat in ipairs(STAT_NAMES) do
					UI.statWeights[stat] = tonumber(chosen[stat]) or 0
					setControl("Stats", "Weight" .. stat, tostring(UI.statWeights[stat]))
				end
				Config.StatRatio = copyMap(UI.statWeights)
				Config.Build = value
				if GB.Stats and type(GB.Stats.setBuild) == "function" then
					GB.Stats.setBuild(value)
				elseif GB.Stats and type(GB.Stats.markDirty) == "function" then
					GB.Stats.markDirty("ui_preset")
				end
			end
			return true
		end),
	}))
	statsTab:AddSection("Custom Weights")
	for _, statName in ipairs(STAT_NAMES) do
		local stat = statName
		register("Stats", "Weight" .. stat, statsTab:AddTextbox({
			Text = stat .. " Weight",
			Placeholder = "0",
			Default = tostring(UI.statWeights[stat] or 0),
			Callback = guard(stat .. " Weight", function(text)
				local value = tonumber(trim(text) or "")
				if not value or value < 0 or value > 100 then
					setControl("Stats", "Weight" .. stat, tostring(UI.statWeights[stat] or 0))
					return false, "Weight must be from 0 to 100"
				end
				local candidate = copyMap(UI.statWeights)
				candidate[stat] = value
				local total = 0
				for _, name in ipairs(STAT_NAMES) do total = total + math.max(0, tonumber(candidate[name]) or 0) end
				if total <= 0 then
					setControl("Stats", "Weight" .. stat, tostring(UI.statWeights[stat] or 0))
					return false, "At least one stat weight must be positive"
				end
				UI.statPreset = "Custom"
				setControl("Stats", "Preset", "Custom")
				UI.statWeights = candidate
				Config.StatRatio = copyMap(UI.statWeights)
				Config.Build = "Custom"
				if GB.Stats and type(GB.Stats.setRatio) == "function" then
					GB.Stats.setRatio(Config.StatRatio)
				elseif GB.Stats and type(GB.Stats.markDirty) == "function" then
					GB.Stats.markDirty("ui_ratio")
				end
				return true
			end),
		}))
	end
	register("Stats", "InvestAvailable", statsTab:AddButton({
		Text = "Invest Available Now",
		Description = "Queue one verified point toward the largest ratio deficit.",
		Callback = guard("Invest Available", function()
			if not (GB.Stats and type(GB.Stats.ReadStatState) == "function" and type(GB.Stats.Invest) == "function") then
				return false, "Stats handler unavailable"
			end
			return queueAction("Invest available point", "stats:available", function()
				local state = GB.Stats.ReadStatState()
				if not state or (tonumber(state.Unused) or 0) < 1 then return false, "No unused stat points" end
				local totalWeight, totalStats = 0, 0
				for _, stat in ipairs(STAT_NAMES) do
					totalWeight = totalWeight + math.max(0, tonumber(Config.StatRatio and Config.StatRatio[stat]) or 0)
					totalStats = totalStats + math.max(0, tonumber(state[stat]) or 0)
				end
				if totalWeight <= 0 then return false, "At least one stat weight must be positive" end
				local selected, largestDeficit
				for _, stat in ipairs(STAT_NAMES) do
					local weight = math.max(0, tonumber(Config.StatRatio and Config.StatRatio[stat]) or 0)
					if weight > 0 then
						local deficit = ((totalStats + 1) * weight / totalWeight) - (tonumber(state[stat]) or 0)
						if largestDeficit == nil or deficit > largestDeficit then selected, largestDeficit = stat, deficit end
					end
				end
				return GB.Stats.Invest(selected or "Strength", 1)
			end)
		end),
	}))
	register("Stats", "AutoStats", statsTab:AddToggle({
		Text = "Auto Stats",
		Description = "Mirror the runtime AutoStats flag.",
		Default = UI.autoStats,
		Callback = guard("Auto Stats", function(value)
			UI.autoStats = value == true
			Config.AutoStats = UI.autoStats
			controllerCall("setUtilityAuto", "AutoStats", UI.autoStats)
			setControl("Home", "AutoStats", UI.autoStats)
			if UI.autoStats and GB.Stats and type(GB.Stats.markDirty) == "function" then GB.Stats.markDirty("ui_stats_tab") end
			return true
		end),
	}))
	statsTab:AddSection("Quick Investment")
	register("Stats", "Selected", statsTab:AddDropdown({
		Text = "Selected Stat",
		Options = STAT_NAMES,
		Default = UI.statSelected,
		Callback = guard("Selected Stat", function(value) UI.statSelected = value return true end),
	}))
	local function quickInvest(amount)
		local stat = UI.statSelected
		if not (stat and GB.Stats and type(GB.Stats.Invest) == "function") then return false, "Stats.Invest unavailable" end
		return queueAction("Invest " .. stat .. " +" .. tostring(amount), "stats:quick", function()
			local requested = amount
			if amount == "MAX" then
				local state = type(GB.Stats.ReadStatState) == "function" and GB.Stats.ReadStatState() or nil
				requested = state and tonumber(state.Unused) or 0
			end
			requested = math.max(0, math.floor(tonumber(requested) or 0))
			if requested < 1 then return false, "No unused stat points" end
			return GB.Stats.Invest(stat, requested)
		end)
	end
	for _, amount in ipairs({ 1, 5, 10, "MAX" }) do
		local amountValue = amount
		register("Stats", "Add" .. tostring(amountValue), statsTab:AddButton({
			Text = amountValue == "MAX" and "Invest Max" or ("Invest +" .. tostring(amountValue)),
			Callback = guard("Quick Stat Invest", function() return quickInvest(amountValue) end),
		}))
	end

	lifeTab:AddSection("Mining")
	register("LifeSkills", "Mining", lifeTab:AddDropdown({
		Text = "Verified Mining Targets",
		Description = "Derived only from QuestSpecs Mining methods.",
		Options = lifeTargets.Mining,
		MultiSelect = true,
		Default = {},
		Callback = guard("Mining Targets", function(values)
			UI.mining = copyArray(values, 32)
			return true
		end),
	}))
	register("LifeSkills", "AutoMining", lifeTab:AddToggle({
		Text = "Auto Mine Selected",
		Description = "Queue one LifeSkills.mineToward handler at a time.",
		Default = false,
		Callback = guard("Auto Mining", function(value)
			UI.autoMining = value == true
			if UI.autoMining then
				if #UI.mining == 0 then
					UI.autoMining, Config.AutoMining = false, false
					setControl("LifeSkills", "AutoMining", false)
					return false, "Select at least one mining target"
				end
				stopOwner("ui_life_skill_owner")
				Config.AutoMining = true
			else
				Config.AutoMining = false
				local handle = M._actionHandles["life:mining"]
				if handle and type(handle.Cancel) == "function" then pcall(handle.Cancel, handle, "mining disabled") end
			end
			return true
		end),
	}))
	register("LifeSkills", "MineOnce", lifeTab:AddButton({
		Text = "Mine Selected Once",
		Callback = guard("Mine Once", function()
			local target = UI.mining[1]
			if not (target and GB.LifeSkills and type(GB.LifeSkills.mineToward) == "function") then return false, "Select a verified mining target" end
			return queueAction("Mine: " .. target, "life:mine_once", function()
				return withRequiredAuto("AutoMining", function() return GB.LifeSkills.mineToward(target) end)
			end)
		end),
	}))
	register("LifeSkills", "Status", lifeTab:AddParagraph({
		Title = "Life Skill Status",
		Text = "Mining uses the current QTE handler. Other life skills remain PARTIAL.",
	}))
	lifeTab:AddSection("Verified Smelting")
	register("LifeSkills", "SmeltCopper", lifeTab:AddButton({
		Text = "Smelt Copper Bar",
		Description = "Verified First Upgrade furnace route; requires Copper Ore.",
		Callback = guard("Smelt Copper", function()
			if not (GB.LifeSkills and type(GB.LifeSkills.smeltToward) == "function") then return false, "Smelt handler unavailable" end
			return queueAction("Smelt Copper Bar", "life:smelt:copper", function()
				return withRequiredAuto("AutoMining", function() return GB.LifeSkills.smeltToward("Copper Bar") end)
			end)
		end),
	}))
	lifeTab:AddSection("Partial Existing Handlers")
	register("LifeSkills", "Fishing", lifeTab:AddDropdown({
		Text = "Fishing Target",
		Description = "PARTIAL: navigation/equip exists; cast payload is unresolved.",
		Options = lifeTargets.Fishing,
		Default = UI.fishing,
		Callback = guard("Fishing Target", function(value) UI.fishing = value return true end),
	}))
	register("LifeSkills", "FishStep", lifeTab:AddButton({
		Text = "Run Fishing Handler Step",
		Callback = guard("Fishing Step", function()
			if not (UI.fishing and GB.LifeSkills and type(GB.LifeSkills.fishToward) == "function") then return false, "No generated fishing target" end
			local target = UI.fishing
			return queueAction("Fishing: " .. target, "life:fishing", function()
				return withRequiredAuto("AutoFishing", function() return GB.LifeSkills.fishToward(target) end)
			end)
		end),
	}))
	register("LifeSkills", "Farming", lifeTab:AddDropdown({
		Text = "Farming Target",
		Description = "PARTIAL: only the current prompt-based handler is called.",
		Options = lifeTargets.Farming,
		Default = UI.farming,
		Callback = guard("Farming Target", function(value) UI.farming = value return true end),
	}))
	register("LifeSkills", "FarmStep", lifeTab:AddButton({
		Text = "Run Farming Handler Step",
		Callback = guard("Farming Step", function()
			if not (UI.farming and GB.LifeSkills and type(GB.LifeSkills.farmToward) == "function") then return false, "No generated farming target" end
			local target = UI.farming
			return queueAction("Farming: " .. target, "life:farming", function()
				return withRequiredAuto("AutoFarming", function() return GB.LifeSkills.farmToward("Harvest", target) end)
			end)
		end),
	}))
	register("LifeSkills", "Cooking", lifeTab:AddDropdown({
		Text = "Cooking Target",
		Description = "PARTIAL: only the existing navigation handler is called.",
		Options = lifeTargets.Cooking,
		Default = UI.cooking,
		Callback = guard("Cooking Target", function(value) UI.cooking = value return true end),
	}))
	register("LifeSkills", "CookStep", lifeTab:AddButton({
		Text = "Run Cooking Handler Step",
		Callback = guard("Cooking Step", function()
			if not (UI.cooking and GB.LifeSkills and type(GB.LifeSkills.cookToward) == "function") then return false, "No generated cooking target" end
			local target = UI.cooking
			return queueAction("Cooking: " .. target, "life:cooking", function()
				return withRequiredAuto("AutoCooking", function() return GB.LifeSkills.cookToward(target) end)
			end)
		end),
	}))
	lifeTab:AddParagraph({
		Title = "General Craft / Dig",
		Text = "UNRESOLVED. No general craft or dig action is exposed.",
	})

	fruitTab:AddSection("Fruit State")
	register("Fruit", "Status", fruitTab:AddParagraph({ Title = "Current / Stored / Desired", Text = "Waiting for cached fruit state." }))
	register("Fruit", "Catalog", fruitTab:AddDropdown({
		Text = "Fruit Catalog",
		Description = "Generated fruit names plus live storage names.",
		Options = fruitNames,
		Default = UI.fruit,
		Callback = guard("Fruit", function(value) UI.fruit = value updateFruitStatus() return true end),
	}))
	register("Fruit", "Pickup", fruitTab:AddButton({
		Text = "Pickup Nearby Fruit",
		Description = "Use Fruit.pickupNearby and its shallow tagged/folder search.",
		Callback = guard("Fruit Pickup", function()
			if not (GB.Fruit and type(GB.Fruit.pickupNearby) == "function") then return false, "Fruit pickup unavailable" end
			return queueAction("Pickup nearby fruit", "fruit:pickup", function() return GB.Fruit.pickupNearby() end)
		end),
	}))
	register("Fruit", "AutoPickup", fruitTab:AddToggle({
		Text = "Auto Pickup Fruit",
		Description = "Mirror the existing AutoFruit handler flag.",
		Default = UI.fruitAutoPickup,
		Callback = guard("Auto Fruit", function(value)
			UI.fruitAutoPickup = value == true
			Config.AutoFruit = UI.fruitAutoPickup
			return true
		end),
	}))
	fruitTab:AddParagraph({
		Title = "Explicit Permanent-Fruit Actions",
		Text = "Warning: store/equip can change permanent or current fruit state. Confirm one action below. Eat/replace is not exposed.",
	})
	register("Fruit", "Confirm", fruitTab:AddToggle({
		Text = "Confirm Next Fruit State Change",
		Description = "Resets after one store or equip request.",
		Default = false,
		Callback = guard("Fruit Confirmation", function(value) UI.fruitConfirm = value == true return true end),
	}))
	register("Fruit", "Store", fruitTab:AddButton({
		Text = "Store Selected Fruit",
		Description = "Verified Remotes.storeFruit path; no force flag.",
		Callback = guard("Store Fruit", function()
			if not UI.fruitConfirm then return false, "Enable confirmation first" end
			if not (UI.fruit and GB.Remotes and type(GB.Remotes.storeFruit) == "function") then return false, "Store Fruit runtime method unavailable" end
			local name = UI.fruit
			UI.fruitConfirm = false
			setControl("Fruit", "Confirm", false)
			return queueAction("Store fruit: " .. name, "fruit:store:" .. name, function()
				return GB.Remotes.storeFruit(name, false)
			end)
		end),
	}))
	register("Fruit", "EquipPermanent", fruitTab:AddButton({
		Text = "Equip Selected Permanent Fruit",
		Description = "Verified method; no force flag and no eat action.",
		Callback = guard("Equip Permanent Fruit", function()
			if not UI.fruitConfirm then return false, "Enable confirmation first" end
			if not (UI.fruit and GB.Remotes and type(GB.Remotes.equipPermanentFruit) == "function") then
				return false, "Equip Permanent Fruit runtime method unavailable"
			end
			local name = UI.fruit
			UI.fruitConfirm = false
			setControl("Fruit", "Confirm", false)
			return queueAction("Equip permanent fruit: " .. name, "fruit:equip:" .. name, function()
				return GB.Remotes.equipPermanentFruit(name, false)
			end)
		end),
	}))

	hakiTab:AddSection("Runtime Evidence")
	register("Haki", "Status", hakiTab:AddParagraph({ Title = "Haki / Race / Trait", Text = "Refreshing cached state." }))
	hakiTab:AddParagraph({
		Title = "Haki and Race Actions",
		Text = "Haki trainer/unlock and race reroll are UNRESOLVED. They remain status-only.",
	})
	local auraMethod = GB.Haki and (
		type(rawget(GB.Haki, "rerollAuraColor")) == "function" and rawget(GB.Haki, "rerollAuraColor")
		or type(rawget(GB.Haki, "RerollAuraColor")) == "function" and rawget(GB.Haki, "RerollAuraColor")
	)
	local traitMethod = GB.RaceTrait and (
		type(rawget(GB.RaceTrait, "rerollTrait")) == "function" and rawget(GB.RaceTrait, "rerollTrait")
		or type(rawget(GB.RaceTrait, "RerollTrait")) == "function" and rawget(GB.RaceTrait, "RerollTrait")
	)
	if auraMethod or traitMethod then
		hakiTab:AddSection("Explicit Rerolls")
		register("Haki", "ConfirmReroll", hakiTab:AddToggle({
			Text = "Confirm Next Reroll",
			Description = "One-shot confirmation. Never runs automatically.",
			Default = false,
			Callback = guard("Reroll Confirmation", function(value)
				UI.rerollConfirm = value == true
				return true
			end),
		}))
	end
	if auraMethod then
		register("Haki", "AuraReroll", hakiTab:AddButton({
			Text = "Request Aura Color Reroll",
			Description = "Verified RerollAuraColor event. May consume the game's reroll product.",
			Callback = guard("Aura Color", function()
				if not UI.rerollConfirm then return false, "Enable one-shot reroll confirmation" end
				UI.rerollConfirm = false
				setControl("Haki", "ConfirmReroll", false)
				return queueAction("Aura color reroll", "haki:aura_reroll", function()
					return auraMethod()
				end)
			end),
		}))
	else
		hakiTab:AddParagraph({
			Title = "Aura Color",
			Text = "Status-only: exact runtime method unavailable.",
		})
	end
	if traitMethod then
		register("Haki", "TraitSlot", hakiTab:AddTextbox({
			Text = "Trait Slot",
			Description = "Verified Trait reroll payload uses an explicit slot number.",
			Placeholder = "1",
			Default = "1",
			Callback = guard("Trait Slot", function(value)
				local slot = math.floor(tonumber(value) or 0)
				if slot < 1 or slot > 8 then
					setControl("Haki", "TraitSlot", tostring(UI.traitSlot))
					return false, "Trait slot must be 1-8"
				end
				UI.traitSlot = slot
				setControl("Haki", "TraitSlot", tostring(slot))
				return true
			end),
		}))
		register("Haki", "TraitReroll", hakiTab:AddButton({
			Text = "Request Trait Slot Reroll",
			Description = "Verified Reroll(\"Trait\", slot) event. Explicit confirmation required.",
			Callback = guard("Trait Reroll", function()
				if not UI.rerollConfirm then return false, "Enable one-shot reroll confirmation" end
				UI.rerollConfirm = false
				setControl("Haki", "ConfirmReroll", false)
				local slot = UI.traitSlot
				return queueAction("Trait reroll slot " .. tostring(slot), "trait:reroll", function()
					return traitMethod(slot)
				end)
			end),
		}))
	else
		hakiTab:AddParagraph({
			Title = "Trait Action",
			Text = "Status-only: exact runtime method unavailable.",
		})
	end

	shopTab:AddSection("Generated Catalog")
	register("Shop", "Item", shopTab:AddDropdown({
		Text = "Shop Item",
		Description = string.format("%d generated entries with known catalog evidence.", #shopNames),
		Options = shopNames,
		Default = UI.shop,
		Callback = guard("Shop Item", function(value) UI.shop = value updateShopStatus() return true end),
	}))
	register("Shop", "Quantity", shopTab:AddTextbox({
		Text = "Quantity",
		Placeholder = "1",
		Default = "1",
		Callback = guard("Shop Quantity", function(text)
			local quantity = tonumber(trim(text) or "")
			if not quantity or quantity < 1 or quantity > 99 then
				setControl("Shop", "Quantity", tostring(UI.shopQuantity))
				return false, "Quantity must be from 1 to 99"
			end
			UI.shopQuantity = math.floor(quantity)
			setControl("Shop", "Quantity", tostring(UI.shopQuantity))
			return true
		end),
	}))
	register("Shop", "Status", shopTab:AddParagraph({ Title = "Price / Gold / Owned", Text = "Select a shop item." }))
	local function buySelectedShop(name, quantity)
		if not (name and shopSet[string.lower(name)] and GB.Shop and type(GB.Shop.buy) == "function") then return false, "Select a generated shop item" end
		quantity = math.max(1, math.min(99, math.floor(tonumber(quantity) or 1)))
		return queueAction("Buy " .. name .. " x" .. tostring(quantity), "shop:buy:" .. name, function()
			return GB.Shop.buy(name, quantity)
		end)
	end
	register("Shop", "Buy", shopTab:AddButton({
		Text = "Buy Selected",
		Description = "Use Shop.buy with generated price and live gold checks.",
		Callback = guard("Buy Item", function() return buySelectedShop(UI.shop, UI.shopQuantity) end),
	}))
	local quickNames, quickSeen = {}, {}
	for _, name in ipairs(GB.ItemData and type(GB.ItemData.PROGRESS_BUY) == "table" and GB.ItemData.PROGRESS_BUY or {}) do
		if shopSet[string.lower(tostring(name))] then addUnique(quickNames, quickSeen, name) end
	end
	if #quickNames == 0 then quickNames = copyArray(shopNames, 12) end
	UI.quickShop = quickNames[1]
	register("Shop", "Quick", shopTab:AddDropdown({
		Text = "Quick Progress Purchase",
		Description = "Dynamic progression subset; uses the same Shop.buy path.",
		Options = quickNames,
		Default = UI.quickShop,
		Callback = guard("Quick Purchase", function(value) UI.quickShop = value return true end),
	}))
	register("Shop", "QuickBuy", shopTab:AddButton({
		Text = "Buy Quick Selection",
		Callback = guard("Quick Purchase", function() return buySelectedShop(UI.quickShop, 1) end),
	}))
	local sellable = {}
	for _, name in ipairs(baseItemNames) do
		if GB.ItemData and type(GB.ItemData.canSell) == "function" then
			local ok, value = pcall(GB.ItemData.canSell, name)
			if ok and value == true then sellable[#sellable + 1] = name end
		end
	end
	if #sellable > 0 then
		UI.sellItem = sellable[1]
		register("Shop", "SellItem", shopTab:AddDropdown({
			Text = "Verified Sellable Item",
			Options = sellable,
			Default = UI.sellItem,
			Callback = guard("Sell Item", function(value) UI.sellItem = value return true end),
		}))
		register("Shop", "Sell", shopTab:AddButton({
			Text = "Sell Selected Safe Item",
			Callback = guard("Sell Item", function()
				local name = UI.sellItem
				if not (name and GB.ItemData.canSell(name) == true and GB.Shop and type(GB.Shop.sellNamed) == "function") then
					return false, "Item is not explicitly sellable"
				end
				return queueAction("Sell: " .. name, "shop:sell:" .. name, function() return GB.Shop.sellNamed(name) end)
			end),
		}))
	else
		shopTab:AddParagraph({
			Title = "Selling",
			Text = "No current ItemData entry is explicitly sellable. No sell action is exposed.",
		})
	end
	shopTab:AddSection("Rowboat")
	register("Shop", "BuyRowboat", shopTab:AddButton({
		Text = "Buy Rowboat",
		Callback = guard("Buy Rowboat", function() return buySelectedShop("Rowboat", 1) end),
	}))
	register("Shop", "SpawnRowboat", shopTab:AddButton({
		Text = "Spawn Rowboat",
		Callback = guard("Spawn Rowboat", function()
			return queueAction("Spawn Rowboat", "shop:boat:spawn", function()
				if not (GB.Boat and type(GB.Boat.spawnRowboat) == "function") then return false, "Boat spawn unavailable" end
				return GB.Boat.spawnRowboat()
			end)
		end),
	}))

	chestTab:AddSection("Indexed Chest Route")
	register("Chest", "Map", chestTab:AddDropdown({
		Text = "Chest Map",
		Description = "CURRENT or the verified Anchor Town route; the index covers Afuaru's chest set only.",
		Options = { "CURRENT", "Anchor Town" },
		Default = UI.chestMap,
		Callback = guard("Chest Map", function(value)
			UI.chestMap = value
			return controllerCall("setChestMap", value)
		end),
	}))
	register("Chest", "Collect", chestTab:AddButton({
		Text = "Collect Selected Map Route",
		Description = "MANUAL_CHEST processes one indexed chest per controller step.",
		Callback = guard("Chest Route", function()
			controllerCall("setChestMap", UI.chestMap)
			controllerCall("setChestAutoLoop", false)
			return startOwner(OWNER.MANUAL_CHEST, "ui_chest_route")
		end),
	}))
	register("Chest", "CollectCurrent", chestTab:AddButton({
		Text = "Collect All Chests in Current Map",
		Description = "Route every verified indexed chest on the current physical map.",
		Callback = guard("Current Chest Route", function()
			UI.chestMap = "CURRENT"
			setControl("Chest", "Map", "CURRENT")
			controllerCall("setChestMap", "CURRENT")
			controllerCall("setChestAutoLoop", false)
			return startOwner(OWNER.MANUAL_CHEST, "ui_chest_current")
		end),
	}))
	register("Chest", "Auto", chestTab:AddToggle({
		Text = "Auto Chest",
		Description = "Continue waiting and route one indexed chest at a time.",
		Default = false,
		Callback = guard("Auto Chest", function(value)
			UI.autoChest = value == true
			if UI.autoChest then
				controllerCall("setChestMap", UI.chestMap)
				controllerCall("setChestAutoLoop", true)
				return startOwner(OWNER.MANUAL_CHEST, "ui_chest_auto")
			end
			controllerCall("setChestAutoLoop", false)
			if controllerOwner() == OWNER.MANUAL_CHEST then return stopOwner("ui_chest_stop") end
			return true
		end),
	}))
	register("Chest", "Cancel", chestTab:AddButton({
		Text = "Cancel Chest Route",
		Callback = guard("Cancel Chest", function()
			UI.autoChest = false
			setControl("Chest", "Auto", false)
			controllerCall("setChestAutoLoop", false)
			if controllerOwner() == OWNER.MANUAL_CHEST then return stopOwner("ui_chest_cancel") end
			if GB.World and type(GB.World.cancelTween) == "function" then GB.World.cancelTween() end
			return true
		end),
	}))
	register("Chest", "Status", chestTab:AddParagraph({ Title = "Chest / Treasure Status", Text = "Refreshing indexed state." }))
	register("Chest", "Maps", chestTab:AddParagraph({ Title = "Treasure Map Inventory", Text = "No cached maps." }))
	chestTab:AddParagraph({
		Title = "Afuaru Chest Index Scope",
		Text = "Only Afuaru's Anchor Town chest set is verified. Clown Town and Maple Village have no supported chest index. Dig remains UNRESOLVED.",
	})

	codesTab:AddSection("Codes")
	local knownCodes = copyArray(type(Config.Codes) == "table" and Config.Codes or {}, 100)
	register("Codes", "Known", codesTab:AddParagraph({
		Title = "Known Codes",
		Text = string.format("%d known: %s", #knownCodes, join(knownCodes, ", ", "None")),
	}))
	register("Codes", "Code", codesTab:AddDropdown({
		Text = "Known Code",
		Options = knownCodes,
		Default = UI.code,
		Callback = guard("Code", function(value) UI.code = value return true end),
	}))
	local function redeemOne(code)
		code = trim(code)
		if not code then return false, "Enter a code" end
		return queueAction("Redeem code: " .. code, "code:redeem", function()
			return GB.Codes.redeem(code)
		end, { cancelActive = false, quiet = true })
	end

	local function beginCodesQueue(codes)
		local ok, result, detail = pcall(GB.Codes.redeemAll, codes)
		if not ok then return false, tostring(result) end
		if result == false then return false, detail end
		M._codesQueueProgress = true
		Config.AutoCodes = true
		controllerCall("setUtilityAuto", "AutoCodes", true)
		return true, detail
	end

	triggerAutoCodesOnce = function()
		if M._autoCodesTriggered then return true, "already started" end
		if #knownCodes == 0 then return false, "No known codes" end
		if Config.Enabled ~= true or not schedulerRunning() then return false, "runtime stopped" end
		local result, detail = beginCodesQueue(knownCodes)
		if result == false then return false, detail end
		M._autoCodesTriggered = true
		return true, detail
	end

	register("Codes", "Redeem", codesTab:AddButton({
		Text = "Redeem Selected",
		Description = "Submit one request through the shared Codes runtime.",
		Callback = guard("Redeem Code", function() return redeemOne(UI.code) end),
	}))
	register("Codes", "RedeemAll", codesTab:AddButton({
		Text = "Redeem All Known",
		Description = "Hand the known list to the single Codes-owned queue.",
		Callback = guard("Redeem All", function()
			return queueAction("Redeem all known codes", "code:all", function()
				return beginCodesQueue(knownCodes)
			end, { cancelActive = false })
		end),
	}))
	register("Codes", "Manual", codesTab:AddTextbox({
		Text = "Manual Code",
		Placeholder = "Exact code",
		Default = "",
		Callback = guard("Manual Code", function(value) UI.manualCode = trim(value) or "" return true end),
	}))
	register("Codes", "RedeemManual", codesTab:AddButton({
		Text = "Redeem Manual Code",
		Callback = guard("Manual Code", function() return redeemOne(UI.manualCode) end),
	}))
	register("Codes", "AutoJoin", codesTab:AddToggle({
		Text = "Auto Codes on Join",
		Description = "Call Codes.redeemAll once this session; Codes owns dequeue and feedback.",
		Default = UI.autoCodesOnJoin,
		Callback = guard("Auto Codes", function(value)
			UI.autoCodesOnJoin = value == true
			if UI.autoCodesOnJoin then
				return triggerAutoCodesOnce()
			end
			Config.AutoCodes = false
			M._codesQueueProgress = nil
			controllerCall("setUtilityAuto", "AutoCodes", false)
			GB.Codes.stop()
			return true
		end),
	}))
	register("Codes", "Status", codesTab:AddParagraph({ Title = "Code Result / Summary", Text = "No results cached." }))
	codesTab:AddSection("Verified Rewards")
	register("Codes", "ClaimRewards", codesTab:AddButton({
		Text = "Run Verified Rewards Tick",
		Description = "Calls only the current Rewards.claim or Rewards.tick implementation.",
		Callback = guard("Rewards", function()
			if not GB.Rewards then return false, "Rewards handler unavailable" end
			return queueAction("Verified rewards", "rewards:tick", function()
				local claim = rawget(GB.Rewards, "claim")
				local tick = rawget(GB.Rewards, "tick")
				if type(claim) == "function" then return claim() end
				if type(tick) == "function" then
					return withRequiredAuto("AutoRewards", tick)
				end
				return false, "Rewards method unavailable"
			end)
		end),
	}))
	register("Codes", "AutoRewards", codesTab:AddToggle({
		Text = "Auto Verified Rewards (FULL_AUTO only)",
		Description = "Stored for FULL_AUTO only. Use Run Verified Rewards Tick for a one-shot action.",
		Default = UI.autoRewards,
		Callback = guard("Auto Rewards", function(value)
			UI.autoRewards = value == true
			Config.AutoRewards = controllerOwner() == OWNER.FULL_AUTO and UI.autoRewards or false
			return true
		end),
	}))
	codesTab:AddParagraph({
		Title = "Battlepass / Achievements",
		Text = "UNRESOLVED claim arguments. Status-only; no claim action is exposed.",
	})

	autoTab:AddSection("Exclusive Progression Owner")
	register("Auto", "Master", autoTab:AddToggle({
		Text = "FULL_AUTO Master",
		Description = "Assign or release the exclusive FULL_AUTO owner.",
		Default = false,
		Callback = guard("Auto Progress", function(value)
			local ok
			if value == true then
				ok = startOwner(OWNER.FULL_AUTO, "ui_auto_master")
			elseif controllerOwner() == OWNER.FULL_AUTO then
				ok = stopOwner("ui_auto_master_off")
			else
				ok = true
			end
			setControl("Home", "FullAuto", value == true)
			return ok
		end),
	}))
	register("Auto", "Mode", autoTab:AddDropdown({
		Text = "Progress Mode",
		Description = "Stores the profile while stopped/manual; applies its full flag baseline only in FULL_AUTO.",
		Options = { "Story First", "Balanced", "Level Rush", "Manual Requirements" },
		Default = UI.autoMode,
		Callback = guard("Progress Mode", function(value)
			UI.autoMode = value
			if controllerOwner() == OWNER.FULL_AUTO then
				applyAutoModeFlags(value)
				Config.AutoRewards = UI.autoRewards == true
				if GB.Engine and type(GB.Engine.markContextDirty) == "function" then GB.Engine.markContextDirty("ui_mode") end
			end
			return true
		end),
	}))
	register("Auto", "Status", autoTab:AddParagraph({
		Title = "Current Intent / Blocker",
		Text = "FULL_AUTO is IDLE until explicitly enabled.",
	}))
	register("Auto", "ResumeStory", autoTab:AddButton({
		Text = "Resume Story",
		Description = "Enable existing story/level flags and assign FULL_AUTO.",
		Callback = guard("Resume Story", function()
			UI.autoMode = "Story First"
			setControl("Auto", "Mode", UI.autoMode)
			return startOwner(OWNER.FULL_AUTO, "ui_resume_story")
		end),
	}))
	register("Auto", "FarmRequirement", autoTab:AddButton({
		Text = "Farm Current Requirement",
		Description = "Dispatch LEVEL, PREREQUISITE, ITEM, or STAT through real handlers.",
		Callback = guard("Farm Requirement", function()
			local current = stateSnapshot().CurrentQuest
			if not current and GB.PlayerData and type(GB.PlayerData.current) == "function" then
				local ok, value = pcall(GB.PlayerData.current)
				if ok then current = value end
			end
			if not current then return false, "No current quest" end
			local kind, reason, data = describeBlocker(current)
			data = type(data) == "table" and data or {}
			if kind == "LEVEL" then
				local candidates = copyArray(repeatQuests, 64)
				if #candidates == 0 then return false, "No repeatable level quest generated" end
				local required = tonumber(data.Required) or tonumber((questRow(current) or {}).NeedLevel)
				if not required or required < 1 then return false, reason or "Required level unavailable" end
				controllerCall("setSelectedRepeatables", candidates)
				controllerCall("setRepeatMode", "BEST")
				controllerCall("setFarmUntilLevel", required)
				controllerCall("setResumeFullAuto", true)
				return startOwner(OWNER.MANUAL_QUEST, "ui_farm_level_requirement")
			elseif kind == "PREREQUISITE" then
				local prerequisite = data.Prerequisite
				if not prerequisite then return false, reason or "Prerequisite name unavailable" end
				controllerCall("setSelectedQuest", prerequisite)
				return startOwner(OWNER.MANUAL_QUEST, "ui_farm_prerequisite")
			elseif kind == "ITEM" then
				local item = data.Item
				local allowed, method, requiredFlag = itemActionAllowed(item)
				if not allowed then return false, method end
				local spec = itemSpec(item) or {}
				return queueAction("Requirement item: " .. item, "auto:requirement:item", function()
					return runItemAcquire(item, 1, {
						Quest = current, Method = method,
						Source = spec.source or spec.Source,
						Location = spec.location or spec.Location,
					}, requiredFlag)
				end)
			elseif kind == "STAT" then
				if not (data.Stat and GB.Stats and type(GB.Stats.Invest) == "function") then return false, reason or "Stat handler unavailable" end
				return queueAction("Requirement stat: " .. data.Stat, "auto:requirement:stat", function()
					return GB.Stats.Invest(data.Stat, 1)
				end)
			end
			return false, reason or "Requirement is UNKNOWN"
		end),
	}))
	register("Auto", "Replan", autoTab:AddButton({
		Text = "Replan",
		Description = "Run Planner.Replan and mark the current Engine context dirty.",
		Callback = guard("Replan", function()
			return queueAction("Replan progression", "auto:replan", function()
				local result
				if GB.Planner and type(GB.Planner.Replan) == "function" then result = GB.Planner.Replan() end
				if GB.Engine and type(GB.Engine.markContextDirty) == "function" then GB.Engine.markContextDirty("ui_replan") end
				return result ~= false
			end)
		end),
	}))
	register("Auto", "Stop", autoTab:AddButton({
		Text = "Stop Auto Progress",
		Callback = guard("Stop Auto Progress", function()
			setControl("Auto", "Master", false)
			return stopOwner("ui_auto_stop")
		end),
	}))

	settingsTab:AddSection("UI Configuration")
	register("Settings", "Status", settingsTab:AddParagraph({
		Title = "GBKaitun/UIConfig.json",
		Text = M._configStatus,
	}))
	register("Settings", "ResumeActions", settingsTab:AddToggle({
		Text = "Resume Actions on Load",
		Description = "Default false. A saved owner starts only when this explicit value is true.",
		Default = false,
		Callback = guard("Resume Actions", function(value)
			UI.resumeActions = value == true
			return true
		end),
	}))
	register("Settings", "Save", settingsTab:AddButton({
		Text = "Save Config",
		Description = "Save only the bounded UI schema; UI source is never stored.",
		Callback = guard("Save Config", function() return M.SaveConfig() end),
	}))
	register("Settings", "Load", settingsTab:AddButton({
		Text = "Load Config",
		Description = "Load and sanitize the bounded schema.",
		Callback = guard("Load Config", function() return M.LoadConfig() end),
	}))
	register("Settings", "Reset", settingsTab:AddButton({
		Text = "Reset Config",
		Description = "Restore safe UI defaults and IDLE owner.",
		Callback = guard("Reset Config", function() return M.ResetConfig() end),
	}))
	settingsTab:AddSection("Mirrored Runtime Settings")
	register("Settings", "CombatRange", settingsTab:AddSlider({
		Text = "Combat Range",
		Min = 2, Max = 30, Increment = 0.5, Default = UI.combatRange, Suffix = " studs",
		Callback = guard("Combat Range", function(value)
			UI.combatRange = clampNumber(value, 2, 30, 5.5)
			Config.CombatRange = UI.combatRange
			setControl("Mobs", "CombatRange", UI.combatRange)
			return controllerCall("setCombatRange", UI.combatRange)
		end),
	}))
	register("Settings", "TweenSpeed", settingsTab:AddSlider({
		Text = "Tween Speed",
		Min = 20, Max = 300, Increment = 5, Default = UI.tweenSpeed, Suffix = " studs/s",
		Callback = guard("Tween Speed", function(value)
			UI.tweenSpeed = clampNumber(value, 20, 300, 95)
			Config.TweenSpeed = UI.tweenSpeed
			setControl("Mobs", "TweenSpeed", UI.tweenSpeed)
			return true
		end),
	}))
	register("Settings", "Stickiness", settingsTab:AddSlider({
		Text = "Target Stickiness",
		Min = 0, Max = 30, Increment = 0.5, Default = UI.stickiness, Suffix = "s",
		Callback = guard("Target Stickiness", function(value)
			UI.stickiness = clampNumber(value, 0, 30, 2)
			Config.TargetStickiness = UI.stickiness
			Controller.targetStickiness = UI.stickiness
			setControl("Mobs", "Stickiness", UI.stickiness)
			return true
		end),
	}))
	register("Settings", "SwitchDistance", settingsTab:AddSlider({
		Text = "Target Switch Distance",
		Min = 10, Max = 300, Increment = 5, Default = UI.switchDistance, Suffix = " studs",
		Callback = guard("Target Switch Distance", function(value)
			UI.switchDistance = clampNumber(value, 10, 300, 55)
			Config.TargetSwitchDistance = UI.switchDistance
			setControl("Mobs", "SwitchDistance", UI.switchDistance)
			return controllerCall("setTargetSwitchDistance", UI.switchDistance)
		end),
	}))
	settingsTab:AddParagraph({
		Title = "Persistence Policy",
		Text = "Selections, modes, target level, ranges, stat ratios, and bounded toggles only. Owner restoration requires Resume Actions on Load.",
	})

	debugTab:AddSection("Low-Rate Runtime Diagnostics")
	register("Debug", "Status", debugTab:AddParagraph({ Title = "Runtime", Text = "Waiting for the low-rate diagnostic refresh." }))
	register("Debug", "SelfCheck", debugTab:AddButton({
		Text = "Self Check",
		Callback = guard("Self Check", function()
			if type(GB.SelfCheck) ~= "function" then return false, "SelfCheck unavailable" end
			return queueAction("Debug self check", "debug:self_check", function()
				local result = GB.SelfCheck()
				setControl("Debug", "Result", resultText(result))
				return true
			end, { cancelActive = false })
		end),
	}))
	register("Debug", "Dump", debugTab:AddButton({
		Text = "Dump Runtime Issue",
		Description = "Call the current bounded diagnostic dump.",
		Callback = guard("Runtime Dump", function()
			if type(GB.DumpRuntimeIssue) ~= "function" then return false, "DumpRuntimeIssue unavailable" end
			return queueAction("Dump runtime issue", "debug:dump", function()
				local result = GB.DumpRuntimeIssue()
				setControl("Debug", "Result", resultText(result))
				return true
			end, { cancelActive = false })
		end),
	}))
	local refreshIndexMethod = GB.Resolver and (
		type(rawget(GB.Resolver, "refreshIndexes")) == "function" and rawget(GB.Resolver, "refreshIndexes")
		or type(rawget(GB.Resolver, "RefreshIndexes")) == "function" and rawget(GB.Resolver, "RefreshIndexes")
	)
	if refreshIndexMethod then
		register("Debug", "RefreshIndexes", debugTab:AddButton({
			Text = "Refresh Indexes",
			Description = "Exact Resolver refresh method detected.",
			Callback = guard("Refresh Indexes", function()
				return queueAction("Refresh resolver indexes", "debug:indexes", function() return refreshIndexMethod() end, {
					cancelActive = false,
				})
			end),
		}))
	else
		debugTab:AddParagraph({
			Title = "Resolver Index Refresh",
			Text = "No exact refresh method exists. Existing event-driven shallow indexes remain active; no deep scan is run.",
		})
	end
	register("Debug", "ClearIntent", debugTab:AddButton({
		Text = "Clear Current Intent",
		Description = "Return UIController to IDLE and dirty the Engine context.",
		Callback = guard("Clear Intent", function()
			local ok, detail = stopOwner("ui_clear_intent")
			if GB.Engine then
				GB.Engine.intent = nil
				if type(GB.Engine.markContextDirty) == "function" then GB.Engine.markContextDirty("ui_clear_intent") end
			end
			return ok, detail
		end),
	}))
	register("Debug", "Result", debugTab:AddParagraph({ Title = "Diagnostic Result", Text = "No diagnostic action run." }))
	debugTab:AddParagraph({
		Title = "Unresolved Debug Targets",
		Text = "Arm wrestling and unsupported minigame payloads remain status-only.",
	})

	local function formatObjective(state)
		local objective = state and state.Objective
		if not objective then
			return state and state.CanTurnIn and "TURN-IN READY" or "No unfinished objective"
		end
		return string.format(
			"%s %s %s/%s",
			tostring(objective.Type or "Objective"),
			tostring(objective.TargetName or ""),
			tostring(objective.Current or 0),
			tostring(objective.Amount or 1)
		)
	end

	local function conditionText(condition)
		if type(condition) ~= "table" then return tostring(condition) end
		local typ = condition.Type or condition.type or "Condition"
		local target
		if GB.QuestData and type(GB.QuestData.conditionTarget) == "function" then
			local ok, value = pcall(GB.QuestData.conditionTarget, condition)
			if ok then target = value end
		end
		target = target or condition.TargetName or condition.Name or ""
		local current, amount
		if GB.QuestData and type(GB.QuestData.conditionCurrent) == "function" then
			local ok, value = pcall(GB.QuestData.conditionCurrent, condition)
			if ok then current = value end
		end
		if GB.QuestData and type(GB.QuestData.conditionAmount) == "function" then
			local ok, value = pcall(GB.QuestData.conditionAmount, condition)
			if ok then amount = value end
		end
		current = current or condition.Current or condition.Amount or 0
		amount = amount or condition.RequiredAmount or condition.Total or 1
		return string.format("%s %s %s/%s", tostring(typ), tostring(target), tostring(current), tostring(amount))
	end

	updateQuestDetails = function()
		local name = UI.detailQuest
		local row = questRow(name)
		if not (name and row) then
			setControl("Quests", "Details", "Select a generated quest.")
			setControl("Quests", "Blocker", "UNKNOWN: no quest selected")
			return
		end
		local state = questState(name)
		local status, statusReason = questStatus(name)
		local lines = {
			"Name: " .. name,
			"Island: " .. tostring(row.Island or (state and state.Island) or "UNKNOWN"),
			string.format("Level: accept %s | range %s-%s | required %s",
				tostring(row.AcceptLevel or 0), tostring(row.RangeMin or "?"), tostring(row.RangeMax or "?"), tostring(row.NeedLevel or 0)),
			"Accept: " .. tostring(row.AcceptNPC or "UNKNOWN") .. " via " .. tostring(row.Start or "UNKNOWN"),
			"Turn-in: " .. tostring(row.TurnInNPC or "UNKNOWN"),
			"Prerequisites: " .. join(row.Prerequisites, ", ", "None"),
			string.format("Rewards: EXP %s | Gold %s | Unlocks %s", tostring(row.Exp or 0), tostring(row.Gold or 0), tostring(row.Unlocks or "None")),
			"Runtime: " .. tostring(status) .. (statusReason and (" - " .. tostring(statusReason)) or ""),
			"Current: " .. formatObjective(state),
			"Stages:",
		}
		for _, stage in ipairs(stagesByQuest[name] or {}) do
			lines[#lines + 1] = string.format(
				"  %s. %s %s x%s | %s | %s",
				tostring(stage.index), tostring(stage.objective), tostring(stage.target or ""),
				tostring(stage.amount or 0), tostring(stage.handler or "UNKNOWN"), tostring(stage.status or "UNKNOWN")
			)
		end
		if #(stagesByQuest[name] or {}) == 0 then lines[#lines + 1] = "  No generated stages" end
		setControl("Quests", "Details", table.concat(lines, "\n"))
		local kind, reason = describeBlocker(name)
		if kind then
			setControl("Quests", "Blocker", tostring(kind) .. ": " .. tostring(reason or "No detail"))
		else
			setControl("Quests", "Blocker", "READY: no LEVEL, PREREQUISITE, ITEM, STAT, or UNKNOWN blocker detected")
		end
	end

	updateActiveQuestDetails = function()
		local name = UI.activeQuest
		if not name then
			setControl("Quests", "ActiveDetails", "No active quest selected.")
			return
		end
		local state = questState(name)
		local unfinished = {}
		if GB.Quest and type(GB.Quest.unfinishedConditions) == "function" then
			local ok, values = pcall(GB.Quest.unfinishedConditions, name)
			if ok and type(values) == "table" then unfinished = values end
		end
		local lines = {
			"Quest: " .. name,
			"Stage: " .. tostring(state and state.StageIndex or "UNKNOWN"),
			"Accepted: " .. tostring(state and state.IsAccepted == true),
			"Turn-in ready: " .. tostring(state and state.CanTurnIn == true),
			"Objective: " .. formatObjective(state),
			"Unfinished conditions:",
		}
		for _, condition in ipairs(unfinished) do lines[#lines + 1] = "  " .. conditionText(condition) end
		if #unfinished == 0 then lines[#lines + 1] = "  None" end
		local kind, reason = describeBlocker(name)
		lines[#lines + 1] = "Blocker: " .. (kind and (tostring(kind) .. " - " .. tostring(reason)) or "None")
		setControl("Quests", "ActiveDetails", table.concat(lines, "\n"))
	end

	updateStoppedStatus = function()
		setControl("Home", "Status", table.concat({
			"Runtime: STOPPED",
			"Scheduler: STOPPED",
			"Owner: IDLE",
			"UI autos and queues are quiesced.",
			"Use Full Auto or Resume to restart. Refresh remains available on demand.",
		}, "\n"))
		setControl("Auto", "Status", table.concat({
			"Owner: IDLE | STOPPED",
			"Mode stored: " .. tostring(UI.autoMode),
			"No progression, movement, combat, or utility work is running.",
		}, "\n"))
		if M.Window and type(M.Window.SetTitle) == "function" then
			pcall(M.Window.SetTitle, M.Window, "Grand Blue Kaitun", "IDLE | STOPPED")
		end
	end

	updateHome = function()
		local state = stateSnapshot()
		local control = controllerSnapshot()
		local engine = GB.Engine or {}
		local player = GB.lp or Players.LocalPlayer
		local active = activeQuestNames(false)
		local questLines = {}
		for _, name in ipairs(active) do
			local quest = questState(name)
			questLines[#questLines + 1] = "  " .. name .. " | stage " .. tostring(quest and quest.StageIndex or "?") .. " | " .. formatObjective(quest)
		end
		if #questLines == 0 then questLines[1] = "  None" end
		local moving = false
		if GB.World and type(GB.World.tweenPlaying) == "function" then
			local ok, value = pcall(GB.World.tweenPlaying)
			moving = ok and value == true
		end
		local combatTarget = GB.Combat and GB.Combat.lockMob
		local combatName = combatTarget and (instanceName(combatTarget) or tostring(combatTarget)) or "None"
		local intent = engine.intent
		local intentText = type(intent) == "table" and (tostring(intent.Kind or "?") .. " -> " .. tostring(intent.Target or "None")) or tostring(intent or "None")
		local lines = {
			"User: " .. tostring(player and player.Name or "UNKNOWN"),
			string.format("Level %s | EXP %s | Gold %s | Island %s (physical %s)",
				tostring(state.Level or 0), tostring(state.Exp or state.EXP or 0), tostring(state.Gold or 0),
				tostring(state.CurrentIsland or "UNKNOWN"), tostring(state.PhysicalIsland or "UNKNOWN")),
			"Active quests:",
			table.concat(questLines, "\n"),
			string.format("Owner %s | Controller %s | %s | queued %s",
				tostring(control.owner or OWNER.IDLE), control.paused and "PAUSED" or "RUNNING",
				tostring(control.status or "IDLE"), tostring(control.queued or 0)),
			"Reason: " .. tostring(control.statusReason or engine.idleReason or "None"),
			"Intent: " .. intentText,
			"Farm session: " .. tostring(engine.farmSession or "None"),
			"Selections: quest=" .. tostring(Controller.selectedQuest or "None")
				.. " | mobs=" .. join(Controller.selectedMobs, ",", "None")
				.. " | bosses=" .. join(Controller.selectedBosses, ",", "None"),
			"Movement: " .. (moving and "ACTIVE" or "IDLE") .. " | Combat: " .. combatName,
			"Stat points: " .. tostring(state.StatPoints or 0),
			string.format(
				"Core %s | UI %s | Build %s | Generated %s",
				tostring(GB.Version or "unknown"),
				tostring(GB.UIVersion or "unknown"),
				tostring(GB.Build or "unknown"),
				tostring(Generated.Version or "unknown")
			),
		}
		setControl("Home", "Status", table.concat(lines, "\n"))
		if M.Window and type(M.Window.SetTitle) == "function" then
			pcall(M.Window.SetTitle, M.Window, "Grand Blue Kaitun", tostring(control.owner or OWNER.IDLE) .. " | " .. tostring(control.status or "IDLE"))
		end
	end

	updateMobStatus = function()
		local snapshot = stateSnapshot()
		local lines = {
			"Mode: " .. tostring(UI.mobMode),
			"Selected: " .. tostring(#UI.mobs),
		}
		for _, name in ipairs(UI.mobs) do
			local count, nearest = 0, nil
			for _, enemy in ipairs(enemiesFor(name)) do
				if enemyAlive(enemy) then
					count = count + 1
					local distance = enemyDistance(enemy, snapshot)
					if distance and (not nearest or distance < nearest) then nearest = distance end
				end
			end
			lines[#lines + 1] = string.format("%s: alive %d | nearest %s", name, count, nearest and string.format("%.1f", nearest) or "UNKNOWN")
		end
		if #UI.mobs == 0 then lines[#lines + 1] = "No targets selected." end
		local control = controllerSnapshot()
		lines[#lines + 1] = "Controller: " .. tostring(control.owner) .. " / " .. tostring(control.status)
		setControl("Mobs", "Status", table.concat(lines, "\n"))
	end

	updateBossDetails = function()
		local name = UI.bossFocus
		if not name then setControl("Bosses", "Details", "No data-derived boss selected.") return end
		local evidence = bossMap[name] or {}
		local alive, nearest = 0, nil
		local snapshot = stateSnapshot()
		for _, enemy in ipairs(enemiesFor(name)) do
			if enemyAlive(enemy) then
				alive = alive + 1
				local distance = enemyDistance(enemy, snapshot)
				if distance and (not nearest or distance < nearest) then nearest = distance end
			end
		end
		setControl("Bosses", "Details", table.concat({
			"Target: " .. name,
			"Alive: " .. tostring(alive) .. " | Distance: " .. (nearest and string.format("%.1f", nearest) or "UNKNOWN"),
			"Evidence: Defeat " .. tostring(evidence.defeat or 0) .. " | BossDrop " .. tostring(evidence.bossDrop or 0)
				.. " | Known mapping " .. tostring(evidence.known == true),
			"Related quests: " .. join(evidence.quests, ", ", "None"),
			"Drops: " .. join(evidence.drops, ", ", "None generated"),
			"Island: " .. join(evidence.islands, ", ", "UNKNOWN"),
			"Markers: " .. join(evidence.markers, ", ", "UNKNOWN"),
			"Respawn: UNKNOWN (no timer is inferred)",
			"Controller: " .. tostring(Controller.status or "IDLE"),
		}, "\n"))
	end

	updateNpcDetails = function()
		local name = UI.npc
		setControl("Teleport", "NPCDetails", table.concat({
			"NPC: " .. tostring(name or "None"),
			"Island: " .. tostring(name and primaryNpcIsland(name) or "UNKNOWN"),
			"Related quests: " .. join(name and npcRelatedQuests(name) or {}, ", ", "None"),
		}, "\n"))
	end

	updateItemDetails = function()
		local name = UI.item
		if not name then setControl("Items", "Details", "No item selected.") return end
		local spec = itemSpec(name) or {}
		local generated = Generated.Items and Generated.Items[name] or {}
		local owned, amount = inventoryCount(name)
		local allowed, action = itemActionAllowed(name)
		setControl("Items", "Details", table.concat({
			"Item: " .. name,
			"Owned: " .. tostring(owned) .. " x" .. tostring(amount),
			"Method: " .. tostring(spec.method or spec.Method or generated.Method or "UNKNOWN"),
			"Source: " .. tostring(spec.source or spec.Source or generated.Source or "UNKNOWN"),
			"Location: " .. tostring(spec.location or spec.Location or generated.Location or "UNKNOWN"),
			"Policy: " .. tostring(generated.Policy or (GB.ItemData and GB.ItemData.kind and GB.ItemData.kind(name)) or "UNKNOWN"),
			"Catalog category: " .. tostring(Catalog.categoryOf and Catalog.categoryOf(name) or "UNKNOWN"),
			"Quest use: " .. join(generated.QuestUse, ", ", "None generated"),
			"Stage status: " .. tostring(itemStageStatus[name] or "UNKNOWN"),
			"Action: " .. (allowed and ("AVAILABLE via " .. tostring(action)) or ("DISABLED - " .. tostring(action))),
			"Completion: ownership or quest credit only; navigation/hunting alone is not acquisition.",
		}, "\n"))
	end

	updateEquipmentDetails = function()
		local name = UI.equipment
		if not name then setControl("Equipment", "Details", "No owned equipment selected.") return end
		local state
		if GB.Equipment and type(GB.Equipment.equipmentState) == "function" then
			local ok, value = pcall(GB.Equipment.equipmentState, name)
			if ok then state = value end
		end
		state = type(state) == "table" and state or {}
		setControl("Equipment", "Details", table.concat({
			"Item: " .. name,
			"Owned: " .. tostring(state.Owned == true) .. " x" .. tostring(state.Amount or 0),
			"Equipped: " .. tostring(state.Equipped == true),
			"Held: " .. tostring(state.Held == true),
			"Quest credited: " .. tostring(state.QuestCredited == true),
			"Catalog category: " .. tostring(Catalog.categoryOf and Catalog.categoryOf(name) or "UNKNOWN"),
			"Upgrade support: " .. (upgradeTargets[name] and "GENERATED" or "UNRESOLVED"),
			"Preferred: " .. tostring(UI.preferredEquipment or "None"),
		}, "\n"))
	end

	updateSkillDetails = function()
		local name = UI.skill
		local row = name and Generated.Skills and Generated.Skills[name] or nil
		local owned, equipped = false, false
		if name and GB.PlayerData and type(GB.PlayerData.skillOwned) == "function" then
			local ok, first, second = pcall(GB.PlayerData.skillOwned, name)
			if ok then owned, equipped = first == true, second == true end
		end
		setControl("Skills", "Details", table.concat({
			"Skill: " .. tostring(name or "None"),
			"Owned: " .. tostring(owned) .. " | Equipped: " .. tostring(equipped),
			"Kinds: " .. join(row and row.Kinds, ", ", "UNKNOWN"),
			"Island: " .. tostring(row and row.Island or "UNKNOWN"),
			"Linked quests: " .. join(row and row.Quests, ", ", "None"),
			"Linked progress: " .. tostring(UI.linkedQuest and formatObjective(questState(UI.linkedQuest)) or "No link selected"),
		}, "\n"))
	end

	updateStatsStatus = function()
		local state = stateSnapshot()
		if GB.Stats and type(GB.Stats.ReadStatState) == "function" then
			local ok, value = pcall(GB.Stats.ReadStatState)
			if ok and type(value) == "table" then state = value end
		end
		local status, reason = "UNKNOWN", nil
		if GB.Stats and type(GB.Stats.status) == "function" then
			local ok, first, second = pcall(GB.Stats.status)
			if ok then status, reason = first, second end
		end
		local lines = {
			"Unused: " .. tostring(state.Unused or state.StatPoints or 0),
			"Source: " .. tostring(state.Source or state.StatSource or "UNKNOWN"),
		}
		for _, stat in ipairs(STAT_NAMES) do
			lines[#lines + 1] = string.format("%s: %s | weight %s", stat, tostring(state[stat] or (state.Stats and state.Stats[stat]) or 0), tostring(Config.StatRatio and Config.StatRatio[stat] or 0))
		end
		lines[#lines + 1] = "Runtime status: " .. tostring(status) .. (reason and (" - " .. tostring(reason)) or "")
		setControl("Stats", "Status", table.concat(lines, "\n"))
	end

	updateLifeStatus = function()
		local rows = {
			"Mining selected: " .. join(UI.mining, ", ", "None"),
			"Auto mining: " .. tostring(UI.autoMining),
			"Mining handler: " .. (GB.LifeSkills and type(GB.LifeSkills.mineToward) == "function" and "AVAILABLE" or "UNAVAILABLE"),
			"Smelt Copper Bar: " .. (GB.LifeSkills and type(GB.LifeSkills.smeltToward) == "function" and "VERIFIED ROUTE" or "UNAVAILABLE"),
			"Fishing: PARTIAL | Farming: PARTIAL | Cooking: PARTIAL",
			string.format(
				"Static catalogs: ores %d | fish %d | rods %d | pickaxes %d (names only)",
				type(Catalog.Ores) == "table" and #Catalog.Ores or 0,
				type(Catalog.Fish) == "table" and #Catalog.Fish or 0,
				type(Catalog.FishingRods) == "table" and #Catalog.FishingRods or 0,
				type(Catalog.Pickaxes) == "table" and #Catalog.Pickaxes or 0
			),
			"General craft/dig: UNRESOLVED",
		}
		setControl("LifeSkills", "Status", table.concat(rows, "\n"))
	end

	local function tableNames(source)
		local out, seen = {}, {}
		if type(source) == "table" then
			for key, value in pairs(source) do
				if type(key) == "string" then addUnique(out, seen, key) end
				if type(value) == "string" then
					addUnique(out, seen, value)
				elseif type(value) == "table" then
					addUnique(out, seen, value.Name or value.name or value.Value)
				end
			end
		end
		return sortStrings(out)
	end

	updateFruitStatus = function()
		local state = stateSnapshot()
		local stored = tableNames(state.StoredFruits)
		local permanent = tableNames(state.PermanentFruits)
		setControl("Fruit", "Status", table.concat({
			"Current: " .. tostring(state.Fruit or "None"),
			"Stored: " .. join(stored, ", ", "None"),
			"Permanent: " .. join(permanent, ", ", "None"),
			"Desired: " .. join(Config.DesiredFruits, ", ", "None"),
			"Selected: " .. tostring(UI.fruit or "None"),
			"Mode: " .. tostring(Config.FruitMode or "KEEP_CURRENT"),
			"Eat/replace: DISABLED",
		}, "\n"))
	end

	updateHakiStatus = function()
		local state = stateSnapshot()
		setControl("Haki", "Status", table.concat({
			"Haki: " .. tostring(state.Haki or "UNKNOWN"),
			"Race: " .. tostring(state.Race or "UNKNOWN"),
			"Trait: " .. (type(state.Trait) == "table" and resultText(state.Trait) or tostring(state.Trait or "UNKNOWN")),
			"Haki trainer/unlock: UNRESOLVED",
			"Race reroll: UNRESOLVED",
			"Aura method: " .. (auraMethod and "AVAILABLE" or "UNAVAILABLE"),
			"Trait method: " .. (traitMethod and "AVAILABLE" or "UNAVAILABLE"),
		}, "\n"))
	end

	updateShopStatus = function()
		local name = UI.shop
		local price
		if name and GB.ItemData and type(GB.ItemData.shopPrice) == "function" then
			local ok, value = pcall(GB.ItemData.shopPrice, name)
			if ok then price = value end
		end
		price = price or (Generated.Shops and Generated.Shops[name])
		local owned, amount = inventoryCount(name)
		local gold = stateSnapshot().Gold or 0
		local total = price and price * UI.shopQuantity or nil
		setControl("Shop", "Status", table.concat({
			"Item: " .. tostring(name or "None"),
			"Unit price: " .. tostring(price or "UNKNOWN"),
			"Quantity: " .. tostring(UI.shopQuantity),
			"Total: " .. tostring(total or "UNKNOWN"),
			"Gold: " .. tostring(gold),
			"Affordable: " .. tostring(total and gold >= total or false),
			"Owned: " .. tostring(owned) .. " x" .. tostring(amount),
		}, "\n"))
	end

	updateChestStatus = function()
		local snapshot = controllerSnapshot()
		local maps = {}
		for _, row in ipairs(inventoryRows()) do
			if type(row.name) == "string" and string.find(string.lower(row.name), "treasure map", 1, true) then
				maps[#maps + 1] = row.name .. " x" .. tostring(row.amount or 1)
			end
		end
		sortStrings(maps)
		setControl("Chest", "Status", table.concat({
			"Selected map: " .. tostring(UI.chestMap),
			"Physical map: " .. tostring(stateSnapshot().PhysicalIsland or "UNKNOWN"),
			"Owner: " .. tostring(snapshot.owner),
			"Status: " .. tostring(snapshot.status) .. " - " .. tostring(snapshot.statusReason or ""),
			"Opened this route: " .. tostring(snapshot.progress and snapshot.progress.current or 0),
			"Indexed routing: one chest per step",
			"Dig: UNRESOLVED",
		}, "\n"))
		setControl("Chest", "Maps", join(maps, "\n", "No treasure maps in cached inventory."))
	end

	updateCodeStatus = function()
		if M._codesQueueProgress and GB.Codes.running ~= true and not GB.Codes.pendingCode then
			M._codesQueueProgress = nil
			Config.AutoCodes = false
			controllerCall("setUtilityAuto", "AutoCodes", false)
		end
		local states = GB.Persist and GB.Persist.data and GB.Persist.data.codes or {}
		local counts = { SUCCESS = 0, ALREADY_USED = 0, INVALID = 0, EXPIRED = 0, ERROR = 0, UNKNOWN = 0 }
		local lines = {}
		for _, code in ipairs(knownCodes) do
			local row = type(states) == "table" and states[code] or nil
			local status = type(row) == "table" and row.state or "UNKNOWN"
			counts[status] = (counts[status] or 0) + 1
			lines[#lines + 1] = code .. ": " .. tostring(status)
		end
		lines[#lines + 1] = string.format(
			"Summary: success %d | used %d | invalid %d | expired %d | error %d | pending %d",
			counts.SUCCESS or 0, counts.ALREADY_USED or 0, counts.INVALID or 0,
			counts.EXPIRED or 0, counts.ERROR or 0, counts.UNKNOWN or 0
		)
		if UI._lastCodeResult then lines[#lines + 1] = "Last: " .. UI._lastCodeResult end
		local queue = GB.Codes and GB.Codes.queue
		if GB.Codes and GB.Codes.running and type(queue) == "table" then
			local remaining = math.max(0, #queue - (tonumber(GB.Codes._queueIndex) or 1) + 1)
			lines[#lines + 1] = "Queue remaining: " .. tostring(remaining)
		end
		if GB.Codes and GB.Codes.pendingCode then lines[#lines + 1] = "Pending: " .. tostring(GB.Codes.pendingCode) end
		setControl("Codes", "Status", table.concat(lines, "\n"))
	end

	updateAutoStatus = function()
		local state = stateSnapshot()
		local control = controllerSnapshot()
		local engine = GB.Engine or {}
		local current = state.CurrentQuest
		local kind, reason = describeBlocker(current)
		local intent = engine.intent
		local intentText = type(intent) == "table" and (tostring(intent.Kind) .. " -> " .. tostring(intent.Target)) or tostring(intent or "None")
		setControl("Auto", "Status", table.concat({
			"Owner: " .. tostring(control.owner) .. " | " .. tostring(control.status),
			"Mode: " .. tostring(UI.autoMode),
			"Intent: " .. intentText,
			"Engine task: " .. tostring(engine.task or "None"),
			"Idle reason: " .. tostring(engine.idleReason or "None"),
			"Current quest: " .. tostring(current or "None"),
			"Blocker: " .. (kind and (tostring(kind) .. " - " .. tostring(reason)) or "None"),
			"Last progress: " .. tostring(engine._lastRealProgressWhy or "UNKNOWN"),
		}, "\n"))
	end

	local equipmentTargets = {}
	for _, rows in pairs(stagesByQuest) do
		for _, stage in ipairs(rows) do
			if stage.objective == "Equip" or stage.objective == "Upgrade" then equipmentTargets[stage.target] = true end
		end
	end

	refreshDynamicOptions = function(includeEnemySnapshot)
		local inventory = inventoryRows()
		local items, itemSeen = copyArray(baseItemNames, 1000), {}
		for _, name in ipairs(items) do itemSeen[string.lower(name)] = true end
		local equipment, equipmentSeen, inventoryText = {}, {}, {}
		for _, row in ipairs(inventory) do
			local name = trim(row.name)
			if name then
				addUnique(items, itemSeen, name)
				inventoryText[#inventoryText + 1] = name .. " x" .. tostring(row.amount or 1)
				local kind = "UNKNOWN"
				if GB.ItemData and type(GB.ItemData.kind) == "function" then
					local ok, value = pcall(GB.ItemData.kind, name)
					if ok then kind = value end
				end
				local supported = kind == "EQUIP" or equipmentTargets[name] == true
				if not supported and type(Catalog.isEquipment) == "function" then
					supported = Catalog.isEquipment(name) == true
				end
				if not supported and GB.Equipment and type(GB.Equipment.needsGearSlot) == "function" then
					local ok, value = pcall(GB.Equipment.needsGearSlot, name)
					supported = ok and value == true
				end
				if supported then addUnique(equipment, equipmentSeen, name) end
			end
		end
		sortStrings(items)
		sortStrings(equipment)
		sortStrings(inventoryText)
		if UI.item and not contains(items, UI.item) then UI.item = items[1] end
		if UI.equipment and not contains(equipment, UI.equipment) then UI.equipment = equipment[1] end
		if not UI.equipment then UI.equipment = equipment[1] end
		if UI.preferredEquipment and not contains(equipment, UI.preferredEquipment) then UI.preferredEquipment = nil end
		if not UI.preferredEquipment then UI.preferredEquipment = equipment[1] end
		setOptions("Items", "Item", items, UI.item)
		setControl("Items", "Inventory", join(inventoryText, "\n", "Inventory cache is empty."))
		setOptions("Equipment", "Owned", equipment, UI.equipment)
		setOptions("Equipment", "Preferred", equipment, UI.preferredEquipment)

		local skills, skillSeen = copyArray(baseSkillNames, 1000), {}
		for _, name in ipairs(skills) do skillSeen[string.lower(name)] = true end
		local snapshot = stateSnapshot()
		for name, row in pairs(type(snapshot.Skills) == "table" and snapshot.Skills or {}) do
			if type(name) == "string" then addUnique(skills, skillSeen, name) end
			if type(row) == "table" then addUnique(skills, skillSeen, row.Name or row.name) end
		end
		sortStrings(skills)
		if UI.skill and not contains(skills, UI.skill) then UI.skill = skills[1] end
		setOptions("Skills", "Skill", skills, UI.skill)
		local skillRow = UI.skill and Generated.Skills and Generated.Skills[UI.skill]
		local links = type(skillRow) == "table" and skillRow.Quests or {}
		if UI.linkedQuest and not contains(links, UI.linkedQuest) then UI.linkedQuest = nil end
		UI.linkedQuest = UI.linkedQuest or links[1]
		setOptions("Skills", "LinkedQuest", links, UI.linkedQuest)

		local fruits, liveFruitSeen = copyArray(fruitNames, 1000), {}
		for _, name in ipairs(fruits) do liveFruitSeen[string.lower(name)] = true end
		addUnique(fruits, liveFruitSeen, type(snapshot.Fruit) == "string" and snapshot.Fruit or nil)
		for _, source in ipairs({ snapshot.StoredFruits, snapshot.PermanentFruits }) do
			for _, name in ipairs(tableNames(source)) do addUnique(fruits, liveFruitSeen, name) end
		end
		sortStrings(fruits)
		if UI.fruit and not contains(fruits, UI.fruit) then UI.fruit = fruits[1] end
		setOptions("Fruit", "Catalog", fruits, UI.fruit)

		local active = activeQuestNames(true)
		sortStrings(active)
		if UI.activeQuest and not contains(active, UI.activeQuest) then UI.activeQuest = nil end
		UI.activeQuest = UI.activeQuest or active[1]
		setOptions("Quests", "Active", active, UI.activeQuest)
		local completed = completedQuestNames()
		if UI.completedQuest and not contains(completed, UI.completedQuest) then UI.completedQuest = nil end
		UI.completedQuest = UI.completedQuest or completed[1]
		setOptions("Quests", "Completed", completed, UI.completedQuest)
		setControl(
			"Quests",
			"CompletedStatus",
			string.format("%d completed / %d known quests", #completed, #allQuests)
		)

		if includeEnemySnapshot and GB.Resolver and type(GB.Resolver.enemySnapshot) == "function" then
			local ok, values = pcall(GB.Resolver.enemySnapshot)
			if ok and type(values) == "table" then
				for key, value in pairs(values) do
					if type(key) == "string" then addUnique(mobNames, mobSet, key) end
					if type(value) == "string" then
						addUnique(mobNames, mobSet, value)
					elseif typeof(value) == "Instance" then
						addUnique(mobNames, mobSet, instanceName(value))
					elseif type(value) == "table" then
						addUnique(mobNames, mobSet, value.Name or value.name or value.DisplayName)
						addUnique(mobNames, mobSet, instanceName(value.Instance))
					end
				end
				sortStrings(mobNames)
			end
		end
		local validMobs = {}
		for _, name in ipairs(UI.mobs) do if contains(mobNames, name) then validMobs[#validMobs + 1] = name end end
		UI.mobs = validMobs
		setOptions("Mobs", "Targets", mobNames, UI.mobs)

		updateQuestDetails()
		updateActiveQuestDetails()
		updateNpcDetails()
		updateItemDetails()
		updateEquipmentDetails()
		updateSkillDetails()
		updateFruitStatus()
	end

	updateDebugStatus = function()
		local now = os.clock()
		local control = controllerSnapshot()
		local engine = GB.Engine or {}
		local cache = GB.Cache and type(GB.Cache.stats) == "function" and GB.Cache.stats() or {}
		local pending = GB.Broker and type(GB.Broker.pendingNames) == "function" and GB.Broker.pendingNames() or {}
		sortStrings(pending)
		local questAge = GB.PlayerData and GB.PlayerData._lastQuestFetchAt and now - GB.PlayerData._lastQuestFetchAt or nil
		local statAge = GB.PlayerData and GB.PlayerData._statsAt and now - GB.PlayerData._statsAt or nil
		local resolverMiss = 0
		if GB.Profiler and GB.Profiler.counters and GB.Profiler.counters.ResolverMiss then
			resolverMiss = tonumber(GB.Profiler.counters.ResolverMiss.total) or 0
		end
		local dummyMiss = 0
		if GB.Resolver and type(GB.Resolver.dummyMissCount) == "function" then
			local ok, value = pcall(GB.Resolver.dummyMissCount)
			if ok then dummyMiss = tonumber(value) or 0 end
		end
		local worstName, worstMs = "None", 0
		for name, row in pairs(GB.Profiler and GB.Profiler.metrics or {}) do
			local maximum = tonumber(row.max) or 0
			if maximum > worstMs then worstName, worstMs = name, maximum end
		end
		local moving = false
		if GB.World and type(GB.World.tweenPlaying) == "function" then
			local ok, value = pcall(GB.World.tweenPlaying)
			moving = ok and value == true
		end
		local sourceCount, sourceBase = 0, 0
		pcall(function()
			sourceCount = tonumber(getgenv()._GBSourceHttpCount) or 0
			sourceBase = tonumber(getgenv()._GBSourceHttpBase) or tonumber(GB._sourceHttpBoot) or sourceCount
		end)
		local intent = engine.intent
		local intentText = type(intent) == "table" and (tostring(intent.Kind) .. " -> " .. tostring(intent.Target)) or tostring(intent or "None")
		setControl("Debug", "Status", table.concat({
			string.format("Version %s | Build %s | Generated %s", tostring(GB.Version or "unknown"), tostring(GB.Build or "unknown"), tostring(Generated.Version or "unknown")),
			"Owner: " .. tostring(control.owner) .. " | Controller: " .. tostring(control.status) .. " / " .. tostring(control.statusReason or ""),
			"Intent: " .. intentText,
			"Cache: " .. tostring(cache.keys or 0) .. "/" .. tostring(cache.max or "?")
				.. " | quest age " .. (questAge and string.format("%.1fs", questAge) or "UNKNOWN")
				.. " | stat age " .. (statAge and string.format("%.1fs", statAge) or "UNKNOWN"),
			"Pending remotes: " .. join(pending, ", ", "None"),
			"Last progress: " .. tostring(engine._lastRealProgressWhy or "UNKNOWN")
				.. " | age " .. (engine._lastRealProgressAt and string.format("%.1fs", now - engine._lastRealProgressAt) or "UNKNOWN"),
			"Movement: " .. (moving and "ACTIVE" or "IDLE")
				.. " | Combat: " .. tostring(GB.Combat and GB.Combat.lockMob and instanceName(GB.Combat.lockMob) or "None"),
			"Resolver misses: " .. tostring(resolverMiss) .. " | dummy misses " .. tostring(dummyMiss),
			"Error: " .. tostring(M._lastUIError or control.error or control.lastError or engine.idleDetail or "None"),
			string.format("Perf worst: %s %.2fms | intent switches/min %.1f", worstName, worstMs * 1000,
				type(engine.intentSwitchesPerMin) == "function" and engine.intentSwitchesPerMin() or 0),
			"SourceHTTP after boot: " .. tostring(math.max(0, sourceCount - sourceBase)),
		}, "\n"))
	end

	syncControls = function()
		local owner = controllerOwner()
		setControl("Auto", "Master", owner == OWNER.FULL_AUTO)
		setControl("Home", "FullAuto", owner == OWNER.FULL_AUTO)
		setControl("Mobs", "Continuous", owner == OWNER.MANUAL_MOB and UI.mobContinuous)
		setControl("Bosses", "AutoFarm", owner == OWNER.MANUAL_BOSS and UI.bossAuto)
		setControl("Chest", "Auto", owner == OWNER.MANUAL_CHEST and UI.autoChest)
		setControl("Home", "AutoRespawn", UI.autoRespawn)
		setControl("Home", "SafeFastAttack", Config.CombatMode == "SAFE_FAST")
		setControl("Home", "AutoEquip", Config.AutoEquip == true)
		setControl("Home", "AutoStats", Config.AutoStats == true)
		setControl("Stats", "AutoStats", Config.AutoStats == true)
		setControl("Mobs", "SwitchDistance", UI.switchDistance)
		setControl("Settings", "CombatRange", UI.combatRange)
		setControl("Settings", "TweenSpeed", UI.tweenSpeed)
		setControl("Settings", "Stickiness", UI.stickiness)
		setControl("Settings", "SwitchDistance", UI.switchDistance)
	end

	local function exactChoice(value, options, fallback)
		if type(value) == "string" and contains(options, value) then return value end
		return fallback
	end

	local function boundedSelection(values, options, maximum)
		local out = {}
		for _, value in ipairs(type(values) == "table" and values or {}) do
			if #out >= (maximum or 64) then break end
			if type(value) == "string" and contains(options, value) and not contains(out, value) then out[#out + 1] = value end
		end
		return out
	end

	local function configDocument()
		local owner = controllerOwner()
		local actionsAllowed = UI.resumeActions == true
		local persistedOwner = OWNER.IDLE
		if actionsAllowed then
			if owner == OWNER.FULL_AUTO then
				persistedOwner = owner
			elseif owner == OWNER.MANUAL_QUEST and (UI.storyContinuous or UI.repeatContinuous) then
				persistedOwner = owner
			elseif owner == OWNER.MANUAL_MOB and UI.mobContinuous then
				persistedOwner = owner
			elseif owner == OWNER.MANUAL_BOSS and (UI.bossAuto or UI.bossWait) then
				persistedOwner = owner
			elseif owner == OWNER.MANUAL_CHEST and UI.autoChest then
				persistedOwner = owner
			end
		end
		return {
			Schema = CONFIG_SCHEMA,
			SavedAt = os.time(),
			ResumeActions = actionsAllowed,
			ActionOwner = persistedOwner,
			Selections = {
				StoryQuest = UI.storyQuest,
				AllQuest = UI.allQuest,
				DetailQuest = UI.detailQuest,
				RepeatQuest = UI.repeatQuest,
				Repeatables = copyArray(UI.repeatables, 64),
				ActiveQuest = UI.activeQuest,
				CompletedQuest = UI.completedQuest,
				Mobs = copyArray(UI.mobs, 64),
				Bosses = copyArray(UI.bosses, 64),
				BossFocus = UI.bossFocus,
				Island = UI.island,
				NPC = UI.npc,
				Location = UI.location,
				Item = UI.item,
				Equipment = UI.equipment,
				PreferredEquipment = UI.preferredEquipment,
				Skill = UI.skill,
				LinkedQuest = UI.linkedQuest,
				Stat = UI.statSelected,
				Mining = copyArray(UI.mining, 32),
				Fishing = UI.fishing,
				Farming = UI.farming,
				Cooking = UI.cooking,
				Fruit = UI.fruit,
				Shop = UI.shop,
				QuickShop = UI.quickShop,
				ChestMap = UI.chestMap,
				Code = UI.code,
			},
			Modes = {
				Repeat = UI.repeatMode,
				Mob = UI.mobMode,
				AutoProgress = UI.autoMode,
				StatPreset = UI.statPreset,
			},
			TargetLevel = UI.targetLevel,
			Ranges = {
				Combat = clampNumber(UI.combatRange, 2, 30, 5.5),
				TweenSpeed = clampNumber(UI.tweenSpeed, 20, 300, 95),
				Stickiness = clampNumber(UI.stickiness, 0, 30, 2),
				SwitchDistance = clampNumber(UI.switchDistance, 10, 300, 55),
			},
			StatRatio = copyMap(UI.statWeights),
			Toggles = {
				AutoRespawn = UI.autoRespawn == true,
				SafeFastAttack = Config.CombatMode == "SAFE_FAST",
				AutoEquip = Config.AutoEquip == true,
				AutoStats = Config.AutoStats == true,
				AntiAFK = UI.antiAFK == true,
				AutoPreferredEquipment = UI.autoPreferredEquipment == true,
				FruitAutoPickup = UI.fruitAutoPickup == true,
				AutoRewards = UI.autoRewards == true,
			},
			Actions = {
				StoryContinuous = actionsAllowed and UI.storyContinuous == true or false,
				RepeatContinuous = actionsAllowed and UI.repeatContinuous == true or false,
				MobContinuous = actionsAllowed and UI.mobContinuous == true or false,
				BossAuto = actionsAllowed and UI.bossAuto == true or false,
				BossWait = actionsAllowed and UI.bossWait == true or false,
				AutoMining = actionsAllowed and UI.autoMining == true or false,
				AutoChest = actionsAllowed and UI.autoChest == true or false,
				AutoCodesOnJoin = actionsAllowed and UI.autoCodesOnJoin == true or false,
				ResumeFullAuto = actionsAllowed and UI.resumeFullAuto == true or false,
			},
		}
	end

	local function setConfigStatus(text)
		M._configStatus = tostring(text)
		setControl("Settings", "Status", M._configStatus)
	end

	function M.SaveConfig(first)
		if first ~= nil and first ~= M and type(first) ~= "boolean" then
			return false, "invalid call"
		end
		if typeof(writefile) ~= "function" then
			setConfigStatus("Executor writefile is unavailable.")
			return false, "writefile unavailable"
		end
		if typeof(makefolder) == "function" then pcall(makefolder, "GBKaitun") end
		local ok, encoded = pcall(HttpService.JSONEncode, HttpService, configDocument())
		if not ok then
			setConfigStatus("JSON encode failed: " .. tostring(encoded))
			return false, tostring(encoded)
		end
		local wrote, err = pcall(writefile, CONFIG_PATH, encoded)
		if not wrote then
			setConfigStatus("Save failed: " .. tostring(err))
			return false, tostring(err)
		end
		setConfigStatus("Saved bounded schema at " .. tostring(os.time()) .. ". ResumeActions=" .. tostring(UI.resumeActions))
		M.Notify("Config saved", CONFIG_PATH, "success")
		return true
	end

	local function applyAntiAFK(value)
		local control = M.Controls.Home and M.Controls.Home.AntiAFK
		if control and type(control.Set) == "function" then
			pcall(control.Set, control, value == true, false)
		else
			UI.antiAFK = false
		end
	end

	local function applyConfigDocument(data)
		stopOwner("ui_config_load")
		local selections = type(data.Selections) == "table" and data.Selections or {}
		local modes = type(data.Modes) == "table" and data.Modes or {}
		local ranges = type(data.Ranges) == "table" and data.Ranges or {}
		local toggles = type(data.Toggles) == "table" and data.Toggles or {}
		local actions = type(data.Actions) == "table" and data.Actions or {}
		local resume = data.ResumeActions == true

		UI.storyQuest = exactChoice(selections.StoryQuest, storyQuests, UI.storyQuest)
		UI.allQuest = exactChoice(selections.AllQuest, allQuests, UI.allQuest)
		UI.detailQuest = exactChoice(selections.DetailQuest, allQuests, UI.detailQuest)
		UI.repeatQuest = exactChoice(selections.RepeatQuest, repeatQuests, UI.repeatQuest)
		UI.repeatables = boundedSelection(selections.Repeatables, repeatQuests, 64)
		UI.activeQuest = type(selections.ActiveQuest) == "string" and selections.ActiveQuest or UI.activeQuest
		UI.completedQuest = type(selections.CompletedQuest) == "string" and selections.CompletedQuest or UI.completedQuest
		UI.mobs = boundedSelection(selections.Mobs, mobNames, 64)
		UI.bosses = boundedSelection(selections.Bosses, bossNames, 64)
		UI.bossFocus = exactChoice(selections.BossFocus, bossNames, UI.bossFocus)
		UI.island = exactChoice(selections.Island, PHYSICAL_ISLANDS, UI.island)
		UI.npc = exactChoice(selections.NPC, npcNames, UI.npc)
		UI.location = exactChoice(selections.Location, locationNames, UI.location)
		UI.item = type(selections.Item) == "string" and selections.Item or UI.item
		UI.equipment = type(selections.Equipment) == "string" and selections.Equipment or UI.equipment
		UI.preferredEquipment = type(selections.PreferredEquipment) == "string" and selections.PreferredEquipment or UI.preferredEquipment
		UI.skill = type(selections.Skill) == "string" and selections.Skill or UI.skill
		UI.linkedQuest = type(selections.LinkedQuest) == "string" and selections.LinkedQuest or UI.linkedQuest
		UI.statSelected = exactChoice(selections.Stat, STAT_NAMES, UI.statSelected)
		UI.mining = boundedSelection(selections.Mining, lifeTargets.Mining, 32)
		UI.fishing = exactChoice(selections.Fishing, lifeTargets.Fishing, UI.fishing)
		UI.farming = exactChoice(selections.Farming, lifeTargets.Farming, UI.farming)
		UI.cooking = exactChoice(selections.Cooking, lifeTargets.Cooking, UI.cooking)
		UI.fruit = type(selections.Fruit) == "string" and selections.Fruit or UI.fruit
		UI.shop = exactChoice(selections.Shop, shopNames, UI.shop)
		UI.quickShop = exactChoice(selections.QuickShop, quickNames, UI.quickShop)
		UI.chestMap = exactChoice(selections.ChestMap, { "CURRENT", "Anchor Town" }, "CURRENT")
		UI.code = exactChoice(selections.Code, knownCodes, UI.code)
		UI.repeatMode = exactChoice(modes.Repeat, { "ONE", "ROTATE", "BEST", "NEAREST" }, "ONE")
		UI.mobMode = exactChoice(modes.Mob, { "NEAREST", "ROUND_ROBIN", "FINISH_GROUP", "PRIORITY" }, "NEAREST")
		UI.autoMode = exactChoice(modes.AutoProgress, { "Story First", "Balanced", "Level Rush", "Manual Requirements" }, "Story First")
		UI.statPreset = exactChoice(modes.StatPreset, { "Balanced", "Strength", "Sword", "Gun", "Fruit", "Hybrid", "Custom" }, "Custom")
		local level = tonumber(data.TargetLevel)
		UI.targetLevel = level and math.floor(clampNumber(level, 1, 100000, 1)) or nil
		UI.combatRange = clampNumber(ranges.Combat, 2, 30, 5.5)
		UI.tweenSpeed = clampNumber(ranges.TweenSpeed, 20, 300, 95)
		UI.stickiness = clampNumber(ranges.Stickiness, 0, 30, 2)
		UI.switchDistance = clampNumber(ranges.SwitchDistance, 10, 300, 55)
		local ratio, ratioTotal = {}, 0
		for _, stat in ipairs(STAT_NAMES) do
			ratio[stat] = clampNumber(type(data.StatRatio) == "table" and data.StatRatio[stat], 0, 100, 0)
			ratioTotal = ratioTotal + ratio[stat]
		end
		local ratioSanitized = ratioTotal <= 0
		if ratioSanitized then
			for _, stat in ipairs(STAT_NAMES) do ratio[stat] = 0 end
			ratio.Strength, ratio.Health = 8, 2
			UI.statPreset = "Custom"
		end
		UI.statWeights = ratio
		UI.resumeActions = resume
		UI.autoRespawn = toggles.AutoRespawn ~= false
		UI.safeFastAttack = toggles.SafeFastAttack == true
		UI.autoEquip = toggles.AutoEquip == true
		UI.autoStats = toggles.AutoStats == true
		UI.autoPreferredEquipment = resume and toggles.AutoPreferredEquipment == true or false
		UI.fruitAutoPickup = toggles.FruitAutoPickup == true
		UI.autoRewards = toggles.AutoRewards == true
		UI.antiAFK = toggles.AntiAFK == true
		UI.storyContinuous = resume and actions.StoryContinuous == true or false
		UI.repeatContinuous = resume and actions.RepeatContinuous == true or false
		UI.mobContinuous = resume and actions.MobContinuous == true or false
		UI.bossAuto = resume and actions.BossAuto == true or false
		UI.bossWait = resume and actions.BossWait == true or false
		UI.autoMining = resume and actions.AutoMining == true or false
		UI.autoChest = resume and actions.AutoChest == true or false
		UI.autoCodesOnJoin = resume and actions.AutoCodesOnJoin == true or false
		UI.resumeFullAuto = resume and actions.ResumeFullAuto == true or false

		Config.AutoRespawn = UI.autoRespawn
		Config.CombatMode = UI.safeFastAttack and "SAFE_FAST" or "NORMAL"
		Config.AutoEquip = UI.autoEquip
		Config.AutoStats = UI.autoStats
		Config.AutoFruit = UI.fruitAutoPickup
		Config.AutoRewards = false
		Config.AutoMining = UI.autoMining
		Config.AutoCodes = false
		Config.CombatRange = UI.combatRange
		Config.TweenSpeed = UI.tweenSpeed
		Config.TargetStickiness = UI.stickiness
		Config.TargetSwitchDistance = UI.switchDistance
		Config.StatRatio = copyMap(UI.statWeights)
		Controller.targetStickiness = UI.stickiness
		controllerCall("setUtilityAuto", "AutoEquip", UI.autoEquip)
		controllerCall("setUtilityAuto", "AutoStats", UI.autoStats)
		controllerCall("setUtilityAuto", "AutoCodes", false)

		controllerCall("setSelectedQuest", UI.detailQuest)
		controllerCall("setSelectedRepeatables", UI.repeatables)
		controllerCall("setRepeatMode", UI.repeatMode)
		controllerCall("setFarmUntilLevel", UI.targetLevel)
		controllerCall("setResumeFullAuto", UI.resumeFullAuto)
		controllerCall("setSelectedMobs", UI.mobs)
		controllerCall("setMobMode", UI.mobMode)
		controllerCall("setSelectedBosses", UI.bosses)
		controllerCall("setWaitBoss", UI.bossWait)
		controllerCall("setBossKillLimit", nil)
		controllerCall("setChestMap", UI.chestMap)
		controllerCall("setChestAutoLoop", UI.autoChest)
		controllerCall("setCombatRange", UI.combatRange)
		controllerCall("setTargetStickiness", UI.stickiness)
		controllerCall("setTargetSwitchDistance", UI.switchDistance)

		setControl("Quests", "Story", UI.storyQuest)
		setControl("Quests", "All", UI.allQuest)
		setControl("Quests", "RepeatSingle", UI.repeatQuest)
		setControl("Quests", "RepeatMulti", UI.repeatables)
		setControl("Quests", "RepeatMode", UI.repeatMode)
		setControl("Quests", "TargetLevel", UI.targetLevel and tostring(UI.targetLevel) or "")
		setControl("Quests", "ResumeFullAuto", UI.resumeFullAuto)
		setControl("Quests", "AutoComplete", UI.storyContinuous)
		setControl("Quests", "RepeatContinuous", UI.repeatContinuous)
		setControl("Mobs", "Targets", UI.mobs)
		setControl("Mobs", "Mode", UI.mobMode)
		setControl("Bosses", "Targets", UI.bosses)
		setControl("Bosses", "Focus", UI.bossFocus)
		setControl("Bosses", "WaitSpawn", UI.bossWait)
		setControl("Teleport", "Island", UI.island)
		setControl("Teleport", "NPC", UI.npc)
		setControl("Teleport", "Location", UI.location)
		setControl("Items", "Item", UI.item)
		setControl("Equipment", "AutoPreferred", UI.autoPreferredEquipment)
		setControl("Skills", "Skill", UI.skill)
		setControl("Stats", "Preset", UI.statPreset)
		setControl("Stats", "Selected", UI.statSelected)
		for _, stat in ipairs(STAT_NAMES) do setControl("Stats", "Weight" .. stat, tostring(UI.statWeights[stat])) end
		setControl("LifeSkills", "Mining", UI.mining)
		setControl("LifeSkills", "AutoMining", UI.autoMining)
		setControl("LifeSkills", "Fishing", UI.fishing)
		setControl("LifeSkills", "Farming", UI.farming)
		setControl("LifeSkills", "Cooking", UI.cooking)
		setControl("Fruit", "Catalog", UI.fruit)
		setControl("Fruit", "AutoPickup", UI.fruitAutoPickup)
		setControl("Shop", "Item", UI.shop)
		setControl("Shop", "Quick", UI.quickShop)
		setControl("Chest", "Map", UI.chestMap)
		setControl("Codes", "Code", UI.code)
		setControl("Codes", "AutoJoin", UI.autoCodesOnJoin)
		setControl("Codes", "AutoRewards", UI.autoRewards)
		setControl("Auto", "Mode", UI.autoMode)
		setControl("Settings", "ResumeActions", UI.resumeActions)
		applyAntiAFK(UI.antiAFK)
		refreshDynamicOptions(false)

		if resume then
			local owner = exactChoice(data.ActionOwner, {
				OWNER.FULL_AUTO, OWNER.MANUAL_QUEST, OWNER.MANUAL_MOB, OWNER.MANUAL_BOSS, OWNER.MANUAL_CHEST,
			}, OWNER.IDLE)
			if owner == OWNER.MANUAL_QUEST and not (UI.storyContinuous or UI.repeatContinuous) then
				owner = OWNER.IDLE
			elseif owner == OWNER.MANUAL_MOB and not UI.mobContinuous then
				owner = OWNER.IDLE
			elseif owner == OWNER.MANUAL_BOSS and not (UI.bossAuto or UI.bossWait) then
				owner = OWNER.IDLE
			elseif owner == OWNER.MANUAL_CHEST and not UI.autoChest then
				owner = OWNER.IDLE
			end
			if owner ~= OWNER.IDLE then startOwner(owner, "ui_config_resume") end
			if UI.autoCodesOnJoin then triggerAutoCodesOnce() end
		end
		syncControls()
		return ratioSanitized
	end

	function M.LoadConfig(first, second)
		local silent = first == M and second == true or first == true
		if typeof(isfile) ~= "function" or typeof(readfile) ~= "function" then
			setConfigStatus("Executor readfile/isfile is unavailable.")
			return false, "read unavailable"
		end
		local existsOk, exists = pcall(isfile, CONFIG_PATH)
		if not existsOk or not exists then
			setConfigStatus(M._initialStatRatioSanitized
				and "No saved config; stat ratio sanitized to 8 Strength / 2 Health."
				or "No saved config; safe defaults active.")
			return false, "not found"
		end
		local readOk, raw = pcall(readfile, CONFIG_PATH)
		if not readOk or type(raw) ~= "string" then
			setConfigStatus("Read failed: " .. tostring(raw))
			return false, tostring(raw)
		end
		local decodedOk, data = pcall(HttpService.JSONDecode, HttpService, raw)
		if not decodedOk or type(data) ~= "table" or tonumber(data.Schema) ~= CONFIG_SCHEMA then
			setConfigStatus("Invalid or unsupported config schema.")
			return false, "invalid schema"
		end
		local applyOk, ratioSanitized = pcall(applyConfigDocument, data)
		if not applyOk then
			setConfigStatus("Load failed: " .. tostring(ratioSanitized))
			return false, tostring(ratioSanitized)
		end
		setConfigStatus("Loaded bounded schema. ResumeActions=" .. tostring(UI.resumeActions)
			.. (ratioSanitized and " Stat ratio sanitized to 8 Strength / 2 Health." or ""))
		if not silent then
			M.Notify(
				"Config loaded",
				ratioSanitized and "Stat ratio sanitized to 8 Strength / 2 Health."
					or (UI.resumeActions and "Eligible saved owner restored." or "Actions remain IDLE."),
				"success"
			)
		end
		return true
	end

	function M.ResetConfig()
		stopOwner("ui_config_reset")
		UI.storyQuest, UI.allQuest = storyQuests[1], allQuests[1]
		UI.detailQuest, UI.repeatQuest = UI.storyQuest or UI.allQuest, repeatQuests[1]
		UI.repeatables, UI.repeatMode, UI.targetLevel, UI.resumeFullAuto = {}, "ONE", nil, false
		UI.storyContinuous, UI.repeatContinuous, UI.activeQuest, UI.completedQuest = false, false, nil, nil
		UI.mobs, UI.mobMode, UI.mobContinuous = {}, "NEAREST", false
		UI.bosses, UI.bossFocus, UI.bossAuto, UI.bossWait = {}, bossNames[1], false, false
		UI.island, UI.npc, UI.location = PHYSICAL_ISLANDS[1], npcNames[1], locationNames[1]
		UI.item, UI.equipment, UI.preferredEquipment, UI.autoPreferredEquipment = baseItemNames[1], nil, nil, false
		UI.skill, UI.linkedQuest, UI.statPreset, UI.statSelected = baseSkillNames[1], nil, "Custom", STAT_NAMES[1]
		for _, stat in ipairs(STAT_NAMES) do UI.statWeights[stat] = 0 end
		UI.statWeights.Strength, UI.statWeights.Health = 8, 2
		UI.mining, UI.autoMining = {}, false
		UI.fishing, UI.farming, UI.cooking = lifeTargets.Fishing[1], lifeTargets.Farming[1], lifeTargets.Cooking[1]
		UI.fruit, UI.fruitConfirm, UI.fruitAutoPickup = fruitNames[1], false, false
		UI.shop, UI.quickShop, UI.shopQuantity = shopNames[1], quickNames[1], 1
		UI.chestMap, UI.autoChest = "CURRENT", false
		UI.code, UI.manualCode, UI.autoCodesOnJoin = knownCodes[1], "", false
		UI.autoRewards = false
		UI.autoMode, UI.resumeActions = "Story First", false
		UI.autoRespawn, UI.safeFastAttack, UI.autoEquip, UI.autoStats = true, true, false, false
		UI.antiAFK = false
		UI.combatRange, UI.tweenSpeed, UI.stickiness, UI.switchDistance = 5.5, 95, 2, 55

		Config.AutoRespawn = true
		Config.CombatMode = "SAFE_FAST"
		Config.AutoEquip, Config.AutoStats, Config.AutoFruit = false, false, false
		Config.AutoMining, Config.AutoFishing, Config.AutoFarming, Config.AutoCooking = false, false, false, false
		Config.AutoCodes, Config.AutoRewards = false, false
		Config.CombatRange, Config.TweenSpeed, Config.TargetStickiness = UI.combatRange, UI.tweenSpeed, UI.stickiness
		Config.TargetSwitchDistance = UI.switchDistance
		Config.StatRatio, Config.Build = copyMap(UI.statWeights), "Melee"
		Controller.targetStickiness = UI.stickiness
		controllerCall("setUtilityAuto", "AutoEquip", false)
		controllerCall("setUtilityAuto", "AutoStats", false)
		controllerCall("setUtilityAuto", "AutoCodes", false)
		GB.Codes.stop()
		controllerCall("setSelectedQuest", UI.detailQuest)
		controllerCall("setSelectedRepeatables", {})
		controllerCall("setRepeatMode", "ONE")
		controllerCall("setFarmUntilLevel", nil)
		controllerCall("setResumeFullAuto", false)
		controllerCall("setSelectedMobs", {})
		controllerCall("setMobMode", "NEAREST")
		controllerCall("setSelectedBosses", {})
		controllerCall("setWaitBoss", false)
		controllerCall("setChestMap", "CURRENT")
		controllerCall("setChestAutoLoop", false)
		controllerCall("setCombatRange", UI.combatRange)
		controllerCall("setTargetStickiness", UI.stickiness)
		controllerCall("setTargetSwitchDistance", UI.switchDistance)
		applyAntiAFK(false)

		setControl("Quests", "Story", UI.storyQuest)
		setControl("Quests", "All", UI.allQuest)
		setControl("Quests", "RepeatSingle", UI.repeatQuest)
		setControl("Quests", "RepeatMulti", {})
		setControl("Quests", "RepeatMode", "ONE")
		setControl("Quests", "TargetLevel", "")
		setControl("Quests", "ResumeFullAuto", false)
		setControl("Quests", "AutoComplete", false)
		setControl("Quests", "RepeatContinuous", false)
		setControl("Mobs", "Targets", {})
		setControl("Mobs", "Mode", "NEAREST")
		setControl("Mobs", "Continuous", false)
		setControl("Bosses", "Targets", {})
		setControl("Bosses", "Focus", UI.bossFocus)
		setControl("Bosses", "WaitSpawn", false)
		setControl("Bosses", "AutoFarm", false)
		setControl("Teleport", "Island", UI.island)
		setControl("Teleport", "NPC", UI.npc)
		setControl("Teleport", "Location", UI.location)
		setControl("Items", "Item", UI.item)
		setControl("Equipment", "AutoPreferred", false)
		setControl("Skills", "Skill", UI.skill)
		setControl("Stats", "Preset", "Custom")
		setControl("Stats", "Selected", UI.statSelected)
		for _, stat in ipairs(STAT_NAMES) do setControl("Stats", "Weight" .. stat, tostring(UI.statWeights[stat])) end
		setControl("LifeSkills", "Mining", {})
		setControl("LifeSkills", "AutoMining", false)
		setControl("Fruit", "Catalog", UI.fruit)
		setControl("Fruit", "Confirm", false)
		setControl("Fruit", "AutoPickup", false)
		setControl("Shop", "Item", UI.shop)
		setControl("Shop", "Quick", UI.quickShop)
		setControl("Shop", "Quantity", "1")
		setControl("Chest", "Map", "CURRENT")
		setControl("Chest", "Auto", false)
		setControl("Codes", "Code", UI.code)
		setControl("Codes", "Manual", "")
		setControl("Codes", "AutoJoin", false)
		setControl("Codes", "AutoRewards", false)
		setControl("Auto", "Master", false)
		setControl("Auto", "Mode", UI.autoMode)
		setControl("Settings", "ResumeActions", false)
		refreshDynamicOptions(false)
		syncControls()
		setConfigStatus("Reset to safe defaults; owner is IDLE.")
		local saved, reason = M.SaveConfig()
		if not saved and reason ~= "writefile unavailable" then return false, reason end
		M.Notify("Config reset", "Safe defaults are active.", "success")
		return true
	end

	function M.Refresh()
		if runtimeDead() then return false, "runtime stopped" end
		local ok, err = pcall(function()
			if GB.PlayerData and type(GB.PlayerData.forceQuestRefresh) == "function" then
				GB.PlayerData.forceQuestRefresh("ui_refresh")
			elseif GB.PlayerData and type(GB.PlayerData.requestLive) == "function" then
				GB.PlayerData.requestLive("ui_refresh")
			end
			if GB.PlayerData and type(GB.PlayerData.requestStats) == "function" then GB.PlayerData.requestStats("ui_refresh") end
			if GB.State and type(GB.State.refresh) == "function" then GB.State.refresh() end
			refreshDynamicOptions(false)
			updateHome()
			updateQuestDetails()
			updateActiveQuestDetails()
			updateMobStatus()
			updateBossDetails()
			updateNpcDetails()
			updateItemDetails()
			updateEquipmentDetails()
			updateSkillDetails()
			updateStatsStatus()
			updateLifeStatus()
			updateFruitStatus()
			updateHakiStatus()
			updateShopStatus()
			updateChestStatus()
			updateCodeStatus()
			updateAutoStatus()
			updateDebugStatus()
			syncControls()
			if Config.Enabled == false then updateStoppedStatus() end
		end)
		if not ok then return false, tostring(err) end
		return true
	end

	trackConnection(GB.Codes.onResult(function(code, status, text)
		if runtimeDead() then return end
		UI._lastCodeResult = tostring(code) .. " -> " .. tostring(status) .. " (" .. tostring(text or "") .. ")"
		M.Notify({
			Title = "Code " .. tostring(status),
			Text = tostring(code) .. ": " .. tostring(text or ""),
			Type = status == "SUCCESS" and "success" or (status == "ERROR" and "error" or "info"),
			Gap = 0.5,
		})
		updateCodeStatus()
	end))

	local previousOwner = controllerOwner()
	local previousStatus = Controller.status
	if type(Controller.onChange) == "function" then
		local ok, connection = pcall(Controller.onChange, Controller, function(snapshot)
			if runtimeDead() or type(snapshot) ~= "table" then return end
			local owner = snapshot.owner or OWNER.IDLE
			if owner ~= previousOwner then
				if previousOwner == OWNER.MANUAL_QUEST and owner ~= OWNER.MANUAL_QUEST then
					UI.storyContinuous, UI.repeatContinuous = false, false
					setControl("Quests", "AutoComplete", false)
					setControl("Quests", "RepeatContinuous", false)
				elseif previousOwner == OWNER.MANUAL_MOB and owner ~= OWNER.MANUAL_MOB then
					UI.mobContinuous = false
					setControl("Mobs", "Continuous", false)
				elseif previousOwner == OWNER.MANUAL_BOSS and owner ~= OWNER.MANUAL_BOSS then
					UI.bossAuto, UI.bossWait = false, false
					setControl("Bosses", "AutoFarm", false)
					setControl("Bosses", "WaitSpawn", false)
				elseif previousOwner == OWNER.MANUAL_CHEST and owner ~= OWNER.MANUAL_CHEST then
					UI.autoChest = false
					setControl("Chest", "Auto", false)
				end
				if owner ~= OWNER.IDLE and UI.autoMining then
					UI.autoMining = false
					Config.AutoMining = false
					setControl("LifeSkills", "AutoMining", false)
				end
				if owner == OWNER.FULL_AUTO then
					applyAutoModeFlags(UI.autoMode)
					UI.autoEquip = Config.AutoEquip == true
					UI.autoStats = Config.AutoStats == true
					Config.AutoRewards = UI.autoRewards == true
					Config.CombatMode = UI.safeFastAttack and "SAFE_FAST" or "NORMAL"
				end
				M.Notify({
					Title = "Owner changed",
					Text = tostring(previousOwner) .. " -> " .. tostring(owner),
					Type = owner == OWNER.IDLE and "warning" or "info",
					Gap = 0.5,
				})
				previousOwner = owner
			end
			syncControls()
		end)
		if ok then trackConnection(connection) end
	end
	if type(Controller.onStatus) == "function" then
		local importantStatus = {
			ACTION_COMPLETE = "success",
			ACTION_FAILED = "error",
			ERROR = "error",
			PAUSED = "warning",
			QUEST_COMPLETE = "success",
			LEVEL_REACHED = "success",
			CHESTS_EXHAUSTED = "success",
			BOSS_LIMIT_REACHED = "success",
			WAIT_RESPAWN = "warning",
			RESUMING = "success",
		}
		local ok, connection = pcall(Controller.onStatus, Controller, function(snapshot)
			if runtimeDead() or type(snapshot) ~= "table" then return end
			local status = snapshot.status
			local target = snapshot.progress and snapshot.progress.target
			local quietComplete = status == "ACTION_COMPLETE" and M._quietLabels and M._quietLabels[target] == true
			if status ~= previousStatus and importantStatus[status] and not quietComplete then
				M.Notify({
					Title = tostring(status),
					Text = tostring(snapshot.reason or target or ""),
					Type = importantStatus[status],
					Gap = 0.65,
				})
			end
			if (status == "ACTION_COMPLETE" or status == "ACTION_FAILED") and target and M._quietLabels then
				M._quietLabels[target] = nil
			end
			previousStatus = status
		end)
		if ok then trackConnection(connection) end
	end

	local statusToken = {}
	M._statusToken = statusToken
	local function runStatus(name, callback, ...)
		local ok, err = pcall(callback, ...)
		if not ok then
			M._lastUIError = name .. ": " .. tostring(err)
			M.Notify({ Title = "UI status error", Text = M._lastUIError, Type = "error", Gap = 8 })
		end
	end
	local statusTask = task.spawn(function()
		local lastDynamic, lastDebug, lastMining, lastPreferred, lastFruit = 0, 0, 0, 0, 0
		while M._statusToken == statusToken and not runtimeDead() do
			local now = os.clock()
			if Config.Enabled == false then
				runStatus("Stopped", updateStoppedStatus)
			else
				if UI.autoCodesOnJoin and not M._autoCodesTriggered then
					runStatus("AutoCodesOnJoin", triggerAutoCodesOnce)
				end
				if M._codesQueueProgress
					and GB.Codes
					and GB.Codes.running ~= true
					and GB.Codes.pendingCode == nil
				then
					M._codesQueueProgress = nil
					Config.AutoCodes = false
					controllerCall("setUtilityAuto", "AutoCodes", false)
					M.Notify("Codes complete", "Known-code queue finished.", "success")
				end
				runStatus("Home", updateHome)
				runStatus("ActiveQuest", updateActiveQuestDetails)
				runStatus("Mobs", updateMobStatus)
				runStatus("Bosses", updateBossDetails)
				runStatus("Stats", updateStatsStatus)
				runStatus("LifeSkills", updateLifeStatus)
				runStatus("Fruit", updateFruitStatus)
				runStatus("HakiRaceTrait", updateHakiStatus)
				runStatus("Shop", updateShopStatus)
				runStatus("Chest", updateChestStatus)
				runStatus("Codes", updateCodeStatus)
				runStatus("AutoProgress", updateAutoStatus)
				runStatus("ControlSync", syncControls)

				if now - lastDynamic >= 3 then
					lastDynamic = now
					runStatus("DynamicOptions", refreshDynamicOptions, true)
				end
				if now - lastDebug >= 1 then
					lastDebug = now
					runStatus("Debug", updateDebugStatus)
				end
				if controllerOwner() == OWNER.IDLE and UI.autoPreferredEquipment and UI.preferredEquipment and now - lastPreferred >= 2 then
					lastPreferred = now
					local preferred = UI.preferredEquipment
					local equipped = false
					if GB.Equipment and type(GB.Equipment.equipmentState) == "function" then
						local ok, value = pcall(GB.Equipment.equipmentState, preferred)
						equipped = ok and type(value) == "table" and (value.Equipped == true or value.Held == true)
					end
					if not equipped and GB.Equipment and type(GB.Equipment.equipNamed) == "function" then
						queueAction("Auto equip: " .. preferred, "equipment:auto_preferred", function()
							return GB.Equipment.equipNamed(preferred, { Manual = true })
						end, { quiet = true })
					end
				end
				if controllerOwner() == OWNER.IDLE and UI.autoMining and #UI.mining > 0 and now - lastMining >= 3 then
					lastMining = now
					UI._miningCursor = ((UI._miningCursor or 0) % #UI.mining) + 1
					local target = UI.mining[UI._miningCursor]
					if GB.LifeSkills and type(GB.LifeSkills.mineToward) == "function" then
						queueAction("Auto mine: " .. target, "life:mining", function()
							Config.AutoMining = true
							return GB.LifeSkills.mineToward(target)
						end, { quiet = true })
					end
				end
				if controllerOwner() == OWNER.IDLE and UI.fruitAutoPickup and now - lastFruit >= 2.5 then
					lastFruit = now
					if GB.Fruit and type(GB.Fruit.pickupNearby) == "function" then
						queueAction("Auto pickup fruit", "fruit:auto_pickup", function()
							return GB.Fruit.pickupNearby()
						end, { quiet = true })
					end
				end
			end
			task.wait(STATUS_INTERVAL)
		end
	end)
	M.Tasks[#M.Tasks + 1] = statusTask
	GB.Tasks = type(GB.Tasks) == "table" and GB.Tasks or {}
	GB.Tasks[#GB.Tasks + 1] = statusTask

	local rawWindowDestroy = M.Window.Destroy
	function M.Destroy()
		if M._destroyed or M._destroying then return true end
		M._destroying = true
		pcall(M.SaveConfig, M)
		M._destroyed = true
		M._statusToken = nil
		quiesce("ui_destroy")
		if statusTask then pcall(task.cancel, statusTask) end
		local connections = M.Connections
		M.Connections = {}
		for _, connection in ipairs(connections) do
			if connection and type(connection.Disconnect) == "function" then
				pcall(connection.Disconnect, connection)
			elseif typeof(connection) == "RBXScriptConnection" then
				pcall(function() connection:Disconnect() end)
			end
			untrackConnection(connection)
		end
		M._antiAFKConnection = nil
		for index = #GB.Tasks, 1, -1 do
			if GB.Tasks[index] == statusTask then table.remove(GB.Tasks, index) end
		end
		M.Tasks = {}
		if type(UILib.Unload) == "function" then pcall(UILib.Unload, UILib) end
		M._destroying = false
		return true
	end

	M.Window.Destroy = function(window, ...)
		if M._destroyed then return rawWindowDestroy(window, ...) end
		if M._windowCloseActive then return true end
		M._windowCloseActive = true
		local stop = GB.Stop
		if type(stop) == "function" then
			local ok, result, detail = pcall(stop)
			if ok then
				if not M._destroyed then M.Destroy() end
				return result, detail
			end
		end
		return M.Destroy()
	end

	M.Save = M.SaveConfig
	M.Load = M.LoadConfig
	M.Reset = M.ResetConfig
	M.Unload = M.Destroy

	if Config.Enabled == false then
		updateStoppedStatus()
	else
		local refreshed, refreshError = M.Refresh()
		if not refreshed then M._lastUIError = "Initial refresh: " .. tostring(refreshError) end
	end
	M.LoadConfig(true)
	if UI.autoCodesOnJoin then triggerAutoCodesOnce() end
	print("[GBUI] ready")
	local loadedOwner = controllerOwner()
	M.Notify({
		Title = "Grand Blue UI",
		Text = loadedOwner == OWNER.IDLE
			and "Loaded in IDLE. Select Full Auto or a farm mode to run."
			or ("Restored explicit saved owner " .. tostring(loadedOwner) .. "."),
		Type = "success",
		Gap = 0,
	})
	return M
end
