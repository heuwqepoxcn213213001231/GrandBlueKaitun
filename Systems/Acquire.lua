-- Generic item acquisition. Methods from QuestSpecs. No quest-name spaghetti.

return function(GB)
	local CS = game:GetService("CollectionService")
	local M = {
		lastItem = nil,
		lastSource = nil,
		cycles = {},
		picked = {},
		dropMiss = {},
	}

	local function pbegin()
		return GB.Profiler and GB.Profiler.begin and GB.Profiler.begin() or nil
	end

	local function pdone(name, t0)
		if t0 and GB.Profiler and GB.Profiler.done then
			GB.Profiler.done(name, t0)
		end
	end

	local function perfCount(name, n)
		if GB.Profiler and GB.Profiler.count then
			GB.Profiler.count(name, n or 1)
		end
	end

	local DROP_FOLDERS = {
		"Drops",
		"DroppedItems",
		"Pickups",
		"QuestItems",
		"Dropped Items",
		"WorldDrops",
		"Loot",
	}
	local DROP_TAGS = { "Drop", "DroppedItem", "Pickup", "QuestItem", "Loot", "DroppedItems" }
	local DROP_INTERACT = { Pickup = true, Collect = true, Loot = true, Drop = true, Take = true }

	local function ownedCount(item)
		local ok, n = GB.PlayerData.hasItem(item)
		if ok then
			return n or 1
		end
		return 0
	end

	local function itemMatch(inst, item)
		if not (inst and item) then
			return false
		end
		if inst.Name == item then
			return true
		end
		local disp = GB.Resolver.displayName(inst)
		if disp == item then
			return true
		end
		for _, key in ipairs({ "Item", "ItemName", "QuestItem", "DropName", "ItemId" }) do
			local v = inst:GetAttribute(key)
			if v == item then
				return true
			end
		end
		if inst:HasTag(item) then
			return true
		end
		return false
	end

	local function inRS(inst)
		local RS = game:GetService("ReplicatedStorage")
		return inst and RS:IsAncestorOf(inst)
	end

	local function collectDropRoots()
		local roots, listed = {}, {}
		local function add(inst)
			if inst and inst.Parent and not listed[inst] and not inRS(inst) then
				listed[inst] = true
				roots[#roots + 1] = inst
			end
		end
		for _, name in ipairs(DROP_FOLDERS) do
			add(workspace:FindFirstChild(name))
			local aa = workspace:FindFirstChild("AA IMPORTANT")
			if aa then
				add(aa:FindFirstChild(name))
			end
		end
		for _, tag in ipairs(DROP_TAGS) do
			local tagged = CS:GetTagged(tag)
			if type(tagged) == "table" then
				for _, inst in ipairs(tagged) do
					add(inst)
				end
			end
		end
		return roots
	end

	function M.findDrop(item)
		if type(item) ~= "string" or item == "" then
			return nil
		end
		local now = os.clock()
		local origin
		local hrp = GB.World.hrp()
		if hrp then
			origin = hrp.Position
		end
		local hits = {}
		local roots = collectDropRoots()
		local considered = {}

		local function consider(inst)
			if not inst or not inst.Parent or inRS(inst) or considered[inst] then
				return
			end
			considered[inst] = true
			if not itemMatch(inst, item) then
				return
			end
			local pos = GB.Resolver.positionOf(inst)
			local dist = (origin and pos) and (pos - origin).Magnitude or 1e9
			hits[#hits + 1] = { inst = inst, dist = dist }
		end

		for _, root in ipairs(roots) do
			consider(root)
			perfCount("WorkspaceDeepScan", 1)
			for _, d in ipairs(root:GetDescendants()) do
				consider(d)
			end
		end

		for _, tag in ipairs({ item }) do
			local tagged = CS:GetTagged(tag)
			if type(tagged) == "table" then
				for _, inst in ipairs(tagged) do
					if inst.Parent and not inRS(inst) then
						local prompt = GB.Resolver.prompt(inst)
						local inter = inst:GetAttribute("Interaction")
						if prompt or DROP_INTERACT[inter] or itemMatch(inst, item) then
							consider(inst)
						end
					end
				end
			end
		end

		local ents = workspace:FindFirstChild("Entities")
		if ents then
			for _, c in ipairs(ents:GetChildren()) do
				if itemMatch(c, item) then
					consider(c)
				end
			end
		end

		if #hits == 0 and now - (M.dropMiss[item] or 0) > 2.5 then
			perfCount("WorkspaceDeepScan", 1)
			for _, d in ipairs(workspace:GetDescendants()) do
				if d:IsA("ProximityPrompt") and not inRS(d) then
					local parent = d.Parent
					if parent and itemMatch(parent, item) then
						local pos = GB.Resolver.positionOf(parent)
						if not origin or (pos and (pos - origin).Magnitude < 45) then
							consider(parent)
						end
					end
				end
			end
		end
		if #hits == 0 then
			M.dropMiss[item] = now
		else
			M.dropMiss[item] = nil
		end

		if #hits == 0 then
			return nil
		end
		table.sort(hits, function(a, b)
			return a.dist < b.dist
		end)
		return hits[1].inst
	end

	function M.AlreadyOwned(item, amount)
		amount = amount or 1
		return ownedCount(item) >= amount
	end

	function M.pickupInst(inst, item)
		if not inst then
			return false
		end
		if M.picked[inst] and os.clock() - M.picked[inst] < 1.2 then
			return false
		end
		if GB.World.interact then
			GB.World.interact(inst, 8)
		else
			GB.World.ToInteractable(inst, 8)
			local pr = GB.Resolver.prompt(inst)
			if pr then
				GB.World.firePrompt(pr)
			end
		end
		M.picked[inst] = os.clock()
		GB.Log.log("PICKUP", tostring(item or inst.Name))
		return true
	end

	function M.WorldPickup(item)
		local inst = M.findDrop(item)
		if not inst then
			return false
		end
		GB.Log.log("DROP", tostring(item))
		return M.pickupInst(inst, item)
	end

	function M.Interactable(item, ctx)
		ctx = ctx or {}
		local tag = ctx.Source or ctx.Marker or item
		local inst = GB.Resolver.taggedAny(tag) or GB.Resolver.byName(tag, "npc")
		if not inst then
			return false
		end
		return M.pickupInst(inst, item)
	end

	function M.ShopPurchase(item, amount)
		return GB.Shop.buy(item, amount or 1)
	end

	function M.Mining(item)
		return GB.LifeSkills.mineToward(item)
	end

	function M.Fishing(item)
		return GB.LifeSkills.fishToward(item)
	end

	function M.Farming(typ, item)
		return GB.LifeSkills.farmToward(typ or "Harvest", item)
	end

	function M.Cooking(item)
		return GB.LifeSkills.cookToward(item)
	end

	function M.Crafting(item)
		if GB.LifeSkills.smeltToward then
			return GB.LifeSkills.smeltToward(item)
		end
		return GB.LifeSkills.mineToward(item)
	end

	function M.Chest(item, amount, ctx)
		if GB.Chest.lootUntil then
			return GB.Chest.lootUntil(ctx and ctx.Quest, amount or 5)
		end
		return GB.Chest.openNearby()
	end

	function M.Treasure()
		return GB.Treasure.tick and GB.Treasure.tick()
	end

	function M.QuestReward()
		return false
	end

	function M.Dialogue(item, ctx)
		local npc = ctx and (ctx.Source or ctx.NPC)
		if not npc or not GB.Quest then
			return false
		end
		return GB.Quest.talk(npc, false, { Quest = ctx.Quest, DisplayName = npc })
	end

	function M.OtherVerified(item, ctx)
		return M.Interactable(item, ctx)
	end

	local function needAmount(ctx, amount)
		return (ctx and ctx.Amount) or amount or 1
	end

	local function questItemCount(item, ctx, amount)
		local qname = ctx and ctx.Quest
		if not qname or not GB.Quest then
			return 0, false
		end
		if GB.PlayerData.refreshLive then
			GB.PlayerData.refreshLive(false, "acquire_probe")
		end
		if (GB.PlayerData.cycleFinished and GB.PlayerData.cycleFinished(qname, true))
			or ((not GB.PlayerData.cycleFinished) and GB.PlayerData.finished(qname, true))
		then
			return needAmount(ctx, amount), true
		end
		local qs = GB.Quest.questState(qname)
		if not qs then
			return 0, false
		end
		if qs.IsComplete then
			return needAmount(ctx, amount), true
		end
		local o = qs.Objective
		if o and o.TargetName == item then
			return o.Current or 0, o.Complete == true
		end
		if ctx.Stage and qs.StageIndex and qs.StageIndex ~= ctx.Stage then
			return needAmount(ctx, amount), true
		end
		return 0, false
	end

	local function credited(item, amount, ctx)
		if M.AlreadyOwned(item, amount) then
			return true
		end
		local n, done = questItemCount(item, ctx, amount)
		return done or n >= amount
	end

	function M.AcquireFromEnemyDrop(item, amount, ctx)
		ctx = ctx or {}
		amount = amount or 1
		ctx.Amount = amount
		local source = ctx.Source
		local spec = GB.QuestSpecs and GB.QuestSpecs.itemOf(item)
		if not source and spec then
			source = spec.source
		end
		if not source or source == "" then
			GB.Log.warn("ACQUIRE", "MISSING_SOURCE " .. tostring(item))
			return false
		end
		M.lastItem = item
		M.lastSource = source
		GB.Log.log("ACQUIRE", "source=" .. tostring(source))

		if credited(item, amount, ctx) then
			return true
		end
		if M.WorldPickup(item) then
			task.wait(0.35)
			if GB.PlayerData and GB.PlayerData.forceQuestRefresh then
				GB.PlayerData.forceQuestRefresh("acquire_pickup")
			end
			if credited(item, amount, ctx) then
				return true
			end
		end

		local t0 = os.clock()
		local budget = 16
		local sawEnemy = false
		local sawDrop = false
		local noEnemy = 0

		while os.clock() - t0 < budget do
			if credited(item, amount, ctx) then
				if GB.Combat then
					GB.Combat.stopLock()
				end
				return true
			end

			local drop = M.findDrop(item)
			if drop then
				sawDrop = true
				if GB.Combat then
					GB.Combat.stopLock()
				end
				GB.Log.log("DROP", tostring(item))
				M.pickupInst(drop, item)
				task.wait(0.3)
				if credited(item, amount, ctx) then
					return true
				end
			end

			local mob = GB.Combat and GB.Combat.findTarget and GB.Combat.findTarget(source)
			if mob then
				sawEnemy = true
				noEnemy = 0
				GB.Log.log("STATE", string.format("doing=combat target=%s", mob.Name))
				local ok, why = false, nil
				if GB.Combat.lockMob and GB.Combat.IsEnemyAlive and GB.Combat.IsEnemyAlive(GB.Combat.lockMob) then
					ok, why = true, "lock_active"
				elseif GB.Combat.hunt then
					ok = GB.Combat.hunt(source, ctx.Quest)
					why = ok and "engaged" or "no_enemy"
				end
				if not ok then
					task.wait(0.35)
				end
				if GB.Combat and GB.Combat.stopLock then
					if why == "dead" or why == "quest_done" or (GB.Combat.lockMob and GB.Combat.IsEnemyAlive and not GB.Combat.IsEnemyAlive(GB.Combat.lockMob)) then
						GB.Combat.stopLock()
					end
				end
				if GB.PlayerData and GB.PlayerData.forceQuestRefresh then
					GB.PlayerData.forceQuestRefresh("acquire_kill")
				end
				task.wait(0.15)
				if credited(item, amount, ctx) then
					if GB.Combat then
						GB.Combat.stopLock()
					end
					GB.Log.log("ACQUIRE", "kill-credit " .. item)
					return true
				end
			else
				noEnemy = noEnemy + 1
				if ctx.Location and GB.World and GB.World.pullStream then
					GB.World.pullStream(ctx.Location)
				end
				task.wait(0.4)
			end
		end

		if credited(item, amount, ctx) then
			return true
		end
		if sawEnemy or sawDrop then
			return false, "hunting"
		end
		return false, "stuck"
	end

	function M.BossDrop(item, amount, ctx)
		return M.AcquireFromEnemyDrop(item, amount, ctx)
	end

	function M.AcquireItem(item, amount, ctx)
		ctx = ctx or {}
		amount = amount or 1
		if type(item) ~= "string" or item == "" then
			return false
		end
		M.lastItem = item
		GB.Log.log("PLAN", "Need item " .. item)

		if M.AlreadyOwned(item, amount) then
			GB.Log.log("ACQUIRE", "AlreadyOwned " .. item)
			return true
		end

		local spec = GB.QuestSpecs and GB.QuestSpecs.lookup(ctx.Quest, ctx.Stage, ctx.Type, item)
		local itemSpec = GB.QuestSpecs and GB.QuestSpecs.itemOf(item)
		local method = ctx.Method or (spec and spec.acquire) or (itemSpec and itemSpec.method) or "WorldPickup"
		local source = ctx.Source or (spec and spec.source) or (itemSpec and itemSpec.source)
		ctx.Source = source
		ctx.Marker = ctx.Marker or (spec and spec.marker)

		local order = ctx.Plan
		if type(order) ~= "table" or #order == 0 then
			if method == "EnemyDrop" or method == "BossDrop" then
				order = { "AlreadyOwned", "WorldPickup", method }
			elseif method == "ShopPurchase" then
				order = { "AlreadyOwned", "ShopPurchase" }
			elseif method == "Mining" then
				order = { "AlreadyOwned", "Mining" }
			elseif method == "Crafting" then
				order = { "AlreadyOwned", "Crafting" }
			elseif method == "Chest" then
				order = { "AlreadyOwned", "Chest" }
			elseif method == "Fishing" then
				order = { "AlreadyOwned", "Fishing" }
			elseif method == "Farming" then
				order = { "AlreadyOwned", "Farming" }
			elseif method == "Cooking" then
				order = { "AlreadyOwned", "Cooking" }
			elseif method == "Dialogue" then
				order = { "AlreadyOwned", "Dialogue" }
			else
				order = { "AlreadyOwned", "WorldPickup", "Interactable" }
			end
		end

		for _, step in ipairs(order) do
			if step == "AlreadyOwned" then
				if M.AlreadyOwned(item, amount) then
					return true
				end
			elseif step == "WorldPickup" then
				if M.WorldPickup(item) then
					task.wait(0.3)
					if M.AlreadyOwned(item, amount) then
						return true
					end
				end
			elseif step == "EnemyDrop" or step == "BossDrop" then
				local ok, err = M.AcquireFromEnemyDrop(item, amount, ctx)
				if ok then
					return true
				end
				if err == "hunting" or err == "stuck" or err == "bounded" then
					return false, err
				end
			elseif step == "ShopPurchase" then
				if M.ShopPurchase(item, amount) then
					return true
				end
			elseif step == "Mining" then
				local swung = M.Mining(item)
				if credited(item, amount, ctx) then
					return true
				end
				if swung then
					return false, "hunting"
				end
			elseif step == "Crafting" then
				if M.Crafting(item) then
					return M.AlreadyOwned(item, amount)
				end
			elseif step == "Chest" then
				if M.Chest(item, amount, ctx) then
					return true
				end
			elseif step == "Fishing" then
				M.Fishing(item)
			elseif step == "Farming" then
				M.Farming(ctx.Type, item)
			elseif step == "Cooking" then
				M.Cooking(item)
			elseif step == "Interactable" then
				if M.Interactable(item, ctx) then
					task.wait(0.3)
					if M.AlreadyOwned(item, amount) then
						return true
					end
				end
			elseif step == "Dialogue" then
				M.Dialogue(item, ctx)
			elseif step == "QuestReward" then
				M.QuestReward()
			elseif step == "Treasure" then
				M.Treasure()
			elseif step == "OtherVerified" then
				M.OtherVerified(item, ctx)
			end
		end
		return M.AlreadyOwned(item, amount)
	end

	function M.clearCycles(quest)
		if not quest then
			M.cycles = {}
			return
		end
		for k in pairs(M.cycles) do
			if string.sub(k, 1, #quest) == quest then
				M.cycles[k] = nil
			end
		end
	end

	local _acquireItemRaw = M.AcquireItem
	function M.AcquireItem(item, amount, ctx)
		local t0 = pbegin()
		local out = { pcall(_acquireItemRaw, item, amount, ctx) }
		pdone("Acquire", t0)
		if not out[1] then
			error(out[2])
		end
		return unpack(out, 2)
	end

	local _enemyDropRaw = M.AcquireFromEnemyDrop
	function M.AcquireFromEnemyDrop(item, amount, ctx)
		local t0 = pbegin()
		local out = { pcall(_enemyDropRaw, item, amount, ctx) }
		pdone("Acquire", t0)
		if not out[1] then
			error(out[2])
		end
		return unpack(out, 2)
	end

	return M
end
