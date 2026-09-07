-- State → Goal → Task → Execute → Validate → Repeat.
-- Priority: Recovery → Tutorial → Rewards → Codes → Unlock → Inventory → Equip →
-- Stats → Skills → Travel → Story → Repeat → Boss → Upgrades → Fruit/Haki/Race →
-- Treasure/Chest → Life skills.

return function(GB)
	local M = {
		goal = nil,
		task = nil,
	}

	local function setTask(name)
		if GB.State.track.TaskName ~= name then
			GB.State.track.TaskName = name
			GB.State.track.TaskStartedAt = os.clock()
			GB.Log.log("STATE", "task " .. tostring(name))
		end
		M.task = name
	end

	local function picker()
		local P = getgenv()._GBPicker
		if P and P.pick then
			local ok, r = pcall(P.pick)
			if ok then
				return r
			end
		end
		return nil
	end

	local function nextStory(island, lv)
		for _, ch in ipairs(GB.QuestData.CHAINS) do
			if ch.island == island then
				for _, name in ipairs(ch.order) do
					if not GB.Config.SkipQuests[name] and not GB.PlayerData.finished(name) then
						if GB.PlayerData.live(name) then
							return name
						end
						local need = GB.QuestData.needLevel(name)
						if lv >= need then
							return name
						end
					end
				end
			end
		end
	end

	local function bestRepeat(island, lv)
		local best
		for _, e in ipairs(GB.QuestData.REPEATS) do
			if e.island == island and lv >= (e.accept or 0) and lv <= (e.full_until or 999) then
				if GB.QuestData.prereqOk(e.prereq) then
					if not best or e.exp > best.exp then
						best = e
					end
				end
			end
		end
		return best and best.name
	end

	function M.decide()
		local snap = GB.State.refresh()
		if not snap.Alive then
			setTask("wait_spawn")
			return
		end
		if snap.GameplayPaused then
			setTask("wait_unpause")
			GB.World.waitUnpause()
			return
		end

		-- Recovery
		if GB.Recovery.stuck() then
			setTask("recovery")
			GB.Recovery.run("engine")
			return
		end

		-- Tutorial / live forced
		if GB.Config.AutoTutorial then
			for _, n in ipairs({ "Introduction", "Basics", "[TUTORIAL] Fruit/Style Storage" }) do
				if GB.PlayerData.live(n) then
					setTask("quest:" .. n)
					GB.Quest.doLive(n)
					return
				end
			end
		end

		-- Codes / rewards (rate limited inside)
		if GB.Config.AutoCodes then
			GB.Codes.tick()
		end
		if GB.Config.AutoRewards then
			GB.Rewards.tick()
		end

		-- Mandatory progression purchases
		if GB.Config.AutoShop then
			GB.Shop.tick()
		end

		-- Inventory full: never sell UNKNOWN
		if GB.Inventory.full() then
			GB.Log.warn("STATE", "inventory many items — UNKNOWN kept")
		end

		GB.Equipment.tick()
		GB.Stats.tick()
		GB.Skills.tick()
		GB.Travel.tick()
		GB.Boat.tick()

		-- Live quest first (prefer current-island story, then highest-exp repeat)
		local liveName
		local d = GB.PlayerData.cache()
		if type(d.Quests) == "table" then
			local lives = {}
			for k, q in pairs(d.Quests) do
				local name = type(q) == "table" and (q.Name or k) or k
				if not GB.Config.SkipQuests[name] then
					table.insert(lives, name)
				end
			end
			for _, ch in ipairs(GB.QuestData.CHAINS) do
				if ch.island == snap.CurrentIsland then
					for _, n in ipairs(ch.order) do
						for _, L in ipairs(lives) do
							if L == n then
								liveName = n
								break
							end
						end
						if liveName then
							break
						end
					end
				end
			end
			if not liveName then
				local bestExp = -1
				for _, n in ipairs(lives) do
					for _, e in ipairs(GB.QuestData.REPEATS) do
						if e.name == n and e.exp > bestExp then
							bestExp = e.exp
							liveName = n
						end
					end
				end
				liveName = liveName or lives[1]
			end
		end
		if liveName then
			setTask("quest:" .. liveName)
			GB.Quest.doLive(liveName)
			GB.Chest.tick()
			return
		end

		local pick = picker()
		if pick and pick.name then
			setTask("pick:" .. pick.name)
			GB.Quest.doLive(pick.name)
			return
		end

		local island = snap.CurrentIsland
		local lv = snap.Level or 0
		local story = nextStory(island, lv)
		if story then
			if lv < GB.QuestData.needLevel(story) then
				local rep = bestRepeat(island, lv)
				if rep then
					setTask("repeat:" .. rep)
					GB.Quest.doLive(rep)
					return
				end
				setTask("wait_level:" .. story)
				local rep2 = bestRepeat(island, lv)
				if rep2 then
					GB.Quest.doLive(rep2)
				end
				return
			end
			setTask("story:" .. story)
			GB.Quest.doLive(story)
			return
		end

		local rep = bestRepeat(island, lv)
		if rep then
			setTask("repeat:" .. rep)
			GB.Quest.doLive(rep)
			return
		end

		GB.Boss.tick()
		GB.Fruit.tick()
		GB.Haki.tick()
		GB.RaceTrait.tick()
		GB.Treasure.tick()
		GB.Chest.tick()
		GB.Backpack.tick()
		setTask("idle")
	end

	return M
end
