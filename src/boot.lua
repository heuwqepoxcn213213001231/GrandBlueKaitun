-- Grand Blue (Eternal Pose) — engine boot (developer source)
-- Production is the generated root kaitun.lua (one file, one compile).

return function(GB)
	if type(GB) ~= "table" or type(GB.Config) ~= "table" then
		error("[Kaitun][BOOT] single-file init incomplete — Config missing")
	end
	local fileVer = tostring(GB.Version or getgenv().GB_VERSION or "")
	local genVer = GB.GeneratedData and tostring(GB.GeneratedData.Version or "")
	if genVer and genVer ~= "" and fileVer ~= "" and genVer ~= fileVer then
		error("[Kaitun][BOOT] GeneratedData version mismatch file=" .. fileVer .. " generated=" .. genVer)
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
		local kn = GB.Knowledge and GB.Knowledge.buildContext and GB.Knowledge.buildContext() or nil
		local dump = {
			Version = tostring(GB.Version or getgenv().GB_VERSION or "unknown"),
			Commit = tostring(GB.Build or getgenv().GB_COMMIT or "unknown"),
			BuiltAt = tostring(getgenv().GB_BUILD_AT or "unknown"),
			GeneratedVersion = GB.GeneratedData and GB.GeneratedData.Version or nil,
			GeneratedCommit = GB.GeneratedData and GB.GeneratedData.Commit or nil,
			Fingerprint = fp,
			StartKind = kn and kn.StartKind or (cur and GB.Knowledge and GB.Knowledge.startKind and GB.Knowledge.startKind(cur) or nil),
			QuestSpec = kn and kn.QuestSpec or nil,
			Unfinished = kn and kn.Unfinished or (cur and GB.Quest and GB.Quest.unfinishedConditions and GB.Quest.unfinishedConditions(cur) or nil),
			Subgoals = GB.Planner and GB.Planner.stack or nil,
			CurrentGoal = GB.State.track.TaskName,
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
		GB.Running = false
		getgenv()._GBKaitunGen = (GB.gen or 0) + 1
		if GB.Scheduler then
			GB.Scheduler.stop()
		end
		if GB.Combat then
			pcall(GB.Combat.stopLock)
		end
		if GB.World and GB.World.cancelTween then
			pcall(GB.World.cancelTween)
		end
		if GB.Respawn and GB.Respawn.unbind then
			pcall(GB.Respawn.unbind)
		end
		if GB.Resolver and GB.Resolver.stopIndexes then
			pcall(GB.Resolver.stopIndexes)
		end
		if type(GB.Tasks) == "table" then
			for _, t in ipairs(GB.Tasks) do
				pcall(task.cancel, t)
			end
			GB.Tasks = {}
		end
		local owned = GB.Connections or GB.conns or {}
		for _, c in ipairs(owned) do
			pcall(function()
				c:Disconnect()
			end)
		end
		GB.conns = {}
		GB.Connections = GB.conns
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
		if type(getgenv()._GBKaitunLogFlush) == "function" then
			pcall(getgenv()._GBKaitunLogFlush)
		end
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

	function GB.SelfCheck()
		local snap = GB.State and GB.State.get and GB.State.get() or {}
		local eng = GB.Engine or {}
		local worstName, worstMax
		if GB.Profiler and GB.Profiler.metrics then
			for name, row in pairs(GB.Profiler.metrics) do
				local mx = tonumber(row.max) or 0
				if not worstMax or mx > worstMax then
					worstMax = mx
					worstName = name
				end
			end
		end
		local pending = GB.Broker and GB.Broker.pendingNames and GB.Broker.pendingNames() or {}
		return {
			Enabled = GB.Config and GB.Config.Enabled == true,
			Alive = snap.Alive == true,
			Version = tostring(getgenv().GB_VERSION or "unknown"),
			Build = tostring(getgenv().GB_COMMIT or "unknown"),
			Intent = eng.intent,
			Owner = eng.owner,
			Quest = GB.PlayerData and GB.PlayerData.current and GB.PlayerData.current() or nil,
			FarmSession = eng.farmSession,
			IdleReason = eng.idleReason,
			RemotePending = pending,
			LastProgress = eng._lastRealProgressAt,
			LastProgressAge = eng._lastRealProgressAt and (os.clock() - eng._lastRealProgressAt) or nil,
			ProfilerWorst = worstName and { name = worstName, max = worstMax } or nil,
			IntentSwitchesPerMin = eng.intentSwitchesPerMin and eng.intentSwitchesPerMin() or 0,
		}
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
	getgenv().GB_VERSION = tostring(GB.Version or getgenv().GB_VERSION or "")

	local s = GB.State.refresh()
	local ver = tostring(GB.Version or getgenv().GB_VERSION or "unknown")
	local commit = tostring(GB.Build or getgenv().GB_COMMIT or "unknown")
	local builtAt = tostring(getgenv().GB_BUILD_AT or "unknown")
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
	return GB
end
