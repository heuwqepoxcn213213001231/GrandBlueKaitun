-- Traced from live MenuHandler callback:
-- ImageButton.Activated -> Events.StatPoints:FireServer("Invest", child.Name, tonumber(TextBox.Text) or 1)
-- UI refresh path: UpdateStats(Events.GetStats:InvokeServer()) + StatPoints.OnClientEvent.

return function(GB)
	local M = {}

	local ORDER = { "Strength", "Health", "Willpower", "Agility", "Precision", "Energy" }
	local STATE_TTL = 1.1
	local GUI_TTL = 0.55
	local VERIFY_TIMEOUT = 3.1
	local BLOCK_RETRY_GAP = 20

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
		GB.Log.log("STAT", string.format("invest %s x%d", tostring(statName), amount))
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
			GB.Log.log("STAT", "after " .. fmtCore(after) .. " VERIFIED src=" .. tostring(after.Source))
			if GB.Recovery and GB.Recovery.markSuccess then
				GB.Recovery.markSuccess()
			end
			return true
		end
		if os.clock() < p.Deadline then
			return false, "waiting"
		end
		GB.Log.warn(
			"STAT",
			string.format(
				"[FAIL] %s unchanged Str=%d unused=%d",
				tostring(p.Stat),
				tonumber(after[p.Stat]) or 0,
				tonumber(after.Unused) or 0
			)
		)
		M._pending = nil
		markBlocked("no_state_transition")
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
		if not GB.Config.AutoStats then
			return
		end
		M.poll()
		if M._pending then
			return
		end
		local state = M.ReadStatState()
		if state.Unused < 1 then
			if not M._zeroAt or os.clock() - M._zeroAt > 12 then
				M._zeroAt = os.clock()
				GB.Log.log("STAT", "unused=0 (no invest)")
			end
			return
		end
		if M._blocked and os.clock() - (M._blockedAt or 0) < BLOCK_RETRY_GAP then
			if not M._blockedLogAt or os.clock() - M._blockedLogAt > 10 then
				M._blockedLogAt = os.clock()
				GB.Log.warn("STAT", "blocked " .. tostring(M._blockedReason or "unknown"))
			end
			return
		end
		local stat = pickNextStat(state)
		if not M._remoteVerified then
			stat = "Strength"
		end
		if not stat then
			return
		end
		local ok, why = beginInvest(stat, 1, "auto")
		if not ok and why ~= "no_points" and why ~= "rate" then
			markBlocked("send_failed:" .. tostring(why))
			GB.Log.warn("STAT", "[FAIL] invest send " .. tostring(why))
		end
	end

	return M
end
