return function(GB)
	local VirtualInputManager
	pcall(function()
		VirtualInputManager = game:GetService("VirtualInputManager")
	end)

	local OWNER = {
		IDLE = "IDLE",
		FULL_AUTO = "FULL_AUTO",
		MANUAL_QUEST = "MANUAL_QUEST",
		MANUAL_MOB = "MANUAL_MOB",
		MANUAL_BOSS = "MANUAL_BOSS",
		MANUAL_CHEST = "MANUAL_CHEST",
	}

	local VALID_OWNER = {}
	for _, value in pairs(OWNER) do
		VALID_OWNER[value] = true
	end

	local REPEAT_MODE = {
		ONE = true,
		ROTATE = true,
		BEST = true,
		NEAREST = true,
	}

	local MOB_MODE = {
		NEAREST = true,
		ROUND_ROBIN = true,
		FINISH_GROUP = true,
		PRIORITY = true,
	}

	local SAFE_UTILITY_AUTO = {
		AutoStats = true,
		AutoEquip = true,
		AutoCodes = true,
	}

	local TERMINAL_STATUS = {
		ACTION_COMPLETE = true,
		ACTION_FAILED = true,
		CHESTS_EXHAUSTED = true,
		LEVEL_REACHED = true,
		QUEST_COMPLETE = true,
		BOSS_LIMIT_REACHED = true,
	}

	local PHYSICAL_MAP = {
		["Anchor Town"] = true,
		["Clown Town"] = true,
		["Maple Village"] = true,
	}

	local KNOWN_BOSS = {
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

	local M = {
		OWNER = OWNER,
		owner = OWNER.IDLE,
		paused = false,
		selectedQuest = nil,
		selectedRepeatables = {},
		repeatMode = "ONE",
		farmUntilLevel = nil,
		resumeFullAuto = false,
		selectedMobs = {},
		mobMode = "NEAREST",
		selectedBosses = {},
		waitBoss = false,
		bossKillLimit = nil,
		chestMap = "CURRENT",
		chestAutoLoop = false,
		autoLoop = false,
		status = "IDLE",
		statusReason = "default",
		statusAt = os.clock(),
		error = nil,
		errorAt = nil,
		lastError = nil,
		lastErrorAt = nil,
		progress = nil,
		queueLimit = 24,
		targetStickiness = math.max(0, tonumber(GB.Config and GB.Config.TargetStickiness) or 2),
		targetSwitchDistance = math.max(10, tonumber(GB.Config and GB.Config.TargetSwitchDistance) or 55),
		utilityAuto = {
			AutoStats = false,
			AutoEquip = false,
			AutoCodes = false,
		},
	}

	local changeListeners = {}
	local statusListeners = {}
	local listenerId = 0
	local reportAt = {}
	local configSnapshot = {}
	local configuredAutoKeys = {}
	local queue = {}
	local actionId = 0

	M._generation = 1
	M._session = 0
	M._destroyed = false
	M._ticking = false
	M._configGated = false
	M._work = nil
	M._workSerial = 0
	M._repeatCursor = 1
	M._repeatActive = nil
	M._repeatHadLive = false
	M._repeatCycles = 0
	M._mobCursor = 1
	M._mobActiveName = nil
	M._mobActiveInstance = nil
	M._pendingMob = nil
	M._pendingMobName = nil
	M._finishGroupName = nil
	M._mobLockedAt = nil
	M._bossCursor = 1
	M._pendingBoss = nil
	M._pendingBossName = nil
	M._bossActiveInstance = nil
	M._bossActiveName = nil
	M._bossKills = 0
	M._waitBossTarget = nil
	M._bossDescriptors = nil
	M._chestTarget = nil
	M._chestOpened = 0
	M._respawnHeld = false

	local workByThread = setmetatable({}, { __mode = "k" })

	local function workStillValid(work)
		return type(work) == "table"
			and M._work == work
			and work.cancelled ~= true
			and M._destroyed ~= true
			and M._generation == work.generation
			and M.owner == work.owner
	end

	local function workCommitAllowed()
		local thread = coroutine.running()
		local work = thread and workByThread[thread] or nil
		if not work then
			return true
		end
		if work.completing == true then
			return M._generation == work.completionGeneration
				and M.owner == work.completionOwner
		end
		return workStillValid(work)
	end

	local function now()
		return os.clock()
	end

	local function trim(value)
		if type(value) ~= "string" then
			return nil
		end
		local out = string.gsub(value, "^%s+", "")
		out = string.gsub(out, "%s+$", "")
		if out == "" then
			return nil
		end
		return out
	end

	local function selectionName(value)
		if type(value) == "string" then
			return trim(value)
		end
		if type(value) == "table" then
			return trim(value.Name or value.name or value.Value or value.value)
		end
		return nil
	end

	local function normalizeList(values)
		local out = {}
		local seen = {}
		local function add(value)
			local name = selectionName(value)
			if not name then
				return
			end
			local key = string.lower(tostring(name))
			if seen[key] then
				return
			end
			seen[key] = true
			out[#out + 1] = name
		end
		if type(values) == "string" then
			add(values)
			return out
		end
		if type(values) ~= "table" then
			return out
		end
		for _, value in ipairs(values) do
			add(value)
		end
		local keyed = {}
		for key, value in pairs(values) do
			if type(key) ~= "number" and value then
				keyed[#keyed + 1] = selectionName(value) or selectionName(key)
			end
		end
		table.sort(keyed, function(a, b)
			return tostring(a or "") < tostring(b or "")
		end)
		for _, value in ipairs(keyed) do
			add(value)
		end
		return out
	end

	local function copyList(values)
		local out = {}
		for i, value in ipairs(values or {}) do
			out[i] = value
		end
		return out
	end

	local function copyTable(value)
		if type(value) ~= "table" then
			return value
		end
		local out = {}
		for key, item in pairs(value) do
			if type(item) == "table" then
				local nested = {}
				for nestedKey, nestedValue in pairs(item) do
					nested[nestedKey] = nestedValue
				end
				out[key] = nested
			else
				out[key] = item
			end
		end
		return out
	end

	local function sameList(a, b)
		if #a ~= #b then
			return false
		end
		for i = 1, #a do
			if a[i] ~= b[i] then
				return false
			end
		end
		return true
	end

	local function contains(values, wanted)
		for i = 1, #(values or {}) do
			if values[i] == wanted then
				return true, i
			end
		end
		return false, nil
	end

	local function methodArg(first, second)
		if first == M then
			return second
		end
		return first
	end

	local function methodArgs(first, second, third)
		if first == M then
			return second, third
		end
		return first, second
	end

	local function rateLog(level, key, message, gap)
		local at = now()
		gap = tonumber(gap) or 6
		if at - (reportAt[key] or 0) < gap then
			return
		end
		reportAt[key] = at
		local logger = GB and GB.Log
		if type(logger) ~= "table" then
			return
		end
		local fn = level == "ERROR" and logger.err or logger.warn
		if type(fn) == "function" then
			pcall(fn, "UI", tostring(message))
		end
	end

	local function listenerHandle(bucket, id)
		local connected = true
		local handle = {}
		function handle:Disconnect()
			if not connected then
				return
			end
			connected = false
			bucket[id] = nil
		end
		handle.disconnect = handle.Disconnect
		return handle
	end

	local function statusFingerprint(status, reason, progress)
		local p = type(progress) == "table" and progress or {}
		return table.concat({
			tostring(status or ""),
			tostring(reason or ""),
			tostring(p.kind or ""),
			tostring(p.target or p.quest or p.boss or p.chest or ""),
			tostring(p.stage or ""),
			tostring(p.current or ""),
			tostring(p.total or ""),
			tostring(p.reason or ""),
		}, "|")
	end

	local function emitChange(reason)
		if M._destroyed then
			return
		end
		local snapshot = M.getSnapshot and M.getSnapshot() or nil
		for id, callback in pairs(changeListeners) do
			local ok, err = pcall(callback, snapshot, reason)
			if not ok then
				changeListeners[id] = nil
				rateLog("ERROR", "change_listener:" .. tostring(id), "change listener failed: " .. tostring(err), 8)
			end
		end
	end

	local function emitStatus(reason)
		if M._destroyed then
			return
		end
		local snapshot = {
			status = M.status,
			reason = M.statusReason,
			at = M.statusAt,
			error = M.error,
			lastError = M.lastError,
			progress = copyTable(M.progress),
			owner = M.owner,
			paused = M.paused,
		}
		for id, callback in pairs(statusListeners) do
			local ok, err = pcall(callback, snapshot, reason)
			if not ok then
				statusListeners[id] = nil
				rateLog("ERROR", "status_listener:" .. tostring(id), "status listener failed: " .. tostring(err), 8)
			end
		end
	end

	local function setStatus(status, reason, progress, force)
		if not workCommitAllowed() then
			return false
		end
		status = tostring(status or "UNKNOWN")
		local fingerprint = statusFingerprint(status, reason, progress)
		local changed = force == true or fingerprint ~= M._statusFingerprint
		M.status = status
		M.statusReason = reason
		M.statusAt = now()
		M.progress = copyTable(progress)
		M._statusFingerprint = fingerprint
		if changed then
			emitStatus(reason)
		end
		return true
	end

	local function clearError()
		if not workCommitAllowed() then
			return false
		end
		M.error = nil
		M.errorAt = nil
		return true
	end

	local function setError(key, message)
		if not workCommitAllowed() then
			return false
		end
		message = tostring(message or "unknown error")
		M.error = message
		M.errorAt = now()
		M.lastError = message
		M.lastErrorAt = M.errorAt
		rateLog("ERROR", "error:" .. tostring(key), message, 6)
		setStatus("ERROR", message, {
			kind = "ERROR",
			reason = tostring(key),
		}, true)
		return true
	end

	local function markContextDirty(reason)
		if GB and GB.Knowledge and type(GB.Knowledge.invalidateContext) == "function" then
			pcall(GB.Knowledge.invalidateContext)
		end
		if GB and GB.Engine then
			if type(GB.Engine.markContextDirty) == "function" then
				pcall(GB.Engine.markContextDirty, reason or "ui_controller")
			else
				GB.Engine._contextDirty = true
			end
		end
		if GB and GB.Scheduler and type(GB.Scheduler.nudge) == "function" then
			pcall(GB.Scheduler.nudge)
		end
	end

	local function cancelRuntime()
		if GB and GB.Combat and type(GB.Combat.stopLock) == "function" then
			pcall(GB.Combat.stopLock)
		end
		if GB and GB.World and type(GB.World.cancelTween) == "function" then
			pcall(GB.World.cancelTween)
		end
		if VirtualInputManager then
			local x, y = 0, 0
			pcall(function()
				local camera = workspace.CurrentCamera
				local viewport = camera and camera.ViewportSize
				if viewport then
					x = viewport.X * 0.5
					y = viewport.Y * 0.58
				end
			end)
			pcall(
				VirtualInputManager.SendMouseButtonEvent,
				VirtualInputManager,
				x,
				y,
				0,
				false,
				game,
				1
			)
		end
	end

	local function taskList()
		GB.Tasks = type(GB.Tasks) == "table" and GB.Tasks or {}
		return GB.Tasks
	end

	local function trackTask(thread)
		if not thread then
			return
		end
		local tasks = taskList()
		tasks[#tasks + 1] = thread
	end

	local function untrackTask(thread)
		if not thread or type(GB.Tasks) ~= "table" then
			return
		end
		for index = #GB.Tasks, 1, -1 do
			if GB.Tasks[index] == thread then
				table.remove(GB.Tasks, index)
			end
		end
	end

	local function cancelActiveWork(reason)
		local work = M._work
		if not work then
			cancelRuntime()
			return false
		end
		work.cancelled = true
		work.cancelReason = reason or "cancelled"
		if work.action then
			work.action.cancelled = true
			work.action.cancelReason = work.cancelReason
			if work.action.handle then
				work.action.handle.Cancelled = true
				work.action.handle.Running = false
				work.action.handle.cancelReason = work.cancelReason
			end
		end
		M._work = nil
		local thread = work.thread
		untrackTask(thread)
		cancelRuntime()
		if thread and coroutine.running() ~= thread then
			local statusOk, status = pcall(coroutine.status, thread)
			if not statusOk or status ~= "dead" then
				pcall(task.cancel, thread)
			end
			work.thread = nil
		end
		return true
	end

	local function clearQueue(reason)
		for _, action in ipairs(queue) do
			action.cancelled = true
			action.cancelReason = reason or "cleared"
			if action.handle then
				action.handle.Cancelled = true
				action.handle.cancelReason = action.cancelReason
			end
		end
		queue = {}
	end

	local function clearTransient(reason)
		M._repeatCursor = 1
		M._repeatActive = nil
		M._repeatHadLive = false
		M._mobCursor = 1
		M._mobActiveName = nil
		M._mobActiveInstance = nil
		M._pendingMob = nil
		M._pendingMobName = nil
		M._finishGroupName = nil
		M._mobLockedAt = nil
		M._bossCursor = 1
		M._pendingBoss = nil
		M._pendingBossName = nil
		M._bossActiveInstance = nil
		M._bossActiveName = nil
		M._bossKills = 0
		M._waitBossTarget = nil
		M._bossDescriptors = nil
		M._chestTarget = nil
		M._lastResetReason = reason
	end

	local function resetSessionCounters()
		M._session = M._session + 1
		M._repeatCycles = 0
		M._chestOpened = 0
	end

	local function invalidateWork(reason)
		M._generation = M._generation + 1
		cancelActiveWork(reason)
		clearQueue(reason)
		clearTransient(reason)
		markContextDirty(reason)
	end

	local function collectAutoKeys()
		local keys = {
			AutoQuest = true,
			AutoLevel = true,
			AutoBoss = true,
			AutoChest = true,
			AutoTreasure = true,
			AutoCodes = true,
			AutoRewards = true,
		}
		local config = GB and GB.Config
		if type(config) == "table" then
			for key, value in pairs(config) do
				if type(key) == "string"
					and string.sub(key, 1, 4) == "Auto"
					and key ~= "AutoRespawn"
					and type(value) == "boolean"
				then
					keys[key] = true
				end
			end
		end
		local out = {}
		for key in pairs(keys) do
			out[#out + 1] = key
		end
		table.sort(out)
		configuredAutoKeys = out
		return out
	end

	local function captureAutos()
		local config = GB and GB.Config
		if type(config) ~= "table" then
			return
		end
		for _, key in ipairs(collectAutoKeys()) do
			configSnapshot[key] = {
				present = config[key] ~= nil,
				value = config[key],
			}
		end
	end

	local function gateAutos()
		local config = GB and GB.Config
		if type(config) ~= "table" then
			return
		end
		for _, key in ipairs(collectAutoKeys()) do
			if SAFE_UTILITY_AUTO[key] then
				config[key] = M.utilityAuto[key] == true
			elseif key ~= "AutoRespawn" then
				config[key] = false
			end
		end
		M._configGated = true
	end

	local function restoreAutos()
		local config = GB and GB.Config
		if type(config) ~= "table" then
			return
		end
		for _, key in ipairs(configuredAutoKeys) do
			local saved = configSnapshot[key]
			if saved then
				if saved.present then
					config[key] = saved.value
				else
					config[key] = nil
				end
			end
		end
		M._configGated = false
	end

	function M.getSnapshot()
		local work = M._work
		local workState
		if work then
			workState = {
				id = work.id,
				kind = work.kind,
				label = work.label,
				owner = work.owner,
				generation = work.generation,
				startedAt = work.startedAt,
				cancelled = work.cancelled == true,
				cancelReason = work.cancelReason,
			}
		end
		return {
			owner = M.owner,
			paused = M.paused,
			selectedQuest = M.selectedQuest,
			selectedRepeatables = copyList(M.selectedRepeatables),
			repeatMode = M.repeatMode,
			farmUntilLevel = M.farmUntilLevel,
			resumeFullAuto = M.resumeFullAuto,
			selectedMobs = copyList(M.selectedMobs),
			mobMode = M.mobMode,
			selectedBosses = copyList(M.selectedBosses),
			waitBoss = M.waitBoss,
			bossKillLimit = M.bossKillLimit,
			bossKills = M._bossKills,
			chestMap = M.chestMap,
			chestAutoLoop = M.chestAutoLoop == true or M.autoLoop == true,
			combatRange = GB and GB.Config and GB.Config.CombatRange or nil,
			targetStickiness = M.targetStickiness,
			targetSwitchDistance = M.targetSwitchDistance,
			status = M.status,
			statusReason = M.statusReason,
			statusAt = M.statusAt,
			error = M.error,
			errorAt = M.errorAt,
			lastError = M.lastError,
			lastErrorAt = M.lastErrorAt,
			progress = copyTable(M.progress),
			generation = M._generation,
			session = M._session,
			queued = #queue,
			workActive = work ~= nil,
			workTask = workState,
			destroyed = M._destroyed,
		}
	end

	M.snapshot = M.getSnapshot
	M.getState = M.getSnapshot

	function M.getOwner()
		return M.owner
	end

	function M.getStatus()
		return M.status, M.statusReason, copyTable(M.progress), M.error
	end

	function M.getSelections()
		return {
			quest = M.selectedQuest,
			repeatables = copyList(M.selectedRepeatables),
			mobs = copyList(M.selectedMobs),
			bosses = copyList(M.selectedBosses),
			chestMap = M.chestMap,
		}
	end

	function M.onChange(first, second)
		local callback = methodArg(first, second)
		if type(callback) ~= "function" or M._destroyed then
			return listenerHandle({}, 0)
		end
		listenerId = listenerId + 1
		changeListeners[listenerId] = callback
		return listenerHandle(changeListeners, listenerId)
	end

	function M.onStatus(first, second)
		local callback = methodArg(first, second)
		if type(callback) ~= "function" or M._destroyed then
			return listenerHandle({}, 0)
		end
		listenerId = listenerId + 1
		statusListeners[listenerId] = callback
		return listenerHandle(statusListeners, listenerId)
	end

	M.subscribe = M.onChange
	M.subscribeChange = M.onChange
	M.subscribeStatus = M.onStatus

	function M.setOwner(first, second, third)
		local mode, reason = methodArgs(first, second, third)
		mode = trim(mode)
		if M._destroyed then
			return false, "destroyed"
		end
		if not mode or not VALID_OWNER[mode] then
			local message = "invalid owner " .. tostring(mode)
			setError("invalid_owner", message)
			return false, message
		end

		local previous = M.owner
		if previous == OWNER.FULL_AUTO and not M._configGated then
			captureAutos()
		end
		invalidateWork("owner:" .. tostring(previous) .. "->" .. mode)
		M.owner = mode
		M.paused = false
		if mode ~= OWNER.IDLE then
			resetSessionCounters()
		end
		if mode == OWNER.FULL_AUTO then
			restoreAutos()
		else
			gateAutos()
		end
		clearError()
		setStatus(mode == OWNER.IDLE and "IDLE" or "READY", reason or mode, {
			kind = "OWNER",
			target = mode,
		}, true)
		markContextDirty("ui_owner:" .. mode)
		emitChange(reason or "owner")
		return true, mode
	end

	function M.stop(first, second)
		local reason = methodArg(first, second)
		return M.setOwner(OWNER.IDLE, reason or "stopped")
	end

	local function completeOwnerWork(mode, reason, terminalStatus, terminalReason, progress)
		local thread = coroutine.running()
		local work = thread and workByThread[thread] or nil
		if work and not workStillValid(work) then
			return false, "stale work"
		end
		if work then
			work.completing = true
			work.completionGeneration = work.generation + 1
			work.completionOwner = mode
		end
		local ok, detail = M.setOwner(mode, reason)
		if ok
			and terminalStatus
			and (not work or (
				M._generation == work.completionGeneration
				and M.owner == work.completionOwner
			))
		then
			setStatus(terminalStatus, terminalReason or reason, progress, true)
		end
		if work then
			work.completing = false
			work.completionGeneration = nil
			work.completionOwner = nil
		end
		return ok, detail
	end

	function M.pause(first, second)
		local reason = methodArg(first, second)
		if M._destroyed then
			return false, "destroyed"
		end
		if M.paused then
			return true
		end
		M._generation = M._generation + 1
		M.paused = true
		cancelActiveWork(reason or "paused")
		clearQueue(reason or "paused")
		M._pendingMob = nil
		M._pendingMobName = nil
		M._pendingBoss = nil
		M._pendingBossName = nil
		setStatus("PAUSED", reason or M.owner, {
			kind = "OWNER",
			target = M.owner,
		}, true)
		emitChange(reason or "paused")
		return true
	end

	function M.resume(first, second)
		local reason = methodArg(first, second)
		if M._destroyed then
			return false, "destroyed"
		end
		if not M.paused then
			return true
		end
		M.paused = false
		clearError()
		markContextDirty("ui_resume")
		setStatus(M.owner == OWNER.IDLE and "IDLE" or "READY", reason or "resumed", {
			kind = "OWNER",
			target = M.owner,
		}, true)
		emitChange(reason or "resumed")
		return true
	end

	local function selectionChanged(reason, activeOwner)
		if M.owner == activeOwner or M._work ~= nil then
			invalidateWork(reason)
		else
			markContextDirty(reason)
		end
		clearError()
		emitChange(reason)
	end

	function M.setSelectedQuest(first, second)
		local value = methodArg(first, second)
		local name = selectionName(value)
		if M.selectedQuest == name then
			return true, name
		end
		M.selectedQuest = name
		selectionChanged("selected_quest", OWNER.MANUAL_QUEST)
		return true, name
	end

	function M.setSelectedRepeatables(first, second)
		local values = methodArg(first, second)
		local list = normalizeList(values)
		if sameList(M.selectedRepeatables, list) then
			return true, copyList(list)
		end
		M.selectedRepeatables = list
		selectionChanged("selected_repeatables", OWNER.MANUAL_QUEST)
		return true, copyList(list)
	end

	function M.setRepeatMode(first, second)
		local value = methodArg(first, second)
		local mode = type(value) == "string" and string.upper(value) or nil
		if not mode or not REPEAT_MODE[mode] then
			return false, "invalid repeat mode"
		end
		if M.repeatMode ~= mode then
			M.repeatMode = mode
			selectionChanged("repeat_mode", OWNER.MANUAL_QUEST)
		end
		return true, mode
	end

	function M.setFarmUntilLevel(first, second)
		local value = methodArg(first, second)
		local level = tonumber(value)
		if value == nil or value == false or value == "" then
			level = nil
		elseif not level or level < 1 then
			return false, "invalid level"
		else
			level = math.floor(level)
		end
		M.farmUntilLevel = level
		selectionChanged("farm_until_level", OWNER.MANUAL_QUEST)
		return true, level
	end

	function M.setResumeFullAuto(first, second)
		local value = methodArg(first, second)
		M.resumeFullAuto = value == true
		emitChange("resume_full_auto")
		return true, M.resumeFullAuto
	end

	function M.setSelectedMobs(first, second)
		local values = methodArg(first, second)
		local list = normalizeList(values)
		if sameList(M.selectedMobs, list) then
			return true, copyList(list)
		end
		M.selectedMobs = list
		selectionChanged("selected_mobs", OWNER.MANUAL_MOB)
		return true, copyList(list)
	end

	function M.setMobMode(first, second)
		local value = methodArg(first, second)
		local mode = type(value) == "string" and string.upper(value) or nil
		if not mode or not MOB_MODE[mode] then
			return false, "invalid mob mode"
		end
		if M.mobMode ~= mode then
			M.mobMode = mode
			selectionChanged("mob_mode", OWNER.MANUAL_MOB)
		end
		return true, mode
	end

	function M.setSelectedBosses(first, second)
		local values = methodArg(first, second)
		local list = normalizeList(values)
		if sameList(M.selectedBosses, list) then
			return true, copyList(list)
		end
		M.selectedBosses = list
		selectionChanged("selected_bosses", OWNER.MANUAL_BOSS)
		return true, copyList(list)
	end

	function M.setWaitBoss(first, second)
		local value = methodArg(first, second)
		M.waitBoss = value == true
		selectionChanged("wait_boss", OWNER.MANUAL_BOSS)
		return true, M.waitBoss
	end

	function M.setBossKillLimit(first, second)
		local value = methodArg(first, second)
		if value == nil or value == false or value == "" then
			M.bossKillLimit = nil
		else
			local amount = math.floor(tonumber(value) or 0)
			if amount < 1 or amount > 1000 then
				return false, "invalid boss kill limit"
			end
			M.bossKillLimit = amount
		end
		M._bossKills = 0
		emitChange("boss_kill_limit")
		return true, M.bossKillLimit
	end

	function M.setUtilityAuto(first, second, third)
		local key, value = methodArgs(first, second, third)
		if not SAFE_UTILITY_AUTO[key] then
			return false, "unsupported utility"
		end
		M.utilityAuto[key] = value == true
		if M.owner ~= OWNER.FULL_AUTO and type(GB.Config) == "table" then
			GB.Config[key] = M.utilityAuto[key]
		end
		emitChange("utility_auto:" .. tostring(key))
		return true, M.utilityAuto[key]
	end

	function M.setTargetStickiness(first, second)
		local value = methodArg(first, second)
		local seconds = tonumber(value)
		if not seconds then
			return false, "invalid stickiness"
		end
		M.targetStickiness = math.max(0, math.min(30, seconds))
		if type(GB.Config) == "table" then
			GB.Config.TargetStickiness = M.targetStickiness
		end
		emitChange("target_stickiness")
		return true, M.targetStickiness
	end

	function M.setTargetSwitchDistance(first, second)
		local value = methodArg(first, second)
		local distance = tonumber(value)
		if not distance then
			return false, "invalid switch distance"
		end
		M.targetSwitchDistance = math.max(10, math.min(300, distance))
		if type(GB.Config) == "table" then
			GB.Config.TargetSwitchDistance = M.targetSwitchDistance
		end
		emitChange("target_switch_distance")
		return true, M.targetSwitchDistance
	end

	function M.setChestMap(first, second)
		local value = methodArg(first, second)
		local map = selectionName(value)
		if map == nil or string.upper(map) == "CURRENT" then
			map = "CURRENT"
		elseif not PHYSICAL_MAP[map] then
			return false, "unverified chest map"
		end
		if M.chestMap ~= map then
			M.chestMap = map
			selectionChanged("chest_map", OWNER.MANUAL_CHEST)
		end
		return true, map
	end

	function M.setChestAutoLoop(first, second)
		local value = methodArg(first, second)
		local enabled = value == true
		M.chestAutoLoop = enabled
		M.autoLoop = enabled
		emitChange("chest_auto_loop")
		return true, enabled
	end

	function M.setCombatRange(first, second)
		local value = methodArg(first, second)
		local range = tonumber(value)
		if not range or range ~= range then
			return false, "invalid range"
		end
		range = math.max(2, math.min(30, range))
		if GB and type(GB.Config) == "table" then
			GB.Config.CombatRange = range
		end
		emitChange("combat_range")
		return true, range
	end

	M.setRange = M.setCombatRange

	function M.getRange()
		return GB and GB.Config and GB.Config.CombatRange or nil
	end

	function M.enqueue(first, second, third, fourth)
		local label, callback, opts
		if first == M then
			label, callback, opts = second, third, fourth
		else
			label, callback, opts = first, second, third
		end
		opts = type(opts) == "table" and opts or {}
		if M._destroyed then
			return false, "destroyed"
		end
		if type(callback) ~= "function" then
			return false, "callback required"
		end
		if #queue >= M.queueLimit then
			rateLog("WARN", "queue_full", "manual action queue full", 5)
			return false, "queue full"
		end
		local key = trim(opts.key)
		if key then
			local activeAction = M._work and M._work.action
			if activeAction and not activeAction.cancelled and activeAction.key == key then
				return false, "duplicate"
			end
			for _, queued in ipairs(queue) do
				if not queued.cancelled and queued.key == key then
					return false, "duplicate"
				end
			end
		end
		actionId = actionId + 1
		local action = {
			id = actionId,
			label = trim(label) or ("action " .. tostring(actionId)),
			fn = callback,
			opts = opts,
			key = key,
			generation = M._generation,
			owner = M.owner,
			cancelled = false,
		}
		local handle = {
			Id = action.id,
			Label = action.label,
			Cancelled = false,
			Running = false,
			Completed = false,
		}
		function handle:Cancel(reason)
			if action.cancelled then
				return
			end
			action.cancelled = true
			action.cancelReason = reason or "cancelled"
			self.Cancelled = true
			self.cancelReason = action.cancelReason
			if M._work and M._work.action == action then
				cancelActiveWork(action.cancelReason)
			end
		end
		handle.Disconnect = handle.Cancel
		handle.disconnect = handle.Cancel
		action.handle = handle
		queue[#queue + 1] = action
		emitChange("enqueue")
		if GB and GB.Scheduler and type(GB.Scheduler.nudge) == "function" then
			pcall(GB.Scheduler.nudge)
		end
		return true, handle
	end

	local function takeQueuedAction()
		local action
		local remaining = {}
		for _, candidate in ipairs(queue) do
			local valid = not candidate.cancelled and candidate.generation == M._generation
			if not action and valid then
				action = candidate
			elseif valid then
				remaining[#remaining + 1] = candidate
			end
		end
		queue = remaining
		if not action then
			return nil
		end
		if action.opts.requireOwner and action.owner ~= M.owner then
			action.cancelled = true
			action.cancelReason = "owner changed"
			if action.handle then
				action.handle.Cancelled = true
				action.handle.cancelReason = action.cancelReason
			end
			return nil
		end
		return action
	end

	local function dispatchWork(kind, label, owner, callback, action)
		if M._work then
			return false, "work pending"
		end
		M._workSerial = M._workSerial + 1
		local work = {
			id = M._workSerial,
			kind = kind,
			label = label,
			owner = owner,
			generation = M._generation,
			startedAt = now(),
			cancelled = false,
			action = action,
		}
		local thread
		thread = coroutine.create(function()
			local ok, result, detail = pcall(callback)
			local valid = workStillValid(work)
			if valid then
				if not ok then
					setError(
						"work:" .. tostring(kind),
						tostring(label) .. " failed: " .. tostring(result)
					)
				elseif action then
					if result == false then
						local reason = tostring(detail or "action returned false")
						M.error = reason
						M.errorAt = now()
						setStatus("ACTION_FAILED", reason, {
							kind = "ACTION",
							target = action.label,
							reason = reason,
						}, true)
					else
						clearError()
						setStatus("ACTION_COMPLETE", action.label, {
							kind = "ACTION",
							target = action.label,
							reason = detail,
						}, true)
					end
					emitChange("action")
				end
			end
			local completed = valid and workStillValid(work)
			if M._work == work then
				M._work = nil
			end
			untrackTask(thread)
			workByThread[thread] = nil
			if action and action.handle then
				action.handle.Running = false
				action.handle.Completed = completed
				action.handle.Result = completed and result or nil
				action.handle.Detail = completed and detail or nil
			end
			if GB and GB.Scheduler and type(GB.Scheduler.nudge) == "function" then
				pcall(GB.Scheduler.nudge)
			end
		end)
		work.thread = thread
		workByThread[thread] = work
		M._work = work
		if action and action.handle then
			action.handle.Running = true
		end
		trackTask(thread)
		local scheduled, scheduleError = pcall(task.spawn, thread)
		if not scheduled then
			if M._work == work then
				M._work = nil
			end
			work.cancelled = true
			work.cancelReason = "spawn failed"
			workByThread[thread] = nil
			untrackTask(thread)
			if action and action.handle then
				action.handle.Running = false
				action.handle.Cancelled = true
				action.handle.cancelReason = work.cancelReason
			end
			return false, tostring(scheduleError)
		end
		return true, work
	end

	local function safeState(refresh)
		local state = GB and GB.State
		if type(state) ~= "table" then
			return {}
		end
		local fn = refresh and state.refresh or state.get
		if type(fn) ~= "function" then
			fn = state.get or state.refresh
		end
		if type(fn) ~= "function" then
			return {}
		end
		local ok, snapshot = pcall(fn)
		if ok and type(snapshot) == "table" then
			return snapshot
		end
		return {}
	end

	local function questRow(name)
		if not name then
			return nil
		end
		local generated = GB and GB.GeneratedData
		if generated then
			if type(generated.quest) == "function" then
				local ok, row = pcall(generated.quest, name)
				if ok and type(row) == "table" then
					return row
				end
			end
			if type(generated.Quests) == "table" and type(generated.Quests[name]) == "table" then
				return generated.Quests[name]
			end
		end
		if GB and GB.Knowledge and type(GB.Knowledge.quest) == "function" then
			local ok, row = pcall(GB.Knowledge.quest, name)
			if ok and type(row) == "table" then
				return row
			end
		end
		return nil
	end

	local function isRepeatable(name)
		local row = questRow(name)
		if row and row.Repeatable == true then
			return true
		end
		local data = GB and GB.QuestData
		if data and type(data.isRepeatable) == "function" then
			local ok, value = pcall(data.isRepeatable, name)
			return ok and value == true
		end
		return false
	end

	local function readQuestState(name)
		if not (GB and GB.Quest and type(GB.Quest.questState) == "function") then
			return nil
		end
		local ok, value = pcall(GB.Quest.questState, name)
		if ok and type(value) == "table" then
			return value
		end
		return nil
	end

	local function playerFinished(name)
		if not (GB and GB.PlayerData and type(GB.PlayerData.finished) == "function") then
			return false
		end
		local ok, value = pcall(GB.PlayerData.finished, name, true)
		return ok and value == true
	end

	local function hasItem(name)
		if not (GB and GB.PlayerData and type(GB.PlayerData.hasItem) == "function") then
			return false
		end
		local ok, value = pcall(GB.PlayerData.hasItem, name)
		return ok and value == true
	end

	local function blockerReason(kind, current, required, subject)
		if kind == "LEVEL" then
			return string.format("Level %s/%s", tostring(current or 0), tostring(required or "?"))
		end
		if kind == "PREREQUISITE" then
			return "Requires " .. tostring(subject or required or "prerequisite")
		end
		if kind == "ITEM" then
			return "Requires item " .. tostring(subject or required or "unknown")
		end
		if kind == "STAT" then
			return string.format("%s %s/%s", tostring(subject or "Stat"), tostring(current or 0), tostring(required or "?"))
		end
		return tostring(subject or "Unclassified blocker")
	end

	function M.describeBlocker(first, second)
		local name = methodArg(first, second)
		name = selectionName(name)
		if not name then
			return "UNKNOWN", "Quest name missing"
		end

		if GB and GB.Quest and type(GB.Quest.CurrentBlockers) == "function" then
			local ok, blockers = pcall(GB.Quest.CurrentBlockers)
			if ok and type(blockers) == "table" then
				for _, blocker in ipairs(blockers) do
					if type(blocker) == "table" and (blocker.Quest == nil or blocker.Quest == name) then
						local rawType = string.upper(tostring(blocker.Type or blocker.Kind or ""))
						local kind
						if string.find(rawType, "LEVEL", 1, true) then
							kind = "LEVEL"
						elseif string.find(rawType, "PREREQ", 1, true) then
							kind = "PREREQUISITE"
						elseif string.find(rawType, "ITEM", 1, true) then
							kind = "ITEM"
						elseif string.find(rawType, "STAT", 1, true) then
							kind = "STAT"
						else
							kind = "UNKNOWN"
						end
						local subject = blocker.Stat or blocker.Item or blocker.Prerequisite or blocker.Reason
						return kind, blocker.Reason or blockerReason(kind, blocker.Current, blocker.Required, subject), blocker
					end
				end
			end
		end

		local snapshot = safeState(false)
		local row = questRow(name)
		if row then
			local requiredLevel = math.max(tonumber(row.AcceptLevel) or 0, tonumber(row.NeedLevel) or 0)
			local currentLevel = tonumber(snapshot.Level) or 0
			if currentLevel < requiredLevel then
				return "LEVEL", blockerReason("LEVEL", currentLevel, requiredLevel), {
					Quest = name,
					Current = currentLevel,
					Required = requiredLevel,
				}
			end
			for _, prerequisite in ipairs(row.Prerequisites or {}) do
				if not playerFinished(prerequisite) then
					return "PREREQUISITE", blockerReason("PREREQUISITE", nil, nil, prerequisite), {
						Quest = name,
						Prerequisite = prerequisite,
					}
				end
			end
		end

		local data = GB and GB.QuestData
		if data and type(data.NEED_ITEM) == "table" then
			local itemNames = {}
			for itemName in pairs(data.NEED_ITEM) do
				itemNames[#itemNames + 1] = itemName
			end
			table.sort(itemNames)
			for _, itemName in ipairs(itemNames) do
				local requirement = data.NEED_ITEM[itemName]
				if type(requirement) == "table" and requirement.quest == name and not hasItem(itemName) then
					return "ITEM", blockerReason("ITEM", nil, nil, itemName), {
						Quest = name,
						Item = itemName,
					}
				end
			end
		end

		if data and type(data.questRequirement) == "function" then
			local ok, requirement = pcall(data.questRequirement, name)
			if ok and type(requirement) == "table" then
				local stats = snapshot.Stats or {}
				local liveStats
				if GB and GB.Stats and type(GB.Stats.ReadStatState) == "function" then
					local statOk, value = pcall(GB.Stats.ReadStatState)
					if statOk and type(value) == "table" then
						liveStats = value
					end
				end
				local statNames = {}
				for statName, amount in pairs(requirement) do
					if type(amount) == "number" then
						statNames[#statNames + 1] = statName
					end
				end
				table.sort(statNames)
				for _, statName in ipairs(statNames) do
					local required = tonumber(requirement[statName]) or 0
					local current = tonumber(liveStats and liveStats[statName]) or tonumber(stats[statName]) or 0
					if current < required then
						return "STAT", blockerReason("STAT", current, required, statName), {
							Quest = name,
							Stat = statName,
							Current = current,
							Required = required,
						}
					end
				end
			end
		end

		local state = readQuestState(name)
		if state and not state.IsAccepted and isRepeatable(name)
			and data and type(data.repeatStartSpec) == "function"
		then
			local ok, start = pcall(data.repeatStartSpec, name)
			if ok and type(start) == "table" and start.Status == "UNRESOLVED_START" then
				return "UNKNOWN", "Quest start is unresolved", start
			end
		end
		if GB and GB.Quest and type(GB.Quest.questStatus) == "function" then
			local ok, status, reason = pcall(GB.Quest.questStatus, name)
			if ok and (status == "BLOCKED_REQUIREMENT" or status == "DEFERRED" or status == "UNRESOLVED") then
				return "UNKNOWN", tostring(reason or status), {
					Quest = name,
					Status = status,
				}
			end
		end
		return nil, nil, nil
	end

	local function resolverPosition(value)
		local instance = type(value) == "table" and value.Instance or value
		if not instance then
			return nil
		end
		if GB and GB.Resolver and type(GB.Resolver.positionOf) == "function" then
			local ok, position = pcall(GB.Resolver.positionOf, instance)
			if ok then
				return position
			end
		end
		return nil
	end

	local function positionDistance(origin, target)
		if origin == nil or target == nil then
			return math.huge
		end
		if GB and GB.World and type(GB.World.planarDist) == "function" then
			local ok, distance = pcall(GB.World.planarDist, origin, target)
			if ok and type(distance) == "number" then
				return distance
			end
		end
		local ok, distance = pcall(function()
			return (origin - target).Magnitude
		end)
		if ok and type(distance) == "number" then
			return distance
		end
		return math.huge
	end

	local function enemyAlive(instance)
		if not instance then
			return false
		end
		if GB and GB.Combat and type(GB.Combat.IsEnemyAlive) == "function" then
			local ok, value = pcall(GB.Combat.IsEnemyAlive, instance)
			return ok and value == true
		end
		local ok, value = pcall(function()
			local humanoid = instance:FindFirstChildOfClass("Humanoid")
			return instance.Parent ~= nil and humanoid ~= nil and humanoid.Health > 0
		end)
		return ok and value == true
	end

	local function enemiesFor(name, allowFindTarget, plan)
		local out = {}
		local seen = {}
		if GB and GB.Resolver and type(GB.Resolver.enemies) == "function" then
			local ok, values = pcall(GB.Resolver.enemies, name)
			if ok and type(values) == "table" then
				for _, instance in ipairs(values) do
					if not seen[instance] and enemyAlive(instance) then
						seen[instance] = true
						out[#out + 1] = instance
					end
				end
			end
		end
		if #out == 0 and allowFindTarget and GB and GB.Combat and type(GB.Combat.findTarget) == "function" then
			local targetPlan = type(plan) == "table" and copyTable(plan) or {}
			targetPlan.SkipStream = true
			local ok, instance = pcall(GB.Combat.findTarget, name, nil, targetPlan)
			if ok and instance and enemyAlive(instance) then
				out[1] = instance
			end
		end
		return out
	end

	local function resolveNpc(name, island)
		if not (name and GB and GB.Resolver and type(GB.Resolver.resolveNPC) == "function") then
			return nil
		end
		local ok, value = pcall(GB.Resolver.resolveNPC, name, {
			DisplayName = name,
			Island = island,
			ExpectedRole = "npc",
			deep = false,
		})
		if ok then
			return value
		end
		return nil
	end

	local function resolveMarker(name, island)
		if not (name and GB and GB.Resolver and type(GB.Resolver.resolveMarker) == "function") then
			return nil
		end
		local ok, value = pcall(GB.Resolver.resolveMarker, name, {
			Island = island,
			ExpectedRole = "marker",
			deep = false,
		})
		if ok then
			return value
		end
		return nil
	end

	local COMBAT_OBJECTIVE = {
		Kill = true,
		Defeat = true,
		Hit = true,
		Shoot = true,
		Destroy = true,
	}

	local function questEndpoint(name, state, snapshot)
		state = state or readQuestState(name)
		snapshot = snapshot or safeState(false)
		local origin = snapshot.Position
		local objective = state and state.Objective
		if objective and COMBAT_OBJECTIVE[objective.Type] and objective.TargetName then
			local enemies = enemiesFor(objective.TargetName, false)
			if enemies[1] then
				local position = resolverPosition(enemies[1])
				return enemies[1], positionDistance(origin, position), true, "target"
			end
			if objective.Type == "Destroy"
				and GB and GB.Resolver and type(GB.Resolver.resolveObject) == "function"
			then
				local ok, object = pcall(GB.Resolver.resolveObject, objective.TargetName, {
					Island = state and state.Island,
					deep = false,
				})
				if ok and object then
					local position = resolverPosition(object)
					return object, positionDistance(origin, position), true, "target"
				end
			end
		end
		if objective and (objective.Type == "Talk" or objective.Type == "Automatic Talk") and objective.TargetName then
			local npc = resolveNpc(objective.TargetName, state and state.Island)
			if npc then
				return npc, positionDistance(origin, resolverPosition(npc)), true, "npc"
			end
		end
		if objective and GB and GB.QuestData and type(GB.QuestData.combatMarker) == "function" then
			local ok, markerName = pcall(
				GB.QuestData.combatMarker,
				name,
				state and state.StageIndex,
				objective.Type,
				objective.TargetName
			)
			if ok and markerName then
				local marker = resolveMarker(markerName, state and state.Island)
				if marker then
					return marker, positionDistance(origin, resolverPosition(marker)), true, "marker"
				end
			end
		end
		local row = questRow(name) or {}
		local npcName
		if state and state.IsAccepted and (state.CanTurnIn or not state.Objective) then
			npcName = row.TurnInNPC or state.NPC
		else
			npcName = row.AcceptNPC or (state and state.NPC)
		end
		if npcName then
			local npc = resolveNpc(npcName, row.Island or (state and state.Island))
			if npc then
				return npc, positionDistance(origin, resolverPosition(npc)), true, "npc"
			end
		end
		return nil, math.huge, false, "unavailable"
	end

	local function repeatList()
		local list = copyList(M.selectedRepeatables)
		if M.selectedQuest and isRepeatable(M.selectedQuest) and not contains(list, M.selectedQuest) then
			list[#list + 1] = M.selectedQuest
		end
		return list
	end

	local function levelSuitability(row, level)
		local minimum = math.max(tonumber(row.AcceptLevel) or 0, tonumber(row.NeedLevel) or 0)
		local low = tonumber(row.RangeMin) or minimum
		local high = tonumber(row.RangeMax) or tonumber(row.full_until) or low
		if level < minimum then
			return -12000
		end
		if level >= low and level <= high then
			return 1400
		end
		if level < low then
			return 700 - ((low - level) * 120)
		end
		return 500 - ((level - high) * 65)
	end

	local function repeatBestScore(name, index, snapshot)
		local row = questRow(name) or {}
		local state = readQuestState(name)
		local score = levelSuitability(row, tonumber(snapshot.Level) or 0)
		local exp = tonumber(row.Exp or row.exp) or 0
		local gold = tonumber(row.Gold or row.gold) or 0
		score = score + (math.log(exp + 1) * 180) + (math.log(gold + 1) * 30)
		if state and state.IsAccepted then
			score = score + 2200
			local objective = state.Objective
			if objective then
				local current = tonumber(objective.Current) or 0
				local total = math.max(tonumber(objective.Amount) or 1, 1)
				local remaining = math.max(total - current, 0)
				score = score + ((current / total) * 700) - (remaining * 12)
			elseif state.CanTurnIn then
				score = score + 1200
			end
		end
		local _, distance, available = questEndpoint(name, state, snapshot)
		if available then
			score = score + 360 - math.min(distance, 1200) * 0.35
		else
			score = score - 280
		end
		local blocker = M.describeBlocker(name)
		if blocker and not (state and state.IsAccepted) then
			score = score - 15000
		end
		return score, index, distance
	end

	local function selectRankedRepeat(list, snapshot, nearestOnly)
		local rows = {}
		for index, name in ipairs(list) do
			local state = readQuestState(name)
			local _, distance, available = questEndpoint(name, state, snapshot)
			local score = nearestOnly and (available and -distance or -math.huge)
				or select(1, repeatBestScore(name, index, snapshot))
			rows[#rows + 1] = {
				name = name,
				index = index,
				score = score,
				distance = distance,
				available = available,
			}
		end
		table.sort(rows, function(a, b)
			if a.score ~= b.score then
				return a.score > b.score
			end
			if a.distance ~= b.distance then
				return a.distance < b.distance
			end
			if a.name ~= b.name then
				return a.name < b.name
			end
			return a.index < b.index
		end)
		return rows[1] and rows[1].name or nil
	end

	local function chooseRepeat(snapshot)
		local list = repeatList()
		if #list == 0 then
			return nil
		end
		if M._repeatActive and contains(list, M._repeatActive) then
			local activeState = readQuestState(M._repeatActive)
			if activeState and activeState.IsAccepted then
				M._repeatHadLive = true
				return M._repeatActive
			end
			if M._repeatHadLive then
				local completed = M._repeatActive
				M._repeatHadLive = false
				M._repeatCycles = M._repeatCycles + 1
				if M.repeatMode == "ROTATE" then
					local _, index = contains(list, completed)
					M._repeatCursor = ((index or M._repeatCursor or 1) % #list) + 1
				end
				M._repeatActive = nil
			else
				return M._repeatActive
			end
		else
			M._repeatActive = nil
			M._repeatHadLive = false
		end

		for _, name in ipairs(list) do
			local state = readQuestState(name)
			if state and state.IsAccepted then
				M._repeatActive = name
				M._repeatHadLive = true
				return name
			end
		end

		local selected
		if M.repeatMode == "ONE" then
			selected = M.selectedQuest and contains(list, M.selectedQuest) and M.selectedQuest or list[1]
		elseif M.repeatMode == "ROTATE" then
			if M._repeatCursor < 1 or M._repeatCursor > #list then
				M._repeatCursor = 1
			end
			selected = list[M._repeatCursor]
		elseif M.repeatMode == "NEAREST" then
			selected = selectRankedRepeat(list, snapshot, true)
		else
			selected = selectRankedRepeat(list, snapshot, false)
		end
		M._repeatActive = selected
		return selected
	end

	local function questProgress(name, state, result)
		local objective = state and state.Objective
		return {
			kind = "QUEST",
			quest = name,
			target = objective and objective.TargetName or name,
			stage = state and state.StageIndex,
			objective = objective and objective.Type,
			current = objective and objective.Current,
			total = objective and objective.Amount,
			reason = result and result.reason,
			cycles = M._repeatCycles,
		}
	end

	local function runManualQuest(snapshot)
		local targetLevel = tonumber(M.farmUntilLevel)
		if targetLevel and (tonumber(snapshot.Level) or 0) >= targetLevel then
			local reason = string.format("Reached level %d", targetLevel)
			if M.resumeFullAuto then
				completeOwnerWork(OWNER.FULL_AUTO, reason)
			else
				completeOwnerWork(OWNER.IDLE, reason, "LEVEL_REACHED", reason, {
					kind = "LEVEL",
					current = tonumber(snapshot.Level) or 0,
					total = targetLevel,
				})
			end
			return true
		end

		local name
		local repeating = false
		if M.selectedQuest and not isRepeatable(M.selectedQuest) then
			name = M.selectedQuest
		else
			name = chooseRepeat(snapshot)
			repeating = name ~= nil
			if not name then
				name = M.selectedQuest
				repeating = name and isRepeatable(name) or false
			end
		end
		if not name then
			setStatus("WAIT_SELECTION", "Select a quest", {
				kind = "QUEST",
			})
			return false
		end
		if not (GB and GB.Quest and type(GB.Quest.doLiveResult) == "function") then
			setError("quest_api", "Quest.doLiveResult unavailable")
			return false
		end

		local before = readQuestState(name)
		if before and not before.IsAccepted then
			local blocker, reason = M.describeBlocker(name)
			if blocker and blocker ~= "ITEM" then
				setStatus("QUEST_BLOCKED", reason, {
					kind = "QUEST",
					quest = name,
					target = name,
					reason = blocker,
				})
				rateLog("WARN", "quest_blocked:" .. name .. ":" .. blocker, name .. " blocked: " .. tostring(reason), 8)
				return false
			end
		end
		if not repeating and before and not before.IsAccepted
			and (before.IsComplete or playerFinished(name))
		then
			completeOwnerWork(OWNER.IDLE, "quest_complete", "QUEST_COMPLETE", name, questProgress(name, before, {
				reason = "complete",
			}))
			return true
		end

		local generation = M._generation
		local ok, result = pcall(GB.Quest.doLiveResult, name)
		if generation ~= M._generation then
			return true
		end
		if not ok then
			setError("quest:" .. name, "manual quest failed: " .. tostring(result))
			return false
		end
		if type(result) ~= "table" then
			result = {
				attempted = true,
				progressed = result == true,
				reason = result and "progress" or "pending",
			}
		end
		local after = readQuestState(name) or before
		if repeating then
			if after and after.IsAccepted then
				M._repeatActive = name
				M._repeatHadLive = true
			end
		elseif (after and after.IsComplete)
			or result.reason == "complete"
			or result.reason == "already_complete"
			or (after and not after.IsAccepted and playerFinished(name))
		then
			clearError()
			completeOwnerWork(
				OWNER.IDLE,
				"quest_complete",
				"QUEST_COMPLETE",
				name,
				questProgress(name, after, result)
			)
			return true
		end

		if result.reason == "doLive_error" then
			setError("quest:" .. name, "Quest.doLiveResult failed for " .. name)
			return false
		end
		clearError()
		setStatus(result.progressed and "QUEST_PROGRESS" or "QUEST_PENDING", name, questProgress(name, after, result))
		return result.attempted ~= false
	end

	local function targetMatches(instance, names)
		if not instance then
			return nil
		end
		for _, name in ipairs(names or {}) do
			if GB and GB.Resolver and type(GB.Resolver.nameMatches) == "function" then
				local aliases = { name }
				if type(GB.Resolver.namesFor) == "function" then
					local ok, values = pcall(GB.Resolver.namesFor, name, {})
					if ok and type(values) == "table" then
						aliases = values
					end
				end
				local ok, hit = pcall(GB.Resolver.nameMatches, instance, aliases)
				if ok and hit == true then
					return name
				end
			else
				local ok, hit = pcall(function()
					return instance.Name == name
				end)
				if ok and hit then
					return name
				end
			end
		end
		return nil
	end

	local function nearestInstanceFor(name, snapshot, allowFindTarget, plan)
		local list = enemiesFor(name, allowFindTarget, plan)
		local best
		local bestDistance
		for _, instance in ipairs(list) do
			local distance = positionDistance(snapshot.Position, resolverPosition(instance))
			if bestDistance == nil or distance < bestDistance then
				best = instance
				bestDistance = distance
			end
		end
		return best, bestDistance or math.huge
	end

	local function engageTarget(name, instance, plan)
		if not (name and instance and enemyAlive(instance)) then
			return false
		end
		plan = type(plan) == "table" and copyTable(plan) or {}
		plan.Target = name
		plan.Instance = instance
		plan.SkipStream = true
		if GB and GB.Combat and type(GB.Combat.hunt) == "function" then
			local ok, value = pcall(GB.Combat.hunt, name, nil, plan)
			return ok and value == true
		end
		if GB and GB.Combat and type(GB.Combat.startLock) == "function" then
			local ok = pcall(GB.Combat.startLock, instance, nil)
			return ok
		end
		return false
	end

	local function releaseMobTarget()
		local releasedName = M._mobActiveName or M._pendingMobName
		if M.mobMode == "ROUND_ROBIN" and #M.selectedMobs > 0 and releasedName then
			local _, index = contains(M.selectedMobs, releasedName)
			M._mobCursor = ((index or M._mobCursor or 1) % #M.selectedMobs) + 1
		elseif M.mobMode == "FINISH_GROUP" and releasedName then
			local remaining = enemiesFor(releasedName, false)
			if #remaining == 0 then
				local _, index = contains(M.selectedMobs, releasedName)
				M._mobCursor = ((index or M._mobCursor or 1) % math.max(#M.selectedMobs, 1)) + 1
				M._finishGroupName = nil
			else
				M._finishGroupName = releasedName
			end
		end
		M._mobActiveName = nil
		M._mobActiveInstance = nil
		M._mobLockedAt = nil
		M._pendingMob = nil
		M._pendingMobName = nil
	end

	local function chooseMob(snapshot)
		local names = M.selectedMobs
		if M._pendingMob and enemyAlive(M._pendingMob) and contains(names, M._pendingMobName) then
			return M._pendingMobName, M._pendingMob
		end
		M._pendingMob = nil
		M._pendingMobName = nil

		if M.mobMode == "PRIORITY" then
			for _, name in ipairs(names) do
				local instance = nearestInstanceFor(name, snapshot, true)
				if instance then
					return name, instance
				end
			end
			return nil, nil
		end

		if M.mobMode == "ROUND_ROBIN" then
			if M._mobCursor < 1 or M._mobCursor > #names then
				M._mobCursor = 1
			end
			for offset = 0, #names - 1 do
				local index = ((M._mobCursor - 1 + offset) % #names) + 1
				local name = names[index]
				local instance = nearestInstanceFor(name, snapshot, true)
				if instance then
					M._mobCursor = index
					return name, instance
				end
			end
			return nil, nil
		end

		if M.mobMode == "FINISH_GROUP" then
			if M._finishGroupName and contains(names, M._finishGroupName) then
				local instance = nearestInstanceFor(M._finishGroupName, snapshot, true)
				if instance then
					return M._finishGroupName, instance
				end
				M._finishGroupName = nil
			end
			if M._mobCursor < 1 or M._mobCursor > #names then
				M._mobCursor = 1
			end
			for offset = 0, #names - 1 do
				local index = ((M._mobCursor - 1 + offset) % #names) + 1
				local name = names[index]
				local instance = nearestInstanceFor(name, snapshot, true)
				if instance then
					M._mobCursor = index
					M._finishGroupName = name
					return name, instance
				end
			end
			return nil, nil
		end

		local bestName
		local bestInstance
		local bestDistance
		local bestIndex
		for index, name in ipairs(names) do
			local instance, distance = nearestInstanceFor(name, snapshot, true)
			if instance and (bestDistance == nil
				or distance < bestDistance
				or (distance == bestDistance and index < bestIndex))
			then
				bestName = name
				bestInstance = instance
				bestDistance = distance
				bestIndex = index
			end
		end
		return bestName, bestInstance
	end

	local function runManualMob(snapshot)
		if #M.selectedMobs == 0 then
			cancelRuntime()
			setStatus("WAIT_SELECTION", "Select at least one mob", {
				kind = "MOB",
			})
			return false
		end
		local combat = GB and GB.Combat
		if type(combat) ~= "table" then
			setError("combat_api", "Combat unavailable")
			return false
		end

		local lock = combat.lockMob
		if lock then
			if not enemyAlive(lock) then
				if type(combat.stopLock) == "function" then
					pcall(combat.stopLock)
				end
				releaseMobTarget()
			else
				local selectedName = targetMatches(lock, M.selectedMobs)
				if selectedName then
					M._mobActiveName = selectedName
					M._mobActiveInstance = lock
					M._mobLockedAt = M._mobLockedAt or now()
					M._pendingMob = nil
					M._pendingMobName = nil
					local shouldSwitch = false
					if now() - M._mobLockedAt >= M.targetStickiness then
						local currentDistance = positionDistance(snapshot.Position, resolverPosition(lock))
						if currentDistance > M.targetSwitchDistance then
							for _, candidateName in ipairs(M.selectedMobs) do
								local candidate, distance = nearestInstanceFor(candidateName, snapshot, false)
								if candidate and candidate ~= lock and distance + 8 < currentDistance then
									shouldSwitch = true
									break
								end
							end
						end
					end
					if shouldSwitch then
						if type(combat.stopLock) == "function" then
							pcall(combat.stopLock)
						end
						releaseMobTarget()
					else
						clearError()
						setStatus("MOB_FIGHTING", selectedName, {
							kind = "MOB",
							target = selectedName,
							mode = M.mobMode,
						})
						return true
					end
				end
				if type(combat.stopLock) == "function" then
					pcall(combat.stopLock)
				end
				releaseMobTarget()
			end
		elseif M._mobActiveInstance and not enemyAlive(M._mobActiveInstance) then
			releaseMobTarget()
		end

		local name, instance = chooseMob(snapshot)
		if not (name and instance) then
			setStatus("MOB_WAITING", "No selected mob is alive", {
				kind = "MOB",
				mode = M.mobMode,
			})
			rateLog("WARN", "mob_missing:" .. table.concat(M.selectedMobs, "|"), "no selected mob is alive", 8)
			return false
		end
		M._pendingMobName = name
		M._pendingMob = instance
		local engaged = engageTarget(name, instance, {
			Manual = true,
		})
		if combat.lockMob and enemyAlive(combat.lockMob) then
			M._mobActiveName = name
			M._mobActiveInstance = combat.lockMob
			M._mobLockedAt = now()
			M._pendingMob = nil
			M._pendingMobName = nil
		end
		clearError()
		setStatus(engaged and "MOB_FIGHTING" or "MOB_APPROACHING", name, {
			kind = "MOB",
			target = name,
			mode = M.mobMode,
		})
		return engaged
	end

	local function sortedKeys(source)
		local keys = {}
		for key in pairs(source or {}) do
			keys[#keys + 1] = key
		end
		table.sort(keys, function(a, b)
			return tostring(a) < tostring(b)
		end)
		return keys
	end

	local function stageFields(stage)
		return {
			quest = stage.Q or stage.quest,
			index = tonumber(stage.S or stage.stage) or 0,
			objective = stage.T or stage.objective,
			target = stage.A or stage.target,
			amount = tonumber(stage.N or stage.amount) or 0,
			method = stage.M or stage.acquire,
			source = stage.Src or stage.source,
			island = stage.Loc or stage.location or stage.island,
			marker = stage.Mk or stage.marker,
			status = stage.St or stage.status,
		}
	end

	local function markerVerified(fields)
		if type(fields.marker) ~= "string" or trim(fields.marker) == nil then
			return false
		end
		local status = string.upper(tostring(fields.status or ""))
		return status ~= ""
			and status ~= "UNRESOLVED"
			and status ~= "DISABLED"
	end

	local function bossStageCandidate(selected, target)
		local candidates = {}
		local function collect(stages, sourceRank)
			for _, key in ipairs(sortedKeys(stages)) do
				local raw = stages[key]
				if type(raw) == "table" then
					local fields = stageFields(raw)
					local combatStage = fields.objective == "Kill"
						or fields.objective == "Defeat"
						or fields.method == "BossDrop"
					local stageTarget = fields.method == "BossDrop" and fields.source or fields.target
					local questMatch = fields.quest == selected
					local targetMatch = stageTarget == selected or stageTarget == target
					if combatStage and stageTarget and (questMatch or targetMatch) then
						local score = sourceRank
						if questMatch then
							score = score + 300
						end
						if targetMatch then
							score = score + 400
						end
						if fields.method == "BossDrop" then
							score = score + 180
						end
						if fields.amount == 1 then
							score = score + 90
						end
						if markerVerified(fields) then
							score = score + 50
						end
						candidates[#candidates + 1] = {
							fields = fields,
							target = stageTarget,
							score = score,
							key = tostring(key),
						}
					end
				end
			end
		end
		local generated = GB and GB.GeneratedData
		collect(generated and generated.Stages, 200)
		collect(GB and GB.QuestSpecs and GB.QuestSpecs.STAGES, 100)
		table.sort(candidates, function(a, b)
			if a.score ~= b.score then
				return a.score > b.score
			end
			if a.fields.index ~= b.fields.index then
				return a.fields.index < b.fields.index
			end
			return a.key < b.key
		end)
		return candidates[1]
	end

	local function deriveBoss(selected)
		local target = KNOWN_BOSS[selected] or selected
		local state = readQuestState(selected)
		if state and state.Objective
			and (state.Objective.Type == "Kill" or state.Objective.Type == "Defeat")
			and state.Objective.TargetName
		then
			target = state.Objective.TargetName
		end
		local candidate = bossStageCandidate(selected, target)
		if candidate then
			target = KNOWN_BOSS[selected] or candidate.target or target
		end
		local fields = candidate and candidate.fields or {}
		local row = questRow(selected) or {}
		return {
			selected = selected,
			target = target,
			quest = fields.quest or (row.Name and selected or nil),
			marker = markerVerified(fields) and fields.marker or nil,
			island = fields.island or row.Island,
			stage = fields.index,
		}
	end

	local function bossDescriptors()
		local signature = table.concat(M.selectedBosses, "\0")
		if M._bossDescriptors and M._bossDescriptorSignature == signature then
			return M._bossDescriptors
		end
		local out = {}
		for _, selected in ipairs(M.selectedBosses) do
			out[#out + 1] = deriveBoss(selected)
		end
		M._bossDescriptors = out
		M._bossDescriptorSignature = signature
		return out
	end

	local function bossTargets(descriptors)
		local out = {}
		for _, descriptor in ipairs(descriptors) do
			out[#out + 1] = descriptor.target
		end
		return out
	end

	local function chooseBoss(snapshot, descriptors)
		if M._pendingBoss and enemyAlive(M._pendingBoss) and contains(bossTargets(descriptors), M._pendingBossName) then
			for _, descriptor in ipairs(descriptors) do
				if descriptor.target == M._pendingBossName then
					return descriptor, M._pendingBoss
				end
			end
		end
		M._pendingBoss = nil
		M._pendingBossName = nil
		local bestDescriptor
		local bestInstance
		local bestDistance
		local bestIndex
		for index, descriptor in ipairs(descriptors) do
			local instance, distance = nearestInstanceFor(descriptor.target, snapshot, true, {
				Marker = descriptor.marker,
				Island = descriptor.island,
			})
			if instance and (bestDistance == nil
				or distance < bestDistance
				or (distance == bestDistance and index < bestIndex))
			then
				bestDescriptor = descriptor
				bestInstance = instance
				bestDistance = distance
				bestIndex = index
			end
		end
		return bestDescriptor, bestInstance
	end

	local function waitAtBossMarker(snapshot, descriptors)
		if #descriptors == 0 then
			return false
		end
		local descriptor
		if M._waitBossTarget then
			for _, candidate in ipairs(descriptors) do
				if candidate.target == M._waitBossTarget then
					descriptor = candidate
					break
				end
			end
		end
		if not descriptor then
			for _, candidate in ipairs(descriptors) do
				if candidate.marker and candidate.island == snapshot.PhysicalIsland then
					descriptor = candidate
					break
				end
			end
		end
		if not descriptor then
			for _, candidate in ipairs(descriptors) do
				if candidate.marker then
					descriptor = candidate
					break
				end
			end
		end
		descriptor = descriptor or descriptors[1]
		M._waitBossTarget = descriptor.target
		if descriptor.island and snapshot.PhysicalIsland ~= descriptor.island
			and GB and GB.Travel and type(GB.Travel.goIsland) == "function"
		then
			pcall(GB.Travel.goIsland, descriptor.island)
			setStatus("BOSS_TRAVEL", descriptor.target, {
				kind = "BOSS",
				boss = descriptor.target,
				target = descriptor.island,
				reason = "verified island",
			})
			return true
		end
		if not descriptor.marker then
			setStatus("BOSS_WAITING", "No verified marker for " .. descriptor.target, {
				kind = "BOSS",
				boss = descriptor.target,
				reason = "marker unavailable",
			})
			return false
		end
		local marker = resolveMarker(descriptor.marker, descriptor.island)
			or resolveNpc(descriptor.marker, descriptor.island)
		local instance = type(marker) == "table" and marker.Instance or marker
		if not instance then
			setStatus("BOSS_WAITING", "Verified marker unavailable: " .. descriptor.marker, {
				kind = "BOSS",
				boss = descriptor.target,
				target = descriptor.marker,
				reason = "marker not loaded",
			})
			return false
		end
		if GB and GB.World and type(GB.World.moveTo) == "function" then
			pcall(GB.World.moveTo, instance, 10)
			setStatus("BOSS_WAITING", descriptor.target, {
				kind = "BOSS",
				boss = descriptor.target,
				target = descriptor.marker,
				reason = "waiting at verified marker",
			})
			return true
		end
		return false
	end

	local function confirmedBossDeath(instance)
		if not instance then
			return false
		end
		local combat = GB and GB.Combat
		if type(combat) ~= "table" then
			return false
		end
		if type(combat.hasDeadFlag) == "function" then
			local ok, dead = pcall(combat.hasDeadFlag, instance)
			if ok and dead == true then
				return true
			end
		end
		if type(combat.isRecentlyDead) == "function" then
			local ok, dead = pcall(combat.isRecentlyDead, instance)
			if ok and dead == true then
				return true
			end
		end
		if type(combat.readHealth) == "function" then
			local ok, health = pcall(combat.readHealth, instance)
			if ok and type(health) == "number" and health <= 0 then
				return true
			end
		end
		return false
	end

	local function runManualBoss(snapshot)
		if #M.selectedBosses == 0 then
			cancelRuntime()
			setStatus("WAIT_SELECTION", "Select at least one boss", {
				kind = "BOSS",
			})
			return false
		end
		local descriptors = bossDescriptors()
		local targets = bossTargets(descriptors)
		local combat = GB and GB.Combat
		if type(combat) ~= "table" then
			setError("combat_api", "Combat unavailable")
			return false
		end
		local function clearBossTarget()
			M._bossActiveInstance = nil
			M._bossActiveName = nil
			M._pendingBoss = nil
			M._pendingBossName = nil
		end
		local function recordBossKill(name)
			local count = M._bossKills + 1
			M._bossKills = count
			clearBossTarget()
			if M.bossKillLimit and count >= M.bossKillLimit then
				local limit = M.bossKillLimit
				completeOwnerWork(
					OWNER.IDLE,
					"boss_kill_limit",
					"BOSS_LIMIT_REACHED",
					tostring(name or "Boss"),
					{
						kind = "BOSS",
						boss = name,
						target = name,
						current = count,
						total = limit,
					}
				)
				return true
			end
			return false
		end
		local lock = combat.lockMob
		if not lock and M._bossActiveInstance and not enemyAlive(M._bossActiveInstance) then
			local activeName = M._bossActiveName
			if activeName and confirmedBossDeath(M._bossActiveInstance) then
				if recordBossKill(activeName) then
					return true
				end
			else
				clearBossTarget()
			end
		end
		if lock then
			if not enemyAlive(lock) then
				local defeatedName = targetMatches(lock, targets) or M._bossActiveName
				local confirmed = confirmedBossDeath(lock)
				if type(combat.stopLock) == "function" then
					pcall(combat.stopLock)
				end
				if confirmed and defeatedName and recordBossKill(defeatedName) then
					return true
				end
				if not confirmed or not defeatedName then
					clearBossTarget()
				end
			else
				local name = targetMatches(lock, targets)
				if name then
					M._bossActiveInstance = lock
					M._bossActiveName = name
					clearError()
					setStatus("BOSS_FIGHTING", name, {
						kind = "BOSS",
						boss = name,
						target = name,
					})
					return true
				end
				if type(combat.stopLock) == "function" then
					pcall(combat.stopLock)
				end
				clearBossTarget()
			end
		end

		local descriptor, instance = chooseBoss(snapshot, descriptors)
		if descriptor and instance then
			M._waitBossTarget = nil
			M._pendingBoss = instance
			M._pendingBossName = descriptor.target
			local engaged = engageTarget(descriptor.target, instance, {
				Manual = true,
				Marker = descriptor.marker,
				Island = descriptor.island,
				Quest = descriptor.quest,
			})
			if combat.lockMob and enemyAlive(combat.lockMob) then
				M._bossActiveInstance = combat.lockMob
				M._bossActiveName = descriptor.target
				M._pendingBoss = nil
				M._pendingBossName = nil
			end
			clearError()
			setStatus(engaged and "BOSS_FIGHTING" or "BOSS_APPROACHING", descriptor.target, {
				kind = "BOSS",
				boss = descriptor.target,
				target = descriptor.target,
			})
			return engaged
		end
		if M.waitBoss then
			return waitAtBossMarker(snapshot, descriptors)
		end
		setStatus("BOSS_UNAVAILABLE", "No selected boss is alive", {
			kind = "BOSS",
			reason = "no live target",
		})
		rateLog("WARN", "boss_missing:" .. table.concat(M.selectedBosses, "|"), "no selected boss is alive", 10)
		return false
	end

	local function chestIsland(chest)
		local position = resolverPosition(chest)
		if not position then
			return nil
		end
		if GB and GB.World and type(GB.World.GetIslandFromPosition) == "function" then
			local ok, island = pcall(GB.World.GetIslandFromPosition, position)
			if ok and PHYSICAL_MAP[island] then
				return island
			end
		end
		return nil
	end

	local function chestAvailable(chest, map)
		if not chest then
			return false
		end
		local ok, valid = pcall(function()
			return chest.Parent ~= nil and chest:GetAttribute("Opened") ~= true
		end)
		if not ok or not valid then
			return false
		end
		if chestIsland(chest) ~= map then
			return false
		end
		return resolverPosition(chest) ~= nil
	end

	local function nearestChest(snapshot, map)
		if not (GB and GB.Resolver and type(GB.Resolver.chests) == "function") then
			return nil
		end
		local ok, values = pcall(GB.Resolver.chests)
		if not ok or type(values) ~= "table" then
			return nil
		end
		local rows = {}
		for index, chest in ipairs(values) do
			if chestAvailable(chest, map) then
				local label = tostring(index)
				pcall(function()
					label = chest:GetFullName()
				end)
				rows[#rows + 1] = {
					instance = chest,
					distance = positionDistance(snapshot.Position, resolverPosition(chest)),
					label = label,
					index = index,
				}
			end
		end
		table.sort(rows, function(a, b)
			if a.distance ~= b.distance then
				return a.distance < b.distance
			end
			if a.label ~= b.label then
				return a.label < b.label
			end
			return a.index < b.index
		end)
		return rows[1] and rows[1].instance or nil
	end

	local function runManualChest(snapshot)
		local map = M.chestMap
		if map == nil or map == "CURRENT" then
			map = snapshot.PhysicalIsland
			if not PHYSICAL_MAP[map] then
				setStatus("CHEST_MAP_UNKNOWN", "Current physical map is unresolved", {
					kind = "CHEST",
					reason = "unverified current map",
				})
				return false
			end
		elseif not PHYSICAL_MAP[map] then
			setError("chest_map", "Unverified chest map " .. tostring(map))
			return false
		end

		if snapshot.PhysicalIsland ~= map then
			if GB and GB.Travel and type(GB.Travel.goIsland) == "function" then
				pcall(GB.Travel.goIsland, map)
				setStatus("CHEST_TRAVEL", map, {
					kind = "CHEST",
					target = map,
				})
				return true
			end
			setStatus("CHEST_MAP_UNAVAILABLE", map, {
				kind = "CHEST",
				target = map,
			})
			return false
		end

		if M._chestTarget then
			local opened = false
			pcall(function()
				opened = M._chestTarget:GetAttribute("Opened") == true
			end)
			if opened then
				M._chestOpened = M._chestOpened + 1
				M._chestTarget = nil
			elseif not chestAvailable(M._chestTarget, map) then
				M._chestTarget = nil
			end
		end
		local chest = M._chestTarget or nearestChest(snapshot, map)
		if not chest then
			local loop = M.chestAutoLoop == true or M.autoLoop == true
			if loop then
				setStatus("CHEST_WAITING", "No unopened chest on " .. map, {
					kind = "CHEST",
					target = map,
					current = M._chestOpened,
					reason = "auto loop",
				})
			else
				completeOwnerWork(OWNER.IDLE, "chests_exhausted", "CHESTS_EXHAUSTED", map, {
					kind = "CHEST",
					target = map,
					current = M._chestOpened,
				})
			end
			return false
		end
		M._chestTarget = chest
		local position = resolverPosition(chest)
		local distance = positionDistance(snapshot.Position, position)
		local label = "Chest"
		pcall(function()
			label = chest.Name
		end)
		if distance > 72 and GB and GB.World and type(GB.World.moveTo) == "function" then
			pcall(GB.World.moveTo, chest, 8)
			setStatus("CHEST_APPROACHING", label, {
				kind = "CHEST",
				chest = label,
				target = map,
				current = M._chestOpened,
			})
			return true
		end
		if not (GB and GB.Chest and type(GB.Chest.openOne) == "function") then
			setError("chest_api", "Chest.openOne unavailable")
			return false
		end
		local ok, opened = pcall(GB.Chest.openOne, chest)
		if not ok then
			setError("chest_open", "Chest.openOne failed: " .. tostring(opened))
			return false
		end
		clearError()
		setStatus(opened and "CHEST_OPENING" or "CHEST_PENDING", label, {
			kind = "CHEST",
			chest = label,
			target = map,
			current = M._chestOpened,
		})
		return opened == true
	end

	local function holdForRespawn()
		if not (GB and GB.Respawn) then
			return false
		end
		if type(GB.Respawn.Detect) == "function" then
			pcall(GB.Respawn.Detect)
		end
		local busy = false
		if type(GB.Respawn.isBusy) == "function" then
			local ok, value = pcall(GB.Respawn.isBusy)
			busy = ok and value == true
		end
		if not busy then
			if M._respawnHeld then
				M._respawnHeld = false
				clearTransient("respawn_complete")
				markContextDirty("ui_respawn_complete")
				setStatus("RESUMING", M.owner, {
					kind = "RESPAWN",
					target = M.owner,
				}, true)
			end
			return false
		end
		if not M._respawnHeld then
			M._respawnHeld = true
			M._generation = M._generation + 1
			cancelActiveWork("respawn")
			clearQueue("respawn")
			clearTransient("respawn")
		end
		local phase = type(GB.Respawn.currentPhase) == "function" and GB.Respawn.currentPhase() or "busy"
		setStatus("WAIT_RESPAWN", phase, {
			kind = "RESPAWN",
			target = phase,
		})
		return true
	end

	local function runUtilities()
		if M.owner == OWNER.FULL_AUTO then
			return
		end
		if GB.Config.AutoStats and GB.Stats and type(GB.Stats.tick) == "function" then
			GB.Stats.tick()
		end
		if (GB.Config.AutoCodes or (GB.Codes and (GB.Codes.running or GB.Codes.pendingCode)))
			and GB.Codes
			and type(GB.Codes.tick) == "function"
		then
			GB.Codes.tick()
		end
		if GB.Config.AutoEquip
			and (M.owner == OWNER.IDLE or M.owner == OWNER.MANUAL_QUEST)
			and GB.Equipment
			and type(GB.Equipment.tick) == "function"
		then
			GB.Equipment.tick()
		end
	end

	local function runTick()
		if GB and type(GB.dead) == "function" then
			local ok, dead = pcall(GB.dead)
			if ok and dead then
				return false, "runtime dead"
			end
		end
		if holdForRespawn() then
			return false, "respawn"
		end
		if M.paused then
			setStatus("PAUSED", M.owner, {
				kind = "OWNER",
				target = M.owner,
			})
			return false, "paused"
		end
		if M._work then
			return false, "work pending"
		end
		local action = takeQueuedAction()
		if action then
			if action.opts.cancelActive ~= false then
				cancelRuntime()
			end
			setStatus("ACTION", action.label, {
				kind = "ACTION",
				target = action.label,
			})
			local dispatched, detail = dispatchWork(
				"ACTION",
				action.label,
				M.owner,
				function()
					return action.fn(GB, M, action.handle)
				end,
				action
			)
			if not dispatched then
				setError("action_spawn", "failed to dispatch " .. action.label .. ": " .. tostring(detail))
			end
			return dispatched, dispatched and "action" or detail
		end
		runUtilities()
		if M.owner == OWNER.IDLE then
			if not TERMINAL_STATUS[M.status] then
				setStatus("IDLE", M.statusReason or "idle", nil)
			end
			return false, "idle"
		end
		if M.owner == OWNER.FULL_AUTO then
			if not (GB and GB.Engine and type(GB.Engine.decide) == "function") then
				setError("engine_api", "Engine.decide unavailable")
				return false, "missing engine"
			end
			GB.Engine.decide()
			clearError()
			setStatus("FULL_AUTO", GB.Engine.task or GB.Engine.idleReason or "running", {
				kind = "FULL_AUTO",
				target = GB.Engine.task,
				reason = GB.Engine.idleReason,
			})
			return true, "full auto"
		end

		local owner = M.owner
		local label
		local step
		if owner == OWNER.MANUAL_QUEST then
			label = "manual quest"
			step = runManualQuest
		elseif owner == OWNER.MANUAL_MOB then
			label = "manual mob"
			step = runManualMob
		elseif owner == OWNER.MANUAL_BOSS then
			label = "manual boss"
			step = runManualBoss
		elseif owner == OWNER.MANUAL_CHEST then
			label = "manual chest"
			step = runManualChest
		end
		if step then
			local dispatched, detail = dispatchWork(owner, label, owner, function()
				local snapshot = safeState(true)
				if snapshot.Alive == false then
					setStatus("WAIT_RESPAWN", "character not ready", {
						kind = "RESPAWN",
						reason = "not alive",
					})
					return false, "not alive"
				end
				return step(snapshot)
			end)
			if not dispatched then
				setError("manual_spawn", "failed to dispatch " .. label .. ": " .. tostring(detail))
			end
			return dispatched, dispatched and label or detail
		end
		return false, "unknown owner"
	end

	function M.tick()
		if M._destroyed then
			return false, "destroyed"
		end
		if M._ticking then
			return false, "reentrant"
		end
		M._ticking = true
		local ok, result, detail = pcall(runTick)
		M._ticking = false
		if not ok then
			setError("tick", "manual controller tick failed: " .. tostring(result))
			return false, result
		end
		return result, detail
	end

	function M.destroy()
		if M._destroyed then
			return true
		end
		M._generation = M._generation + 1
		cancelActiveWork("destroyed")
		clearQueue("destroyed")
		clearTransient("destroyed")
		restoreAutos()
		M.owner = OWNER.IDLE
		M.paused = true
		M._destroyed = true
		changeListeners = {}
		statusListeners = {}
		return true
	end

	function M.getSelectedQuest()
		return M.selectedQuest
	end

	function M.getSelectedRepeatables()
		return copyList(M.selectedRepeatables)
	end

	function M.getRepeatMode()
		return M.repeatMode
	end

	function M.getFarmUntilLevel()
		return M.farmUntilLevel
	end

	function M.getSelectedMobs()
		return copyList(M.selectedMobs)
	end

	function M.getMobMode()
		return M.mobMode
	end

	function M.getSelectedBosses()
		return copyList(M.selectedBosses)
	end

	function M.getChestMap()
		return M.chestMap
	end

	M.get = M.getSnapshot
	M.onChanged = M.onChange
	M.onStatusChanged = M.onStatus
	M.setQuest = M.setSelectedQuest
	M.setRepeatables = M.setSelectedRepeatables
	M.setMobs = M.setSelectedMobs
	M.setBosses = M.setSelectedBosses
	M.setAutoLoop = M.setChestAutoLoop
	M.Destroy = M.destroy
	M.Stop = M.stop
	M.Pause = M.pause
	M.Resume = M.resume
	M.Tick = M.tick

	captureAutos()
	gateAutos()
	return M
end
