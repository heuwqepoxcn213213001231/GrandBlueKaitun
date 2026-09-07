-- Grand Blue Kaitun bundle (generated).
-- Version: 1.1.18
-- Commit: 75ee423
-- BuiltAt: 2026-09-08T02:47:11+07:00
-- Source: heuwqepoxcn213213001231/GrandBlueKaitun@main

return function(meta)
	if type(getgenv) ~= "function" then
		error("[Kaitun][Bundle] getgenv missing")
	end
	if type(loadstring) ~= "function" then
		error("[Kaitun][Bundle] loadstring missing")
	end

	local function stopPreviousInstance()
		local prev = getgenv().GBKaitun
		local stopped = false
		if type(prev) == "table" then
			if type(prev.Stop) == "function" then
				pcall(prev.Stop)
				stopped = true
			elseif type(prev.Destroy) == "function" then
				pcall(prev.Destroy)
				stopped = true
			end
		end
		if not stopped and type(getgenv()._GBKaitunUnload) == "function" then
			pcall(getgenv()._GBKaitunUnload)
			stopped = true
		end
		if stopped then
			task.wait(0.12)
		end
	end

	stopPreviousInstance()

	local BUILD_VERSION = "1.1.18"
	local BUILD_COMMIT = "75ee423"
	local BUILD_AT = "2026-09-08T02:47:11+07:00"
	local GEN = (tonumber(getgenv()._GBKaitunGen) or 0) + 1
	getgenv()._GBKaitunGen = GEN

	local function dead()
		return getgenv()._GBKaitunGen ~= GEN
	end

	local files = {
    ["Config.lua"] = [[-- Grand Blue Kaitun — Config
-- Override via getgenv().GBConfig before load, or mutate after.

return function(GB)
	local C = getgenv().GBConfig
	if type(C) ~= "table" then
		C = {}
		getgenv().GBConfig = C
	end

	local function def(k, v)
		if C[k] == nil then
			C[k] = v
		end
	end

	def("Enabled", true)
	def("Tick", 0.4)
	def("LogLevel", "INFO") -- DEBUG INFO WARN ERROR
	def("Debug", false)
	def("Persist", true)

	-- Auto flags
	def("AutoQuest", true)
	def("AutoLevel", true)
	def("AutoCombat", true)
	def("AutoStats", true)
	def("AutoSkills", true)
	def("AutoEquip", true)
	def("AutoShop", true)
	def("AutoTravel", true)
	def("AutoBoat", true)
	def("AutoInventory", true)
	def("AutoBackpack", false) -- slot-upgrade UNRESOLVED; Open/Equip still used by Tutorial/Equipment
	def("AutoFruit", true)
	def("AutoHaki", false) -- trainer UNRESOLVED
	def("AutoRaceTrait", false) -- default off; no spam reroll
	def("StoryFirst", true) -- Fruit/Haki/Race do not interrupt story
	def("AutoBoss", true)
	def("AutoChest", true)
	def("AutoTreasure", true)
	def("AutoMining", true)
	def("AutoFishing", true)
	def("AutoFarming", true)
	def("AutoCooking", true)
	def("AutoCodes", true)
	def("AutoRewards", true)
	def("AutoTutorial", true)

	-- Build: Melee | Balanced | Strength | Sword | Gun | Fruit | Hybrid
	-- StatRatio is live current totals, not a dump of unused points. 8 Str : 2 Health.
	def("Build", "Melee")
	def("StatRatio", { Strength = 8, Health = 2 })
	def("FruitMode", "KEEP_CURRENT") -- KEEP_CURRENT | DesiredFruits
	def("DesiredFruits", { "Flame", "Darkness", "Light", "Chop" })

	def("Codes", {
		"Release!",
		"HappySunday",
		"TwitterGoalReached",
		"SorryForBreakingGame",
		"10KCCU",
		"WorldBossBroke",
		"NewYouNewCrew",
		"FruitBasket",
	})

	def("TalkRange", 14)
	def("TalkOffset", 5)
	def("CombatRange", 5.5)
	def("DummyBeside", 3.2)
	def("ShootRange", 9)
	def("QuestMaxRetries", 5)
	def("ResolveDeepAfter", 3)
	def("DestYMin", 0)
	def("DestYMax", 180)
	def("MoveHop", 45)
	def("TweenSpeed", 95)
	def("TweenMaxDur", 1.8)
	def("StuckSeconds", 18)
	def("RecoveryCooldown", 8)
	def("ActionTimeout", 25)
	def("MaxRetries", 3)
	def("QuestMaxAcquireCycles", 8)
	def("DropWindow", 4)

	-- HARD: do not skip these after RE
	def("NeverSkip", {
		["Escort The Mayor"] = true,
		["The Wandering Hypnotist"] = true,
	})

	-- Skip test / archived / empty stubs
	def("SkipQuests", {
		["Debug Quest"] = true,
		["Debug Quest 2"] = true,
		["Daily Quest Test"] = true,
		["Weekly Quest Test"] = true,
		["Jack's Daily Haul"] = true,
		["Kim Wu's Daily Quota"] = true,
		["Joe's Daily Chores"] = true,
		["Remy's Daily Order"] = true,
		["The Stolen Tip Jar"] = true,
		["Officer Investigation"] = true,
		["Leveling Skill"] = true,
		["Aim Training"] = true,
	})

	return C
end
]],
    ["Core/Cache.lua"] = [[-- World / scan cache. Refresh on island, quest, target-lost, timeout, state change.

return function(GB)
	local M = {
		_store = {},
		_at = {},
	}

	local DEFAULT_TTL = 2.5

	function M.get(key, ttl)
		local row = M._store[key]
		if not row then
			return nil
		end
		if os.clock() - (M._at[key] or 0) > (ttl or DEFAULT_TTL) then
			return nil
		end
		return row
	end

	function M.set(key, value)
		M._store[key] = value
		M._at[key] = os.clock()
		return value
	end

	function M.invalidate(key)
		if key then
			M._store[key] = nil
			M._at[key] = nil
			return
		end
		M._store = {}
		M._at = {}
	end

	function M.memo(key, ttl, fn)
		local hit = M.get(key, ttl)
		if hit ~= nil then
			return hit
		end
		local v = fn()
		if v ~= nil then
			M.set(key, v)
		end
		return v
	end

	return M
end
]],
    ["Core/Logger.lua"] = [[-- [Kaitun][CAT] message

return function(GB)
	local LEVEL = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 }
	local last = {}
	local order = {}
	local MAX_KEYS = 720
	local M = {}

	local function dedupeKey(cat, msg)
		local m = tostring(msg)
		m = string.gsub(m, "%d%d%d%d+", "<n>")
		if #m > 180 then
			m = string.sub(m, 1, 180)
		end
		return tostring(cat) .. "|" .. m
	end

	local function rememberKey(key, now)
		if last[key] == nil then
			order[#order + 1] = key
		end
		last[key] = now
		if #order <= MAX_KEYS then
			return
		end
		local drop = table.remove(order, 1)
		if drop then
			last[drop] = nil
		end
	end

	function M.log(cat, msg, lvl)
		lvl = lvl or "INFO"
		local want = LEVEL[GB.Config.LogLevel or "INFO"] or 2
		if (LEVEL[lvl] or 2) < want then
			return
		end
		local line = string.format("[Kaitun][%s] %s", cat, tostring(msg))
		local key = dedupeKey(cat, msg)
		local now = os.clock()
		local gap = 2.5
		if cat == "ERROR" then
			gap = 8
		elseif cat == "PLAN" or cat == "ACQUIRE" or cat == "DROP" or cat == "PICKUP" then
			gap = 1.1
		elseif cat == "STATE" and string.find(tostring(msg), "doing=", 1, true) then
			gap = 1.1
		elseif cat == "GATE" or cat == "UI" then
			gap = 1.4
		elseif cat == "COMBAT" then
			local m = tostring(msg)
			if string.find(m, "dead", 1, true) or string.find(m, "Clearing", 1, true) or string.find(m, "Target ", 1, true) then
				gap = 0.8
			end
		elseif cat == "QUEST" then
			local m = tostring(msg)
			if string.find(m, "not credited", 1, true) or string.find(m, "resolve miss", 1, true) then
				gap = 8
			end
		end
		if last[key] and now - last[key] < gap then
			return
		end
		rememberKey(key, now)
		print(line)
	end

	function M.debug(cat, msg)
		M.log(cat, msg, "DEBUG")
	end

	function M.warn(cat, msg)
		M.log(cat, msg, "WARN")
	end

	function M.err(cat, msg)
		M.log(cat, msg, "ERROR")
	end

	return M
end
]],
    ["Core/Persist.lua"] = [[-- Optional persist. writefile/readfile if present; no crash without FS.
-- Live PlayerState always wins.

return function(GB)
	local M = {
		path = "GBKaitun_persist.json",
		data = {
			codes = {},
			checkpoint = {},
			failedRemotes = {},
			session = nil,
		},
	}

	local function canIO()
		return typeof(isfile) == "function" and typeof(readfile) == "function" and typeof(writefile) == "function"
	end

	local function encode(t)
		local ok, Http = pcall(function()
			return game:GetService("HttpService")
		end)
		if ok and Http then
			local s, r = pcall(Http.JSONEncode, Http, t)
			if s then
				return r
			end
		end
		return nil
	end

	local function decode(s)
		local ok, Http = pcall(function()
			return game:GetService("HttpService")
		end)
		if ok and Http then
			local s2, r = pcall(Http.JSONDecode, Http, s)
			if s2 and type(r) == "table" then
				return r
			end
		end
		return nil
	end

	function M.load()
		if not M.data.session then
			M.data.session = "s" .. tostring(os.time())
		end
		if not GB.Config.Persist or not canIO() then
			return
		end
		if isfile(M.path) then
			local raw = readfile(M.path)
			local t = decode(raw)
			if type(t) == "table" then
				if type(t.codes) == "table" then
					M.data.codes = t.codes
				end
				if type(t.checkpoint) == "table" then
					M.data.checkpoint = t.checkpoint
				end
				if type(t.failedRemotes) == "table" then
					M.data.failedRemotes = t.failedRemotes
				end
				if type(t.session) == "string" then
					M.data.session = t.session
				end
			end
		end
		if not M.data.session then
			M.data.session = "s" .. tostring(os.time())
		end
		if type(getgenv().GBCodes) == "table" then
			for k, v in pairs(getgenv().GBCodes) do
				M.data.codes[k] = v
			end
		end
		getgenv().GBCodes = M.data.codes
	end

	function M.save()
		if not GB.Config.Persist or not canIO() then
			return
		end
		local s = encode(M.data)
		if s then
			pcall(writefile, M.path, s)
		end
	end

	function M.codeState(code, state)
		M.data.codes[code] = {
			state = state,
			at = os.time(),
		}
		getgenv().GBCodes = M.data.codes
		M.save()
	end

	function M.failRemote(name, why)
		M.data.failedRemotes[name] = {
			why = tostring(why),
			at = os.time(),
		}
		M.save()
	end

	function M.checkpoint(key, value)
		M.data.checkpoint[key] = value
		M.save()
	end

	return M
end
]],
    ["Core/Profiler.lua"] = [[-- Lightweight runtime profiler + per-minute counters.
-- Uses os.clock(), reports only in PerfDebug windows.

return function(GB)
	local M = {
		metrics = {},
		metricOrder = {},
		counters = {},
		counterOrder = {},
		windowAt = os.clock(),
		lastReportAt = os.clock(),
		lastSpikeAt = {},
	}

	local METRIC_LIMIT = 160
	local COUNTER_LIMIT = 200
	local SPIKE_GAP = 8
	local COUNTER_REPORT_ORDER = {
		"SourceHttp",
		"GetDataQuests",
		"GetStats",
		"StatInvest",
		"PlayerGuiFullScan",
		"QuestGuiScan",
		"WorkspaceDeepScan",
		"ResolverDeepScan",
		"getgc",
		"getconnections",
		"RuntimeFileWrite",
		"PersistWrite",
		"HeartbeatQuestCheck",
		"PlayerDataRefresh",
	}

	local function capOrder(order, map, maxN)
		while #order > maxN do
			local key = table.remove(order, 1)
			if key ~= nil then
				map[key] = nil
			end
		end
	end

	local function metricRow(name)
		local row = M.metrics[name]
		if row then
			return row
		end
		row = {
			count = 0,
			total = 0,
			max = 0,
			over8ms = 0,
			over16ms = 0,
			over33ms = 0,
		}
		M.metrics[name] = row
		M.metricOrder[#M.metricOrder + 1] = name
		capOrder(M.metricOrder, M.metrics, METRIC_LIMIT)
		return row
	end

	local function counterRow(name)
		local row = M.counters[name]
		if row then
			return row
		end
		row = { total = 0, window = 0 }
		M.counters[name] = row
		M.counterOrder[#M.counterOrder + 1] = name
		capOrder(M.counterOrder, M.counters, COUNTER_LIMIT)
		return row
	end

	local function shouldReport()
		if not (GB.Config and GB.Config.PerfDebug == true) then
			return false
		end
		local now = os.clock()
		local every = tonumber(GB.Config.PerfReportInterval) or 15
		return now - M.lastReportAt >= math.max(3, every)
	end

	local function metricMs(v)
		return string.format("%.2f", (tonumber(v) or 0) * 1000)
	end

	local function resetWindow()
		M.windowAt = os.clock()
		M.lastReportAt = M.windowAt
		for _, row in pairs(M.metrics) do
			row.count = 0
			row.total = 0
			row.max = 0
			row.over8ms = 0
			row.over16ms = 0
			row.over33ms = 0
		end
		for _, row in pairs(M.counters) do
			row.window = 0
		end
	end

	function M.begin()
		return os.clock()
	end

	function M.count(name, n)
		if type(name) ~= "string" or name == "" then
			return
		end
		n = tonumber(n) or 1
		if n == 0 then
			return
		end
		local row = counterRow(name)
		row.total = row.total + n
		row.window = row.window + n
	end

	function M.done(name, startedAt)
		if type(name) ~= "string" or name == "" or type(startedAt) ~= "number" then
			return 0
		end
		local dt = os.clock() - startedAt
		if dt < 0 then
			dt = 0
		end
		local row = metricRow(name)
		row.count = row.count + 1
		row.total = row.total + dt
		if dt > row.max then
			row.max = dt
		end
		if dt >= 0.008 then
			row.over8ms = row.over8ms + 1
		end
		if dt >= 0.016 then
			row.over16ms = row.over16ms + 1
			local now = os.clock()
			local last = M.lastSpikeAt[name] or 0
			if (GB.Config and GB.Config.PerfDebug == true) or dt >= 0.033 then
				if now - last >= SPIKE_GAP then
					M.lastSpikeAt[name] = now
					print(string.format("[Kaitun][PERF][SPIKE] %s %sms", name, metricMs(dt)))
				end
			end
		end
		if dt >= 0.033 then
			row.over33ms = row.over33ms + 1
		end
		return dt
	end

	function M.wrap(name, fn, ...)
		if type(fn) ~= "function" then
			return nil
		end
		local t0 = M.begin()
		local out = { pcall(fn, ...) }
		M.done(name, t0)
		if not out[1] then
			error(out[2])
		end
		return unpack(out, 2)
	end

	function M.snapshot()
		return {
			windowAt = M.windowAt,
			lastReportAt = M.lastReportAt,
			metrics = M.metrics,
			counters = M.counters,
		}
	end

	function M.report(force)
		if not force and not shouldReport() then
			return
		end
		local now = os.clock()
		local elapsed = math.max(0.001, now - M.windowAt)
		if GB.Log and GB.Log.log then
			GB.Log.log("PERF", string.format("window=%.1fs metrics=%d counters=%d", elapsed, #M.metricOrder, #M.counterOrder))
			local base = tonumber(getgenv()._GBSourceHttpBase)
			local current = tonumber(getgenv()._GBSourceHttpCount)
			if base and current then
				local afterBoot = math.max(0, current - base)
				GB.Log.log("PERF", string.format("SourceHttpAfterBoot=%d", afterBoot))
			end
		end

		local ranked = {}
		for _, name in ipairs(M.metricOrder) do
			local row = M.metrics[name]
			if row and row.count > 0 then
				ranked[#ranked + 1] = { name = name, row = row }
			end
		end
		table.sort(ranked, function(a, b)
			if a.row.total ~= b.row.total then
				return a.row.total > b.row.total
			end
			return a.name < b.name
		end)
		for i = 1, math.min(#ranked, 24) do
			local item = ranked[i]
			local row = item.row
			local avg = row.total / math.max(1, row.count)
			GB.Log.log(
				"PERF",
				string.format(
					"%s count=%d avg=%sms max=%sms >8=%d >16=%d >33=%d",
					item.name,
					row.count,
					metricMs(avg),
					metricMs(row.max),
					row.over8ms,
					row.over16ms,
					row.over33ms
				)
			)
		end

		local printed = {}
		for _, name in ipairs(COUNTER_REPORT_ORDER) do
			local row = counterRow(name)
			local perMin = row.window * 60 / elapsed
			GB.Log.log("PERF", string.format("%s=%s (%.1f/min)", name, tostring(row.window), perMin))
			printed[name] = true
		end
		for _, name in ipairs(M.counterOrder) do
			if not printed[name] then
				local row = M.counters[name]
				if row and row.window ~= 0 then
					local perMin = row.window * 60 / elapsed
					GB.Log.log("PERF", string.format("%s=%s (%.1f/min)", name, tostring(row.window), perMin))
				end
			end
		end
		resetWindow()
	end

	function M.tick()
		M.report(false)
	end

	resetWindow()
	return M
end
]],
    ["Core/Recovery.lua"] = [[-- Stuck: change strategy. lookup drop → enemy → diagnostic → blocker.
-- Teleport/talk/log is not progress. Void rescue stays on tick.

return function(GB)
	local M = {
		last = 0,
		level = 0,
		reason = nil,
		si = 1,
		deadOnce = {},
		outcome = nil,
	}

	M.STRATS = { "lookup", "enemy", "diagnostic", "blocker" }

	function M.currentStrategy()
		return M.STRATS[M.si] or "lookup"
	end

	function M.resetStrategy()
		M.si = 1
	end

	function M.advanceStrategy()
		if M.si < #M.STRATS then
			M.si = M.si + 1
		end
		return M.currentStrategy()
	end

	function M.markSuccess()
		GB.State.track.SuccessfulAction = os.clock()
		M.level = 0
		M.reason = nil
		M.outcome = nil
		M.resetStrategy()
	end

	function M.stuck()
		local tr = GB.State.track
		local cfg = GB.Config
		local now = os.clock()
		if now - M.last < (cfg.RecoveryCooldown or 8) then
			return false
		end
		local started = tr.TaskStartedAt or 0
		if started == 0 then
			return false
		end
		local idle = now - math.max(tr.SuccessfulAction or 0, tr.StateChange or 0, started)
		return idle >= (cfg.StuckSeconds or 18)
	end

	function M.run(why)
		if os.clock() - M.last < (GB.Config.RecoveryCooldown or 8) then
			return
		end
		local gate = GB.Tutorial and GB.Tutorial.GetCurrentGate and GB.Tutorial.GetCurrentGate()
		if gate and GB.Tutorial.GateTypes and gate.Type == GB.Tutorial.GateTypes.ContinueOverlay then
			if os.clock() - (M.lastSkipAt or 0) > 8 then
				M.lastSkipAt = os.clock()
				GB.Log.warn("RECOVERY", "skip ContinueOverlay " .. tostring(gate.Id))
			end
			M.last = os.clock()
			return
		end
		if M.outcome == "BLOCKING_GATE_UNRESOLVED" then
			GB.Log.warn("RECOVERY", "BLOCKING_GATE_UNRESOLVED keep")
			return
		end
		local gkey = gate and (tostring(gate.Type) .. "|" .. tostring(gate.Id) .. "|" .. tostring(gate.Payload))
		if gkey and M.lastGateKey == gkey and M.outcome == "BLOCKING_UI" then
			return
		end
		M.lastGateKey = gkey
		M.last = os.clock()
		M.level = M.level + 1
		M.reason = why
		local cur0 = GB.PlayerData and GB.PlayerData.current and GB.PlayerData.current()
		if cur0 and GB.Quest and GB.Quest.deferred and select(1, GB.Quest.deferred(cur0)) then
			GB.Log.warn("RECOVERY", "defer " .. tostring(cur0))
			M.markSuccess()
			return
		end
		local strat = M.currentStrategy()
		if M.level > 1 then
			strat = M.advanceStrategy()
		end
		local cur = GB.PlayerData and GB.PlayerData.current and GB.PlayerData.current()
		local qs = cur and GB.Quest and GB.Quest.questState and GB.Quest.questState(cur)
		local o = qs and qs.Objective
		if o and (o.Type == "Unlock" or o.Type == "Loot" or o.Type == "Open" or o.Type == "Interact") then
			if strat == "enemy" then
				strat = M.advanceStrategy()
			end
		end
		GB.Log.warn("RECOVERY", string.format("level=%d strategy=%s %s", M.level, tostring(strat), tostring(why)))
		GB.Cache.invalidate()

		if strat == "lookup" or strat == "enemy" then
			GB.State.track.TaskStartedAt = os.clock()
			return
		end

		if GB.Combat then
			GB.Combat.stopLock()
		end

		if M.outcome == "BLOCKING_GATE_UNRESOLVED" then
			GB.Log.warn("RECOVERY", "BLOCKING_GATE_UNRESOLVED keep")
			return
		end

		if strat == "diagnostic" then
			if GB.Tutorial and GB.Tutorial.unresolved then
				M.outcome = "BLOCKING_GATE_UNRESOLVED"
				GB.Log.warn("RECOVERY", "BLOCKING_GATE_UNRESOLVED")
				if GB.Tutorial.DumpTutorialState then
					GB.Tutorial.DumpTutorialState()
				end
				return
			end
			if GB.Tutorial and GB.Tutorial.IsBlocking and select(1, GB.Tutorial.IsBlocking()) then
				M.outcome = "BLOCKING_UI"
				local step = GB.Tutorial.GetActiveStep and GB.Tutorial.GetActiveStep()
				GB.Log.warn("RECOVERY", "BLOCKING_UI " .. tostring(step))
				M.resetStrategy()
				GB.State.track.TaskStartedAt = os.clock()
				return
			end
			if GB.DumpRuntimeIssue then
				GB.DumpRuntimeIssue()
			end
			M.resetStrategy()
			GB.State.track.TaskStartedAt = os.clock()
			return
		end
		-- blocker: dump once, then resume hunt next tick
		if GB.WriteDeadEnd then
			GB.WriteDeadEnd()
		end
		local q = GB.State.snap.CurrentQuest
		if q and GB.Config.NeverSkip[q] then
			GB.Log.warn("RECOVERY", "keep " .. q)
		end
		M.resetStrategy()
		M.level = 0
		GB.State.track.TaskStartedAt = os.clock()
	end

	function M.tick()
		if M.stuck() then
			M.run("stuck " .. tostring(GB.State.track.TaskName))
		end
		if GB.World then
			GB.World.rescue()
		end
	end

	return M
end
]],
    ["Core/Retry.lua"] = [[-- RunAction: Timeout, MaxRetries, Validate, Recovery. No infinite retry.

return function(GB)
	local M = {}
	local lastFire = {}

	function M.rateOk(key, gap)
		gap = gap or 0.6
		local t = lastFire[key] or 0
		if os.clock() - t < gap then
			return false
		end
		lastFire[key] = os.clock()
		return true
	end

	function M.mark(key)
		lastFire[key] = os.clock()
	end

	function M.run(opts)
		opts = opts or {}
		local name = opts.Name or "action"
		local timeout = opts.Timeout or GB.Config.ActionTimeout or 25
		local tries = opts.MaxRetries or GB.Config.MaxRetries or 3
		local exec = opts.Execute
		local validate = opts.Validate
		local recover = opts.Recovery
		if type(exec) ~= "function" then
			return false, "no execute"
		end
		local lastErr
		for i = 1, tries do
			if GB.dead and GB.dead() then
				return false, "unloaded"
			end
			local t0 = os.clock()
			local ok, err = pcall(exec, i)
			if not ok then
				lastErr = err
				GB.Log.warn("ERROR", name .. " pcall " .. tostring(err))
			elseif validate then
				local vok, vmsg
				repeat
					if os.clock() - t0 > timeout then
						vok, vmsg = false, "timeout"
						break
					end
					local v2, m2 = pcall(validate)
					if v2 and m2 then
						vok = true
						break
					end
					vok, vmsg = false, m2 or "validate"
					task.wait(0.2)
				until GB.dead and GB.dead()
				if vok then
					return true
				end
				lastErr = vmsg
			elseif ok then
				return true
			end
			if recover and i < tries then
				pcall(recover, i, lastErr)
			end
			task.wait(0.25)
		end
		return false, lastErr
	end

	return M
end
]],
    ["Core/Scheduler.lua"] = [[-- Tick loop. No giant while-true spaghetti in systems.

return function(GB)
	local M = {
		_jobs = {},
		_order = {},
		_conn = nil,
		_last = 0,
		_running = false,
	}

	function M.add(name, fn, every)
		M._jobs[name] = {
			fn = fn,
			every = every or 0,
			at = 0,
		}
		local found
		for _, n in ipairs(M._order) do
			if n == name then
				found = true
				break
			end
		end
		if not found then
			table.insert(M._order, name)
		end
	end

	function M.remove(name)
		M._jobs[name] = nil
	end

	function M.step()
		if not GB.Config.Enabled then
			return
		end
		if GB.dead and GB.dead() then
			return
		end
		local now = os.clock()
		for _, name in ipairs(M._order) do
			local j = M._jobs[name]
			if j and now - j.at >= (j.every or 0) then
				j.at = now
				local ok, err = pcall(j.fn)
				if not ok then
					GB.Log.err("ERROR", name .. " " .. tostring(err))
				end
			end
		end
	end

	function M.start()
		if M._running then
			return
		end
		M._running = true
		task.spawn(function()
			while M._running and not (GB.dead and GB.dead()) do
				M.step()
				task.wait(GB.Config.Tick or 0.4)
			end
		end)
	end

	function M.stop()
		M._running = false
	end

	return M
end
]],
    ["Core/State.lua"] = [[-- Unified PlayerState snapshot. All decisions read this.

return function(GB)
	local M = {
		snap = {},
		prev = {},
		_overlayKnown = {},
		_overlayHooked = false,
		_overlayDirty = true,
		_overlayVisible = false,
		_overlayVisibleUi = nil,
		_overlayVisibleAt = 0,
		_overlayLastScanAt = 0,
		_continueHandlers = {},
		_continueRetryAt = {},
		track = {
			LastPosition = nil,
			Level = 0,
			EXP = 0,
			Gold = 0,
			StatPoints = 0,
			Strength = 0,
			Health = 0,
			CurrentQuest = nil,
			QuestProgress = "",
			Kill = 0,
			SuccessfulAction = 0,
			StateChange = 0,
			TaskStartedAt = 0,
			TaskName = nil,
		},
	}

	local STATS = { "Health", "Strength", "Agility", "Precision", "Energy", "Willpower" }

	local function readTextProp(inst)
		if inst and (inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox")) then
			local t = inst.Text
			if type(t) == "string" then
				return t
			end
		end
		return nil
	end

	-- Never index .Text on ImageButton / Frame. DialogueUI NodeFrame: text is sibling TextLabel.
	local function guiText(inst)
		if not inst then
			return nil
		end
		local direct = readTextProp(inst)
		if direct and direct ~= "" then
			return direct
		end
		local named = inst:FindFirstChild("TextLabel")
		local fromNamed = readTextProp(named)
		if fromNamed and fromNamed ~= "" then
			return fromNamed
		end
		local deep = inst:FindFirstChildWhichIsA("TextLabel", true)
		local fromDeep = readTextProp(deep)
		if fromDeep and fromDeep ~= "" then
			return fromDeep
		end
		local parent = inst.Parent
		if parent then
			local sib = readTextProp(parent:FindFirstChild("TextLabel"))
			if sib and sib ~= "" then
				return sib
			end
		end
		local attr = inst:GetAttribute("Text")
		if type(attr) == "string" and attr ~= "" then
			return attr
		end
		return direct
	end

	local function guiNum(inst)
		if not inst then
			return nil
		end
		local t
		if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
			t = inst.Text
		else
			local n = inst:FindFirstChild("StatpointText") or inst:FindFirstChildWhichIsA("TextLabel", true)
			t = n and (n:IsA("TextLabel") or n:IsA("TextButton") or n:IsA("TextBox")) and n.Text or nil
		end
		if type(t) ~= "string" then
			t = guiText(inst)
		end
		if type(t) ~= "string" then
			return nil
		end
		local n = t:gsub(",", ""):match("(%d+%.?%d*)")
		return n and tonumber(n) or nil
	end

	function M.guiText(inst)
		return guiText(inst)
	end

	function M.guiNum(inst)
		return guiNum(inst)
	end

	-- Never index .Activate / :Activate() — this executor ImageButton throws
	-- "Activate is not a valid member". DialogueHandler setupButton wires
	-- ImageButton.Activated, InputBegan(Touch), and GetAttributeChangedSignal("Clicked").
	-- Keyboard 1–7 flips Clicked on the same ImageButton.
	local function rbxSignal(inst, name)
		if not inst or type(name) ~= "string" then
			return nil
		end
		local ok, ev = pcall(function()
			return inst[name]
		end)
		if ok and typeof(ev) == "RBXScriptSignal" then
			return ev
		end
		return nil
	end

	local function fireRbxSignal(sig)
		if typeof(sig) ~= "RBXScriptSignal" then
			return false
		end
		if typeof(firesignal) == "function" then
			if pcall(firesignal, sig) then
				return true
			end
		end
		if typeof(getconnections) ~= "function" then
			return false
		end
		perfCount("getconnections", 1)
		local ok, conns = pcall(getconnections, sig)
		if not (ok and type(conns) == "table") then
			return false
		end
		local any = false
		local seen = {}
		local function tryConn(c)
			if c == nil or seen[c] then
				return
			end
			seen[c] = true
			local fire = nil
			pcall(function()
				fire = c.Fire or c.fire
			end)
			if typeof(fire) == "function" and pcall(fire, c) then
				any = true
				return
			end
			local fn = nil
			pcall(function()
				fn = c.Function
			end)
			if typeof(fn) == "function" and pcall(fn) then
				any = true
			end
		end
		for i = 1, #conns do
			tryConn(conns[i])
		end
		for _, c in pairs(conns) do
			tryConn(c)
		end
		return any
	end

	function M.clickGui(btn)
		if not (btn and btn.Parent) then
			return false
		end
		local fired = fireRbxSignal(rbxSignal(btn, "Activated"))
		if not fired then
			fired = fireRbxSignal(rbxSignal(btn, "MouseButton1Click"))
		end
		-- Same path DialogueHandler uses for KeyCode.One on Main.1.ImageButton.
		-- u89 no-ops if Activated already ran (u12 / u48).
		local ok = pcall(function()
			btn:SetAttribute("Clicked", not btn:GetAttribute("Clicked"))
		end)
		return fired or ok
	end

	-- SkillObtained / TutorialScreen: no GuiButton. Client is UIS.InputBegan
	-- MouseButton1/Touch/ButtonX. gameProcessed=true is ignored unless ButtonX.
	-- SkillObtained.PassiveObtained connects InputBegan only after task.wait(3).
	-- ContinueButton is a TextLabel. Prefer SkillObtained over TutorialScreen
	-- (TutorialLocal WaitForClear waits for SkillObtained to close first).
	local OVERLAY_GUIS = { "SkillObtained", "TutorialScreen" }
	local SKILL_OBTAINED_LISTEN = 3.15
	local KNOWN_OVERLAYS = {
		SkillObtained = true,
		TutorialScreen = true,
		QuestOverlay = true,
		ScreenShadow = true,
	}
	local OVERLAY_CACHE_TTL = 0.25
	local OVERLAY_FULL_SCAN_GAP = 3

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

	local function layerOn(ui)
		if not ui then
			return false
		end
		if ui:IsA("LayerCollector") and ui.Enabled == true then
			return true
		end
		return ui:GetAttribute("Enabled") == true
	end

	local function overlayLabel(ui)
		if not ui then
			return "overlay"
		end
		if ui.Name == "TutorialScreen" then
			local title = ui:FindFirstChild("Title")
			local t = title and guiText(title)
			return "TutorialScreen " .. tostring(t or "")
		end
		if ui.Name == "SkillObtained" then
			local frame = ui:FindFirstChild("Frame")
			local sn = frame and frame:FindFirstChild("SkillName")
			return "SkillObtained " .. tostring((sn and guiText(sn)) or "")
		end
		return ui.Name
	end

	local function pressAnywhereText(t)
		if type(t) ~= "string" or t == "" then
			return false
		end
		local low = string.lower(t)
		return string.find(low, "press anywhere", 1, true) ~= nil
			or string.find(low, "click anywhere", 1, true) ~= nil
	end

	local function markOverlayDirty()
		M._overlayDirty = true
		M._overlayVisibleAt = 0
	end

	local function bindOverlaySignals(ui)
		if typeof(ui) ~= "Instance" then
			return
		end
		if not KNOWN_OVERLAYS[ui.Name] then
			return
		end
		M._overlayKnown[ui.Name] = ui
		if ui:IsA("LayerCollector") then
			GB.conns[#GB.conns + 1] = ui:GetPropertyChangedSignal("Enabled"):Connect(markOverlayDirty)
		end
	end

	local function ensureOverlayHooks(pg)
		if M._overlayHooked or not pg then
			return
		end
		M._overlayHooked = true
		for _, ui in ipairs(pg:GetChildren()) do
			bindOverlaySignals(ui)
		end
		GB.conns[#GB.conns + 1] = pg.ChildAdded:Connect(function(ui)
			bindOverlaySignals(ui)
			markOverlayDirty()
		end)
		GB.conns[#GB.conns + 1] = pg.ChildRemoved:Connect(function(ui)
			if KNOWN_OVERLAYS[ui.Name] and M._overlayKnown[ui.Name] == ui then
				M._overlayKnown[ui.Name] = nil
			end
			markOverlayDirty()
		end)
	end

	function M.tutorialOverlayVisible()
		local t0 = pbegin()
		local pg = GB.lp and GB.lp.PlayerGui
		if not pg then
			pdone("State.tutorialOverlayVisible", t0)
			return false, nil
		end
		ensureOverlayHooks(pg)
		local now = os.clock()
		if not M._overlayDirty and now - (M._overlayVisibleAt or 0) < OVERLAY_CACHE_TTL then
			pdone("State.tutorialOverlayVisible", t0)
			return M._overlayVisible == true, M._overlayVisibleUi
		end
		for _, name in ipairs(OVERLAY_GUIS) do
			local ui = M._overlayKnown[name]
			if not (ui and ui.Parent) then
				ui = pg:FindFirstChild(name)
				if ui then
					bindOverlaySignals(ui)
				end
			end
			if layerOn(ui) then
				M._overlayVisible = true
				M._overlayVisibleUi = ui
				M._overlayVisibleAt = now
				M._overlayDirty = false
				pdone("State.tutorialOverlayVisible", t0)
				return true, ui
			end
		end
		if now - (M._overlayLastScanAt or 0) < OVERLAY_FULL_SCAN_GAP then
			M._overlayVisible = false
			M._overlayVisibleUi = nil
			M._overlayVisibleAt = now
			M._overlayDirty = false
			pdone("State.tutorialOverlayVisible", t0)
			return false, nil
		end
		M._overlayLastScanAt = now
		perfCount("PlayerGuiFullScan", 1)
		for _, ui in ipairs(pg:GetChildren()) do
			if ui:IsA("LayerCollector") and layerOn(ui) then
				if ui:FindFirstChild("ClickToContinue", true) or ui:FindFirstChild("ContinueButton", true) then
					M._overlayVisible = true
					M._overlayVisibleUi = ui
					M._overlayVisibleAt = now
					M._overlayDirty = false
					pdone("State.tutorialOverlayVisible", t0)
					return true, ui
				end
				local title = ui:FindFirstChild("Title")
				local tt = title and guiText(title)
				if pressAnywhereText(tt) or (type(tt) == "string" and string.find(tt, "Unlock Skill", 1, true)) then
					M._overlayVisible = true
					M._overlayVisibleUi = ui
					M._overlayVisibleAt = now
					M._overlayDirty = false
					pdone("State.tutorialOverlayVisible", t0)
					return true, ui
				end
				for _, d in ipairs(ui:GetDescendants()) do
					if (d:IsA("TextLabel") or d:IsA("TextButton")) and pressAnywhereText(d.Text) then
						M._overlayVisible = true
						M._overlayVisibleUi = ui
						M._overlayVisibleAt = now
						M._overlayDirty = false
						pdone("State.tutorialOverlayVisible", t0)
						return true, ui
					end
				end
			end
		end
		M._overlayVisible = false
		M._overlayVisibleUi = nil
		M._overlayVisibleAt = now
		M._overlayDirty = false
		pdone("State.tutorialOverlayVisible", t0)
		return false, nil
	end

	local OWNER_NAMES = {
		TutorialLocal = true,
		PassiveObtained = true,
	}

	local function makeInput(kind)
		local t = {
			UserInputType = kind == "x" and Enum.UserInputType.Gamepad1 or Enum.UserInputType.MouseButton1,
			UserInputState = Enum.UserInputState.Begin,
			KeyCode = kind == "x" and Enum.KeyCode.ButtonX or Enum.KeyCode.Unknown,
			Position = Vector3.new(400, 300, 0),
			Delta = Vector3.new(0, 0, 0),
		}
		function t:IsModifierKeyDown()
			return false
		end
		return t
	end

	local function invokeFn(fn, fake, processed)
		if typeof(fn) ~= "function" then
			return false
		end
		return pcall(fn, fake, processed)
	end

	local function connOwnerName(c)
		local name
		pcall(function()
			local scr = c.Script
			if typeof(scr) == "Instance" then
				name = scr.Name
			end
		end)
		if type(name) == "string" and OWNER_NAMES[name] then
			return name
		end
		local fn
		pcall(function()
			fn = c.Function
		end)
		if typeof(fn) == "function" and typeof(getfenv) == "function" then
			pcall(function()
				local env = getfenv(fn)
				local scr = env and env.script
				if typeof(scr) == "Instance" then
					name = scr.Name
				end
			end)
		end
		if type(name) == "string" and OWNER_NAMES[name] then
			return name
		end
		return nil
	end

	local function invokeConn(c, fake, processed)
		if c == nil then
			return false
		end
		pcall(function()
			if c.Enabled == false then
				c.Enabled = true
			end
		end)
		local fire
		pcall(function()
			fire = c.Fire or c.fire
		end)
		if typeof(fire) == "function" then
			if pcall(fire, c, fake, processed) then
				return true
			end
			if pcall(function()
				c:Fire(fake, processed)
			end) then
				return true
			end
		end
		local fn
		pcall(function()
			fn = c.Function
		end)
		return invokeFn(fn, fake, processed)
	end

	-- TutorialLocal / PassiveObtained InputBegan: ButtonX + MouseButton1/Touch.
	local function overlayInputFn(fn)
		if typeof(fn) ~= "function" or typeof(getconstants) ~= "function" then
			return false
		end
		local ok, cs = pcall(getconstants, fn)
		if not (ok and type(cs) == "table") then
			return false
		end
		local hasX, hasClick = false, false
		for _, c in ipairs(cs) do
			if c == Enum.KeyCode.ButtonX or c == "ButtonX" then
				hasX = true
			end
			if c == Enum.UserInputType.MouseButton1
				or c == Enum.UserInputType.Touch
				or c == "MouseButton1"
				or c == "Touch"
			then
				hasClick = true
			end
		end
		return hasX and hasClick
	end

	local function scriptNameOfFn(fn)
		local name
		if typeof(getfenv) == "function" then
			pcall(function()
				local env = getfenv(fn)
				local scr = env and env.script
				if typeof(scr) == "Instance" then
					name = scr.Name
				end
			end)
		end
		if type(name) == "string" then
			return name
		end
		if debug and debug.info then
			pcall(function()
				local src = debug.info(fn, "s")
				if type(src) == "string" then
					name = src:match("([^\\/]+)$") or src
					name = name:match("([^%.]+)$") or name
				end
			end)
		end
		return name
	end

	local function clickViewport(vim)
		if not (vim and vim.SendMouseButtonEvent) then
			return false
		end
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
		local w = (vp and vp.X) or 800
		local h = (vp and vp.Y) or 600
		-- Background.Active=false — click the dimmer, not the card. Same as a hand click.
		local pts = {
			{ w * 0.12, h * 0.55 },
			{ w * 0.50, h * 0.92 },
			{ w * 0.88, h * 0.18 },
		}
		pcall(function()
			for _, p in ipairs(pts) do
				if vim.SendMouseMoveEvent then
					vim:SendMouseMoveEvent(p[1], p[2], game)
				end
				vim:SendMouseButtonEvent(p[1], p[2], 0, true, game, 1)
				task.wait(0.02)
				vim:SendMouseButtonEvent(p[1], p[2], 0, false, game, 1)
				task.wait(0.04)
			end
		end)
		return true
	end

	-- Highest visible numbered stage under Tutorials/<Title>. AdvanceStage does not hide prior stages.
	function M.overlayStage(ui)
		if not ui then
			return nil, 0, 0
		end
		local tutorials = ui:FindFirstChild("Tutorials")
		if not tutorials then
			return nil, 0, 0
		end
		local title = ui:FindFirstChild("Title")
		local name = title and guiText(title)
		local folder = (type(name) == "string" and name ~= "" and tutorials:FindFirstChild(name)) or nil
		if not folder then
			for _, ch in ipairs(tutorials:GetChildren()) do
				if ch:IsA("GuiObject") and ch.Visible then
					folder = ch
					name = ch.Name
					break
				end
			end
		end
		if not folder then
			return name, 0, 0
		end
		local maxVis, total = 0, 0
		for _, ch in ipairs(folder:GetChildren()) do
			local n = tonumber(ch.Name)
			if n then
				total = total + 1
				local vis = false
				if ch:IsA("GuiObject") and ch.Visible then
					vis = true
				end
				if not vis then
					for _, d in ipairs(ch:GetDescendants()) do
						if d:IsA("GuiObject") and d.Visible then
							vis = true
							break
						end
					end
				end
				if vis and n > maxVis then
					maxVis = n
				end
			end
		end
		return name, maxVis, total
	end

	-- Invoke TutorialLocal / PassiveObtained InputBegan only. Never hide GUI.
	-- Do not walk all UIS.InputBegan connections — CorePackages Scheduler ModuleScripts
	-- throw `_src` on this executor and abort the engine tick.
	function M.invokeContinueInput(ui, _strategy)
		local t0 = pbegin()
		local fakeMb = makeInput("mb1")
		local fakeX = makeInput("x")
		local method, invoked = nil, 0
		local UIS = game:GetService("UserInputService")
		local sig = rbxSignal(UIS, "InputBegan")
		local want = (ui and ui.Name == "SkillObtained") and "PassiveObtained" or "TutorialLocal"
		local overlayKey = (ui and ui.Name) or "GenericOverlay"
		local cached = M._continueHandlers[overlayKey]
		if type(cached) == "table" then
			local okCached = false
			if cached.kind == "fn" and typeof(cached.ref) == "function" then
				okCached = invokeFn(cached.ref, fakeX, false)
					or invokeFn(cached.ref, fakeX, true)
					or invokeFn(cached.ref, fakeMb, false)
			elseif cached.kind == "conn" then
				okCached = invokeConn(cached.ref, fakeX, false)
					or invokeConn(cached.ref, fakeX, true)
					or invokeConn(cached.ref, fakeMb, false)
			end
			if okCached then
				pdone("Tutorial.continuation", t0)
				return true, "InputBegan:cache:" .. tostring(cached.owner or want), 1
			end
			M._continueHandlers[overlayKey] = nil
		end

		local function hitOwner(fn)
			if typeof(fn) ~= "function" then
				return false
			end
			local sn = scriptNameOfFn(fn)
			if sn ~= want then
				return false
			end
			if not overlayInputFn(fn) then
				return false
			end
			if invokeFn(fn, fakeX, false) or invokeFn(fn, fakeX, true) or invokeFn(fn, fakeMb, false) then
				invoked = invoked + 1
				method = "InputBegan:" .. tostring(sn)
				M._continueHandlers[overlayKey] = {
					kind = "fn",
					ref = fn,
					owner = sn,
					at = os.clock(),
				}
				return true
			end
			return false
		end

		local now = os.clock()
		local allowHeavy = now >= (M._continueRetryAt[overlayKey] or 0)

		-- 1) Direct owner fn via getgc (name-gated). Same path that closed SkillObtained.
		if allowHeavy and typeof(getgc) == "function" then
			perfCount("getgc", 1)
			local ok, gc = pcall(getgc, false)
			if not ok then
				ok, gc = pcall(getgc)
			end
			if ok and type(gc) == "table" then
				for _, fn in ipairs(gc) do
					if invoked >= 2 then
						break
					end
					pcall(hitOwner, fn)
				end
			end
		end

		-- 2) Name-gated connection only. Never fingerprint CorePackages.
		if allowHeavy and invoked == 0 and typeof(getconnections) == "function" and typeof(sig) == "RBXScriptSignal" then
			perfCount("getconnections", 1)
			local ok, conns = pcall(getconnections, sig)
			if ok and type(conns) == "table" then
				for _, c in pairs(conns) do
					if invoked >= 2 then
						break
					end
					pcall(function()
						local sn = connOwnerName(c)
						if sn ~= want then
							return
						end
						if invokeConn(c, fakeX, false) or invokeConn(c, fakeX, true) or invokeConn(c, fakeMb, false) then
							invoked = invoked + 1
							method = method or ("InputBegan:" .. sn)
							M._continueHandlers[overlayKey] = {
								kind = "conn",
								ref = c,
								owner = sn,
								at = os.clock(),
							}
						end
					end)
				end
			end
		end
		if invoked == 0 and allowHeavy then
			M._continueRetryAt[overlayKey] = os.clock() + 1.8
		end

		-- 3) firesignal — some executors no-op; still try.
		if typeof(firesignal) == "function" and typeof(sig) == "RBXScriptSignal" then
			pcall(firesignal, sig, fakeX, false)
			pcall(firesignal, sig, fakeX, true)
			pcall(firesignal, sig, fakeMb, false)
			method = method or "InputBegan:firesignal"
		end

		-- 4) Real input. ButtonX is the only key accepted when gameProcessed=true.
		--    Mouse on Background (Active=false) is gameProcessed=false — hand-click path.
		local vim = game:GetService("VirtualInputManager")
		if vim and vim.SendKeyEvent then
			pcall(function()
				vim:SendKeyEvent(true, Enum.KeyCode.ButtonX, false, game)
				task.wait(0.03)
				vim:SendKeyEvent(false, Enum.KeyCode.ButtonX, false, game)
			end)
			method = method or "VirtualInput:ButtonX"
		end
		if clickViewport(vim) then
			method = method or "VirtualInput:Mouse1"
		end
		if typeof(mouse1click) == "function" then
			pcall(mouse1click)
			method = method or "mouse1click"
		end

		pdone("Tutorial.continuation", t0)
		return invoked > 0 or method ~= nil, method or "none", invoked
	end

	function M.overlayStillOn(ui)
		return layerOn(ui)
	end

	function M.dumpOverlayTree(ui)
		local rows = {}
		if not ui then
			return rows
		end
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
		local area = (vp and vp.X > 0 and vp.Y > 0) and (vp.X * vp.Y) or 0
		local function add(inst, depth)
			if #rows >= 24 then
				return
			end
			local row = {
				Name = inst.Name,
				Class = inst.ClassName,
				Depth = depth,
			}
			pcall(function()
				local attrs = inst:GetAttributes()
				if type(attrs) == "table" and next(attrs) then
					row.Attrs = attrs
				end
			end)
			if inst:IsA("LayerCollector") then
				row.Enabled = inst.Enabled
				row.AttrEnabled = inst:GetAttribute("Enabled")
			elseif inst:IsA("GuiObject") then
				row.Visible = inst.Visible
				row.Active = inst.Active
				row.Selectable = inst.Selectable
				row.ZIndex = inst.ZIndex
				local sz = inst.AbsoluteSize
				row.Abs = { math.floor(sz.X + 0.5), math.floor(sz.Y + 0.5) }
				if area > 0 then
					row.Cover = math.floor((sz.X * sz.Y) / area * 1000) / 10
				end
			end
			if inst:IsA("GuiButton") then
				row.Button = true
				row.Activated = rbxSignal(inst, "Activated") ~= nil
			end
			if inst:IsA("TextLabel") or inst:IsA("TextButton") then
				local t = inst.Text
				if type(t) == "string" and #t > 0 and #t < 80 then
					row.Text = t
				end
			end
			rows[#rows + 1] = row
			for _, ch in ipairs(inst:GetChildren()) do
				add(ch, depth + 1)
			end
		end
		add(ui, 0)
		local ranked = {}
		for _, r in ipairs(rows) do
			if type(r.Cover) == "number" then
				ranked[#ranked + 1] = r
			end
		end
		table.sort(ranked, function(a, b)
			return (a.Cover or 0) > (b.Cover or 0)
		end)
		if GB.Log then
			GB.Log.warn("GATE", string.format("overlay tree %s nodes=%d path=%s", tostring(ui.Name), #rows, ui:GetFullName()))
			for i = 1, math.min(#ranked, 8) do
				local r = ranked[i]
				GB.Log.warn(
					"GATE",
					string.format(
						"cover=%.1f%% %s %s vis=%s active=%s btn=%s text=%s",
						r.Cover or 0,
						tostring(r.Class),
						tostring(r.Name),
						tostring(r.Visible),
						tostring(r.Active),
						tostring(r.Button),
						tostring(r.Text or "")
					)
				)
			end
		end
		return rows
	end

	function M.skillNameOf(ui)
		if not ui then
			return nil
		end
		local frame = ui:FindFirstChild("Frame")
		local sn = frame and frame:FindFirstChild("SkillName")
		return sn and guiText(sn)
	end

	-- Attempt only. Caller must validate overlay actually closed.
	function M.dismissTutorialOverlay()
		local vis, ui = M.tutorialOverlayVisible()
		if not vis then
			M._overlayLog = nil
			M._soSeen = nil
			M._soWaitLog = nil
			M._tsSeen = nil
			return false, nil, "gone"
		end
		local now = os.clock()
		local label = overlayLabel(ui)
		if ui.Name == "SkillObtained" then
			M._soSeen = M._soSeen or now
			if now - M._soSeen < SKILL_OBTAINED_LISTEN then
				if M._soWaitLog ~= label then
					M._soWaitLog = label
					GB.Log.log("GATE", "waiting SkillObtained listener " .. label)
				end
				return false, ui, "wait_listener"
			end
		elseif ui.Name == "TutorialScreen" then
			M._soSeen = nil
			M._soWaitLog = nil
			M._tsSeen = M._tsSeen or now
			-- OpenGUI ShowContinue(0.75) then u6=true. First press after that.
			if now - M._tsSeen < 0.85 then
				if M._soWaitLog ~= label then
					M._soWaitLog = label
					GB.Log.log("GATE", "waiting TutorialScreen continue " .. label)
				end
				return false, ui, "wait_listener"
			end
		else
			M._soSeen = nil
			M._soWaitLog = nil
			M._tsSeen = nil
		end
		if now - (M._overlayAt or 0) < 0.4 then
			return false, ui, "rate"
		end
		M._overlayAt = now
		local pok, ok, method, n = pcall(M.invokeContinueInput, ui, M._continueStrategy or "owner")
		if not pok then
			if GB.Log then
				GB.Log.warn("GATE", "continue invoke " .. tostring(ok))
			end
			return false, ui, "err", 0
		end
		return ok, ui, method, n
	end

	function M.refresh()
		local t0 = pbegin()
		M.prev = M.snap
		local s = {}
		local lp = GB.lp
		local char = lp and lp.Character
		local hrp = char and (char:FindFirstChild("HumanoidRootPart") or (char:IsA("Model") and char.PrimaryPart))
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		s.Character = char
		s.HRP = hrp
		s.Humanoid = hum
		s.Alive = char and hum and hum.Health > 0
		s.Position = hrp and hrp.Position
		s.GameplayPaused = lp and lp:GetAttribute("GameplayPaused") == true

		local d = GB.PlayerData and GB.PlayerData.cache() or {}
		s.Level = d.Level or 0
		s.Exp = d.EXP or d.Exp or 0
		s.Gold = d.Gold or 0
		s.CelestialCoins = d["Celestial Coins"] or d.CelestialCoins or 0
		local liveStats, livePts, liveSrc
		if GB.PlayerData and GB.PlayerData.latestStats then
			liveStats, livePts, liveSrc = GB.PlayerData.latestStats()
		end
		s.StatSource = liveSrc or "PlayerDataCache"
		s.StatPoints = tonumber(livePts)
			or tonumber(d.StatPoints)
			or tonumber(d["Stat Points"])
			or tonumber(d.UnusedStatPoints)
			or 0
		s.SkillPoints = d.SkillPoints or d["Skill Points"] or 0
		s.Stats = {}
		for _, n in ipairs(STATS) do
			s.Stats[n] = tonumber(liveStats and liveStats[n])
				or tonumber(d.Stats and d.Stats[n])
				or 0
		end
		s.Skills = d.Skills or {}
		s.Inventory = d.Inventory or {}
		s.Backpack = d.Backpack or d.Inventory
		s.Equipment = d.Equipment or d.Equips or {}
		s.Weapon = d.Weapon
		s.FightingStyle = (lp and lp:GetAttribute("Style")) or d.FightingStyle or d.Style
		s.Fruit = (lp and lp:GetAttribute("Fruit")) or d.Fruit
		s.StoredFruits = d["Fruit Storage"] or d.FruitStorage or {}
		s.PermanentFruits = d["Permanent Fruits"] or {}
		s.Race = d.Race or (lp and lp:GetAttribute("Race"))
		s.Trait = d.Trait or d.Traits
		s.Haki = d.Haki
		s.Boat = d.Boats or d.Ships
		s.LifeSkills = d.Lifeskills or d.LifeSkills or {}
		s.Flags = d.Flags or {}
		s.Quests = d.Quests or {}
		s.Completed = d.CompletedSet or {}
		s.CurrentQuest = (GB.PlayerData and GB.PlayerData.current()) or d.CurrentQuest
		s.CurrentIsland = (GB.World and GB.World.islandFromProgress(s)) or "Anchor Town"
		local ui = {
			Blocking = false,
			TutorialActive = false,
			TutorialText = nil,
			TutorialStep = nil,
			Modal = nil,
			DialogueActive = false,
			BackpackOpen = false,
			InventoryOpen = false,
		}
		if GB.Tutorial and GB.Tutorial.snapshot then
			local snap = GB.Tutorial.snapshot()
			if type(snap) == "table" then
				ui.Blocking = snap.Blocking == true
				ui.TutorialActive = snap.TutorialActive == true
				ui.TutorialText = snap.TutorialText
				ui.TutorialStep = snap.TutorialStep
				ui.Modal = snap.Modal
				ui.DialogueActive = snap.DialogueActive == true
				ui.BackpackOpen = snap.BackpackOpen == true
				ui.InventoryOpen = snap.InventoryOpen == true
				ui.GateType = snap.GateType
			end
		else
			local vis, overlay = M.tutorialOverlayVisible()
			ui.TutorialActive = vis
			ui.Modal = vis and overlay and overlay.Name or nil
			local pg = lp and lp.PlayerGui
			local dui = pg and pg:FindFirstChild("DialogueUI")
			ui.DialogueActive = dui and dui:IsA("LayerCollector") and dui.Enabled == true
		end
		s.UI = ui
		s.EquipmentState = nil
		if GB.Equipment and GB.Equipment.equipmentState and s.CurrentQuest then
			local qs = GB.Quest and GB.Quest.questState and GB.Quest.questState(s.CurrentQuest)
			if qs and qs.Objective and qs.Objective.Type == "Equip" then
				s.EquipmentState = GB.Equipment.equipmentState(qs.Objective.TargetName)
			end
		end
		s.PhysicalIsland = nil
		if GB.World and s.Position then
			s.PhysicalIsland = GB.World.GetIslandFromPosition(s.Position)
		end

		-- GUI fallbacks (old kaitun: StatpointText.Value lies)
		pcall(function()
			local pg = lp.PlayerGui
			local menu = pg:FindFirstChild("Menu") or pg:FindFirstChild("UI")
			if menu then
				local radar = menu:FindFirstChild("Radar", true)
				if radar then
					local st = radar:FindFirstChild("StatpointText", true)
					local n = guiNum(st)
					if n and n >= 0 and ((tonumber(s.StatPoints) or -1) < 1) then
						s.StatPoints = n
						s.StatSource = tostring(s.StatSource or "Unknown") .. "|GUIFallback"
					end
				end
			end
			local prog = pg:FindFirstChild("Progression")
			if prog then
				local lv = prog:FindFirstChild("Level", true)
				local n = guiNum(lv)
				if n and n > 0 and (tonumber(s.Level) or 0) <= 0 then
					s.Level = n
				end
			end
		end)

		if s.Position then
			M.track.LastPosition = s.Position
		end
		local stageIndex = nil
		if s.CurrentQuest and GB.PlayerData and GB.PlayerData.live and GB.QuestData and GB.QuestData.currentStage then
			local liveQuest = GB.PlayerData.live(s.CurrentQuest)
			stageIndex = liveQuest and select(1, GB.QuestData.currentStage(liveQuest)) or nil
		end
		local qsig = tostring(s.CurrentQuest or "-") .. "|" .. tostring(stageIndex or "-")
		if s.Level ~= M.track.Level
			or s.Exp ~= M.track.EXP
			or s.Gold ~= M.track.Gold
			or tonumber(s.StatPoints) ~= tonumber(M.track.StatPoints)
			or tonumber(s.Stats.Strength) ~= tonumber(M.track.Strength)
			or tonumber(s.Stats.Health) ~= tonumber(M.track.Health)
			or s.CurrentQuest ~= M.track.CurrentQuest
			or qsig ~= tostring(M.track.QuestProgress or "")
		then
			M.track.StateChange = os.clock()
		end
		M.track.Level = s.Level
		M.track.EXP = s.Exp
		M.track.Gold = s.Gold
		M.track.StatPoints = tonumber(s.StatPoints) or 0
		M.track.Strength = tonumber(s.Stats.Strength) or 0
		M.track.Health = tonumber(s.Stats.Health) or 0
		M.track.CurrentQuest = s.CurrentQuest
		M.track.QuestProgress = qsig
		M.snap = s
		pdone("State.refresh", t0)
		return s
	end

	function M.get()
		if not M.snap.Level then
			return M.refresh()
		end
		return M.snap
	end

	M.Refresh = M.refresh

	function M.changed(field)
		local a, b = M.snap[field], M.prev[field]
		return a ~= b
	end

	return M
end
]],
    ["Game/Inventory.lua"] = [[-- Inventory classify + helpers.

return function(GB)
	local M = {}

	function M.list()
		local inv = GB.PlayerData.cache().Inventory
		local rows = {}
		if type(inv) ~= "table" then
			return rows
		end
		for k, v in pairs(inv) do
			if type(v) == "table" then
				table.insert(rows, {
					key = v.Key or v.Name or k,
					name = v.Name or k,
					amount = tonumber(v.Amount) or 1,
					lock = v.BackpackLock,
				})
			end
		end
		return rows
	end

	function M.full()
		-- slot upgrade UNRESOLVED; heuristic only
		local n = #M.list()
		return n >= 40
	end

	function M.classify(name)
		return GB.ItemData.kind(name)
	end

	return M
end
]],
    ["Game/ItemData.lua"] = [[-- KEEP / EQUIP / STORE / SELL / USE / QUEST_ITEM / UNKNOWN.
-- UNKNOWN = KEEP. Never sell rare / quest / fruit / progression.

return function(GB)
	local M = {}

	M.KEEP = {
		["Stolen Watch"] = "QUEST_ITEM",
		["Flintlock"] = "EQUIP",
		["Rusty Pickaxe"] = "EQUIP",
		["Rusty Shovel"] = "KEEP",
		["Transponder Snail"] = "EQUIP",
		["Rowboat"] = "KEEP",
		["Afuaru's Key"] = "QUEST_ITEM",
		["Pirate Fan Letter"] = "QUEST_ITEM",
		["Pirate's Ruby"] = "QUEST_ITEM",
		["Treasure Map (Easy)"] = "KEEP",
		["Treasure Map (Medium)"] = "KEEP",
		["Treasure Map (Hard)"] = "KEEP",
		["Treasure Map (Expert)"] = "KEEP",
		["Carbon Rod"] = "EQUIP",
		["Wooden Rod"] = "EQUIP",
		["Terry's Hat"] = "EQUIP",
		["Joe's Overalls (Outfit)"] = "EQUIP",
		["Chef Apron (Outfit)"] = "EQUIP",
		["Stone Ring"] = "KEEP",
		["Handle"] = "KEEP",
		["Telescope"] = "KEEP",
		["Muggy Ball"] = "KEEP",
		["Slingshot"] = "KEEP",
		["Strong Punch"] = "KEEP",
		["Skill: Strong Punch"] = "KEEP",
		["Skill Scroll"] = "KEEP",
		["King's Punch"] = "KEEP",
		["[50%] Smuggler's Coupon"] = "KEEP",
		["Calvin's Treasure"] = "KEEP",
		["Worm"] = "USE",
		["Copper Ore"] = "KEEP",
		["Copper Bar"] = "KEEP",
		["Iron Ore"] = "KEEP",
		["Lead Ore"] = "KEEP",
		["Lead"] = "KEEP",
		["Lead Ball"] = "KEEP",
		["Gunpowder"] = "KEEP",
		["Cutlass"] = "EQUIP",
	}

	M.FRUITS = {
		Flame = true,
		Darkness = true,
		Invisibility = true,
		Spin = true,
		Chop = true,
		Bomb = true,
		Wolf = true,
		Clothing = true,
		Strength = true,
		Swim = true,
		Weight = true,
		Spike = true,
		Cannon = true,
		Drain = true,
		Light = true,
	}

	M.SHOP = {
		["Flintlock"] = { gold = 150, need = "Gearing Up" },
		["Cutlass"] = { gold = 200 },
		["Rowboat"] = { gold = 50, need = "Setting Sail", via = "Ships" },
		["Transponder Snail"] = { gold = 100, need = "A Voice in a Shell" },
		["Rusty Pickaxe"] = { gold = 25, need = "First Upgrade" },
		["Rusty Shovel"] = { gold = 25 },
		["Wooden Rod"] = { gold = 75 },
		["Worm"] = { gold = 5 },
		["Apple"] = { gold = 5 },
		["Lemon"] = { gold = 5 },
		["Banana"] = { gold = 5 },
		["Carrot"] = { gold = 5 },
		["Potato"] = { gold = 5 },
		["Eggplant"] = { gold = 5 },
		["Pet Food"] = { gold = 100 },
	}

	M.PROGRESS_BUY = { "Flintlock", "Rusty Pickaxe", "Transponder Snail", "Rowboat" }

	function M.kind(name)
		if not name then
			return "UNKNOWN"
		end
		if M.FRUITS[name] or string.find(name, "Fruit") then
			return "KEEP"
		end
		if M.KEEP[name] then
			return M.KEEP[name]
		end
		if string.find(name, "Recipe") or string.find(name, "Map") then
			return "KEEP"
		end
		if string.find(name, "Rep Punch") then
			return "KEEP"
		end
		return "UNKNOWN"
	end

	function M.canSell(name)
		local k = M.kind(name)
		if k == "UNKNOWN" or k == "KEEP" or k == "QUEST_ITEM" or k == "EQUIP" then
			return false
		end
		return k == "SELL"
	end

	function M.shopPrice(name)
		local r = M.SHOP[name]
		return r and r.gold
	end

	return M
end
]],
    ["Game/PlayerData.lua"] = [[-- Live quest truth: GetData("Quests","Completed Quests") + PlayerGui.Quests tracker.
-- ClientCache.Quests is a boot snapshot. QuestBegan/QuestDeleted/QuestStageUpdated are empty.

return function(GB)
	local RS = game:GetService("ReplicatedStorage")
	local M = {
		_cache = nil,
		_stat = nil,
		_live = {},
		_order = {},
		_done = {},
		_at = 0,
		_tracker = nil,
		_trackerAt = 0,
		_trackerCache = nil,
		_current = nil,
		_hooked = false,
		_questDirty = true,
		_questDirtyAt = 0,
		_unusedPts = nil,
		_unusedPtsAt = 0,
		_liveStats = nil,
		_statsSource = nil,
		_statsAt = 0,
		_lastQuestFetchAt = 0,
	}

	local LIVE_SAFETY_TTL = 5.4
	local TRACKER_TTL = 0.75
	local UNUSED_TTL = 2.8
	local STAT_NAMES = { "Health", "Strength", "Agility", "Precision", "Energy", "Willpower", "Level" }

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

	local STAGE_HINT = {
		["Equip your new skill"] = "Basics",
		["Equip Skill: Strong Punch"] = "Basics",
		["Cast the skill"] = "Basics",
		["Use Skill: Strong Punch"] = "Basics",
		["Invest your stat"] = "Basics",
		["Invest Stat Points"] = "Basics",
		["Open the logbook"] = "Basics",
		["Open your logbook"] = "Basics",
		["Select the 'Strong Punch'"] = "Basics",
		["Select the \"Strong Punch\""] = "Basics",
		["Walk up to a dummy"] = "Introduction",
		["Press Q to perform a dash"] = "Introduction",
		["Hold F to perform a block"] = "Introduction",
		["Talk to Officer Graves to get started"] = "Introduction",
	}

	local function loadMods()
		if not M._cache then
			M._cache = require(RS.Modules.ClientCache)
		end
		if not M._stat then
			M._stat = require(RS.Modules.StatSystem)
		end
	end

	local function completedSet(done)
		local set = {}
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

	local function questActive(q)
		if type(q) ~= "table" then
			return false
		end
		if q.Complete == true or q.State == "Complete" then
			return false
		end
		local stages = q.Stages
		if type(stages) ~= "table" then
			return true
		end
		for _, st in ipairs(stages) do
			if type(st) == "table" and not st.Complete then
				local conds = st.Conditions or st.conditions
				if type(conds) ~= "table" or #conds == 0 then
					return true
				end
				for _, cond in ipairs(conds) do
					if type(cond) == "table" then
						if not GB.QuestData then
							return true
						end
						if not GB.QuestData.conditionComplete(cond) then
							return true
						end
					end
				end
			end
		end
		return false
	end

	local function hintQuest(text)
		if type(text) ~= "string" or text == "" then
			return nil
		end
		for needle, name in pairs(STAGE_HINT) do
			if string.find(text, needle, 1, true) then
				return name
			end
		end
		if GB.QuestData then
			for _, ch in ipairs(GB.QuestData.CHAINS) do
				for _, name in ipairs(ch.order) do
					if text == name or string.find(text, name, 1, true) then
						return name
					end
				end
			end
			for _, e in ipairs(GB.QuestData.REPEATS) do
				if text == e.name then
					return e.name
				end
			end
		end
		return nil
	end

	local function readTracker()
		local now = os.clock()
		if M._trackerCache and now - (M._trackerAt or 0) < TRACKER_TTL then
			return M._trackerCache
		end
		local lp = GB.lp
		local pg = lp and lp.PlayerGui
		if not pg then
			M._trackerCache = nil
			M._trackerAt = now
			return nil
		end
		local gui = pg:FindFirstChild("Quests")
		if not gui then
			M._trackerCache = nil
			M._trackerAt = now
			return nil
		end
		local det = gui:FindFirstChild("QuestDetails")
		if det then
			local attr = det:GetAttribute("QuestName")
			if type(attr) == "string" and attr ~= "" then
				M._trackerCache = attr
				M._trackerAt = now
				return attr
			end
			local qn = det:FindFirstChild("QuestName")
			local t = qn and GB.State and GB.State.guiText(qn)
			local hinted = hintQuest(t)
			if hinted then
				M._trackerCache = hinted
				M._trackerAt = now
				return hinted
			end
		end
		local qf = gui:FindFirstChild("Quest")
		local sf = qf and qf:FindFirstChild("ScrollingFrame")
		if not sf then
			M._trackerCache = nil
			M._trackerAt = now
			return nil
		end
		local function scanNode(root, depth, budget)
			if not (root and budget > 0 and depth >= 0) then
				return nil, budget
			end
			for _, d in ipairs(root:GetChildren()) do
				if budget <= 0 then
					break
				end
				local attr = d:GetAttribute("QuestName") or d:GetAttribute("QuestId")
				if type(attr) == "string" and attr ~= "" and hintQuest(attr) then
					return hintQuest(attr) or attr, budget
				end
				if d:IsA("TextLabel") or d:IsA("TextButton") then
					local hinted = hintQuest(d.Text)
					if hinted then
						return hinted, budget
					end
				end
				if depth > 0 then
					local hit
					hit, budget = scanNode(d, depth - 1, budget - 1)
					if hit then
						return hit, budget
					end
				end
			end
			return nil, budget
		end
		local hit = select(1, scanNode(sf, 3, 70))
		if hit then
			M._trackerCache = hit
			M._trackerAt = now
			return hit
		end
		local overlay = pg:FindFirstChild("ScreenShadow") or pg:FindFirstChild("Tutorial")
		if overlay then
			local ov = select(1, scanNode(overlay, 2, 40))
			if ov then
				M._trackerCache = ov
				M._trackerAt = now
				return ov
			end
			for _, d in ipairs(overlay:GetChildren()) do
				if d:IsA("TextLabel") or d:IsA("TextButton") then
					local hinted = hintQuest(d.Text)
					if hinted then
						M._trackerCache = hinted
						M._trackerAt = now
						return hinted
					end
				end
			end
		end
		M._trackerCache = nil
		M._trackerAt = now
		return nil
	end

	local function ingestList(list)
		local live, order = {}, {}
		if type(list) ~= "table" then
			return live, order
		end
		local function add(name, q)
			if type(name) ~= "string" or name == "" then
				return
			end
			if M._done[name] then
				return
			end
			if not questActive(q) then
				return
			end
			if not live[name] then
				live[name] = q
				order[#order + 1] = name
			end
		end
		if list[1] ~= nil then
			for _, q in ipairs(list) do
				if type(q) == "table" then
					add(q.Name or q.name, q)
				end
			end
			return live, order
		end
		for k, q in pairs(list) do
			if type(q) == "table" then
				add(q.Name or k, q)
			end
		end
		return live, order
	end

	local function pickCurrent()
		local tr = M._tracker
		if tr and M._live[tr] then
			return tr
		end
		if tr and not M._done[tr] then
			return tr
		end
		if GB.QuestData then
			for _, ch in ipairs(GB.QuestData.CHAINS) do
				for _, name in ipairs(ch.order) do
					if M._live[name] then
						return name
					end
				end
			end
			local best, bestExp
			for _, e in ipairs(GB.QuestData.REPEATS) do
				if M._live[e.name] and (not best or e.exp > bestExp) then
					best, bestExp = e.name, e.exp
				end
			end
			if best then
				return best
			end
		end
		local ck = GB.Persist and GB.Persist.data and GB.Persist.data.checkpoint
		if ck and type(ck.quest) == "string" and M._live[ck.quest] then
			return ck.quest
		end
		return M._order[1]
	end

	local function markQuestDirty(why)
		M._questDirty = true
		M._questDirtyAt = os.clock()
		M._at = 0
		if why and (not M._dirtyLogAt or os.clock() - M._dirtyLogAt > 1.5) then
			M._dirtyLogAt = os.clock()
			GB.Log.log("STATE", "quest dirty " .. tostring(why))
		end
	end

	function M.invalidateLive(why)
		markQuestDirty(why or "invalidate")
	end

	function M.questDirty()
		return M._questDirty == true
	end

	function M.forceQuestRefresh(why)
		markQuestDirty(why or "force")
		return M.refreshLive(true, why or "force")
	end

	function M.refreshLive(force, why)
		local t0 = pbegin()
		loadMods()
		local now = os.clock()
		M._tracker = readTracker()
		local stale = now - (M._lastQuestFetchAt or 0) >= LIVE_SAFETY_TTL
		if not force and not M._questDirty and not stale and (next(M._live) or M._tracker or M._current) then
			M._current = pickCurrent()
			pdone("PlayerData.refreshLive", t0)
			return M._live
		end
		perfCount("PlayerDataRefresh", 1)
		local quests, done = GB.Remotes.getQuests()
		if quests == nil and done == nil then
			local snap = M._cache and M._cache.Data
			if snap then
				quests = snap.Quests
				done = snap["Completed Quests"] or snap.CompletedQuests
			end
		end
		if quests ~= nil or done ~= nil then
			M._done = completedSet(done)
			M._live, M._order = ingestList(quests)
			M._at = now
			M._lastQuestFetchAt = now
			M._questDirty = false
			M._tracker = readTracker() or M._tracker
			local prev = M._current
			M._current = pickCurrent()
			if M._current and M._current ~= prev then
				GB.Log.log("STATE", "live quest " .. M._current)
				if GB.Combat and GB.Combat.stopLock then
					GB.Combat.stopLock()
				end
				if GB.Persist and GB.Persist.checkpoint then
					GB.Persist.checkpoint("quest", M._current)
				end
			end
		elseif force or stale then
			-- Keep dirty=true so next safety poll/event will retry.
			M._questDirty = true
			if why and os.clock() - (M._refreshWarnAt or 0) > 6 then
				M._refreshWarnAt = os.clock()
				GB.Log.warn("STATE", "quest refresh miss " .. tostring(why))
			end
		end
		pdone("PlayerData.refreshLive", t0)
		return M._live
	end

	function M.hookQuestEvents()
		if M._hooked then
			return
		end
		M._hooked = true
		local ev = RS:FindFirstChild("Events")
		if not ev then
			return
		end
		local function bump(why)
			markQuestDirty(why)
			M._trackerAt = 0
			M._trackerCache = nil
			if GB.State and GB.State.track then
				GB.State.track.StateChange = os.clock()
			end
		end
		local beginQ = ev:FindFirstChild("BeginQuest")
		if beginQ then
			GB.conns[#GB.conns + 1] = beginQ.OnClientEvent:Connect(function(q)
				local name = type(q) == "table" and q.Name or q
				bump("BeginQuest " .. tostring(name))
				if type(q) == "table" and q.Name then
					M._done[q.Name] = nil
					M._live[q.Name] = q
					M._order[#M._order + 1] = q.Name
					M._current = q.Name
				end
				if GB.Stats and GB.Stats.markDirty then
					GB.Stats.markDirty("quest_begin")
				end
			end)
		end
		local clearQ = ev:FindFirstChild("ClearQuest")
		if clearQ then
			GB.conns[#GB.conns + 1] = clearQ.OnClientEvent:Connect(function(name)
				bump("ClearQuest " .. tostring(name))
				if type(name) == "string" then
					M._live[name] = nil
					M._done[name] = true
					if M._current == name then
						M._current = nil
					end
				end
				if GB.Stats and GB.Stats.markDirty then
					GB.Stats.markDirty("quest_clear")
				end
			end)
		end
		local prog = ev:FindFirstChild("QuestProgress")
		if prog then
			GB.conns[#GB.conns + 1] = prog.OnClientEvent:Connect(function()
				bump("QuestProgress")
			end)
		end
		local upd = ev:FindFirstChild("UpdateQuestState")
		if upd then
			GB.conns[#GB.conns + 1] = upd.OnClientEvent:Connect(function(name, state)
				if state == "Complete" and type(name) == "string" then
					M._live[name] = nil
					M._done[name] = true
					if M._current == name then
						M._current = nil
					end
					if GB.Stats and GB.Stats.markDirty then
						GB.Stats.markDirty("quest_complete")
					end
				end
				bump("UpdateQuestState " .. tostring(name))
			end)
		end
		local cc = RS:FindFirstChild("Modules") and RS.Modules:FindFirstChild("ClientCache")
		local ch = cc and cc:FindFirstChild("QuestsChanged")
		if ch then
			GB.conns[#GB.conns + 1] = ch.Event:Connect(function()
				bump("QuestsChanged")
			end)
		end
		local st = ev:FindFirstChild("StatPoints")
		if st then
			GB.conns[#GB.conns + 1] = st.OnClientEvent:Connect(function(stats, pts)
				if type(stats) == "table" then
					M._liveStats = stats
					M._statsSource = "StatPointsEvent"
					M._statsAt = os.clock()
				end
				if type(pts) == "number" then
					M._unusedPts = pts
					M._unusedPtsAt = os.clock()
					M._statsSource = M._statsSource or "StatPointsEvent"
					M._statsAt = os.clock()
					if GB.Stats and GB.Stats.markDirty then
						GB.Stats.markDirty("stat_points_event")
					end
				end
				if GB.State and GB.State.track then
					GB.State.track.StateChange = os.clock()
				end
			end)
		end
		task.spawn(function()
			M.pullStats()
		end)
	end

	function M.raw()
		loadMods()
		return M._cache and M._cache.Data or {}
	end

	function M.cache()
		loadMods()
		M.refreshLive()
		local d = M._cache and M._cache.Data or {}
		local out = {}
		for k, v in pairs(d) do
			out[k] = v
		end
		out.Level = tonumber(d.Level) or tonumber(d.level) or 0
		if out.Level <= 0 and d.Stats then
			out.Level = tonumber(d.Stats.Level) or 0
		end
		local lp = GB.lp
		local char = lp and lp.Character
		if out.Level <= 0 and char then
			out.Level = tonumber(char:GetAttribute("Level")) or 0
			if out.Level <= 0 and M._stat and M._stat.GetValue then
				local n = M._stat.GetValue(char, "Level")
				if type(n) == "number" then
					out.Level = n
				end
			end
		end
		out.EXP = tonumber(d.EXP) or tonumber(d.Exp) or 0
		out.Gold = tonumber(d.Gold) or 0
		out.StatPoints = tonumber(M._unusedPts)
		if out.StatPoints == nil then
			out.StatPoints = tonumber(d.StatPoints) or tonumber(d["Stat Points"]) or tonumber(d.UnusedStatPoints) or 0
		end
		out.Stats = {}
		if char and M._stat and M._stat.GetBaseValue then
			for _, n in ipairs({ "Health", "Strength", "Agility", "Precision", "Energy", "Willpower" }) do
				local v = M._stat.GetBaseValue(char, n)
				out.Stats[n] = type(v) == "number" and v or 0
			end
		end
		out.CompletedSet = M._done
		out.Quests = M._live
		out.Inventory = d.Inventory or {}
		out.Skills = d.Skills or {}
		out.Fruit = d.Fruit
		out["Fruit Storage"] = d["Fruit Storage"]
		out["Permanent Fruits"] = d["Permanent Fruits"]
		out.CurrentQuest = M._current
		return out
	end

	function M.finished(name, skipRefresh)
		if not skipRefresh then
			M.refreshLive()
		end
		return name and M._done[name] == true
	end

	function M.live(name)
		if not name then
			return nil
		end
		M.refreshLive()
		if M._done[name] then
			return nil
		end
		return M._live[name]
	end

	function M.current()
		M.refreshLive()
		return M._current
	end

	function M.activeNames()
		M.refreshLive()
		local out = {}
		for _, n in ipairs(M._order) do
			if M._live[n] then
				out[#out + 1] = n
			end
		end
		return out
	end

	function M.hasItem(name)
		local inv = M.cache().Inventory
		if type(inv) ~= "table" then
			return false, 0
		end
		if inv[name] then
			local row = inv[name]
			if type(row) == "table" then
				return true, tonumber(row.Amount) or 1
			end
			return true, 1
		end
		for _, v in pairs(inv) do
			if type(v) == "table" and (v.Name == name or v.Key == name or v.Value == name) then
				return true, tonumber(v.Amount) or 1
			end
		end
		return false, 0
	end

	function M.skillOwned(name)
		local skills = M.cache().Skills
		if type(skills) ~= "table" or not name then
			return false, false
		end
		local row = skills[name]
		if type(row) == "table" then
			return row.Owned == true or row.Equipped == true, row.Equipped == true
		end
		return false, false
	end

	function M.pullStats()
		local t0 = pbegin()
		local a, b = GB.Remotes.getStats()
		local stats
		local pts
		if type(a) == "table" then
			stats = a
		elseif type(b) == "table" then
			stats = b
		end
		if type(a) == "number" then
			pts = a
		end
		if type(b) == "number" then
			pts = b
		end
		if type(stats) == "table" then
			local packed = {}
			for _, name in ipairs(STAT_NAMES) do
				packed[name] = tonumber(stats[name]) or 0
			end
			M._liveStats = packed
			M._statsSource = "GetStats"
			M._statsAt = os.clock()
		end
		if type(pts) == "number" then
			M._unusedPts = pts
			M._unusedPtsAt = os.clock()
			M._statsSource = M._statsSource or "GetStats"
			M._statsAt = os.clock()
		end
		pdone("PlayerData.pullStats", t0)
		return a, b
	end

	function M.unusedStatPoints(force)
		if force or type(M._unusedPts) ~= "number" or os.clock() - (M._unusedPtsAt or 0) > UNUSED_TTL then
			M.pullStats()
		end
		return tonumber(M._unusedPts)
	end

	function M.latestStats()
		return M._liveStats, tonumber(M._unusedPts), M._statsSource, M._statsAt
	end

	function M.refreshStats()
		GB.Remotes.statReplicate()
		return M.pullStats()
	end

	return M
end
]],
    ["Game/QuestData.lua"] = [[-- Planner tables from data.json / picker. Kill-name fixes from Studio modules.

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
	M.OBJECT_TARGETS = {
		["Marine Gate"] = {
			Island = "Anchor Town",
			Path = { "Islands", "Anchor Town", "Island", "Gate" },
			Tags = { "Marine Metal Gate", "Gate" },
			Prompts = { "Pushable Door" },
		},
	}

	M.QUEST_REQUIREMENTS = {
		["Gate of Authority"] = {
			Strength = 100,
			Status = "IMPLEMENTED_UNVERIFIED",
			Reason = "Gate push interaction appears strength-gated; runtime validate while quest executes.",
		},
	}

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

	function M.deliverSpec(target)
		return M.DELIVER[target]
	end

	function M.objectSpec(target)
		return M.OBJECT_TARGETS[target]
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

	if GB.Resolver then
		GB.Resolver.NPC_ALIAS = M.NPC_ALIAS
	end

	return M
end
]],
    ["Game/QuestSpecs.lua"] = [[-- Generated from research/quests.json. Item sources are QuestInfo markers/conditions only.
return function(GB)
	local M = { ITEMS = {}, STAGES = {}, SUBGOALS = {} }

	M.ITEMS["Afuaru's Chests"] = { method = "Chest", source = "Afuaru's Chests", location = "Anchor Town", gold = nil }
	M.ITEMS["Afuaru's Key"] = { method = "BossDrop", source = "Afuaru, The Hoarder", location = "Anchor Town", gold = nil }
	M.ITEMS["Apple"] = { method = "ShopPurchase", source = "Apple", location = "Anchor Town", gold = nil }
	M.ITEMS["Apple Pot Pie"] = { method = "Farming", source = "Apple Pot Pie", location = "Anchor Town", gold = nil }
	M.ITEMS["Banana"] = { method = "ShopPurchase", source = "Banana", location = "Anchor Town", gold = nil }
	M.ITEMS["Black Shell"] = { method = "WorldPickup", source = "Red Shell Spawn", location = "Anchor Town", gold = nil }
	M.ITEMS["Bucket of Water"] = { method = "WorldPickup", source = "Clucking Villager", location = "Maple Village", gold = nil }
	M.ITEMS["Cabbage"] = { method = "Farming", source = "Cabbage", location = "Maple Village", gold = nil }
	M.ITEMS["Captive Swordsman's Swords"] = { method = "WorldPickup", source = "Captive Swordsman's Swords", location = "Anchor Town", gold = nil }
	M.ITEMS["Carp"] = { method = "Fishing", source = "Carp", location = "Anchor Town", gold = nil }
	M.ITEMS["Carrot"] = { method = "ShopPurchase", source = "Carrot", location = "Anchor Town", gold = nil }
	M.ITEMS["Cloth"] = { method = "WorldPickup", source = "Cloth", location = "Anchor Town", gold = nil }
	M.ITEMS["Clown Cannon Ball"] = { method = "WorldPickup", source = "Clown Cannon Ball", location = "Clown Town", gold = nil }
	M.ITEMS["Clown Propaganda Poster"] = { method = "WorldPickup", source = "Clown Propaganda Poster", location = "Clown Town", gold = nil }
	M.ITEMS["Copper Bar"] = { method = "Crafting", source = "Furnace", location = "Anchor Town", gold = nil }
	M.ITEMS["Copper Ore"] = { method = "Mining", source = "Copper Ore", location = "Anchor Town", gold = nil }
	M.ITEMS["Crop"] = { method = "Farming", source = "Crop", location = "Maple Village", gold = nil }
	M.ITEMS["Denver The Dog"] = { method = "WorldPickup", source = "Denver The Dog", location = "Anchor Town", gold = nil }
	M.ITEMS["Dish"] = { method = "Cooking", source = "Dish", location = "Maple Village", gold = nil }
	M.ITEMS["Dumbbell"] = { method = "WorldPickup", source = "Dumbbell", location = "Clown Town", gold = nil }
	M.ITEMS["Egg"] = { method = "WorldPickup", source = "Egg", location = "Maple Village", gold = nil }
	M.ITEMS["Fist Wraps"] = { method = "WorldPickup", source = "Fist Wraps", location = "Clown Town", gold = nil }
	M.ITEMS["Flintlock"] = { method = "ShopPurchase", source = "Flintlock", location = "Anchor Town", gold = 150 }
	M.ITEMS["Grilled Fish"] = { method = "Cooking", source = "Grilled Fish", location = "Maple Village", gold = nil }
	M.ITEMS["Gunpowder"] = { method = "WorldPickup", source = "Gunpowder", location = "Clown Town", gold = nil }
	M.ITEMS["Henrietta"] = { method = "WorldPickup", source = "Martha Chicken", location = "Maple Village", gold = nil }
	M.ITEMS["Iron Ore"] = { method = "Mining", source = "Iron Ore", location = "Anchor Town", gold = nil }
	M.ITEMS["Lamp Oil"] = { method = "WorldPickup", source = "Lamp Oil Spawn", location = "Anchor Town", gold = nil }
	M.ITEMS["Lead"] = { method = "Crafting", source = "Furnace", location = "Maple Village", gold = nil }
	M.ITEMS["Lead Ball"] = { method = "WorldPickup", source = "Lead Ball", location = "Maple Village", gold = nil }
	M.ITEMS["Lead Ore"] = { method = "Mining", source = "Lead Ore", location = "Maple Village", gold = nil }
	M.ITEMS["Lemon"] = { method = "ShopPurchase", source = "Lemon", location = "Anchor Town", gold = nil }
	M.ITEMS["Mayor's Mustache"] = { method = "WorldPickup", source = "Mayor's Mustache", location = "Clown Town", gold = nil }
	M.ITEMS["Mythic+ Fish"] = { method = "Fishing", source = "Mythic+ Fish", location = "Anchor Town", gold = nil }
	M.ITEMS["Oil"] = { method = "WorldPickup", source = "Oil", location = "Maple Village", gold = nil }
	M.ITEMS["Omelette"] = { method = "Cooking", source = "Omelette", location = "Maple Village", gold = nil }
	M.ITEMS["Pepper"] = { method = "WorldPickup", source = "Pepper", location = "Maple Village", gold = nil }
	M.ITEMS["Pirate Fan Letter"] = { method = "EnemyDrop", source = "Corrupt Marine", location = "Anchor Town", gold = nil }
	M.ITEMS["Pirate Instructions"] = { method = "EnemyDrop", source = "Black Noir Officer", location = "Maple Village", gold = nil }
	M.ITEMS["Pirate's Ruby"] = { method = "WorldPickup", source = "Jokic", location = "Anchor Town", gold = nil }
	M.ITEMS["Raw Chicken"] = { method = "WorldPickup", source = "Raw Chicken", location = "Maple Village", gold = nil }
	M.ITEMS["Red Shell"] = { method = "WorldPickup", source = "Red Shell Spawn", location = "Anchor Town", gold = nil }
	M.ITEMS["Roast Chicken"] = { method = "Cooking", source = "Roast Chicken", location = "Maple Village", gold = nil }
	M.ITEMS["Rowboat"] = { method = "ShopPurchase", source = "Rowboat", location = "Anchor Town", gold = 50 }
	M.ITEMS["Rusty Pickaxe"] = { method = "ShopPurchase", source = "Rusty Pickaxe", location = "Anchor Town", gold = 25 }
	M.ITEMS["Sealed Satchel"] = { method = "WorldPickup", source = "Trust Dock Delivery", location = "Anchor Town", gold = nil }
	M.ITEMS["Seed"] = { method = "Farming", source = "Seed", location = "Maple Village", gold = nil }
	M.ITEMS["Servant's Journal"] = { method = "WorldPickup", source = "Servant's Journal Spawn", location = "Maple Village", gold = nil }
	M.ITEMS["Silver Miners Bracelet"] = { method = "WorldPickup", source = "Silver Miners Bracelet", location = "Anchor Town", gold = nil }
	M.ITEMS["Soggy Boot"] = { method = "EnemyDrop", source = "Treasure Hunter", location = "Anchor Town", gold = nil }
	M.ITEMS["Stick"] = { method = "WorldPickup", source = "Stick", location = "Anchor Town", gold = nil }
	M.ITEMS["Stolen Watch"] = { method = "EnemyDrop", source = "Corrupt Marine", location = "Anchor Town", gold = nil }
	M.ITEMS["Stone Ring"] = { method = "Crafting", source = "Stone Ring", location = "Anchor Town", gold = nil }
	M.ITEMS["Sturdy Stick"] = { method = "WorldPickup", source = "Sturdy Stick", location = "Clown Town", gold = nil }
	M.ITEMS["Tomato"] = { method = "Farming", source = "Tomato", location = "Maple Village", gold = nil }
	M.ITEMS["Tomato Crate"] = { method = "WorldPickup", source = "Tomato Crate", location = "Clown Town", gold = nil }
	M.ITEMS["Transponder Snail"] = { method = "ShopPurchase", source = "Transponder Snail", location = "Anchor Town", gold = 100 }
	M.ITEMS["Wade's Belongings"] = { method = "EnemyDrop", source = "Treasure Hunter", location = "Anchor Town", gold = nil }
	M.ITEMS["Wheat"] = { method = "Farming", source = "Wheat", location = "Maple Village", gold = nil }
	M.ITEMS["White Shell"] = { method = "WorldPickup", source = "Red Shell Spawn", location = "Anchor Town", gold = nil }
	M.ITEMS["Worm"] = { method = "ShopPurchase", source = "Worm", location = "Anchor Town", gold = nil }
	M.ITEMS["Yellow Shell"] = { method = "WorldPickup", source = "Red Shell Spawn", location = "Anchor Town", gold = nil }

	M.SUBGOALS["First Upgrade"] = {
		{ goal = "HaveGold", item = "Gold", method = nil, amount = 25 },
		{ goal = "AcquireItem", item = "Rusty Pickaxe", method = "ShopPurchase", amount = 1 },
		{ goal = "AcquireItem", item = "Copper Ore", method = "Mining", amount = 2 },
		{ goal = "AcquireItem", item = "Copper Bar", method = "Crafting", amount = 2 },
		{ goal = "Upgrade", item = "Flintlock", method = nil, amount = 1 },
	}

	M.STAGES["A Voice in a Shell|1|Talk|Officer Graves"] = { quest = "A Voice in a Shell", stage = 1, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Officer Graves", amount = 1, acquire = nil, source = "Officer Graves", location = "Anchor Town", marker = "Officer Graves", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["A Voice in a Shell|2|Purchase|Transponder Snail"] = { quest = "A Voice in a Shell", stage = 2, island = "Anchor Town", objective = "Purchase", goal = "AcquireItem", target = "Transponder Snail", amount = 1, acquire = "ShopPurchase", source = "Transponder Snail", location = "Anchor Town", marker = "SnailForSale", handler = "Shop.buy", status = "IMPLEMENTED" }
	M.STAGES["A Voice in a Shell|3|Equip|Transponder Snail"] = { quest = "A Voice in a Shell", stage = 3, island = "Anchor Town", objective = "Equip", goal = "Equip", target = "Transponder Snail", amount = 1, acquire = nil, source = "Transponder Snail", location = "Anchor Town", marker = nil, handler = "Equipment.equipNamed", status = "IMPLEMENTED" }
	M.STAGES["Advanced Training|1|Talk|Officer Graves [2]"] = { quest = "Advanced Training", stage = 1, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Officer Graves [2]", amount = 1, acquire = nil, source = "Officer Graves [2]", location = "Anchor Town", marker = "Officer Graves [2]", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Advanced Training|2|Talk|Wallace"] = { quest = "Advanced Training", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Wallace", amount = 1, acquire = nil, source = "Wallace", location = "Anchor Town", marker = "Wallace", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Advanced Training|2|Talk|Shiro"] = { quest = "Advanced Training", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Shiro", amount = 1, acquire = nil, source = "Shiro", location = "Anchor Town", marker = "Shiro", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Aim Training|1|Talk|Officer Graves"] = { quest = "Aim Training", stage = 1, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Officer Graves", amount = 1, acquire = nil, source = "Officer Graves", location = "Anchor Town", marker = "Officer Graves", handler = "Quest.talk", status = "UNRESOLVED" }
	M.STAGES["Aim Training|2|Shoot|Training Dummy"] = { quest = "Aim Training", stage = 2, island = "Anchor Town", objective = "Shoot", goal = "Kill", target = "Training Dummy", amount = 1, acquire = nil, source = "Training Dummy", location = "Anchor Town", marker = "TrainingDummy", handler = "Combat.attack", status = "UNRESOLVED" }
	M.STAGES["Aim Training|3|Talk|Officer Graves"] = { quest = "Aim Training", stage = 3, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Officer Graves", amount = 1, acquire = nil, source = "Officer Graves", location = "Anchor Town", marker = "Officer Graves", handler = "Quest.talk", status = "UNRESOLVED" }
	M.STAGES["Axe-Handed Tyrant|1|Kill|Axe-Hand Logan"] = { quest = "Axe-Handed Tyrant", stage = 1, island = "Anchor Town", objective = "Kill", goal = "Kill", target = "Axe-Hand Logan", amount = 1, acquire = nil, source = "Axe-Hand Logan", location = "Anchor Town", marker = "Axe-Hand Logan", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Basics|1|Talk|Officer Graves"] = { quest = "Basics", stage = 1, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Officer Graves", amount = 1, acquire = nil, source = "Officer Graves", location = "Anchor Town", marker = "Officer Graves", handler = "Quest.talk", status = "RUNTIME_VERIFIED" }
	M.STAGES["Basics|2|EquipSkill|Strong Punch"] = { quest = "Basics", stage = 2, island = "Anchor Town", objective = "EquipSkill", goal = "Skill", target = "Strong Punch", amount = 1, acquire = nil, source = "Strong Punch", location = "Anchor Town", marker = nil, handler = "Skills.equip/cast", status = "RUNTIME_VERIFIED" }
	M.STAGES["Basics|3|Cast|Strong Punch"] = { quest = "Basics", stage = 3, island = "Anchor Town", objective = "Cast", goal = "Skill", target = "Strong Punch", amount = 1, acquire = nil, source = "Strong Punch", location = "Anchor Town", marker = nil, handler = "Skills.equip/cast", status = "RUNTIME_VERIFIED" }
	M.STAGES["Basics|4|Talk|Officer Graves"] = { quest = "Basics", stage = 4, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Officer Graves", amount = 1, acquire = nil, source = "Officer Graves", location = "Anchor Town", marker = "Officer Graves", handler = "Quest.talk", status = "RUNTIME_VERIFIED" }
	M.STAGES["Basics|5|Required|TotalStatPoints"] = { quest = "Basics", stage = 5, island = "Anchor Town", objective = "Required", goal = "Invest", target = "TotalStatPoints", amount = 1, acquire = nil, source = nil, location = "Anchor Town", marker = nil, handler = "Stats.investMinimum", status = "RUNTIME_VERIFIED" }
	M.STAGES["Basics|6|Talk|Officer Graves"] = { quest = "Basics", stage = 6, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Officer Graves", amount = 1, acquire = nil, source = "Officer Graves", location = "Anchor Town", marker = "Officer Graves", handler = "Quest.talk", status = "RUNTIME_VERIFIED" }
	M.STAGES["Basics|7|Open|Logbook"] = { quest = "Basics", stage = 7, island = "Anchor Town", objective = "Open", goal = "OpenLogbook", target = "Logbook", amount = 1, acquire = nil, source = "Logbook", location = "Anchor Town", marker = nil, handler = "Quest.openLogbook", status = "RUNTIME_VERIFIED" }
	M.STAGES["Captain's Brat|1|Required|Level"] = { quest = "Captain's Brat", stage = 1, island = "Anchor Town", objective = "Required", goal = "LevelGate", target = "Level", amount = 1, acquire = nil, source = nil, location = "Anchor Town", marker = nil, handler = "DecisionEngine.levelFarm", status = "IMPLEMENTED" }
	M.STAGES["Captain's Brat|2|Talk|Granny Todo"] = { quest = "Captain's Brat", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Granny Todo", amount = 1, acquire = nil, source = "Granny Todo", location = "Anchor Town", marker = "Granny Todo", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Captain's Brat|3|Kill|Blonde Goblin"] = { quest = "Captain's Brat", stage = 3, island = "Anchor Town", objective = "Kill", goal = "Kill", target = "Blonde Goblin", amount = 1, acquire = nil, source = "Blonde Goblin", location = "Anchor Town", marker = "Helmeppo (Guards)", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Captain's Brat|3|Kill|Corrupt Guard"] = { quest = "Captain's Brat", stage = 3, island = "Anchor Town", objective = "Kill", goal = "Kill", target = "Corrupt Guard", amount = 2, acquire = nil, source = "Corrupt Guard", location = "Anchor Town", marker = "Corrupt Guard", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Captain's Brat|4|Talk|Granny Todo"] = { quest = "Captain's Brat", stage = 4, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Granny Todo", amount = 1, acquire = nil, source = "Granny Todo", location = "Anchor Town", marker = "Granny Todo", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Captive Swordsman|1|Talk|Captive Swordsman"] = { quest = "Captive Swordsman", stage = 1, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Captive Swordsman", amount = 1, acquire = nil, source = "Captive Swordsman", location = "Anchor Town", marker = "Captive Swordsman", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Captive Swordsman|2|CollectLocalItem|Captive Swordsman's Swords"] = { quest = "Captive Swordsman", stage = 2, island = "Anchor Town", objective = "CollectLocalItem", goal = "AcquireItem", target = "Captive Swordsman's Swords", amount = 1, acquire = "WorldPickup", source = "Captive Swordsman's Swords", location = "Anchor Town", marker = "Captive Swordsman's Swords", handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Captive Swordsman|3|Talk|Captive Swordsman"] = { quest = "Captive Swordsman", stage = 3, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Captive Swordsman", amount = 1, acquire = nil, source = "Captive Swordsman", location = "Anchor Town", marker = "Captive Swordsman", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Feral Dog|1|Required|Level"] = { quest = "Feral Dog", stage = 1, island = "Anchor Town", objective = "Required", goal = "LevelGate", target = "Level", amount = 1, acquire = nil, source = nil, location = "Anchor Town", marker = nil, handler = "DecisionEngine.levelFarm", status = "IMPLEMENTED" }
	M.STAGES["Feral Dog|2|Kill|Blonde Goblin"] = { quest = "Feral Dog", stage = 2, island = "Anchor Town", objective = "Kill", goal = "Kill", target = "Blonde Goblin", amount = 1, acquire = nil, source = "Blonde Goblin", location = "Anchor Town", marker = "Helmeppo (Soro)", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Feral Dog|2|Kill|Soro"] = { quest = "Feral Dog", stage = 2, island = "Anchor Town", objective = "Kill", goal = "Kill", target = "Soro", amount = 1, acquire = nil, source = "Soro", location = "Anchor Town", marker = "Soro", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["First Upgrade|1|Talk|Blacksmith Shinozaki"] = { quest = "First Upgrade", stage = 1, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Blacksmith Shinozaki", amount = 1, acquire = nil, source = "Blacksmith Shinozaki", location = "Anchor Town", marker = "Blacksmith Shinozaki", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["First Upgrade|2|Collect|Rusty Pickaxe"] = { quest = "First Upgrade", stage = 2, island = "Anchor Town", objective = "Collect", goal = "AcquireItem", target = "Rusty Pickaxe", amount = 1, acquire = "ShopPurchase", source = "Rusty Pickaxe", location = "Anchor Town", marker = "Rusty Pickaxe", handler = "Shop.buy", status = "IMPLEMENTED" }
	M.STAGES["First Upgrade|3|Collect|Copper Ore"] = { quest = "First Upgrade", stage = 3, island = "Anchor Town", objective = "Collect", goal = "AcquireItem", target = "Copper Ore", amount = 2, acquire = "Mining", source = "Copper Ore", location = "Anchor Town", marker = "Copper Ore", handler = "LifeSkills.mineToward", status = "IMPLEMENTED" }
	M.STAGES["First Upgrade|4|Talk|Blacksmith Shinozaki"] = { quest = "First Upgrade", stage = 4, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Blacksmith Shinozaki", amount = 1, acquire = nil, source = "Blacksmith Shinozaki", location = "Anchor Town", marker = "Blacksmith Shinozaki", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["First Upgrade|5|Smelt|Copper Bar"] = { quest = "First Upgrade", stage = 5, island = "Anchor Town", objective = "Smelt", goal = "AcquireItem", target = "Copper Bar", amount = 2, acquire = "Crafting", source = "Furnace", location = "Anchor Town", marker = "Furnace", handler = "LifeSkills.smeltToward", status = "IMPLEMENTED" }
	M.STAGES["First Upgrade|6|Upgrade|Flintlock"] = { quest = "First Upgrade", stage = 6, island = "Anchor Town", objective = "Upgrade", goal = "Upgrade", target = "Flintlock", amount = 1, acquire = nil, source = "Flintlock", location = "Anchor Town", marker = "Anvil", handler = "Equipment.upgradeNamed", status = "IMPLEMENTED" }
	M.STAGES["Gate of Authority|1|Open|Marine Gate"] = { quest = "Gate of Authority", stage = 1, island = "Anchor Town", objective = "Open", goal = "Interact", target = "Marine Gate", amount = 1, acquire = nil, source = "Marine Metal Gate", location = "Anchor Town", marker = "Marine Metal Gate", handler = "Quest.waitAtMarineGate", status = "RUNTIME_VERIFIED" }
	M.STAGES["Gearing Up|1|Sell|Stolen Watch"] = { quest = "Gearing Up", stage = 1, island = "Anchor Town", objective = "Sell", goal = "Sell", target = "Stolen Watch", amount = 1, acquire = nil, source = "Stolen Watch", location = "Anchor Town", marker = "Merchant", handler = "Shop.sellNamed", status = "IMPLEMENTED" }
	M.STAGES["Gearing Up|2|Purchase|Flintlock"] = { quest = "Gearing Up", stage = 2, island = "Anchor Town", objective = "Purchase", goal = "AcquireItem", target = "Flintlock", amount = 1, acquire = "ShopPurchase", source = "Flintlock", location = "Anchor Town", marker = "FlintlockForSale", handler = "Shop.buy", status = "IMPLEMENTED" }
	M.STAGES["Gearing Up|3|Equip|Flintlock"] = { quest = "Gearing Up", stage = 3, island = "Anchor Town", objective = "Equip", goal = "Equip", target = "Flintlock", amount = 1, acquire = nil, source = "Flintlock", location = "Anchor Town", marker = nil, handler = "Equipment.equipViaBackpack", status = "IMPLEMENTED" }
	M.STAGES["Gearing Up|4|Shoot|Training Dummy"] = { quest = "Gearing Up", stage = 4, island = "Anchor Town", objective = "Shoot", goal = "Kill", target = "Training Dummy", amount = 1, acquire = nil, source = "Training Dummy", location = "Anchor Town", marker = "TrainingDummy", handler = "Combat.shootUntilCredit", status = "IMPLEMENTED" }
	M.STAGES["Introduction|1|Talk|Officer Graves"] = { quest = "Introduction", stage = 1, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Officer Graves", amount = 1, acquire = nil, source = "Officer Graves", location = "Anchor Town", marker = "Officer Graves", handler = "Quest.talk", status = "RUNTIME_VERIFIED" }
	M.STAGES["Introduction|2|Hit|Training Dummy"] = { quest = "Introduction", stage = 2, island = "Anchor Town", objective = "Hit", goal = "Kill", target = "Training Dummy", amount = 4, acquire = nil, source = "Training Dummy", location = "Anchor Town", marker = "TrainingDummy", handler = "Combat.attack", status = "RUNTIME_VERIFIED" }
	M.STAGES["Introduction|3|Dash|Press Q"] = { quest = "Introduction", stage = 3, island = "Anchor Town", objective = "Dash", goal = "CombatAction", target = "Press Q", amount = 2, acquire = nil, source = nil, location = "Anchor Town", marker = nil, handler = "Combat.dash/block", status = "RUNTIME_VERIFIED" }
	M.STAGES["Introduction|4|Block|Hold F"] = { quest = "Introduction", stage = 4, island = "Anchor Town", objective = "Block", goal = "CombatAction", target = "Hold F", amount = 1, acquire = nil, source = nil, location = "Anchor Town", marker = nil, handler = "Combat.dash/block", status = "RUNTIME_VERIFIED" }
	M.STAGES["Introduction|5|Talk|Officer Graves"] = { quest = "Introduction", stage = 5, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Officer Graves", amount = 1, acquire = nil, source = "Officer Graves", location = "Anchor Town", marker = "Officer Graves", handler = "Quest.talk", status = "RUNTIME_VERIFIED" }
	M.STAGES["Leveling Skill|1|Level|Strong Punch"] = { quest = "Leveling Skill", stage = 1, island = "Anchor Town", objective = "Level", goal = "Other", target = "Strong Punch", amount = 1, acquire = nil, source = "Strong Punch", location = "Anchor Town", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Leveling Skill|1|Level|Gunshot"] = { quest = "Leveling Skill", stage = 1, island = "Anchor Town", objective = "Level", goal = "Other", target = "Gunshot", amount = 1, acquire = nil, source = "Gunshot", location = "Anchor Town", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Leveling Skill|2|Talk|Officer Graves"] = { quest = "Leveling Skill", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Officer Graves", amount = 1, acquire = nil, source = "Officer Graves", location = "Anchor Town", marker = "Officer Graves", handler = "Quest.talk", status = "UNRESOLVED" }
	M.STAGES["Pirate Fan Letter|1|Talk|Officer Graves"] = { quest = "Pirate Fan Letter", stage = 1, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Officer Graves", amount = 1, acquire = nil, source = "Officer Graves", location = "Anchor Town", marker = "Officer Graves", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Pirate Fan Letter|2|Talk|Koro"] = { quest = "Pirate Fan Letter", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Koro", amount = 1, acquire = nil, source = "Koro", location = "Anchor Town", marker = "Koro", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Pirate Fan Letter|3|Collect|Pirate Fan Letter"] = { quest = "Pirate Fan Letter", stage = 3, island = "Anchor Town", objective = "Collect", goal = "AcquireItem", target = "Pirate Fan Letter", amount = 1, acquire = "EnemyDrop", source = "Corrupt Marine", location = "Anchor Town", marker = "Corrupt Marine", handler = "Acquire.AcquireFromEnemyDrop", status = "IMPLEMENTED" }
	M.STAGES["Pirate Fan Letter|4|Talk|Koro"] = { quest = "Pirate Fan Letter", stage = 4, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Koro", amount = 1, acquire = nil, source = "Koro", location = "Anchor Town", marker = "Koro", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Setting Sail|1|Required|Level"] = { quest = "Setting Sail", stage = 1, island = "Anchor Town", objective = "Required", goal = "LevelGate", target = "Level", amount = 30, acquire = nil, source = nil, location = "Anchor Town", marker = nil, handler = "DecisionEngine.levelFarm", status = "IMPLEMENTED" }
	M.STAGES["Setting Sail|2|Talk|Officer Graves"] = { quest = "Setting Sail", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Officer Graves", amount = 1, acquire = nil, source = "Officer Graves", location = "Anchor Town", marker = "Officer Graves", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Setting Sail|3|Purchase|Rowboat"] = { quest = "Setting Sail", stage = 3, island = "Anchor Town", objective = "Purchase", goal = "AcquireItem", target = "Rowboat", amount = 1, acquire = "ShopPurchase", source = "Rowboat", location = "Anchor Town", marker = "RowboatForSale", handler = "Shop.buy", status = "IMPLEMENTED" }
	M.STAGES["Setting Sail|4|Spawn|Rowboat"] = { quest = "Setting Sail", stage = 4, island = "Anchor Town", objective = "Spawn", goal = "Spawn", target = "Rowboat", amount = 1, acquire = nil, source = "Rowboat", location = "Anchor Town", marker = "Ship Spawner", handler = "Boat.spawnRowboat", status = "IMPLEMENTED" }
	M.STAGES["Setting Sail|5|Talk|Mayor Kiyoshi"] = { quest = "Setting Sail", stage = 5, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Mayor Kiyoshi", amount = 1, acquire = nil, source = "Mayor Kiyoshi", location = "Anchor Town", marker = "Mayor Kiyoshi", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Tea Party Crashers|1|Talk|Maeve"] = { quest = "Tea Party Crashers", stage = 1, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Maeve", amount = 1, acquire = nil, source = "Maeve", location = "Anchor Town", marker = "Maeve", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Tea Party Crashers|2|Kill|Corrupt Marine Officer"] = { quest = "Tea Party Crashers", stage = 2, island = "Anchor Town", objective = "Kill", goal = "Kill", target = "Corrupt Marine Officer", amount = 7, acquire = nil, source = "Corrupt Swordsman Officer", location = "Anchor Town", marker = "Corrupt Marine Officer", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Tea Party Crashers|2|Kill|Marine Snitch"] = { quest = "Tea Party Crashers", stage = 2, island = "Anchor Town", objective = "Kill", goal = "Kill", target = "Marine Snitch", amount = 1, acquire = nil, source = "Marine Snitch", location = "Anchor Town", marker = "Marine Snitch", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Tea Party Crashers|3|Talk|Maeve"] = { quest = "Tea Party Crashers", stage = 3, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Maeve", amount = 1, acquire = nil, source = "Maeve", location = "Anchor Town", marker = "Maeve", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["The Hoarder|1|Required|Level"] = { quest = "The Hoarder", stage = 1, island = "Anchor Town", objective = "Required", goal = "LevelGate", target = "Level", amount = 1, acquire = nil, source = nil, location = "Anchor Town", marker = nil, handler = "DecisionEngine.levelFarm", status = "IMPLEMENTED" }
	M.STAGES["The Hoarder|2|Talk|Troubled Civilian"] = { quest = "The Hoarder", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Troubled Civilian", amount = 1, acquire = nil, source = "Troubled Civilian", location = "Anchor Town", marker = "Troubled Civilian", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["The Hoarder|3|Kill|Afuaru, The Hoarder"] = { quest = "The Hoarder", stage = 3, island = "Anchor Town", objective = "Kill", goal = "Kill", target = "Afuaru, The Hoarder", amount = 1, acquire = nil, source = "Afuaru, The Hoarder", location = "Anchor Town", marker = "Afuaru, The Hoarder", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["The Hoarder|3|Collect|Afuaru's Key"] = { quest = "The Hoarder", stage = 3, island = "Anchor Town", objective = "Collect", goal = "AcquireItem", target = "Afuaru's Key", amount = 1, acquire = "BossDrop", source = "Afuaru, The Hoarder", location = "Anchor Town", marker = "Afuaru, The Hoarder", handler = "Acquire.AcquireFromEnemyDrop", status = "IMPLEMENTED" }
	M.STAGES["The Hoarder|4|Unlock|Afuaru's Gate"] = { quest = "The Hoarder", stage = 4, island = "Anchor Town", objective = "Unlock", goal = "Interact", target = "Afuaru's Gate", amount = 1, acquire = nil, source = "Afuaru's Gate", location = "Anchor Town", marker = "Afuaru's Gate", handler = "Quest.unlock", status = "IMPLEMENTED" }
	M.STAGES["The Hoarder|5|Loot|Afuaru's Chests"] = { quest = "The Hoarder", stage = 5, island = "Anchor Town", objective = "Loot", goal = "Interact", target = "Afuaru's Chests", amount = 5, acquire = "Chest", source = "Afuaru's Chests", location = "Anchor Town", marker = nil, handler = "Chest.lootUntil", status = "IMPLEMENTED" }
	M.STAGES["The Hoarder|6|Talk|Troubled Civilian"] = { quest = "The Hoarder", stage = 6, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Troubled Civilian", amount = 1, acquire = nil, source = "Troubled Civilian", location = "Anchor Town", marker = "Troubled Civilian", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["A Joke Gone Too Far|1|Talk|Clowny D. Clown"] = { quest = "A Joke Gone Too Far", stage = 1, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Clowny D. Clown", amount = 1, acquire = nil, source = "Clowny D. Clown", location = "Clown Town", marker = "Clowny D. Clown", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["A Joke Gone Too Far|2|Kill|Clown"] = { quest = "A Joke Gone Too Far", stage = 2, island = "Clown Town", objective = "Kill", goal = "Kill", target = "Clown", amount = 7, acquire = nil, source = "Clown", location = "Clown Town", marker = "Clown Marker", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["A Joke Gone Too Far|3|Talk|Clowny D. Clown"] = { quest = "A Joke Gone Too Far", stage = 3, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Clowny D. Clown", amount = 1, acquire = nil, source = "Clowny D. Clown", location = "Clown Town", marker = "Clowny D. Clown", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Butcher's Business|1|Required|Level"] = { quest = "Butcher's Business", stage = 1, island = "Clown Town", objective = "Required", goal = "LevelGate", target = "Level", amount = 1, acquire = nil, source = nil, location = "Clown Town", marker = nil, handler = "DecisionEngine.levelFarm", status = "IMPLEMENTED" }
	M.STAGES["Butcher's Business|2|Talk|Billy B."] = { quest = "Butcher's Business", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Billy B.", amount = 1, acquire = nil, source = "Billy B.", location = "Clown Town", marker = "Billy B.", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Butcher's Business|3|Kill|Killer Clown"] = { quest = "Butcher's Business", stage = 3, island = "Clown Town", objective = "Kill", goal = "Kill", target = "Killer Clown", amount = 7, acquire = nil, source = "Killer Clown", location = "Clown Town", marker = "Killer Clown Marker", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Butcher's Business|4|Talk|Billy B."] = { quest = "Butcher's Business", stage = 4, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Billy B.", amount = 1, acquire = nil, source = "Billy B.", location = "Clown Town", marker = "Billy B.", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Circus Suppliers|1|Required|Level"] = { quest = "Circus Suppliers", stage = 1, island = "Clown Town", objective = "Required", goal = "LevelGate", target = "Level", amount = 1, acquire = nil, source = nil, location = "Clown Town", marker = nil, handler = "DecisionEngine.levelFarm", status = "IMPLEMENTED" }
	M.STAGES["Circus Suppliers|2|Talk|Mayor Kiyoshi"] = { quest = "Circus Suppliers", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Mayor Kiyoshi", amount = 1, acquire = nil, source = "Mayor Kiyoshi", location = "Clown Town", marker = "Mayor Kiyoshi", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Circus Suppliers|3|Kill|Circus Supplier"] = { quest = "Circus Suppliers", stage = 3, island = "Clown Town", objective = "Kill", goal = "Kill", target = "Circus Supplier", amount = 2, acquire = nil, source = "Circus Supplier", location = "Clown Town", marker = nil, handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Circus Suppliers|4|Talk|Mayor Kiyoshi"] = { quest = "Circus Suppliers", stage = 4, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Mayor Kiyoshi", amount = 1, acquire = nil, source = "Mayor Kiyoshi", location = "Clown Town", marker = "Mayor Kiyoshi", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Clown Captives|1|Talk|Mayor Kiyoshi"] = { quest = "Clown Captives", stage = 1, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Mayor Kiyoshi", amount = 1, acquire = nil, source = "Mayor Kiyoshi", location = "Clown Town", marker = "Mayor Kiyoshi", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Clown Captives|2|Free|Child Captive"] = { quest = "Clown Captives", stage = 2, island = "Clown Town", objective = "Free", goal = "Interact", target = "Child Captive", amount = 2, acquire = nil, source = "Child Captive", location = "Clown Town", marker = "Child Captive", handler = "Quest.goTagged", status = "IMPLEMENTED" }
	M.STAGES["Clown Captives|2|Free|Adult Captive"] = { quest = "Clown Captives", stage = 2, island = "Clown Town", objective = "Free", goal = "Interact", target = "Adult Captive", amount = 4, acquire = nil, source = "Adult Captive", location = "Clown Town", marker = "Adult Captive", handler = "Quest.goTagged", status = "IMPLEMENTED" }
	M.STAGES["Clown Captives|3|Talk|Mayor Kiyoshi"] = { quest = "Clown Captives", stage = 3, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Mayor Kiyoshi", amount = 1, acquire = nil, source = "Mayor Kiyoshi", location = "Clown Town", marker = "Mayor Kiyoshi", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Clown Town's Militia|1|Talk|Mayor Kiyoshi [2]"] = { quest = "Clown Town's Militia", stage = 1, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Mayor Kiyoshi [2]", amount = 1, acquire = nil, source = "Mayor Kiyoshi [2]", location = "Clown Town", marker = "Mayor Kiyoshi [2]", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Clown Town's Militia|2|CollectLocalItem|Sturdy Stick"] = { quest = "Clown Town's Militia", stage = 2, island = "Clown Town", objective = "CollectLocalItem", goal = "AcquireItem", target = "Sturdy Stick", amount = 1, acquire = "WorldPickup", source = "Sturdy Stick", location = "Clown Town", marker = "Sturdy Stick", handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Clown Town's Militia|2|CollectLocalItem|Tomato Crate"] = { quest = "Clown Town's Militia", stage = 2, island = "Clown Town", objective = "CollectLocalItem", goal = "AcquireItem", target = "Tomato Crate", amount = 1, acquire = "WorldPickup", source = "Tomato Crate", location = "Clown Town", marker = "Tomato Crate", handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Clown Town's Militia|2|CollectLocalItem|Fist Wraps"] = { quest = "Clown Town's Militia", stage = 2, island = "Clown Town", objective = "CollectLocalItem", goal = "AcquireItem", target = "Fist Wraps", amount = 1, acquire = "WorldPickup", source = "Fist Wraps", location = "Clown Town", marker = "Fist Wraps", handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Clown Town's Militia|3|Talk|Clown Town Angry Civilian 1"] = { quest = "Clown Town's Militia", stage = 3, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Clown Town Angry Civilian 1", amount = 1, acquire = nil, source = "Clown Town Angry Civilian 1", location = "Clown Town", marker = "Clown Town Angry Civilian 1", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Clown Town's Militia|3|Talk|Clown Town Angry Civilian 2"] = { quest = "Clown Town's Militia", stage = 3, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Clown Town Angry Civilian 2", amount = 1, acquire = nil, source = "Clown Town Angry Civilian 2", location = "Clown Town", marker = "Clown Town Angry Civilian 2", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Clown Town's Militia|3|Talk|Clown Town Angry Civilian 3"] = { quest = "Clown Town's Militia", stage = 3, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Clown Town Angry Civilian 3", amount = 1, acquire = nil, source = "Clown Town Angry Civilian 3", location = "Clown Town", marker = "Clown Town Angry Civilian 3", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Escort The Mayor|1|Required|Level"] = { quest = "Escort The Mayor", stage = 1, island = "Clown Town", objective = "Required", goal = "LevelGate", target = "Level", amount = 1, acquire = nil, source = nil, location = "Clown Town", marker = nil, handler = "DecisionEngine.levelFarm", status = "IMPLEMENTED" }
	M.STAGES["Escort The Mayor|2|Talk|Mayor Kiyoshi"] = { quest = "Escort The Mayor", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Mayor Kiyoshi", amount = 1, acquire = nil, source = "Mayor Kiyoshi", location = "Clown Town", marker = "Mayor Kiyoshi", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Escort The Mayor|3|Escort|Mayor Kiyoshi"] = { quest = "Escort The Mayor", stage = 3, island = "Clown Town", objective = "Escort", goal = "Escort", target = "Mayor Kiyoshi", amount = 1, acquire = nil, source = "Mayor Kiyoshi", location = "Clown Town", marker = nil, handler = "Quest.escort", status = "RUNTIME_REQUIRED" }
	M.STAGES["Escort The Mayor|4|Talk|Mayor Kiyoshi [2]"] = { quest = "Escort The Mayor", stage = 4, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Mayor Kiyoshi [2]", amount = 1, acquire = nil, source = "Mayor Kiyoshi [2]", location = "Clown Town", marker = "Mayor Kiyoshi [2]", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Journey to Maple Village|1|Talk|Mayor Kiyoshi"] = { quest = "Journey to Maple Village", stage = 1, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Mayor Kiyoshi", amount = 1, acquire = nil, source = "Mayor Kiyoshi", location = "Clown Town", marker = "Mayor Kiyoshi", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Journey to Maple Village|2|Required|Level"] = { quest = "Journey to Maple Village", stage = 2, island = "Clown Town", objective = "Required", goal = "LevelGate", target = "Level", amount = 70, acquire = nil, source = nil, location = "Clown Town", marker = nil, handler = "DecisionEngine.levelFarm", status = "IMPLEMENTED" }
	M.STAGES["Journey to Maple Village|3|Reach Maple Village|"] = { quest = "Journey to Maple Village", stage = 3, island = "Clown Town", objective = "Reach Maple Village", goal = "Travel", target = "", amount = 1, acquire = nil, source = "Maple Village", location = "Clown Town", marker = "Maple Village Marker", handler = "Travel.goIsland", status = "IMPLEMENTED" }
	M.STAGES["Lion's Victim|1|Required|Level"] = { quest = "Lion's Victim", stage = 1, island = "Clown Town", objective = "Required", goal = "LevelGate", target = "Level", amount = 1, acquire = nil, source = nil, location = "Clown Town", marker = nil, handler = "DecisionEngine.levelFarm", status = "IMPLEMENTED" }
	M.STAGES["Lion's Victim|2|Talk|Stephon"] = { quest = "Lion's Victim", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Stephon", amount = 1, acquire = nil, source = "Stephon", location = "Clown Town", marker = "Stephon", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Lion's Victim|3|Kill|Circus Lion"] = { quest = "Lion's Victim", stage = 3, island = "Clown Town", objective = "Kill", goal = "Kill", target = "Circus Lion", amount = 1, acquire = nil, source = "Circus Lion", location = "Clown Town", marker = "Beast Tamer Marker", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Lion's Victim|3|Kill|Beast Tamer"] = { quest = "Lion's Victim", stage = 3, island = "Clown Town", objective = "Kill", goal = "Kill", target = "Beast Tamer", amount = 1, acquire = nil, source = "Beast Tamer", location = "Clown Town", marker = "Beast Tamer Marker", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Lion's Victim|4|Talk|Stephon"] = { quest = "Lion's Victim", stage = 4, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Stephon", amount = 1, acquire = nil, source = "Stephon", location = "Clown Town", marker = "Stephon", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Mayor's Stache|1|Talk|Mayor Kiyoshi [2]"] = { quest = "Mayor's Stache", stage = 1, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Mayor Kiyoshi [2]", amount = 1, acquire = nil, source = "Mayor Kiyoshi [2]", location = "Clown Town", marker = "Mayor Kiyoshi [2]", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Mayor's Stache|2|CollectLocalItem|Mayor's Mustache"] = { quest = "Mayor's Stache", stage = 2, island = "Clown Town", objective = "CollectLocalItem", goal = "AcquireItem", target = "Mayor's Mustache", amount = 1, acquire = "WorldPickup", source = "Mayor's Mustache", location = "Clown Town", marker = "Mayor's Mustache", handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Mayor's Stache|3|Talk|Mayor Kiyoshi [2]"] = { quest = "Mayor's Stache", stage = 3, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Mayor Kiyoshi [2]", amount = 1, acquire = nil, source = "Mayor Kiyoshi [2]", location = "Clown Town", marker = "Mayor Kiyoshi [2]", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Revenge of the Nibblebottom|1|Talk|Johnny Nibblebottom"] = { quest = "Revenge of the Nibblebottom", stage = 1, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Johnny Nibblebottom", amount = 1, acquire = nil, source = "Johnny Nibblebottom", location = "Clown Town", marker = "Johnny Nibblebottom", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Revenge of the Nibblebottom|2|Kill|Clown Officer"] = { quest = "Revenge of the Nibblebottom", stage = 2, island = "Clown Town", objective = "Kill", goal = "Kill", target = "Clown Officer", amount = 5, acquire = nil, source = "Clown Officer", location = "Clown Town", marker = nil, handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Revenge of the Nibblebottom|2|Destroy|Air Balloon"] = { quest = "Revenge of the Nibblebottom", stage = 2, island = "Clown Town", objective = "Destroy", goal = "Kill", target = "Air Balloon", amount = 1, acquire = nil, source = "Air Balloon", location = "Clown Town", marker = nil, handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Revenge of the Nibblebottom|3|Talk|Johnny Nibblebottom"] = { quest = "Revenge of the Nibblebottom", stage = 3, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Johnny Nibblebottom", amount = 1, acquire = nil, source = "Johnny Nibblebottom", location = "Clown Town", marker = "Johnny Nibblebottom", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Sabotage The Cannon|1|Required|Level"] = { quest = "Sabotage The Cannon", stage = 1, island = "Clown Town", objective = "Required", goal = "LevelGate", target = "Level", amount = 1, acquire = nil, source = nil, location = "Clown Town", marker = nil, handler = "DecisionEngine.levelFarm", status = "IMPLEMENTED" }
	M.STAGES["Sabotage The Cannon|2|Talk|Clowny D. Clown"] = { quest = "Sabotage The Cannon", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Clowny D. Clown", amount = 1, acquire = nil, source = "Clowny D. Clown", location = "Clown Town", marker = "Clowny D. Clown", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Sabotage The Cannon|3|Destroy|Muggy Cannon"] = { quest = "Sabotage The Cannon", stage = 3, island = "Clown Town", objective = "Destroy", goal = "Kill", target = "Muggy Cannon", amount = 1, acquire = nil, source = "Muggy Cannon", location = "Clown Town", marker = "Muggy Cannon", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Sabotage The Cannon|4|Talk|Clowny D. Clown"] = { quest = "Sabotage The Cannon", stage = 4, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Clowny D. Clown", amount = 1, acquire = nil, source = "Clowny D. Clown", location = "Clown Town", marker = "Clowny D. Clown", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Stephon's Tormentor|1|Required|Level"] = { quest = "Stephon's Tormentor", stage = 1, island = "Clown Town", objective = "Required", goal = "LevelGate", target = "Level", amount = 1, acquire = nil, source = nil, location = "Clown Town", marker = nil, handler = "DecisionEngine.levelFarm", status = "IMPLEMENTED" }
	M.STAGES["Stephon's Tormentor|2|Talk|Stephon"] = { quest = "Stephon's Tormentor", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Stephon", amount = 1, acquire = nil, source = "Stephon", location = "Clown Town", marker = "Stephon", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Stephon's Tormentor|3|Kill|\"Barrel Clown\" Binki"] = { quest = "Stephon's Tormentor", stage = 3, island = "Clown Town", objective = "Kill", goal = "Kill", target = "\"Barrel Clown\" Binki", amount = 1, acquire = nil, source = "\"Barrel Clown\" Binki", location = "Clown Town", marker = nil, handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Stephon's Tormentor|4|Talk|Stephon"] = { quest = "Stephon's Tormentor", stage = 4, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Stephon", amount = 1, acquire = nil, source = "Stephon", location = "Clown Town", marker = "Stephon", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["The Ringmaster|1|Required|Level"] = { quest = "The Ringmaster", stage = 1, island = "Clown Town", objective = "Required", goal = "LevelGate", target = "Level", amount = 1, acquire = nil, source = nil, location = "Clown Town", marker = nil, handler = "DecisionEngine.levelFarm", status = "IMPLEMENTED" }
	M.STAGES["The Ringmaster|2|Talk|Mayor Kiyoshi [2]"] = { quest = "The Ringmaster", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Mayor Kiyoshi [2]", amount = 1, acquire = nil, source = "Mayor Kiyoshi [2]", location = "Clown Town", marker = "Mayor Kiyoshi [2]", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["The Ringmaster|3|Kill|Choppy The Clown"] = { quest = "The Ringmaster", stage = 3, island = "Clown Town", objective = "Kill", goal = "Kill", target = "Choppy The Clown", amount = 1, acquire = nil, source = "Choppy The Clown", location = "Clown Town", marker = "Choppy The Clown Marker", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["The Ringmaster|4|Talk|Mayor Kiyoshi [2]"] = { quest = "The Ringmaster", stage = 4, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Mayor Kiyoshi [2]", amount = 1, acquire = nil, source = "Mayor Kiyoshi [2]", location = "Clown Town", marker = "Mayor Kiyoshi [2]", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Destroy the Signalers|1|Destroy|North Camp Signal Fire"] = { quest = "Destroy the Signalers", stage = 1, island = "Maple Village", objective = "Destroy", goal = "Kill", target = "North Camp Signal Fire", amount = 1, acquire = nil, source = "North Camp Signal Fire", location = "Maple Village", marker = "North Camp Signal Fire", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Destroy the Signalers|1|Destroy|South Camp Signal Fire"] = { quest = "Destroy the Signalers", stage = 1, island = "Maple Village", objective = "Destroy", goal = "Kill", target = "South Camp Signal Fire", amount = 1, acquire = nil, source = "South Camp Signal Fire", location = "Maple Village", marker = "South Camp Signal Fire", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Destroy the Signalers|1|Destroy|Overlook Signal Fire"] = { quest = "Destroy the Signalers", stage = 1, island = "Maple Village", objective = "Destroy", goal = "Kill", target = "Overlook Signal Fire", amount = 1, acquire = nil, source = "Overlook Signal Fire", location = "Maple Village", marker = "Overlook Signal Fire", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Destroy the Signalers|2|Talk|Captain Esopo"] = { quest = "Destroy the Signalers", stage = 2, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Captain Esopo", amount = 1, acquire = nil, source = "Captain Esopo", location = "Maple Village", marker = "Captain Esopo (Dialogue)", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Expose the Butler|1|Investigate The Garden|"] = { quest = "Expose the Butler", stage = 1, island = "Maple Village", objective = "Investigate The Garden", goal = "Interact", target = "", amount = 1, acquire = nil, source = "Mansion Garden Marker", location = "Maple Village", marker = "Mansion Garden Marker", handler = "Quest.goTagged", status = "IMPLEMENTED" }
	M.STAGES["Expose the Butler|2|Talk|Frightened Servant"] = { quest = "Expose the Butler", stage = 2, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Frightened Servant", amount = 1, acquire = nil, source = "Frightened Servant", location = "Maple Village", marker = "Frightened Servant (Dialogue)", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Expose the Butler|2|Kill|Scratch"] = { quest = "Expose the Butler", stage = 2, island = "Maple Village", objective = "Kill", goal = "Kill", target = "Scratch", amount = 1, acquire = nil, source = "Scratch", location = "Maple Village", marker = "Frightened Servant (Dialogue)", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Expose the Butler|2|Kill|Grab"] = { quest = "Expose the Butler", stage = 2, island = "Maple Village", objective = "Kill", goal = "Kill", target = "Grab", amount = 1, acquire = nil, source = "Grab", location = "Maple Village", marker = "Frightened Servant (Dialogue)", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Expose the Butler|3|Talk|Frightened Servant"] = { quest = "Expose the Butler", stage = 3, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Frightened Servant", amount = 1, acquire = nil, source = "Frightened Servant", location = "Maple Village", marker = "Frightened Servant (Dialogue)", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Expose the Butler|4|Talk|Captain Esopo"] = { quest = "Expose the Butler", stage = 4, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Captain Esopo", amount = 1, acquire = nil, source = "Captain Esopo", location = "Maple Village", marker = "Captain Esopo (Dialogue)", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Missing Servants|1|Talk|Kuro"] = { quest = "Missing Servants", stage = 1, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Kuro", amount = 1, acquire = nil, source = "Kuro", location = "Maple Village", marker = "Kuro (Dialogue)", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Missing Servants|2|Investigate The Garden|"] = { quest = "Missing Servants", stage = 2, island = "Maple Village", objective = "Investigate The Garden", goal = "Interact", target = "", amount = 1, acquire = nil, source = "Mansion Garden Marker", location = "Maple Village", marker = "Mansion Garden Marker", handler = "Quest.goTagged", status = "IMPLEMENTED" }
	M.STAGES["Missing Servants|2|Investigate The Fountain|"] = { quest = "Missing Servants", stage = 2, island = "Maple Village", objective = "Investigate The Fountain", goal = "Interact", target = "", amount = 1, acquire = nil, source = "Mansion Fountain Marker", location = "Maple Village", marker = "Mansion Fountain Marker", handler = "Quest.goTagged", status = "IMPLEMENTED" }
	M.STAGES["Missing Servants|3|CollectLocalItem|Servant's Journal"] = { quest = "Missing Servants", stage = 3, island = "Maple Village", objective = "CollectLocalItem", goal = "AcquireItem", target = "Servant's Journal", amount = 1, acquire = "WorldPickup", source = "Servant's Journal Spawn", location = "Maple Village", marker = "Servant's Journal Spawn", handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Missing Servants|4|Talk|Captain Esopo"] = { quest = "Missing Servants", stage = 4, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Captain Esopo", amount = 1, acquire = nil, source = "Captain Esopo", location = "Maple Village", marker = "Captain Esopo (Dialogue)", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Pirate Instructions|1|Collect|Pirate Instructions"] = { quest = "Pirate Instructions", stage = 1, island = "Maple Village", objective = "Collect", goal = "AcquireItem", target = "Pirate Instructions", amount = 1, acquire = "EnemyDrop", source = "Black Noir Officer", location = "Maple Village", marker = "Black Noir Officer Marker", handler = "Acquire.AcquireFromEnemyDrop", status = "IMPLEMENTED" }
	M.STAGES["Pirate Instructions|2|Talk|Captain Esopo"] = { quest = "Pirate Instructions", stage = 2, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Captain Esopo", amount = 1, acquire = nil, source = "Captain Esopo", location = "Maple Village", marker = "Captain Esopo (Dialogue)", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Proof of Pirates|1|Kill|Black Noir Pirate"] = { quest = "Proof of Pirates", stage = 1, island = "Maple Village", objective = "Kill", goal = "Kill", target = "Black Noir Pirate", amount = 7, acquire = nil, source = "Black Noir Pirate", location = "Maple Village", marker = "Black Noir Pirate Marker", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Proof of Pirates|2|Deliver Object|Stolen Goods"] = { quest = "Proof of Pirates", stage = 2, island = "Maple Village", objective = "Deliver Object", goal = "DeliverObject", target = "Stolen Goods", amount = 2, acquire = nil, source = "Stolen Goods", location = "Maple Village", marker = "StolenGoods", handler = "Quest.goTagged", status = "IMPLEMENTED" }
	M.STAGES["Proof of Pirates|3|Talk|Captain Esopo"] = { quest = "Proof of Pirates", stage = 3, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Captain Esopo", amount = 1, acquire = nil, source = "Captain Esopo", location = "Maple Village", marker = "Captain Esopo (Dialogue)", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Raid Preparations|1|Talk|Remy"] = { quest = "Raid Preparations", stage = 1, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Remy", amount = 1, acquire = nil, source = "Remy", location = "Maple Village", marker = "Remy", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Raid Preparations|1|Talk|Farmer Joe"] = { quest = "Raid Preparations", stage = 1, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Farmer Joe", amount = 1, acquire = nil, source = "Farmer Joe", location = "Maple Village", marker = "Farmer Joe", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Raid Preparations|1|Talk|Pip"] = { quest = "Raid Preparations", stage = 1, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Pip", amount = 1, acquire = nil, source = "Pip", location = "Maple Village", marker = "Pip", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Raid Preparations|1|Talk|Lady Maia"] = { quest = "Raid Preparations", stage = 1, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Lady Maia", amount = 1, acquire = nil, source = "Lady Maia", location = "Maple Village", marker = "Lady Maia", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Raid Preparations|2|Collect|Lead Ore"] = { quest = "Raid Preparations", stage = 2, island = "Maple Village", objective = "Collect", goal = "AcquireItem", target = "Lead Ore", amount = 6, acquire = "Mining", source = "Lead Ore", location = "Maple Village", marker = nil, handler = "LifeSkills.mineToward", status = "IMPLEMENTED" }
	M.STAGES["Raid Preparations|3|Talk|Captain Esopo"] = { quest = "Raid Preparations", stage = 3, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Captain Esopo", amount = 1, acquire = nil, source = "Captain Esopo", location = "Maple Village", marker = "Captain Esopo (Dialogue)", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Something Isn't Right|1|Talk|Farmer Joe"] = { quest = "Something Isn't Right", stage = 1, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Farmer Joe", amount = 1, acquire = nil, source = "Farmer Joe", location = "Maple Village", marker = nil, handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Something Isn't Right|1|Talk|Tara"] = { quest = "Something Isn't Right", stage = 1, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Tara", amount = 1, acquire = nil, source = "Tara", location = "Maple Village", marker = nil, handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Something Isn't Right|1|Talk|Martha"] = { quest = "Something Isn't Right", stage = 1, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Martha", amount = 1, acquire = nil, source = "Martha", location = "Maple Village", marker = nil, handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Something Isn't Right|2|Investigate The Footsteps (1)|"] = { quest = "Something Isn't Right", stage = 2, island = "Maple Village", objective = "Investigate The Footsteps (1)", goal = "Interact", target = "", amount = 1, acquire = nil, source = "Campsite Footsteps Marker", location = "Maple Village", marker = "Campsite Footsteps Marker", handler = "Quest.goTagged", status = "IMPLEMENTED" }
	M.STAGES["Something Isn't Right|3|Destroy|Supply Crate"] = { quest = "Something Isn't Right", stage = 3, island = "Maple Village", objective = "Destroy", goal = "Kill", target = "Supply Crate", amount = 2, acquire = nil, source = "Supply Crate", location = "Maple Village", marker = "Black Noir Campsite 1", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Something Isn't Right|3|Kill|Black Noir Pirate"] = { quest = "Something Isn't Right", stage = 3, island = "Maple Village", objective = "Kill", goal = "Kill", target = "Black Noir Pirate", amount = 2, acquire = nil, source = "Black Noir Pirate", location = "Maple Village", marker = "Black Noir Campsite 1", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Something Isn't Right|4|Investigate The Footsteps (2)|"] = { quest = "Something Isn't Right", stage = 4, island = "Maple Village", objective = "Investigate The Footsteps (2)", goal = "Interact", target = "", amount = 1, acquire = nil, source = "Campsite Footsteps Marker", location = "Maple Village", marker = "Campsite Footsteps Marker", handler = "Quest.goTagged", status = "IMPLEMENTED" }
	M.STAGES["Something Isn't Right|5|Destroy|Supply Crate"] = { quest = "Something Isn't Right", stage = 5, island = "Maple Village", objective = "Destroy", goal = "Kill", target = "Supply Crate", amount = 2, acquire = nil, source = "Supply Crate", location = "Maple Village", marker = "Black Noir Campsite 2", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Something Isn't Right|5|Kill|Black Noir Pirate"] = { quest = "Something Isn't Right", stage = 5, island = "Maple Village", objective = "Kill", goal = "Kill", target = "Black Noir Pirate", amount = 2, acquire = nil, source = "Black Noir Pirate", location = "Maple Village", marker = "Black Noir Campsite 2", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Something Isn't Right|6|Talk|Captain Esopo"] = { quest = "Something Isn't Right", stage = 6, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Captain Esopo", amount = 1, acquire = nil, source = "Captain Esopo", location = "Maple Village", marker = "Captain Esopo (Dialogue)", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Stocked for a Siege|1|Donate|Dish"] = { quest = "Stocked for a Siege", stage = 1, island = "Maple Village", objective = "Donate", goal = "Deliver", target = "Dish", amount = 6, acquire = nil, source = "Dish", location = "Maple Village", marker = "Pantry Basket", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Stocked for a Siege|2|Talk|Captain Esopo"] = { quest = "Stocked for a Siege", stage = 2, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Captain Esopo", amount = 1, acquire = nil, source = "Captain Esopo", location = "Maple Village", marker = "Captain Esopo (Dialogue)", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["The Beast of Maple Village|1|Investigate The Wreckage|"] = { quest = "The Beast of Maple Village", stage = 1, island = "Maple Village", objective = "Investigate The Wreckage", goal = "Interact", target = "", amount = 1, acquire = nil, source = "Beast Wreckage Marker", location = "Maple Village", marker = "Beast Wreckage Marker", handler = "Quest.goTagged", status = "IMPLEMENTED" }
	M.STAGES["The Beast of Maple Village|2|Investigate The Beast's Den|"] = { quest = "The Beast of Maple Village", stage = 2, island = "Maple Village", objective = "Investigate The Beast's Den", goal = "Interact", target = "", amount = 1, acquire = nil, source = "Beast Den Marker", location = "Maple Village", marker = "Beast Den Marker", handler = "Quest.goTagged", status = "IMPLEMENTED" }
	M.STAGES["The Beast of Maple Village|3|Kill|The Beast?"] = { quest = "The Beast of Maple Village", stage = 3, island = "Maple Village", objective = "Kill", goal = "Kill", target = "The Beast?", amount = 1, acquire = nil, source = "The Beast?", location = "Maple Village", marker = "Beast Den Marker", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["The Beast of Maple Village|3|Talk|Barry"] = { quest = "The Beast of Maple Village", stage = 3, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Barry", amount = 1, acquire = nil, source = "Barry", location = "Maple Village", marker = "Barry", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["The Beast of Maple Village|4|Talk|Captain Esopo"] = { quest = "The Beast of Maple Village", stage = 4, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Captain Esopo", amount = 1, acquire = nil, source = "Captain Esopo", location = "Maple Village", marker = "Captain Esopo (Dialogue)", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["The Black Noir Raid|1|Defend|Black Noir Raid"] = { quest = "The Black Noir Raid", stage = 1, island = "Maple Village", objective = "Defend", goal = "Unresolved", target = "Black Noir Raid", amount = 1, acquire = nil, source = "Black Noir Raid", location = "Maple Village", marker = "Captain Esopo (Dialogue)", handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["The Black Noir Raid|2|Talk|Lady Maia"] = { quest = "The Black Noir Raid", stage = 2, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Lady Maia", amount = 1, acquire = nil, source = "Lady Maia", location = "Maple Village", marker = "Lady Maia", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["The Island's Protector|1|Kill|Captain Esopo"] = { quest = "The Island's Protector", stage = 1, island = "Maple Village", objective = "Kill", goal = "Kill", target = "Captain Esopo", amount = 1, acquire = nil, source = "Captain Esopo", location = "Maple Village", marker = "Captain Esopo (NPC)", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["The Island's Protector|2|Talk|Captain Esopo"] = { quest = "The Island's Protector", stage = 2, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Captain Esopo", amount = 1, acquire = nil, source = "Captain Esopo", location = "Maple Village", marker = "Captain Esopo (Dialogue)", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["The Wandering Hypnotist|1|Wake|Clucking Villager"] = { quest = "The Wandering Hypnotist", stage = 1, island = "Maple Village", objective = "Wake", goal = "Interact", target = "Clucking Villager", amount = 1, acquire = nil, source = "Clucking Villager", location = "Maple Village", marker = "Clucking Villager", handler = "Quest.goTagged", status = "IMPLEMENTED" }
	M.STAGES["The Wandering Hypnotist|1|Check On|Sleeping Villager"] = { quest = "The Wandering Hypnotist", stage = 1, island = "Maple Village", objective = "Check On", goal = "Interact", target = "Sleeping Villager", amount = 1, acquire = nil, source = "Sleeping Villager", location = "Maple Village", marker = "Sleeping Villager", handler = "Quest.goTagged", status = "IMPLEMENTED" }
	M.STAGES["The Wandering Hypnotist|1|CollectLocalItem|Bucket of Water"] = { quest = "The Wandering Hypnotist", stage = 1, island = "Maple Village", objective = "CollectLocalItem", goal = "AcquireItem", target = "Bucket of Water", amount = 1, acquire = "WorldPickup", source = "Clucking Villager", location = "Maple Village", marker = "Clucking Villager", handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["The Wandering Hypnotist|1|Wake|Sleeping Villager"] = { quest = "The Wandering Hypnotist", stage = 1, island = "Maple Village", objective = "Wake", goal = "Interact", target = "Sleeping Villager", amount = 1, acquire = nil, source = "Sleeping Villager", location = "Maple Village", marker = "Sleeping Villager", handler = "Quest.goTagged", status = "IMPLEMENTED" }
	M.STAGES["The Wandering Hypnotist|2|Kill|\"Hypnotist\" Mango"] = { quest = "The Wandering Hypnotist", stage = 2, island = "Maple Village", objective = "Kill", goal = "Kill", target = "\"Hypnotist\" Mango", amount = 1, acquire = nil, source = "\"Hypnotist\" Mango", location = "Maple Village", marker = "\\", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["The Wandering Hypnotist|3|Talk|Captain Esopo"] = { quest = "The Wandering Hypnotist", stage = 3, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Captain Esopo", amount = 1, acquire = nil, source = "Captain Esopo", location = "Maple Village", marker = "Captain Esopo (Dialogue)", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["A Dish Best Served Cold|1|Convince|Blonde Goblin"] = { quest = "A Dish Best Served Cold", stage = 1, island = "Anchor Town", objective = "Convince", goal = "Unresolved", target = "Blonde Goblin", amount = 1, acquire = nil, source = "Blonde Goblin", location = "Anchor Town", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["A Dish Best Served Cold|2|Talk|Penniless Pete"] = { quest = "A Dish Best Served Cold", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Penniless Pete", amount = 1, acquire = nil, source = "Penniless Pete", location = "Anchor Town", marker = "Penniless Pete", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Apple Pot Pie|1|Talk|Granny Todo"] = { quest = "Apple Pot Pie", stage = 1, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Granny Todo", amount = 1, acquire = nil, source = "Granny Todo", location = "Anchor Town", marker = "Granny Todo", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Apple Pot Pie|2|Collect|Apple"] = { quest = "Apple Pot Pie", stage = 2, island = "Anchor Town", objective = "Collect", goal = "AcquireItem", target = "Apple", amount = 5, acquire = "ShopPurchase", source = "Apple", location = "Anchor Town", marker = "Apple Seller", handler = "Shop.buy", status = "IMPLEMENTED" }
	M.STAGES["Apple Pot Pie|3|Collect|Apple Pot Pie"] = { quest = "Apple Pot Pie", stage = 3, island = "Anchor Town", objective = "Collect", goal = "AcquireItem", target = "Apple Pot Pie", amount = 1, acquire = "Farming", source = "Apple Pot Pie", location = "Anchor Town", marker = "Granny Todo", handler = "LifeSkills.farmToward", status = "IMPLEMENTED" }
	M.STAGES["Apple Pot Pie|4|Deliver Jay Vonera|Apple Pot Pie"] = { quest = "Apple Pot Pie", stage = 4, island = "Anchor Town", objective = "Deliver Jay Vonera", goal = "Other", target = "Apple Pot Pie", amount = 1, acquire = nil, source = "Apple Pot Pie", location = "Anchor Town", marker = "Jay Vonera", handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Collections|1|Kill|Corrupt Marine"] = { quest = "Collections", stage = 1, island = "Anchor Town", objective = "Kill", goal = "Kill", target = "Corrupt Marine", amount = 4, acquire = nil, source = "Corrupt Marine", location = "Anchor Town", marker = "Corrupt Marine", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Collections|2|Deliver Object|Trust Strongbox"] = { quest = "Collections", stage = 2, island = "Anchor Town", objective = "Deliver Object", goal = "DeliverObject", target = "Trust Strongbox", amount = 1, acquire = nil, source = "Trust Strongbox", location = "Anchor Town", marker = "TrustStrongbox", handler = "Quest.goTagged", status = "IMPLEMENTED" }
	M.STAGES["Collections|3|Talk|Nagi"] = { quest = "Collections", stage = 3, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Nagi", amount = 1, acquire = nil, source = "Nagi", location = "Anchor Town", marker = "Nagi", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Courier's Test|1|CollectLocalItem|Sealed Satchel"] = { quest = "Courier's Test", stage = 1, island = "Anchor Town", objective = "CollectLocalItem", goal = "AcquireItem", target = "Sealed Satchel", amount = 1, acquire = "WorldPickup", source = "Trust Dock Delivery", location = "Anchor Town", marker = "Trust Dock Delivery", handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Courier's Test|2|Talk|Nagi"] = { quest = "Courier's Test", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Nagi", amount = 1, acquire = nil, source = "Nagi", location = "Anchor Town", marker = "Nagi", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Down on His Luck|1|Donate|Gold"] = { quest = "Down on His Luck", stage = 1, island = "Anchor Town", objective = "Donate", goal = "Deliver", target = "Gold", amount = 100, acquire = nil, source = "Gold", location = "Anchor Town", marker = "Penniless Pete", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Down on His Luck|2|Talk|Penniless Pete"] = { quest = "Down on His Luck", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Penniless Pete", amount = 1, acquire = nil, source = "Penniless Pete", location = "Anchor Town", marker = "Penniless Pete", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Dwindling Iron Supply|1|Collect|Iron Ore"] = { quest = "Dwindling Iron Supply", stage = 1, island = "Anchor Town", objective = "Collect", goal = "AcquireItem", target = "Iron Ore", amount = 3, acquire = "Mining", source = "Iron Ore", location = "Anchor Town", marker = "Iron Ore", handler = "LifeSkills.mineToward", status = "IMPLEMENTED" }
	M.STAGES["Dwindling Iron Supply|2|Talk|Miner Song Kim Wu"] = { quest = "Dwindling Iron Supply", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Miner Song Kim Wu", amount = 1, acquire = nil, source = "Miner Song Kim Wu", location = "Anchor Town", marker = "Miner Song Kim Wu", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Feed The Hungry|1|Collect|Apple"] = { quest = "Feed The Hungry", stage = 1, island = "Anchor Town", objective = "Collect", goal = "AcquireItem", target = "Apple", amount = 1, acquire = "ShopPurchase", source = "Apple", location = "Anchor Town", marker = "AppleForSale", handler = "Shop.buy", status = "IMPLEMENTED" }
	M.STAGES["Feed The Hungry|2|Talk|Loki"] = { quest = "Feed The Hungry", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Loki", amount = 1, acquire = nil, source = "Loki", location = "Anchor Town", marker = "Loki", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Feed The Hungry|3|Collect|Carrot"] = { quest = "Feed The Hungry", stage = 3, island = "Anchor Town", objective = "Collect", goal = "AcquireItem", target = "Carrot", amount = 1, acquire = "ShopPurchase", source = "Carrot", location = "Anchor Town", marker = "CarrotForSale", handler = "Shop.buy", status = "IMPLEMENTED" }
	M.STAGES["Feed The Hungry|4|Talk|Loki"] = { quest = "Feed The Hungry", stage = 4, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Loki", amount = 1, acquire = nil, source = "Loki", location = "Anchor Town", marker = "Loki", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Feed The Hungry|5|Collect|Lemon"] = { quest = "Feed The Hungry", stage = 5, island = "Anchor Town", objective = "Collect", goal = "AcquireItem", target = "Lemon", amount = 1, acquire = "ShopPurchase", source = "Lemon", location = "Anchor Town", marker = "LemonForSale", handler = "Shop.buy", status = "IMPLEMENTED" }
	M.STAGES["Feed The Hungry|6|Talk|Loki"] = { quest = "Feed The Hungry", stage = 6, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Loki", amount = 1, acquire = nil, source = "Loki", location = "Anchor Town", marker = "Loki", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Feed The Hungry|7|Collect|Banana"] = { quest = "Feed The Hungry", stage = 7, island = "Anchor Town", objective = "Collect", goal = "AcquireItem", target = "Banana", amount = 1, acquire = "ShopPurchase", source = "Banana", location = "Anchor Town", marker = "BananaForSale", handler = "Shop.buy", status = "IMPLEMENTED" }
	M.STAGES["Feed The Hungry|8|Talk|Loki"] = { quest = "Feed The Hungry", stage = 8, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Loki", amount = 1, acquire = nil, source = "Loki", location = "Anchor Town", marker = "Loki", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Finders Keepers|1|Dig|up Wade's Belongings"] = { quest = "Finders Keepers", stage = 1, island = "Anchor Town", objective = "Dig", goal = "Unresolved", target = "up Wade's Belongings", amount = 5, acquire = nil, source = "up Wade's Belongings", location = "Anchor Town", marker = "Treasure Hunter", handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Finders Keepers|1|Collect|Wade's Belongings"] = { quest = "Finders Keepers", stage = 1, island = "Anchor Town", objective = "Collect", goal = "AcquireItem", target = "Wade's Belongings", amount = 1, acquire = "EnemyDrop", source = "Treasure Hunter", location = "Anchor Town", marker = "Treasure Hunter", handler = "Acquire.AcquireFromEnemyDrop", status = "IMPLEMENTED" }
	M.STAGES["Finders Keepers|2|Kill|Treasure Hunter"] = { quest = "Finders Keepers", stage = 2, island = "Anchor Town", objective = "Kill", goal = "Kill", target = "Treasure Hunter", amount = 4, acquire = nil, source = "Treasure Hunter", location = "Anchor Town", marker = "Treasure Hunter", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Finders Keepers|3|Talk|Wade"] = { quest = "Finders Keepers", stage = 3, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Wade", amount = 1, acquire = nil, source = "Wade", location = "Anchor Town", marker = "Wade", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Finding Denver|1|CollectLocalItem|Denver The Dog"] = { quest = "Finding Denver", stage = 1, island = "Anchor Town", objective = "CollectLocalItem", goal = "AcquireItem", target = "Denver The Dog", amount = 1, acquire = "WorldPickup", source = "Denver The Dog", location = "Anchor Town", marker = "Denver The Dog", handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Finding Denver|2|Talk|Jokic"] = { quest = "Finding Denver", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Jokic", amount = 1, acquire = nil, source = "Jokic", location = "Anchor Town", marker = "Jokic", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Fisherman Jack's Challenge|1|Fish|Carp"] = { quest = "Fisherman Jack's Challenge", stage = 1, island = "Anchor Town", objective = "Fish", goal = "AcquireItem", target = "Carp", amount = 1, acquire = "Fishing", source = "Carp", location = "Anchor Town", marker = "Anchor Town Pond Marker", handler = "LifeSkills.fishToward", status = "IMPLEMENTED" }
	M.STAGES["Fisherman Jack's Challenge|2|Talk|Fisherman Jack"] = { quest = "Fisherman Jack's Challenge", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Fisherman Jack", amount = 1, acquire = nil, source = "Fisherman Jack", location = "Anchor Town", marker = "Fisherman Jack", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Guest List|1|Talk|Granny Todo"] = { quest = "Guest List", stage = 1, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Granny Todo", amount = 1, acquire = nil, source = "Granny Todo", location = "Anchor Town", marker = "Granny Todo", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Guest List|1|Talk|Terry"] = { quest = "Guest List", stage = 1, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Terry", amount = 1, acquire = nil, source = "Terry", location = "Anchor Town", marker = "Terry", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Guest List|1|Talk|Aria"] = { quest = "Guest List", stage = 1, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Aria", amount = 1, acquire = nil, source = "Aria", location = "Anchor Town", marker = "Aria", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Guest List|2|Talk|Maeve"] = { quest = "Guest List", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Maeve", amount = 1, acquire = nil, source = "Maeve", location = "Anchor Town", marker = "Maeve", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Guest List|3|Kill|Party Crasher"] = { quest = "Guest List", stage = 3, island = "Anchor Town", objective = "Kill", goal = "Kill", target = "Party Crasher", amount = 2, acquire = nil, source = "Party Crasher", location = "Anchor Town", marker = "Party Crasher", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Guest List|4|Talk|Maeve"] = { quest = "Guest List", stage = 4, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Maeve", amount = 1, acquire = nil, source = "Maeve", location = "Anchor Town", marker = "Maeve", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Handle Recipe|1|Collect|Stick"] = { quest = "Handle Recipe", stage = 1, island = "Anchor Town", objective = "Collect", goal = "AcquireItem", target = "Stick", amount = 2, acquire = "WorldPickup", source = "Stick", location = "Anchor Town", marker = nil, handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Handle Recipe|1|Collect|Cloth"] = { quest = "Handle Recipe", stage = 1, island = "Anchor Town", objective = "Collect", goal = "AcquireItem", target = "Cloth", amount = 1, acquire = "WorldPickup", source = "Cloth", location = "Anchor Town", marker = nil, handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Handle Recipe|2|Talk|Craftsman Henry"] = { quest = "Handle Recipe", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Craftsman Henry", amount = 1, acquire = nil, source = "Craftsman Henry", location = "Anchor Town", marker = nil, handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Keeper of the Flame|1|CollectLocalItem|Lamp Oil"] = { quest = "Keeper of the Flame", stage = 1, island = "Anchor Town", objective = "CollectLocalItem", goal = "AcquireItem", target = "Lamp Oil", amount = 1, acquire = "WorldPickup", source = "Lamp Oil Spawn", location = "Anchor Town", marker = "Lamp Oil Spawn", handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Keeper of the Flame|2|Talk|Keeper Otis"] = { quest = "Keeper of the Flame", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Keeper Otis", amount = 1, acquire = nil, source = "Keeper Otis", location = "Anchor Town", marker = "Keeper Otis (Dialogue)", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Message for the Strongbox|1|Talk|Captain Arashi"] = { quest = "Message for the Strongbox", stage = 1, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Captain Arashi", amount = 1, acquire = nil, source = "Captain Arashi", location = "Anchor Town", marker = "Captain Arashi", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Message for the Strongbox|2|Talk|Tomoe"] = { quest = "Message for the Strongbox", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Tomoe", amount = 1, acquire = nil, source = "Tomoe", location = "Anchor Town", marker = "Tomoe", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Message for the Strongbox|3|Talk|Captain Jones"] = { quest = "Message for the Strongbox", stage = 3, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Captain Jones", amount = 1, acquire = nil, source = "Captain Jones", location = "Anchor Town", marker = "Captain Jones", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Mina's Request|1|Enter Zone|Anchor Town Fishing Shop"] = { quest = "Mina's Request", stage = 1, island = "Anchor Town", objective = "Enter Zone", goal = "Other", target = "Anchor Town Fishing Shop", amount = 1, acquire = nil, source = "Anchor Town Fishing Shop", location = "Anchor Town", marker = "Anchor Town Fishing Shop", handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Mina's Request|1|Enter Zone|Anchor Town Food Foo"] = { quest = "Mina's Request", stage = 1, island = "Anchor Town", objective = "Enter Zone", goal = "Other", target = "Anchor Town Food Foo", amount = 1, acquire = nil, source = "Anchor Town Food Foo", location = "Anchor Town", marker = "Anchor Town Food Foo", handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Mina's Request|1|Enter Zone|Anchor Town Plaza"] = { quest = "Mina's Request", stage = 1, island = "Anchor Town", objective = "Enter Zone", goal = "Other", target = "Anchor Town Plaza", amount = 1, acquire = nil, source = "Anchor Town Plaza", location = "Anchor Town", marker = "Anchor Town Plaza", handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Mina's Request|2|Escort|Mina"] = { quest = "Mina's Request", stage = 2, island = "Anchor Town", objective = "Escort", goal = "Escort", target = "Mina", amount = 1, acquire = nil, source = "Mina", location = "Anchor Town", marker = nil, handler = "Quest.escort", status = "RUNTIME_REQUIRED" }
	M.STAGES["Miners Bracelet|1|CollectLocalItem|Silver Miners Bracelet"] = { quest = "Miners Bracelet", stage = 1, island = "Anchor Town", objective = "CollectLocalItem", goal = "AcquireItem", target = "Silver Miners Bracelet", amount = 1, acquire = "WorldPickup", source = "Silver Miners Bracelet", location = "Anchor Town", marker = "Silver Miners Bracelet", handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Miners Bracelet|2|Talk|Miner Song Jil Wu"] = { quest = "Miners Bracelet", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Miner Song Jil Wu", amount = 1, acquire = nil, source = "Miner Song Jil Wu", location = "Anchor Town", marker = "Miner Song Jil Wu", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Miners Stone Ring|1|Craft|Stone Ring"] = { quest = "Miners Stone Ring", stage = 1, island = "Anchor Town", objective = "Craft", goal = "AcquireItem", target = "Stone Ring", amount = 1, acquire = "Crafting", source = "Stone Ring", location = "Anchor Town", marker = "CraftingTable", handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Overdue Payment|1|Collect|Pirate's Ruby"] = { quest = "Overdue Payment", stage = 1, island = "Anchor Town", objective = "Collect", goal = "AcquireItem", target = "Pirate's Ruby", amount = 1, acquire = "WorldPickup", source = "Jokic", location = "Anchor Town", marker = "Jokic", handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Overdue Payment|2|Talk|Smuggler"] = { quest = "Overdue Payment", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Smuggler", amount = 1, acquire = nil, source = "Smuggler", location = "Anchor Town", marker = "Smuggler", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Paper Route|1|Talk|Nessa"] = { quest = "Paper Route", stage = 1, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Nessa", amount = 1, acquire = nil, source = "Nessa", location = "Anchor Town", marker = "Nessa", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Paper Route|2|Talk|Billy B."] = { quest = "Paper Route", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Billy B.", amount = 1, acquire = nil, source = "Billy B.", location = "Anchor Town", marker = "Billy B.", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Paper Route|3|Talk|Farmer Joe"] = { quest = "Paper Route", stage = 3, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Farmer Joe", amount = 1, acquire = nil, source = "Farmer Joe", location = "Anchor Town", marker = "Farmer Joe", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Paper Route|4|Talk|Nagi"] = { quest = "Paper Route", stage = 4, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Nagi", amount = 1, acquire = nil, source = "Nagi", location = "Anchor Town", marker = "Nagi", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Sushi's Training 1|1|Hit|Training Dummy"] = { quest = "Sushi's Training 1", stage = 1, island = "Anchor Town", objective = "Hit", goal = "Kill", target = "Training Dummy", amount = 100, acquire = nil, source = "Training Dummy", location = "Anchor Town", marker = "TrainingDummy", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Sushi's Training 1|2|Talk|Sushi"] = { quest = "Sushi's Training 1", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Sushi", amount = 1, acquire = nil, source = "Sushi", location = "Anchor Town", marker = "Sushi", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Sushi's Training 2|1|Hit|Training Dummy"] = { quest = "Sushi's Training 2", stage = 1, island = "Anchor Town", objective = "Hit", goal = "Kill", target = "Training Dummy", amount = 1000, acquire = nil, source = "Training Dummy", location = "Anchor Town", marker = "TrainingDummy", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Sushi's Training 2|2|Talk|Sushi"] = { quest = "Sushi's Training 2", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Sushi", amount = 1, acquire = nil, source = "Sushi", location = "Anchor Town", marker = "Sushi", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Sushi's Training 3|1|Hit|Training Dummy"] = { quest = "Sushi's Training 3", stage = 1, island = "Anchor Town", objective = "Hit", goal = "Kill", target = "Training Dummy", amount = 10000, acquire = nil, source = "Training Dummy", location = "Anchor Town", marker = "TrainingDummy", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Sushi's Training 3|2|Talk|Sushi"] = { quest = "Sushi's Training 3", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Sushi", amount = 1, acquire = nil, source = "Sushi", location = "Anchor Town", marker = "Sushi", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Sushi's Training 4|1|Hit|Training Dummy"] = { quest = "Sushi's Training 4", stage = 1, island = "Anchor Town", objective = "Hit", goal = "Kill", target = "Training Dummy", amount = 100000, acquire = nil, source = "Training Dummy", location = "Anchor Town", marker = "TrainingDummy", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Sushi's Training 4|2|Talk|Sushi"] = { quest = "Sushi's Training 4", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Sushi", amount = 1, acquire = nil, source = "Sushi", location = "Anchor Town", marker = "Sushi", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Sushi's Training 5|1|Hit|Training Dummy"] = { quest = "Sushi's Training 5", stage = 1, island = "Anchor Town", objective = "Hit", goal = "Kill", target = "Training Dummy", amount = 1000000, acquire = nil, source = "Training Dummy", location = "Anchor Town", marker = "TrainingDummy", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Sushi's Training 5|2|Talk|Sushi"] = { quest = "Sushi's Training 5", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Sushi", amount = 1, acquire = nil, source = "Sushi", location = "Anchor Town", marker = "Sushi", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Sushi's Training 6|1|Hit|Training Dummy"] = { quest = "Sushi's Training 6", stage = 1, island = "Anchor Town", objective = "Hit", goal = "Kill", target = "Training Dummy", amount = 10000000, acquire = nil, source = "Training Dummy", location = "Anchor Town", marker = "TrainingDummy", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Sushi's Training 6|2|Talk|Sushi"] = { quest = "Sushi's Training 6", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Sushi", amount = 1, acquire = nil, source = "Sushi", location = "Anchor Town", marker = "Sushi", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Sushi's Training 7|1|Hit|Training Dummy"] = { quest = "Sushi's Training 7", stage = 1, island = "Anchor Town", objective = "Hit", goal = "Kill", target = "Training Dummy", amount = 100000000, acquire = nil, source = "Training Dummy", location = "Anchor Town", marker = "TrainingDummy", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Sushi's Training 7|2|Talk|Sushi"] = { quest = "Sushi's Training 7", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Sushi", amount = 1, acquire = nil, source = "Sushi", location = "Anchor Town", marker = "Sushi", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Sushi's Training 8|1|Hit|Training Dummy"] = { quest = "Sushi's Training 8", stage = 1, island = "Anchor Town", objective = "Hit", goal = "Kill", target = "Training Dummy", amount = 1000000000, acquire = nil, source = "Training Dummy", location = "Anchor Town", marker = "TrainingDummy", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Sushi's Training 8|2|Talk|Sushi"] = { quest = "Sushi's Training 8", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Sushi", amount = 1, acquire = nil, source = "Sushi", location = "Anchor Town", marker = "Sushi", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Sushi's Training 9|1|Hit|Training Dummy"] = { quest = "Sushi's Training 9", stage = 1, island = "Anchor Town", objective = "Hit", goal = "Kill", target = "Training Dummy", amount = 10000000000, acquire = nil, source = "Training Dummy", location = "Anchor Town", marker = "TrainingDummy", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Sushi's Training 9|2|Talk|Sushi"] = { quest = "Sushi's Training 9", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Sushi", amount = 1, acquire = nil, source = "Sushi", location = "Anchor Town", marker = "Sushi", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Terry vs. The Tide|1|Return|Terry's Boat"] = { quest = "Terry vs. The Tide", stage = 1, island = "Anchor Town", objective = "Return", goal = "Other", target = "Terry's Boat", amount = 1, acquire = nil, source = "Terry's Boat", location = "Anchor Town", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Terry vs. The Tide|2|Talk|Terry"] = { quest = "Terry vs. The Tide", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Terry", amount = 1, acquire = nil, source = "Terry", location = "Anchor Town", marker = nil, handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Terry's White Whale|1|Fish|Mythic+ Fish"] = { quest = "Terry's White Whale", stage = 1, island = "Anchor Town", objective = "Fish", goal = "AcquireItem", target = "Mythic+ Fish", amount = 1, acquire = "Fishing", source = "Mythic+ Fish", location = "Anchor Town", marker = nil, handler = "LifeSkills.fishToward", status = "IMPLEMENTED" }
	M.STAGES["Terry's White Whale|2|Talk|Terry"] = { quest = "Terry's White Whale", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Terry", amount = 1, acquire = nil, source = "Terry", location = "Anchor Town", marker = "Terry", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["The 'Priceless' Haul|1|Collect|Soggy Boot"] = { quest = "The 'Priceless' Haul", stage = 1, island = "Anchor Town", objective = "Collect", goal = "AcquireItem", target = "Soggy Boot", amount = 3, acquire = "EnemyDrop", source = "Treasure Hunter", location = "Anchor Town", marker = "Treasure Hunter", handler = "Acquire.AcquireFromEnemyDrop", status = "IMPLEMENTED" }
	M.STAGES["The 'Priceless' Haul|2|Talk|Merchant"] = { quest = "The 'Priceless' Haul", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Merchant", amount = 1, acquire = nil, source = "Merchant", location = "Anchor Town", marker = "Merchant", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["The 'Priceless' Haul|3|Talk|Wade"] = { quest = "The 'Priceless' Haul", stage = 3, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Wade", amount = 1, acquire = nil, source = "Wade", location = "Anchor Town", marker = "Wade", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Wizards Apprentice|1|CollectLocalItem|Red Shell"] = { quest = "Wizards Apprentice", stage = 1, island = "Anchor Town", objective = "CollectLocalItem", goal = "AcquireItem", target = "Red Shell", amount = 1, acquire = "WorldPickup", source = "Red Shell Spawn", location = "Anchor Town", marker = "Red Shell Spawn", handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Wizards Apprentice|1|CollectLocalItem|Yellow Shell"] = { quest = "Wizards Apprentice", stage = 1, island = "Anchor Town", objective = "CollectLocalItem", goal = "AcquireItem", target = "Yellow Shell", amount = 1, acquire = "WorldPickup", source = "Red Shell Spawn", location = "Anchor Town", marker = "Red Shell Spawn", handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Wizards Apprentice|1|CollectLocalItem|White Shell"] = { quest = "Wizards Apprentice", stage = 1, island = "Anchor Town", objective = "CollectLocalItem", goal = "AcquireItem", target = "White Shell", amount = 1, acquire = "WorldPickup", source = "Red Shell Spawn", location = "Anchor Town", marker = "Red Shell Spawn", handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Wizards Apprentice|1|CollectLocalItem|Black Shell"] = { quest = "Wizards Apprentice", stage = 1, island = "Anchor Town", objective = "CollectLocalItem", goal = "AcquireItem", target = "Black Shell", amount = 1, acquire = "WorldPickup", source = "Red Shell Spawn", location = "Anchor Town", marker = "Red Shell Spawn", handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Wizards Apprentice|2|Talk|Almighty Calvin"] = { quest = "Wizards Apprentice", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Almighty Calvin", amount = 1, acquire = nil, source = "Almighty Calvin", location = "Anchor Town", marker = "Almighty Calvin", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Wormless Terry|1|Collect|Worm"] = { quest = "Wormless Terry", stage = 1, island = "Anchor Town", objective = "Collect", goal = "AcquireItem", target = "Worm", amount = 20, acquire = "ShopPurchase", source = "Worm", location = "Anchor Town", marker = "WormForSale", handler = "Shop.buy", status = "IMPLEMENTED" }
	M.STAGES["Wormless Terry|2|Talk|Terry"] = { quest = "Wormless Terry", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Terry", amount = 1, acquire = nil, source = "Terry", location = "Anchor Town", marker = "Terry", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Arm Wrestling 1|1|Win Arm Wrestle|Beginner Arm Wrestler"] = { quest = "Arm Wrestling 1", stage = 1, island = "Clown Town", objective = "Win Arm Wrestle", goal = "Other", target = "Beginner Arm Wrestler", amount = 1, acquire = nil, source = "Beginner Arm Wrestler", location = "Clown Town", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Arm Wrestling 1|2|Talk|Beginner Arm Wrestler"] = { quest = "Arm Wrestling 1", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Beginner Arm Wrestler", amount = 1, acquire = nil, source = "Beginner Arm Wrestler", location = "Clown Town", marker = nil, handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Arm Wrestling 2|1|Win Arm Wrestle|Intermediate Arm Wrestler"] = { quest = "Arm Wrestling 2", stage = 1, island = "Clown Town", objective = "Win Arm Wrestle", goal = "Other", target = "Intermediate Arm Wrestler", amount = 1, acquire = nil, source = "Intermediate Arm Wrestler", location = "Clown Town", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Arm Wrestling 2|2|Talk|Intermediate Arm Wrestler"] = { quest = "Arm Wrestling 2", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Intermediate Arm Wrestler", amount = 1, acquire = nil, source = "Intermediate Arm Wrestler", location = "Clown Town", marker = nil, handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Arm Wrestling 3|1|Win Arm Wrestle|Arm Wrestling Champion"] = { quest = "Arm Wrestling 3", stage = 1, island = "Clown Town", objective = "Win Arm Wrestle", goal = "Other", target = "Arm Wrestling Champion", amount = 1, acquire = nil, source = "Arm Wrestling Champion", location = "Clown Town", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Arm Wrestling 3|2|Talk|Arm Wrestling Champion"] = { quest = "Arm Wrestling 3", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Arm Wrestling Champion", amount = 1, acquire = nil, source = "Arm Wrestling Champion", location = "Clown Town", marker = nil, handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Clown Imposter|1|Escort|Fake Clown"] = { quest = "Clown Imposter", stage = 1, island = "Clown Town", objective = "Escort", goal = "Escort", target = "Fake Clown", amount = 1, acquire = nil, source = "Fake Clown", location = "Clown Town", marker = nil, handler = "Quest.escort", status = "RUNTIME_REQUIRED" }
	M.STAGES["Clown Propaganda|1|CollectLocalItem|Clown Propaganda Poster"] = { quest = "Clown Propaganda", stage = 1, island = "Clown Town", objective = "CollectLocalItem", goal = "AcquireItem", target = "Clown Propaganda Poster", amount = 10, acquire = "WorldPickup", source = "Clown Propaganda Poster", location = "Clown Town", marker = "Clown Propaganda Poster", handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Clown Propaganda|2|Talk|Benny"] = { quest = "Clown Propaganda", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Benny", amount = 1, acquire = nil, source = "Benny", location = "Clown Town", marker = "Benny", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Emergency Deliveries|1|Talk|Billy's Customer 1"] = { quest = "Emergency Deliveries", stage = 1, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Billy's Customer 1", amount = 1, acquire = nil, source = "Billy's Customer 1", location = "Clown Town", marker = "Billy's Customer 1", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Emergency Deliveries|1|Talk|Billy's Customer 2"] = { quest = "Emergency Deliveries", stage = 1, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Billy's Customer 2", amount = 1, acquire = nil, source = "Billy's Customer 2", location = "Clown Town", marker = "Billy's Customer 2", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Emergency Deliveries|1|Talk|Billy's Customer 3"] = { quest = "Emergency Deliveries", stage = 1, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Billy's Customer 3", amount = 1, acquire = nil, source = "Billy's Customer 3", location = "Clown Town", marker = "Billy's Customer 3", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Emergency Deliveries|2|Talk|Billy B."] = { quest = "Emergency Deliveries", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Billy B.", amount = 1, acquire = nil, source = "Billy B.", location = "Clown Town", marker = "Billy B.", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Explosive Research 1|1|Deliver Object|Explosive Wooden Crate"] = { quest = "Explosive Research 1", stage = 1, island = "Clown Town", objective = "Deliver Object", goal = "DeliverObject", target = "Explosive Wooden Crate", amount = 5, acquire = nil, source = "Explosive Wooden Crate", location = "Clown Town", marker = nil, handler = "Quest.goTagged", status = "IMPLEMENTED" }
	M.STAGES["Explosive Research 1|2|Talk|Mei"] = { quest = "Explosive Research 1", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Mei", amount = 1, acquire = nil, source = "Mei", location = "Clown Town", marker = "Mei", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Explosive Research 2|1|Collect|Clown Cannon Ball"] = { quest = "Explosive Research 2", stage = 1, island = "Clown Town", objective = "Collect", goal = "AcquireItem", target = "Clown Cannon Ball", amount = 1, acquire = "WorldPickup", source = "Clown Cannon Ball", location = "Clown Town", marker = nil, handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Explosive Research 2|2|Talk|Mei"] = { quest = "Explosive Research 2", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Mei", amount = 1, acquire = nil, source = "Mei", location = "Clown Town", marker = "Mei", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Explosive Research 3|1|Collect|Gunpowder"] = { quest = "Explosive Research 3", stage = 1, island = "Clown Town", objective = "Collect", goal = "AcquireItem", target = "Gunpowder", amount = 1, acquire = "WorldPickup", source = "Gunpowder", location = "Clown Town", marker = nil, handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Explosive Research 3|2|Talk|Mei"] = { quest = "Explosive Research 3", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Mei", amount = 1, acquire = nil, source = "Mei", location = "Clown Town", marker = "Mei", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Ferris Wheel Standoff|1|Talk|Lash"] = { quest = "Ferris Wheel Standoff", stage = 1, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Lash", amount = 1, acquire = nil, source = "Lash", location = "Clown Town", marker = "Lash", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Ferris Wheel Standoff|2|Talk|Marnie"] = { quest = "Ferris Wheel Standoff", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Marnie", amount = 1, acquire = nil, source = "Marnie", location = "Clown Town", marker = "Marnie", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Militia Powerup 1|1|CollectLocalItem|Dumbbell"] = { quest = "Militia Powerup 1", stage = 1, island = "Clown Town", objective = "CollectLocalItem", goal = "AcquireItem", target = "Dumbbell", amount = 1, acquire = "WorldPickup", source = "Dumbbell", location = "Clown Town", marker = "Dumbbell", handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Militia Powerup 1|2|Talk|Clown Town Angry Civilian 1"] = { quest = "Militia Powerup 1", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Clown Town Angry Civilian 1", amount = 1, acquire = nil, source = "Clown Town Angry Civilian 1", location = "Clown Town", marker = "Clown Town Angry Civilian 1", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Militia Powerup 2|1|Unknown|"] = { quest = "Militia Powerup 2", stage = 1, island = "Clown Town", objective = "Unknown", goal = "Other", target = "", amount = 1, acquire = nil, source = nil, location = "Clown Town", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Militia Powerup 2|2|Unknown|"] = { quest = "Militia Powerup 2", stage = 2, island = "Clown Town", objective = "Unknown", goal = "Other", target = "", amount = 1, acquire = nil, source = nil, location = "Clown Town", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Militia Powerup 3|1|Unknown|"] = { quest = "Militia Powerup 3", stage = 1, island = "Clown Town", objective = "Unknown", goal = "Other", target = "", amount = 1, acquire = nil, source = nil, location = "Clown Town", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Militia Powerup 3|2|Unknown|"] = { quest = "Militia Powerup 3", stage = 2, island = "Clown Town", objective = "Unknown", goal = "Other", target = "", amount = 1, acquire = nil, source = nil, location = "Clown Town", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Tightrope Trouble|1|Talk|Augustine"] = { quest = "Tightrope Trouble", stage = 1, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Augustine", amount = 1, acquire = nil, source = "Augustine", location = "Clown Town", marker = nil, handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Tightrope Trouble|2|Rescue|Augustine"] = { quest = "Tightrope Trouble", stage = 2, island = "Clown Town", objective = "Rescue", goal = "Other", target = "Augustine", amount = 1, acquire = nil, source = "Augustine", location = "Clown Town", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Tightrope Trouble|3|Talk|Augustine [2]"] = { quest = "Tightrope Trouble", stage = 3, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Augustine [2]", amount = 1, acquire = nil, source = "Augustine [2]", location = "Clown Town", marker = "Augustine [2]", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Undermine The Circus 1|1|Kill|Clown"] = { quest = "Undermine The Circus 1", stage = 1, island = "Clown Town", objective = "Kill", goal = "Kill", target = "Clown", amount = 6, acquire = nil, source = "Clown", location = "Clown Town", marker = "Muggy Cannon", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Undermine The Circus 1|1|Destroy|Air Balloon"] = { quest = "Undermine The Circus 1", stage = 1, island = "Clown Town", objective = "Destroy", goal = "Kill", target = "Air Balloon", amount = 2, acquire = nil, source = "Air Balloon", location = "Clown Town", marker = "Muggy Cannon", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Undermine The Circus 1|1|Free|Captive"] = { quest = "Undermine The Circus 1", stage = 1, island = "Clown Town", objective = "Free", goal = "Interact", target = "Captive", amount = 2, acquire = nil, source = "Muggy Cannon", location = "Clown Town", marker = "Muggy Cannon", handler = "Quest.goTagged", status = "IMPLEMENTED" }
	M.STAGES["Undermine The Circus 1|1|Destroy|Explosive Wooden Crate"] = { quest = "Undermine The Circus 1", stage = 1, island = "Clown Town", objective = "Destroy", goal = "Kill", target = "Explosive Wooden Crate", amount = 6, acquire = nil, source = "Explosive Wooden Crate", location = "Clown Town", marker = "Muggy Cannon", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Undermine The Circus 1|1|Destroy|Muggy Cannon"] = { quest = "Undermine The Circus 1", stage = 1, island = "Clown Town", objective = "Destroy", goal = "Kill", target = "Muggy Cannon", amount = 1, acquire = nil, source = "Muggy Cannon", location = "Clown Town", marker = "Muggy Cannon", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Undermine The Circus 1|2|Talk|Gambit"] = { quest = "Undermine The Circus 1", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Gambit", amount = 1, acquire = nil, source = "Gambit", location = "Clown Town", marker = "Gambit", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Undermine The Circus 2|1|Kill|Bazaji"] = { quest = "Undermine The Circus 2", stage = 1, island = "Clown Town", objective = "Kill", goal = "Kill", target = "Bazaji", amount = 1, acquire = nil, source = "Bazaji", location = "Clown Town", marker = nil, handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Undermine The Circus 2|1|Kill|Circus Lion"] = { quest = "Undermine The Circus 2", stage = 1, island = "Clown Town", objective = "Kill", goal = "Kill", target = "Circus Lion", amount = 1, acquire = nil, source = "Circus Lion", location = "Clown Town", marker = nil, handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Undermine The Circus 2|1|Kill|Beast Tamer"] = { quest = "Undermine The Circus 2", stage = 1, island = "Clown Town", objective = "Kill", goal = "Kill", target = "Beast Tamer", amount = 1, acquire = nil, source = "Beast Tamer", location = "Clown Town", marker = nil, handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Undermine The Circus 2|2|Talk|Gambit"] = { quest = "Undermine The Circus 2", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Gambit", amount = 1, acquire = nil, source = "Gambit", location = "Clown Town", marker = "Gambit", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Undermine The Circus 3|1|Kill|Choppy The Clown"] = { quest = "Undermine The Circus 3", stage = 1, island = "Clown Town", objective = "Kill", goal = "Kill", target = "Choppy The Clown", amount = 1, acquire = nil, source = "Choppy The Clown", location = "Clown Town", marker = "Choppy The Clown Marker", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Undermine The Circus 3|2|Talk|Gambit"] = { quest = "Undermine The Circus 3", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Gambit", amount = 1, acquire = nil, source = "Gambit", location = "Clown Town", marker = "Gambit", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["A Balanced Field|1|Harvest|Tomato"] = { quest = "A Balanced Field", stage = 1, island = "Maple Village", objective = "Harvest", goal = "AcquireItem", target = "Tomato", amount = 1, acquire = "Farming", source = "Tomato", location = "Maple Village", marker = nil, handler = "LifeSkills.farmToward", status = "IMPLEMENTED" }
	M.STAGES["A Balanced Field|1|Harvest|Carrot"] = { quest = "A Balanced Field", stage = 1, island = "Maple Village", objective = "Harvest", goal = "AcquireItem", target = "Carrot", amount = 1, acquire = "Farming", source = "Carrot", location = "Maple Village", marker = nil, handler = "LifeSkills.farmToward", status = "IMPLEMENTED" }
	M.STAGES["A Balanced Field|1|Harvest|Cabbage"] = { quest = "A Balanced Field", stage = 1, island = "Maple Village", objective = "Harvest", goal = "AcquireItem", target = "Cabbage", amount = 1, acquire = "Farming", source = "Cabbage", location = "Maple Village", marker = nil, handler = "LifeSkills.farmToward", status = "IMPLEMENTED" }
	M.STAGES["A Balanced Field|1|Harvest|Wheat"] = { quest = "A Balanced Field", stage = 1, island = "Maple Village", objective = "Harvest", goal = "AcquireItem", target = "Wheat", amount = 1, acquire = "Farming", source = "Wheat", location = "Maple Village", marker = nil, handler = "LifeSkills.farmToward", status = "IMPLEMENTED" }
	M.STAGES["A Balanced Field|1|Water|Crop"] = { quest = "A Balanced Field", stage = 1, island = "Maple Village", objective = "Water", goal = "AcquireItem", target = "Crop", amount = 4, acquire = "Farming", source = "Crop", location = "Maple Village", marker = nil, handler = "LifeSkills.farmToward", status = "IMPLEMENTED" }
	M.STAGES["A Balanced Field|2|Collect|Egg"] = { quest = "A Balanced Field", stage = 2, island = "Maple Village", objective = "Collect", goal = "AcquireItem", target = "Egg", amount = 2, acquire = "WorldPickup", source = "Egg", location = "Maple Village", marker = nil, handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["A Balanced Field|3|Talk|Farmer Joe"] = { quest = "A Balanced Field", stage = 3, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Farmer Joe", amount = 1, acquire = nil, source = "Farmer Joe", location = "Maple Village", marker = "Farmer Joe", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Big Shot 1|1|Collect|Lead"] = { quest = "Big Shot 1", stage = 1, island = "Maple Village", objective = "Collect", goal = "AcquireItem", target = "Lead", amount = 2, acquire = "Crafting", source = "Furnace", location = "Maple Village", marker = nil, handler = "LifeSkills.mineToward", status = "IMPLEMENTED" }
	M.STAGES["Big Shot 1|2|Talk|Pip"] = { quest = "Big Shot 1", stage = 2, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Pip", amount = 1, acquire = nil, source = "Pip", location = "Maple Village", marker = "Pip", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Big Shot 2|1|Collect|Lead Ball"] = { quest = "Big Shot 2", stage = 1, island = "Maple Village", objective = "Collect", goal = "AcquireItem", target = "Lead Ball", amount = 1, acquire = "WorldPickup", source = "Lead Ball", location = "Maple Village", marker = nil, handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Big Shot 2|1|Collect|Pepper"] = { quest = "Big Shot 2", stage = 1, island = "Maple Village", objective = "Collect", goal = "AcquireItem", target = "Pepper", amount = 10, acquire = "WorldPickup", source = "Pepper", location = "Maple Village", marker = nil, handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Big Shot 2|2|Talk|Pip"] = { quest = "Big Shot 2", stage = 2, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Pip", amount = 1, acquire = nil, source = "Pip", location = "Maple Village", marker = "Pip", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Big Shot 3|1|Collect|Lead Ball"] = { quest = "Big Shot 3", stage = 1, island = "Maple Village", objective = "Collect", goal = "AcquireItem", target = "Lead Ball", amount = 1, acquire = "WorldPickup", source = "Lead Ball", location = "Maple Village", marker = nil, handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Big Shot 3|1|Collect|Oil"] = { quest = "Big Shot 3", stage = 1, island = "Maple Village", objective = "Collect", goal = "AcquireItem", target = "Oil", amount = 3, acquire = "WorldPickup", source = "Oil", location = "Maple Village", marker = nil, handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Big Shot 3|2|Talk|Pip"] = { quest = "Big Shot 3", stage = 2, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Pip", amount = 1, acquire = nil, source = "Pip", location = "Maple Village", marker = "Pip", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Big Shot 4|1|Collect|Lead Ball"] = { quest = "Big Shot 4", stage = 1, island = "Maple Village", objective = "Collect", goal = "AcquireItem", target = "Lead Ball", amount = 1, acquire = "WorldPickup", source = "Lead Ball", location = "Maple Village", marker = nil, handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Big Shot 4|1|Collect|Gunpowder"] = { quest = "Big Shot 4", stage = 1, island = "Maple Village", objective = "Collect", goal = "AcquireItem", target = "Gunpowder", amount = 2, acquire = "WorldPickup", source = "Gunpowder", location = "Maple Village", marker = nil, handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Big Shot 4|2|Talk|Pip"] = { quest = "Big Shot 4", stage = 2, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Pip", amount = 1, acquire = nil, source = "Pip", location = "Maple Village", marker = "Pip", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Fresh From the Farm|1|Collect|Egg"] = { quest = "Fresh From the Farm", stage = 1, island = "Maple Village", objective = "Collect", goal = "AcquireItem", target = "Egg", amount = 2, acquire = "WorldPickup", source = "Egg", location = "Maple Village", marker = nil, handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Fresh From the Farm|1|Collect|Raw Chicken"] = { quest = "Fresh From the Farm", stage = 1, island = "Maple Village", objective = "Collect", goal = "AcquireItem", target = "Raw Chicken", amount = 1, acquire = "WorldPickup", source = "Raw Chicken", location = "Maple Village", marker = nil, handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Fresh From the Farm|2|Cook|Omelette"] = { quest = "Fresh From the Farm", stage = 2, island = "Maple Village", objective = "Cook", goal = "AcquireItem", target = "Omelette", amount = 1, acquire = "Cooking", source = "Omelette", location = "Maple Village", marker = nil, handler = "LifeSkills.cookToward", status = "IMPLEMENTED" }
	M.STAGES["Fresh From the Farm|2|Cook|Roast Chicken"] = { quest = "Fresh From the Farm", stage = 2, island = "Maple Village", objective = "Cook", goal = "AcquireItem", target = "Roast Chicken", amount = 1, acquire = "Cooking", source = "Roast Chicken", location = "Maple Village", marker = nil, handler = "LifeSkills.cookToward", status = "IMPLEMENTED" }
	M.STAGES["Fresh From the Farm|3|Talk|Remy"] = { quest = "Fresh From the Farm", stage = 3, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Remy", amount = 1, acquire = nil, source = "Remy", location = "Maple Village", marker = "Remy", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Green Thumb|1|Plant|Seed"] = { quest = "Green Thumb", stage = 1, island = "Maple Village", objective = "Plant", goal = "AcquireItem", target = "Seed", amount = 4, acquire = "Farming", source = "Seed", location = "Maple Village", marker = nil, handler = "LifeSkills.farmToward", status = "IMPLEMENTED" }
	M.STAGES["Green Thumb|2|Harvest|Crop"] = { quest = "Green Thumb", stage = 2, island = "Maple Village", objective = "Harvest", goal = "AcquireItem", target = "Crop", amount = 4, acquire = "Farming", source = "Crop", location = "Maple Village", marker = nil, handler = "LifeSkills.farmToward", status = "IMPLEMENTED" }
	M.STAGES["Green Thumb|3|Talk|Farmer Joe"] = { quest = "Green Thumb", stage = 3, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Farmer Joe", amount = 1, acquire = nil, source = "Farmer Joe", location = "Maple Village", marker = "Farmer Joe", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Kitchen Helper|1|Cook|Grilled Fish"] = { quest = "Kitchen Helper", stage = 1, island = "Maple Village", objective = "Cook", goal = "AcquireItem", target = "Grilled Fish", amount = 1, acquire = "Cooking", source = "Grilled Fish", location = "Maple Village", marker = nil, handler = "LifeSkills.cookToward", status = "IMPLEMENTED" }
	M.STAGES["Kitchen Helper|2|Talk|Remy"] = { quest = "Kitchen Helper", stage = 2, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Remy", amount = 1, acquire = nil, source = "Remy", location = "Maple Village", marker = "Remy", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Pecking Order|1|Obtain|Chicken Pet"] = { quest = "Pecking Order", stage = 1, island = "Maple Village", objective = "Obtain", goal = "Other", target = "Chicken Pet", amount = 1, acquire = nil, source = "Chicken Pet", location = "Maple Village", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Pecking Order|2|Talk|Chicken Hank"] = { quest = "Pecking Order", stage = 2, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Chicken Hank", amount = 1, acquire = nil, source = "Chicken Hank", location = "Maple Village", marker = "Chicken Hank", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["The Full Harvest|1|Fertilize|Crop"] = { quest = "The Full Harvest", stage = 1, island = "Maple Village", objective = "Fertilize", goal = "AcquireItem", target = "Crop", amount = 1, acquire = "Farming", source = "Crop", location = "Maple Village", marker = nil, handler = "LifeSkills.farmToward", status = "IMPLEMENTED" }
	M.STAGES["The Full Harvest|1|Harvest|Crop"] = { quest = "The Full Harvest", stage = 1, island = "Maple Village", objective = "Harvest", goal = "AcquireItem", target = "Crop", amount = 12, acquire = "Farming", source = "Crop", location = "Maple Village", marker = nil, handler = "LifeSkills.farmToward", status = "IMPLEMENTED" }
	M.STAGES["The Full Harvest|2|Talk|Farmer Joe"] = { quest = "The Full Harvest", stage = 2, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Farmer Joe", amount = 1, acquire = nil, source = "Farmer Joe", location = "Maple Village", marker = "Farmer Joe", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["The Perfect Dish|1|Perfect Cook|Dish"] = { quest = "The Perfect Dish", stage = 1, island = "Maple Village", objective = "Perfect Cook", goal = "AcquireItem", target = "Dish", amount = 1, acquire = "Cooking", source = "Dish", location = "Maple Village", marker = nil, handler = "LifeSkills.cookToward", status = "IMPLEMENTED" }
	M.STAGES["The Perfect Dish|2|Talk|Remy"] = { quest = "The Perfect Dish", stage = 2, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Remy", amount = 1, acquire = nil, source = "Remy", location = "Maple Village", marker = "Remy", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Trouble Down the Well|1|CollectLocalItem|Henrietta"] = { quest = "Trouble Down the Well", stage = 1, island = "Maple Village", objective = "CollectLocalItem", goal = "AcquireItem", target = "Henrietta", amount = 1, acquire = "WorldPickup", source = "Martha Chicken", location = "Maple Village", marker = "Martha Chicken", handler = "Acquire.WorldPickup", status = "IMPLEMENTED" }
	M.STAGES["Trouble Down the Well|2|Talk|Martha"] = { quest = "Trouble Down the Well", stage = 2, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Martha", amount = 1, acquire = nil, source = "Martha", location = "Maple Village", marker = "Martha", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["[TUTORIAL] Fruit/Style Storage|1|Visit|Closet"] = { quest = "[TUTORIAL] Fruit/Style Storage", stage = 1, island = "Tutorial", objective = "Visit", goal = "Interact", target = "Closet", amount = 1, acquire = nil, source = "Closet", location = "Tutorial", marker = "Closet", handler = "Quest.goTagged", status = "IMPLEMENTED" }
	M.STAGES["Bullies in Suits|1|Kill|Corrupt Marine"] = { quest = "Bullies in Suits", stage = 1, island = "Anchor Town", objective = "Kill", goal = "Kill", target = "Corrupt Marine", amount = 6, acquire = nil, source = "Corrupt Marine", location = "Anchor Town", marker = "Corrupt Marine Marker", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Bullies in Suits|2|Talk|Koro"] = { quest = "Bullies in Suits", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Koro", amount = 1, acquire = nil, source = "Koro", location = "Anchor Town", marker = "Koro", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Granny's Nemesis|1|Kill|Blonde Goblin"] = { quest = "Granny's Nemesis", stage = 1, island = "Anchor Town", objective = "Kill", goal = "Kill", target = "Blonde Goblin", amount = 1, acquire = nil, source = "Blonde Goblin", location = "Anchor Town", marker = "Helmeppo (Guards)", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Granny's Nemesis|1|Kill|Corrupt Guard"] = { quest = "Granny's Nemesis", stage = 1, island = "Anchor Town", objective = "Kill", goal = "Kill", target = "Corrupt Guard", amount = 2, acquire = nil, source = "Corrupt Guard", location = "Anchor Town", marker = "Corrupt Guard", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Granny's Nemesis|2|Talk|Granny Todo"] = { quest = "Granny's Nemesis", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Granny Todo", amount = 1, acquire = nil, source = "Granny Todo", location = "Anchor Town", marker = "Granny Todo", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Officer Termination|1|Kill|Corrupt Marine Officer"] = { quest = "Officer Termination", stage = 1, island = "Anchor Town", objective = "Kill", goal = "Kill", target = "Corrupt Marine Officer", amount = 7, acquire = nil, source = "Corrupt Marine Officer", location = "Anchor Town", marker = "Corrupt Marine Officer Marker", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Officer Termination|2|Talk|Maeve"] = { quest = "Officer Termination", stage = 2, island = "Anchor Town", objective = "Talk", goal = "Talk", target = "Maeve", amount = 1, acquire = nil, source = "Maeve", location = "Anchor Town", marker = "Maeve", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Tyrannical Captain|1|Kill|Axe-Hand Logan"] = { quest = "Tyrannical Captain", stage = 1, island = "Anchor Town", objective = "Kill", goal = "Kill", target = "Axe-Hand Logan", amount = 1, acquire = nil, source = "Axe-Hand Logan", location = "Anchor Town", marker = "Axe-Hand Logan Marker", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Billy's Business|1|Kill|Killer Clown"] = { quest = "Billy's Business", stage = 1, island = "Clown Town", objective = "Kill", goal = "Kill", target = "Killer Clown", amount = 7, acquire = nil, source = "Killer Clown", location = "Clown Town", marker = "Killer Clown Marker", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Billy's Business|2|Talk|Billy B."] = { quest = "Billy's Business", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Billy B.", amount = 1, acquire = nil, source = "Billy B.", location = "Clown Town", marker = "Billy B.", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Cat Problem|1|Kill|Circus Lion"] = { quest = "Cat Problem", stage = 1, island = "Clown Town", objective = "Kill", goal = "Kill", target = "Circus Lion", amount = 1, acquire = nil, source = "Circus Lion", location = "Clown Town", marker = "Beast Tamer Marker", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Cat Problem|1|Kill|Beast Tamer"] = { quest = "Cat Problem", stage = 1, island = "Clown Town", objective = "Kill", goal = "Kill", target = "Beast Tamer", amount = 1, acquire = nil, source = "Beast Tamer", location = "Clown Town", marker = "Beast Tamer Marker", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Cat Problem|2|Talk|Stephon"] = { quest = "Cat Problem", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Stephon", amount = 1, acquire = nil, source = "Stephon", location = "Clown Town", marker = "Stephon", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Choppy The Clown|1|Kill|Choppy The Clown"] = { quest = "Choppy The Clown", stage = 1, island = "Clown Town", objective = "Kill", goal = "Kill", target = "Choppy The Clown", amount = 1, acquire = nil, source = "Choppy The Clown", location = "Clown Town", marker = "Choppy The Clown Marker", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Choppy The Clown|2|Talk|Mayor Kiyoshi [2]"] = { quest = "Choppy The Clown", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Mayor Kiyoshi [2]", amount = 1, acquire = nil, source = "Mayor Kiyoshi [2]", location = "Clown Town", marker = "Mayor Kiyoshi [2]", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Nibblebottom's Revenge|1|Kill|Clown Officer"] = { quest = "Nibblebottom's Revenge", stage = 1, island = "Clown Town", objective = "Kill", goal = "Kill", target = "Clown Officer", amount = 5, acquire = nil, source = "Clown Officer", location = "Clown Town", marker = nil, handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Nibblebottom's Revenge|2|Talk|Johnny Nibblebottom"] = { quest = "Nibblebottom's Revenge", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Johnny Nibblebottom", amount = 1, acquire = nil, source = "Johnny Nibblebottom", location = "Clown Town", marker = "Johnny Nibblebottom", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["This Is Personal|1|Kill|Clown"] = { quest = "This Is Personal", stage = 1, island = "Clown Town", objective = "Kill", goal = "Kill", target = "Clown", amount = 7, acquire = nil, source = "Clown", location = "Clown Town", marker = "Clown Marker", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["This Is Personal|2|Talk|Clowny D. Clown"] = { quest = "This Is Personal", stage = 2, island = "Clown Town", objective = "Talk", goal = "Talk", target = "Clowny D. Clown", amount = 1, acquire = nil, source = "Clowny D. Clown", location = "Clown Town", marker = "Clowny D. Clown", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Clear the Road|1|Kill|Black Noir Pirate"] = { quest = "Clear the Road", stage = 1, island = "Maple Village", objective = "Kill", goal = "Kill", target = "Black Noir Pirate", amount = 8, acquire = nil, source = "Black Noir Pirate", location = "Maple Village", marker = "Black Noir Pirate Marker", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Clear the Road|2|Talk|Nell"] = { quest = "Clear the Road", stage = 2, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Nell", amount = 1, acquire = nil, source = "Nell", location = "Maple Village", marker = "Nell", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Peace of Mind|1|Kill|Black Noir Officer"] = { quest = "Peace of Mind", stage = 1, island = "Maple Village", objective = "Kill", goal = "Kill", target = "Black Noir Officer", amount = 5, acquire = nil, source = "Black Noir Officer", location = "Maple Village", marker = "Black Noir Officer Marker", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Peace of Mind|2|Talk|Gus"] = { quest = "Peace of Mind", stage = 2, island = "Maple Village", objective = "Talk", goal = "Talk", target = "Gus", amount = 1, acquire = nil, source = "Gus", location = "Maple Village", marker = "Gus", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Debug Quest|1|Kill|Corrupt Marine"] = { quest = "Debug Quest", stage = 1, island = "Test", objective = "Kill", goal = "Kill", target = "Corrupt Marine", amount = 1, acquire = nil, source = "Corrupt Marine", location = "Test", marker = nil, handler = "Combat.attack", status = "UNRESOLVED" }
	M.STAGES["Debug Quest 2|1|Kill|Corrupt Marine"] = { quest = "Debug Quest 2", stage = 1, island = "Test", objective = "Kill", goal = "Kill", target = "Corrupt Marine", amount = 2, acquire = nil, source = "Corrupt Marine", location = "Test", marker = nil, handler = "Combat.attack", status = "UNRESOLVED" }
	M.STAGES["Brawler 1|1|Emote|Pushup"] = { quest = "Brawler 1", stage = 1, island = "Fighting Style", objective = "Emote", goal = "Unresolved", target = "Pushup", amount = 20, acquire = nil, source = "Pushup", location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Brawler 1|1|Emote|Situp"] = { quest = "Brawler 1", stage = 1, island = "Fighting Style", objective = "Emote", goal = "Unresolved", target = "Situp", amount = 20, acquire = nil, source = "Situp", location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Brawler 1|2|Talk|Wallace"] = { quest = "Brawler 1", stage = 2, island = "Fighting Style", objective = "Talk", goal = "Talk", target = "Wallace", amount = 1, acquire = nil, source = "Wallace", location = "Fighting Style", marker = "Wallace", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Brawler 2|1|Take Damage|"] = { quest = "Brawler 2", stage = 1, island = "Fighting Style", objective = "Take Damage", goal = "Other", target = "", amount = 200, acquire = nil, source = nil, location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Brawler 2|1|Damage|"] = { quest = "Brawler 2", stage = 1, island = "Fighting Style", objective = "Damage", goal = "Other", target = "", amount = 200, acquire = nil, source = nil, location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Brawler 2|2|Talk|Wallace"] = { quest = "Brawler 2", stage = 2, island = "Fighting Style", objective = "Talk", goal = "Talk", target = "Wallace", amount = 1, acquire = nil, source = "Wallace", location = "Fighting Style", marker = "Wallace", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Brawler 3|1|Take Damage|"] = { quest = "Brawler 3", stage = 1, island = "Fighting Style", objective = "Take Damage", goal = "Other", target = "", amount = 300, acquire = nil, source = nil, location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Brawler 3|1|Damage|"] = { quest = "Brawler 3", stage = 1, island = "Fighting Style", objective = "Damage", goal = "Other", target = "", amount = 300, acquire = nil, source = nil, location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Brawler 3|2|Talk|Wallace"] = { quest = "Brawler 3", stage = 2, island = "Fighting Style", objective = "Talk", goal = "Talk", target = "Wallace", amount = 1, acquire = nil, source = "Wallace", location = "Fighting Style", marker = "Wallace", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Brawler 4|1|Take Damage|"] = { quest = "Brawler 4", stage = 1, island = "Fighting Style", objective = "Take Damage", goal = "Other", target = "", amount = 400, acquire = nil, source = nil, location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Brawler 4|1|Damage|"] = { quest = "Brawler 4", stage = 1, island = "Fighting Style", objective = "Damage", goal = "Other", target = "", amount = 400, acquire = nil, source = nil, location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Brawler 4|2|Talk|Wallace"] = { quest = "Brawler 4", stage = 2, island = "Fighting Style", objective = "Talk", goal = "Talk", target = "Wallace", amount = 1, acquire = nil, source = "Wallace", location = "Fighting Style", marker = "Wallace", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Marksman 1|1|Land|Projectile"] = { quest = "Marksman 1", stage = 1, island = "Fighting Style", objective = "Land", goal = "Other", target = "Projectile", amount = 50, acquire = nil, source = "Projectile", location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Marksman 1|2|Talk|Captain Esopo"] = { quest = "Marksman 1", stage = 2, island = "Fighting Style", objective = "Talk", goal = "Talk", target = "Captain Esopo", amount = 1, acquire = nil, source = "Captain Esopo", location = "Fighting Style", marker = "Captain Esopo (Dialogue)", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Marksman 2|1|Proc Hunter's Timing Passive|"] = { quest = "Marksman 2", stage = 1, island = "Fighting Style", objective = "Proc Hunter's Timing Passive", goal = "Other", target = "", amount = 50, acquire = nil, source = nil, location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Marksman 2|2|Talk|Captain Esopo"] = { quest = "Marksman 2", stage = 2, island = "Fighting Style", objective = "Talk", goal = "Talk", target = "Captain Esopo", amount = 1, acquire = nil, source = "Captain Esopo", location = "Fighting Style", marker = "Captain Esopo (Dialogue)", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Marksman 3|1|Land a projectile on a marked target|"] = { quest = "Marksman 3", stage = 1, island = "Fighting Style", objective = "Land a projectile on a marked target", goal = "Other", target = "", amount = 25, acquire = nil, source = nil, location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Marksman 3|2|Talk|Captain Esopo"] = { quest = "Marksman 3", stage = 2, island = "Fighting Style", objective = "Talk", goal = "Talk", target = "Captain Esopo", amount = 1, acquire = nil, source = "Captain Esopo", location = "Fighting Style", marker = "Captain Esopo (Dialogue)", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Marksman 4|1|Reduce the cooldown of 25 skills, using quickdraw.|"] = { quest = "Marksman 4", stage = 1, island = "Fighting Style", objective = "Reduce the cooldown of 25 skills, using quickdraw.", goal = "Other", target = "", amount = 25, acquire = nil, source = nil, location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Marksman 4|1|Speed up the windup of 25 skills, using quickdraw.|"] = { quest = "Marksman 4", stage = 1, island = "Fighting Style", objective = "Speed up the windup of 25 skills, using quickdraw.", goal = "Other", target = "", amount = 25, acquire = nil, source = nil, location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Marksman 4|2|Talk|Captain Esopo"] = { quest = "Marksman 4", stage = 2, island = "Fighting Style", objective = "Talk", goal = "Talk", target = "Captain Esopo", amount = 1, acquire = nil, source = "Captain Esopo", location = "Fighting Style", marker = "Captain Esopo (Dialogue)", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Novice Swordsman 1|1|Unlock Skill|Power Slash"] = { quest = "Novice Swordsman 1", stage = 1, island = "Fighting Style", objective = "Unlock Skill", goal = "Unresolved", target = "Power Slash", amount = 1, acquire = nil, source = "Power Slash", location = "Fighting Style", marker = "Corrupt Marine", handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Novice Swordsman 1|2|Damage|Power Slash"] = { quest = "Novice Swordsman 1", stage = 2, island = "Fighting Style", objective = "Damage", goal = "Other", target = "Power Slash", amount = 200, acquire = nil, source = "Power Slash", location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Novice Swordsman 1|3|Talk|Shiro"] = { quest = "Novice Swordsman 1", stage = 3, island = "Fighting Style", objective = "Talk", goal = "Talk", target = "Shiro", amount = 1, acquire = nil, source = "Shiro", location = "Fighting Style", marker = "Shiro", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Novice Swordsman 2|1|Unlock Skill|Sword Lunge"] = { quest = "Novice Swordsman 2", stage = 1, island = "Fighting Style", objective = "Unlock Skill", goal = "Unresolved", target = "Sword Lunge", amount = 1, acquire = nil, source = "Sword Lunge", location = "Fighting Style", marker = "Corrupt Marine Officer", handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Novice Swordsman 2|2|Damage|Sword Lunge"] = { quest = "Novice Swordsman 2", stage = 2, island = "Fighting Style", objective = "Damage", goal = "Other", target = "Sword Lunge", amount = 200, acquire = nil, source = "Sword Lunge", location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Novice Swordsman 2|3|Talk|Shiro"] = { quest = "Novice Swordsman 2", stage = 3, island = "Fighting Style", objective = "Talk", goal = "Talk", target = "Shiro", amount = 1, acquire = nil, source = "Shiro", location = "Fighting Style", marker = "Shiro", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Novice Swordsman 3|1|Unlock Skill|Whirlwind Slash"] = { quest = "Novice Swordsman 3", stage = 1, island = "Fighting Style", objective = "Unlock Skill", goal = "Unresolved", target = "Whirlwind Slash", amount = 1, acquire = nil, source = "Whirlwind Slash", location = "Fighting Style", marker = "Corrupt Marine Officer", handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Novice Swordsman 3|2|Damage|Whirlwind Slash"] = { quest = "Novice Swordsman 3", stage = 2, island = "Fighting Style", objective = "Damage", goal = "Other", target = "Whirlwind Slash", amount = 200, acquire = nil, source = "Whirlwind Slash", location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Novice Swordsman 3|3|Talk|Shiro"] = { quest = "Novice Swordsman 3", stage = 3, island = "Fighting Style", objective = "Talk", goal = "Talk", target = "Shiro", amount = 1, acquire = nil, source = "Shiro", location = "Fighting Style", marker = "Shiro", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Novice Swordsman 4|1|Damage|Power Slash"] = { quest = "Novice Swordsman 4", stage = 1, island = "Fighting Style", objective = "Damage", goal = "Other", target = "Power Slash", amount = 200, acquire = nil, source = "Power Slash", location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Novice Swordsman 4|1|Damage|Sword Lunge"] = { quest = "Novice Swordsman 4", stage = 1, island = "Fighting Style", objective = "Damage", goal = "Other", target = "Sword Lunge", amount = 200, acquire = nil, source = "Sword Lunge", location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Novice Swordsman 4|1|Damage|Whirlwind Slash"] = { quest = "Novice Swordsman 4", stage = 1, island = "Fighting Style", objective = "Damage", goal = "Other", target = "Whirlwind Slash", amount = 200, acquire = nil, source = "Whirlwind Slash", location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Novice Swordsman 4|1|Damage|Sword"] = { quest = "Novice Swordsman 4", stage = 1, island = "Fighting Style", objective = "Damage", goal = "Other", target = "Sword", amount = 1000, acquire = nil, source = "Sword", location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Novice Swordsman 4|2|Talk|Shiro"] = { quest = "Novice Swordsman 4", stage = 2, island = "Fighting Style", objective = "Talk", goal = "Talk", target = "Shiro", amount = 1, acquire = nil, source = "Shiro", location = "Fighting Style", marker = "Shiro", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Trickster 1|1|Pickpocket|Gold"] = { quest = "Trickster 1", stage = 1, island = "Fighting Style", objective = "Pickpocket", goal = "Other", target = "Gold", amount = 100, acquire = nil, source = "Gold", location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Trickster 1|1|Land|Pocket Sand"] = { quest = "Trickster 1", stage = 1, island = "Fighting Style", objective = "Land", goal = "Other", target = "Pocket Sand", amount = 20, acquire = nil, source = "Pocket Sand", location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Trickster 1|2|Talk|Loki [2]"] = { quest = "Trickster 1", stage = 2, island = "Fighting Style", objective = "Talk", goal = "Talk", target = "Loki [2]", amount = 1, acquire = nil, source = "Loki [2]", location = "Fighting Style", marker = "Loki [2]", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Trickster 2|1|Land|Cheap Shot"] = { quest = "Trickster 2", stage = 1, island = "Fighting Style", objective = "Land", goal = "Other", target = "Cheap Shot", amount = 25, acquire = nil, source = "Cheap Shot", location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Trickster 2|2|Talk|Loki [2]"] = { quest = "Trickster 2", stage = 2, island = "Fighting Style", objective = "Talk", goal = "Talk", target = "Loki [2]", amount = 1, acquire = nil, source = "Loki [2]", location = "Fighting Style", marker = "Loki [2]", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Trickster 3|1|Deceive|Hostile Enemy"] = { quest = "Trickster 3", stage = 1, island = "Fighting Style", objective = "Deceive", goal = "Other", target = "Hostile Enemy", amount = 25, acquire = nil, source = "Hostile Enemy", location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Trickster 3|2|Talk|Loki [2]"] = { quest = "Trickster 3", stage = 2, island = "Fighting Style", objective = "Talk", goal = "Talk", target = "Loki [2]", amount = 1, acquire = nil, source = "Loki [2]", location = "Fighting Style", marker = "Loki [2]", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Trickster 4|1|Damage|Poison"] = { quest = "Trickster 4", stage = 1, island = "Fighting Style", objective = "Damage", goal = "Other", target = "Poison", amount = 750, acquire = nil, source = "Poison", location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Trickster 4|1|Land Poisoned Shiv While Stealthed|"] = { quest = "Trickster 4", stage = 1, island = "Fighting Style", objective = "Land Poisoned Shiv While Stealthed", goal = "Other", target = "", amount = 25, acquire = nil, source = nil, location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Trickster 4|2|Talk|Loki [2]"] = { quest = "Trickster 4", stage = 2, island = "Fighting Style", objective = "Talk", goal = "Talk", target = "Loki [2]", amount = 1, acquire = nil, source = "Loki [2]", location = "Fighting Style", marker = "Loki [2]", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Trickster 5|1|Fear|Enemy"] = { quest = "Trickster 5", stage = 1, island = "Fighting Style", objective = "Fear", goal = "Other", target = "Enemy", amount = 50, acquire = nil, source = "Enemy", location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Trickster 5|1|Place Down Trap While Stealthed|"] = { quest = "Trickster 5", stage = 1, island = "Fighting Style", objective = "Place Down Trap While Stealthed", goal = "Other", target = "", amount = 10, acquire = nil, source = nil, location = "Fighting Style", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Trickster 5|2|Talk|Loki [2]"] = { quest = "Trickster 5", stage = 2, island = "Fighting Style", objective = "Talk", goal = "Talk", target = "Loki [2]", amount = 1, acquire = nil, source = "Loki [2]", location = "Fighting Style", marker = "Loki [2]", handler = "Quest.talk", status = "IMPLEMENTED" }
	M.STAGES["Chop Chop Punch|1|Defeat|World Boss Buggy"] = { quest = "Chop Chop Punch", stage = 1, island = "Skill Mastery", objective = "Defeat", goal = "Kill", target = "World Boss Buggy", amount = 1, acquire = nil, source = "World Boss Buggy", location = "Skill Mastery", marker = nil, handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Liberation|1|Defeat|World Boss Buggy"] = { quest = "Liberation", stage = 1, island = "Skill Mastery", objective = "Defeat", goal = "Kill", target = "World Boss Buggy", amount = 1, acquire = nil, source = "World Boss Buggy", location = "Skill Mastery", marker = nil, handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Easy Pickings|1|Steal|Tip Jar"] = { quest = "Easy Pickings", stage = 1, island = "Anchor Town", objective = "Steal", goal = "Unresolved", target = "Tip Jar", amount = 1, acquire = nil, source = "Tip Jar", location = "Anchor Town", marker = "Tip Jar", handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Easy Pickings|2|Cash Out|Tip Jar"] = { quest = "Easy Pickings", stage = 2, island = "Anchor Town", objective = "Cash Out", goal = "Unresolved", target = "Tip Jar", amount = 1, acquire = nil, source = "Tip Jar", location = "Anchor Town", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Jack's Daily Haul|0||"] = { quest = "Jack's Daily Haul", stage = 0, island = "Anchor Town", objective = "", goal = "Unresolved", target = "", amount = 0, acquire = nil, source = nil, location = "Anchor Town", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Kim Wu's Daily Quota|0||"] = { quest = "Kim Wu's Daily Quota", stage = 0, island = "Anchor Town", objective = "", goal = "Unresolved", target = "", amount = 0, acquire = nil, source = nil, location = "Anchor Town", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Noise Complaint|1|Kill|Sushi"] = { quest = "Noise Complaint", stage = 1, island = "Anchor Town", objective = "Kill", goal = "Kill", target = "Sushi", amount = 1, acquire = nil, source = "Sushi", location = "Anchor Town", marker = "Sushi", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Joe's Daily Chores|0||"] = { quest = "Joe's Daily Chores", stage = 0, island = "Maple Village", objective = "", goal = "Unresolved", target = "", amount = 0, acquire = nil, source = nil, location = "Maple Village", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Remy's Daily Order|0||"] = { quest = "Remy's Daily Order", stage = 0, island = "Maple Village", objective = "", goal = "Unresolved", target = "", amount = 0, acquire = nil, source = nil, location = "Maple Village", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Daily Quest Test|1|Hit|Training Dummy"] = { quest = "Daily Quest Test", stage = 1, island = "Test", objective = "Hit", goal = "Kill", target = "Training Dummy", amount = 5, acquire = nil, source = "Training Dummy", location = "Test", marker = nil, handler = "Combat.attack", status = "UNRESOLVED" }
	M.STAGES["Corruption Cleanse|1|Kill|Corrupt Marine"] = { quest = "Corruption Cleanse", stage = 1, island = "Anchor Town", objective = "Kill", goal = "Kill", target = "Corrupt Marine", amount = 6, acquire = nil, source = "Corrupt Marine", location = "Anchor Town", marker = "Corrupt Marine Marker", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Corruption Cleanse|2|Kill|Afuaru, The Hoarder"] = { quest = "Corruption Cleanse", stage = 2, island = "Anchor Town", objective = "Kill", goal = "Kill", target = "Afuaru, The Hoarder", amount = 1, acquire = nil, source = "Afuaru, The Hoarder", location = "Anchor Town", marker = "Afuaru, The Hoarder", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Corruption Cleanse|3|Kill|Corrupt Marine Officer"] = { quest = "Corruption Cleanse", stage = 3, island = "Anchor Town", objective = "Kill", goal = "Kill", target = "Corrupt Marine Officer", amount = 5, acquire = nil, source = "Corrupt Marine Officer", location = "Anchor Town", marker = "Corrupt Marine Officer", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Corruption Cleanse|4|Kill|Blonde Goblin"] = { quest = "Corruption Cleanse", stage = 4, island = "Anchor Town", objective = "Kill", goal = "Kill", target = "Blonde Goblin", amount = 1, acquire = nil, source = "Blonde Goblin", location = "Anchor Town", marker = "Helmeppo (Soro)", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Corruption Cleanse|4|Kill|Soro"] = { quest = "Corruption Cleanse", stage = 4, island = "Anchor Town", objective = "Kill", goal = "Kill", target = "Soro", amount = 1, acquire = nil, source = "Soro", location = "Anchor Town", marker = "Soro", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Corruption Cleanse|5|Kill|Axe-Hand Logan"] = { quest = "Corruption Cleanse", stage = 5, island = "Anchor Town", objective = "Kill", goal = "Kill", target = "Axe-Hand Logan", amount = 1, acquire = nil, source = "Axe-Hand Logan", location = "Anchor Town", marker = "Axe-Hand Logan", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Weekly Quest Test|1|Hit|Training Dummy"] = { quest = "Weekly Quest Test", stage = 1, island = "Test", objective = "Hit", goal = "Kill", target = "Training Dummy", amount = 5, acquire = nil, source = "Training Dummy", location = "Test", marker = nil, handler = "Combat.attack", status = "UNRESOLVED" }
	M.STAGES["The Stolen Tip Jar|0||"] = { quest = "The Stolen Tip Jar", stage = 0, island = "Anchor Town", objective = "", goal = "Unresolved", target = "", amount = 0, acquire = nil, source = nil, location = "Anchor Town", marker = nil, handler = "UNKNOWN", status = "UNRESOLVED" }
	M.STAGES["Defeat 25 Corrupt Marines|1|Kill|Corrupt Marine"] = { quest = "Defeat 25 Corrupt Marines", stage = 1, island = "Crew", objective = "Kill", goal = "Kill", target = "Corrupt Marine", amount = 25, acquire = nil, source = "Corrupt Marine", location = "Crew", marker = "Corrupt Marine Marker", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Defeat 50 Corrupt Marines|1|Kill|Corrupt Marine"] = { quest = "Defeat 50 Corrupt Marines", stage = 1, island = "Crew", objective = "Kill", goal = "Kill", target = "Corrupt Marine", amount = 50, acquire = nil, source = "Corrupt Marine", location = "Crew", marker = "Corrupt Marine Marker", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Defeat 75 Corrupt Marines|1|Kill|Corrupt Marine"] = { quest = "Defeat 75 Corrupt Marines", stage = 1, island = "Crew", objective = "Kill", goal = "Kill", target = "Corrupt Marine", amount = 75, acquire = nil, source = "Corrupt Marine", location = "Crew", marker = "Corrupt Marine Marker", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Crew: Defeat Corrupt Marines|1|Kill|Corrupt Marine"] = { quest = "Crew: Defeat Corrupt Marines", stage = 1, island = "Crew", objective = "Kill", goal = "Kill", target = "Corrupt Marine", amount = 10, acquire = nil, source = "Corrupt Marine", location = "Crew", marker = "Corrupt Marine Marker", handler = "Combat.attack", status = "IMPLEMENTED" }
	M.STAGES["Crew: Defeat Corrupt Marines|2|Talk|Koro"] = { quest = "Crew: Defeat Corrupt Marines", stage = 2, island = "Crew", objective = "Talk", goal = "Talk", target = "Koro", amount = 1, acquire = nil, source = "Koro", location = "Crew", marker = "Koro", handler = "Quest.talk", status = "IMPLEMENTED" }

	function M.itemOf(name)
		return name and M.ITEMS[name]
	end

	function M.lookup(quest, stage, typ, target)
		if not quest then
			return nil
		end
		local key = string.format("%s|%s|%s|%s", quest, tostring(stage or 1), tostring(typ or ""), tostring(target or ""))
		local hit = M.STAGES[key]
		if hit then
			return hit
		end
		for _, row in pairs(M.STAGES) do
			if row.quest == quest and row.target == target and row.objective == typ then
				return row
			end
		end
		if target and M.ITEMS[target] then
			local it = M.ITEMS[target]
			return {
				quest = quest,
				stage = stage,
				goal = "AcquireItem",
				target = target,
				acquire = it.method,
				source = it.source,
				location = it.location,
				handler = "Acquire.AcquireItem",
			}
		end
		return nil
	end

	function M.subgoalsOf(quest)
		return quest and M.SUBGOALS[quest]
	end

	return M
end
]],
    ["Game/Remotes.lua"] = [[-- Resolve remotes. Fire only verified arg shapes.

return function(GB)
	local RS = game:GetService("ReplicatedStorage")
	local M = {
		failed = {},
	}

	local function ev(name)
		local e = RS:FindFirstChild("Events")
		return e and e:FindFirstChild(name)
	end

	function M.get(name)
		return ev(name)
	end

	function M.fire(name, gap, ...)
		if not GB.Retry.rateOk("re:" .. name, gap or 0.55) then
			return false, "rate"
		end
		local r = ev(name)
		if not r then
			GB.Log.warn("ERROR", "remote missing " .. name)
			M.failed[name] = "missing"
			return false, "missing"
		end
		local ok, err = pcall(function(...)
			r:FireServer(...)
		end, ...)
		if not ok then
			GB.Log.err("ERROR", name .. " FireServer " .. tostring(err))
			GB.Persist.failRemote(name, err)
			return false, err
		end
		return true
	end

	function M.invoke(name, ...)
		if not GB.Retry.rateOk("rf:" .. name, 0.4) then
			return nil, "rate"
		end
		local r = ev(name)
		if not r then
			return nil, "missing"
		end
		local ok, res = pcall(function(...)
			return r:InvokeServer(...)
		end, ...)
		if not ok then
			GB.Persist.failRemote(name, res)
			return nil, res
		end
		return res
	end

	-- VERIFIED wrappers
	function M.talk(displayName)
		return M.fire("ClientQuest", 0.8, "Talk", displayName)
	end

	function M.autoTalk(displayName)
		return M.fire("ClientQuest", 0.8, "Automatic Talk", displayName)
	end

	function M.beginAutomatic(questName)
		-- Logbook path. NOT BeginQuest.
		return M.fire("ClientQuest", 1.0, "BeginAutomatic", questName)
	end

	function M.closetVisit()
		return M.fire("ClientQuest", 1.2, "Closet", "Visit")
	end

	function M.dialogueConfig(config)
		local b = RS:FindFirstChild("Events") and RS.Events:FindFirstChild("DialogueBindable")
		if not (b and config) then
			return false
		end
		if not GB.Retry.rateOk("dialogue", 0.7) then
			return false
		end
		return pcall(function()
			b:Fire(config)
		end)
	end

	function M.statInvest(stat, n)
		local r = ev("StatPoints")
		if not r then
			GB.Log.warn("ERROR", "remote missing StatPoints")
			return false
		end
		if not r:IsA("RemoteEvent") then
			GB.Log.warn("ERROR", "StatPoints type " .. tostring(r.ClassName))
			return false, "type"
		end
		n = math.max(1, math.floor(tonumber(n) or 1))
		if not GB.Retry.rateOk("re:StatPoints", 0.2) then
			return false, "rate"
		end
		local ok, err = pcall(function()
			r:FireServer("Invest", tostring(stat), n)
		end)
		if not ok then
			GB.Log.err("ERROR", "StatPoints FireServer " .. tostring(err))
			return false, err
		end
		return true
	end

	function M.describeStatInvest()
		local r = ev("StatPoints")
		local p = "ReplicatedStorage.Events.StatPoints"
		return {
			Path = p,
			Type = r and r.ClassName or "missing",
			Method = "FireServer",
			Args = { "Invest", "<StatName>", "<Amount:number>" },
			Callsite = "MenuHandler.Activated",
		}
	end

	function M.statReplicate()
		local r = ev("StatReplication")
		if r then
			pcall(function()
				r:FireServer()
			end)
			return true
		end
		return false
	end

	function M.shopPurchase(part, qty)
		return M.fire("Shop", 0.7, "Purchase", part, qty or 1)
	end

	function M.rotatingPurchase(index, qty)
		return M.fire("RotatingShop", 0.7, "Purchase", index, qty or 1)
	end

	function M.rowboatPurchase()
		return M.fire("Ships", 1.0, "Purchase", { Type = "Rowboat" })
	end

	function M.shipSpawn(index)
		return M.fire("Ships", 1.2, "Spawn", index)
	end

	function M.heldEquip(id)
		return M.fire("HeldItem", 0.4, "Equip", id)
	end

	-- BackpackLocal.MoveToolToSlot → SaveOrder(slot, key)
	function M.saveOrder(slot, key)
		return M.fire("SaveOrder", 0.35, slot, key)
	end

	-- BindableEvent. BackpackLocal: Fire(true) selects topbar → OpenStorage.
	function M.backpackToggle(open)
		local ev = RS:FindFirstChild("Events")
		local b = ev and ev:FindFirstChild("BackpackToggle")
		if not b then
			return false
		end
		if not GB.Retry.rateOk("be:BackpackToggle", 0.35) then
			return false
		end
		local ok = pcall(function()
			if open == nil then
				b:Fire()
			else
				b:Fire(open and true or false)
			end
		end)
		return ok
	end

	function M.heldUnequip()
		return M.fire("HeldItem", 0.4, "Unequip")
	end

	function M.sell(key, amount)
		if amount then
			return M.fire("SellItem", 0.6, key, amount)
		end
		return M.fire("SellItem", 0.6, key)
	end

	function M.upgrade(key)
		return M.fire("Upgrade", 0.8, "Upgrade", key)
	end

	function M.pickupFruit(fruitId)
		return M.fire("PickupDF", 0.8, fruitId)
	end

	function M.storeFruit(name, force)
		if name then
			return M.fire("PermanentFruit", 0.8, "Store Fruit", name, force and true or nil)
		end
		return M.fire("PermanentFruit", 0.8, "Store Fruit")
	end

	function M.equipPermanentFruit(name, force)
		return M.fire("PermanentFruit", 0.8, "Equip Permanent Fruit", name, force and true or nil)
	end

	function M.changeStyle(name)
		return M.fire("ChangeFightingStyle", 0.8, name)
	end

	function M.promptSkillEquip(name)
		return M.fire("PromptSkillEquip", 0.6, name)
	end

	-- SkillHandler ToggleEquip: Events.Skill:FireServer("Equip"|"Unequip", skillName)
	function M.skillEquip(name)
		return M.fire("Skill", 0.55, "Equip", name)
	end

	function M.skillUnequip(name)
		return M.fire("Skill", 0.55, "Unequip", name)
	end

	-- ScrollFrameSlide ButtonPressed: ConsumeSkillScroll:FireServer(nil). Server reads HeldItem.
	function M.consumeSkillScroll()
		return M.fire("ConsumeSkillScroll", 0.7, nil)
	end

	-- ForceOpenLogbook after Tutorial/Controls sequence
	function M.openLogbookHelp()
		local ev = RS:FindFirstChild("Events")
		local folder = ev and ev:FindFirstChild("QuestEvents")
		local r = folder and folder:FindFirstChild("OpenLogbookHelp")
		if not r then
			GB.Log.warn("ERROR", "remote missing OpenLogbookHelp")
			return false, "missing"
		end
		if not GB.Retry.rateOk("re:OpenLogbookHelp", 1.0) then
			return false, "rate"
		end
		r:FireServer()
		return true
	end

	-- StarterPlayer Zones: ClientQuest(zoneName, "Enter Zone")
	function M.enterZone(zoneName)
		return M.fire("ClientQuest", 0.8, zoneName, "Enter Zone")
	end

	-- QuestInfo client + QuestLocal LoadQuests
	function M.getQuests()
		local r = ev("GetData")
		if not r then
			GB.Log.warn("ERROR", "remote missing GetData")
			return nil, nil
		end
		if not GB.Retry.rateOk("rf:GetDataQuests", 0.35) then
			return nil, nil
		end
		local ok, a, b = pcall(r.InvokeServer, r, "Quests", "Completed Quests")
		if not ok then
			GB.Log.err("ERROR", "GetData Quests " .. tostring(a))
			return nil, nil
		end
		return a, b
	end

	function M.code(str)
		return M.fire("Codes", 0.55, str)
	end

	function M.codeProg(...)
		return M.fire("CodeProg", 0.5, ...)
	end

	function M.getData(key)
		return M.invoke("GetData", key)
	end

	function M.getStats()
		local r = ev("GetStats")
		if not r then
			return nil, nil
		end
		if not r:IsA("RemoteFunction") then
			GB.Log.warn("ERROR", "GetStats type " .. tostring(r.ClassName))
			return nil, nil
		end
		if not GB.Retry.rateOk("rf:GetStats", 0.45) then
			return nil, nil
		end
		local ok, a, b = pcall(r.InvokeServer, r)
		if not ok then
			GB.Persist.failRemote("GetStats", a)
			return nil, nil
		end
		return a, b
	end

	function M.getEquip()
		return M.invoke("GetEquip")
	end

	function M.neverBeginQuest()
		-- rules.never_fire_beginquest
		return false
	end

	return M
end
]],
    ["Game/Resolver.lua"] = [[-- Resolve NPC / enemy / item / island / shop / trainer / remote.
-- World Graves is DialogueNPCs "Officer Graves [2]" (DisplayName "Officer Graves").
-- ReplicatedStorage "Officer Graves" is character-create — never interact.

return function(GB)
	local CS = game:GetService("CollectionService")
	local RS = game:GetService("ReplicatedStorage")
	local M = {}

	-- Verified only. Studio + QuestInfo + DialogueUtilities.GetNPCName.
	M.NPC_ALIAS = {
		["Officer Graves"] = { "Officer Graves [2]", "Graves" },
		["Officer Graves [2]"] = { "Officer Graves", "Graves" },
		["Graves"] = { "Officer Graves", "Officer Graves [2]" },
	}

	M.ENEMY_ALIAS = {
		["Barrel Clown"] = { '"Barrel Clown" Binki', "Binki" },
		["Binki"] = { '"Barrel Clown" Binki', "Barrel Clown" },
		['"Barrel Clown" Binki'] = { "Barrel Clown", "Binki" },
		["Hypnotist"] = { '"Hypnotist" Mango', "Mango" },
		["Mango"] = { '"Hypnotist" Mango', "Hypnotist" },
		['"Hypnotist" Mango'] = { "Hypnotist", "Mango" },
		-- Studio: Workspace.Entities.Training Dummy1..8, CollectionService tag TrainingDummy
		["Training Dummy"] = {
			"TrainingDummy",
			"Training Dummy1",
			"Training Dummy2",
			"Training Dummy3",
			"Training Dummy4",
			"Training Dummy5",
			"Training Dummy6",
			"Training Dummy7",
			"Training Dummy8",
		},
		["TrainingDummy"] = { "Training Dummy", "Training Dummy1" },
		-- Quest/mob-zone name. Live models: Corrupt Swordsman Officer N / Corrupt Sniper Officer N.
		-- Tag + NPCName are the variant, not "Corrupt Marine Officer". Foot soldier is "Corrupt Marine" only.
		["Corrupt Marine Officer"] = {
			"Corrupt Swordsman Officer",
			"Corrupt Sniper Officer",
		},
		["Corrupt Swordsman Officer"] = { "Corrupt Marine Officer", "Corrupt Sniper Officer" },
		["Corrupt Sniper Officer"] = { "Corrupt Marine Officer", "Corrupt Swordsman Officer" },
	}

	-- Quest target "Marine Gate". Live: Model Gate tagged Marine Metal Gate. Not the mob-zone part.
	M.OBJECT_ALIAS = {
		["Marine Gate"] = { "Marine Metal Gate", "Gate" },
		["Marine Metal Gate"] = { "Marine Gate", "Gate" },
	}

	local missLog = {}
	local dummyCache = nil
	local dummyPos = nil
	local dummyMiss = 0
	M.lastCandidates = {}
	local negativeCache = {}
	local negativeEpoch = 1
	local NEG_TTL = 3.8

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

	local function clearNegative()
		negativeCache = {}
		negativeEpoch = negativeEpoch + 1
	end

	local function negativeHit(key)
		local row = negativeCache[key]
		if type(row) ~= "table" then
			return false
		end
		if row.epoch ~= negativeEpoch then
			negativeCache[key] = nil
			return false
		end
		if os.clock() >= (row.untilAt or 0) then
			negativeCache[key] = nil
			return false
		end
		return true
	end

	local function noteNegative(key, ttl)
		negativeCache[key] = {
			untilAt = os.clock() + (ttl or NEG_TTL),
			epoch = negativeEpoch,
		}
	end

	function M.isDummyName(name)
		if type(name) ~= "string" or name == "" then
			return false
		end
		if name == "Training Dummy" or name == "TrainingDummy" then
			return true
		end
		return string.find(name, "Dummy", 1, true) ~= nil
	end

	function M.invalidateDummy()
		dummyCache = nil
	end

	function M.lastDummyPos()
		return dummyPos
	end

	function M.dummyMissCount()
		return dummyMiss
	end

	local function aliases()
		if GB.QuestData and GB.QuestData.NPC_ALIAS then
			return GB.QuestData.NPC_ALIAS
		end
		return M.NPC_ALIAS
	end

	local function pushName(list, seen, name)
		if type(name) ~= "string" or name == "" or name == "\\" then
			return
		end
		if seen[name] then
			return
		end
		seen[name] = true
		list[#list + 1] = name
	end

	function M.namesFor(request, opts)
		opts = opts or {}
		local list, seen = {}, {}
		pushName(list, seen, request)
		pushName(list, seen, opts.DisplayName)
		pushName(list, seen, opts.InternalName)
		pushName(list, seen, opts.QuestName)
		local src = aliases()
		local function addMapped(key)
			local v = src[key] or M.NPC_ALIAS[key] or M.ENEMY_ALIAS[key] or M.OBJECT_ALIAS[key]
			if type(v) == "string" then
				pushName(list, seen, v)
			elseif type(v) == "table" then
				for _, n in ipairs(v) do
					pushName(list, seen, n)
				end
			end
		end
		for _, n in ipairs({ request, opts.DisplayName, opts.InternalName }) do
			if type(n) == "string" then
				addMapped(n)
			end
		end
		for key, v in pairs(src) do
			if v == request or (type(v) == "table" and table.find(v, request)) then
				pushName(list, seen, key)
			end
		end
		return list
	end

	local function inRS(inst)
		return inst and RS:IsAncestorOf(inst)
	end

	function M.displayName(model)
		if not model then
			return nil
		end
		local attr = model:GetAttribute("NPCName") or model:GetAttribute("DisplayName")
		if type(attr) == "string" and attr ~= "" then
			return attr
		end
		local h = model:FindFirstChildOfClass("Humanoid")
		if h and h.DisplayName and h.DisplayName ~= "" then
			return h.DisplayName
		end
		return model.Name
	end

	local function isDialogue(inst)
		if not inst then
			return false
		end
		if inst:GetAttribute("Interaction") == "Dialogue" then
			return true
		end
		if inst:FindFirstChild("Dialogue") then
			return true
		end
		if inst:HasTag("Dialogue") or inst:HasTag("Interactable") then
			return true
		end
		return false
	end

	local function partOf(inst)
		if not inst then
			return nil
		end
		if inst:IsA("BasePart") then
			return inst
		end
		if inst:IsA("Attachment") then
			local host = inst.Parent
			if host and host:IsA("BasePart") then
				return host
			end
			return host and host:FindFirstChildWhichIsA("BasePart", true)
		end
		if inst:IsA("Model") then
			if inst.PrimaryPart and inst.PrimaryPart:IsA("BasePart") then
				return inst.PrimaryPart
			end
			local hrp = inst:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") then
				return hrp
			end
			return inst:FindFirstChildWhichIsA("BasePart", true)
		end
		if inst:IsA("ProximityPrompt") then
			local p = inst.Parent
			if p and p:IsA("BasePart") then
				return p
			end
			if p and p:IsA("Attachment") then
				local host = p.Parent
				if host and host:IsA("BasePart") then
					return host
				end
			end
			return p and p:FindFirstChildWhichIsA("BasePart", true)
		end
		if inst:IsA("Folder") or inst:IsA("Configuration") then
			return inst:FindFirstChildWhichIsA("BasePart", true)
		end
		return inst:FindFirstChildWhichIsA("BasePart", true)
	end

	function M.part(inst)
		return partOf(inst)
	end

	function M.positionOf(inst)
		if not inst then
			return nil
		end
		if inst:IsA("BasePart") then
			return inst.Position
		end
		if inst:IsA("Attachment") then
			return inst.WorldPosition
		end
		local p = partOf(inst)
		if p and p:IsA("BasePart") then
			return p.Position
		end
		if inst:IsA("Model") then
			local ok, cf = pcall(inst.GetPivot, inst)
			if ok and typeof(cf) == "CFrame" then
				return cf.Position
			end
		end
		return nil
	end

	local function climbRoot(inst)
		if not inst then
			return nil
		end
		if inst:IsA("Model") then
			return inst
		end
		local m = inst:FindFirstAncestorOfClass("Model")
		if m and not inRS(m) then
			return m
		end
		if inst:IsA("BasePart") or inst:IsA("Folder") or inst:IsA("Configuration") then
			return inst
		end
		return inst
	end

	-- Studio: Workspace.Entities."<Player> Slot N Pet" tagged Pet (+ NPC/Character).
	function M.isPet(inst)
		if not inst then
			return false
		end
		local root = climbRoot(inst) or inst
		if root:HasTag("Pet") then
			return true
		end
		local n = root.Name
		if type(n) == "string" and string.find(n, " Slot ", 1, true) and string.sub(n, -4) == " Pet" then
			return true
		end
		return false
	end

	local function enemyAlive(root)
		if GB.Combat and GB.Combat.IsEnemyAlive then
			return GB.Combat.IsEnemyAlive(root)
		end
		if not (root and root.Parent) then
			return false
		end
		if root:GetAttribute("Dead") == true then
			return false
		end
		local h = root:FindFirstChildOfClass("Humanoid")
		if h and h.Health <= 0 then
			return false
		end
		return true
	end

	local function usable(inst, kind)
		if not (inst and inst.Parent) or inRS(inst) then
			return false
		end
		local root = climbRoot(inst)
		if not root or inRS(root) then
			return false
		end
		if M.isPet(root) then
			return false
		end
		if kind == "enemy" then
			if GB.Combat and GB.Combat.isRecentlyDead and GB.Combat.isRecentlyDead(root) then
				return false
			end
			if not enemyAlive(root) then
				return false
			end
		end
		if root:IsA("Model") or root:IsA("BasePart") or root:IsA("Folder") or root:IsA("Configuration") then
			return M.positionOf(root) ~= nil or partOf(root) ~= nil or isDialogue(root)
		end
		return false
	end

	function M.dummy()
		if dummyCache and dummyCache.Parent and usable(dummyCache, "enemy") then
			return dummyCache
		end
		dummyCache = nil

		local tagged = CS:GetTagged("TrainingDummy")
		if type(tagged) == "table" then
			for _, t in ipairs(tagged) do
				if usable(t, "enemy") then
					dummyCache = climbRoot(t) or t
					dummyPos = M.positionOf(dummyCache)
					dummyMiss = 0
					GB.Cache.set("res:enemy:Training Dummy", dummyCache)
					GB.Log.log("RESOLVE", "Training Dummy -> " .. dummyCache:GetFullName())
					return dummyCache
				end
			end
		end

		local ents = workspace:FindFirstChild("Entities")
		if ents then
			for _, c in ipairs(ents:GetChildren()) do
				if string.find(c.Name, "Dummy", 1, true) and usable(c, "enemy") then
					dummyCache = c
					dummyPos = M.positionOf(c)
					dummyMiss = 0
					GB.Cache.set("res:enemy:Training Dummy", dummyCache)
					GB.Log.log("RESOLVE", "Training Dummy -> " .. c:GetFullName())
					return c
				end
			end
		end

		dummyMiss = dummyMiss + 1
		local now = os.clock()
		local mk = "miss:Training Dummy"
		if not missLog[mk] or now - missLog[mk] > 8 then
			missLog[mk] = now
			GB.Log.warn("ERROR", "resolve miss Training Dummy")
		end
		return nil
	end

	local function islandOf(inst)
		if not inst then
			return nil
		end
		local p = inst
		while p and p ~= workspace do
			local n = p.Name
			if n == "Anchor Town" or n == "Clown Town" or n == "Maple Village" then
				return n
			end
			p = p.Parent
		end
		local pos = M.positionOf(inst)
		if pos and GB.World and GB.World.GetIslandFromPosition then
			return GB.World.GetIslandFromPosition(pos)
		end
		return nil
	end

	function M.pack(inst, request)
		local root = climbRoot(inst) or inst
		return {
			Instance = root,
			Root = root,
			Position = M.positionOf(root),
			DisplayName = M.displayName(root),
			InternalName = root.Name,
			Interaction = root:GetAttribute("Interaction"),
			Island = islandOf(root),
			Request = request,
		}
	end

	local function npcRoots()
		local roots, seen = {}, {}
		local function add(inst)
			if inst and not seen[inst] then
				seen[inst] = true
				roots[#roots + 1] = inst
			end
		end
		local aa = workspace:FindFirstChild("AA IMPORTANT")
		if aa then
			add(aa:FindFirstChild("DialogueNPCs"))
			add(aa:FindFirstChild("Markers"))
			add(aa:FindFirstChild("NPCAreas"))
			add(aa:FindFirstChild("PointsOfInterest"))
		end
		add(workspace:FindFirstChild("DialogueNPCs"))
		add(workspace:FindFirstChild("Entities"))
		add(workspace:FindFirstChild("Islands"))
		return roots
	end

	function M.baseName(s)
		if type(s) ~= "string" then
			return ""
		end
		return (string.gsub(s, " %d+$", ""))
	end

	function M.isCorruptOfficer(inst)
		if not inst then
			return false
		end
		if inst:HasTag("Corrupt Swordsman Officer") or inst:HasTag("Corrupt Sniper Officer") then
			return true
		end
		for _, s in ipairs({ inst:GetAttribute("NPCName"), inst.Name, M.displayName(inst) }) do
			if type(s) == "string" and string.find(s, "Officer", 1, true) and string.find(s, "Corrupt", 1, true) then
				return true
			end
		end
		return false
	end

	function M.nameMatches(inst, names)
		if not (inst and type(names) == "table") then
			return false
		end
		local nm = inst.Name
		local disp = M.displayName(inst)
		local npc = inst:GetAttribute("NPCName")
		local bases = { M.baseName(nm), M.baseName(disp or ""), M.baseName(type(npc) == "string" and npc or "") }
		for _, n in ipairs(names) do
			if type(n) == "string" and n ~= "" then
				if n == "Corrupt Marine Officer" and M.isCorruptOfficer(inst) then
					return true
				end
				if nm == n or disp == n or npc == n then
					return true
				end
				local tagged
				pcall(function()
					tagged = inst:HasTag(n)
				end)
				if tagged then
					return true
				end
				for _, b in ipairs(bases) do
					if b == n then
						return true
					end
				end
				if #n > 3 and string.sub(nm, 1, #n) == n then
					local ch = string.sub(nm, #n + 1, #n + 1)
					if ch == "" or ch == " " then
						return true
					end
				end
			end
		end
		return false
	end

	local function nameHit(inst, names)
		return M.nameMatches(inst, names)
	end

	local function dialogueNameHit(inst, names)
		local cfg = inst:FindFirstChild("Dialogue")
		if not (cfg and cfg:IsA("Configuration")) then
			return false
		end
		local qn = cfg:FindFirstChild("QuestName2") or cfg:FindFirstChild("QuestName")
		if qn then
			local v = qn:FindFirstChild("QuestName")
			local val = v and v.Value
			-- quest-name node is evidence the model is a quest NPC, not a name match
			if type(val) == "string" then
				for _, n in ipairs(names) do
					if val == n then
						return true
					end
				end
			end
		end
		return false
	end

	local function firstWorldTagged(tag)
		local ok, tagged = pcall(CS.GetTagged, CS, tag)
		if not ok or type(tagged) ~= "table" then
			return nil
		end
		for _, t in ipairs(tagged) do
			if usable(t, "npc") then
				return climbRoot(t)
			end
		end
		return nil
	end

	local function scanRoots(pred, limit)
		local t0 = pbegin()
		limit = limit or 8
		perfCount("ResolverDeepScan", 1)
		local hits = {}
		for _, root in ipairs(npcRoots()) do
			if pred(root) then
				hits[#hits + 1] = root
				if #hits >= limit then
					pdone("Resolver deep scan", t0)
					return hits
				end
			end
			for _, d in ipairs(root:GetDescendants()) do
				if pred(d) then
					hits[#hits + 1] = d
					if #hits >= limit then
						pdone("Resolver deep scan", t0)
						return hits
					end
				end
			end
		end
		pdone("Resolver deep scan", t0)
		return hits
	end

	local function scoreInst(inst, names, opts)
		local s = 0
		local nm = inst.Name
		local disp = M.displayName(inst)
		for i, n in ipairs(names) do
			local w = (#names - i + 1)
			if nm == n then
				s = s + 50 + w
			end
			if disp == n then
				s = s + 45 + w
			end
			if inst:HasTag(n) then
				s = s + 40 + w
			end
			if inst:GetAttribute("NPCName") == n then
				s = s + 42 + w
			end
		end
		if isDialogue(inst) then
			s = s + 8
		end
		local parent = inst.Parent
		if parent and parent.Parent and parent.Parent.Name == "DialogueNPCs" then
			s = s + 12
		end
		if opts and opts.Island and islandOf(inst) == opts.Island then
			s = s + 6
		end
		if inRS(inst) then
			s = s - 200
		end
		return s
	end

	function M.dumpNearby(request, opts)
		local t0 = pbegin()
		opts = opts or {}
		local names = M.namesFor(request, opts)
		local origin
		local hrp = GB.World and GB.World.hrp and GB.World.hrp()
		if hrp then
			origin = hrp.Position
		end
		local cand = {}
		perfCount("ResolverDeepScan", 1)
		for _, root in ipairs(npcRoots()) do
			for _, d in ipairs(root:GetDescendants()) do
				if d:IsA("Model") and not inRS(d) then
					local disp = M.displayName(d)
					local low = string.lower(d.Name .. " " .. tostring(disp or ""))
					local want = false
					for _, n in ipairs(names) do
						if string.find(low, string.lower(n), 1, true) then
							want = true
							break
						end
					end
					if not want and (isDialogue(d) or d:FindFirstChildOfClass("Humanoid")) then
						local pos = M.positionOf(d)
						if origin and pos and (pos - origin).Magnitude < 90 then
							want = true
						end
					end
					if want then
						local pos = M.positionOf(d)
						local dist = (origin and pos) and math.floor((pos - origin).Magnitude) or -1
						cand[#cand + 1] = {
							Name = d.Name,
							ClassName = d.ClassName,
							DisplayName = disp,
							Parent = d.Parent and d.Parent.Name,
							Position = pos,
							Dist = dist,
							Score = scoreInst(d, names, opts),
						}
					end
				end
			end
		end
		table.sort(cand, function(a, b)
			if a.Score ~= b.Score then
				return a.Score > b.Score
			end
			local da = a.Dist >= 0 and a.Dist or 1e9
			local db = b.Dist >= 0 and b.Dist or 1e9
			return da < db
		end)
		local n = math.min(#cand, 8)
		local bits = {}
		for i = 1, n do
			local c = cand[i]
			bits[i] = string.format(
				"%s [%s] disp=%s parent=%s d=%s",
				c.Name,
				c.ClassName,
				tostring(c.DisplayName),
				tostring(c.Parent),
				tostring(c.Dist)
			)
		end
		GB.Log.warn(
			"RESOLVE",
			string.format("miss '%s' nearby=%d %s", tostring(request), #cand, table.concat(bits, " | "))
		)
		M.lastCandidates = {}
		for i = 1, n do
			local c = cand[i]
			M.lastCandidates[i] = {
				Name = c.Name,
				DisplayName = c.DisplayName,
				Parent = c.Parent,
				Dist = c.Dist,
			}
		end
		pdone("Resolver deep scan", t0)
		return cand
	end

	function M.resolve(request, opts)
		local t0 = pbegin()
		opts = opts or {}
		if type(request) ~= "string" or request == "" or request == "\\" then
			pdone("Resolver.resolve", t0)
			return nil
		end
		local kind0 = opts.ExpectedRole or opts.kind or "npc"
		if (kind0 == "enemy" or kind0 == "any") and M.isDummyName(request) then
			local d = M.dummy()
			local out = d and M.pack(d, request)
			pdone("Resolver.resolve", t0)
			return out
		end
		local names = M.namesFor(request, opts)
		local kind = opts.ExpectedRole or opts.kind or "npc"
		local cacheKey = "res:" .. kind .. ":" .. table.concat(names, "|")
		local hit = GB.Cache.get(cacheKey, opts.deep and 0.4 or 2.0)
		if hit and hit.Parent and usable(hit, kind) then
			local out = M.pack(hit, request)
			pdone("Resolver.resolve", t0)
			return out
		end
		if not opts.deep and negativeHit(cacheKey) then
			pdone("Resolver.resolve", t0)
			return nil
		end

		local best, bestS
		local function consider(inst)
			if not usable(inst, kind) then
				return
			end
			local root = climbRoot(inst)
			if not root then
				return
			end
			if not (nameHit(root, names) or dialogueNameHit(root, names)) then
				return
			end
			local s = scoreInst(root, names, opts)
			if not bestS or s > bestS then
				best, bestS = root, s
			end
		end

		for _, n in ipairs(names) do
			local tagged = firstWorldTagged(n)
			if tagged then
				consider(tagged)
			end
		end

		local ents = workspace:FindFirstChild("Entities")
		if ents then
			for _, n in ipairs(names) do
				local c = ents:FindFirstChild(n)
				if c then
					consider(c)
				end
			end
		end

		local aa = workspace:FindFirstChild("AA IMPORTANT")
		local dlg = (aa and aa:FindFirstChild("DialogueNPCs")) or workspace:FindFirstChild("DialogueNPCs")
		if dlg then
			if opts.Island then
				local folder = dlg:FindFirstChild(opts.Island)
				if folder then
					for _, c in ipairs(folder:GetChildren()) do
						consider(c)
					end
				end
			end
			for _, islandFolder in ipairs(dlg:GetChildren()) do
				for _, c in ipairs(islandFolder:GetChildren()) do
					consider(c)
				end
			end
		end

		if not best or opts.deep then
			scanRoots(function(d)
				if d:IsA("Model") or d:IsA("Folder") or d:IsA("BasePart") then
					consider(d)
				end
				return false
			end, 1)
		end

		if best then
			GB.Cache.set(cacheKey, best)
			negativeCache[cacheKey] = nil
			local pack = M.pack(best, request)
			GB.Log.log("RESOLVE", string.format("%s -> %s", request, best:GetFullName()))
			pdone("Resolver.resolve", t0)
			return pack
		end

		local now = os.clock()
		local mk = "miss:" .. request
		if not missLog[mk] or now - missLog[mk] > 8 then
			missLog[mk] = now
			GB.Log.warn("ERROR", "resolve miss " .. table.concat(names, " / "))
		end
		noteNegative(cacheKey, opts.negTTL or NEG_TTL)
		pdone("Resolver.resolve", t0)
		return nil
	end

	local function followPath(path)
		if type(path) ~= "table" then
			return nil
		end
		local cur = workspace
		for _, step in ipairs(path) do
			if not (cur and type(step) == "string") then
				return nil
			end
			cur = cur:FindFirstChild(step)
		end
		return cur
	end

	local function hasAnyTag(inst, tags)
		if not (inst and type(tags) == "table") then
			return false
		end
		for _, tag in ipairs(tags) do
			local ok, hit = pcall(function()
				return inst:HasTag(tag)
			end)
			if ok and hit then
				return true
			end
		end
		return false
	end

	function M.resolveObject(name, opts)
		opts = opts or {}
		local spec = GB.QuestData and GB.QuestData.objectSpec and GB.QuestData.objectSpec(name) or nil
		if not spec then
			return M.resolve(name, {
				kind = "any",
				ExpectedRole = "any",
				Island = opts.Island,
				deep = opts.deep,
			})
		end
		local hit = followPath(spec.Path)
		if hit then
			local root = climbRoot(hit) or hit
			if (not spec.Island) or islandOf(root) == spec.Island then
				return M.pack(root, name)
			end
		end
		if type(spec.Tags) == "table" then
			for _, tag in ipairs(spec.Tags) do
				local tagged = firstWorldTagged(tag)
				if tagged then
					local root = climbRoot(tagged) or tagged
					if (not spec.Island) or islandOf(root) == spec.Island then
						return M.pack(root, name)
					end
				end
			end
		end
		local pack = M.resolve(name, {
			kind = "any",
			ExpectedRole = "any",
			Island = spec.Island or opts.Island,
			deep = opts.deep,
		})
		if pack and hasAnyTag(pack.Instance, spec.Tags) then
			return pack
		end
		return pack
	end

	function M.byName(name, kind)
		local pack = M.resolve(name, { kind = kind or "any", ExpectedRole = kind })
		return pack and pack.Instance
	end

	function M.npc(name, opts)
		opts = opts or {}
		opts.ExpectedRole = opts.ExpectedRole or "npc"
		opts.kind = "npc"
		local pack = M.resolve(name, opts)
		return pack and pack.Instance
	end

	function M.resolveNPC(name, opts)
		opts = opts or {}
		opts.ExpectedRole = opts.ExpectedRole or "npc"
		opts.kind = "npc"
		return M.resolve(name, opts)
	end

	local _resolveObjectRaw = M.resolveObject
	function M.resolveObject(name, opts)
		local t0 = pbegin()
		local out = { pcall(_resolveObjectRaw, name, opts) }
		pdone("Resolver.resolveObject", t0)
		if not out[1] then
			error(out[2])
		end
		return unpack(out, 2)
	end

	local _resolveNPCRaw = M.resolveNPC
	function M.resolveNPC(name, opts)
		local t0 = pbegin()
		local out = { pcall(_resolveNPCRaw, name, opts) }
		pdone("Resolver.resolveNPC", t0)
		if not out[1] then
			error(out[2])
		end
		return unpack(out, 2)
	end

	function M.enemies(name)
		local out = {}
		if name == "\\" or name == "" then
			return out
		end
		if M.isDummyName(name) then
			local d = M.dummy()
			if d then
				out[1] = d
			end
			return out
		end
		local origin
		local hrp = GB.World and GB.World.hrp and GB.World.hrp()
		if hrp then
			origin = hrp.Position
		end
		local seen = {}
		local names = M.namesFor(name, {})
		local function consider(inst)
			if not usable(inst, "enemy") then
				return
			end
			local root = climbRoot(inst) or inst
			if seen[root] or M.isPet(root) then
				return
			end
			if GB.Combat and GB.Combat.isRecentlyDead and GB.Combat.isRecentlyDead(root) then
				return
			end
			if GB.Combat and GB.Combat.IsEnemyAlive and not GB.Combat.IsEnemyAlive(root) then
				return
			end
			seen[root] = true
			local pos = M.positionOf(root)
			local d = (origin and pos) and (pos - origin).Magnitude or 1e9
			out[#out + 1] = { inst = root, dist = d }
		end
		for _, n in ipairs(names) do
			local ok, tagged = pcall(CS.GetTagged, CS, n)
			if ok and type(tagged) == "table" then
				for _, inst in ipairs(tagged) do
					consider(inst)
				end
			end
		end
		local ents = workspace:FindFirstChild("Entities")
		if ents then
			for _, c in ipairs(ents:GetChildren()) do
				if nameHit(c, names) then
					consider(c)
				end
			end
		end
		if #out == 0 then
			local pack = M.resolve(name, { kind = "enemy", ExpectedRole = "enemy" })
			if pack and pack.Instance then
				consider(pack.Instance)
			end
		end
		table.sort(out, function(a, b)
			return a.dist < b.dist
		end)
		local flat = {}
		for i, row in ipairs(out) do
			flat[i] = row.inst
		end
		return flat
	end

	function M.enemy(name)
		if name == "\\" or name == "" then
			return nil
		end
		if M.isDummyName(name) then
			return M.dummy()
		end
		local list = M.enemies(name)
		local best = list[1]
		if best then
			GB.Log.log("RESOLVE", string.format("%s -> %s", name, best:GetFullName()))
			return best
		end
		return nil
	end

	function M.taggedAny(tag)
		if type(tag) ~= "string" or tag == "" then
			return nil
		end
		for _, inst in ipairs(CS:GetTagged(tag)) do
			if inst.Parent and not inRS(inst) and not M.isPet(inst) then
				return inst
			end
		end
		return nil
	end

	function M.waitTagged(tag, timeout)
		timeout = timeout or 4
		local hit = firstWorldTagged(tag)
		if hit then
			return hit
		end
		local t0 = os.clock()
		local got
		local conn = CS:GetInstanceAddedSignal(tag):Connect(function(inst)
			if usable(inst, "npc") then
				got = climbRoot(inst)
			end
		end)
		while not got and os.clock() - t0 < timeout do
			got = firstWorldTagged(tag)
			if got then
				break
			end
			task.wait(0.15)
		end
		conn:Disconnect()
		return got
	end

	function M.shopItem(name)
		name = name or ""
		local cacheKey = "shop:" .. name
		local hit = GB.Cache.get(cacheKey, 4)
		if hit and hit.Parent then
			return hit
		end
		local tagged = M.taggedAny(name)
		if tagged and (tagged:GetAttribute("Interaction") == "Shop Item" or M.prompt(tagged, "Shop Item")) then
			local root = M.interactableOf and M.interactableOf(tagged) or tagged
			GB.Cache.set(cacheKey, root)
			return root
		end
		local function isShop(d)
			if d:IsA("ProximityPrompt") and d.Name == "Shop Item" then
				local p = d.Parent
				local item = p and (p:GetAttribute("Item") or p.Name)
				local climb = M.interactableOf and M.interactableOf(d)
				return item == name or (p and p.Name == name) or (climb and climb.Name == name)
			end
			if d:GetAttribute("Interaction") == "Shop Item" then
				return (d:GetAttribute("Item") or d.Name) == name
			end
			return false
		end
		local found = scanRoots(isShop, 6)
		if found[1] then
			local part = found[1]
			if part:IsA("ProximityPrompt") then
				part = (M.interactableOf and M.interactableOf(part)) or part.Parent
			end
			GB.Cache.set(cacheKey, part)
			return part
		end
		return M.byName(name, "shop")
	end

	function M.island(name)
		local isles = workspace:FindFirstChild("Islands")
		return isles and isles:FindFirstChild(name)
	end

	function M.dialogueConfig(model)
		if not model then
			return nil
		end
		local cfg = model:FindFirstChildWhichIsA("Configuration")
		if cfg then
			return cfg
		end
		perfCount("ResolverDeepScan", 1)
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("Configuration") then
				return d
			end
		end
		return nil
	end

	function M.prompt(model, interaction)
		if not model then
			return nil
		end
		perfCount("ResolverDeepScan", 1)
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("ProximityPrompt") then
				if not interaction or d.Name == interaction or d:GetAttribute("Interaction") == interaction then
					return d
				end
			end
		end
		return nil
	end

	function M.interactableOf(inst)
		local cur = inst
		while cur do
			if cur:HasTag("Interactable") or cur:HasTag("ClientInteractable") then
				return cur
			end
			cur = cur.Parent
		end
		return inst
	end

	function M.promptAnchor(inst)
		if not inst then
			return nil, nil
		end
		local pr = inst:IsA("ProximityPrompt") and inst or M.prompt(inst)
		if pr then
			local p = pr.Parent
			if p and p:IsA("Attachment") then
				return p.WorldPosition, p.WorldCFrame.LookVector, pr
			end
			if p and p:IsA("BasePart") then
				return p.Position, p.CFrame.LookVector, pr
			end
		end
		local hrp = inst:FindFirstChild("HumanoidRootPart", true)
		if hrp and hrp:IsA("Attachment") then
			return hrp.WorldPosition, hrp.WorldCFrame.LookVector, pr
		end
		if hrp and hrp:IsA("BasePart") then
			return hrp.Position, hrp.CFrame.LookVector, pr
		end
		return M.positionOf(inst), nil, pr
	end

	function M.ore()
		return M.byName("Copper Ore", "ore")
			or M.byName("Iron Ore", "ore")
			or M.byName("Lead Ore", "ore")
	end

	local function chestOpened(inst)
		return inst and inst:GetAttribute("Opened") == true
	end

	function M.chests()
		local out = {}
		local seen = {}
		local function add(inst)
			if not inst or seen[inst] or inRS(inst) or not inst.Parent then
				return
			end
			if chestOpened(inst) then
				return
			end
			seen[inst] = true
			out[#out + 1] = inst
		end
		for i = 1, 8 do
			local tagged
			pcall(function()
				tagged = CS:GetTagged("Afuaru's Chest " .. i)
			end)
			if tagged then
				for _, t in ipairs(tagged) do
					add(t)
				end
			end
		end
		local folder = workspace:FindFirstChild("Afuaru's Chests")
		if folder then
			for _, c in ipairs(folder:GetChildren()) do
				add(c)
			end
		end
		local interact
		pcall(function()
			interact = CS:GetTagged("ClientInteractable")
		end)
		if interact then
			for _, t in ipairs(interact) do
				local n = t.Name
				if string.find(n, "Afuaru", 1, true) and string.find(n, "Chest", 1, true) then
					add(t)
				end
			end
		end
		return out
	end

	function M.chest()
		local list = M.chests()
		if list[1] then
			return list[1]
		end
		return M.byName("Afuaru's Chests", "chest")
	end

	local function watchInvalidate(root)
		if not (root and root.Parent) then
			return
		end
		GB.conns[#GB.conns + 1] = root.ChildAdded:Connect(function()
			clearNegative()
		end)
		GB.conns[#GB.conns + 1] = root.ChildRemoved:Connect(function()
			clearNegative()
		end)
	end

	local function hookNegativeInvalidation()
		watchInvalidate(workspace:FindFirstChild("Entities"))
		watchInvalidate(workspace:FindFirstChild("Islands"))
		local aa = workspace:FindFirstChild("AA IMPORTANT")
		if aa then
			watchInvalidate(aa)
			watchInvalidate(aa:FindFirstChild("DialogueNPCs"))
		end
		GB.conns[#GB.conns + 1] = workspace.ChildAdded:Connect(function(ch)
			if ch.Name == "Entities" or ch.Name == "Islands" or ch.Name == "AA IMPORTANT" then
				clearNegative()
				watchInvalidate(ch)
				if ch.Name == "AA IMPORTANT" then
					watchInvalidate(ch:FindFirstChild("DialogueNPCs"))
				end
			end
		end)
	end

	hookNegativeInvalidation()

	return M
end
]],
    ["Game/World.lua"] = [[-- Islands, move, destOk, floorAt, tweenTo. Combat does not snap to roofs.

return function(GB)
	local TweenService = game:GetService("TweenService")
	local M = {
		lastSafe = nil,
		anchorSafe = nil,
		_tween = nil,
		_tweenDest = nil,
	}

	local ISLANDS = { "Anchor Town", "Clown Town", "Maple Village" }

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

	function M.char()
		return GB.lp and GB.lp.Character
	end

	function M.hrp()
		local c = M.char()
		if not c then
			return nil
		end
		local hrp = c:FindFirstChild("HumanoidRootPart")
		if hrp then
			return hrp
		end
		if c:IsA("Model") then
			return c.PrimaryPart
		end
		return nil
	end

	function M.hum()
		local c = M.char()
		return c and c:FindFirstChildOfClass("Humanoid")
	end

	function M.waterY()
		return workspace.FallenPartsDestroyHeight and math.max(workspace.FallenPartsDestroyHeight + 20, 0) or 0
	end

	function M.destOk(pos)
		if typeof(pos) ~= "Vector3" then
			return false
		end
		local y = pos.Y
		local yMin = math.max(GB.Config.DestYMin or 0, M.waterY() + 2)
		if y < yMin or y > (GB.Config.DestYMax or 180) then
			return false
		end
		return true
	end

	function M.groundAt(pos)
		if typeof(pos) ~= "Vector3" then
			return nil
		end
		local origin = Vector3.new(pos.X, pos.Y + 40, pos.Z)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local c = M.char()
		params.FilterDescendantsInstances = c and { c } or {}
		local hit = workspace:Raycast(origin, Vector3.new(0, -220, 0), params)
		if not hit then
			return nil
		end
		if hit.Material == Enum.Material.Water then
			return nil
		end
		if hit.Instance and string.find(string.lower(hit.Instance.Name), "water", 1, true) then
			return nil
		end
		local p = hit.Position + Vector3.new(0, 4, 0)
		if not M.destOk(p) then
			return nil
		end
		return p
	end

	-- Floor under the target. groundAt(+40) hits roofs first when the mob is indoors.
	function M.floorAt(pos, preferY)
		if typeof(pos) ~= "Vector3" then
			return nil
		end
		preferY = tonumber(preferY) or pos.Y
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local c = M.char()
		params.FilterDescendantsInstances = c and { c } or {}
		for _, lift in ipairs({ 2.4, 5, 9 }) do
			local origin = Vector3.new(pos.X, preferY + lift, pos.Z)
			local hit = workspace:Raycast(origin, Vector3.new(0, -(lift + 10), 0), params)
			if hit and hit.Material ~= Enum.Material.Water then
				if not (hit.Instance and string.find(string.lower(hit.Instance.Name), "water", 1, true)) then
					local p = hit.Position + Vector3.new(0, 3, 0)
					if p.Y <= preferY + 3.5 and M.destOk(p) then
						return p
					end
				end
			end
		end
		local flat = Vector3.new(pos.X, preferY, pos.Z)
		if M.destOk(flat) then
			return flat
		end
		return nil
	end

	function M.cancelTween()
		if M._tween then
			pcall(function()
				M._tween:Cancel()
			end)
			M._tween = nil
			M._tweenDest = nil
		end
	end

	function M.tweenPlaying()
		local tw = M._tween
		if not tw then
			return false
		end
		local ok, st = pcall(function()
			return tw.PlaybackState
		end)
		return ok and st == Enum.PlaybackState.Playing
	end

	function M.tweenTo(pos, lookAt, opts)
		opts = opts or {}
		local root = M.hrp()
		if not (root and typeof(pos) == "Vector3") then
			return false
		end
		if not M.destOk(pos) then
			return false
		end
		local range = tonumber(opts.range) or 3.5
		local here = root.Position
		local dist = (here - pos).Magnitude
		local function face()
			if typeof(lookAt) == "Vector3" then
				root.CFrame = CFrame.new(root.Position, Vector3.new(lookAt.X, root.Position.Y, lookAt.Z))
			end
		end
		if dist <= range then
			face()
			return true
		end
		if M.tweenPlaying() and M._tweenDest and (M._tweenDest - pos).Magnitude < 2.4 then
			return (root.Position - pos).Magnitude <= range + 3
		end
		M.cancelTween()
		local speed = tonumber(GB.Config.TweenSpeed) or 95
		local maxDur = tonumber(opts.maxDur) or tonumber(GB.Config.TweenMaxDur) or 1.8
		local dur = math.clamp(dist / math.max(speed, 20), 0.08, maxDur)
		local goal = typeof(lookAt) == "Vector3" and CFrame.new(pos, Vector3.new(lookAt.X, pos.Y, lookAt.Z))
			or CFrame.new(pos)
		pcall(function()
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end)
		local tw = TweenService:Create(
			root,
			TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CFrame = goal }
		)
		M._tween = tw
		M._tweenDest = pos
		tw:Play()
		if opts.wait == false then
			return (root.Position - pos).Magnitude <= range + 6
		end
		local t0 = os.clock()
		while os.clock() - t0 < dur + 0.06 do
			if not root.Parent then
				break
			end
			if (root.Position - pos).Magnitude <= range then
				break
			end
			task.wait()
		end
		if tw.PlaybackState == Enum.PlaybackState.Playing then
			pcall(function()
				tw:Cancel()
			end)
		end
		if M._tween == tw then
			M._tween = nil
			M._tweenDest = nil
		end
		face()
		M.rememberSafe()
		return (root.Position - pos).Magnitude <= range + 3
	end

	function M.rememberSafe()
		local root = M.hrp()
		if not root then
			return
		end
		local y = root.Position.Y
		if y > M.waterY() + 10 and y < 250 and M.destOk(root.Position) then
			M.lastSafe = root.CFrame
		end
	end

	function M.ensureAnchorSafe()
		if M.anchorSafe then
			return
		end
		local g = GB.Resolver.npc("Officer Graves") or GB.Resolver.npc("Officer Graves [2]")
		local pos = g and GB.Resolver.positionOf(g)
		if pos then
			M.anchorSafe = CFrame.new(pos + Vector3.new(0, 0, 6))
		end
	end

	function M.rescue()
		local root = M.hrp()
		if not root then
			return
		end
		local y = root.Position.Y
		local wet = y < M.waterY() + 4 or y > 240
		if not wet then
			M.rememberSafe()
			return
		end
		M.ensureAnchorSafe()
		local dest = M.lastSafe or M.anchorSafe
		if not dest then
			return
		end
		if GB.Combat then
			pcall(GB.Combat.stopLock)
		end
		M.cancelTween()
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = dest
		GB.Log.warn("TRAVEL", "rescue swim/void")
	end

	function M.goSafe()
		M.ensureAnchorSafe()
		local root = M.hrp()
		local dest = M.lastSafe or M.anchorSafe
		if root and dest then
			M.cancelTween()
			root.CFrame = dest
		end
	end

	function M.waitUnpause()
		local t = os.clock()
		while GB.lp and GB.lp:GetAttribute("GameplayPaused") and os.clock() - t < 12 do
			if GB.State and GB.State.dismissTutorialOverlay then
				GB.State.dismissTutorialOverlay()
			end
			task.wait(0.2)
		end
	end

	function M.setPos(cf, opts)
		opts = opts or {}
		local root = M.hrp()
		if not root then
			return false
		end
		local pos = typeof(cf) == "CFrame" and cf.Position or cf
		if not M.destOk(pos) then
			return false
		end
		local g = M.groundAt(pos)
		if g and opts.MaxGroundY and g.Y > opts.MaxGroundY then
			g = nil
		end
		if g then
			root.CFrame = CFrame.new(g)
		else
			root.CFrame = typeof(cf) == "CFrame" and cf or CFrame.new(pos)
		end
		M.rememberSafe()
		return true
	end

	function M.moveTo(instOrPos, range)
		range = range or 6
		local root = M.hrp()
		local hum = M.hum()
		if not root then
			return false
		end
		local pos
		if typeof(instOrPos) == "Vector3" then
			pos = instOrPos
		elseif typeof(instOrPos) == "CFrame" then
			pos = instOrPos.Position
		else
			pos = GB.Resolver.positionOf(instOrPos)
		end
		if not pos then
			return false
		end
		if not M.destOk(pos) then
			local g = M.groundAt(pos)
			if not g then
				return false
			end
			pos = g
		end
		local dist = (root.Position - pos).Magnitude
		if dist <= range then
			return true
		end
		M.waitUnpause()
		if dist > 220 then
			local hop = GB.Config.MoveHop or 45
			local dir = (pos - root.Position)
			dir = Vector3.new(dir.X, 0, dir.Z)
			if dir.Magnitude < 1 then
				return M.setPos(pos)
			end
			local step = root.Position + dir.Unit * math.min(hop, dist - range)
			step = Vector3.new(step.X, pos.Y, step.Z)
			M.setPos(step)
			return (root.Position - pos).Magnitude <= range
		end
		local dest = M.floorAt(pos, pos.Y) or pos
		if dist > 16 then
			return M.tweenTo(dest, pos, { wait = true, range = range })
		end
		if hum then
			hum:MoveTo(dest)
		end
		return (root.Position - dest).Magnitude <= range + 4
	end

	local geoCache = {}
	local geoLogged = {}

	local function isPart(inst)
		return inst and inst:IsA("BasePart")
	end

	local function isModel(inst)
		return inst and inst:IsA("Model")
	end

	local function modelPivot(inst)
		if not isModel(inst) then
			return nil
		end
		local ok, cf = pcall(inst.GetPivot, inst)
		if ok and typeof(cf) == "CFrame" then
			return cf
		end
		return nil
	end

	local function modelBoundingBox(inst)
		if not isModel(inst) then
			return nil
		end
		local ok, cf, size = pcall(inst.GetBoundingBox, inst)
		if ok and typeof(cf) == "CFrame" and typeof(size) == "Vector3" then
			return cf, size
		end
		return nil
	end

	local function instancePosition(inst)
		if not inst then
			return nil
		end
		if isPart(inst) then
			return inst.Position
		end
		if isModel(inst) then
			local pp = inst.PrimaryPart
			if pp then
				return pp.Position
			end
			local pivot = modelPivot(inst)
			if pivot then
				return pivot.Position
			end
		end
		return nil
	end

	local function resolveIslandInst(island)
		if typeof(island) == "Instance" then
			return island
		end
		if type(island) ~= "string" or island == "" then
			return nil
		end
		if GB.Resolver and GB.Resolver.island then
			return GB.Resolver.island(island)
		end
		local isles = workspace:FindFirstChild("Islands")
		return isles and isles:FindFirstChild(island)
	end

	local function aabbFromCenterSize(center, size)
		local h = size * 0.5
		return center - h, center + h
	end

	local function aabbFromRadius(center, radius)
		local r = Vector3.new(radius, math.max(radius * 0.35, 120), radius)
		return center - r, center + r
	end

	local function aabbContains(minV, maxV, pos, pad)
		pad = pad or 0
		return pos.X >= minV.X - pad
			and pos.X <= maxV.X + pad
			and pos.Y >= minV.Y - pad
			and pos.Y <= maxV.Y + pad
			and pos.Z >= minV.Z - pad
			and pos.Z <= maxV.Z + pad
	end

	local function median(t)
		local n = #t
		if n == 0 then
			return 0
		end
		table.sort(t)
		if n % 2 == 1 then
			return t[(n + 1) / 2]
		end
		return (t[n / 2] + t[n / 2 + 1]) / 2
	end

	local function harvestIslandFolder(folder)
		local samples = {}
		for _, c in ipairs(folder:GetChildren()) do
			if isPart(c) then
				local vol = math.abs(c.Size.X * c.Size.Y * c.Size.Z)
				if vol >= 200 then
					samples[#samples + 1] = { pos = c.Position, size = c.Size }
				end
			elseif isModel(c) then
				local cf, size = modelBoundingBox(c)
				if cf and size then
					local vol = math.abs(size.X * size.Y * size.Z)
					if vol >= 200 then
						samples[#samples + 1] = { pos = cf.Position, size = size }
					end
				end
			end
		end
		return samples
	end

	local function samplesToGeo(samples)
		if #samples == 0 then
			return nil
		end
		local xs, ys, zs = {}, {}, {}
		for i, s in ipairs(samples) do
			xs[i], ys[i], zs[i] = s.pos.X, s.pos.Y, s.pos.Z
		end
		local mid = Vector3.new(median(xs), median(ys), median(zs))
		local used = {}
		for _, s in ipairs(samples) do
			local dx = s.pos.X - mid.X
			local dz = s.pos.Z - mid.Z
			if math.sqrt(dx * dx + dz * dz) < 900 then
				used[#used + 1] = s
			end
		end
		if #used < 3 then
			used = samples
		end
		local minV, maxV
		local sx, sy, sz, n = 0, 0, 0, 0
		for _, s in ipairs(used) do
			local p = s.pos
			sx, sy, sz, n = sx + p.X, sy + p.Y, sz + p.Z, n + 1
			local half = s.size and (s.size * 0.5) or Vector3.new(4, 4, 4)
			local a, b = p - half, p + half
			if not minV then
				minV, maxV = a, b
			else
				minV = Vector3.new(math.min(minV.X, a.X), math.min(minV.Y, a.Y), math.min(minV.Z, a.Z))
				maxV = Vector3.new(math.max(maxV.X, b.X), math.max(maxV.Y, b.Y), math.max(maxV.Z, b.Z))
			end
		end
		return Vector3.new(sx / n, sy / n, sz / n), minV, maxV, n
	end

	local function countParts(inst)
		local n = 0
		if not inst then
			return 0
		end
		perfCount("WorkspaceDeepScan", 1)
		for _, d in ipairs(inst:GetDescendants()) do
			if isPart(d) then
				n = n + 1
			end
		end
		return n
	end

	local function usablePos(pos)
		if typeof(pos) ~= "Vector3" then
			return nil
		end
		if M.destOk(pos) then
			return pos
		end
		local ymin = (GB.Config and GB.Config.DestYMin) or 8
		local ymax = (GB.Config and GB.Config.DestYMax) or 180
		local y = pos.Y
		if y < ymin then
			y = ymin + 4
		elseif y > ymax then
			y = ymax
		end
		return Vector3.new(pos.X, y, pos.Z)
	end

	local function computeGeo(island)
		local islandChild = island:FindFirstChild("Island")
		local islandKids = islandChild and #islandChild:GetChildren() or 0

		if isPart(island) then
			local minV, maxV = aabbFromCenterSize(island.Position, island.Size)
			return {
				pos = island.Position,
				min = minV,
				max = maxV,
				center = island.Position,
				method = "BasePart",
				parts = 1,
				islandKids = islandKids,
			}
		end

		if isModel(island) then
			local pos = instancePosition(island)
			local cf, size = modelBoundingBox(island)
			if cf and size then
				local minV, maxV = aabbFromCenterSize(cf.Position, size)
				local method = "Model.GetBoundingBox"
				if island.PrimaryPart then
					method = "Model.PrimaryPart"
				end
				return {
					pos = pos or cf.Position,
					min = minV,
					max = maxV,
					center = cf.Position,
					method = method,
					parts = 1,
					islandKids = islandKids,
				}
			end
			if pos then
				local pad = Vector3.new(80, 80, 80)
				return {
					pos = pos,
					min = pos - pad,
					max = pos + pad,
					center = pos,
					method = "Model.GetPivot",
					parts = 1,
					islandKids = islandKids,
				}
			end
		end

		local spawn
		local spawnRoot = island:FindFirstChild("SpawnLocations")
		if spawnRoot then
			perfCount("WorkspaceDeepScan", 1)
			for _, d in ipairs(spawnRoot:GetDescendants()) do
				if d:IsA("SpawnLocation") or isPart(d) then
					spawn = d
					break
				end
			end
		end
		if not spawn then
			for _, c in ipairs(island:GetChildren()) do
				if c:IsA("SpawnLocation") or (c.Name == "Spawn" and isPart(c)) then
					spawn = c
					break
				end
			end
		end

		local paPos, paRadius
		local pa = island:FindFirstChild("PersistentAnchor")
		if pa then
			local center = pa:FindFirstChild("Center")
			if isPart(center) then
				paPos = center.Position
			elseif isModel(pa) then
				paPos = instancePosition(pa)
			elseif isPart(pa) then
				paPos = pa.Position
			end
			local r = pa:FindFirstChild("Radius")
			if r and r:IsA("ValueBase") then
				paRadius = tonumber(r.Value)
			end
		end

		local persPos, persSize
		local cons = island:FindFirstChild("Constants")
		local pers = cons and cons:FindFirstChild("Persistent")
		if pers then
			if isModel(pers) then
				local cf, size = modelBoundingBox(pers)
				if cf then
					persPos, persSize = cf.Position, size
				else
					persPos = instancePosition(pers)
				end
			elseif isPart(pers) then
				persPos, persSize = pers.Position, pers.Size
			end
		end

		local samplePos, sampleMin, sampleMax, sampleN
		if islandChild then
			if isPart(islandChild) then
				samplePos = islandChild.Position
				sampleMin, sampleMax = aabbFromCenterSize(islandChild.Position, islandChild.Size)
				sampleN = 1
			elseif isModel(islandChild) then
				local cf, size = modelBoundingBox(islandChild)
				samplePos = instancePosition(islandChild) or (cf and cf.Position)
				if cf and size then
					sampleMin, sampleMax = aabbFromCenterSize(cf.Position, size)
					sampleN = 1
				end
			else
				local samples = harvestIslandFolder(islandChild)
				if #samples > 0 then
					samplePos, sampleMin, sampleMax, sampleN = samplesToGeo(samples)
				end
			end
		end

		local namedPos
		for _, key in ipairs({ "Main", "Ground", "Dock", "Teleport" }) do
			local n = island:FindFirstChild(key)
			if not n and islandChild then
				n = islandChild:FindFirstChild(key)
			end
			if n then
				namedPos = instancePosition(n)
				if namedPos then
					break
				end
			end
		end

		local method, pos, minV, maxV, center, radius
		if spawn then
			pos = instancePosition(spawn)
			method = "SpawnLocation"
		end
		if paPos then
			if not pos then
				pos = paPos
				method = "PersistentAnchor.Center"
			end
			center = paPos
			radius = paRadius
			if paRadius then
				minV, maxV = aabbFromRadius(paPos, paRadius)
			end
		end
		-- Game-authored Persistent volume beats a thin streamed Island cluster.
		if not minV and persPos and persSize then
			minV, maxV = aabbFromCenterSize(persPos, persSize)
			if not pos then
				pos = persPos
				method = "Constants.Persistent"
			end
		end
		if not minV and sampleMin then
			minV, maxV = sampleMin, sampleMax
			if not pos then
				pos = samplePos
				method = "IslandBounds"
			end
		elseif not pos and persPos then
			pos = persPos
			method = "Constants.Persistent"
			if not minV then
				local pad = Vector3.new(200, 80, 200)
				minV, maxV = persPos - pad, persPos + pad
			end
		end
		if not pos and namedPos then
			pos = namedPos
			method = "NamedMarker"
		end
		if not pos and samplePos then
			pos = samplePos
			method = "IslandBounds"
		end

		if not pos then
			return {
				failed = true,
				parts = countParts(island),
				islandKids = islandKids,
			}
		end
		if not minV then
			local pad = Vector3.new(120, 80, 120)
			minV, maxV = pos - pad, pos + pad
		end
		return {
			pos = pos,
			min = minV,
			max = maxV,
			center = center or pos,
			radius = radius,
			method = method,
			parts = sampleN or 0,
			islandKids = islandKids,
		}
	end

	local function rememberGeo(island, geo)
		geoCache[island] = geo
		local name = island.Name
		if not geo or geo.failed or not geo.pos then
			if geoLogged[name] ~= "fail" and geoLogged[name] ~= "ok" then
				geoLogged[name] = "fail"
				GB.Log.warn(
					"World",
					string.format(
						"Unable to resolve island position: %s class=%s descendantParts=%s",
						name,
						island.ClassName,
						tostring(geo and geo.parts or 0)
					)
				)
			end
			return geo
		end
		if geoLogged[name] ~= "ok" then
			geoLogged[name] = "ok"
			local msg = string.format("Island resolved: %s via %s", name, tostring(geo.method))
			GB.Log.debug("World", msg)
			GB.Log.log("World", msg)
		end
		return geo
	end

	function M.getIslandGeo(island)
		island = resolveIslandInst(island)
		if not island then
			return nil
		end
		local cached = geoCache[island]
		local islandChild = island:FindFirstChild("Island")
		local kids = islandChild and #islandChild:GetChildren() or 0
		if cached and cached.islandKids == kids then
			if cached.failed then
				return nil
			end
			return cached
		end
		local geo = computeGeo(island)
		rememberGeo(island, geo)
		if not geo or geo.failed then
			return nil
		end
		return geo
	end

	function M.GetIslandPosition(island)
		local geo = M.getIslandGeo(island)
		return geo and usablePos(geo.pos) or nil
	end

	function M.GetIslandBounds(island)
		local geo = M.getIslandGeo(island)
		if not geo or not geo.min then
			return nil
		end
		return geo.min, geo.max, geo.center, geo.radius
	end

	function M.IsPositionInsideIsland(position, island)
		if typeof(position) ~= "Vector3" then
			return false
		end
		local geo = M.getIslandGeo(island)
		if not geo then
			return false
		end
		if geo.radius and geo.center then
			local dx = position.X - geo.center.X
			local dz = position.Z - geo.center.Z
			if dx * dx + dz * dz <= geo.radius * geo.radius then
				return position.Y >= geo.center.Y - 80 and position.Y <= geo.center.Y + 450
			end
			return false
		end
		if geo.min and geo.max then
			return aabbContains(geo.min, geo.max, position, 40)
		end
		return false
	end

	function M.GetIslandFromPosition(position)
		if typeof(position) ~= "Vector3" then
			return nil
		end
		local isles = workspace:FindFirstChild("Islands")
		if not isles then
			return nil
		end
		local list, seen = {}, {}
		for _, name in ipairs(ISLANDS) do
			local isl = isles:FindFirstChild(name)
			if isl then
				seen[isl] = true
				list[#list + 1] = isl
			end
		end
		for _, isl in ipairs(isles:GetChildren()) do
			if not seen[isl] then
				list[#list + 1] = isl
			end
		end
		local best, bestD
		for _, isl in ipairs(list) do
			if M.IsPositionInsideIsland(position, isl) then
				local geo = geoCache[isl]
				local c = geo and (geo.center or geo.pos)
				local d = 0
				if c then
					local dx, dz = position.X - c.X, position.Z - c.Z
					d = math.sqrt(dx * dx + dz * dz)
				end
				if not bestD or d < bestD then
					best, bestD = isl.Name, d
				end
			end
		end
		return best
	end

	function M.islandFromProgress(snap)
		snap = snap or GB.State.get()
		if not GB.PlayerData.finished("Setting Sail", true) then
			return "Anchor Town"
		end
		if not GB.PlayerData.finished("Journey to Maple Village", true) then
			return "Clown Town"
		end
		return "Maple Village"
	end

	function M.islandFromPosition(pos)
		return M.GetIslandFromPosition(pos)
	end

	function M.islandSpawn(name)
		local isl = resolveIslandInst(name)
		if not isl then
			return nil
		end
		local spawnRoot = isl:FindFirstChild("SpawnLocations") or isl:FindFirstChild("SpawnLocation")
		if spawnRoot then
			if spawnRoot:IsA("SpawnLocation") or isPart(spawnRoot) then
				return usablePos(spawnRoot.Position)
			end
			perfCount("WorkspaceDeepScan", 1)
			for _, d in ipairs(spawnRoot:GetDescendants()) do
				if d:IsA("SpawnLocation") or isPart(d) then
					return usablePos(d.Position)
				end
			end
		end
		return M.GetIslandPosition(isl)
	end

	function M.ToPosition(pos, range)
		return M.moveTo(pos, range or 6)
	end

	function M.ToInstance(inst, range)
		return M.moveTo(inst, range or 8)
	end

	function M.safeOffset(inst, dist)
		dist = dist or (GB.Config.TalkOffset or 5)
		local part = GB.Resolver.part(inst)
		if not part or not part:IsA("BasePart") then
			local pos = GB.Resolver.positionOf(inst)
			return pos and (pos + Vector3.new(0, 0, dist))
		end
		local look = part.CFrame.LookVector
		local off = Vector3.new(look.X, 0, look.Z)
		if off.Magnitude < 0.2 then
			off = Vector3.new(0, 0, 1)
		end
		return part.Position + off.Unit * dist
	end

	function M.ToNPC(resolved, range)
		local inst = type(resolved) == "table" and resolved.Instance or resolved
		if not inst then
			return false
		end
		local dest = M.safeOffset(inst, range or (GB.Config.TalkOffset or 5))
		if not dest then
			return M.moveTo(inst, range or 8)
		end
		if not M.destOk(dest) then
			local g = M.groundAt(dest)
			if g then
				dest = g
			end
		end
		GB.Log.log("TRAVEL", "Teleport -> " .. (M.displayLabel(resolved) or inst.Name))
		return M.setPos(dest)
	end

	function M.displayLabel(resolved)
		if type(resolved) == "table" then
			return resolved.DisplayName or resolved.InternalName
		end
		if typeof(resolved) == "Instance" then
			return GB.Resolver.displayName(resolved)
		end
		return nil
	end

	function M.ToEnemy(inst, range)
		if not inst then
			return false
		end
		if GB.Combat and GB.Combat.IsEnemyAlive and not GB.Combat.IsEnemyAlive(inst) then
			return false
		end
		if GB.Resolver.isPet and GB.Resolver.isPet(inst) then
			return false
		end
		range = range or (GB.Config.CombatRange or 5.5)
		local part = GB.Resolver.part(inst)
		local dest
		if part and part:IsA("BasePart") then
			local look = part.CFrame.LookVector
			local off = -Vector3.new(look.X, 0, look.Z)
			if off.Magnitude < 0.2 then
				off = Vector3.new(0, 0, range)
			else
				off = off.Unit * range
			end
			dest = part.Position + off
		else
			dest = M.safeOffset(inst, range)
		end
		if not dest then
			return M.moveTo(inst, range + 2)
		end
		local preferY = (part and part:IsA("BasePart") and part.Position.Y) or dest.Y
		dest = M.floorAt(dest, preferY) or Vector3.new(dest.X, preferY, dest.Z)
		if not M.destOk(dest) then
			return false
		end
		local root = M.hrp()
		if not root then
			return false
		end
		local look = part and part.Position or dest
		local dist = (root.Position - dest).Magnitude
		GB.Log.log("TRAVEL", "Tween -> " .. (GB.Resolver.displayName(inst) or inst.Name))
		local speed = tonumber(GB.Config.TweenSpeed) or 95
		local maxDur = tonumber(GB.Config.TweenMaxDur) or 1.8
		local maxStep = speed * maxDur
		if dist > maxStep + 10 then
			local flat = Vector3.new(dest.X - root.Position.X, 0, dest.Z - root.Position.Z)
			if flat.Magnitude > 1 then
				local mid = root.Position + flat.Unit * maxStep
				mid = M.floorAt(mid, preferY) or Vector3.new(mid.X, preferY, mid.Z)
				M.tweenTo(mid, look, { wait = true, range = 3 })
			end
		end
		return M.tweenTo(dest, look, { wait = true, range = range + 1.2 })
	end

	function M.ToInteractable(inst, range)
		range = range or 4
		local origin, look = nil, nil
		if GB.Resolver.promptAnchor then
			origin, look = GB.Resolver.promptAnchor(inst)
		end
		origin = origin or GB.Resolver.positionOf(inst)
		if not origin then
			return M.moveTo(inst, range)
		end
		local xz = look and Vector3.new(look.X, 0, look.Z)
		if not xz or xz.Magnitude < 0.2 then
			xz = Vector3.new(0, 0, 1)
		else
			xz = xz.Unit
		end
		local perp = Vector3.new(-xz.Z, 0, xz.X)
		local dist = math.clamp(range, 3, 6)
		local cands = {
			origin + xz * dist,
			origin - xz * dist,
			origin + perp * dist,
			origin - perp * dist,
		}
		local dest
		local best
		for i = 1, #cands do
			local c = cands[i]
			local g = M.groundAt(c)
			if g and g.Y > origin.Y + 4 then
				g = Vector3.new(c.X, origin.Y, c.Z)
			end
			local use = g or Vector3.new(c.X, origin.Y, c.Z)
			if M.destOk(use) then
				local dPrompt = (use - origin).Magnitude
				local lift = math.abs(use.Y - origin.Y)
				if dPrompt <= 7.6 and (not best or lift < best) then
					best = lift
					dest = use
				end
			end
		end
		dest = dest or Vector3.new(origin.X + xz.X * dist, origin.Y, origin.Z + xz.Z * dist)
		GB.Log.log("TRAVEL", "Teleport -> " .. (GB.Resolver.displayName(inst) or inst.Name))
		local ok = M.setPos(dest, { MaxGroundY = origin.Y + 4 })
		local root = M.hrp()
		if root and (root.Position - origin).Magnitude > 7.5 then
			root.CFrame = CFrame.new(dest)
			M.rememberSafe()
			ok = true
		end
		return ok
	end

	function M.firePrompt(pr, hold, inst)
		if not pr then
			return false
		end
		local dur = hold
		if dur == nil then
			local ok, hd = pcall(function()
				return pr.HoldDuration
			end)
			dur = (ok and type(hd) == "number" and hd) or 0
		end
		if type(dur) ~= "number" or dur < 0 then
			dur = 0
		end
		local ok = pcall(function()
			if dur > 0 then
				fireproximityprompt(pr, dur)
			else
				fireproximityprompt(pr)
			end
		end)
		task.wait(dur > 0 and (dur + 0.12) or 0.12)
		local target = inst or (GB.Resolver.interactableOf and GB.Resolver.interactableOf(pr))
		local ev = game.ReplicatedStorage:FindFirstChild("Events")
		local r = ev and ev:FindFirstChild("ProximityPrompt")
		if r then
			pcall(function()
				r:FireServer(pr, pr.Name, {
					ObjectName = target and target.Name or pr.Name,
				})
			end)
		end
		return ok
	end

	function M.interact(inst, range, hold)
		if not inst then
			return false
		end
		M.ToInteractable(inst, range or 4)
		task.wait(0.15)
		local origin, _, pr = nil, nil, nil
		if GB.Resolver.promptAnchor then
			origin, _, pr = GB.Resolver.promptAnchor(inst)
		end
		pr = pr or GB.Resolver.prompt(inst)
		if not pr then
			return false
		end
		local root = M.hrp()
		local d = (root and origin) and (root.Position - origin).Magnitude or -1
		if root and origin and d > 7.5 then
			root.CFrame = CFrame.new(origin + Vector3.new(0, 0, 3))
			M.rememberSafe()
			d = (root.Position - origin).Magnitude
		end
		local dur = hold
		if dur == nil then
			local ok, hd = pcall(function()
				return pr.HoldDuration
			end)
			dur = (ok and type(hd) == "number" and hd) or 0
		end
		GB.Log.log("UI", string.format("%s %s d=%.1f", (dur and dur > 0) and "hold prompt" or "prompt", inst.Name or pr.Name, d))
		return M.firePrompt(pr, dur, inst)
	end

	function M.sameIsland(a, b)
		return a and b and a == b
	end

	function M.pullStream(island)
		if type(island) ~= "string" or island == "" then
			return false
		end
		local dests = {}
		local function addPos(pos)
			if typeof(pos) == "Vector3" then
				local u = usablePos(pos)
				if u and M.destOk(u) then
					dests[#dests + 1] = u
				end
			end
		end
		addPos(M.islandSpawn(island))
		local aa = workspace:FindFirstChild("AA IMPORTANT")
		local sl = aa and aa:FindFirstChild("Spawn Locations")
		if sl then
			for _, c in ipairs(sl:GetChildren()) do
				if string.find(c.Name, island, 1, true) then
					if isPart(c) then
						addPos(c.Position)
					else
						addPos(instancePosition(c))
					end
				end
			end
		end
		local dlg = aa and aa:FindFirstChild("DialogueNPCs")
		local folder = dlg and dlg:FindFirstChild(island)
		if folder then
			for _, c in ipairs(folder:GetChildren()) do
				addPos(GB.Resolver.positionOf(c))
			end
		end
		if #dests == 0 then
			return false
		end
		local root = M.hrp()
		local start = root and root.Position
		local pick = dests[1]
		if start then
			local bestD = (pick - start).Magnitude
			for i = 2, #dests do
				local d = (dests[i] - start).Magnitude
				if d > 40 and d < bestD then
					pick, bestD = dests[i], d
				end
			end
			if bestD < 18 then
				for i = 1, #dests do
					if (dests[i] - start).Magnitude > 80 then
						pick = dests[i]
						break
					end
				end
			end
		end
		GB.Log.log("TRAVEL", "stream pull " .. island)
		return M.setPos(pick)
	end

	local _moveToRaw = M.moveTo
	function M.moveTo(instOrPos, range)
		local t0 = pbegin()
		local out = { pcall(_moveToRaw, instOrPos, range) }
		pdone("World travel operations", t0)
		if not out[1] then
			error(out[2])
		end
		return unpack(out, 2)
	end

	local _toEnemyRaw = M.ToEnemy
	function M.ToEnemy(inst, range)
		local t0 = pbegin()
		local out = { pcall(_toEnemyRaw, inst, range) }
		pdone("World travel operations", t0)
		if not out[1] then
			error(out[2])
		end
		return unpack(out, 2)
	end

	return M
end
]],
    ["Progression/DecisionEngine.lua"] = [[-- Priority: Recovery → Mandatory story → Prerequisites → Level-gate farm → Story.
-- Optional Fruit/Haki/Race after story is idle.

return function(GB)
	local M = {
		goal = nil,
		task = nil,
	}
	local logDoing

	local function pbegin()
		return GB.Profiler and GB.Profiler.begin and GB.Profiler.begin() or nil
	end

	local function pdone(name, t0)
		if t0 and GB.Profiler and GB.Profiler.done then
			GB.Profiler.done(name, t0)
		end
	end

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

	local function isStory(name)
		if not name or not GB.QuestData then
			return false
		end
		for _, ch in ipairs(GB.QuestData.CHAINS) do
			for _, n in ipairs(ch.order) do
				if n == name then
					return true
				end
			end
		end
		return false
	end

	local function nextStory(island, lv)
		for _, ch in ipairs(GB.QuestData.CHAINS) do
			if ch.island == island then
				for _, name in ipairs(ch.order) do
					if not GB.Config.SkipQuests[name] and not GB.PlayerData.finished(name, true) then
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

	local function activeQuestNames()
		local names = GB.PlayerData.activeNames and GB.PlayerData.activeNames() or {}
		local cur = GB.PlayerData.current and GB.PlayerData.current() or nil
		if type(cur) == "string" and cur ~= "" and not table.find(names, cur) then
			names[#names + 1] = cur
		end
		return names
	end

	local function questStatus(name)
		if GB.Quest and GB.Quest.questStatus then
			return GB.Quest.questStatus(name)
		end
		return "UNRESOLVED", "missing-status"
	end

	local function blockerList()
		return GB.Quest and GB.Quest.CurrentBlockers and GB.Quest.CurrentBlockers() or {}
	end

	local function logBlockedQuest(name, why)
		local key = tostring(name) .. "|" .. tostring(why)
		if M._blockedKey == key and os.clock() - (M._blockedAt or 0) < 8 then
			return
		end
		M._blockedKey = key
		M._blockedAt = os.clock()
		GB.Log.warn("QUEST", "defer " .. tostring(name) .. " " .. tostring(why))
	end

	local function pickReadyActive(skipName)
		local chosen
		for _, name in ipairs(activeQuestNames()) do
			if name ~= skipName and not GB.Config.SkipQuests[name] then
				local status, why = questStatus(name)
				if status == "BLOCKED_REQUIREMENT" or status == "DEFERRED" then
					logBlockedQuest(name, why)
				elseif status == "READY" or status == "IN_PROGRESS" then
					chosen = name
					break
				end
			end
		end
		return chosen
	end

	local function runFarmGoal(snap, why)
		local rep = bestRepeat(snap.CurrentIsland, snap.Level or 0)
		if not rep then
			return false
		end
		local blockers = blockerList()
		local note = tostring(why or "story_blocked")
		for _, b in ipairs(blockers) do
			if b.Type == "STAT_REQUIREMENT" and b.Stat == "Strength" then
				note = string.format("FarmUntilStrength(%d/%d)", tonumber(b.Current) or 0, tonumber(b.Required) or 0)
				break
			end
		end
		if M._farmNote ~= (rep .. "|" .. note) then
			M._farmNote = rep .. "|" .. note
			GB.Log.log("PLANNER", "farm goal " .. note)
			GB.Log.log("PLANNER", "next=" .. tostring(rep))
		end
		M.goal = { Type = "FARM", Quest = rep, Note = note, At = os.clock() }
		setTask("farm:" .. rep)
		logDoing("farm", rep)
		GB.Quest.doLive(rep)
		return true
	end

	function M.optionalOk()
		if GB.Config.StoryFirst == false then
			return true
		end
		local cur = GB.PlayerData.current()
		if cur and isStory(cur) and not GB.Config.SkipQuests[cur] then
			return false
		end
		if M.task and string.find(tostring(M.task), "quest:", 1, true) then
			return false
		end
		if M.task and string.find(tostring(M.task), "story:", 1, true) then
			return false
		end
		return true
	end

	local function runOptional()
		if not M.optionalOk() then
			return
		end
		GB.Boss.tick()
		GB.Fruit.tick()
		GB.Haki.tick()
		GB.RaceTrait.tick()
		GB.Treasure.tick()
		GB.Chest.tick()
		GB.Backpack.tick()
	end

	function logDoing(doing, target)
		local key = tostring(doing) .. "|" .. tostring(target or "-")
		if M._doingKey == key then
			return
		end
		M._doingKey = key
		GB.Log.log("STATE", string.format("doing=%s target=%s", tostring(doing), tostring(target or "-")))
	end

	local function logQuestDoing(name)
		local mob = GB.Combat and GB.Combat.lockMob
		if mob and GB.Combat.IsEnemyAlive and GB.Combat.IsEnemyAlive(mob) then
			logDoing("combat", mob.Name)
			return
		end
		local qs = name and GB.Quest.questState(name)
		local o = qs and qs.Objective
		if o then
			local typ = tostring(o.Type or "quest")
			if typ == "Collect" or typ == "Kill" or typ == "Defeat" or typ == "Hit" or typ == "Shoot" then
				logDoing("combat", o.TargetName or (GB.Acquire and GB.Acquire.lastSource) or "-")
			elseif typ == "Talk" or typ == "Automatic Talk" then
				logDoing("talk", o.TargetName)
			else
				logDoing(string.lower(typ), o.TargetName)
			end
			return
		end
		logDoing("quest", name)
	end

	local function acceptNextStory(island, lv)
		local story = nextStory(island, lv)
		if not story then
			return false
		end
		if GB.PlayerData.finished(story, true) then
			return false
		end
		setTask("story:" .. story)
		logDoing("accept", story)
		GB.Quest.doLive(story)
		return true
	end

	local function afterQuest(name)
		if GB.Tutorial and GB.Tutorial.IsBlocking and select(1, GB.Tutorial.IsBlocking()) then
			return
		end
		if name and GB.PlayerData.finished(name, true) then
			if GB.Stats and GB.Stats.markDirty then
				GB.Stats.markDirty("quest_complete")
			end
			if GB.Combat then
				GB.Combat.stopLock()
			end
			local snap = GB.State.get()
			acceptNextStory(snap.CurrentIsland, snap.Level or 0)
			return
		end
		logQuestDoing(name)
	end

	function M.decide()
		local snap = GB.State.refresh()
		if not snap.Alive then
			setTask("wait_spawn")
			logDoing("wait_spawn")
			return
		end
		if GB.PlayerData and GB.PlayerData.refreshLive then
			GB.PlayerData.refreshLive(false, "engine_cycle")
		end

		local tutSnap = snap.UI or nil
		local gate = GB.Tutorial and GB.Tutorial.GetCurrentGate and GB.Tutorial.GetCurrentGate()
		local continueOverlay = gate and gate.Type == (GB.Tutorial.GateTypes and GB.Tutorial.GateTypes.ContinueOverlay)

		-- Recovery dumps / strategy change, then resume story. Do not freeze.
		-- ContinueOverlay owns its own attempt budget — do not recycle lookup.
		if GB.Recovery.stuck() and not continueOverlay then
			setTask("recovery")
			GB.Recovery.run("engine")
			local s2 = GB.State.get and GB.State.get() or nil
			tutSnap = (s2 and s2.UI) or tutSnap
			gate = GB.Tutorial and GB.Tutorial.GetCurrentGate and GB.Tutorial.GetCurrentGate()
			continueOverlay = gate and gate.Type == (GB.Tutorial.GateTypes and GB.Tutorial.GateTypes.ContinueOverlay)
		end

		local blocking = (type(tutSnap) == "table" and (tutSnap.Blocking == true or tutSnap.TutorialActive == true))
			or (GB.Tutorial and GB.Tutorial.IsBlocking and select(1, GB.Tutorial.IsBlocking()))
		if GB.Recovery.outcome == "BLOCKING_UI" or GB.Recovery.outcome == "BLOCKING_GATE_UNRESOLVED" or blocking then
			if GB.Recovery.outcome == "BLOCKING_GATE_UNRESOLVED" and GB.Tutorial and GB.Tutorial.unresolved then
				return
			end
			setTask("tutorial")
			logDoing("tutorial", gate and (gate.Id .. ":" .. tostring(gate.Payload or gate.Type)) or (snap.UI and snap.UI.TutorialStep))
			if GB.Combat then
				GB.Combat.stopLock()
			end
			local cleared = false
			if GB.Tutorial and GB.Tutorial.ExecuteGate then
				cleared = GB.Tutorial.ExecuteGate(gate)
			elseif GB.Tutorial and GB.Tutorial.ExecuteCurrentStep then
				cleared = GB.Tutorial.ExecuteCurrentStep()
			end
			if cleared and GB.Tutorial and not select(1, GB.Tutorial.IsBlocking()) then
				GB.Recovery.outcome = nil
				M._doingKey = nil
				if GB.Tutorial.refreshAfterGate then
					GB.Tutorial.refreshAfterGate()
				else
					if GB.PlayerData and GB.PlayerData.forceQuestRefresh then
						GB.PlayerData.forceQuestRefresh("tutorial_gate")
					elseif GB.PlayerData and GB.PlayerData.refreshLive then
						GB.PlayerData.refreshLive(true, "tutorial_gate")
					end
					if GB.Planner and GB.Planner.Replan then
						GB.Planner.Replan()
					end
				end
				snap = GB.State.refresh()
				tutSnap = snap.UI or tutSnap
				-- fall through to quest this tick
			else
				return
			end
		end

		if snap.GameplayPaused then
			setTask("wait_unpause")
			logDoing("wait_unpause")
			if GB.State.dismissTutorialOverlay then
				GB.State.dismissTutorialOverlay()
			end
			GB.World.waitUnpause()
			return
		end

		if GB.Stats and GB.Stats.tick then
			GB.Stats.tick()
		end

		if GB.Config.AutoCodes then
			GB.Codes.tick()
		end
		if GB.Config.AutoRewards then
			GB.Rewards.tick()
		end
		-- Quest path returns before the idle ticks. Keep gear mid-story.
		if GB.Equipment and GB.Equipment.tick then
			GB.Equipment.tick()
		end

		local function otherOrFarm(skipName, reason)
			local nextQuest = pickReadyActive(skipName)
			if nextQuest then
				if M._planQuest ~= nextQuest then
					M._planQuest = nextQuest
					GB.Log.log("PLANNER", "choose " .. tostring(nextQuest))
				end
				setTask("quest:" .. nextQuest)
				logQuestDoing(nextQuest)
				GB.Quest.doLive(nextQuest)
				afterQuest(nextQuest)
				return true
			end
			if runFarmGoal(snap, reason or "no_ready_active") then
				return true
			end
			return false
		end

		-- Mandatory live story
		if GB.Config.AutoTutorial or GB.Config.AutoQuest then
			local cur = GB.PlayerData.current()
			if cur and not GB.Config.SkipQuests[cur] then
				local status, why = questStatus(cur)
				if status == "BLOCKED_REQUIREMENT" or status == "DEFERRED" then
					logBlockedQuest(cur, why)
					if otherOrFarm(cur, why) then
						return
					end
					setTask("defer:" .. cur)
					logDoing("defer", cur)
					return
				end
				local qs = GB.Quest.questState(cur)
				local obj = qs and qs.Objective
				local gated = obj and obj.Type == "Required" and obj.TargetName == "Level"
				local need = gated and (obj.Amount or GB.QuestData.needLevel(cur)) or 0
				if gated and (snap.Level or 0) < need then
					if runFarmGoal(snap, "FarmUntilLevel(" .. tostring(need) .. ")") then
						return
					end
					setTask("wait_level:" .. cur)
					logDoing("wait_level", cur)
					return
				end
				setTask("quest:" .. cur)
				logQuestDoing(cur)
				GB.Quest.doLive(cur)
				afterQuest(cur)
				return
			end
			local readyActive = pickReadyActive(nil)
			if readyActive then
				if M._planQuest ~= readyActive then
					M._planQuest = readyActive
					GB.Log.log("PLANNER", "choose " .. tostring(readyActive))
				end
				setTask("quest:" .. readyActive)
				logQuestDoing(readyActive)
				GB.Quest.doLive(readyActive)
				afterQuest(readyActive)
				return
			end
			if #blockerList() > 0 and otherOrFarm(nil, "all_story_blocked") then
				return
			end
		end

		-- Prerequisites / progression shop (Flintlock, pickaxe, snail, boat)
		if GB.Config.AutoShop then
			GB.Shop.tick()
		end

		if GB.Inventory.full() then
			GB.Log.warn("STATE", "inventory many items — UNKNOWN kept")
		end

		GB.Skills.tick()
		GB.Travel.tick()
		GB.Boat.tick()

		local liveName = GB.PlayerData.current()
		if liveName and not GB.Config.SkipQuests[liveName] then
			local status, why = questStatus(liveName)
			if status == "BLOCKED_REQUIREMENT" or status == "DEFERRED" then
				logBlockedQuest(liveName, why)
			else
				setTask("quest:" .. liveName)
				logQuestDoing(liveName)
				GB.Quest.doLive(liveName)
				afterQuest(liveName)
				return
			end
		end

		local readyFallback = pickReadyActive(liveName)
		if readyFallback then
			GB.Log.log("PLANNER", "choose " .. tostring(readyFallback))
			setTask("quest:" .. readyFallback)
			logQuestDoing(readyFallback)
			GB.Quest.doLive(readyFallback)
			afterQuest(readyFallback)
			return
		end
		if #blockerList() > 0 and runFarmGoal(snap, "active_blocked") then
			return
		end

		local pick = picker()
		if pick and pick.name then
			setTask("pick:" .. pick.name)
			logDoing("pick", pick.name)
			GB.Quest.doLive(pick.name)
			afterQuest(pick.name)
			return
		end

		local island = snap.CurrentIsland
		local lv = snap.Level or 0
		local story = nextStory(island, lv)
		if story then
			if lv < GB.QuestData.needLevel(story) then
				if runFarmGoal(snap, "FarmUntilLevel(" .. tostring(GB.QuestData.needLevel(story)) .. ")") then
					return
				end
				setTask("wait_level:" .. story)
				logDoing("wait_level", story)
				return
			end
			setTask("story:" .. story)
			logDoing("accept", story)
			GB.Quest.doLive(story)
			afterQuest(story)
			return
		end

		local rep = bestRepeat(island, lv)
		if rep then
			runFarmGoal(snap, "story_idle")
			return
		end

		runOptional()
		setTask("idle")
		logDoing("idle")
	end

	local _decideRaw = M.decide
	function M.decide()
		local t0 = pbegin()
		local out = { pcall(_decideRaw) }
		pdone("DecisionEngine.decide", t0)
		if not out[1] then
			error(out[2])
		end
		return unpack(out, 2)
	end

	return M
end
]],
    ["Progression/Planner.lua"] = [[-- Goal + acquisition plan. Subgoal stack. No ObjectiveType-only dispatch for Collect.

return function(GB)
	local M = {
		last = nil,
		seen = {},
	}

	local function objOf(qs)
		return qs and qs.Objective
	end

	function M.Replan()
		local cur = GB.PlayerData and GB.PlayerData.current and GB.PlayerData.current()
		if not (cur and GB.Quest and GB.Quest.questState) then
			M.last = nil
			return nil
		end
		return M.build(GB.Quest.questState(cur))
	end

	function M.build(qs)
		if not qs or not qs.Objective then
			M.last = nil
			return nil
		end
		local o = qs.Objective
		local spec = GB.QuestSpecs and GB.QuestSpecs.lookup(qs.Name, qs.StageIndex, o.Type, o.TargetName)
		local itemSpec = o.TargetName and GB.QuestSpecs and GB.QuestSpecs.itemOf(o.TargetName)
		local goal = (spec and spec.goal) or o.Type
		local method = spec and spec.acquire
		if not method and itemSpec then
			method = itemSpec.method
		end
		if o.Type == "Collect" or o.Type == "CollectLocal" or o.Type == "CollectLocalItem" or o.Type == "Loot" then
			goal = "AcquireItem"
		end
		local stack = GB.QuestSpecs and GB.QuestSpecs.subgoalsOf(qs.Name)
		local plan = {
			Quest = qs.Name,
			Stage = qs.StageIndex,
			Goal = goal,
			Target = o.TargetName,
			Amount = o.Amount or 1,
			Current = o.Current or 0,
			Method = method,
			Source = (spec and spec.source) or (itemSpec and itemSpec.source),
			Location = (spec and spec.location) or qs.Island,
			Marker = spec and spec.marker,
			Type = o.Type,
			Subgoals = stack,
			Handler = spec and spec.handler,
		}
		M.last = plan
		return plan
	end

	local function subgoalDone(step)
		if not step then
			return true
		end
		if step.goal == "HaveGold" then
			local gold = GB.State.get().Gold or 0
			return gold >= (step.amount or 0)
		end
		if step.goal == "AcquireItem" then
			local ok, n = GB.PlayerData.hasItem(step.item)
			return ok and (n or 1) >= (step.amount or 1)
		end
		if step.goal == "Upgrade" then
			local qs = GB.Quest.questState("First Upgrade")
			if not qs or qs.IsComplete then
				return true
			end
			local o = qs.Objective
			return not o or o.Type ~= "Upgrade"
		end
		return false
	end

	function M.executeSubgoals(qs, plan)
		local stack = plan.Subgoals
		if type(stack) ~= "table" then
			return false
		end
		local qkey = qs.Name
		if not M.seen[qkey] then
			M.seen[qkey] = {}
		end
		local o = objOf(qs)
		for i, step in ipairs(stack) do
			local id = tostring(step.goal) .. "|" .. tostring(step.item or i)
			if M.seen[qkey][id] and M.seen[qkey][id] > 12 then
				GB.Log.warn("PLAN", "CYCLE " .. qs.Name .. " " .. id)
				return false
			end
			if not subgoalDone(step) then
				M.seen[qkey][id] = (M.seen[qkey][id] or 0) + 1
				if step.goal == "HaveGold" then
					GB.Log.log("PLAN", "Need gold " .. tostring(step.amount))
					return false
				end
				if step.goal == "AcquireItem" then
					if o and o.Type == "Collect" and o.TargetName and o.TargetName ~= step.item then
						-- live condition is a later item; skip only if owned
					end
					return GB.Acquire.AcquireItem(step.item, step.amount or 1, {
						Quest = qs.Name,
						Stage = qs.StageIndex,
						Type = o and o.Type,
						Method = step.method,
					})
				end
				if step.goal == "Upgrade" then
					return GB.Equipment.upgradeNamed(step.item)
				end
				return false
			end
		end
		return true
	end

	function M.execute(qs, plan)
		if not (qs and plan) then
			return false
		end
		if GB.Tutorial and GB.Tutorial.IsBlocking and select(1, GB.Tutorial.IsBlocking()) then
			return GB.Tutorial.ExecuteCurrentStep()
		end
		if plan.Goal == "Equip" and plan.Target then
			return GB.Quest.handleCondition(qs.Name, qs.Objective.Raw, qs.Stage)
		end
		if plan.Type == "Unlock" or plan.Type == "Loot" or plan.Type == "Smelt" or plan.Type == "Upgrade" then
			return GB.Quest.handleCondition(qs.Name, qs.Objective.Raw, qs.Stage)
		end
		if plan.Goal == "AcquireItem" and plan.Target then
			if qs.Name == "First Upgrade" and plan.Type == "Collect" and plan.Target == "Rusty Pickaxe" then
				return GB.Shop.buy(plan.Target, plan.Amount or 1)
			end
			local beforeCur = plan.Current or 0
			local beforeSig = GB.Quest.signature(qs)
			local ok, err = GB.Acquire.AcquireItem(plan.Target, plan.Amount or 1, {
				Quest = qs.Name,
				Stage = qs.StageIndex,
				Type = plan.Type,
				Method = plan.Method,
				Source = plan.Source,
				Marker = plan.Marker,
			})
			if ok and GB.Quest.waitProgress then
				local progressed = GB.Quest.waitProgress(qs.Name, beforeSig, 2.4)
				if progressed then
					local after = GB.Quest.questState(qs.Name)
					local nextCur = plan.Amount
					if after.StageIndex == qs.StageIndex and after.Objective then
						nextCur = after.Objective.Current
					end
					GB.Log.log(
						"QUEST",
						string.format("%s/%s -> %s/%s", tostring(beforeCur), tostring(plan.Amount), tostring(nextCur), tostring(plan.Amount))
					)
					GB.Quest.noteOk(qs.Name)
					if GB.Acquire.clearCycles then
						GB.Acquire.clearCycles(qs.Name)
					end
					return true
				end
			end
			if ok then
				return true
			end
			if err == "hunting" then
				return false
			end
			GB.Quest.noteFail(qs.Name, "acquire " .. tostring(plan.Target))
			return false
		end
		return GB.Quest.handleCondition(qs.Name, qs.Objective.Raw, qs.Stage)
	end

	return M
end
]],
    ["Systems/Acquire.lua"] = [[-- Generic item acquisition. Methods from QuestSpecs. No quest-name spaghetti.

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
		if GB.PlayerData.finished(qname, true) then
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
				local ok, why = GB.Combat.huntUntilDead and GB.Combat.huntUntilDead(source, 12, ctx.Quest)
				if not ok then
					GB.Combat.hunt(source, ctx.Quest)
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
]],
    ["Systems/Backpack.lua"] = [[-- Backpack UI open/select/equip. Slot-upgrade remote still UNRESOLVED.

return function(GB)
	local M = {
		disabled = false,
		reason = nil,
		lastOpen = 0,
	}

	local function pg()
		return GB.lp and GB.lp.PlayerGui
	end

	local function backpackRoot()
		local ui = pg()
		local bp = ui and ui:FindFirstChild("Backpack")
		return bp and bp:FindFirstChild("Backpack")
	end

	function M.storageFrame()
		local root = backpackRoot()
		if not root then
			return nil
		end
		local frame = root:FindFirstChild("BackpackFrame")
		local scale = frame and frame:FindFirstChild("Scale")
		return scale and scale:FindFirstChild("Storage")
	end

	function M.equipsSlots()
		local root = backpackRoot()
		if not root then
			return nil
		end
		local frame = root:FindFirstChild("BackpackFrame")
		local scale = frame and frame:FindFirstChild("Scale")
		local equips = scale and scale:FindFirstChild("Equips")
		local slots = equips and equips:FindFirstChild("Slots")
		return slots
	end

	function M.isOpen()
		local storage = M.storageFrame()
		return storage ~= nil and storage.Visible == true
	end

	function M.topbarButton()
		local ui = pg()
		if not ui then
			return nil
		end
		local tb = ui:FindFirstChild("TopbarStandard")
		local holders = tb and tb:FindFirstChild("Holders")
		local left = holders and holders:FindFirstChild("Left")
		return left and left:FindFirstChild("Backpack")
	end

	function M.open()
		if M.isOpen() then
			return true
		end
		if os.clock() - M.lastOpen < 0.4 then
			return M.isOpen()
		end
		M.lastOpen = os.clock()
		GB.Log.log("UI", "Opening backpack")
		if GB.Remotes.backpackToggle then
			GB.Remotes.backpackToggle(true)
		end
		local btn = M.topbarButton()
		if btn then
			if btn:IsA("GuiButton") then
				GB.State.clickGui(btn)
			else
				local child = btn:FindFirstChildWhichIsA("GuiButton", true)
				if child then
					GB.State.clickGui(child)
				else
					GB.State.clickGui(btn)
				end
			end
		end
		local t0 = os.clock()
		while os.clock() - t0 < 1.2 do
			if M.isOpen() then
				return true
			end
			task.wait(0.08)
		end
		return M.isOpen()
	end

	function M.close()
		if not M.isOpen() then
			return true
		end
		if GB.Remotes.backpackToggle then
			GB.Remotes.backpackToggle(false)
		end
		return not M.isOpen()
	end

	local function titleOf(inst)
		if not inst then
			return nil
		end
		local t = inst:FindFirstChild("Title")
		if t and (t:IsA("TextLabel") or t:IsA("TextButton") or t:IsA("TextBox")) then
			return t.Text
		end
		return GB.State and GB.State.guiText(inst)
	end

	function M.findItemFrame(name)
		local storage = M.storageFrame()
		local sf = storage and storage:FindFirstChild("ScrollingFrame")
		if sf then
			for _, child in ipairs(sf:GetChildren()) do
				if child:IsA("Frame") and titleOf(child) == name then
					return child
				end
			end
		end
		local root = backpackRoot()
		local frame = root and root:FindFirstChild("BackpackFrame")
		local scale = frame and frame:FindFirstChild("Scale")
		local bars = scale and scale:FindFirstChild("Bars")
		local bscale = bars and bars:FindFirstChild("Scale")
		local hotbar = bscale and bscale:FindFirstChild("Hotbar")
		if hotbar then
			for _, slot in ipairs(hotbar:GetChildren()) do
				if slot:IsA("Frame") then
					for _, child in ipairs(slot:GetChildren()) do
						if child:IsA("Frame") and titleOf(child) == name then
							return child
						end
					end
				end
			end
		end
		return nil
	end

	function M.isGearEquipped(name)
		local slots = M.equipsSlots()
		if not slots then
			return false
		end
		for _, slot in ipairs(slots:GetChildren()) do
			if slot:IsA("Frame") then
				if titleOf(slot) == name then
					return true
				end
				for _, child in ipairs(slot:GetDescendants()) do
					if (child:IsA("TextLabel") or child:IsA("TextButton")) and child.Name == "Title" and child.Text == name then
						return true
					end
				end
			end
		end
		return false
	end

	function M.tick()
		if not GB.Config.AutoBackpack then
			return
		end
	end

	return M
end
]],
    ["Systems/Boat.lua"] = [[-- Rowboat purchase + spawn. Ships:FireServer("Purchase", {Type="Rowboat"})
-- Spawn: Ships:FireServer("Spawn", index) — index from owned list when available.

return function(GB)
	local M = {
		bought = false,
		spawned = false,
	}

	function M.buyRowboat()
		local gold = GB.State.get().Gold or 0
		if gold < 50 then
			GB.Log.log("TRAVEL", "Rowboat needs 50G")
			return false
		end
		local part = GB.Resolver.shopItem("Rowboat")
		if part then
			GB.World.moveTo(part, 12)
		end
		GB.Log.log("TRAVEL", "Ships Purchase Rowboat")
		M.bought = GB.Remotes.rowboatPurchase()
		return M.bought
	end

	function M.spawnRowboat()
		if not M.bought and not GB.PlayerData.hasItem("Rowboat") then
			M.buyRowboat()
			task.wait(0.4)
		end
		-- index UNKNOWN until GetShipInfo / viewer list; try 1 then 0
		GB.Log.log("TRAVEL", "Ships Spawn try 1")
		GB.Remotes.shipSpawn(1)
		M.spawned = true
		return true
	end

	function M.travelToward(island)
		M.spawnRowboat()
		local dest = GB.World.islandSpawn(island)
		if dest then
			return GB.World.moveTo(dest, 30)
		end
		return false
	end

	function M.tick()
		if not GB.Config.AutoBoat then
			return
		end
		if GB.PlayerData.live("Setting Sail") then
			if not GB.PlayerData.hasItem("Rowboat") then
				M.buyRowboat()
			else
				M.spawnRowboat()
			end
		end
	end

	return M
end
]],
    ["Systems/Boss.lua"] = [[-- Boss = named kill on live/story quest. No invented HP/loot.

return function(GB)
	local M = {}

	local BOSSES = {
		["The Hoarder"] = "Afuaru, The Hoarder",
		["Axe-Handed Tyrant"] = "Axe-Hand Logan",
		["Tyrannical Captain"] = "Axe-Hand Logan",
		["Feral Dog"] = "Soro",
		["Captain's Brat"] = "Blonde Goblin",
		["The Ringmaster"] = "Choppy The Clown",
		["Choppy The Clown"] = "Choppy The Clown",
		["Stephon's Tormentor"] = "\"Barrel Clown\" Binki",
		["The Wandering Hypnotist"] = "\"Hypnotist\" Mango",
		["The Island's Protector"] = "Captain Esopo",
		["Undermine The Circus 3"] = "Choppy The Clown",
	}

	function M.tick()
		if not GB.Config.AutoBoss then
			return
		end
		local snap = GB.State.get()
		for name, target in pairs(BOSSES) do
			if GB.PlayerData.live(name) then
				if GB.Combat.lockMob and GB.Combat.IsEnemyAlive and not GB.Combat.IsEnemyAlive(GB.Combat.lockMob) then
					GB.Combat.stopLock()
				end
				GB.Combat.attack(target, name)
				return
			end
		end
	end

	return M
end
]],
    ["Systems/Chest.lua"] = [[-- Afuaru loot + opportunistic nearby chests. No far junk travel.

return function(GB)
	local M = {}

	local function chestPos(chest)
		return GB.Resolver.positionOf(chest)
	end

	function M.openOne(chest)
		if not chest then
			return false
		end
		if chest:GetAttribute("Opened") == true then
			return false
		end
		local root = GB.World.hrp()
		local pos = chestPos(chest)
		if not (root and pos) then
			return false
		end
		if (root.Position - pos).Magnitude > 80 then
			if not GB.PlayerData.live("The Hoarder") then
				return false
			end
		end
		if GB.World.interact then
			GB.World.interact(chest, 6)
		else
			GB.World.moveTo(chest, 6)
			local pr = GB.Resolver.prompt(chest)
			if pr then
				GB.World.firePrompt(pr)
			end
		end
		GB.Log.log("CHEST", "loot " .. chest.Name)
		return true
	end

	function M.openNearby()
		if not GB.Config.AutoChest then
			return false
		end
		local chest = GB.Resolver.chest()
		return M.openOne(chest)
	end

	function M.lootUntil(questName, amount)
		amount = amount or 5
		local t0 = os.clock()
		local hits = 0
		while os.clock() - t0 < 18 do
			if questName and GB.Quest then
				if GB.PlayerData.refreshLive then
					GB.PlayerData.refreshLive(false, "chest_probe")
				end
				if GB.PlayerData.finished(questName, true) then
					return true
				end
				local qs = GB.Quest.questState(questName)
				if qs and (qs.IsComplete or qs.StageIndex and qs.Objective and qs.Objective.Type ~= "Loot") then
					return true
				end
				if qs and qs.Objective and (qs.Objective.Current or 0) >= amount then
					return true
				end
			end
			local list = GB.Resolver.chests and GB.Resolver.chests() or {}
			local chest = list[1] or GB.Resolver.chest()
			if not chest then
				task.wait(0.35)
			else
				if M.openOne(chest) then
					hits = hits + 1
					if GB.PlayerData and GB.PlayerData.forceQuestRefresh then
						GB.PlayerData.forceQuestRefresh("chest_loot")
					end
				end
				task.wait(0.4)
			end
			if hits >= amount then
				return true
			end
		end
		return hits > 0
	end

	function M.tick()
		if GB.PlayerData.live("The Hoarder") then
			local qs = GB.Quest and GB.Quest.questState("The Hoarder")
			if qs and qs.Objective and qs.Objective.Type == "Loot" then
				M.openNearby()
			end
		end
	end

	return M
end
]],
    ["Systems/Codes.lua"] = [[-- Codes:FireServer(code) VERIFIED. OnClientEvent ShowFeedback(text, ok).
-- CodeProg:FireServer() list; CodeProg:FireServer(code, index) claim.
-- Finite retries. Migrate getgenv().GBCodes.

return function(GB)
	local M = {
		i = 1,
		hooked = false,
		lastAt = 0,
	}

	local function classify(text, ok)
		text = string.lower(tostring(text or ""))
		if ok then
			if string.find(text, "already") then
				return "ALREADY_USED"
			end
			return "SUCCESS"
		end
		if string.find(text, "invalid") or string.find(text, "not found") then
			return "INVALID"
		end
		if string.find(text, "expir") then
			return "EXPIRED"
		end
		if string.find(text, "already") or string.find(text, "used") then
			return "ALREADY_USED"
		end
		return "ERROR"
	end

	function M.hook()
		if M.hooked then
			return
		end
		local r = GB.Remotes.get("Codes")
		if r then
			r.OnClientEvent:Connect(function(text, ok)
				local st = classify(text, ok)
				local cur = GB.Config.Codes[M.i]
				if cur then
					GB.Persist.codeState(cur, st)
					GB.Log.log("REWARD", "code " .. cur .. " " .. st .. " " .. tostring(text))
				end
			end)
			M.hooked = true
		end
		GB.Remotes.codeProg()
	end

	function M.tick()
		if not GB.Config.AutoCodes then
			return
		end
		M.hook()
		local list = GB.Config.Codes
		if M.i > #list then
			return
		end
		local code = list[M.i]
		local prev = GB.Persist.data.codes[code]
		if prev and (prev.state == "SUCCESS" or prev.state == "INVALID" or prev.state == "EXPIRED" or prev.state == "ALREADY_USED") then
			M.i = M.i + 1
			return
		end
		if os.clock() - M.lastAt < 2.8 then
			return
		end
		local tries = prev and prev.tries or 0
		if tries >= 2 then
			GB.Persist.codeState(code, "ERROR")
			M.i = M.i + 1
			return
		end
		GB.Persist.data.codes[code] = GB.Persist.data.codes[code] or {}
		GB.Persist.data.codes[code].tries = tries + 1
		GB.Persist.data.codes[code].state = "UNKNOWN"
		GB.Log.log("REWARD", "redeem " .. code)
		M.lastAt = os.clock()
		GB.Remotes.code(code)
	end

	return M
end
]],
    ["Systems/Combat.lua"] = [[-- FindTarget / MoveToTarget / AttackTarget / ValidateKill / RecoverCombat.
-- Death = Dead attribute / Health<=0 / StateService Dead. Parent nil is despawn, not death.
-- AttackModule.Swing only at CanSwing + swingStateDuration.

return function(GB)
	local RS = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local M = {
		lockMob = nil,
		lockConn = nil,
		lockQuest = nil,
		lastSwing = 0,
		lastDash = 0,
		lastBlock = 0,
		lastStandAt = 0,
		lastTargetPos = nil,
		Attack = nil,
		State = nil,
		ActiveTarget = nil,
		deadTargets = {},
		diedConn = nil,
		deadAttrConn = nil,
		_released = nil,
		_hpLogged = nil,
		lastKillBefore = nil,
		lastQuestCheck = 0,
		lastQuestRefresh = 0,
		lastQuestDone = nil,
		KillTypes = {
			Kill = true,
			Defeat = true,
			Hit = true,
			Destroy = true,
			Shoot = true,
		},
	}

	local SWING_GAP = 0.42
	local REPOS_DIST = 4.2
	local TARGET_MOVED = 3.5
	local DEAD_TTL = 12
	local QUEST_CHECK_MIN_GAP = 0.32
	local QUEST_CHECK_SAFETY = 2.8

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

	local function loadAttack()
		if not M.Attack then
			M.Attack = require(RS.Modules.AttackModule)
		end
		return M.Attack
	end

	local function loadState()
		if not M.State then
			M.State = require(RS.Modules.StateService)
		end
		return M.State
	end

	local function pressKey()
		local ev = RS:FindFirstChild("Events")
		return ev and ev:FindFirstChild("PressKey")
	end

	local function isDummy(name)
		if GB.Resolver.isDummyName then
			return GB.Resolver.isDummyName(name)
		end
		return type(name) == "string" and string.find(name, "Dummy", 1, true) ~= nil
	end

	function M.canSwing(char)
		char = char or GB.World.char()
		if not char then
			return false
		end
		return loadState().GetPermission(char, "CanSwing") == true
	end

	function M.canDodge(char)
		char = char or GB.World.char()
		if not char then
			return false
		end
		return loadState().GetPermission(char, "CanDodge") == true
	end

	function M.isPet(inst)
		return GB.Resolver.isPet and GB.Resolver.isPet(inst)
	end

	function M.pruneDeadCache()
		local now = os.clock()
		for inst, t in pairs(M.deadTargets) do
			if typeof(inst) ~= "Instance" or not inst.Parent or now - t > DEAD_TTL then
				M.deadTargets[inst] = nil
			end
		end
	end

	function M.isRecentlyDead(target)
		if not target then
			return false
		end
		local t = M.deadTargets[target]
		return t ~= nil and os.clock() - t < DEAD_TTL
	end

	function M.markDead(target, reason)
		if not target then
			return
		end
		if M.deadTargets[target] then
			return
		end
		M.deadTargets[target] = os.clock()
		if GB.Cache and GB.Cache.invalidatePrefix then
			GB.Cache.invalidatePrefix("res:enemy:")
		elseif GB.Cache and GB.Cache.invalidate then
			GB.Cache.invalidate("res:enemy:" .. tostring(target and target.Name or "?"))
		end
		if GB.Resolver and GB.Resolver.invalidateDummy and isDummy(target.Name) then
			GB.Resolver.invalidateDummy()
		end
		local label = (GB.Resolver and GB.Resolver.displayName(target)) or target.Name
		if M._hpLogged ~= target then
			M._hpLogged = target
			GB.Log.log("COMBAT", string.format("%s hp=0 — dead", tostring(label)))
		end
		GB.Log.log("COMBAT", "Clearing dead target")
	end

	function M.readHealth(target)
		if not target then
			return nil
		end
		local h = target:FindFirstChildOfClass("Humanoid")
		if h then
			return h.Health, h.MaxHealth
		end
		local attr = target:GetAttribute("Health")
		if type(attr) == "number" then
			return attr, target:GetAttribute("MaxHealth")
		end
		local nv = target:FindFirstChild("Health")
		if nv and nv:IsA("NumberValue") then
			return nv.Value, nil
		end
		return nil, nil
	end

	function M.hasDeadFlag(target)
		if not target then
			return false
		end
		if target:GetAttribute("Dead") == true then
			return true
		end
		local st = M.State or (pcall(loadState) and M.State)
		if st and st.CheckForState then
			local ok, dead = pcall(st.CheckForState, st, target, "Dead")
			if ok and dead then
				return true
			end
		end
		return false
	end

	-- Central live/dead. Parent nil is despawn, not the death signal.
	function M.IsEnemyAlive(target)
		if typeof(target) ~= "Instance" then
			return false
		end
		if M.isRecentlyDead(target) then
			return false
		end
		if M.hasDeadFlag(target) then
			return false
		end
		if not target.Parent then
			return false
		end
		if M.isPet(target) then
			return false
		end
		local hp = M.readHealth(target)
		if type(hp) == "number" and hp <= 0 then
			return false
		end
		local h = target:FindFirstChildOfClass("Humanoid")
		if h then
			local ok, state = pcall(function()
				return h:GetState()
			end)
			if ok and state == Enum.HumanoidStateType.Dead then
				return false
			end
		end
		return true
	end

	function M.IsValidTarget(target, context)
		context = context or {}
		if typeof(target) ~= "Instance" then
			return false
		end
		if not M.IsEnemyAlive(target) then
			return false
		end
		if M.isPet(target) then
			return false
		end
		if GB.Resolver and GB.Resolver.part and not GB.Resolver.part(target) then
			return false
		end
		if context.Name then
			local want = context.Name
			if GB.Resolver and GB.Resolver.isDummyName and GB.Resolver.isDummyName(want) and isDummy(target.Name) then
				return true
			end
			local names = GB.Resolver and GB.Resolver.namesFor and GB.Resolver.namesFor(want, {})
			if GB.Resolver and GB.Resolver.nameMatches then
				if not GB.Resolver.nameMatches(target, names or { want }) then
					return false
				end
			else
				local disp = GB.Resolver and GB.Resolver.displayName(target)
				local npc = target:GetAttribute("NPCName")
				if target.Name ~= want and disp ~= want and npc ~= want then
					return false
				end
			end
		end
		return true
	end

	-- Compat for older call sites
	function M.aliveEnemy(mob)
		return M.IsEnemyAlive(mob)
	end

	function M.clearDeathWatch()
		if M.diedConn then
			M.diedConn:Disconnect()
			M.diedConn = nil
		end
		if M.deadAttrConn then
			M.deadAttrConn:Disconnect()
			M.deadAttrConn = nil
		end
	end

	function M.watchDeath(target)
		M.clearDeathWatch()
		if typeof(target) ~= "Instance" then
			return
		end
		local hum = target:FindFirstChildOfClass("Humanoid")
		if hum then
			M.diedConn = hum.Died:Connect(function()
				if M.lockMob == target then
					M.onTargetDead(target, "Died")
				else
					M.markDead(target, "Died")
				end
			end)
		end
		M.deadAttrConn = target:GetAttributeChangedSignal("Dead"):Connect(function()
			if target:GetAttribute("Dead") == true then
				if M.lockMob == target then
					M.onTargetDead(target, "Dead")
				else
					M.markDead(target, "Dead")
				end
			end
		end)
	end

	function M.setActive(target, questName)
		M.ActiveTarget = {
			Instance = target,
			Humanoid = target and target:FindFirstChildOfClass("Humanoid"),
			Root = GB.Resolver and GB.Resolver.part(target),
			Name = target and ((GB.Resolver and GB.Resolver.displayName(target)) or target.Name),
			AcquiredAt = os.clock(),
			LastHealth = target and M.readHealth(target),
			Dead = false,
			Quest = questName,
		}
		M.lockQuest = questName
		M.lastQuestDone = nil
		M.lastQuestCheck = 0
		M.lastQuestRefresh = 0
		M._released = nil
		M._hpLogged = nil
		if target then
			local hp = M.readHealth(target)
			GB.Log.log("COMBAT", string.format("Target %s hp=%s", M.ActiveTarget.Name, tostring(hp or "?")))
			M.watchDeath(target)
		end
	end

	function M.stopLock()
		M.clearDeathWatch()
		M.lockMob = nil
		M.lastTargetPos = nil
		M.lockQuest = nil
		if M.ActiveTarget then
			M.ActiveTarget.Dead = true
			M.ActiveTarget = nil
		end
		if M.lockConn then
			M.lockConn:Disconnect()
			M.lockConn = nil
		end
		local hum = GB.World.hum()
		if hum then
			hum.AutoRotate = true
			hum.PlatformStand = false
		end
	end

	function M.questCombatDone(questName, opts)
		opts = opts or {}
		questName = questName or M.lockQuest
		if not questName or not GB.Quest then
			return false
		end
		local now = os.clock()
		local force = opts.force == true
		if not force then
			if now - (M.lastQuestCheck or 0) < QUEST_CHECK_MIN_GAP then
				return false
			end
			local dirty = GB.PlayerData and GB.PlayerData.questDirty and GB.PlayerData.questDirty() or false
			if not dirty and now - (M.lastQuestRefresh or 0) < QUEST_CHECK_SAFETY then
				return false
			end
		end
		M.lastQuestCheck = now
		M.lastQuestRefresh = now
		perfCount("HeartbeatQuestCheck", 1)
		local t0 = pbegin()
		if GB.PlayerData and GB.PlayerData.refreshLive then
			GB.PlayerData.refreshLive(force, opts.source or "combat")
		end
		if GB.PlayerData and GB.PlayerData.finished and GB.PlayerData.finished(questName, true) then
			pdone("Combat Heartbeat slow path", t0)
			return true
		end
		local qs = GB.Quest.questState(questName)
		pdone("Combat Heartbeat slow path", t0)
		if not qs then
			return false
		end
		if qs.IsComplete then
			return true
		end
		local o = qs.Objective
		if not o then
			return true
		end
		if not M.KillTypes[o.Type] then
			return true
		end
		if type(o.Current) == "number" and type(o.Amount) == "number" and o.Current >= o.Amount then
			return true
		end
		if o.Complete == true then
			return true
		end
		return false
	end

	function M.logKillCredit(questName, before)
		if not (questName and GB.Quest) then
			return
		end
		if GB.PlayerData and GB.PlayerData.forceQuestRefresh then
			GB.PlayerData.forceQuestRefresh("kill_credit")
		elseif GB.PlayerData and GB.PlayerData.refreshLive then
			GB.PlayerData.refreshLive(true, "kill_credit")
		end
		local after = GB.Quest.questState(questName)
		local prevCur = type(before) == "table" and before.Current or (type(before) == "number" and before) or 0
		local prevAmt = type(before) == "table" and before.Amount or 0
		if after and after.IsComplete then
			GB.Log.log("QUEST", string.format("kill credited %s/%s -> done", tostring(prevCur), tostring(prevAmt)))
			return true
		end
		local o = after and after.Objective
		if type(before) == "table" and before.StageIndex and after and after.StageIndex and after.StageIndex ~= before.StageIndex then
			GB.Log.log(
				"QUEST",
				string.format("kill credited %s/%s -> stage %s", tostring(prevCur), tostring(prevAmt), tostring(after.StageIndex))
			)
			return true
		end
		if o and type(o.Current) == "number" and o.Current > prevCur then
			GB.Log.log(
				"QUEST",
				string.format("Kill credited %s/%s -> %s/%s", tostring(prevCur), tostring(o.Amount or prevAmt), tostring(o.Current), tostring(o.Amount or prevAmt))
			)
			return true
		end
		local label = M.ActiveTarget and M.ActiveTarget.Name or (M.lockMob and M.lockMob.Name) or "?"
		GB.Log.log("QUEST", "kill not credited target=" .. tostring(label))
		return false
	end

	function M.onTargetDead(target, reason)
		if not target then
			return
		end
		if M._released == target then
			return
		end
		M._released = target
		M.markDead(target, reason)
		if M.ActiveTarget and M.ActiveTarget.Instance == target then
			M.ActiveTarget.Dead = true
			M.ActiveTarget.LastHealth = 0
		end
		local qn = M.lockQuest
		local before = M.lastKillBefore
		M.stopLock()
		if qn then
			local ok = M.logKillCredit(qn, before)
			if ok or M.questCombatDone(qn, { force = true, source = "target_dead" }) then
				M.lastQuestDone = qn
			end
		end
	end

	function M.findTarget(name, questName)
		name = GB.QuestData.killName(questName, name)
		if not name then
			GB.Log.warn("COMBAT", "kill name unresolved")
			return nil
		end
		M.pruneDeadCache()
		if isDummy(name) then
			local d = GB.Resolver.dummy()
			if d and M.IsValidTarget(d, { Name = name }) then
				return d
			end
			return nil
		end
		if GB.Resolver.enemies then
			local list = GB.Resolver.enemies(name)
			if type(list) == "table" then
				for _, inst in ipairs(list) do
					if M.IsValidTarget(inst, { Name = name }) then
						return inst
					end
				end
			end
		end
		local mob = GB.Resolver.enemy(name)
		if mob and M.IsValidTarget(mob, { Name = name }) then
			return mob
		end
		return nil
	end

	local function standDest(mob)
		local part = GB.Resolver.part(mob)
		if not (part and part:IsA("BasePart")) then
			return nil
		end
		local dest
		if isDummy(mob.Name) then
			dest = part.Position + Vector3.new(GB.Config.DummyBeside or 3.2, 0, 0)
		else
			local look = part.CFrame.LookVector
			local off = -Vector3.new(look.X, 0, look.Z)
			if off.Magnitude < 0.2 then
				off = Vector3.new(0, 0, GB.Config.CombatRange or 5.5)
			else
				off = off.Unit * (GB.Config.CombatRange or 5.5)
			end
			dest = part.Position + off
		end
		if not GB.World.destOk(dest) then
			dest = part.Position + Vector3.new(GB.Config.DummyBeside or 3.2, 0, 0)
		end
		if GB.World.floorAt then
			dest = GB.World.floorAt(dest, part.Position.Y) or Vector3.new(dest.X, part.Position.Y, dest.Z)
		end
		return dest, part
	end

	function M.needReposition(mob)
		if not M.IsEnemyAlive(mob) then
			return false
		end
		local root = GB.World.hrp()
		local dest, part = standDest(mob)
		if not (root and dest and part) then
			return false
		end
		local moved = M.lastTargetPos and (M.lastTargetPos - part.Position).Magnitude or 99
		if GB.World.tweenPlaying and GB.World.tweenPlaying() then
			return moved > TARGET_MOVED
		end
		local far = (root.Position - dest).Magnitude > REPOS_DIST
		return far or moved > TARGET_MOVED
	end

	function M.standPose(mob)
		if not M.IsEnemyAlive(mob) then
			return false
		end
		local root = GB.World.hrp()
		local dest, part = standDest(mob)
		if not (root and dest and part) then
			return false
		end
		M.lastTargetPos = part.Position
		M.lastStandAt = os.clock()
		if (root.Position - dest).Magnitude <= 2.2 then
			root.CFrame = CFrame.new(root.Position, Vector3.new(part.Position.X, root.Position.Y, part.Position.Z))
			return true
		end
		if GB.World.tweenTo then
			return GB.World.tweenTo(dest, part.Position, { wait = false, range = 2.2 })
		end
		root.CFrame = CFrame.new(dest, Vector3.new(part.Position.X, dest.Y, part.Position.Z))
		return true
	end

	function M.swing()
		local c = GB.World.char()
		if not c then
			return
		end
		if os.clock() - M.lastSwing < SWING_GAP then
			return
		end
		if not M.canSwing(c) then
			return
		end
		if M.lockMob and not M.IsEnemyAlive(M.lockMob) then
			return
		end
		M.lastSwing = os.clock()
		local atk = loadAttack()
		if atk and atk.Swing then
			atk.Swing(c)
		end
	end

	function M.startLock(mob, questName)
		if not mob or M.isPet(mob) then
			return
		end
		if not M.IsEnemyAlive(mob) then
			M.markDead(mob, "lock")
			return
		end
		if M.lockMob == mob and M.lockConn then
			M.lockQuest = questName or M.lockQuest
			return
		end
		if M.lockConn then
			M.stopLock()
		end
		M.lockMob = mob
		M.setActive(mob, questName)
		GB.Log.log("STATE", string.format("doing=combat target=%s", mob.Name))
		M.lockConn = RunService.Heartbeat:Connect(function()
			if GB.dead and GB.dead() then
				M.stopLock()
				return
			end
			local snap = GB.State and GB.State.get and GB.State.get()
			if snap and snap.Alive == false then
				M.stopLock()
				return
			end
			local mob2 = M.lockMob
			if not mob2 then
				M.stopLock()
				return
			end
			if not M.IsEnemyAlive(mob2) then
				M.onTargetDead(mob2, "poll")
				return
			end
			if M.needReposition(mob2) then
				M.standPose(mob2)
			end
			if M.IsEnemyAlive(mob2) then
				M.swing()
			else
				M.onTargetDead(mob2, "post-swing")
			end
		end)
	end

	function M.hunt(name, questName)
		local mob = M.findTarget(name, questName)
		if not mob then
			return false
		end
		if not M.IsValidTarget(mob, { Name = name }) then
			return false
		end
		GB.Log.log("COMBAT", "Next target " .. tostring(name))
		GB.Log.log("STATE", string.format("doing=combat target=%s", mob.Name))
		if not M.IsEnemyAlive(mob) then
			M.markDead(mob, "pre-travel")
			return false
		end
		if GB.World.ToEnemy then
			if not GB.World.ToEnemy(mob, GB.Config.CombatRange or 5.5) then
				if not M.IsEnemyAlive(mob) then
					M.markDead(mob, "travel")
					return false
				end
				if not GB.World.moveTo(mob, 12) then
					return false
				end
			end
		elseif not GB.World.moveTo(mob, 12) then
			return false
		end
		if not M.IsEnemyAlive(mob) then
			M.markDead(mob, "post-travel")
			return false
		end
		M.startLock(mob, questName)
		return true
	end

	function M.huntUntilDead(name, timeout, questName)
		timeout = timeout or 14
		if questName and GB.Quest then
			local qs = GB.Quest.questState(questName)
			M.lastKillBefore = qs and qs.Objective and {
				Current = qs.Objective.Current or 0,
				Amount = qs.Objective.Amount or 1,
				StageIndex = qs.StageIndex,
			} or nil
		end
		local mob = M.findTarget(name, questName)
		if not M.IsEnemyAlive(mob) then
			return false, "no_enemy"
		end
		if not M.hunt(name, questName) then
			return false, "travel"
		end
		local t0 = os.clock()
		local tracked = M.lockMob or mob
		while os.clock() - t0 < timeout do
			if questName and M.lastQuestDone == questName then
				M.stopLock()
				return true, "quest_done"
			end
			if questName and not M.lockConn and M.questCombatDone(questName, { source = "hunt", force = true }) then
				M.lastQuestDone = questName
				return true, "quest_done"
			end
			local cur = M.lockMob or tracked
			if not M.IsEnemyAlive(cur) then
				if cur then
					M.onTargetDead(cur, "wait")
				else
					M.stopLock()
				end
				return true, "dead"
			end
			task.wait(0.12)
		end
		if not M.IsEnemyAlive(M.lockMob or tracked) then
			M.onTargetDead(M.lockMob or tracked, "timeout-dead")
			return true, "dead"
		end
		return true, "timeout"
	end

	function M.shootStance(mob)
		if not M.IsEnemyAlive(mob) then
			return false
		end
		local root = GB.World.hrp()
		local part = GB.Resolver.part(mob)
		if not (root and part and part:IsA("BasePart")) then
			return false
		end
		local range = GB.Config.ShootRange or 9
		local look = part.CFrame.LookVector
		local off = Vector3.new(look.X, 0, look.Z)
		if off.Magnitude < 0.2 then
			off = Vector3.new(range, 0, 0)
		else
			off = off.Unit * range
		end
		local dest = part.Position + off
		if not GB.World.destOk(dest) then
			dest = part.Position + Vector3.new(range, 0, 0)
		end
		if GB.World.floorAt then
			dest = GB.World.floorAt(dest, part.Position.Y) or Vector3.new(dest.X, part.Position.Y, dest.Z)
		end
		if GB.World.tweenTo then
			GB.World.tweenTo(dest, part.Position, { wait = false, range = 2.5 })
		else
			root.CFrame = CFrame.new(dest, Vector3.new(part.Position.X, dest.Y, part.Position.Z))
		end
		if GB.Skills and GB.Skills.aimAt then
			GB.Skills.aimAt(mob)
		end
		return true
	end

	function M.shootUntilCredit(name, questName, timeout)
		timeout = timeout or 22
		local skill = (GB.Skills and GB.Skills.resolveShootSkill and GB.Skills.resolveShootSkill()) or "Gunshot"
		if questName and GB.Quest then
			local qs = GB.Quest.questState(questName)
			M.lastKillBefore = qs and qs.Objective and {
				Current = qs.Objective.Current or 0,
				Amount = qs.Objective.Amount or 1,
				StageIndex = qs.StageIndex,
			} or nil
		end
		M.stopLock()
		local mob = M.findTarget(name, questName)
		if not M.IsEnemyAlive(mob) then
			return false, "no_enemy"
		end
		GB.Log.log("COMBAT", "Shoot " .. skill .. " -> " .. tostring(mob.Name))
		if GB.World.ToEnemy then
			GB.World.ToEnemy(mob, GB.Config.ShootRange or 9)
		end
		M.shootStance(mob)
		local t0 = os.clock()
		while os.clock() - t0 < timeout do
			if questName and M.questCombatDone(questName) then
				M.logKillCredit(questName, M.lastKillBefore)
				return true, "quest_done"
			end
			mob = M.findTarget(name, questName) or mob
			if not M.IsEnemyAlive(mob) then
				return false, "no_enemy"
			end
			M.shootStance(mob)
			if GB.Skills and GB.Skills.castHold then
				GB.Skills.castHold(skill, {
					keepLock = true,
					target = mob,
					hold = 0.5,
					cooldown = 6.1,
				})
			end
			task.wait(0.9)
			if questName and M.questCombatDone(questName) then
				M.logKillCredit(questName, M.lastKillBefore)
				return true, "quest_done"
			end
			task.wait(5.2)
		end
		if questName and M.questCombatDone(questName) then
			M.logKillCredit(questName, M.lastKillBefore)
			return true, "quest_done"
		end
		return false, "timeout"
	end

	function M.attack(name, questName)
		if questName then
			local qs = GB.Quest.questState(questName)
			local typ = qs and qs.Objective and qs.Objective.Type
			if typ and not M.KillTypes[typ] then
				M.stopLock()
				return false
			end
			M.lastKillBefore = qs and qs.Objective and {
				Current = qs.Objective.Current or 0,
				Amount = qs.Objective.Amount or 1,
				StageIndex = qs.StageIndex,
			} or nil
		end
		return M.hunt(name, questName)
	end

	function M.waitPermission(kind, timeout)
		timeout = timeout or 1.6
		local t0 = os.clock()
		while os.clock() - t0 < timeout do
			local c = GB.World.char()
			if c then
				if kind == "dodge" and M.canDodge(c) then
					return true
				end
				if kind == "swing" and M.canSwing(c) then
					return true
				end
			end
			task.wait(0.08)
		end
		return false
	end

	function M.dash()
		M.stopLock()
		if os.clock() - M.lastDash < 0.55 then
			return false
		end
		if not M.waitPermission("dodge", 1.6) then
			GB.Log.warn("COMBAT", "dash blocked CanDodge")
			return false
		end
		local ev = pressKey()
		if not ev then
			GB.Log.warn("COMBAT", "PressKey missing")
			return false
		end
		M.lastDash = os.clock()
		ev:Fire(Enum.KeyCode.Q)
		GB.Log.log("COMBAT", "Dash Q")
		return true
	end

	function M.block(hold)
		M.stopLock()
		if os.clock() - M.lastBlock < 0.7 then
			return false
		end
		local ev = pressKey()
		if not ev then
			GB.Log.warn("COMBAT", "PressKey missing")
			return false
		end
		M.lastBlock = os.clock()
		ev:Fire(Enum.KeyCode.F, Enum.KeyCode)
		task.wait(hold or 0.7)
		ev:Fire(Enum.KeyCode.F, Enum.KeyCode, false)
		GB.Log.log("COMBAT", "Block F")
		return true
	end

	function M.validateKill(name, questName, before)
		local live = GB.PlayerData.live(questName)
		if not live then
			return true
		end
		if GB.PlayerData.finished(questName, true) then
			return true
		end
		local _, st = GB.QuestData.currentStage(live)
		if not st then
			return true
		end
		if st.Complete then
			return true
		end
		local conds = st.Conditions or st.conditions or {}
		for _, cond in ipairs(conds) do
			if type(cond) == "table" and not cond.Complete then
				local cur = GB.QuestData.conditionCurrent(cond)
				local prev = type(before) == "number" and before or 0
				return cur > prev
			end
		end
		return false
	end

	function M.tick()
		M.pruneDeadCache()
		if M.lockMob then
			if not M.IsEnemyAlive(M.lockMob) then
				M.onTargetDead(M.lockMob, "tick")
			elseif M.lockQuest and M.questCombatDone(M.lockQuest, { source = "combat_tick" }) then
				M.lastQuestDone = M.lockQuest
				M.stopLock()
			end
		end
	end

	return M
end
]],
    ["Systems/Equipment.lua"] = [[-- DIRECT_EQUIP = HeldItem Equip (hotbar hold).
-- UI_EQUIP = backpack open + SaveOrder(slot, key) — same path as drag-to-gear.
-- Gearing Up Equip Flintlock is UI_EQUIP: HeldItem does not credit the quest.

return function(GB)
	local M = {
		lastUi = 0,
		lastDirect = 0,
		lastStrategy = nil,
	}

	local WEAPON_ITEMS = {
		Flintlock = true,
		Cutlass = true,
	}

	local function findInvKey(name)
		local inv = GB.PlayerData.cache().Inventory
		if type(inv) ~= "table" then
			return name
		end
		if inv[name] then
			local row = inv[name]
			return (type(row) == "table" and (row.Key or row.Name)) or name
		end
		for k, v in pairs(inv) do
			if type(v) == "table" and (v.Name == name or v.Key == name) then
				return v.Key or k or name
			end
		end
		return name
	end

	function M.heldName()
		local char = GB.World and GB.World.char and GB.World.char()
		if not char then
			return nil
		end
		local tool = char:FindFirstChildOfClass("Tool")
		if tool then
			return tool:GetAttribute("ItemName") or tool.Name
		end
		return nil
	end

	function M.equipmentState(name)
		local owned, amt = GB.PlayerData.hasItem(name)
		local equipped = GB.Backpack and GB.Backpack.isGearEquipped and GB.Backpack.isGearEquipped(name)
		local held = M.heldName() == name
		local qs = GB.Quest and GB.PlayerData.current and GB.Quest.questState(GB.PlayerData.current())
		local credited = false
		if qs and qs.Objective and qs.Objective.Type == "Equip" and qs.Objective.TargetName == name then
			credited = (qs.Objective.Current or 0) >= (qs.Objective.Amount or 1) or qs.Objective.Complete == true
		elseif qs and qs.IsComplete then
			credited = true
		end
		return {
			Owned = owned == true,
			Amount = amt or 0,
			Selected = held,
			Equipped = equipped == true,
			Held = held,
			QuestCredited = credited,
		}
	end

	function M.needsGearSlot(name)
		if WEAPON_ITEMS[name] then
			return true
		end
		local kind = GB.ItemData and GB.ItemData.kind and GB.ItemData.kind(name)
		return kind == "EQUIP" and name ~= "Transponder Snail" and name ~= "Rusty Pickaxe" and name ~= "Rusty Shovel"
	end

	function M.equipViaBackpack(name)
		if not name then
			return false
		end
		if os.clock() - M.lastUi < 0.9 then
			return false
		end
		M.lastUi = os.clock()
		M.lastStrategy = "UI_EQUIP"
		if GB.Combat and GB.Combat.stopLock then
			GB.Combat.stopLock()
		end
		if GB.Backpack and not GB.Backpack.isOpen() then
			GB.Backpack.open()
			task.wait(0.15)
		end
		if GB.Backpack and GB.Backpack.isGearEquipped(name) then
			return true
		end
		local key = findInvKey(name)
		local slot = WEAPON_ITEMS[name] and "Weapon2" or "Weapon2"
		if name == "Cutlass" then
			slot = "Weapon1"
		end
		GB.Log.log("EQUIP", string.format("Selecting %s", tostring(name)))
		GB.Log.log("EQUIP", string.format("Equipping %s slot=%s", tostring(key), tostring(slot)))
		local ok = GB.Remotes.saveOrder(slot, key)
		if WEAPON_ITEMS[name] then
			task.wait(0.2)
			if GB.Backpack and not GB.Backpack.isGearEquipped(name) then
				GB.Remotes.saveOrder("Weapon1", key)
			end
		end
		task.wait(0.25)
		return ok or (GB.Backpack and GB.Backpack.isGearEquipped(name))
	end

	function M.equipDirect(name)
		if not name then
			return false
		end
		if os.clock() - M.lastDirect < 0.7 then
			return false
		end
		M.lastDirect = os.clock()
		M.lastStrategy = "DIRECT_EQUIP"
		local key = findInvKey(name)
		GB.Log.log("EQUIP", "HeldItem Equip " .. tostring(key))
		return GB.Remotes.heldEquip(key)
	end

	function M.equipNamed(name, opts)
		opts = opts or {}
		if not name then
			return false
		end
		if not GB.PlayerData.hasItem(name) then
			return false
		end
		local st = M.equipmentState(name)
		if st.QuestCredited then
			return true
		end
		local gate = GB.Tutorial and GB.Tutorial.IsBlocking and GB.Tutorial.IsBlocking()
		local mode = opts.Mode
		if not mode then
			if opts.QuestEquip or gate or M.needsGearSlot(name) then
				mode = "UI_EQUIP"
			else
				mode = "DIRECT_EQUIP"
			end
		end
		if st.Equipped and not st.QuestCredited then
			GB.Log.log("EQUIP", tostring(name) .. " equipped but quest not credited")
			if gate and GB.Tutorial and GB.Tutorial.ExecuteCurrentStep then
				return GB.Tutorial.ExecuteCurrentStep()
			end
			if mode ~= "UI_EQUIP" then
				mode = "UI_EQUIP"
			end
		elseif st.Held and not st.Equipped and not st.QuestCredited and M.needsGearSlot(name) then
			GB.Log.log("EQUIP", tostring(name) .. " equipped but quest not credited")
			mode = "UI_EQUIP"
		end
		if mode == "UI_EQUIP" then
			return M.equipViaBackpack(name)
		end
		return M.equipDirect(name)
	end

	function M.upgradeNamed(name)
		local key = findInvKey(name or "Flintlock")
		local anvil = GB.Resolver.taggedAny and GB.Resolver.taggedAny("Anvil") or GB.Resolver.byName("Anvil")
		if anvil and GB.World.ToInteractable then
			GB.World.ToInteractable(anvil, 8)
			local pr = GB.Resolver.prompt(anvil)
			if pr then
				GB.World.firePrompt(pr)
			end
		end
		GB.Log.log("EQUIP", "Upgrade " .. tostring(key))
		local ok = GB.Remotes.upgrade(key)
		task.wait(0.3)
		return ok
	end

	function M.tick()
		if not GB.Config.AutoEquip then
			return
		end
		if GB.Tutorial and GB.Tutorial.IsBlocking and GB.Tutorial.IsBlocking() then
			return
		end
		if GB.PlayerData.live("A Voice in a Shell") and GB.PlayerData.hasItem("Transponder Snail") then
			local st = M.equipmentState("Transponder Snail")
			if not (st.Held or st.Equipped or st.QuestCredited) then
				M.equipDirect("Transponder Snail")
			end
		end
		if GB.PlayerData.live("First Upgrade") and GB.PlayerData.hasItem("Rusty Pickaxe") then
			local st = M.equipmentState("Rusty Pickaxe")
			if not (st.Held or st.Equipped) then
				M.equipDirect("Rusty Pickaxe")
			end
		end
	end

	return M
end
]],
    ["Systems/Fruit.lua"] = [[-- KEEP_CURRENT default. PickupDF(FruitId) VERIFIED.
-- Store/equip via PermanentFruit. Eat = tool activate (server Prompt) — do not eat blindly.

return function(GB)
	local CS = game:GetService("CollectionService")
	local M = {}
	local DEEP_SCAN_GAP = 8

	local function perfCount(name, n)
		if GB.Profiler and GB.Profiler.count then
			GB.Profiler.count(name, n or 1)
		end
	end

	local function isFruit(inst)
		return inst
			and inst.Parent
			and inst:GetAttribute("FruitId")
			and inst:GetAttribute("Interaction") == "Devil Fruit"
	end

	local function taggedFruit()
		for _, tag in ipairs({ "Devil Fruit", "Drop", "DroppedItem", "ClientInteractable" }) do
			local ok, tagged = pcall(CS.GetTagged, CS, tag)
			if ok and type(tagged) == "table" then
				for _, inst in ipairs(tagged) do
					if isFruit(inst) then
						return inst
					end
				end
			end
		end
		return nil
	end

	local function folderFruit()
		for _, folderName in ipairs({ "Drops", "DroppedItems", "QuestItems", "WorldDrops" }) do
			local root = workspace:FindFirstChild(folderName)
			if root then
				for _, child in ipairs(root:GetChildren()) do
					if isFruit(child) then
						return child
					end
				end
			end
		end
		return nil
	end

	function M.pickupNearby()
		local found = taggedFruit() or folderFruit()
		if not found and os.clock() - (M._deepAt or 0) >= DEEP_SCAN_GAP then
			M._deepAt = os.clock()
			perfCount("WorkspaceDeepScan", 1)
			pcall(function()
				for _, d in ipairs(workspace:GetDescendants()) do
					if isFruit(d) then
						found = d
						break
					end
				end
			end)
		end
		if not found then
			return false
		end
		if not GB.World.moveTo(found, 10) then
			return false
		end
		local id = found:GetAttribute("FruitId")
		GB.Log.log("FRUIT", "PickupDF " .. tostring(id))
		return GB.Remotes.pickupFruit(id)
	end

	function M.tick()
		if not GB.Config.AutoFruit then
			return
		end
		M.pickupNearby()
		local snap = GB.State.get()
		if GB.Config.FruitMode ~= "DesiredFruits" then
			return
		end
		-- Eat path unverified as a dedicated remote (tool ServerActivated + Prompt).
		-- Do not Fire eat. Store current if Desired differs and Closet store is safe.
		local want = GB.Config.DesiredFruits
		if type(want) ~= "table" or not snap.Fruit then
			return
		end
		local desired
		for _, n in ipairs(want) do
			if n == snap.Fruit then
				return
			end
			if GB.ItemData.FRUITS[n] then
				desired = desired or n
			end
		end
		if desired and snap.Fruit ~= desired then
			GB.Log.log("FRUIT", "KEEP_CURRENT override — eat disabled; store via Closet only if you hold desired")
		end
	end

	return M
end
]],
    ["Systems/Haki.lua"] = [[-- Trainer / unlock quests UNRESOLVED after Studio search (no HakiTrainer, no Haki quest).
-- RerollAuraColor:FireServer() is color product, not unlock.

return function(GB)
	local M = { disabled = true, reason = "UNRESOLVED trainer/reqs" }

	function M.tick()
		if not GB.Config.AutoHaki then
			return
		end
		-- remain disabled even if flag flipped without evidence
		if M.disabled then
			return
		end
	end

	return M
end
]],
    ["Systems/LifeSkills.lua"] = [[-- Mining: hold MouseButton1 through the QTE bar, release in the crit zone.
-- EquipAndActivateBindable("Pickaxe") only starts the swing — a tap cancels the charge.
-- PickaxeHit args stay on the tool client. Do not invent them.

return function(GB)
	local RS = game:GetService("ReplicatedStorage")
	local VIM = game:GetService("VirtualInputManager")
	local RunService = game:GetService("RunService")
	local M = {
		_busy = false,
		_mouse = false,
	}

	local function fireActivate(kind)
		local b = RS:FindFirstChild("Events") and RS.Events:FindFirstChild("EquipAndActivateBindable")
		if not b then
			return false
		end
		return pcall(function()
			b:Fire(kind)
		end)
	end

	local function pickaxeName()
		for _, n in ipairs({
			"Rusty Pickaxe",
			"Steel Pickaxe",
			"Silver Pickaxe",
			"Golden Pickaxe",
			"Obsidian Pickaxe",
			"Emerald Pickaxe",
			"Diamond Pickaxe",
		}) do
			if GB.PlayerData.hasItem(n) then
				return n
			end
		end
		return nil
	end

	local function oreHp(ore)
		if not ore then
			return nil
		end
		local n
		pcall(function()
			n = ore:GetAttribute("Health") or ore:GetAttribute("HP") or ore:GetAttribute("OreHealth")
		end)
		if type(n) == "number" then
			return n
		end
		local hum = ore:FindFirstChildOfClass("Humanoid")
		if hum then
			return hum.Health
		end
		return nil
	end

	local function distTo(ore)
		local root = GB.World and GB.World.hrp and GB.World.hrp()
		local pos = ore and GB.Resolver.positionOf and GB.Resolver.positionOf(ore)
		if not (root and pos) then
			return math.huge
		end
		return (root.Position - pos).Magnitude
	end

	local function chargeGui()
		local char = GB.World and GB.World.char and GB.World.char()
		if not char then
			return nil
		end
		local pp = char.PrimaryPart or char:FindFirstChild("HumanoidRootPart")
		if pp then
			local g = pp:FindFirstChild("Mining")
			if g and g:FindFirstChild("Frame") then
				return g
			end
		end
		for _, d in ipairs(char:GetDescendants()) do
			if d.Name == "Mining" and d:FindFirstChild("Frame") then
				return d
			end
		end
		return nil
	end

	-- QTE cursor is 1 - Amount.Scale.Y. Zone is Critical Zone Y scale + height.
	local function inCritZone(gui)
		local frame = gui and gui:FindFirstChild("Frame")
		local amount = frame and frame:FindFirstChild("Amount")
		local zone = frame and frame:FindFirstChild("Critical Zone")
		if not (amount and zone) then
			return false, 0
		end
		local fill = amount.Size.Y.Scale
		local cursor = 1 - fill
		local top = zone.Position.Y.Scale
		local bot = top + zone.Size.Y.Scale
		return cursor >= top and cursor <= bot, fill
	end

	local function mouseAt(down)
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
		local x, y = vp.X * 0.5, vp.Y * 0.58
		pcall(function()
			if VIM.SendMouseMoveEvent then
				VIM:SendMouseMoveEvent(x, y, game)
			end
			VIM:SendMouseButtonEvent(x, y, 0, down, game, 1)
		end)
		M._mouse = down
	end

	local function waitClearStun(sec)
		local char = GB.World and GB.World.char and GB.World.char()
		if not char then
			return
		end
		local ok, SS = pcall(function()
			return require(RS.Modules.StateService)
		end)
		if not (ok and type(SS) == "table" and SS.CheckForState) then
			return
		end
		local t0 = os.clock()
		while os.clock() - t0 < (sec or 1.2) do
			local stunned
			pcall(function()
				stunned = SS.CheckForState(char, "Stun")
			end)
			if not stunned then
				return
			end
			task.wait(0.08)
		end
	end

	local function waitReleaseWindow()
		local t0 = os.clock()
		local seen = false
		while os.clock() - t0 < 2.4 do
			local gui = chargeGui()
			if gui then
				seen = true
				local hit, fill = inCritZone(gui)
				if hit then
					return true, fill
				end
				if fill >= 0.93 then
					return true, fill
				end
			elseif seen then
				return false, 0
			elseif os.clock() - t0 > 0.9 then
				return false, 0
			end
			RunService.RenderStepped:Wait()
		end
		return seen, 0
	end

	function M.mineToward(target)
		if not GB.Config.AutoMining then
			return false
		end
		if M._busy then
			return true
		end
		if GB.State and GB.State.tutorialOverlayVisible and GB.State.tutorialOverlayVisible() then
			if GB.State.dismissTutorialOverlay then
				GB.State.dismissTutorialOverlay()
			end
			return false
		end
		M._busy = true
		local ok = false
		local did = pcall(function()
			if GB.Combat and GB.Combat.stopLock then
				GB.Combat.stopLock()
			end
			local axe = pickaxeName()
			if axe and (not GB.Equipment.heldName or GB.Equipment.heldName() ~= axe) then
				GB.Equipment.equipNamed(axe)
				task.wait(0.15)
			end
			local ore = GB.Resolver.byName(target) or GB.Resolver.ore()
			if not ore then
				GB.Log.warn("MINING", "ore miss " .. tostring(target))
				return
			end
			if distTo(ore) > 7 then
				if GB.World.ToInteractable then
					GB.World.ToInteractable(ore, 5)
				else
					GB.World.moveTo(ore, 7)
				end
				task.wait(0.2)
			end
			waitClearStun(1.2)
			if GB.Skills and GB.Skills.aimAt then
				GB.Skills.aimAt(ore)
			end
			local hp0 = oreHp(ore)
			mouseAt(true)
			task.wait(0.06)
			fireActivate("Pickaxe")
			GB.Log.log("MINING", "hold charge at " .. ore.Name)
			local released, fill = waitReleaseWindow()
			mouseAt(false)
			GB.Log.log(
				"MINING",
				string.format("release fill=%.2f zone=%s", tonumber(fill) or 0, released and "yes" or "timeout")
			)
			task.wait(0.85)
			local hp1 = oreHp(ore)
			if hp0 and hp1 and hp1 < hp0 then
				GB.Log.log("MINING", string.format("hit hp %s->%s", tostring(hp0), tostring(hp1)))
				if GB.Recovery and GB.Recovery.markSuccess then
					GB.Recovery.markSuccess()
				end
			end
			ok = true
		end)
		if M._mouse then
			mouseAt(false)
		end
		M._busy = false
		return did and ok
	end

	function M.smeltToward(target)
		if target == "Copper Bar" or target == "Copper Ore" then
			local has = GB.PlayerData.hasItem and select(1, GB.PlayerData.hasItem("Copper Ore"))
			if not has then
				GB.Log.warn("SMELT", "need Copper Ore")
				return false
			end
		end
		local station = (GB.Resolver.taggedAny and GB.Resolver.taggedAny("Furnace")) or GB.Resolver.byName("Furnace")
		if not station then
			GB.Log.warn("SMELT", "furnace miss " .. tostring(target))
			return false
		end
		if GB.World.interact then
			GB.World.interact(station, 8)
		else
			GB.World.moveTo(station, 8)
		end
		GB.Log.log("SMELT", tostring(target) .. " at Furnace")
		return true
	end

	function M.fishToward(target)
		if not GB.Config.AutoFishing then
			return false
		end
		local rod = GB.PlayerData.hasItem("Carbon Rod") and "Carbon Rod" or (GB.PlayerData.hasItem("Wooden Rod") and "Wooden Rod")
		if rod then
			GB.Equipment.equipNamed(rod)
		end
		local shop = GB.Resolver.byName("Anchor Town Fishing Shop") or GB.Resolver.shopItem("Wooden Rod")
		if shop then
			GB.World.moveTo(shop, 12)
		end
		GB.Log.log("FISHING", "at water for " .. tostring(target) .. " (cast remote args UNRESOLVED)")
		return true
	end

	function M.farmToward(typ, target)
		if not GB.Config.AutoFarming then
			return false
		end
		local obj = GB.Resolver.byName(target) or GB.Resolver.byName("Seed")
		if obj then
			GB.World.moveTo(obj, 8)
			local pr = GB.Resolver.prompt(obj)
			if pr then
				GB.World.firePrompt(pr)
			end
			return true
		end
		GB.Log.warn("FARMING", typ .. " miss " .. tostring(target))
		return false
	end

	function M.cookToward(target)
		if not GB.Config.AutoCooking then
			return false
		end
		local obj = GB.Resolver.byName(target) or GB.Resolver.byName("Remy")
		if obj then
			GB.World.moveTo(obj, 8)
			return true
		end
		return false
	end

	function M.tick()
	end

	return M
end
]],
    ["Systems/Quest.lua"] = [[-- Generic executor: GetLiveQuest → Stage → ParseObjective → Resolve → Execute → Validate.
-- Talk: ClientQuest("Talk", DisplayName) + DialogueBindable(Configuration). Never BeginQuest.

return function(GB)
	local M = {
		lastTalk = {},
		lastClick = 0,
		track = {},
		unknown = {},
		lastSig = {},
		diagByFingerprint = {},
		detailByFingerprint = {},
		deferUntil = {},
		deferReason = {},
	}

	M.STATUS = {
		READY = "READY",
		IN_PROGRESS = "IN_PROGRESS",
		BLOCKED_REQUIREMENT = "BLOCKED_REQUIREMENT",
		DEFERRED = "DEFERRED",
		COMPLETE = "COMPLETE",
		UNRESOLVED = "UNRESOLVED",
	}

	local DETAIL_DUMP_GAP = 45
	local DIAG_DUMP_GAP = 45
	local TRACK_LIMIT = 96
	local FAIL_FINGERPRINT_GAP = 1.2
	local FAIL_DEFER_GAP = 30

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

	local DECLINE = {
		Decline = true,
		["Good luck with"] = true,
		Bye = true,
		No = true,
		Cancel = true,
	}

	local HANDLED = {
		Talk = true,
		["Automatic Talk"] = true,
		Kill = true,
		Defeat = true,
		Hit = true,
		Destroy = true,
		Shoot = true,
		Purchase = true,
		Sell = true,
		Equip = true,
		Upgrade = true,
		EquipSkill = true,
		Cast = true,
		Required = true,
		Collect = true,
		CollectLocal = true,
		CollectLocalItem = true,
		Loot = true,
		Mine = true,
		Smelt = true,
		Fish = true,
		Plant = true,
		Harvest = true,
		Water = true,
		Fertilize = true,
		Cook = true,
		["Perfect Cook"] = true,
		Craft = true,
		Deliver = true,
		Donate = true,
		GiveItemTo = true,
		Interact = true,
		Investigate = true,
		Wake = true,
		["Check On"] = true,
		Open = true,
		Free = true,
		Visit = true,
		Reach = true,
		Spawn = true,
		Escort = true,
		Dash = true,
		Block = true,
		Travel = true,
		Boss = true,
		Unlock = true,
		["Deliver Object"] = true,
		["Reach Maple Village"] = true,
		["Investigate The Footsteps (1)"] = true,
		["Investigate The Footsteps (2)"] = true,
		["Investigate The Wreckage"] = true,
		["Investigate The Beast's Den"] = true,
		["Investigate The Garden"] = true,
		["Investigate The Fountain"] = true,
		Defend = true,
	}

	local function guiText(inst)
		return GB.State.guiText(inst)
	end

	local function isDecline(t)
		if type(t) ~= "string" then
			return false
		end
		for bad in pairs(DECLINE) do
			if string.find(t, bad, 1, true) then
				return true
			end
		end
		return false
	end

	local function isAcceptText(t)
		if type(t) ~= "string" then
			return false
		end
		if string.find(t, "Accept", 1, true) then
			return true
		end
		if string.find(t, "Thank", 1, true) then
			return true
		end
		if string.find(t, "Yes", 1, true) then
			return true
		end
		-- Officer Graves Dialogue.Definition FirstAgree — Introduction first node
		if string.find(t, "I can help change that", 1, true) then
			return true
		end
		if string.find(t, "upgrade my flintlock", 1, true) then
			return true
		end
		if string.find(t, "I need you", 1, true) then
			return true
		end
		return false
	end

	local function dialogueOpen()
		local pg = GB.lp and GB.lp.PlayerGui
		local ui = pg and pg:FindFirstChild("DialogueUI")
		if not ui then
			return false
		end
		if ui:IsA("LayerCollector") and ui.Enabled ~= true then
			return false
		end
		local main = ui:FindFirstChild("Main")
		if main then
			for _, frame in ipairs(main:GetChildren()) do
				if frame:IsA("Frame") and frame:FindFirstChildWhichIsA("GuiButton", true) then
					return true
				end
			end
		end
		return ui:IsA("LayerCollector") and ui.Enabled == true
	end

	-- Choices live in DialogueUI.Main as cloned NodeFrames. ImageButton has no .Text;
	-- label is sibling TextLabel. Template under DialogueHandler.NodeFrame is not clickable.
	local function clickAccept()
		local pg = GB.lp and GB.lp.PlayerGui
		local ui = pg and pg:FindFirstChild("DialogueUI")
		if not ui then
			return false
		end
		local main = ui:FindFirstChild("Main")
		if not main then
			return false
		end
		local candidates = {}
		for _, frame in ipairs(main:GetChildren()) do
			if frame:IsA("Frame") then
				local btn = frame:FindFirstChild("ImageButton")
				if btn and btn:IsA("GuiButton") then
					local t = guiText(frame) or guiText(btn) or ""
					if not isDecline(t) then
						local num = frame:FindFirstChild("Number")
						local ntext = ""
						if num and (num:IsA("TextLabel") or num:IsA("TextButton") or num:IsA("TextBox")) then
							ntext = num.Text
						end
						candidates[#candidates + 1] = {
							btn = btn,
							text = t,
							first = frame.Name == "1" or frame.Name == 1 or (type(ntext) == "string" and string.sub(ntext, 1, 1) == "1"),
							glow = frame:FindFirstChild("Quest Glow") ~= nil,
						}
					end
				end
			end
		end
		local pick
		for _, c in ipairs(candidates) do
			if isAcceptText(c.text) or c.glow then
				pick = c
				break
			end
		end
		if not pick then
			for _, c in ipairs(candidates) do
				if c.first then
					pick = c
					break
				end
			end
		end
		pick = pick or candidates[1]
		if not pick then
			return false
		end
		local shown = pick.text
		if shown == "" then
			shown = pick.btn.Name
		end
		GB.Log.log("QUEST", "Click " .. tostring(shown))
		return GB.State.clickGui(pick.btn)
	end

	local function clickPlayerGuiPath(path)
		local pg = GB.lp and GB.lp.PlayerGui
		if not (pg and type(path) == "string") then
			return false
		end
		local cur = pg
		for part in string.gmatch(path, "[^%.]+") do
			cur = cur:FindFirstChild(part)
			if not cur then
				return false
			end
		end
		if cur:IsA("GuiButton") then
			return GB.State.clickGui(cur)
		end
		local btn = cur:FindFirstChildWhichIsA("GuiButton", true)
		return btn and GB.State.clickGui(btn)
	end

	local function layerOn(name)
		local pg = GB.lp and GB.lp.PlayerGui
		local ui = pg and pg:FindFirstChild(name)
		return ui and ui:IsA("LayerCollector") and ui.Enabled == true
	end

	local function rememberUnknown(key, line)
		if M.unknown[key] then
			return
		end
		M.unknown[key] = { at = os.clock() }
		local count = 0
		local dropKey
		local dropAt
		for k, v in pairs(M.unknown) do
			count = count + 1
			local at = type(v) == "table" and (v.at or 0) or 0
			if not dropAt or at < dropAt then
				dropAt = at
				dropKey = k
			end
		end
		if count > TRACK_LIMIT and dropKey then
			M.unknown[dropKey] = nil
		end
		GB.Log.err("QUEST", line)
	end

	-- ForceOpenLogbook sequence + OpenLogbookHelp:FireServer
	local function openLogbook()
		if not layerOn("Menu") then
			clickPlayerGuiPath("TopbarStandard.Holders.Left.Menu")
			task.wait(0.2)
		end
		if not layerOn("Logbook") then
			clickPlayerGuiPath("Menu.ContainerFrame.Icons.Logbook")
			task.wait(0.25)
		end
		clickPlayerGuiPath("Logbook.Frame.IndexContainer.ScrollingFrame.Tutorial")
		task.wait(0.2)
		clickPlayerGuiPath("Logbook.Frame.Left.Tutorial.Controls")
		task.wait(0.15)
		local ok = GB.Remotes.openLogbookHelp()
		GB.Log.log("QUEST", "Open Logbook")
		return ok or layerOn("Logbook")
	end

	local function goTagged(tag, dist)
		if not tag or tag == "" then
			return false
		end
		local inst = GB.Resolver.taggedAny and GB.Resolver.taggedAny(tag)
		if not inst then
			inst = GB.Resolver.waitTagged(tag, 0.8)
		end
		if not inst then
			inst = GB.Resolver.byName(tag)
		end
		if not inst then
			GB.Log.warn("QUEST", "marker miss " .. tostring(tag))
			return false
		end
		if GB.World.interact then
			GB.World.interact(inst, dist or 10)
		else
			GB.World.ToInteractable(inst, dist or 10)
			local pr = GB.Resolver.prompt(inst)
			if pr then
				GB.World.firePrompt(pr)
			end
		end
		GB.Remotes.enterZone(tag)
		return true
	end

	local function gateRequirement()
		local req = GB.QuestData and GB.QuestData.questRequirement and GB.QuestData.questRequirement("Gate of Authority")
		local need = tonumber(req and req.Strength) or 100
		return need, req
	end

	local function readStrength()
		if GB.Stats and GB.Stats.ReadStatState then
			local st = GB.Stats.ReadStatState()
			return tonumber(st and st.Strength) or 0
		end
		local snap = GB.State.get()
		return tonumber((snap and snap.Stats and snap.Stats.Strength) or 0)
	end

	local function resolveMarineGate()
		local pack = GB.Resolver.resolveObject and GB.Resolver.resolveObject("Marine Gate", {
			Island = "Anchor Town",
			deep = true,
		})
		if pack and pack.Instance then
			local pr = GB.Resolver.prompt(pack.Instance, "Pushable Door") or GB.Resolver.prompt(pack.Instance)
			return pack.Instance, pr
		end
		local islands = workspace:FindFirstChild("Islands")
		local anchorTown = islands and islands:FindFirstChild("Anchor Town")
		local island = anchorTown and anchorTown:FindFirstChild("Island")
		local gate = island and island:FindFirstChild("Gate")
		if gate then
			local pr = GB.Resolver.prompt(gate, "Pushable Door") or GB.Resolver.prompt(gate)
			return gate, pr
		end
		return nil, nil
	end

	local function gateBlocker()
		local need = gateRequirement()
		local str = readStrength()
		if str < need then
			return true, string.format("Strength %d/%d", str, need), {
				Goal = "Gate of Authority",
				Type = "STAT_REQUIREMENT",
				Stat = "Strength",
				Required = need,
				Current = str,
				Status = M.STATUS.BLOCKED_REQUIREMENT,
			}
		end
		return false, nil, nil
	end

	-- Gate objective can be credit-on-open while nearby. Interact if possible, otherwise hold near the gate.
	local function waitAtMarineGate(questName, inst)
		local blocked, _, blocker = gateBlocker()
		if blocked then
			GB.Log.warn(
				"QUEST",
				string.format("Gate of Authority BLOCKED Strength=%d/%d", blocker.Current, blocker.Required)
			)
			return false, "blocked"
		end
		local qs = M.questState(questName)
		local before = M.signature(qs)
		local anchor = inst:FindFirstChild("Anchor")
		local stand = (anchor and anchor:IsA("BasePart") and anchor.Position)
			or select(1, GB.Resolver.promptAnchor(inst))
		if stand and GB.World.tweenTo then
			GB.World.tweenTo(stand, nil, { wait = true, range = 6 })
		elseif stand then
			GB.World.setPos(stand, { MaxGroundY = stand.Y + 8 })
		else
			GB.World.ToInteractable(inst, 6)
		end
		local pr = GB.Resolver.prompt(inst, "Pushable Door") or GB.Resolver.prompt(inst)
		if pr then
			GB.World.firePrompt(pr, pr.HoldDuration or 0, inst)
		elseif GB.World.interact then
			GB.World.interact(inst, 6)
		end
		if M.waitProgress(questName, before, 7.5) then
			M._gateWaitUntil = nil
			M.noteOk(questName)
			return true
		end
		M._gateWaitUntil = os.clock() + 18
		if not M._gateSealAt or os.clock() - M._gateSealAt > 8 then
			M._gateSealAt = os.clock()
			GB.Log.log("QUEST", "Gate still sealed, defer and run other goals")
		end
		return false
	end

	function M.deferred(name)
		local untilAt = M.deferUntil[name]
		if untilAt and untilAt > os.clock() then
			return true, M.deferReason[name] or "deferred_after_fail"
		end
		if name == "Gate of Authority" then
			local blocked, why = gateBlocker()
			if blocked then
				return true, why
			end
			if (M._gateWaitUntil or 0) > os.clock() then
				return true, "gate sealed waiting window"
			end
		end
		return false
	end

	function M.CurrentBlockers()
		local out = {}
		local names = GB.PlayerData.activeNames and GB.PlayerData.activeNames() or {}
		local cur = GB.PlayerData.current and GB.PlayerData.current() or nil
		if type(cur) == "string" and cur ~= "" and not table.find(names, cur) then
			names[#names + 1] = cur
		end
		for _, name in ipairs(names) do
			if name == "Gate of Authority" then
				local blocked, _, blocker = gateBlocker()
				if blocked and blocker then
					out[#out + 1] = blocker
				end
			end
		end
		return out
	end

	function M.questStatus(name)
		local qs = M.questState(name)
		if not qs then
			return M.STATUS.UNRESOLVED, "missing"
		end
		if qs.IsComplete then
			return M.STATUS.COMPLETE, nil
		end
		local blocked, why = M.deferred(name)
		if blocked then
			if why == "gate sealed waiting window" or why == "deferred_after_fail" then
				return M.STATUS.DEFERRED, why
			end
			return M.STATUS.BLOCKED_REQUIREMENT, why
		end
		if qs.IsAccepted then
			return M.STATUS.IN_PROGRESS, nil
		end
		return M.STATUS.READY, nil
	end

	function M.condProgress(cond)
		return GB.QuestData.conditionCurrent(cond), GB.QuestData.conditionAmount(cond)
	end

	local function collectGuiText(root, out, budget)
		if not (root and out and budget and budget > 0) then
			return budget or 0
		end
		for _, c in ipairs(root:GetChildren()) do
			if budget <= 0 then
				break
			end
			if (c:IsA("TextLabel") or c:IsA("TextButton") or c:IsA("TextBox")) and type(c.Text) == "string" and c.Text ~= "" then
				out[#out + 1] = c.Text
				budget = budget - 1
			end
			budget = collectGuiText(c, out, budget)
		end
		return budget
	end

	local function inferObjective(name)
		local now = os.clock()
		if M._inferName == name and M._inferObj and now - (M._inferAt or 0) < 1.1 then
			return M._inferObj
		end
		perfCount("QuestGuiScan", 1)
		local pg = GB.lp and GB.lp.PlayerGui
		if not pg then
			return nil
		end
		local gui = pg:FindFirstChild("Quests")
		if not gui then
			return nil
		end
		local blob = {}
		local details = gui:FindFirstChild("QuestDetails")
		local list = gui:FindFirstChild("Quest")
		local sf = list and list:FindFirstChild("ScrollingFrame")
		local budget = 90
		budget = collectGuiText(details, blob, budget)
		budget = collectGuiText(sf, blob, budget)
		budget = collectGuiText(gui:FindFirstChild("Frame"), blob, budget)
		local text = table.concat(blob, "\n")
		if name == "Basics" then
			if string.find(text, "skill scroll", 1, true) or string.find(text, "Equip Skill", 1, true) or string.find(text, "Equip your new skill", 1, true) or string.find(text, "Equip the skill", 1, true) then
				M._inferName = name
				M._inferAt = now
				M._inferObj = { Type = "EquipSkill", TargetName = "Strong Punch", Current = 0, Amount = 1, Complete = false, Raw = { Type = "EquipSkill", Target = { Name = "Strong Punch", Amount = 0, RequiredAmount = 1 } } }
				return M._inferObj
			end
			if string.find(text, "Use Skill", 1, true) or string.find(text, "Cast the skill", 1, true) or string.find(text, "Use your Strong Punch", 1, true) then
				M._inferName = name
				M._inferAt = now
				M._inferObj = { Type = "Cast", TargetName = "Strong Punch", Current = 0, Amount = 1, Complete = false, Raw = { Type = "Cast", Target = { Name = "Strong Punch", Amount = 0, RequiredAmount = 1 } } }
				return M._inferObj
			end
			if string.find(text, "Invest", 1, true) and string.find(text, "stat", 1, true) then
				M._inferName = name
				M._inferAt = now
				M._inferObj = { Type = "Required", TargetName = "TotalStatPoints", Current = 0, Amount = 1, Complete = false, Raw = { Type = "Required", Target = { Name = "TotalStatPoints", Amount = 0, RequiredAmount = 1 } } }
				return M._inferObj
			end
			if string.find(text, "logbook", 1, true) or string.find(text, "Logbook", 1, true) then
				M._inferName = name
				M._inferAt = now
				M._inferObj = { Type = "Open", TargetName = "Logbook", Current = 0, Amount = 1, Complete = false, Raw = { Type = "Open", Target = { Name = "Logbook", Amount = 0, RequiredAmount = 1 } } }
				return M._inferObj
			end
		end
		if name == "Introduction" then
			if string.find(text, "Press Q", 1, true) then
				M._inferName = name
				M._inferAt = now
				M._inferObj = { Type = "Dash", TargetName = "", Current = 0, Amount = 2, Complete = false, Raw = { Type = "Dash", Target = { Name = "", Amount = 0, RequiredAmount = 2 } } }
				return M._inferObj
			end
			if string.find(text, "Hold F", 1, true) then
				M._inferName = name
				M._inferAt = now
				M._inferObj = { Type = "Block", TargetName = "", Current = 0, Amount = 1, Complete = false, Raw = { Type = "Block", Target = { Name = "", Amount = 0, RequiredAmount = 1 } } }
				return M._inferObj
			end
			if string.find(text, "dummy", 1, true) or string.find(text, "Dummy", 1, true) then
				M._inferName = name
				M._inferAt = now
				M._inferObj = { Type = "Hit", TargetName = "Training Dummy", Current = 0, Amount = 4, Complete = false, Raw = { Type = "Hit", Target = { Name = "Training Dummy", Amount = 0, RequiredAmount = 4 } } }
				return M._inferObj
			end
		end
		M._inferName = name
		M._inferAt = now
		M._inferObj = nil
		return nil
	end

	function M.questState(name)
		local t0 = pbegin()
		local live = GB.PlayerData.live(name)
		local island = GB.QuestData.islandOf(name)
		local npc = GB.QuestData.talkNpc(name)
		if not live then
			local inferred = GB.PlayerData.current() == name and inferObjective(name)
			if inferred then
				local out = {
					Name = name,
					IsAccepted = true,
					IsComplete = false,
					CanTurnIn = false,
					Automatic = GB.QuestData.AUTOMATIC[name] == true,
					NPC = npc,
					Island = island,
					StageIndex = inferred.Type,
					Objective = inferred,
				}
				pdone("Quest.questState", t0)
				return out
			end
			local out = {
				Name = name,
				IsAccepted = false,
				IsComplete = GB.PlayerData.finished(name, true),
				CanTurnIn = false,
				Automatic = GB.QuestData.AUTOMATIC[name] == true,
				NPC = npc,
				Island = island,
				StageIndex = nil,
				Objective = nil,
			}
			pdone("Quest.questState", t0)
			return out
		end
		local si, st = GB.QuestData.currentStage(live)
		local obj
		if st then
			local conds = st.Conditions or st.conditions or {}
			for _, cond in ipairs(conds) do
				if type(cond) == "table" and not cond.Complete then
					local typ = cond.Type or cond.type
					local target = GB.QuestData.conditionTarget(cond)
					if typ == "Kill" or typ == "Defeat" then
						target = GB.QuestData.killName(name, target)
					end
					local cur, amt = M.condProgress(cond)
					obj = {
						Type = typ,
						TargetName = target,
						Current = cur,
						Amount = amt,
						Complete = cond.Complete == true,
						Raw = cond,
						Automatic = typ == "Automatic Talk",
					}
					break
				end
			end
		end
		local allDone = st and st.Complete == true
		if si and live.Stages and si >= #live.Stages and allDone then
			allDone = true
		end
		local canTurn = false
		if st and not obj then
			canTurn = true
		end
		local out = {
			Name = name,
			Live = live,
			IsAccepted = true,
			IsComplete = GB.PlayerData.finished(name, true),
			CanTurnIn = canTurn,
			Automatic = GB.QuestData.AUTOMATIC[name] == true,
			NPC = npc,
			Island = island,
			StageIndex = si,
			Stage = st,
			Objective = obj,
		}
		pdone("Quest.questState", t0)
		return out
	end

	function M.signature(qs)
		local o = qs.Objective
		if not o then
			return qs.Name .. "|turn|" .. tostring(qs.StageIndex)
		end
		return string.format("%s|%s|%s|%s/%s", qs.Name, tostring(qs.StageIndex), tostring(o.Type), tostring(o.Current), tostring(o.Amount))
	end

	local function capMap(map, maxN)
		local n = 0
		local dropKey
		local dropAt
		for k, v in pairs(map) do
			n = n + 1
			local at = 0
			if type(v) == "table" then
				at = tonumber(v.LastAt or v.LastDump or v.LastFingerprintAt or v.at) or 0
			else
				at = tonumber(v) or 0
			end
			if not dropAt or at < dropAt then
				dropAt = at
				dropKey = k
			end
		end
		if n > maxN and dropKey ~= nil then
			map[dropKey] = nil
		end
	end

	function M.trackOf(name)
		local t = M.track[name]
		if not t then
			t = {
				AttemptCount = 0,
				LastError = nil,
				NextRetryAt = 0,
				LastDump = 0,
				LastFingerprint = nil,
				LastFingerprintAt = 0,
				LastAt = os.clock(),
			}
			M.track[name] = t
			capMap(M.track, TRACK_LIMIT)
		end
		t.LastAt = os.clock()
		return t
	end

	function M.clearTrack(name)
		M.track[name] = nil
	end

	local function scopedResolveInvalidate(qs)
		if not GB.Cache then
			return
		end
		local invalidatePrefix = GB.Cache.invalidatePrefix
		if type(invalidatePrefix) ~= "function" then
			if GB.Cache.invalidate then
				GB.Cache.invalidate()
			end
			return
		end
		local o = qs and qs.Objective
		if not o then
			invalidatePrefix("res:")
			return
		end
		local typ = tostring(o.Type or "")
		if typ == "Talk" or typ == "Automatic Talk" then
			invalidatePrefix("res:npc:")
			return
		end
		if typ == "Kill" or typ == "Defeat" or typ == "Hit" or typ == "Shoot" then
			invalidatePrefix("res:enemy:")
			return
		end
		if typ == "Purchase" or typ == "Sell" then
			invalidatePrefix("shop:")
			return
		end
		invalidatePrefix("res:any:")
	end

	function M.noteFail(name, err)
		local t = M.trackOf(name)
		local now = os.clock()
		if now < t.NextRetryAt then
			return t
		end
		local qs = M.questState(name)
		local stage = qs and qs.StageIndex or "-"
		local action = qs and qs.Objective and qs.Objective.Type or "-"
		local fp = string.format("%s|%s|%s|%s", tostring(name), tostring(stage), tostring(action), tostring(err))
		if t.LastFingerprint == fp and now - (t.LastFingerprintAt or 0) < FAIL_FINGERPRINT_GAP then
			return t
		end
		t.LastFingerprint = fp
		t.LastFingerprintAt = now
		t.AttemptCount = t.AttemptCount + 1
		t.LastError = err
		t.NextRetryAt = now + 1.5
		GB.Log.warn("QUEST", string.format("%s fail #%d %s", name, t.AttemptCount, tostring(err)))
		if t.AttemptCount == 3 then
			scopedResolveInvalidate(qs)
			local target = qs and qs.Objective and qs.Objective.TargetName or (qs and qs.NPC)
			local lastDetail = M.detailByFingerprint[fp] or 0
			if now - lastDetail >= DETAIL_DUMP_GAP then
				M.detailByFingerprint[fp] = now
				capMap(M.detailByFingerprint, 192)
				if target then
					GB.Resolver.dumpNearby(target, { Island = qs and qs.Island, DisplayName = target })
					t.LastDump = now
				end
				if qs and qs.Island and GB.World.pullStream then
					GB.World.pullStream(qs.Island)
				end
			end
		end
		if t.AttemptCount >= 5 then
			local lastDiag = M.diagByFingerprint[fp] or 0
			if now - lastDiag >= DIAG_DUMP_GAP then
				M.diagByFingerprint[fp] = now
				capMap(M.diagByFingerprint, 192)
				GB.Log.err("QUEST", "STUCK " .. name .. " " .. tostring(err))
				GB.Recovery.run("quest:" .. name)
				if GB.DumpRuntimeIssue then
					GB.DumpRuntimeIssue()
				end
			end
			M.deferUntil[name] = now + FAIL_DEFER_GAP
			M.deferReason[name] = "deferred_after_fail"
			t.AttemptCount = 0
			t.NextRetryAt = now + 4
		end
		return t
	end

	function M.noteOk(name)
		if name == "Gate of Authority" then
			M._gateBlockedKey = nil
		end
		M.deferUntil[name] = nil
		M.deferReason[name] = nil
		M.clearTrack(name)
		GB.Recovery.markSuccess()
	end

	local function talkName(pack, fallback)
		if pack and pack.DisplayName and pack.DisplayName ~= "" then
			return pack.DisplayName
		end
		if fallback and fallback ~= "" then
			return fallback
		end
		return pack and pack.InternalName
	end

	function M.talk(request, automatic, opts)
		opts = opts or {}
		local qsName = opts.Quest
		local island = opts.Island or (qsName and GB.QuestData.islandOf(qsName))
		local key = tostring(request)

		if dialogueOpen() then
			if os.clock() - (M.lastClick or 0) < 0.7 then
				return false, "rate"
			end
			local clicked = clickAccept()
			if clicked then
				M.lastClick = os.clock()
			end
			return clicked, clicked and "advance" or "waiting"
		end

		if os.clock() - (M.lastTalk[key] or 0) < 1.8 then
			return false, "rate"
		end

		local pack = GB.Resolver.resolveNPC(request, {
			DisplayName = opts.DisplayName or request,
			InternalName = opts.InternalName,
			QuestName = qsName,
			Island = island,
			ExpectedRole = "npc",
			deep = opts.deep,
		})
		if not pack then
			if island then
				local snap = GB.State.get()
				if snap.PhysicalIsland and snap.PhysicalIsland ~= island then
					if GB.Travel then
						GB.Travel.goIsland(island)
					end
				else
					GB.World.pullStream(island)
				end
				local names = GB.Resolver.namesFor(request, opts)
				local t0 = os.clock()
				while not pack and os.clock() - t0 < 2.6 do
					for _, tag in ipairs(names) do
						local inst = GB.Resolver.waitTagged(tag, 0.35)
						if inst then
							pack = GB.Resolver.pack(inst, request)
							break
						end
					end
					if not pack then
						pack = GB.Resolver.resolveNPC(request, {
							DisplayName = request,
							Island = island,
							ExpectedRole = "npc",
							deep = true,
						})
					end
				end
			end
		end
		if not pack then
			if qsName then
				M.noteFail(qsName, "NPC miss " .. tostring(request))
			else
				GB.Log.warn("QUEST", "NPC miss " .. tostring(request))
			end
			return false, "resolve"
		end

		local shown = talkName(pack, request)
		if pack.Island and island and pack.Island ~= island and GB.Travel then
			GB.Travel.goIsland(island)
		end
		if not GB.World.ToNPC(pack, GB.Config.TalkOffset or 5) then
			if not GB.World.moveTo(pack.Instance, GB.Config.TalkRange or 14) then
				return false, "travel"
			end
		end
		GB.World.waitUnpause()
		task.wait(0.2)

		GB.Log.log("QUEST", "Talking " .. tostring(shown))
		if automatic then
			GB.Remotes.autoTalk(shown)
		else
			GB.Remotes.talk(shown)
		end
		local cfg = GB.Resolver.dialogueConfig(pack.Instance)
		if cfg then
			GB.Remotes.dialogueConfig(cfg)
		end
		task.wait(0.35)
		if clickAccept() then
			M.lastClick = os.clock()
		end
		M.lastTalk[key] = os.clock()
		return true, shown
	end

	function M.waitProgress(name, beforeSig, timeout)
		timeout = timeout or 2.8
		local t0 = os.clock()
		while os.clock() - t0 < timeout do
			task.wait(0.2)
			if GB.PlayerData.finished(name, true) then
				return true, "done"
			end
			local qs = M.questState(name)
			local sig = M.signature(qs)
			if sig ~= beforeSig then
				return true, sig
			end
		end
		return false, "timeout"
	end

	function M.ensureItem(name)
		local spec = GB.QuestData.NEED_ITEM[name]
		if GB.PlayerData.hasItem(name) then
			return true
		end
		if spec and spec.gold then
			local gold = GB.State.get().Gold or 0
			if gold < spec.gold then
				GB.Log.warn("QUEST", string.format("need %s %dG have %d", name, spec.gold, gold))
				return false
			end
		end
		return GB.Shop.buy(name)
	end

	function M.handleCondition(questName, cond, stage)
		if type(cond) ~= "table" then
			return false
		end
		if cond.Complete then
			return true
		end
		local typ = cond.Type or cond.type
		local target = GB.QuestData.conditionTarget(cond)
		if typ == "Kill" or typ == "Defeat" then
			target = GB.QuestData.killName(questName, target)
		end
		if not typ then
			return false
		end
		if not HANDLED[typ] then
			rememberUnknown(questName .. typ, "UNKNOWN_OBJECTIVE " .. tostring(typ) .. " " .. tostring(target))
			return false
		end

		if typ == "Talk" or typ == "Automatic Talk" then
			local qs = M.questState(questName)
			local before = M.signature(qs)
			local ok = M.talk(target, typ == "Automatic Talk", {
				Quest = questName,
				Island = qs.Island,
				DisplayName = target,
			})
			if ok then
				local progressed, sig = M.waitProgress(questName, before)
				if progressed then
					local after = M.questState(questName)
					local prev = qs.Objective
					if prev then
						local nextCur = prev.Amount
						if after.StageIndex == qs.StageIndex and after.Objective and not after.IsComplete then
							nextCur = after.Objective.Current
						end
						GB.Log.log(
							"QUEST",
							string.format(
								"%s %s/%s -> %s/%s",
								questName,
								tostring(prev.Current),
								tostring(prev.Amount),
								tostring(nextCur),
								tostring(prev.Amount)
							)
						)
					end
					M.noteOk(questName)
					return true
				end
				M.noteFail(questName, "talk not credited " .. tostring(target))
			end
			return false
		end
		if typ == "Shoot" then
			local before = M.questState(questName)
			local beforeCur = before.Objective and before.Objective.Current or 0
			local ok, why = GB.Combat.shootUntilCredit(target or "Training Dummy", questName, 24)
			if GB.PlayerData and GB.PlayerData.forceQuestRefresh then
				GB.PlayerData.forceQuestRefresh("shoot_credit")
			elseif GB.PlayerData and GB.PlayerData.refreshLive then
				GB.PlayerData.refreshLive(true, "shoot_credit")
			end
			local after = M.questState(questName)
			if after.IsComplete or (after.Objective and after.Objective.Current and after.Objective.Current > beforeCur) or after.StageIndex ~= before.StageIndex then
				M.noteOk(questName)
				return true
			end
			if why == "quest_done" then
				M.noteOk(questName)
				return true
			end
			if not ok then
				local pos = GB.Resolver.lastDummyPos and GB.Resolver.lastDummyPos()
				if pos and GB.World.destOk(pos) then
					GB.World.setPos(pos + Vector3.new(GB.Config.ShootRange or 9, 0, 0))
				elseif before.Island then
					GB.World.pullStream(before.Island)
				end
				M.noteFail(questName, "shoot miss " .. tostring(target))
			end
			return false
		end
		if typ == "Kill" or typ == "Defeat" or typ == "Hit" or typ == "Destroy" then
			local before = M.questState(questName)
			local beforeCur = before.Objective and before.Objective.Current or 0
			local ok, why = false, nil
			if GB.Combat.huntUntilDead then
				ok, why = GB.Combat.huntUntilDead(target or "Training Dummy", 16, questName)
			else
				ok = GB.Combat.attack(target or "Training Dummy", questName)
			end
			if not ok then
				local pos = GB.Resolver.lastDummyPos and GB.Resolver.lastDummyPos()
				local misses = GB.Resolver.dummyMissCount and GB.Resolver.dummyMissCount() or 0
				if misses >= 3 then
					if pos and GB.World.destOk(pos) then
						GB.World.setPos(pos + Vector3.new(GB.Config.DummyBeside or 3.2, 0, 0))
					elseif before.Island then
						GB.World.pullStream(before.Island)
					end
				end
				if why ~= "dead" then
					M.noteFail(questName, "resolve miss " .. tostring(target))
				end
				return false
			end
			if GB.PlayerData and GB.PlayerData.forceQuestRefresh then
				GB.PlayerData.forceQuestRefresh("kill_credit")
			elseif GB.PlayerData and GB.PlayerData.refreshLive then
				GB.PlayerData.refreshLive(true, "kill_credit")
			end
			local after = M.questState(questName)
			if after.IsComplete or (after.Objective and after.Objective.Current and after.Objective.Current > beforeCur) or after.StageIndex ~= before.StageIndex then
				M.noteOk(questName)
				return true
			end
			if why == "quest_done" then
				M.noteOk(questName)
				return true
			end
			if why == "dead" then
				return true
			end
			return ok
		end
		if typ == "Purchase" then
			return M.ensureItem(target) or GB.Shop.buy(target)
		end
		if typ == "Sell" then
			return GB.Shop.sellNamed(target)
		end
		if typ == "Equip" then
			if not GB.PlayerData.hasItem(target) then
				M.ensureItem(target)
			end
			local qs = M.questState(questName)
			local before = M.signature(qs)
			if GB.Tutorial and GB.Tutorial.IsBlocking and select(1, GB.Tutorial.IsBlocking()) then
				GB.Tutorial.ExecuteCurrentStep()
				local progressed = M.waitProgress(questName, before, 2.2)
				if progressed then
					M.noteOk(questName)
					return true
				end
				return false
			end
			local st = GB.Equipment.equipmentState and GB.Equipment.equipmentState(target)
			if st and (st.Held or st.Equipped) and not st.QuestCredited then
				GB.Log.log("EQUIP", tostring(target) .. " equipped but quest not credited")
				GB.Log.log("GATE", "Inspecting tutorial state")
				if GB.Tutorial and GB.Tutorial.ExecuteCurrentStep then
					GB.Tutorial.ExecuteCurrentStep()
				elseif GB.Equipment.equipViaBackpack then
					GB.Equipment.equipViaBackpack(target)
				end
				local progressed = M.waitProgress(questName, before, 2.2)
				if progressed then
					M.noteOk(questName)
					return true
				end
				return false
			end
			local needUi = GB.Equipment.needsGearSlot and GB.Equipment.needsGearSlot(target)
			local ok = GB.Equipment.equipNamed(target, { QuestEquip = needUi, Mode = needUi and "UI_EQUIP" or "DIRECT_EQUIP" })
			if ok then
				local progressed = M.waitProgress(questName, before, 2.4)
				if progressed then
					local after = M.questState(questName)
					local prev = qs.Objective
					if prev then
						local nextCur = prev.Amount
						if after.StageIndex == qs.StageIndex and after.Objective and not after.IsComplete then
							nextCur = after.Objective.Current
						end
						GB.Log.log(
							"QUEST",
							string.format(
								"Equip %s %s/%s -> %s/%s",
								tostring(target),
								tostring(prev.Current),
								tostring(prev.Amount),
								tostring(nextCur),
								tostring(prev.Amount)
							)
						)
					end
					M.noteOk(questName)
					return true
				end
				GB.Log.log("EQUIP", "action ok quest not credited " .. tostring(target))
				if GB.Tutorial and GB.Tutorial.IsBlocking and select(1, GB.Tutorial.IsBlocking()) then
					GB.Log.log("GATE", "Inspecting tutorial state")
					return false
				end
			end
			return ok
		end
		if typ == "Upgrade" then
			GB.Combat.stopLock()
			local qs = M.questState(questName)
			local before = M.signature(qs)
			local anvil = GB.Resolver.taggedAny("Anvil") or GB.Resolver.byName("Anvil")
			if anvil and GB.World.interact then
				GB.World.interact(anvil, 8)
			end
			clickPlayerGuiPath("Blacksmith.Blacksmith.ScrollingFrame.FlintlockHolder.Flintlock")
			task.wait(0.15)
			clickPlayerGuiPath("Blacksmith.Blacksmith.Upgrade.UpgradeButton")
			local ok = GB.Equipment.upgradeNamed(target)
			if ok then
				local progressed = M.waitProgress(questName, before, 2.4)
				if progressed then
					M.noteOk(questName)
					return true
				end
			end
			return ok
		end
		if typ == "EquipSkill" then
			GB.Combat.stopLock()
			if GB.State.tutorialOverlayVisible() then
				GB.State.dismissTutorialOverlay()
				return false
			end
			local qs = M.questState(questName)
			local before = M.signature(qs)
			local ok = GB.Skills.equip(target)
			if ok then
				local progressed = M.waitProgress(questName, before, 2.4)
				if progressed then
					M.noteOk(questName)
					return true
				end
				if GB.State.tutorialOverlayVisible() then
					GB.State.dismissTutorialOverlay()
					return false
				end
				M.noteFail(questName, "equipskill not credited " .. tostring(target))
			end
			return ok
		end
		if typ == "Cast" then
			GB.Combat.stopLock()
			if GB.State.tutorialOverlayVisible() then
				GB.State.dismissTutorialOverlay()
				return false
			end
			local qs = M.questState(questName)
			local before = M.signature(qs)
			local ok = GB.Skills.cast(target)
			if ok then
				local progressed = M.waitProgress(questName, before, 2.4)
				if progressed then
					M.noteOk(questName)
					return true
				end
				if GB.State.tutorialOverlayVisible() then
					GB.State.dismissTutorialOverlay()
					return false
				end
				M.noteFail(questName, "cast not credited " .. tostring(target))
			end
			return ok
		end
		if typ == "Required" and target == "TotalStatPoints" then
			return GB.Stats.investMinimum(1)
		end
		if typ == "Required" and target == "Level" then
			return false
		end
		if typ == "Loot" then
			GB.Combat.stopLock()
			local qs = M.questState(questName)
			local before = M.signature(qs)
			local need = GB.QuestData.conditionAmount(cond) or 5
			GB.Log.log("QUEST", "Loot " .. tostring(target))
			local ok = GB.Chest and GB.Chest.lootUntil and GB.Chest.lootUntil(questName, need)
			if ok then
				M.waitProgress(questName, before, 1.2)
				local after = M.questState(questName)
				if after.IsComplete or after.StageIndex ~= qs.StageIndex then
					M.noteOk(questName)
					return true
				end
				if after.Objective and (after.Objective.Current or 0) > ((qs.Objective and qs.Objective.Current) or 0) then
					M.noteOk(questName)
					return true
				end
			end
			M.noteFail(questName, "loot miss " .. tostring(target))
			return false
		end
		if typ == "Collect" or typ == "CollectLocal" or typ == "CollectLocalItem" then
			local spec = GB.QuestSpecs and GB.QuestSpecs.lookup(questName, nil, typ, target)
			if spec and spec.acquire == "ShopPurchase" then
				return GB.Shop.buy(target, GB.QuestData.conditionAmount(cond) or 1)
			end
			if GB.Planner and GB.Planner.execute then
				local qs = M.questState(questName)
				local plan = GB.Planner.build(qs)
				if plan and plan.Goal == "AcquireItem" then
					return GB.Planner.execute(qs, plan)
				end
			end
			if GB.Acquire then
				return GB.Acquire.AcquireItem(target, GB.QuestData.conditionAmount(cond), {
					Quest = questName,
					Type = typ,
				})
			end
			GB.Log.warn("QUEST", "collect miss " .. tostring(target))
			return false
		end
		if typ == "Mine" then
			if not GB.PlayerData.hasItem("Rusty Pickaxe") then
				M.ensureItem("Rusty Pickaxe")
			end
			return GB.LifeSkills.mineToward(target)
		end
		if typ == "Smelt" then
			GB.Combat.stopLock()
			local qs = M.questState(questName)
			local before = M.signature(qs)
			local ok = GB.LifeSkills.smeltToward and GB.LifeSkills.smeltToward(target)
			if ok then
				clickPlayerGuiPath("Crafting.Frame.Recipes.Inventory.Scroll.Copper Bar")
				task.wait(0.15)
				clickPlayerGuiPath("Crafting.Frame.Ingredients.Craft")
				local progressed = M.waitProgress(questName, before, 2.4)
				if progressed then
					M.noteOk(questName)
					return true
				end
			end
			return ok
		end
		if typ == "Fish" then
			return GB.LifeSkills.fishToward(target)
		end
		if typ == "Plant" or typ == "Harvest" or typ == "Water" or typ == "Fertilize" then
			return GB.LifeSkills.farmToward(typ, target)
		end
		if typ == "Cook" or typ == "Perfect Cook" then
			return GB.LifeSkills.cookToward(target)
		end
		if typ == "Craft" then
			GB.Log.warn("QUEST", "UNKNOWN_OBJECTIVE Craft " .. tostring(target))
			return false
		end
		if typ == "Spawn" and target == "Rowboat" then
			if not GB.PlayerData.hasItem("Rowboat") then
				M.ensureItem("Rowboat")
			end
			return GB.Boat.spawnRowboat()
		end
		if typ == "Reach" or typ == "Travel" or (type(typ) == "string" and string.sub(typ, 1, 6) == "Reach ") then
			local island = target
			if typ == "Reach Maple Village" or island == "" or not island then
				island = "Maple Village"
			end
			local tag = GB.QuestData.markerOf(typ, target)
			if tag and tag ~= island then
				goTagged(tag, 16)
			end
			return GB.Travel.goIsland(island)
		end
		if typ == "Unlock" then
			GB.Combat.stopLock()
			local tag = GB.QuestData.markerOf(typ, target) or target
			local qs = M.questState(questName)
			local before = M.signature(qs)
			local beforeCur = (qs.Objective and qs.Objective.Current) or 0
			local inst = GB.Resolver.taggedAny and GB.Resolver.taggedAny(tag)
			if not inst then
				inst = GB.Resolver.waitTagged and GB.Resolver.waitTagged(tag, 0.8)
			end
			if not inst then
				inst = GB.Resolver.byName(tag)
			end
			if not inst then
				M.noteFail(questName, "unlock miss " .. tostring(tag))
				return false
			end
			local keyName = inst:GetAttribute("Key")
			if keyName and not GB.PlayerData.hasItem(keyName) then
				M.noteFail(questName, "need key " .. tostring(keyName))
				return false
			end
			GB.Log.log("QUEST", "Unlock " .. tostring(target))
			local fired = GB.World.interact and GB.World.interact(inst, 4)
			if not fired then
				GB.World.ToInteractable(inst, 4)
				local pr = GB.Resolver.prompt(inst)
				if pr then
					GB.World.firePrompt(pr, pr.HoldDuration or 0, inst)
					fired = true
				end
			end
			local progressed = M.waitProgress(questName, before, 2.8)
			if not progressed then
				local pr = GB.Resolver.prompt(inst)
				if pr then
					GB.World.firePrompt(pr, pr.HoldDuration or 0, inst)
					progressed = M.waitProgress(questName, before, 1.6)
				end
			end
			if progressed then
				local after = M.questState(questName)
				local nextCur = beforeCur
				if after.IsComplete or after.StageIndex ~= qs.StageIndex then
					nextCur = (qs.Objective and qs.Objective.Amount) or 1
				elseif after.Objective then
					nextCur = after.Objective.Current or nextCur
				end
				GB.Log.log("QUEST", string.format("Unlock credited %s/1 -> %s/1", tostring(beforeCur), tostring(nextCur)))
				M.noteOk(questName)
				return true
			end
			M.noteFail(questName, "unlock not credited " .. tostring(target))
			return false
		end
		if typ == "Deliver Object" then
			GB.Combat.stopLock()
			local spec = GB.QuestData.deliverSpec(target)
			if spec then
				goTagged(spec.object, 12)
				task.wait(0.3)
				return goTagged(spec.location, 12)
			end
			return goTagged(target, 12)
		end
		if type(typ) == "string" and string.sub(typ, 1, 11) == "Investigate" then
			GB.Combat.stopLock()
			return goTagged(GB.QuestData.markerOf(typ, target) or target, 10)
		end
		if typ == "Defend" then
			rememberUnknown(questName .. "Defend", "UNKNOWN_OBJECTIVE Defend " .. tostring(target) .. " — skip")
			return false
		end
		if typ == "Visit" and target == "Closet" then
			local c = GB.Resolver.byName("Closet")
			if c then
				GB.World.ToInteractable(c, 10)
				GB.Remotes.closetVisit()
				return true
			end
			return false
		end
		if typ == "Open" and target == "Logbook" then
			return openLogbook()
		end
		if typ == "Open" or typ == "Interact" or typ == "Investigate" or typ == "Wake" or typ == "Check On" or typ == "Free" then
			if target == "Marine Gate" or questName == "Gate of Authority" then
				local blocked, _, blocker = gateBlocker()
				if blocked and blocker then
					local key = tostring(blocker.Current) .. "/" .. tostring(blocker.Required)
					if M._gateBlockedKey ~= key then
						M._gateBlockedKey = key
						GB.Log.warn(
							"QUEST",
							string.format("Gate of Authority BLOCKED Strength=%d/%d", blocker.Current, blocker.Required)
						)
						GB.Log.warn("QUEST", "deferring blocked quest")
					end
					return false
				end
				local gate = resolveMarineGate()
				if not gate then
					M.noteFail(questName, "gate unresolved")
					return false
				end
				return waitAtMarineGate(questName, gate)
			end
			local spec = GB.QuestSpecs and GB.QuestSpecs.lookup(questName, nil, typ, target)
			local tag = (spec and (spec.marker or spec.source)) or GB.QuestData.markerOf(typ, target) or target
			local objPack = GB.Resolver.resolveObject and GB.Resolver.resolveObject(tag, { deep = true }) or nil
			local obj = objPack and objPack.Instance
			if not obj and target and target ~= tag then
				objPack = GB.Resolver.resolveObject and GB.Resolver.resolveObject(target, { deep = true }) or nil
				obj = objPack and objPack.Instance
			end
			if not obj then
				obj = (GB.Resolver.taggedAny and GB.Resolver.taggedAny(tag))
					or GB.Resolver.byName(tag)
					or GB.Resolver.byName(target)
			end
			if not obj then
				M.noteFail(questName, "resolve miss " .. tostring(target))
				return false
			end
			if GB.World.interact then
				GB.World.interact(obj, 8)
			else
				GB.World.ToInteractable(obj, 8)
				local pr = GB.Resolver.prompt(obj)
				if pr then
					GB.World.firePrompt(pr)
				end
			end
			return true
		end
		if typ == "Deliver" or typ == "Donate" or typ == "GiveItemTo" then
			return M.talk(target, false, { Quest = questName, DisplayName = target })
		end
		if typ == "Escort" then
			GB.Log.warn("QUEST", "Escort " .. tostring(target) .. " NeverSkip — follow only")
			local pack = GB.Resolver.resolveNPC(target, {
				Island = GB.QuestData.islandOf(questName),
				ExpectedRole = "npc",
			})
			if pack then
				GB.World.moveTo(pack.Instance, 8)
				return true
			end
			return false
		end
		if typ == "Dash" then
			GB.Combat.stopLock()
			local qs = M.questState(questName)
			local before = M.signature(qs)
			local ok = GB.Combat.dash()
			if ok then
				local progressed = M.waitProgress(questName, before, 2.2)
				if progressed then
					local after = M.questState(questName)
					local prev = qs.Objective
					if prev then
						local nextCur = prev.Amount
						if after.StageIndex == qs.StageIndex and after.Objective and not after.IsComplete then
							nextCur = after.Objective.Current
						end
						GB.Log.log(
							"QUEST",
							string.format(
								"%s %s/%s -> %s/%s",
								questName,
								tostring(prev.Current),
								tostring(prev.Amount),
								tostring(nextCur),
								tostring(prev.Amount)
							)
						)
					end
					M.noteOk(questName)
					return true
				end
				M.noteFail(questName, "dash not credited")
			else
				M.noteFail(questName, "dash blocked")
			end
			return false
		end
		if typ == "Block" then
			GB.Combat.stopLock()
			local qs = M.questState(questName)
			local before = M.signature(qs)
			local ok = GB.Combat.block(0.7)
			if ok then
				local progressed = M.waitProgress(questName, before, 2.2)
				if progressed then
					local after = M.questState(questName)
					local prev = qs.Objective
					if prev then
						local nextCur = prev.Amount
						if after.StageIndex == qs.StageIndex and after.Objective and not after.IsComplete then
							nextCur = after.Objective.Current
						end
						GB.Log.log(
							"QUEST",
							string.format(
								"%s %s/%s -> %s/%s",
								questName,
								tostring(prev.Current),
								tostring(prev.Amount),
								tostring(nextCur),
								tostring(prev.Amount)
							)
						)
					end
					M.noteOk(questName)
					return true
				end
				M.noteFail(questName, "block not credited")
			else
				M.noteFail(questName, "block blocked")
			end
			return false
		end
		GB.Log.err("QUEST", "UNKNOWN_OBJECTIVE " .. tostring(typ) .. " " .. tostring(target))
		return false
	end

	function M.doLive(name)
		if GB.Config.SkipQuests[name] then
			return false
		end
		local qs = M.questState(name)
		local t = M.trackOf(name)
		if os.clock() < t.NextRetryAt and t.LastError then
			return false
		end
		local blocked, why = M.deferred(name)
		if blocked then
			if M._deferQuest ~= name or os.clock() - (M._deferAt or 0) > 8 then
				M._deferQuest = name
				M._deferAt = os.clock()
				GB.Log.warn("QUEST", "defer " .. tostring(name) .. " " .. tostring(why))
			end
			t.NextRetryAt = os.clock() + 2.5
			return false
		end

		if not qs.IsAccepted then
			if qs.IsComplete then
				return true
			end
			if qs.Automatic then
				GB.Remotes.beginAutomatic(name)
			end
			if qs.NPC then
				return M.talk(qs.NPC, false, { Quest = name, Island = qs.Island, DisplayName = qs.NPC })
			end
			return false
		end

		local sig = M.signature(qs)
		if M.lastSig[name] ~= sig then
			M.lastSig[name] = sig
			if GB.Persist and GB.Persist.checkpoint then
				GB.Persist.checkpoint("quest", name)
				GB.Persist.checkpoint("stage", qs.StageIndex)
			end
			GB.Log.log("QUEST", string.format("%s stage=%s", name, tostring(qs.StageIndex or "-")))
			if qs.Objective then
				GB.Log.log(
					"QUEST",
					string.format("Objective %s %s", string.upper(tostring(qs.Objective.Type or "?")), tostring(qs.Objective.TargetName or ""))
				)
				local ot = qs.Objective.Type
				if ot == "Dash" or ot == "Block" or ot == "EquipSkill" or ot == "Cast" or ot == "Required" or ot == "Open" then
					GB.Combat.stopLock()
				end
			end
		end

		if qs.IsComplete then
			M.noteOk(name)
			return true
		end

		if qs.Objective then
			if GB.State.tutorialOverlayVisible() then
				GB.State.dismissTutorialOverlay()
				return false
			end
			if GB.Tutorial and GB.Tutorial.IsBlocking and select(1, GB.Tutorial.IsBlocking()) then
				return GB.Tutorial.ExecuteCurrentStep()
			end
			local typ = qs.Objective.Type
			if typ and not HANDLED[typ] then
				rememberUnknown(
					name .. tostring(typ),
					"UNKNOWN_OBJECTIVE " .. tostring(typ) .. " " .. tostring(qs.Objective.TargetName)
				)
				t.NextRetryAt = os.clock() + 6
				return false
			end
			if GB.Planner then
				local plan = GB.Planner.build(qs)
				if plan then
					return GB.Planner.execute(qs, plan)
				end
			end
			return M.handleCondition(name, qs.Objective.Raw, qs.Stage)
		end

		if qs.NPC then
			if GB.State.tutorialOverlayVisible() then
				GB.State.dismissTutorialOverlay()
				return false
			end
			return M.talk(qs.NPC, false, { Quest = name, Island = qs.Island, DisplayName = qs.NPC })
		end
		return false
	end

	local _doLiveRaw = M.doLive
	function M.doLive(name)
		local t0 = pbegin()
		local out = { pcall(_doLiveRaw, name) }
		pdone("Quest.doLive", t0)
		if not out[1] then
			error(out[2])
		end
		return unpack(out, 2)
	end

	function M.Refresh()
		if GB.PlayerData and GB.PlayerData.forceQuestRefresh then
			GB.PlayerData.forceQuestRefresh("Quest.Refresh")
		elseif GB.PlayerData and GB.PlayerData.refreshLive then
			GB.PlayerData.refreshLive(true, "Quest.Refresh")
		end
		local cur = GB.PlayerData and GB.PlayerData.current and GB.PlayerData.current()
		return cur and M.questState(cur) or nil
	end

	return M
end
]],
    ["Systems/RaceTrait.lua"] = [[-- Trait: Reroll:FireServer("Trait", slotNumber) VERIFIED.
-- Race reroll FireServer("Race") NOT found. AutoRaceTrait default false. No spam.

return function(GB)
	local M = {
		rolled = false,
	}

	function M.tick()
		if not GB.Config.AutoRaceTrait then
			return
		end
		if M.rolled then
			return
		end
		GB.Log.warn("RACE", "AutoRaceTrait on but race remote UNRESOLVED; trait reroll not auto-fired")
		M.rolled = true
	end

	return M
end
]],
    ["Systems/Rewards.lua"] = [[-- Daily/weekly live quests only if they have stages.
-- Empty stubs skipped via Config.SkipQuests.
-- ClaimAchievement RF args UNKNOWN — do not invent.

return function(GB)
	local M = {}

	local SAFE_DAILY = {
		"Easy Pickings",
		"Noise Complaint",
		"Corruption Cleanse",
	}

	function M.tick()
		if not GB.Config.AutoRewards then
			return
		end
		for _, name in ipairs(SAFE_DAILY) do
			if GB.PlayerData.live(name) then
				GB.Quest.doLive(name)
				return
			end
		end
	end

	return M
end
]],
    ["Systems/Shop.lua"] = [[-- Shop:FireServer("Purchase", InteractablePart, qty)
-- Rowboat: Ships:FireServer("Purchase", {Type="Rowboat"})
-- Sell: SellItem:FireServer(key [, amount])

return function(GB)
	local M = {}

	function M.buy(name, qty)
		qty = qty or 1
		if name == "Rowboat" then
			return GB.Boat.buyRowboat()
		end
		local price = GB.ItemData.shopPrice(name)
		local gold = GB.State.get().Gold or 0
		if price and gold < price * qty then
			GB.Log.log("SHOP", "need " .. tostring(price) .. "G for " .. name)
			return false
		end
		local part = GB.Resolver.shopItem(name)
		if not part then
			GB.Log.warn("SHOP", "no display " .. tostring(name))
			return false
		end
		local interact = (GB.Resolver.interactableOf and GB.Resolver.interactableOf(part)) or part
		if GB.World.ToInteractable then
			GB.World.ToInteractable(interact, 6)
		elseif not GB.World.moveTo(interact, 12) then
			GB.Log.warn("SHOP", "travel fail " .. tostring(name))
			return false
		end
		task.wait(0.15)
		local stock = interact:GetAttribute("Stock") or part:GetAttribute("Stock")
		local before = select(2, GB.PlayerData.hasItem(name))
		if stock then
			local idx = tonumber(interact.Parent and interact.Parent.Name)
			GB.Remotes.rotatingPurchase(idx, qty)
		else
			GB.Remotes.shopPurchase(interact, qty)
		end
		local pr = GB.Resolver.prompt(interact, "Shop Item") or GB.Resolver.prompt(interact)
		if pr and GB.World.firePrompt then
			GB.World.firePrompt(pr, pr.HoldDuration or 0, interact)
		end
		GB.Log.log("SHOP", "Purchase " .. name .. " x" .. qty)
		task.wait(0.45)
		local _, after = GB.PlayerData.hasItem(name)
		if after > before then
			GB.Recovery.markSuccess()
			return true
		end
		GB.Log.warn("SHOP", "purchase fired, item not in inventory yet")
		return false
	end

	function M.sellNamed(name)
		local inv = GB.PlayerData.cache().Inventory
		if type(inv) ~= "table" then
			return false
		end
		for k, v in pairs(inv) do
			local nm = type(v) == "table" and v.Name or k
			if nm == name then
				local key = type(v) == "table" and (v.Key or k) or k
				GB.Log.log("SHOP", "Sell " .. tostring(nm))
				return GB.Remotes.sell(key)
			end
		end
		return false
	end

	function M.tick()
		if not GB.Config.AutoShop then
			return
		end
		local gold = GB.State.get().Gold or 0
		-- save for progression buys
		for _, name in ipairs(GB.ItemData.PROGRESS_BUY) do
			local spec = GB.ItemData.SHOP[name]
			if spec and spec.need and GB.PlayerData.live(spec.need) then
				if not GB.PlayerData.hasItem(name) then
					if spec.gold and gold >= spec.gold then
						M.buy(name)
					end
				end
			end
		end
	end

	return M
end
]],
    ["Systems/Skills.lua"] = [[-- EquipSkill: scroll overlay → ConsumeSkillScroll(nil) → Skill("Equip", name).
-- Cast: dismiss TutorialScreen/SkillObtained first, then hotbar ToolFrame Title == name.
-- PromptSkillEquip only for Tool obtain popup.

return function(GB)
	local M = {
		lastEquip = {},
		lastCast = {},
	}

	local function pg()
		return GB.lp and GB.lp.PlayerGui
	end

	local function guiEnabled(name)
		local ui = pg() and pg():FindFirstChild(name)
		if not ui then
			return false
		end
		if ui:IsA("LayerCollector") then
			return ui.Enabled == true
		end
		return true
	end

	local function clickPath(path)
		local root = pg()
		if not (root and type(path) == "string") then
			return false
		end
		local cur = root
		for part in string.gmatch(path, "[^%.]+") do
			cur = cur:FindFirstChild(part)
			if not cur then
				return false
			end
		end
		if cur:IsA("GuiButton") then
			return GB.State.clickGui(cur)
		end
		local btn = cur:FindFirstChildWhichIsA("GuiButton", true)
		if btn then
			return GB.State.clickGui(btn)
		end
		return false
	end

	local function hotbar()
		local ui = pg()
		if not ui then
			return nil
		end
		local cur = ui:FindFirstChild("Backpack")
		for _, n in ipairs({ "Backpack", "BackpackFrame", "Scale", "Bars", "Scale", "Hotbar" }) do
			cur = cur and cur:FindFirstChild(n)
		end
		return cur
	end

	local function hotbarSlot(title)
		local bar = hotbar()
		if not bar then
			return nil, nil
		end
		for _, child in ipairs(bar:GetChildren()) do
			local tf = child:FindFirstChild("ToolFrame")
			local lab = tf and tf:FindFirstChild("Title")
			if lab and (lab:IsA("TextLabel") or lab:IsA("TextButton")) and lab.Text == title then
				return tf, child
			end
		end
		return nil, nil
	end

	local function skillInStorage(name)
		local skills = pg() and pg():FindFirstChild("Skills")
		if not skills then
			return nil
		end
		local sf = skills:FindFirstChild("ScrollingFrame")
		local storage = sf and sf:FindFirstChild("Storage")
		return storage and storage:FindFirstChild(name)
	end

	local function skillEquipped(name)
		local owned, eq = GB.PlayerData.skillOwned(name)
		if eq then
			return true
		end
		if hotbarSlot(name) then
			return true
		end
		return owned and skillInStorage(name) == nil and hotbarSlot(name) ~= nil
	end

	local function overlayMessage()
		local ui = pg()
		if not ui then
			return ""
		end
		for _, d in ipairs(ui:GetDescendants()) do
			if (d:IsA("TextLabel") or d:IsA("TextButton")) and type(d.Text) == "string" then
				if string.find(d.Text, "skill scroll", 1, true) or string.find(d.Text, "unlock the skill", 1, true) then
					return d.Text
				end
			end
		end
		return ""
	end

	local function findScrollKey(name)
		local inv = GB.PlayerData.cache().Inventory
		if type(inv) ~= "table" then
			return nil
		end
		local want = { "Skill: " .. name, "Skill Scroll", name }
		for _, w in ipairs(want) do
			if inv[w] then
				local row = inv[w]
				return (type(row) == "table" and (row.Key or row.Name)) or w
			end
		end
		for k, v in pairs(inv) do
			if type(v) == "table" then
				local nm = v.Name or k
				if nm == "Skill Scroll" and (v.Value == name or v.Skill == name) then
					return v.Key or k
				end
				if nm == "Skill: " .. name or nm == name then
					return v.Key or k
				end
			end
		end
		return nil
	end

	local function consumeScroll(name)
		local scrollUi = pg() and pg():FindFirstChild("SkillScroll")
		if scrollUi then
			local frame = scrollUi:FindFirstChild("Frame")
			local btn = frame and frame:FindFirstChild("ImageButton")
			if btn and btn:IsA("GuiButton") then
				GB.Log.log("SKILL", "click SkillScroll unlock")
				GB.State.clickGui(btn)
			end
		end
		GB.Remotes.consumeSkillScroll()
		return true
	end

	local function openSkillsMenu()
		if guiEnabled("Skills") then
			return true
		end
		if not guiEnabled("Menu") then
			clickPath("TopbarStandard.Holders.Left.Menu")
			task.wait(0.2)
		end
		clickPath("Menu.ContainerFrame.Icons.Skills")
		task.wait(0.25)
		return guiEnabled("Skills")
	end

	local function closeMenus()
		if guiEnabled("Skills") then
			clickPath("Skills.TopBar.BackButton")
			task.wait(0.15)
		end
		if guiEnabled("Menu") then
			clickPath("Menu.ContainerFrame.Icons.Close")
			task.wait(0.15)
		end
	end

	function M.equip(name)
		if not name then
			return false
		end
		if GB.State.tutorialOverlayVisible() then
			GB.State.dismissTutorialOverlay()
			return false
		end
		if os.clock() - (M.lastEquip[name] or 0) < 0.9 then
			return false
		end
		M.lastEquip[name] = os.clock()
		GB.Combat.stopLock()

		if skillEquipped(name) then
			GB.Log.log("SKILL", name .. " already equipped")
			return true
		end

		local msg = overlayMessage()
		local scrollSlot = hotbarSlot("Skill: " .. name)
		local scrollUi = pg() and pg():FindFirstChild("SkillScroll")
		local lastTool = scrollUi and scrollUi:GetAttribute("LastToolName")

		if scrollSlot or (type(msg) == "string" and string.find(msg, "skill scroll", 1, true)) or lastTool then
			GB.Log.log("SKILL", "scroll flow " .. name)
			if scrollSlot and not lastTool then
				GB.State.clickGui(scrollSlot:FindFirstChildWhichIsA("GuiButton", true) or scrollSlot)
				task.wait(0.25)
			end
			local key = findScrollKey(name)
			if key then
				GB.Remotes.heldEquip(key)
				task.wait(0.25)
			end
			consumeScroll(name)
			task.wait(0.35)
		end

		if skillInStorage(name) or GB.PlayerData.skillOwned(name) then
			GB.Log.log("SKILL", "Skill Equip " .. name)
			GB.Remotes.skillEquip(name)
			if openSkillsMenu() then
				local icon = skillInStorage(name)
				if icon then
					local btn = icon:IsA("GuiButton") and icon or icon:FindFirstChildWhichIsA("GuiButton", true)
					if btn then
						GB.State.clickGui(btn)
						task.wait(0.2)
					end
				end
				clickPath("Skills.RightFrame.InfoFrame.Equip Button")
				clickPath("Skills.Frame.Equip Button")
			end
		elseif GB.Remotes.promptSkillEquip(name) then
			GB.Log.log("SKILL", "PromptSkillEquip " .. name)
		end

		task.wait(0.3)
		if skillEquipped(name) then
			return true
		end
		GB.Log.warn("SKILL", "equip not confirmed " .. name)
		return false
	end

	local SLOT_KEYS = {
		Enum.KeyCode.One,
		Enum.KeyCode.Two,
		Enum.KeyCode.Three,
		Enum.KeyCode.Four,
		Enum.KeyCode.Five,
		Enum.KeyCode.Six,
		Enum.KeyCode.Seven,
		Enum.KeyCode.Eight,
		Enum.KeyCode.Nine,
		Enum.KeyCode.Zero,
	}

	local function skillInfo(name)
		local ok, SI = pcall(function()
			return require(game:GetService("ReplicatedStorage").Modules.SkillInformation)
		end)
		if not (ok and type(SI) == "table" and SI.GetSkillInfo) then
			return nil
		end
		local ok2, info = pcall(SI.GetSkillInfo, name)
		if ok2 and type(info) == "table" then
			return info
		end
		return nil
	end

	local function chargeHoldSec(name)
		local info = skillInfo(name)
		if not (info and info.ChargeInfo) then
			return nil
		end
		local base = info.BaseInfo or {}
		local ok, ci = pcall(info.ChargeInfo, base)
		if ok and type(ci) == "table" and type(ci.minimumDuration) == "number" then
			return ci.minimumDuration
		end
		return type(base.Windup) == "number" and base.Windup or 0.35
	end

	function M.isHoldSkill(name)
		if chargeHoldSec(name) then
			return true
		end
		local tf = select(1, hotbarSlot(name))
		if not tf then
			return false
		end
		local extra = tf:FindFirstChild("ExtraText", true)
		if extra and (extra:IsA("TextLabel") or extra:IsA("TextButton")) then
			return string.upper(tostring(extra.Text or "")) == "HOLD"
		end
		return false
	end

	function M.hotbarIndex(title)
		local _, child = hotbarSlot(title)
		if not child then
			return nil
		end
		local n = tonumber(child.Name)
		if n then
			return n
		end
		if type(child.LayoutOrder) == "number" and child.LayoutOrder > 0 then
			return child.LayoutOrder
		end
		return nil
	end

	function M.resolveShootSkill()
		if hotbarSlot("Gunshot") then
			return "Gunshot"
		end
		local bar = hotbar()
		if bar then
			for _, child in ipairs(bar:GetChildren()) do
				local tf = child:FindFirstChild("ToolFrame")
				local extra = tf and tf:FindFirstChild("ExtraText", true)
				local lab = tf and tf:FindFirstChild("Title")
				if extra and (extra:IsA("TextLabel") or extra:IsA("TextButton")) and string.upper(tostring(extra.Text or "")) == "HOLD" then
					if lab and (lab:IsA("TextLabel") or lab:IsA("TextButton")) and type(lab.Text) == "string" and lab.Text ~= "" then
						return lab.Text
					end
				end
			end
		end
		return "Gunshot"
	end

	local function backpackEnv()
		if typeof(getsenv) ~= "function" then
			return nil
		end
		local ui = pg()
		local bp = ui and ui:FindFirstChild("Backpack")
		if not bp then
			return nil
		end
		local ls = bp:FindFirstChild("BackpackLocal", true)
		if not (ls and ls:IsA("LocalScript")) then
			for _, d in ipairs(bp:GetDescendants()) do
				if d:IsA("LocalScript") and d.Name == "BackpackLocal" then
					ls = d
					break
				end
			end
		end
		if not ls then
			return nil
		end
		local ok, env = pcall(getsenv, ls)
		if ok and type(env) == "table" then
			return env
		end
		return nil
	end

	local function pressSlot(idx, down)
		local key = SLOT_KEYS[idx]
		if not key then
			return false
		end
		local ev = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
		local pk = ev and ev:FindFirstChild("PressKey")
		if not pk then
			return false
		end
		if down == false then
			return pcall(function()
				pk:Fire(key, Enum.UserInputType.Keyboard, false)
			end)
		end
		return pcall(function()
			pk:Fire(key, Enum.UserInputType.Keyboard)
		end)
	end

	function M.aimAt(target)
		if typeof(target) ~= "Instance" then
			return false
		end
		local part = GB.Resolver and GB.Resolver.part and GB.Resolver.part(target)
		if not (part and part:IsA("BasePart")) then
			local hrp = target:FindFirstChild("HumanoidRootPart")
			part = (hrp and hrp:IsA("BasePart") and hrp) or (target.PrimaryPart and target.PrimaryPart:IsA("BasePart") and target.PrimaryPart)
		end
		local root = GB.World and GB.World.hrp and GB.World.hrp()
		if not (part and part:IsA("BasePart") and root) then
			return false
		end
		local dest = root.Position
		root.CFrame = CFrame.new(dest, Vector3.new(part.Position.X, dest.Y, part.Position.Z))
		local cam = workspace.CurrentCamera
		if cam then
			local origin = dest + Vector3.new(0, 1.5, 0)
			pcall(function()
				cam.CFrame = CFrame.new(origin, part.Position)
			end)
			local sp, on = cam:WorldToViewportPoint(part.Position)
			if on then
				local vim = game:GetService("VirtualInputManager")
				if vim and vim.SendMouseMoveEvent then
					pcall(function()
						vim:SendMouseMoveEvent(sp.X, sp.Y, game)
					end)
				end
			end
		end
		return true
	end

	function M.castHold(name, opts)
		opts = opts or {}
		if not name then
			return false
		end
		if GB.State.tutorialOverlayVisible() then
			GB.State.dismissTutorialOverlay()
			return false
		end
		local cd = opts.cooldown or 6.2
		if os.clock() - (M.lastCast[name] or 0) < cd then
			return false
		end
		if not opts.keepLock and GB.Combat and GB.Combat.stopLock then
			GB.Combat.stopLock()
		end
		if not skillEquipped(name) then
			M.equip(name)
			task.wait(0.2)
		end
		closeMenus()
		if opts.target then
			M.aimAt(opts.target)
		end
		local idx = M.hotbarIndex(name) or 5
		local hold = opts.hold or ((chargeHoldSec(name) or 0.35) + 0.12)
		local env = backpackEnv()
		local method = nil
		if env and type(env.UseTool) == "function" then
			if pcall(env.UseTool, idx, true) then
				method = "UseTool"
			end
		end
		if not method then
			if pressSlot(idx, true) then
				method = "PressKey"
			end
		end
		if not method then
			GB.Log.warn("SKILL", "hold press miss " .. name)
			return false
		end
		M.lastCast[name] = os.clock()
		GB.Log.log("SKILL", string.format("hold %s slot=%s %.2fs via %s", name, tostring(idx), hold, method))
		task.wait(hold)
		if opts.target then
			M.aimAt(opts.target)
		end
		if method == "UseTool" and env and type(env.ReleaseTool) == "function" then
			pcall(env.ReleaseTool, idx)
		else
			pressSlot(idx, false)
		end
		GB.Log.log("SKILL", "release " .. name)
		return true
	end

	function M.cast(name, opts)
		if M.isHoldSkill(name) then
			return M.castHold(name, opts)
		end
		if not name then
			return false
		end
		if GB.State.tutorialOverlayVisible() then
			GB.State.dismissTutorialOverlay()
			return false
		end
		if os.clock() - (M.lastCast[name] or 0) < 0.7 then
			return false
		end
		M.lastCast[name] = os.clock()
		if not (opts and opts.keepLock) and GB.Combat then
			GB.Combat.stopLock()
		end
		if not skillEquipped(name) then
			M.equip(name)
			task.wait(0.2)
		end
		closeMenus()
		local slot = hotbarSlot(name)
		if slot then
			GB.Log.log("SKILL", "cast hotbar " .. name)
			local btn = slot:FindFirstChildWhichIsA("GuiButton", true) or slot
			GB.State.clickGui(btn)
			local char = GB.World.char()
			local tool = char and char:FindFirstChild(name)
			if tool and tool:IsA("Tool") and tool.Activate then
				tool:Activate()
			end
			return true
		end
		local ev = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
		local pk = ev and ev:FindFirstChild("PressKey")
		if pk then
			pk:Fire(Enum.KeyCode.One)
			GB.Log.log("SKILL", "cast PressKey One " .. name)
			return true
		end
		GB.Log.warn("SKILL", "cast miss hotbar " .. name)
		return false
	end

	function M.ensure(name)
		return M.equip(name)
	end

	function M.tick()
		if not GB.Config.AutoSkills then
			return
		end
		local cur = GB.PlayerData.current()
		if not cur then
			return
		end
		local qs = GB.Quest.questState(cur)
		local obj = qs and qs.Objective
		if not obj then
			return
		end
		if obj.Type == "EquipSkill" then
			M.equip(obj.TargetName)
		elseif obj.Type == "Cast" then
			M.cast(obj.TargetName)
		end
	end

	return M
end
]],
    ["Systems/Stats.lua"] = [[-- Traced from live MenuHandler callback:
-- ImageButton.Activated -> Events.StatPoints:FireServer("Invest", child.Name, tonumber(TextBox.Text) or 1)
-- UI refresh path: UpdateStats(Events.GetStats:InvokeServer()) + StatPoints.OnClientEvent.

return function(GB)
	local M = {}

	local ORDER = { "Strength", "Health", "Willpower", "Agility", "Precision", "Energy" }
	local STATE_TTL = 1.1
	local GUI_TTL = 3.2
	local VERIFY_TIMEOUT = 3.1
	local BLOCK_RETRY_GAP = 20
	local FAIL_PAUSE_GAP = 45

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

	M._dirty = true
	M._pausedUntil = 0

	local function cloneState(src)
		local out = { Source = src and src.Source or "Unknown" }
		for _, name in ipairs(ORDER) do
			out[name] = tonumber(src and src[name]) or 0
		end
		out.Unused = math.max(0, math.floor(tonumber(src and src.Unused) or 0))
		return out
	end

	local function normalizeStats(raw)
		if type(raw) ~= "table" then
			return nil
		end
		local out = {}
		local any = false
		for _, name in ipairs(ORDER) do
			local v = tonumber(raw[name])
			if v ~= nil then
				any = true
			end
			out[name] = v or 0
		end
		if not any then
			return nil
		end
		return out
	end

	local function pullTuple(a, b)
		local stats
		local unused
		if type(a) == "table" then
			stats = a
		elseif type(b) == "table" then
			stats = b
		end
		if type(a) == "number" then
			unused = a
		end
		if type(b) == "number" then
			unused = b
		end
		return stats, unused
	end

	local function resolveGuiStatLabel()
		if M._guiLabel and M._guiLabel.Parent then
			return M._guiLabel
		end
		perfCount("PlayerGuiFullScan", 1)
		local lp = GB.lp
		local pg = lp and lp.PlayerGui
		if not pg then
			return nil
		end
		local menu = pg:FindFirstChild("Menu")
		local radar = menu and menu:FindFirstChild("Radar", true)
		local statNode = radar and radar:FindFirstChild("StatpointText", true)
		local label = statNode and statNode:FindFirstChild("StatpointText")
		if not label and statNode and (statNode:IsA("TextLabel") or statNode:IsA("TextButton") or statNode:IsA("TextBox")) then
			label = statNode
		end
		if not label then
			local progression = pg:FindFirstChild("Progression")
			local fallback = progression and progression:FindFirstChild("StatpointText", true)
			if fallback and (fallback:IsA("TextLabel") or fallback:IsA("TextButton") or fallback:IsA("TextBox")) then
				label = fallback
			end
		end
		M._guiLabel = label
		return label
	end

	local function guiUnused()
		local now = os.clock()
		if M._guiUnused ~= nil and now - (M._guiAt or 0) < GUI_TTL then
			return M._guiUnused
		end
		local label = resolveGuiStatLabel()
		local n
		if GB.State and GB.State.guiNum then
			n = GB.State.guiNum(label)
		end
		M._guiUnused = tonumber(n)
		M._guiAt = now
		return M._guiUnused
	end

	local function pullRemoteState(force)
		local now = os.clock()
		if not force and M._remoteStats and now - (M._remoteAt or 0) < STATE_TTL then
			return M._remoteStats, M._remoteUnused, "GetStatsCache"
		end
		local a, b
		if GB.PlayerData and GB.PlayerData.pullStats then
			a, b = GB.PlayerData.pullStats()
		else
			a, b = GB.Remotes.getStats()
		end
		local statsRaw, unusedRaw = pullTuple(a, b)
		local stats = normalizeStats(statsRaw)
		if stats then
			M._remoteStats = stats
			M._remoteUnused = tonumber(unusedRaw)
			M._remoteAt = now
			return stats, tonumber(unusedRaw), "GetStats"
		end
		local live, pts, src
		if GB.PlayerData and GB.PlayerData.latestStats then
			live, pts, src = GB.PlayerData.latestStats()
		end
		stats = normalizeStats(live)
		if stats then
			M._remoteStats = stats
			M._remoteUnused = tonumber(pts) or M._remoteUnused
			M._remoteAt = now
			return stats, tonumber(pts), src or "StatPointsEvent"
		end
		return nil, nil, nil
	end

	function M.ReadStatState(opts)
		opts = opts or {}
		local now = os.clock()
		if not opts.force and M._state and now - (M._stateAt or 0) < STATE_TTL then
			return cloneState(M._state)
		end
		local stats, unused, source = pullRemoteState(opts.force == true)
		if not stats then
			local snap = GB.State and GB.State.get and GB.State.get() or nil
			stats = normalizeStats(snap and snap.Stats or nil)
			if stats then
				source = source or "StateSnapshot"
			end
			if unused == nil and snap then
				unused = tonumber(snap.StatPoints)
			end
		end
		if unused == nil then
			local n = GB.PlayerData and GB.PlayerData.unusedStatPoints and GB.PlayerData.unusedStatPoints() or nil
			if type(n) == "number" then
				unused = n
				source = source or "PlayerDataCache"
			end
		end
		if unused == nil then
			local g = guiUnused()
			if type(g) == "number" then
				unused = g
				source = source or "GUIFallback"
			end
		end
		local out = { Source = source or "Unknown" }
		for _, name in ipairs(ORDER) do
			out[name] = tonumber(stats and stats[name]) or 0
		end
		out.Unused = math.max(0, math.floor(tonumber(unused) or 0))
		M._state = out
		M._stateAt = now
		return cloneState(out)
	end

	local function fmtCore(state)
		return string.format(
			"unused=%d Str=%d Hp=%d",
			tonumber(state and state.Unused) or 0,
			tonumber(state and state.Strength) or 0,
			tonumber(state and state.Health) or 0
		)
	end

	local function markBlocked(reason)
		M._blocked = true
		M._blockedReason = reason
		M._blockedAt = os.clock()
	end

	local function clearBlocked()
		M._blocked = false
		M._blockedReason = nil
		M._blockedAt = nil
		M._pausedUntil = 0
	end

	function M.markDirty(reason)
		M._dirty = true
		M._dirtyAt = os.clock()
		if reason and (not M._dirtyLogAt or os.clock() - M._dirtyLogAt > 2.5) then
			M._dirtyLogAt = os.clock()
			GB.Log.log("STAT", "dirty " .. tostring(reason))
		end
	end

	local function gateNeedsStrength(state)
		local blockers = GB.Quest and GB.Quest.CurrentBlockers and GB.Quest.CurrentBlockers() or nil
		if type(blockers) == "table" then
			for _, b in ipairs(blockers) do
				if b.Type == "STAT_REQUIREMENT" and b.Stat == "Strength" then
					local req = tonumber(b.Required) or 0
					if req > 0 and (state.Strength or 0) < req then
						return true, req
					end
				end
			end
		end
		local cur = GB.PlayerData and GB.PlayerData.current and GB.PlayerData.current() or nil
		if cur == "Gate of Authority" and (state.Strength or 0) < 100 then
			return true, 100
		end
		return false, nil
	end

	local function pickNextStat(state)
		if gateNeedsStrength(state) then
			return "Strength"
		end
		local str = tonumber(state.Strength) or 0
		local hp = tonumber(state.Health) or 0
		local strTarget = (str + hp) * 0.8
		if str <= strTarget then
			return "Strength"
		end
		return "Health"
	end

	local function beginInvest(statName, amount, phase)
		local before = M.ReadStatState({ force = true })
		amount = math.max(1, math.floor(tonumber(amount) or 1))
		if before.Unused < 1 then
			return false, "no_points", before
		end
		if before.Unused < amount then
			amount = before.Unused
		end
		if amount < 1 then
			return false, "no_points", before
		end
		GB.Log.log("STAT", "before " .. fmtCore(before) .. " src=" .. tostring(before.Source))
		local phase = (not M._remoteVerified and statName == "Strength" and amount == 1) and "test" or "invest"
		GB.Log.log("STAT", string.format("%s %s x%d", phase, tostring(statName), amount))
		local ok, err = GB.Remotes.statInvest(statName, amount)
		if not ok then
			return false, err or "remote", before
		end
		M._pending = {
			Phase = phase or "auto",
			Stat = statName,
			Amount = amount,
			Before = before,
			StartedAt = os.clock(),
			Deadline = os.clock() + VERIFY_TIMEOUT,
		}
		M._attempted = true
		M._dirty = false
		return true, "sent", before
	end

	local function pendingVerified(after)
		local p = M._pending
		if not p then
			return false
		end
		local before = p.Before
		local statGain = (tonumber(after[p.Stat]) or 0) - (tonumber(before[p.Stat]) or 0)
		local used = (tonumber(before.Unused) or 0) - (tonumber(after.Unused) or 0)
		return statGain >= p.Amount and used >= p.Amount
	end

	function M.poll()
		local p = M._pending
		if not p then
			return nil
		end
		local after = M.ReadStatState({ force = true })
		if pendingVerified(after) then
			M._remoteVerified = true
			clearBlocked()
			M._pending = nil
			M._state = after
			M._stateAt = os.clock()
			M._dirty = (tonumber(after.Unused) or 0) > 0
			GB.Log.log("STAT", "after " .. fmtCore(after) .. " VERIFIED src=" .. tostring(after.Source))
			if GB.Recovery and GB.Recovery.markSuccess then
				GB.Recovery.markSuccess()
			end
			return true
		end
		if os.clock() < p.Deadline then
			return false, "waiting"
		end
		GB.Log.warn("STAT", string.format("[FAIL] unchanged unused=%d Str=%d", tonumber(after.Unused) or 0, tonumber(after.Strength) or 0))
		M._pending = nil
		M._dirty = false
		M._pausedUntil = os.clock() + FAIL_PAUSE_GAP
		markBlocked("no_state_transition")
		GB.Log.warn("STAT", "AutoStats paused after failed canary")
		return false, "no_state_transition"
	end

	function M.unused()
		local s = M.ReadStatState()
		return s.Unused
	end

	function M.Invest(statName, amount)
		if M._pending then
			return false, "pending"
		end
		M.markDirty("manual")
		statName = tostring(statName or "Strength")
		for _, n in ipairs(ORDER) do
			if n == statName then
				return beginInvest(statName, amount, "manual")
			end
		end
		return false, "bad_stat"
	end

	function M.investMinimum(n)
		if M._pending then
			return true, "pending"
		end
		n = math.max(1, math.floor(tonumber(n) or 1))
		local state = M.ReadStatState()
		local stat = (not M._remoteVerified and "Strength") or pickNextStat(state) or "Strength"
		-- Verify one-point transitions first; avoid large unverified bursts.
		return beginInvest(stat, math.min(1, n), "quest")
	end

	function M.status()
		if M._remoteVerified then
			return "RUNTIME_VERIFIED", nil
		end
		if M._blocked then
			return "BLOCKED", M._blockedReason
		end
		if M._attempted then
			return "IMPLEMENTED_UNVERIFIED", nil
		end
		return "IMPLEMENTED", nil
	end

	function M.tick()
		local t0 = pbegin()
		if not GB.Config.AutoStats then
			pdone("Stats.tick", t0)
			return
		end
		if os.clock() < (M._pausedUntil or 0) then
			if not M._blockedLogAt or os.clock() - M._blockedLogAt > 10 then
				M._blockedLogAt = os.clock()
				GB.Log.warn("STAT", "paused waiting for retry window")
			end
			pdone("Stats.tick", t0)
			return
		end
		M.poll()
		if M._pending then
			pdone("Stats.tick", t0)
			return
		end
		local snap = GB.State and GB.State.get and GB.State.get() or nil
		local snapUnused = tonumber(snap and snap.StatPoints)
		local snapLevel = tonumber(snap and snap.Level)
		if snapUnused ~= nil and snapUnused ~= M._lastUnused then
			M._lastUnused = snapUnused
			if snapUnused > 0 then
				M.markDirty("stat_points_changed")
			end
		end
		if snapLevel ~= nil and snapLevel ~= M._lastLevel then
			M._lastLevel = snapLevel
			M.markDirty("level_changed")
		end
		if M._blocked and os.clock() - (M._blockedAt or 0) >= BLOCK_RETRY_GAP then
			clearBlocked()
			M.markDirty("retry_window")
		end
		if M._blocked and os.clock() - (M._blockedAt or 0) < BLOCK_RETRY_GAP then
			if not M._blockedLogAt or os.clock() - M._blockedLogAt > 10 then
				M._blockedLogAt = os.clock()
				GB.Log.warn("STAT", "blocked " .. tostring(M._blockedReason or "unknown"))
			end
			pdone("Stats.tick", t0)
			return
		end
		if not M._dirty then
			pdone("Stats.tick", t0)
			return
		end
		local state = M.ReadStatState()
		if state.Unused < 1 then
			if not M._zeroAt or os.clock() - M._zeroAt > 12 then
				M._zeroAt = os.clock()
				GB.Log.log("STAT", "unused=0 (no invest)")
			end
			M._dirty = false
			pdone("Stats.tick", t0)
			return
		end
		local stat = pickNextStat(state)
		if not M._remoteVerified then
			stat = "Strength"
		end
		if not stat then
			pdone("Stats.tick", t0)
			return
		end
		local ok, why = beginInvest(stat, 1, "auto")
		if not ok and why ~= "no_points" and why ~= "rate" then
			markBlocked("send_failed:" .. tostring(why))
			GB.Log.warn("STAT", "[FAIL] invest send " .. tostring(why))
		end
		pdone("Stats.tick", t0)
	end

	return M
end
]],
    ["Systems/Travel.lua"] = [[-- World graph. Walk / boat / verified travel. No stale tele.

return function(GB)
	local M = {}

	function M.goIsland(name)
		local snap = GB.State.get()
		if snap.PhysicalIsland == name then
			return true
		end
		local dest = GB.World.islandSpawn(name)
		if dest and GB.World.destOk(dest) then
			GB.Log.log("TRAVEL", "walk/hop " .. name)
			return GB.World.moveTo(dest, 20)
		end
		if name == "Clown Town" and not GB.PlayerData.finished("Setting Sail", true) then
			return false
		end
		if name == "Maple Village" and not GB.PlayerData.finished("Journey to Maple Village", true) then
			if GB.PlayerData.live("Journey to Maple Village") then
				return GB.Boat.travelToward("Maple Village")
			end
			return false
		end
		if name ~= snap.CurrentIsland then
			GB.Log.log("TRAVEL", "need progress gate for " .. name)
		end
		return false
	end

	function M.tick()
		if not GB.Config.AutoTravel then
			return
		end
		local snap = GB.State.get()
		if snap.PhysicalIsland and snap.CurrentIsland and snap.PhysicalIsland ~= snap.CurrentIsland then
			M.goIsland(snap.CurrentIsland)
		end
	end

	return M
end
]],
    ["Systems/Treasure.lua"] = [[-- Treasure Map (Easy) from Finders Keepers. Dig remotes args UNKNOWN.
-- Move to map/dig if live quest; no invented ShovelHit payload.

return function(GB)
	local M = {}

	function M.tick()
		if not GB.Config.AutoTreasure then
			return
		end
		if GB.PlayerData.live("Finders Keepers") or GB.PlayerData.live("The 'Priceless' Haul") then
			local obj = GB.Resolver.byName("Wade's Belongings") or GB.Resolver.byName("Wade")
			if obj then
				GB.World.moveTo(obj, 8)
			end
		end
	end

	return M
end
]],
    ["Systems/Tutorial.lua"] = [[-- Blocking tutorial / UI gates. Complete the real client action; never hide GUI.
-- Source: QuestInfo.Functions.TutorialFolder + ScreenShadow + QuestOverlay.

return function(GB)
	local M = {
		lastStep = nil,
		lastAt = 0,
		lastAction = nil,
		attempts = 0,
		owner = nil,
		lastGate = nil,
		lastMethod = nil,
		lastTransition = nil,
		continueAttempts = 0,
		unresolved = nil,
		dumpedTree = nil,
		_overlayText = nil,
		_overlayTextSrc = nil,
		_overlayTextAt = 0,
	}

	M.GateTypes = {
		ContinueOverlay = "ContinueOverlay",
		ActionRequired = "ActionRequired",
		Dialogue = "Dialogue",
		UISelection = "UISelection",
		EquipRequired = "EquipRequired",
		InputRequired = "InputRequired",
	}
	local OVERLAY_TEXT_TTL = 0.65

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

	-- Studio-verified fullscreen continue overlays (no GuiButton).
	M.CONTINUE_OVERLAYS = {
		SkillObtained = {
			script = "PassiveObtained",
			continuation = "UIS.InputBegan",
			listenDelay = 3.15,
			event = true,
		},
		TutorialScreen = {
			script = "TutorialLocal",
			continuation = "UIS.InputBegan",
			listenDelay = 0.75,
			event = false,
		},
	}

	-- Verified TutorialFolder modules (Studio place 118635363908336)
	M.REGISTRY = {
		{
			id = "EquipFlintlock",
			quest = "Gearing Up",
			texts = {
				"Open the backpack.",
				"Hold and drag the Flintlock to the weapon slot.",
				"Drop it on the weapon slot.",
			},
		},
		{
			id = "EquipStrongPunch",
			quest = "Basics",
			texts = {
				"Select the 'Strong Punch' skill scroll",
				"Press the button to unlock the skill",
			},
		},
		{
			id = "CastStrongPunch",
			quest = "Basics",
			texts = {},
		},
		{
			id = "InvestStats",
			quest = "Basics",
			texts = {
				"Open the menu",
				"Invest a point in to a stat",
			},
		},
		{
			id = "ForceOpenLogbook",
			quest = "Basics",
			texts = {
				"Open the Logbook",
				"Open the Tutorial",
				"Read the first tutorial page",
			},
		},
		{
			id = "SellWatch",
			quest = "Gearing Up",
			texts = {
				"Ask to sell your goods",
				"Sell the Stolen Watch",
				"Sell it!",
			},
		},
		{
			id = "UpgradeFlintlock",
			quest = "First Upgrade",
			texts = {
				"Select Flintlock",
				"Click Upgrade",
			},
		},
		{
			id = "EquippedWeapon",
			quest = "First Upgrade",
			texts = {
				"Select Flintlock",
				"Click Upgrade",
			},
		},
		{
			id = "SmeltTutorial",
			quest = "First Upgrade",
			texts = {
				"Select Copper Bar",
				"Click Craft",
			},
		},
		{
			id = "UnsheathWeapon",
			quest = nil,
			texts = {
				"Toggle your weapon",
			},
		},
		{
			id = "CraftStoneRing",
			quest = "Miners Stone Ring",
			texts = {
				"Open your backpack",
				"Select the 'Stone Ring Recipe' scroll",
				"Press the button to learn the recipe",
			},
		},
		{
			id = "PunchTraining",
			quest = "Introduction",
			texts = {},
		},
		{
			id = "UpgradeSkill",
			quest = nil,
			texts = {},
		},
		{
			id = "Pets",
			quest = nil,
			texts = {},
		},
		{
			id = "SkillObtained",
			quest = nil,
			texts = {
				"PRESS ANYWHERE TO CONTINUE",
				"Press anywhere to continue",
			},
		},
	}

	local function guiText(inst)
		return GB.State and GB.State.guiText(inst)
	end

	local function overlayKeyword(t)
		if type(t) ~= "string" or #t < 5 or #t > 90 then
			return false
		end
		local low = string.lower(t)
		return string.find(low, "backpack", 1, true)
			or string.find(low, "drag", 1, true)
			or string.find(low, "open the", 1, true)
			or string.find(low, "select", 1, true)
			or string.find(low, "invest", 1, true)
			or string.find(low, "sell", 1, true)
	end

	local function collectOverlayText(root, budget)
		if not (root and budget and budget > 0) then
			return nil, budget or 0
		end
		for _, d in ipairs(root:GetChildren()) do
			if budget <= 0 then
				break
			end
			if d:IsA("TextLabel") or d:IsA("TextButton") then
				local t = d.Text
				if overlayKeyword(t) then
					return t, budget
				end
				budget = budget - 1
			end
			local hit
			hit, budget = collectOverlayText(d, budget)
			if hit then
				return hit, budget
			end
		end
		return nil, budget
	end

	local function overlayText()
		local now = os.clock()
		if now - (M._overlayTextAt or 0) < OVERLAY_TEXT_TTL then
			if M._overlayText == false then
				return nil, nil
			end
			return M._overlayText, M._overlayTextSrc
		end
		perfCount("QuestGuiScan", 1)
		local pg = GB.lp and GB.lp.PlayerGui
		if not pg then
			M._overlayText = false
			M._overlayTextSrc = nil
			M._overlayTextAt = now
			return nil
		end
		local qo = pg:FindFirstChild("QuestOverlay")
		if qo then
			local msg = qo:FindFirstChild("QuestMessage") or qo:FindFirstChildWhichIsA("TextLabel", true)
			local t = guiText(msg)
			if type(t) == "string" and t ~= "" then
				M._overlayText = t
				M._overlayTextSrc = "QuestOverlay"
				M._overlayTextAt = now
				return t, "QuestOverlay"
			end
		end
		local ss = pg:FindFirstChild("ScreenShadow")
		if ss then
			local hit = collectOverlayText(ss, 120)
			if hit then
				M._overlayText = hit
				M._overlayTextSrc = "ScreenShadow"
				M._overlayTextAt = now
				return hit, "ScreenShadow"
			end
		end
		M._overlayText = false
		M._overlayTextSrc = nil
		M._overlayTextAt = now
		return nil, nil
	end

	local function matchRegistry(text, quest)
		if type(text) == "string" then
			for _, row in ipairs(M.REGISTRY) do
				for _, needle in ipairs(row.texts) do
					if text == needle or string.find(text, needle, 1, true) then
						return row, needle
					end
				end
			end
		end
		if quest then
			for _, row in ipairs(M.REGISTRY) do
				if row.quest == quest then
					return row, nil
				end
			end
		end
		return nil, nil
	end

	function M.readInstruction()
		return overlayText()
	end

	function M.snapshot()
		local text, src = overlayText()
		local cur = GB.PlayerData and GB.PlayerData.current and GB.PlayerData.current()
		local qs = cur and GB.Quest and GB.Quest.questState(cur)
		local obj = qs and qs.Objective
		local row, needle = matchRegistry(text, nil)
		if not row and obj and obj.Type == "Equip" then
			row = matchRegistry(nil, cur)
		end
		local backpackOpen = GB.Backpack and GB.Backpack.isOpen and GB.Backpack.isOpen()
		local dialogue = false
		local pg = GB.lp and GB.lp.PlayerGui
		local dui = pg and pg:FindFirstChild("DialogueUI")
		if dui and dui:IsA("LayerCollector") and dui.Enabled == true then
			dialogue = true
		end
		local overlayVis, overlayUi = false, nil
		if GB.State and GB.State.tutorialOverlayVisible then
			overlayVis, overlayUi = GB.State.tutorialOverlayVisible()
		end
		local modalName = overlayUi and overlayUi.Name or nil
		local blocking = false
		if text then
			local low = string.lower(text)
			if string.find(low, "open the backpack", 1, true)
				or string.find(low, "open your backpack", 1, true)
				or string.find(low, "drag the flintlock", 1, true)
				or string.find(low, "weapon slot", 1, true)
			then
				blocking = true
				row = row or matchRegistry(text, cur)
			end
		end
		if obj and obj.Type == "Equip" and obj.TargetName == "Flintlock" then
			local geared = GB.Backpack and GB.Backpack.isGearEquipped and GB.Backpack.isGearEquipped("Flintlock")
			if not geared then
				blocking = true
				row = row or { id = "EquipFlintlock" }
			end
		end
		if overlayVis then
			blocking = true
			if modalName == "SkillObtained" then
				row = { id = "SkillObtained" }
				if overlayUi and GB.State.skillNameOf then
					text = GB.State.skillNameOf(overlayUi) or text
					src = "SkillObtained"
				end
			elseif modalName == "TutorialScreen" then
				row = row or { id = "UnlockSkill" }
			end
		elseif M.lastStep and string.find(tostring(M.lastStep), "SkillObtained", 1, true) then
			if M.lastTransition ~= "cleared" then
				GB.Log.log("GATE", "SkillObtained cleared")
			end
			M.releaseTutorial("cleared")
		end
		return {
			Blocking = blocking,
			TutorialActive = blocking or overlayVis == true,
			TutorialText = text,
			TutorialStep = (row and row.id) or needle,
			TutorialSource = src,
			Modal = modalName,
			GateType = overlayVis and M.GateTypes.ContinueOverlay or (blocking and M.GateTypes.ActionRequired or nil),
			DialogueActive = dialogue,
			BackpackOpen = backpackOpen == true,
			InventoryOpen = backpackOpen == true,
			Quest = cur,
			Objective = obj and obj.Type,
			Target = obj and obj.TargetName,
		}
	end

	function M.GetActiveStep()
		local s = M.snapshot()
		return s.TutorialStep, s
	end

	function M.IsBlocking()
		local s = M.snapshot()
		return s.Blocking == true, s
	end

	function M.GetCurrentGate()
		local vis, ui = false, nil
		if GB.State and GB.State.tutorialOverlayVisible then
			vis, ui = GB.State.tutorialOverlayVisible()
		end
		if vis and ui then
			local payload = nil
			if ui.Name == "SkillObtained" and GB.State.skillNameOf then
				payload = GB.State.skillNameOf(ui)
			elseif ui.Name == "TutorialScreen" then
				local title = ui:FindFirstChild("Title")
				payload = GB.State.guiText and GB.State.guiText(title) or nil
			end
			local spec = M.CONTINUE_OVERLAYS[ui.Name]
			return {
				Type = M.GateTypes.ContinueOverlay,
				Id = ui.Name,
				Payload = payload,
				Instance = ui,
				ContinuationMethod = spec and spec.continuation or "UIS.InputBegan",
				ListenDelay = spec and spec.listenDelay,
				EventOnly = spec and spec.event == true,
			}
		end
		local s = M.snapshot()
		if s.Blocking then
			local typ = M.GateTypes.ActionRequired
			if s.Objective == "Equip" then
				typ = M.GateTypes.EquipRequired
			elseif s.DialogueActive then
				typ = M.GateTypes.Dialogue
			end
			return {
				Type = typ,
				Id = s.TutorialStep,
				Payload = s.Target or s.TutorialText,
				Instance = nil,
				ContinuationMethod = "action",
			}
		end
		return nil
	end

	function M.ValidateGateCompleted(gate)
		if not gate then
			return true
		end
		if gate.Type == M.GateTypes.ContinueOverlay then
			if gate.Instance and GB.State.overlayStillOn and GB.State.overlayStillOn(gate.Instance) then
				return false
			end
			local vis = GB.State.tutorialOverlayVisible and select(1, GB.State.tutorialOverlayVisible())
			return vis ~= true
		end
		local after = M.snapshot()
		return after.Blocking ~= true or after.TutorialStep ~= gate.Id
	end

	function M.DumpTutorialState()
		local gate = M.GetCurrentGate()
		local vis, ui = false, nil
		if GB.State and GB.State.tutorialOverlayVisible then
			vis, ui = GB.State.tutorialOverlayVisible()
		end
		local dump = {
			DetectedGate = gate and gate.Id or nil,
			GateType = gate and gate.Type or nil,
			Payload = gate and gate.Payload or nil,
			GuiPath = ui and ui:GetFullName() or nil,
			ContinuationMethod = gate and gate.ContinuationMethod or M.lastMethod,
			Attempt = M.continueAttempts,
			LastTransition = M.lastTransition,
			LastAction = M.lastAction,
			CachedState = M.lastStep,
			ActualVisibleState = vis == true,
			Owner = M.owner,
			Unresolved = M.unresolved,
			Tree = (ui and GB.State.dumpOverlayTree and GB.State.dumpOverlayTree(ui)) or nil,
		}
		GB.Log.warn("GATE", string.format("DumpTutorialState id=%s type=%s payload=%s visible=%s", tostring(dump.DetectedGate), tostring(dump.GateType), tostring(dump.Payload), tostring(dump.ActualVisibleState)))
		return dump
	end

	local STRATS = { "owner", "consts", "getgc", "synth" }

	function M.releaseTutorial(why)
		M.owner = nil
		M.lastStep = nil
		M.continueAttempts = 0
		M.unresolved = nil
		M.lastTransition = why or "cleared"
		if GB.Recovery and GB.Recovery.outcome == "BLOCKING_UI" then
			GB.Recovery.outcome = nil
		end
	end

	function M.refreshAfterGate()
		if GB.PlayerData and GB.PlayerData.forceQuestRefresh then
			GB.PlayerData.forceQuestRefresh("tutorial_gate")
		elseif GB.PlayerData and GB.PlayerData.refreshLive then
			GB.PlayerData.refreshLive(true, "tutorial_gate")
		end
		if GB.State and GB.State.refresh then
			GB.State.refresh()
		end
		if GB.Planner and GB.Planner.Replan then
			GB.Planner.Replan()
		end
		if GB.Stats and GB.Stats.markDirty then
			GB.Stats.markDirty("tutorial_gate")
		end
		if GB.Recovery and GB.Recovery.markSuccess then
			GB.Recovery.markSuccess()
		end
	end

	function M.HandleContinuationOverlay(gate)
		gate = gate or M.GetCurrentGate()
		if not (gate and gate.Type == M.GateTypes.ContinueOverlay) then
			return false
		end
		local key = gate.Id .. "|" .. tostring(gate.Payload)
		if M.unresolved == key then
			return false
		end
		if GB.Combat and GB.Combat.stopLock then
			GB.Combat.stopLock()
		end
		M.owner = "Tutorial"
		M.lastGate = gate
		if M.lastStep ~= key then
			M.lastStep = key
			M.continueAttempts = 0
			M.dumpedTree = nil
			GB.Log.log("GATE", string.format("detected ContinueOverlay %s payload=%s", tostring(gate.Id), tostring(gate.Payload)))
			GB.Log.log("GATE", "continuation=" .. tostring(gate.ContinuationMethod))
			if GB.Config and GB.Config.Debug == true and GB.State.dumpOverlayTree then
				GB.State.dumpOverlayTree(gate.Instance)
			end
		end
		GB.State._continueStrategy = STRATS[(M.continueAttempts % #STRATS) + 1]
		local stageName, stageBefore, stageTotal = nil, 0, 0
		if GB.State.overlayStage then
			stageName, stageBefore, stageTotal = GB.State.overlayStage(gate.Instance)
		end
		local _, _, method = GB.State.dismissTutorialOverlay()
		if method == "wait_listener" or method == "rate" then
			return false
		end
		if method == "gone" then
			M.releaseTutorial("cleared")
			GB.Log.log("GATE", tostring(gate.Id) .. " cleared")
			GB.Log.log("STATE", "tutorial complete")
			M.refreshAfterGate()
			return true
		end
		M.lastMethod = method
		M.lastAction = "ContinueOverlay"
		M.continueAttempts = M.continueAttempts + 1
		local ver = ""
		pcall(function()
			ver = tostring(getgenv().GB_VERSION or "")
		end)
		GB.Log.log(
			"UI",
			string.format(
				"continue %s %s via %s ver=%s",
				tostring(gate.Id),
				tostring(gate.Payload or stageName or ""),
				tostring(method),
				ver
			)
		)
		local linger = 0.55
		if stageTotal > 0 and stageBefore >= stageTotal then
			linger = 0.9
		end
		local t0 = os.clock()
		while os.clock() - t0 < linger do
			if M.ValidateGateCompleted(gate) then
				M.releaseTutorial("cleared")
				GB.Log.log("GATE", tostring(gate.Id) .. " cleared")
				GB.Log.log("STATE", "tutorial complete")
				M.refreshAfterGate()
				return true
			end
			task.wait(0.08)
		end
		if GB.State.overlayStage then
			local _, stageAfter = GB.State.overlayStage(gate.Instance)
			if type(stageAfter) == "number" and stageAfter > (stageBefore or 0) then
				GB.Log.log(
					"GATE",
					string.format(
						"%s %s stage %d->%d",
						tostring(gate.Id),
						tostring(gate.Payload or stageName or ""),
						stageBefore or 0,
						stageAfter
					)
				)
				M.continueAttempts = 0
			end
		end
		if M.continueAttempts >= 2 and M.dumpedTree ~= key then
			M.dumpedTree = key
			M.DumpTutorialState()
		end
		if M.continueAttempts >= 12 then
			M.unresolved = key
			if GB.Recovery then
				GB.Recovery.outcome = "BLOCKING_GATE_UNRESOLVED"
			end
			GB.Log.warn("GATE", "BLOCKING_GATE_UNRESOLVED " .. key)
			GB.Log.warn(
				"GATE",
				string.format(
					"id=%s payload=%s method=%s before=Enabled after=still",
					tostring(gate.Id),
					tostring(gate.Payload),
					tostring(method)
				)
			)
			M.DumpTutorialState()
			if GB.DumpRuntimeIssue then
				GB.DumpRuntimeIssue()
			end
		end
		return false
	end

	function M.ExecuteGate(gate)
		gate = gate or M.GetCurrentGate()
		if not gate then
			M.owner = nil
			return false
		end
		if gate.Type == M.GateTypes.ContinueOverlay then
			return M.HandleContinuationOverlay(gate)
		end
		return M.ExecuteCurrentStep()
	end

	function M.needsGearEquip(name)
		local s = M.snapshot()
		if s.TutorialStep == "EquipFlintlock" then
			return true
		end
		if s.TutorialText and string.find(string.lower(s.TutorialText), "backpack", 1, true) then
			return true
		end
		if s.TutorialText and string.find(string.lower(s.TutorialText), "drag", 1, true) then
			return true
		end
		return name == "Flintlock" and s.Objective == "Equip"
	end

	local function logGate(s)
		if s.TutorialStep and M.lastStep ~= s.TutorialStep .. "|" .. tostring(s.TutorialText) then
			M.lastStep = s.TutorialStep .. "|" .. tostring(s.TutorialText)
			GB.Log.log("GATE", "Tutorial detected " .. tostring(s.TutorialStep))
			if s.TutorialText then
				GB.Log.log("GATE", "Instruction: " .. tostring(s.TutorialText))
			end
		end
	end

	function M.ValidateTransition(before)
		local after = M.snapshot()
		if before and after then
			if before.Modal and before.Modal ~= after.Modal then
				GB.Log.log(
					"GATE",
					string.format("Tutorial advanced %s -> %s", tostring(before.Modal), tostring(after.Modal or "none"))
				)
				M.attempts = 0
				return true, after
			end
			if before.TutorialText ~= after.TutorialText then
				GB.Log.log(
					"GATE",
					string.format("Tutorial advanced %s -> %s", tostring(before.TutorialStep or before.TutorialText), tostring(after.TutorialStep or after.TutorialText))
				)
				M.attempts = 0
				return true, after
			end
			if before.BackpackOpen ~= after.BackpackOpen then
				M.attempts = 0
				return true, after
			end
		end
		return false, after
	end

	function M.ExecuteCurrentStep()
		local gate = M.GetCurrentGate()
		if gate and gate.Type == M.GateTypes.ContinueOverlay then
			return M.HandleContinuationOverlay(gate)
		end
		local blocking, s = M.IsBlocking()
		if not blocking then
			M.owner = nil
			return false
		end
		if GB.Combat and GB.Combat.stopLock then
			GB.Combat.stopLock()
		end
		M.owner = "Tutorial"
		logGate(s)
		local text = s.TutorialText or ""
		local low = string.lower(text)
		local before = s

		if string.find(low, "open the backpack", 1, true) or string.find(low, "open your backpack", 1, true) or (s.TutorialStep == "EquipFlintlock" and not s.BackpackOpen) then
			M.lastAction = "OpenBackpack"
			if GB.Backpack then
				GB.Backpack.open()
			end
			task.wait(0.2)
			return select(1, M.ValidateTransition(before))
		end

		if string.find(low, "drag", 1, true) or string.find(low, "weapon slot", 1, true) or string.find(low, "drop it", 1, true) then
			M.lastAction = "EquipGear"
			local target = s.Target or "Flintlock"
			if GB.Equipment and GB.Equipment.equipViaBackpack then
				GB.Equipment.equipViaBackpack(target)
			end
			task.wait(0.25)
			return select(1, M.ValidateTransition(before))
		end

		if s.Objective == "Equip" and s.Target then
			M.lastAction = "EquipGear"
			if not s.BackpackOpen and GB.Backpack then
				GB.Backpack.open()
				task.wait(0.15)
			end
			if GB.Equipment and GB.Equipment.equipViaBackpack then
				GB.Equipment.equipViaBackpack(s.Target)
			end
			task.wait(0.25)
			return select(1, M.ValidateTransition(before))
		end

		if string.find(low, "open the menu", 1, true) then
			M.lastAction = "OpenMenu"
			if GB.Quest and GB.State.clickGui then
				local pg = GB.lp and GB.lp.PlayerGui
				local tb = pg and pg:FindFirstChild("TopbarStandard")
				local left = tb and tb:FindFirstChild("Holders") and tb.Holders:FindFirstChild("Left")
				local menu = left and left:FindFirstChild("Menu")
				if menu then
					local btn = menu:IsA("GuiButton") and menu or menu:FindFirstChildWhichIsA("GuiButton", true)
					if btn then
						GB.State.clickGui(btn)
					end
				end
			end
			return select(1, M.ValidateTransition(before))
		end

		if string.find(low, "invest", 1, true) then
			M.lastAction = "Invest"
			if GB.Stats and GB.Stats.investMinimum then
				GB.Stats.investMinimum(1)
			end
			return select(1, M.ValidateTransition(before))
		end

		if string.find(low, "logbook", 1, true) or string.find(low, "tutorial page", 1, true) then
			M.lastAction = "OpenLogbook"
			return false
		end

		M.attempts = M.attempts + 1
		if M.attempts >= 6 then
			GB.Log.warn("GATE", "unchanged after attempts step=" .. tostring(s.TutorialStep))
			if GB.DumpRuntimeIssue then
				GB.DumpRuntimeIssue()
			end
			M.attempts = 0
		end
		return false
	end

	function M.ResolveCurrentGate()
		return M.ExecuteCurrentStep()
	end

	function M.dump()
		return M.snapshot()
	end

	local _snapshotRaw = M.snapshot
	function M.snapshot()
		local t0 = pbegin()
		local out = { pcall(_snapshotRaw) }
		pdone("Tutorial.snapshot", t0)
		if not out[1] then
			error(out[2])
		end
		return unpack(out, 2)
	end

	local _getCurrentGateRaw = M.GetCurrentGate
	function M.GetCurrentGate()
		local t0 = pbegin()
		local out = { pcall(_getCurrentGateRaw) }
		pdone("Tutorial.GetCurrentGate", t0)
		if not out[1] then
			error(out[2])
		end
		return unpack(out, 2)
	end

	local _continuationRaw = M.HandleContinuationOverlay
	function M.HandleContinuationOverlay(gate)
		local t0 = pbegin()
		local out = { pcall(_continuationRaw, gate) }
		pdone("Tutorial continuation", t0)
		if not out[1] then
			error(out[2])
		end
		return unpack(out, 2)
	end

	return M
end
]],
    ["kaitun.lua"] = [[-- Grand Blue (Eternal Pose) — engine boot
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
		return {
			Total = total,
			Connected = connected,
			SchedulerRunning = GB.Scheduler and GB.Scheduler._running == true or false,
			CombatLock = GB.Combat and GB.Combat.lockConn ~= nil or false,
		}
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
	print("[Kaitun][BOOT] starting version " .. ver .. " commit=" .. commit)
	return GB
end
]],
    ["picker.lua"] = [[-- Grand Blue — picker theo level + Completed Quests. Rules inline (not readfile).
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
  full_until = 25,
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
  full_until = 20,
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
	if GB and GB.PlayerData then
		return GB.PlayerData.live(name)
	end
	local ev = RS:FindFirstChild("Events")
	local gd = ev and ev:FindFirstChild("GetData")
	local list = gd and gd:InvokeServer("Quests")
	if type(list) == "table" then
		if list[1] ~= nil then
			for _, v in ipairs(list) do
				if type(v) == "table" and v.Name == name then
					if P.finished(name) then
						return
					end
					return v
				end
			end
			return
		end
		if list[name] then
			if P.finished(name) then
				return
			end
			return list[name]
		end
	end
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
print("[GB Pick]", P.pick().why, P.pick().name or "-", "lv"..P.level(), P.island())
return P
]],
	}

	local order = {
    { key = "Config", path = "Config.lua", kind = "core" },
    { key = "Log", path = "Core/Logger.lua", kind = "core" },
    { key = "Profiler", path = "Core/Profiler.lua", kind = "core" },
    { key = "Cache", path = "Core/Cache.lua", kind = "core" },
    { key = "Retry", path = "Core/Retry.lua", kind = "core" },
    { key = "Scheduler", path = "Core/Scheduler.lua", kind = "core" },
    { key = "Persist", path = "Core/Persist.lua", kind = "core" },
    { key = "State", path = "Core/State.lua", kind = "core" },
    { key = "Recovery", path = "Core/Recovery.lua", kind = "core" },
    { key = "Remotes", path = "Game/Remotes.lua", kind = "core" },
    { key = "Resolver", path = "Game/Resolver.lua", kind = "core" },
    { key = "PlayerData", path = "Game/PlayerData.lua", kind = "core" },
    { key = "World", path = "Game/World.lua", kind = "core" },
    { key = "ItemData", path = "Game/ItemData.lua", kind = "core" },
    { key = "QuestData", path = "Game/QuestData.lua", kind = "core" },
    { key = "QuestSpecs", path = "Game/QuestSpecs.lua", kind = "core" },
    { key = "Inventory", path = "Game/Inventory.lua", kind = "core" },
    { key = "Combat", path = "Systems/Combat.lua", kind = "core" },
    { key = "Quest", path = "Systems/Quest.lua", kind = "core" },
    { key = "Acquire", path = "Systems/Acquire.lua", kind = "core" },
    { key = "Stats", path = "Systems/Stats.lua", kind = "optional" },
    { key = "Skills", path = "Systems/Skills.lua", kind = "optional" },
    { key = "Equipment", path = "Systems/Equipment.lua", kind = "optional" },
    { key = "Shop", path = "Systems/Shop.lua", kind = "optional" },
    { key = "Travel", path = "Systems/Travel.lua", kind = "optional" },
    { key = "Boat", path = "Systems/Boat.lua", kind = "optional" },
    { key = "Fruit", path = "Systems/Fruit.lua", kind = "optional" },
    { key = "Haki", path = "Systems/Haki.lua", kind = "optional" },
    { key = "RaceTrait", path = "Systems/RaceTrait.lua", kind = "optional" },
    { key = "LifeSkills", path = "Systems/LifeSkills.lua", kind = "optional" },
    { key = "Chest", path = "Systems/Chest.lua", kind = "optional" },
    { key = "Treasure", path = "Systems/Treasure.lua", kind = "optional" },
    { key = "Boss", path = "Systems/Boss.lua", kind = "optional" },
    { key = "Codes", path = "Systems/Codes.lua", kind = "optional" },
    { key = "Rewards", path = "Systems/Rewards.lua", kind = "optional" },
    { key = "Backpack", path = "Systems/Backpack.lua", kind = "optional" },
    { key = "Tutorial", path = "Systems/Tutorial.lua", kind = "core" },
    { key = "Planner", path = "Progression/Planner.lua", kind = "core" },
    { key = "Engine", path = "Progression/DecisionEngine.lua", kind = "core" },
    { key = "Picker", path = "picker.lua", kind = "optional", factory = false },
	}

	local chunkCache = {}
	local function LoadModule(rel)
		if type(rel) ~= "string" then
			error("[Kaitun][Bundle] bad module path")
		end
		rel = rel:gsub("^/+", "")
		if not rel:match("%.lua$") then
			rel = rel .. ".lua"
		end
		if chunkCache[rel] ~= nil then
			return chunkCache[rel]
		end
		local src = files[rel]
		if type(src) ~= "string" then
			error("[Kaitun][Bundle] missing " .. rel)
		end
		local fn, err = loadstring(src, rel)
		if not fn then
			error("[Kaitun][Bundle] compile " .. rel .. " " .. tostring(err))
		end
		local out = fn()
		chunkCache[rel] = out
		return out
	end

	local function Require(dotted)
		local path = tostring(dotted):gsub("%.", "/")
		return LoadModule(path)
	end

	local Players = game:GetService("Players")
	local lp = Players.LocalPlayer
	if not lp then
		repeat
			task.wait()
		until Players.LocalPlayer
		lp = Players.LocalPlayer
	end

	local GB = {
		gen = GEN,
		dead = dead,
		lp = lp,
		conns = {},
		LoadModule = LoadModule,
		Require = Require,
	}

	local function optionalStub()
		local M = {}
		setmetatable(M, {
			__index = function()
				return function() end
			end,
		})
		return M
	end

	getgenv()._GBKaitunLoader = {
		LoadModule = LoadModule,
		Require = Require,
		BASE_URL = tostring(meta and meta.BASE_URL or "bundle://dist"),
		VERSION = BUILD_VERSION,
		COMMIT = BUILD_COMMIT,
		BUILD_AT = BUILD_AT,
		SOURCE_MODE = "BUNDLE",
		OWNER = tostring(meta and meta.OWNER or ""),
		REPO = tostring(meta and meta.REPO or ""),
		BRANCH = tostring(meta and meta.BRANCH or ""),
		BUNDLE = "dist/kaitun.lua",
	}
	getgenv().GB_VERSION = BUILD_VERSION
	getgenv().GB_COMMIT = BUILD_COMMIT
	getgenv().GB_BUILD_AT = BUILD_AT

	local loaded = 0
	for _, row in ipairs(order) do
		local key, rel, kind = row.key, row.path, row.kind or "core"
		local factoryOk = row.factory ~= false
		local ok, result = pcall(LoadModule, rel)
		if not ok then
			if kind == "core" then
				error(tostring(result))
			end
			if key then
				GB[key] = optionalStub()
			end
		else
			loaded = loaded + 1
			if factoryOk then
				if type(result) ~= "function" then
					if kind == "core" then
						error("[Kaitun][Bundle] " .. rel .. " must return function(GB)")
					end
					GB[key] = optionalStub()
				else
					local ok2, inst = pcall(result, GB)
					if not ok2 then
						if kind == "core" then
							error("[Kaitun][Bundle] init " .. rel .. " " .. tostring(inst))
						end
						GB[key] = optionalStub()
					else
						GB[key] = inst
					end
				end
			end
		end
	end

	print("[Kaitun][Loader] Loaded " .. loaded .. " modules (bundle)")
	local boot = LoadModule("kaitun.lua")
	if type(boot) ~= "function" then
		error("[Kaitun][Bundle] entry must return function(GB)")
	end
	boot(GB)

	getgenv().GBKaitun = GB
	getgenv().GBConfig = GB.Config
	getgenv().GB_VERSION = BUILD_VERSION
	return GB
end
