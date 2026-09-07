-- Stuck: change strategy. lookup drop → enemy → diagnostic → blocker.
-- Teleport/talk/log is not progress. Void rescue stays on tick.

return function(GB)
	local M = {
		last = 0,
		level = 0,
		reason = nil,
		si = 1,
		deadOnce = {},
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
		M.last = os.clock()
		M.level = M.level + 1
		M.reason = why
		local strat = M.currentStrategy()
		if M.level > 1 then
			strat = M.advanceStrategy()
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

		if strat == "diagnostic" then
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
