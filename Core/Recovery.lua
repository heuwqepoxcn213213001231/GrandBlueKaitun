-- Stuck: change strategy. lookup drop → enemy → diagnostic → blocker.
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
			GB.Log.warn("RECOVERY", "skip ContinueOverlay " .. tostring(gate.Id))
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
