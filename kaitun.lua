-- Grand Blue (Eternal Pose) — engine boot
-- Production: run loader.lua (HttpGet). Do not load this file as the one-liner.
-- Modules are injected by the loader. This file only starts the engine.

return function(GB)
	if type(GB) ~= "table" or type(GB.Config) ~= "table" then
		error("[Kaitun][BOOT] run loader.lua — modules not injected")
	end
	local runtimeEnabled = GB.Config.RuntimeDiagnostics ~= false

	local function perfCount(name, n)
		if GB.Profiler and GB.Profiler.count then
			GB.Profiler.count(name, n or 1)
		end
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
		return runtimeEnabled and typeof(writefile) == "function"
	end

	local function ensureFolder(path)
		if typeof(makefolder) == "function" then
			makefolder(path)
		end
	end

	local LOG_RING_MAX = 180
	local LOG_ROTATE_BYTES = math.max(32768, math.floor(tonumber(GB.Config.RuntimeLogMaxBytes) or 262144))
	local LOG_MAX_FILES = math.max(1, math.floor(tonumber(GB.Config.RuntimeLogMaxFiles) or 8))
	local logRing = {}
	local rotatePath = nil
	local rotateIndex = 1
	local rotateBytes = 0
	local lastLatestWriteAt = 0
	local LATEST_WRITE_GAP = 0.8

	local function capNumberMap(map, maxN)
		local n = 0
		local dropKey
		local dropAt
		for k, v in pairs(map) do
			n = n + 1
			local at = tonumber(v) or 0
			if not dropAt or at < dropAt then
				dropAt = at
				dropKey = k
			end
		end
		if n > maxN and dropKey then
			map[dropKey] = nil
		end
	end

	local function ringPush(line)
		logRing[#logRing + 1] = line
		if #logRing > LOG_RING_MAX then
			table.remove(logRing, 1)
		end
	end

	local function runtimeDir()
		local sid = GB.Persist.data and GB.Persist.data.session or "session"
		ensureFolder("GBKaitun")
		ensureFolder("GBKaitun/runtime")
		ensureFolder("GBKaitun/runtime/" .. tostring(sid))
		return "GBKaitun/runtime/" .. tostring(sid)
	end

	local function writeLatest()
		if not canWrite() then
			return
		end
		local now = os.clock()
		if now - (lastLatestWriteAt or 0) < LATEST_WRITE_GAP then
			return
		end
		lastLatestWriteAt = now
		local body = table.concat(logRing, "\n")
		if body ~= "" then
			body = body .. "\n"
		end
		if pcall(writefile, "GBKaitun/runtime/latest.jsonl", body) then
			perfCount("RuntimeFileWrite", 1)
		end
	end

	local function appendRotate(line)
		if not canWrite() or typeof(appendfile) ~= "function" or typeof(isfile) ~= "function" then
			return
		end
		local lineText = tostring(line) .. "\n"
		local lineBytes = #lineText
		local function nextPath()
			rotatePath = string.format("%s/runtime_%03d.jsonl", runtimeDir(), rotateIndex)
			rotateIndex = (rotateIndex % LOG_MAX_FILES) + 1
			rotateBytes = 0
		end
		if rotatePath == nil then
			nextPath()
		end
		if rotateBytes + lineBytes > LOG_ROTATE_BYTES then
			nextPath()
		end
		if rotateBytes <= 0 or not isfile(rotatePath) then
			if pcall(writefile, rotatePath, lineText) then
				rotateBytes = lineBytes
				perfCount("RuntimeFileWrite", 1)
			end
			return
		end
		if pcall(appendfile, rotatePath, lineText) then
			rotateBytes = rotateBytes + lineBytes
			perfCount("RuntimeFileWrite", 1)
		end
	end

	local function appendJsonl(line)
		if not canWrite() then
			return
		end
		ringPush(line)
		appendRotate(line)
		writeLatest()
	end

	local lastDump = nil
	local lastDumpAt = 0
	local lastDumpFp = nil
	local dumpByFingerprint = {}

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
		local blockers = GB.Quest and GB.Quest.CurrentBlockers and GB.Quest.CurrentBlockers() or nil
		local statState = GB.Stats and GB.Stats.ReadStatState and GB.Stats.ReadStatState() or nil
		local statStatus, statReason = "UNRESOLVED", nil
		if GB.Stats and GB.Stats.status then
			statStatus, statReason = GB.Stats.status()
		end
		local fp = string.format(
			"%s|%s|%s|%s",
			tostring(cur),
			tostring(qs and qs.StageIndex or "-"),
			tostring(obj and obj.Type or "-"),
			tostring(tr and tr.LastError or "-")
		)
		local now = os.clock()
		local seenAt = dumpByFingerprint[fp] or 0
		if lastDump and ((lastDumpFp == fp and now - lastDumpAt < 10) or (seenAt > 0 and now - seenAt < 45)) then
			return lastDump
		end
		lastDumpAt = now
		lastDumpFp = fp
		dumpByFingerprint[fp] = now
		capNumberMap(dumpByFingerprint, 120)
		local dump = {
			Version = tostring(getgenv().GB_VERSION or (getgenv()._GBKaitunLoader and getgenv()._GBKaitunLoader.VERSION) or "unknown"),
			Commit = tostring(getgenv()._GBKaitunLoader and getgenv()._GBKaitunLoader.COMMIT or "unknown"),
			BuiltAt = tostring(getgenv()._GBKaitunLoader and getgenv()._GBKaitunLoader.BUILD_AT or "unknown"),
			TutorialDump = GB.DumpTutorialState and GB.DumpTutorialState() or nil,
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
			Blockers = blockers,
			StatSystem = {
				Status = statStatus,
				Reason = statReason,
			},
			Stats = statState and {
				Unused = statState.Unused,
				Strength = statState.Strength,
				Health = statState.Health,
				Willpower = statState.Willpower,
				Agility = statState.Agility,
				Precision = statState.Precision,
				Energy = statState.Energy,
				Source = statState.Source,
			} or nil,
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
		lastDump = dump
		local line = encodeDump(dump)
		if canWrite() then
			ensureFolder("GBKaitun")
			ensureFolder("GBKaitun/runtime")
			appendJsonl(line)
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
		local n = 0
		for _ in pairs(GB.Recovery.deadOnce) do
			n = n + 1
		end
		if n > 80 then
			GB.Recovery.deadOnce = {}
		end
		GB.Recovery.deadOnce[key] = true
		if canWrite() then
			local sid = GB.Persist.data and GB.Persist.data.session or "session"
			ensureFolder("runtime_reports")
			ensureFolder("runtime_reports/" .. sid)
			if pcall(writefile, "runtime_reports/" .. sid .. "/" .. key .. ".json", encodeDump(dump)) then
				perfCount("RuntimeFileWrite", 1)
			end
		end
		GB.Log.err("DIAG", "dead-end " .. key)
		return dump
	end

	local function stopAll(label)
		if GB._stopped then
			return true
		end
		GB._stopped = true
		getgenv()._GBKaitunGen = (GB.gen or 0) + 1
		if GB.Scheduler then
			GB.Scheduler.stop()
		end
		if GB.Combat then
			pcall(GB.Combat.stopLock)
		end
		if GB.Respawn and GB.Respawn.unbind then
			pcall(GB.Respawn.unbind)
		end
		for _, c in ipairs(GB.conns) do
			pcall(function()
				c:Disconnect()
			end)
		end
		GB.conns = {}
		if GB.Profiler and GB.Profiler.report then
			GB.Profiler.report(true)
		end
		if GB.Persist then
			GB.Persist.save()
		end
		if GB.Log and GB.Log.log then
			GB.Log.log("BOOT", tostring(label or "stopped"))
		end
		print("[Kaitun][BOOT] unloaded")
		return true
	end

	function GB.Stop()
		return stopAll("stopped")
	end

	function GB.Destroy()
		return stopAll("destroyed")
	end

	function GB.unload()
		return stopAll("unloaded")
	end

	function GB.ConnectionStats()
		local total = #GB.conns
		local connected = 0
		for _, c in ipairs(GB.conns) do
			local ok, state = pcall(function()
				return c and c.Connected == true
			end)
			if ok and state then
				connected = connected + 1
			end
		end
		local respawn = GB.Respawn and GB.Respawn.connectionCounts and GB.Respawn.connectionCounts() or nil
		return {
			Total = total,
			Connected = connected,
			SchedulerRunning = GB.Scheduler and GB.Scheduler._running == true or false,
			CombatLock = GB.Combat and GB.Combat.lockConn ~= nil or false,
			Respawn = respawn,
		}
	end

	getgenv()._GBKaitunUnload = GB.unload

	if GB.Respawn and GB.Respawn.bind then
		GB.Respawn.bind()
	end

	GB.Scheduler.add("respawn", function()
		if GB.Respawn and GB.Respawn.tick then
			GB.Respawn.tick()
		end
	end, 0.25, { critical = true, first = true })

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

	GB.Scheduler.add("perfCounters", function()
		local cur = tonumber(getgenv()._GBSourceHttpCount) or 0
		local last = tonumber(GB._sourceHttpLast) or cur
		if cur > last then
			perfCount("SourceHttp", cur - last)
		end
		GB._sourceHttpLast = cur
	end, 1.0)

	GB._sourceHttpBoot = tonumber(getgenv()._GBSourceHttpCount) or 0
	GB._sourceHttpLast = GB._sourceHttpBoot
	getgenv()._GBSourceHttpBase = GB._sourceHttpBoot

	GB.Scheduler.start()

	function GB.DumpTutorialState()
		if GB.Tutorial and GB.Tutorial.DumpTutorialState then
			return GB.Tutorial.DumpTutorialState()
		end
		return nil
	end

	getgenv().GBKaitun = GB
	getgenv().GBConfig = GB.Config
	getgenv().GB_VERSION = (getgenv()._GBKaitunLoader and getgenv()._GBKaitunLoader.VERSION) or getgenv().GB_VERSION

	local s = GB.State.refresh()
	local loaderMeta = getgenv()._GBKaitunLoader or {}
	local ver = tostring(loaderMeta.VERSION or getgenv().GB_VERSION or "unknown")
	local commit = tostring(loaderMeta.COMMIT or "unknown")
	local builtAt = tostring(loaderMeta.BUILD_AT or "unknown")
	getgenv().GB_VERSION = ver
	getgenv().GB_COMMIT = commit
	GB.Log.log(
		"BOOT",
		string.format(
			"v%s commit=%s built=%s lv%s island=%s gold=%s",
			ver,
			commit,
			builtAt,
			tostring(s.Level),
			tostring(s.CurrentIsland),
			tostring(s.Gold)
		)
	)
	GB.Log.log("PERF", "SourceHttpAfterBoot=0")
	print(string.format("[Kaitun][BOOT] version=%s build=%s", ver, commit))
	return GB
end
