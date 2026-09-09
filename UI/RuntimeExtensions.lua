return function(GB)
	if type(GB) ~= "table" then
		error("[GrandBlue UI] runtime table missing")
	end

	local M = {
		_destroyed = false,
		originals = {},
	}

	local SEND_GAP = 2.8
	local FEEDBACK_TIMEOUT = 5
	local FEEDBACK_DRAIN_WINDOW = 5
	local SCHEDULER_WAIT = 0.03
	local REROLL_GAP = 1.5
	local MAX_CODE_ATTEMPTS = 2
	local STAT_NAMES = { "Strength", "Health", "Willpower", "Agility", "Precision", "Energy" }
	local TERMINAL_CODE_STATES = {
		SUCCESS = true,
		ALREADY_USED = true,
		INVALID = true,
		EXPIRED = true,
	}

	local PRESETS = {
		Balanced = { Strength = 1, Health = 1, Willpower = 1, Agility = 1, Precision = 1, Energy = 1 },
		Strength = { Strength = 8, Health = 2 },
		Sword = { Strength = 6, Health = 2, Agility = 2 },
		Gun = { Precision = 6, Health = 2, Agility = 2 },
		Fruit = { Willpower = 6, Health = 2, Energy = 2 },
		Hybrid = { Strength = 3, Health = 2, Willpower = 2, Agility = 1, Precision = 2, Energy = 1 },
		Melee = { Strength = 8, Health = 2 },
	}

	local KNOWN_BOSS_MAPPINGS = {
		{ Quest = "The Hoarder", Target = "Afuaru, The Hoarder" },
		{ Quest = "Axe-Handed Tyrant", Target = "Axe-Hand Logan" },
		{ Quest = "Tyrannical Captain", Target = "Axe-Hand Logan" },
		{ Quest = "Feral Dog", Target = "Soro" },
		{ Quest = "Captain's Brat", Target = "Blonde Goblin" },
		{ Quest = "The Ringmaster", Target = "Choppy The Clown" },
		{ Quest = "Choppy The Clown", Target = "Choppy The Clown" },
		{ Quest = "Stephon's Tormentor", Target = "\"Barrel Clown\" Binki" },
		{ Quest = "The Wandering Hypnotist", Target = "\"Hypnotist\" Mango" },
		{ Quest = "The Island's Protector", Target = "Captain Esopo" },
		{ Quest = "Undermine The Circus 3", Target = "Choppy The Clown" },
	}

	local SAFE_REWARDS = {
		"Easy Pickings",
		"Noise Complaint",
		"Corruption Cleanse",
	}

	GB.Config = type(GB.Config) == "table" and GB.Config or {}

	local function trim(value)
		if type(value) ~= "string" then
			return nil
		end
		local result = string.gsub(value, "^%s+", "")
		result = string.gsub(result, "%s+$", "")
		if result == "" then
			return nil
		end
		return result
	end

	local function copyArray(source)
		local result = {}
		if type(source) == "table" then
			for _, value in ipairs(source) do
				result[#result + 1] = value
			end
		end
		return result
	end

	local function finiteNonnegative(value)
		local number = tonumber(value)
		if not number or number ~= number or number == math.huge or number == -math.huge then
			return 0
		end
		return math.max(0, number)
	end

	local function sortStrings(values)
		table.sort(values, function(left, right)
			local leftLower = string.lower(tostring(left))
			local rightLower = string.lower(tostring(right))
			if leftLower ~= rightLower then
				return leftLower < rightLower
			end
			return tostring(left) < tostring(right)
		end)
		return values
	end

	local function addUniqueString(values, seen, value)
		value = trim(value)
		if not value then
			return
		end
		local key = string.lower(tostring(value))
		if seen[key] then
			return
		end
		seen[key] = true
		values[#values + 1] = value
	end

	local function log(kind, category, message)
		local logger = type(GB.Log) == "table" and GB.Log or nil
		local callback = logger and logger[kind]
		if type(callback) == "function" then
			pcall(callback, category, tostring(message))
		end
	end

	local function isRemoteEvent(remote)
		if remote == nil then
			return false
		end
		local ok, result = pcall(function()
			return remote:IsA("RemoteEvent")
		end)
		if ok then
			return result == true
		end
		local className
		pcall(function()
			className = remote.ClassName
		end)
		return className == "RemoteEvent"
	end

	local function getRemote(name)
		if type(GB.Remotes) ~= "table" or type(GB.Remotes.get) ~= "function" then
			return nil, "remotes_unavailable"
		end
		local ok, remote = pcall(GB.Remotes.get, name)
		if not ok then
			return nil, tostring(remote)
		end
		if not isRemoteEvent(remote) then
			return nil, "remote_missing"
		end
		return remote
	end

	-- The core scheduler exposes no task handle. Track the UI runtime loop so a
	-- stop followed by an immediate start cannot revive the previous loop.
	local Scheduler = type(GB.Scheduler) == "table" and GB.Scheduler or nil
	local schedulerGeneration = 0
	local schedulerTask = nil
	local schedulerWrapped = false

	local function schedulerIsDead()
		if type(GB.dead) ~= "function" then
			return false
		end
		local ok, dead = pcall(GB.dead)
		return ok and dead == true
	end

	local function untrackSchedulerTask(target)
		if target == nil or type(GB.Tasks) ~= "table" then
			return
		end
		for index = #GB.Tasks, 1, -1 do
			if GB.Tasks[index] == target then
				table.remove(GB.Tasks, index)
			end
		end
	end

	local function invalidateSchedulerLoop()
		schedulerGeneration = schedulerGeneration + 1
		if not Scheduler then
			return
		end
		Scheduler._uiGeneration = schedulerGeneration
		local previousTask = schedulerTask or Scheduler._uiTask
		schedulerTask = nil
		if Scheduler._uiTask == previousTask then
			Scheduler._uiTask = nil
		end
		untrackSchedulerTask(previousTask)
		if previousTask ~= nil and previousTask ~= coroutine.running() then
			pcall(task.cancel, previousTask)
		end
	end

	local function runtimeShuttingDown()
		return GB._stopped == true or GB.Running == false or schedulerIsDead()
	end

	if Scheduler and type(Scheduler.step) == "function" then
		local originalSchedulerStart = Scheduler._uiOriginalStart or Scheduler.start
		local originalSchedulerStop = Scheduler._uiOriginalStop or Scheduler.stop
		M.originals.SchedulerStart = originalSchedulerStart
		M.originals.SchedulerStop = originalSchedulerStop
		Scheduler._uiOriginalStart = originalSchedulerStart
		Scheduler._uiOriginalStop = originalSchedulerStop
		schedulerWrapped = true

		function Scheduler.start()
			if Scheduler._running == true and schedulerTask ~= nil and Scheduler._uiTask == schedulerTask then
				return
			end

			invalidateSchedulerLoop()
			Scheduler._running = true
			Scheduler._nudge = false
			local generation = schedulerGeneration
			local spawnedTask
			spawnedTask = task.spawn(function()
				local currentTask = coroutine.running()
				local loopOk, loopError = pcall(function()
					while Scheduler._running == true
						and schedulerGeneration == generation
						and not schedulerIsDead()
					do
						Scheduler.step()
						local budget = tonumber(GB.Config and GB.Config.Tick) or 0.15
						if budget < 0.05 then
							budget = 0.05
						end
						local waitStarted = os.clock()
						while Scheduler._running == true
							and schedulerGeneration == generation
							and not schedulerIsDead()
						do
							if Scheduler._nudge then
								Scheduler._nudge = false
								break
							end
							local remaining = budget - (os.clock() - waitStarted)
							if remaining <= 0 then
								break
							end
							task.wait(math.min(SCHEDULER_WAIT, remaining))
						end
					end
				end)

				if Scheduler._uiTask == currentTask then
					Scheduler._uiTask = nil
				end
				if schedulerTask == currentTask then
					schedulerTask = nil
				end
				untrackSchedulerTask(currentTask)
				if schedulerGeneration == generation then
					Scheduler._running = false
					if not loopOk then
						log("err", "ERROR", "scheduler loop " .. tostring(loopError))
					end
				end
			end)
			schedulerTask = spawnedTask
			Scheduler._uiTask = spawnedTask
			GB.Tasks = type(GB.Tasks) == "table" and GB.Tasks or {}
			GB.Tasks[#GB.Tasks + 1] = spawnedTask
		end

		function Scheduler.stop()
			Scheduler._running = false
			Scheduler._nudge = false
			invalidateSchedulerLoop()
		end
	end

	-- Codes is replaced before either the engine or manual utility scheduler can tick.
	local originalCodes = type(GB.Codes) == "table" and GB.Codes or nil
	local Codes = {
		_original = originalCodes,
		_uiRuntimeExtension = true,
		i = 1,
		hooked = false,
		lastAt = nil,
		running = false,
		queue = nil,
		results = {},
		pendingCode = nil,
		pendingAt = nil,
		_queueIndex = 1,
		_attempts = {},
		_feedbackGeneration = 0,
		_drainUntil = 0,
		_destroyed = false,
	}
	M.originals.Codes = originalCodes

	local codeListeners = {}
	local nextCodeListenerId = 0
	local handleCodeFeedback

	local function persistedCodeState(code)
		local persist = type(GB.Persist) == "table" and GB.Persist or nil
		local data = persist and type(persist.data) == "table" and persist.data or nil
		local states = data and type(data.codes) == "table" and data.codes or nil
		local row = states and states[code] or nil
		local state
		if type(row) == "table" then
			state = row.state or row.State
		elseif type(row) == "string" then
			state = row
		end
		if type(state) == "string" then
			return string.upper(state)
		end
		local result = Codes.results[code]
		if type(result) == "table" and type(result.state) == "string" then
			return string.upper(tostring(result.state))
		end
		return nil
	end

	local function isTerminalCode(code)
		local state = persistedCodeState(code)
		return TERMINAL_CODE_STATES[state] == true, state
	end

	local function persistCodeState(code, state)
		if type(GB.Persist) == "table" and type(GB.Persist.codeState) == "function" then
			pcall(GB.Persist.codeState, code, state)
		end
	end

	local function classifyCodeResult(text, accepted)
		local lower = string.lower(tostring(text or ""))
		if accepted == true then
			if string.find(lower, "already", 1, true) then
				return "ALREADY_USED"
			end
			return "SUCCESS"
		end
		if string.find(lower, "invalid", 1, true) or string.find(lower, "not found", 1, true) then
			return "INVALID"
		end
		if string.find(lower, "expir", 1, true) then
			return "EXPIRED"
		end
		if string.find(lower, "already", 1, true) then
			return "ALREADY_USED"
		end
		return "ERROR"
	end

	local function publishCodeResult(code, state, text)
		local result = {
			state = state,
			text = tostring(text or ""),
			at = os.clock(),
		}
		Codes.results[code] = result
		persistCodeState(code, state)
		log("log", "REWARD", "code " .. tostring(code) .. " " .. state .. " " .. result.text)
		for id, callback in pairs(codeListeners) do
			local ok = pcall(callback, code, state, result.text, result)
			if not ok then
				codeListeners[id] = nil
			end
		end
		return result
	end

	local function finishCodeOwner(owner, index)
		if owner == "queue" then
			if Codes._queueIndex == index then
				Codes._queueIndex = index + 1
			end
			if type(Codes.queue) ~= "table" or Codes._queueIndex > #Codes.queue then
				Codes.running = false
				Codes.queue = nil
				Codes._queueIndex = 1
			end
		elseif owner == "auto" and Codes.i == index then
			Codes.i = index + 1
		end
	end

	local function clearPendingCode()
		Codes._pending = nil
		Codes.pendingCode = nil
		Codes.pendingAt = nil
	end

	local function feedbackDrainActive(now)
		now = now or os.clock()
		local drainUntil = tonumber(Codes._drainUntil) or 0
		if now < drainUntil then
			return true, drainUntil - now
		end
		if drainUntil > 0 then
			Codes._drainUntil = 0
			Codes._drainGeneration = nil
		end
		return false, 0
	end

	local function invalidateCodeFeedback(startDrain)
		Codes._feedbackGeneration = (tonumber(Codes._feedbackGeneration) or 0) + 1
		clearPendingCode()
		if startDrain then
			Codes._drainGeneration = Codes._feedbackGeneration
			Codes._drainUntil = math.max(
				tonumber(Codes._drainUntil) or 0,
				os.clock() + FEEDBACK_DRAIN_WINDOW
			)
		end
	end

	local function finishPendingCode(state, text, expectedGeneration)
		local pending = Codes._pending
		if type(pending) ~= "table" then
			return nil
		end
		if expectedGeneration ~= nil and pending.generation ~= expectedGeneration then
			return nil
		end
		if pending.generation ~= Codes._feedbackGeneration then
			return nil
		end
		clearPendingCode()
		local result = publishCodeResult(pending.code, state, text)
		local attempts = tonumber(Codes._attempts[pending.code]) or tonumber(pending.attempt) or 0
		if TERMINAL_CODE_STATES[state] or attempts >= MAX_CODE_ATTEMPTS then
			finishCodeOwner(pending.owner, pending.index)
		end
		return result
	end

	handleCodeFeedback = function(text, accepted)
		if Codes._destroyed or M._destroyed or feedbackDrainActive(os.clock()) then
			return
		end
		local pending = Codes._pending
		if type(pending) ~= "table" or pending.generation ~= Codes._feedbackGeneration then
			return
		end
		finishPendingCode(classifyCodeResult(text, accepted), text, pending.generation)
	end

	local function requestCodeProgress()
		if Codes._progressRequested then
			return
		end
		Codes._progressRequested = true
		if type(GB.Remotes) == "table" and type(GB.Remotes.codeProg) == "function" then
			pcall(GB.Remotes.codeProg)
		end
	end

	local function ensureCodeListener(requestProgress)
		if Codes._destroyed or M._destroyed then
			return false, "destroyed"
		end
		if Codes._conn then
			if requestProgress then
				requestCodeProgress()
			end
			return true
		end
		local remote, reason = getRemote("Codes")
		if not remote then
			return false, reason
		end
		local signal
		pcall(function()
			signal = remote.OnClientEvent
		end)
		if signal == nil or type(signal.Connect) ~= "function" then
			return false, "feedback_unavailable"
		end
		local ok, connection = pcall(function()
			return signal:Connect(handleCodeFeedback)
		end)
		if not ok or connection == nil then
			return false, ok and "connect_failed" or tostring(connection)
		end
		Codes._conn = connection
		Codes.hooked = true
		GB.conns = type(GB.conns) == "table" and GB.conns or {}
		GB.Connections = GB.conns
		GB.conns[#GB.conns + 1] = connection
		if requestProgress then
			requestCodeProgress()
		end
		return true
	end

	function Codes.known()
		local result = {}
		local seen = {}
		local configured = type(GB.Config.Codes) == "table" and GB.Config.Codes or {}
		for _, rawCode in ipairs(configured) do
			local code = trim(rawCode)
			if code and not seen[code] then
				seen[code] = true
				result[#result + 1] = code
			end
		end
		return result
	end

	function Codes.onResult(callback)
		if type(callback) ~= "function" or Codes._destroyed then
			local disconnected = { Connected = false }
			function disconnected:Disconnect()
				self.Connected = false
			end
			return disconnected
		end
		nextCodeListenerId = nextCodeListenerId + 1
		local id = nextCodeListenerId
		codeListeners[id] = callback
		local handle = { Connected = true }
		function handle:Disconnect()
			if not self.Connected then
				return
			end
			self.Connected = false
			codeListeners[id] = nil
		end
		return handle
	end

	local function sendCode(rawCode, owner, index)
		if Codes._destroyed or M._destroyed then
			return false, "destroyed"
		end
		local code = trim(rawCode)
		if not code then
			return false, "empty"
		end
		local now = os.clock()
		local draining, drainRemaining = feedbackDrainActive(now)
		if draining then
			return false, "draining", drainRemaining
		end
		local terminal, state = isTerminalCode(code)
		if terminal then
			return false, "terminal", state
		end
		if Codes.pendingCode then
			return false, "pending"
		end
		if Codes.lastAt and now - Codes.lastAt < SEND_GAP then
			return false, "rate"
		end
		local listenerOk, listenerReason = ensureCodeListener(true)
		if not listenerOk then
			return false, listenerReason
		end
		if type(GB.Remotes) ~= "table" or type(GB.Remotes.code) ~= "function" then
			return false, "code_unavailable"
		end

		local previousAttempts = tonumber(Codes._attempts[code]) or 0
		local attempt = previousAttempts + 1
		local generation = (tonumber(Codes._feedbackGeneration) or 0) + 1
		Codes._feedbackGeneration = generation
		local pending = {
			code = code,
			owner = owner,
			index = index,
			attempt = attempt,
			generation = generation,
		}
		Codes._attempts[code] = attempt
		Codes._pending = pending
		Codes.pendingCode = code
		Codes.pendingAt = now
		Codes.lastAt = now
		log("log", "REWARD", "redeem " .. code)

		local ok, sent, detail = pcall(GB.Remotes.code, code)
		if not ok or sent == false then
			if Codes._pending == pending then
				Codes._attempts[code] = previousAttempts
				invalidateCodeFeedback(not ok)
			end
			if not ok then
				return false, tostring(sent)
			end
			return false, detail or "send"
		end
		return true, "sent"
	end

	function Codes.redeem(code)
		if Codes.running then
			return false, "busy"
		end
		return sendCode(code, nil, nil)
	end

	function Codes.redeemAll(codes)
		if Codes._destroyed or M._destroyed then
			return false, "destroyed"
		end
		if Codes.running or Codes.pendingCode then
			return false, "busy"
		end
		local source
		if codes == nil then
			source = Codes.known()
		elseif type(codes) == "table" then
			source = codes
		else
			return false, "bad_codes"
		end
		local queue = {}
		local seen = {}
		for _, rawCode in ipairs(source) do
			local code = trim(rawCode)
			local terminal = code and isTerminalCode(code) or false
			if code and not seen[code] and not terminal then
				seen[code] = true
				queue[#queue + 1] = code
			end
		end
		Codes.queue = queue
		Codes._queueIndex = 1
		Codes.running = #queue > 0
		return true, #queue
	end

	function Codes.stop()
		Codes.running = false
		Codes.queue = nil
		Codes._queueIndex = 1
		invalidateCodeFeedback(type(Codes._pending) == "table")
		return true
	end

	function Codes.summary()
		local counts = {
			SUCCESS = 0,
			ALREADY_USED = 0,
			INVALID = 0,
			EXPIRED = 0,
			ERROR = 0,
			UNKNOWN = 0,
		}
		for _, code in ipairs(Codes.known()) do
			local state = persistedCodeState(code) or "UNKNOWN"
			if counts[state] == nil then
				state = "UNKNOWN"
			end
			counts[state] = counts[state] + 1
		end
		return counts
	end

	function Codes.tick()
		if Codes._destroyed or M._destroyed then
			return false, "destroyed"
		end
		if GB.Config.AutoCodes ~= true and not Codes.running then
			return nil
		end
		local now = os.clock()
		local draining, drainRemaining = feedbackDrainActive(now)
		if draining then
			return false, "draining", drainRemaining
		end
		local listenerOk, listenerReason = ensureCodeListener(true)
		if not listenerOk then
			return false, listenerReason
		end
		if Codes.pendingCode then
			if now - (Codes.pendingAt or now) < FEEDBACK_TIMEOUT then
				return false, "pending"
			end
			local pending = Codes._pending
			finishPendingCode("ERROR", "feedback timeout", pending and pending.generation)
			invalidateCodeFeedback(true)
			return false, "feedback_timeout"
		end

		local owner
		local index
		local list
		if Codes.running then
			owner = "queue"
			index = Codes._queueIndex
			list = Codes.queue
		else
			owner = "auto"
			index = Codes.i
			list = Codes.known()
		end
		if type(list) ~= "table" or index > #list then
			if owner == "queue" then
				Codes.running = false
				Codes.queue = nil
				Codes._queueIndex = 1
			end
			return nil
		end

		local code = list[index]
		local terminal, state = isTerminalCode(code)
		if terminal then
			finishCodeOwner(owner, index)
			return true, "skipped_terminal", state
		end
		if (tonumber(Codes._attempts[code]) or 0) >= MAX_CODE_ATTEMPTS then
			publishCodeResult(code, "ERROR", "attempt limit")
			finishCodeOwner(owner, index)
			return false, "attempt_limit"
		end
		return sendCode(code, owner, index)
	end

	function Codes.destroy()
		if Codes._destroyed then
			return true
		end
		Codes.stop()
		Codes._destroyed = true
		if Codes._conn then
			pcall(function()
				Codes._conn:Disconnect()
			end)
			Codes._conn = nil
		end
		Codes.hooked = false
		codeListeners = {}
		return true
	end

	GB.Codes = Codes
	M.Codes = Codes

	-- Stats keeps its state/verification implementation; only policy tick is replaced.
	local Stats = type(GB.Stats) == "table" and GB.Stats or {}
	GB.Stats = Stats
	M.Stats = Stats
	local originalStatsTick = Stats._uiOriginalTick or Stats.tick
	M.originals.StatsTick = originalStatsTick
	M.originals.StatsSetRatio = Stats.setRatio
	M.originals.StatsSetBuild = Stats.setBuild
	Stats._uiOriginalTick = originalStatsTick
	Stats._uiOriginalSetRatio = Stats.setRatio
	Stats._uiOriginalSetBuild = Stats.setBuild

	local presetByLower = {}
	for name in pairs(PRESETS) do
		presetByLower[string.lower(name)] = name
	end

	local function markStatsDirty(reason)
		if type(Stats.markDirty) == "function" then
			pcall(Stats.markDirty, reason)
		end
	end

	function Stats.statNames()
		return copyArray(STAT_NAMES)
	end

	function Stats.setRatio(weights)
		if type(weights) ~= "table" then
			return false, "bad_ratio"
		end
		local ratio = {}
		local total = 0
		for _, statName in ipairs(STAT_NAMES) do
			local weight = finiteNonnegative(weights[statName])
			ratio[statName] = weight
			total = total + weight
		end
		if total <= 0 then
			return false, "empty_ratio"
		end
		GB.Config.StatRatio = ratio
		GB.Config.Build = "Custom"
		markStatsDirty("ui_ratio")
		return true
	end

	function Stats.setBuild(rawName)
		local name = trim(rawName)
		local canonical = name and presetByLower[string.lower(tostring(name))] or nil
		local preset = canonical and PRESETS[canonical] or nil
		if not preset then
			return false, "unknown_build"
		end
		local ratio = {}
		for _, statName in ipairs(STAT_NAMES) do
			ratio[statName] = finiteNonnegative(preset[statName])
		end
		GB.Config.Build = canonical
		GB.Config.StatRatio = ratio
		markStatsDirty("ui_build")
		return true
	end

	local function readStatsStatus()
		if type(Stats.status) ~= "function" then
			return true, nil, nil
		end
		local ok, status, reason = pcall(Stats.status)
		if not ok then
			return false, nil, tostring(status)
		end
		return true, status, reason
	end

	local function strengthIsBlocked(state)
		if type(GB.Quest) ~= "table" or type(GB.Quest.CurrentBlockers) ~= "function" then
			return false
		end
		local ok, blockers = pcall(GB.Quest.CurrentBlockers)
		if not ok or type(blockers) ~= "table" then
			return false
		end
		for _, blocker in pairs(blockers) do
			if type(blocker) == "table"
				and string.upper(tostring(blocker.Type or blocker.type or "")) == "STAT_REQUIREMENT"
				and string.lower(tostring(blocker.Stat or blocker.stat or "")) == "strength"
			then
				local required = tonumber(blocker.Required or blocker.required)
				if not required or finiteNonnegative(state.Strength) < required then
					return true
				end
			end
		end
		return false
	end

	local function ratioForTick()
		local configured = type(GB.Config.StatRatio) == "table" and GB.Config.StatRatio or nil
		local ratio = {}
		local total = 0
		for _, statName in ipairs(STAT_NAMES) do
			local weight = finiteNonnegative(configured and configured[statName] or nil)
			ratio[statName] = weight
			total = total + weight
		end
		if total > 0 then
			return ratio, total
		end
		local build = PRESETS[tostring(GB.Config.Build or "")] or PRESETS.Melee
		total = 0
		for _, statName in ipairs(STAT_NAMES) do
			local weight = finiteNonnegative(build[statName])
			ratio[statName] = weight
			total = total + weight
		end
		return ratio, total
	end

	local function chooseDeficitStat(state)
		if strengthIsBlocked(state) then
			return "Strength"
		end
		local ratio, totalWeight = ratioForTick()
		local totalStats = 0
		for _, statName in ipairs(STAT_NAMES) do
			totalStats = totalStats + finiteNonnegative(state[statName])
		end
		local selected
		local largestDeficit
		for _, statName in ipairs(STAT_NAMES) do
			local weight = ratio[statName]
			if weight > 0 then
				local wanted = (totalStats + 1) * weight / totalWeight
				local deficit = wanted - finiteNonnegative(state[statName])
				if largestDeficit == nil or deficit > largestDeficit then
					selected = statName
					largestDeficit = deficit
				end
			end
		end
		return selected or "Strength"
	end

	function Stats.tick()
		if M._destroyed then
			return false, "destroyed"
		end
		if GB.Config.AutoStats ~= true then
			return nil
		end

		local statusOk, status, statusReason = readStatsStatus()
		if not statusOk then
			return false, "status:" .. tostring(statusReason)
		end
		if string.upper(tostring(status or "")) == "BLOCKED" then
			if type(originalStatsTick) ~= "function" then
				return false, statusReason or "blocked"
			end
			local recoveryOk, recoveryResult, recoveryReason, recoveryDetail = pcall(originalStatsTick)
			if not recoveryOk then
				return false, "recovery:" .. tostring(recoveryResult)
			end
			statusOk, status, statusReason = readStatsStatus()
			if not statusOk then
				return false, "status:" .. tostring(statusReason)
			end
			if string.upper(tostring(status or "")) == "BLOCKED" then
				if recoveryResult == false then
					return false, recoveryReason or statusReason or "blocked", recoveryDetail
				end
				return false, statusReason or "blocked"
			end
		end
		if type(Stats.poll) ~= "function" then
			return false, "poll_unavailable"
		end
		local pollOk, pollResult, pollReason = pcall(Stats.poll)
		if not pollOk then
			return false, "poll:" .. tostring(pollResult)
		end
		if pollResult == false then
			return false, pollReason or "poll_pending"
		end

		statusOk, status, statusReason = readStatsStatus()
		if not statusOk then
			return false, "status:" .. tostring(statusReason)
		end
		if string.upper(tostring(status or "")) == "BLOCKED" then
			return false, statusReason or "blocked"
		end
		if type(Stats.ReadStatState) ~= "function" then
			return false, "state_unavailable"
		end
		local stateOk, state = pcall(Stats.ReadStatState)
		if not stateOk or type(state) ~= "table" then
			return false, stateOk and "bad_state" or tostring(state)
		end
		if finiteNonnegative(state.Unused) < 1 then
			return false, "no_points"
		end
		if type(Stats.Invest) ~= "function" then
			return false, "invest_unavailable"
		end
		local statName = chooseDeficitStat(state)
		local investOk, result, reason, detail = pcall(Stats.Invest, statName, 1)
		if not investOk then
			return false, tostring(result)
		end
		return result, reason, detail
	end

	-- Boss.list is evidence-only. It never predicts spawn or respawn timing.
	local Boss = type(GB.Boss) == "table" and GB.Boss or {}
	GB.Boss = Boss
	M.Boss = Boss
	M.originals.BossList = Boss.list
	Boss._uiOriginalList = Boss.list

	local function stageFields(stage)
		return {
			quest = stage.Q or stage.quest or stage.Quest,
			objective = stage.T or stage.objective or stage.Objective,
			target = stage.A or stage.target or stage.Target,
			amount = tonumber(stage.N or stage.amount or stage.Amount) or 0,
			method = stage.M or stage.acquire or stage.Method,
			source = stage.Src or stage.source or stage.Source,
			island = stage.Loc or stage.location or stage.island or stage.Location or stage.Island,
			marker = stage.Mk or stage.marker or stage.Marker,
		}
	end

	local function newBossEvidence(name)
		return {
			name = name,
			single = 0,
			multi = 0,
			defeat = 0,
			bossDrop = 0,
			known = false,
			quests = {},
			questSeen = {},
			islands = {},
			islandSeen = {},
			markers = {},
			markerSeen = {},
			drops = {},
			dropSeen = {},
		}
	end

	local function bossEvidenceEntry(entries, name)
		name = trim(name)
		if not name then
			return nil
		end
		local key = string.lower(tostring(name))
		local entry = entries[key]
		if not entry then
			entry = newBossEvidence(name)
			entries[key] = entry
		end
		return entry
	end

	local function addBossStage(entry, fields)
		if not entry then
			return
		end
		addUniqueString(entry.quests, entry.questSeen, fields.quest)
		addUniqueString(entry.islands, entry.islandSeen, fields.island)
		addUniqueString(entry.markers, entry.markerSeen, fields.marker)
	end

	function Boss.list()
		local entries = {}
		local generated = type(GB.GeneratedData) == "table" and GB.GeneratedData or nil
		local questSpecs = type(GB.QuestSpecs) == "table" and GB.QuestSpecs or nil
		local stages = generated and type(generated.Stages) == "table" and generated.Stages or nil
		if not stages or next(stages) == nil then
			stages = questSpecs and type(questSpecs.STAGES) == "table" and questSpecs.STAGES or {}
		end

		for _, rawStage in pairs(stages) do
			if type(rawStage) == "table" then
				local fields = stageFields(rawStage)
				local objective = tostring(fields.objective or "")
				if (objective == "Kill" or objective == "Defeat") and trim(fields.target) then
					local entry = bossEvidenceEntry(entries, fields.target)
					if fields.amount == 1 then
						entry.single = entry.single + 1
					elseif fields.amount > 1 then
						entry.multi = entry.multi + 1
					end
					if objective == "Defeat" then
						entry.defeat = entry.defeat + 1
					end
					addBossStage(entry, fields)
				end
				if tostring(fields.method or "") == "BossDrop" and trim(fields.source) then
					local entry = bossEvidenceEntry(entries, fields.source)
					entry.bossDrop = entry.bossDrop + 1
					addBossStage(entry, fields)
					addUniqueString(entry.drops, entry.dropSeen, fields.target)
				end
			end
		end

		for _, mapping in ipairs(KNOWN_BOSS_MAPPINGS) do
			local entry = bossEvidenceEntry(entries, mapping.Target)
			entry.known = true
			addUniqueString(entry.quests, entry.questSeen, mapping.Quest)
		end

		local result = {}
		for _, entry in pairs(entries) do
			if entry.known or entry.defeat > 0 or entry.bossDrop > 0 then
				sortStrings(entry.quests)
				sortStrings(entry.islands)
				sortStrings(entry.markers)
				sortStrings(entry.drops)
				result[#result + 1] = {
					Name = entry.name,
					Target = entry.name,
					Quest = entry.quests[1],
					Quests = copyArray(entry.quests),
					Island = entry.islands[1],
					Islands = copyArray(entry.islands),
					Marker = entry.markers[1],
					Markers = copyArray(entry.markers),
					Drops = copyArray(entry.drops),
					Single = entry.single,
					Multi = entry.multi,
					Defeat = entry.defeat,
					BossDrop = entry.bossDrop,
					KnownMapping = entry.known,
					Evidence = {
						Defeat = entry.defeat > 0,
						BossDrop = entry.bossDrop > 0,
						KnownMapping = entry.known,
					},
				}
			end
		end
		table.sort(result, function(left, right)
			local leftName = string.lower(tostring(left.Name))
			local rightName = string.lower(tostring(right.Name))
			if leftName ~= rightName then
				return leftName < rightName
			end
			return tostring(left.Name) < tostring(right.Name)
		end)
		return result
	end

	-- Rewards exposes only the three live quests with current safe execution paths.
	local Rewards = type(GB.Rewards) == "table" and GB.Rewards or {}
	GB.Rewards = Rewards
	M.Rewards = Rewards
	M.originals.RewardsList = Rewards.list
	M.originals.RewardsClaim = Rewards.claim
	Rewards._uiOriginalList = Rewards.list
	Rewards._uiOriginalClaim = Rewards.claim

	function Rewards.list()
		return copyArray(SAFE_REWARDS)
	end

	function Rewards.claim()
		if M._destroyed then
			return false, "destroyed"
		end
		if type(GB.PlayerData) ~= "table" or type(GB.PlayerData.live) ~= "function" then
			return false, "player_data_unavailable"
		end
		if type(GB.Quest) ~= "table" or type(GB.Quest.doLive) ~= "function" then
			return false, "quest_unavailable"
		end
		for _, questName in ipairs(SAFE_REWARDS) do
			local liveOk, live = pcall(GB.PlayerData.live, questName)
			if liveOk and live ~= nil then
				local claimOk, progressed = pcall(GB.Quest.doLive, questName)
				if not claimOk then
					return false, tostring(progressed)
				end
				return true, questName, progressed
			end
		end
		return false, "none_available"
	end

	-- Explicit rerolls only. Existing automatic tick behavior is left untouched.
	local Haki = type(GB.Haki) == "table" and GB.Haki or {}
	GB.Haki = Haki
	M.Haki = Haki
	M.originals.HakiRerollAuraColor = Haki.rerollAuraColor
	Haki._uiOriginalRerollAuraColor = Haki.rerollAuraColor

	function Haki.rerollAuraColor()
		if M._destroyed then
			return false, "destroyed"
		end
		local now = os.clock()
		if Haki._uiAuraRerollAt and now - Haki._uiAuraRerollAt < REROLL_GAP then
			return false, "rate"
		end
		local remote, reason = getRemote("RerollAuraColor")
		if not remote then
			return false, reason
		end
		Haki._uiAuraRerollAt = now
		local ok, fireError = pcall(remote.FireServer, remote)
		if not ok then
			return false, tostring(fireError)
		end
		log("log", "HAKI", "RerollAuraColor requested")
		return true
	end

	Haki.RerollAuraColor = Haki.rerollAuraColor

	local RaceTrait = type(GB.RaceTrait) == "table" and GB.RaceTrait or {}
	GB.RaceTrait = RaceTrait
	M.RaceTrait = RaceTrait
	M.originals.RaceTraitRerollTrait = RaceTrait.rerollTrait
	RaceTrait._uiOriginalRerollTrait = RaceTrait.rerollTrait

	function RaceTrait.rerollTrait(slot)
		if M._destroyed then
			return false, "destroyed"
		end
		local slotNumber = tonumber(slot)
		if not slotNumber
			or slotNumber ~= slotNumber
			or slotNumber == math.huge
			or slotNumber == -math.huge
			or slotNumber % 1 ~= 0
			or slotNumber < 1
			or slotNumber > 8
		then
			return false, "bad_slot"
		end
		local now = os.clock()
		if RaceTrait._uiTraitRerollAt and now - RaceTrait._uiTraitRerollAt < REROLL_GAP then
			return false, "rate"
		end
		local remote, reason = getRemote("Reroll")
		if not remote then
			return false, reason
		end
		RaceTrait._uiTraitRerollAt = now
		local ok, fireError = pcall(remote.FireServer, remote, "Trait", slotNumber)
		if not ok then
			return false, tostring(fireError)
		end
		log("log", "RACE", "Trait reroll slot=" .. tostring(slotNumber))
		return true
	end

	RaceTrait.RerollTrait = RaceTrait.rerollTrait

	-- FULL_AUTO Talk (Pirate Instructions / Esopo) was a 0-interval retry:
	-- ToNPC logged Teleport, setPos failed destOk/snap-back, Quest.talk
	-- returned "travel" without lastTalk, Engine.decide immediately retried.
	-- Visible result: spam Teleport, character never moves, no Talk remote.
	local World = type(GB.World) == "table" and GB.World or nil
	local Quest = type(GB.Quest) == "table" and GB.Quest or nil
	if World and type(World.ToNPC) == "function" and type(World.setPos) == "function" then
		M.originals.WorldSetPos = World.setPos
		M.originals.WorldToNPC = World.ToNPC
		World._uiOriginalSetPos = World.setPos
		World._uiOriginalToNPC = World.ToNPC
		local talkTravel = {
			at = 0,
			key = nil,
			ok = false,
		}

		local function copyOpts(opts)
			local out = {}
			if type(opts) == "table" then
				for key, value in pairs(opts) do
					out[key] = value
				end
			end
			return out
		end

		local function destVector(cf)
			if typeof(cf) == "CFrame" then
				return cf.Position
			end
			if typeof(cf) == "Vector3" then
				return cf
			end
			return nil
		end

		local function clampTalkDest(pos, npcPos)
			if typeof(pos) ~= "Vector3" then
				return nil
			end
			local yMin = 4
			local yMax = tonumber(GB.Config and GB.Config.DestYMax) or 260
			if type(World.waterY) == "function" then
				local ok, water = pcall(World.waterY)
				if ok and type(water) == "number" then
					yMin = math.max(yMin, water + 2)
				end
			end
			local y = pos.Y
			if y ~= y or y < yMin or y > yMax then
				if typeof(npcPos) == "Vector3" and npcPos.Y == npcPos.Y then
					y = npcPos.Y
				else
					local root = type(World.hrp) == "function" and World.hrp() or nil
					y = root and root.Position.Y or (yMin + 6)
				end
			end
			y = math.clamp(y, yMin, yMax)
			return Vector3.new(pos.X, y, pos.Z)
		end

		local function applyPivot(pos, lookAt)
			if typeof(pos) ~= "Vector3" then
				return false
			end
			local root = type(World.hrp) == "function" and World.hrp() or nil
			local char = type(World.char) == "function" and World.char() or nil
			local hum = type(World.hum) == "function" and World.hum() or nil
			if not root then
				return false
			end
			if hum then
				pcall(function()
					hum.Sit = false
					hum.PlatformStand = false
				end)
			end
			pcall(function()
				root.Anchored = false
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
			end)
			local cf
			if typeof(lookAt) == "Vector3" then
				cf = CFrame.new(pos, Vector3.new(lookAt.X, pos.Y, lookAt.Z))
			else
				cf = CFrame.new(pos)
			end
			if char and type(char.PivotTo) == "function" then
				pcall(char.PivotTo, char, cf)
			elseif M.originals.WorldSetPos then
				local snapOpts = { AllowFar = true, SkipGround = true }
				pcall(M.originals.WorldSetPos, cf, snapOpts)
			end
			if type(World.rememberSafe) == "function" then
				pcall(World.rememberSafe)
			end
			if type(World.planarDist) == "function" then
				return World.planarDist(root.Position, pos) <= 18
			end
			return (root.Position - pos).Magnitude <= 22
		end

		function World.setPos(cf, opts)
			if M._destroyed then
				return M.originals.WorldSetPos(cf, opts)
			end
			opts = copyOpts(opts)
			local pos = destVector(cf)
			if typeof(pos) == "Vector3"
				and World.destOk
				and not World.destOk(pos, opts)
				and (opts.SkipGround == true or opts.AllowFar == true)
			then
				opts.AllowFar = true
				pos = clampTalkDest(pos, nil) or pos
				cf = pos
			end
			local ok = M.originals.WorldSetPos(cf, opts)
			if ok then
				local root = type(World.hrp) == "function" and World.hrp() or nil
				if root and typeof(pos) == "Vector3" and World.planarDist then
					if World.planarDist(root.Position, pos) <= 16 then
						return true
					end
				elseif ok then
					return true
				end
			end
			if typeof(pos) ~= "Vector3" then
				return ok == true
			end
			return applyPivot(clampTalkDest(pos, nil) or pos, nil)
		end

		function World.ToNPC(resolved, range)
			if M._destroyed then
				return M.originals.WorldToNPC(resolved, range)
			end
			local inst = type(resolved) == "table" and resolved.Instance or resolved
			local key = tostring(inst or resolved)
			local now = os.clock()
			if talkTravel.key == key and now - talkTravel.at < 0.4 then
				return talkTravel.ok == true
			end
			local ok = M.originals.WorldToNPC(resolved, range)
			local talkRange = (GB.Config and GB.Config.TalkRange) or 14
			if ok and World.atTalk and World.atTalk(resolved, talkRange) then
				talkTravel.at = now
				talkTravel.key = key
				talkTravel.ok = true
				return true
			end
			local dest = nil
			if type(World.safeOffset) == "function" then
				local destOk, value = pcall(World.safeOffset, inst, range or (GB.Config and GB.Config.TalkOffset) or 5)
				if destOk then
					dest = value
				end
			end
			local npcPos = inst and GB.Resolver and type(GB.Resolver.positionOf) == "function" and GB.Resolver.positionOf(inst)
			dest = clampTalkDest(dest or npcPos, npcPos)
			local moved = dest and applyPivot(dest, npcPos) or false
			talkTravel.at = now
			talkTravel.key = key
			talkTravel.ok = moved == true or (World.atTalk and World.atTalk(resolved, talkRange) == true)
			if talkTravel.ok then
				log("log", "TRAVEL", "talk snap " .. tostring(World.displayLabel and World.displayLabel(resolved) or inst))
			elseif now - (World._uiTalkFailAt or 0) >= 2 then
				World._uiTalkFailAt = now
				log("warn", "TRAVEL", "talk snap failed " .. tostring(key))
			end
			return talkTravel.ok
		end
	end

	if Quest and type(Quest.talk) == "function" then
		M.originals.QuestTalk = Quest.talk
		Quest._uiOriginalTalk = Quest.talk
		local talkGate = {
			at = 0,
			key = nil,
		}
		function Quest.talk(request, automatic, opts)
			if M._destroyed then
				return M.originals.QuestTalk(request, automatic, opts)
			end
			local key = tostring(request)
			local now = os.clock()
			if talkGate.key == key and now - talkGate.at < 0.45 then
				return false, "travel"
			end
			local ok, why = M.originals.QuestTalk(request, automatic, opts)
			if ok ~= true and why == "travel" then
				talkGate.at = now
				talkGate.key = key
			else
				talkGate.key = nil
			end
			return ok, why
		end
	end

	function M.destroy()
		if M._destroyed then
			return true
		end
		M._destroyed = true
		if World and M.originals.WorldSetPos then
			World.setPos = M.originals.WorldSetPos
		end
		if World and M.originals.WorldToNPC then
			World.ToNPC = M.originals.WorldToNPC
		end
		if Quest and M.originals.QuestTalk then
			Quest.talk = M.originals.QuestTalk
		end
		Codes.destroy()
		if schedulerWrapped then
			if runtimeShuttingDown() then
				Scheduler.stop()
			else
				invalidateSchedulerLoop()
			end
		end
		return true
	end

	-- Connect only; CodeProg and redemption traffic remain tick/user initiated.
	ensureCodeListener(false)

	return M
end
