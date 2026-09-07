-- Grand Blue (Eternal Pose) — engine boot
-- Production: run loader.lua (HttpGet). Do not load this file as the one-liner.
-- Modules are injected by the loader. This file only starts the engine.

return function(GB)
	if type(GB) ~= "table" or type(GB.Config) ~= "table" then
		error("[Kaitun][BOOT] run loader.lua — modules not injected")
	end

	GB.Persist.load()
	GB.Remotes.statReplicate()
	if GB.PlayerData.hookQuestEvents then
		GB.PlayerData.hookQuestEvents()
	end
	GB.PlayerData.refreshLive(true)
	local ck = GB.Persist.data and GB.Persist.data.checkpoint
	if ck and ck.quest then
		GB.Log.log("BOOT", "checkpoint quest=" .. tostring(ck.quest) .. " stage=" .. tostring(ck.stage or "-"))
	end

	local function encodeDump(t)
		local Http = game:GetService("HttpService")
		return Http:JSONEncode(t)
	end

	local function canWrite()
		return typeof(writefile) == "function"
	end

	local function ensureFolder(path)
		if typeof(makefolder) == "function" then
			makefolder(path)
		end
	end

	local function appendJsonl(path, line)
		if not canWrite() then
			return
		end
		local prev = ""
		if typeof(isfile) == "function" and isfile(path) and typeof(readfile) == "function" then
			prev = readfile(path)
			if type(prev) ~= "string" then
				prev = ""
			end
		end
		writefile(path, prev .. line .. "\n")
	end

	local function invSummary()
		local rows = {}
		if not (GB.Inventory and GB.Inventory.list) then
			return rows
		end
		for _, r in ipairs(GB.Inventory.list()) do
			rows[#rows + 1] = { name = r.name, amount = r.amount }
		end
		return rows
	end

	function GB.DumpRuntimeIssue()
		local snap = GB.State.get()
		local cur = GB.PlayerData.current()
		local qs = cur and GB.Quest.questState(cur)
		local tr = cur and GB.Quest.trackOf(cur)
		local plan = GB.Planner and GB.Planner.last
		local obj = qs and qs.Objective
		local dump = {
			Version = tostring(getgenv().GB_VERSION or "1.1.4"),
			PlaceId = game.PlaceId,
			Level = snap.Level,
			Island = snap.CurrentIsland,
			Quest = cur,
			Stage = qs and qs.StageIndex,
			Objective = obj and {
				Type = obj.Type,
				Target = obj.TargetName,
				Current = obj.Current,
				Amount = obj.Amount,
			} or nil,
			Plan = plan and {
				Goal = plan.Goal,
				Target = plan.Target,
				Method = plan.Method,
				Source = plan.Source,
			} or nil,
			Target = obj and obj.TargetName,
			Item = GB.Acquire and GB.Acquire.lastItem,
			Attempts = tr and tr.AttemptCount,
			LastProgress = GB.State.track.QuestProgress,
			LastError = tr and tr.LastError,
			Strategy = GB.Recovery and GB.Recovery.currentStrategy and GB.Recovery.currentStrategy(),
			ResolverCandidates = GB.Resolver.lastCandidates,
			Inventory = invSummary(),
			Equip = snap.Weapon,
			EquipmentState = snap.EquipmentState,
			UI = snap.UI,
			Tutorial = GB.Tutorial and GB.Tutorial.dump and GB.Tutorial.dump() or nil,
			BackpackOpen = snap.UI and snap.UI.BackpackOpen,
			Held = GB.Equipment and GB.Equipment.heldName and GB.Equipment.heldName(),
			CombatTarget = GB.Combat and GB.Combat.lockMob and GB.Combat.lockMob.Name,
			TargetAlive = GB.Combat and GB.Combat.lockMob and GB.Combat.IsEnemyAlive and GB.Combat.IsEnemyAlive(GB.Combat.lockMob),
		}
		GB.Log.warn("DIAG", string.format("DumpRuntimeIssue quest=%s stage=%s", tostring(cur), tostring(dump.Stage)))
		local line = encodeDump(dump)
		if canWrite() then
			ensureFolder("GBKaitun")
			ensureFolder("GBKaitun/runtime")
			appendJsonl("GBKaitun/runtime/latest.jsonl", line)
			local sid = GB.Persist.data and GB.Persist.data.session or "session"
			appendJsonl("GBKaitun/runtime/" .. sid .. ".jsonl", line)
		end
		return dump
	end

	function GB.WriteDeadEnd()
		local dump = GB.DumpRuntimeIssue()
		local q = tostring(dump.Quest or "unknown"):gsub("[^%w _%-]", "_")
		local st = tostring(dump.Stage or 0)
		local key = q .. "_" .. st
		if GB.Recovery.deadOnce[key] then
			return dump
		end
		GB.Recovery.deadOnce[key] = true
		if canWrite() then
			local sid = GB.Persist.data and GB.Persist.data.session or "session"
			ensureFolder("runtime_reports")
			ensureFolder("runtime_reports/" .. sid)
			writefile("runtime_reports/" .. sid .. "/" .. key .. ".json", encodeDump(dump))
		end
		GB.Log.err("DIAG", "dead-end " .. key)
		return dump
	end

	function GB.unload()
		getgenv()._GBKaitunGen = (GB.gen or 0) + 1
		if GB.Scheduler then
			GB.Scheduler.stop()
		end
		if GB.Combat then
			pcall(GB.Combat.stopLock)
		end
		for _, c in ipairs(GB.conns) do
			pcall(function()
				c:Disconnect()
			end)
		end
		GB.conns = {}
		if GB.Persist then
			GB.Persist.save()
		end
		print("[Kaitun][BOOT] unloaded")
	end

	getgenv()._GBKaitunUnload = GB.unload

	GB.conns[#GB.conns + 1] = GB.lp.CharacterAdded:Connect(function()
		task.wait(0.4)
		if GB.dead() then
			return
		end
		GB.Cache.invalidate()
		GB.Remotes.statReplicate()
		if GB.Combat then
			GB.Combat.stopLock()
		end
		GB.Log.log("STATE", "respawn")
	end)

	GB.Scheduler.add("recovery", function()
		GB.Recovery.tick()
		GB.World.rememberSafe()
	end, 0.5)

	GB.Scheduler.add("combat", function()
		GB.Combat.tick()
	end, 0.2)

	GB.Scheduler.add("engine", function()
		GB.Engine.decide()
	end, 0)

	GB.Scheduler.start()

	getgenv().GBKaitun = GB
	getgenv().GBConfig = GB.Config
	getgenv().GB_VERSION = getgenv().GB_VERSION or (getgenv()._GBKaitunLoader and getgenv()._GBKaitunLoader.VERSION)

	local s = GB.State.refresh()
	GB.Log.log("BOOT", string.format("lv%s island=%s gold=%s", tostring(s.Level), tostring(s.CurrentIsland), tostring(s.Gold)))
	print("[Kaitun][BOOT] ready — GBKaitun / GBConfig / GB_VERSION")
	return GB
end
