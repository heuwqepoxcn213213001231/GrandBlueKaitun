-- Stuck: retry → reacquire → rebuild state → reset move/combat → abandon invalid → safe → restart.
-- Cooldown. No infinite retry.

return function(GB)
	local M = {
		last = 0,
		level = 0,
		reason = nil,
	}

	function M.markSuccess()
		GB.State.track.SuccessfulAction = os.clock()
		M.level = 0
		M.reason = nil
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
		GB.Log.warn("RECOVERY", string.format("level=%d %s", M.level, tostring(why)))
		GB.Cache.invalidate()

		if M.level == 1 then
			if GB.Combat then
				pcall(GB.Combat.stopLock)
			end
			return
		end
		if M.level == 2 then
			GB.State.refresh()
			if GB.Combat then
				pcall(GB.Combat.stopLock)
			end
			if GB.World then
				pcall(GB.World.rescue)
			end
			return
		end
		if M.level == 3 then
			if GB.World then
				pcall(GB.World.goSafe)
			end
			GB.State.track.TaskStartedAt = os.clock()
			return
		end
		-- level 4+: reset task, do not abandon NeverSkip
		local q = GB.State.snap.CurrentQuest
		if q and GB.Config.NeverSkip[q] then
			GB.Log.warn("RECOVERY", "keep " .. q)
		end
		GB.State.track.TaskName = nil
		GB.State.track.TaskStartedAt = os.clock()
		M.level = 0
	end

	function M.tick()
		if M.stuck() then
			M.run("stuck " .. tostring(GB.State.track.TaskName))
		end
		if GB.World then
			pcall(GB.World.rescue)
		end
	end

	return M
end
