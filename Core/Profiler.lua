-- Lightweight runtime profiler + per-minute counters.
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
		"GetDescendants",
		"getgc",
		"getconnections",
		"RuntimeFileWrite",
		"PersistWrite",
		"HeartbeatQuestCheck",
		"HeartbeatCallbacks",
		"PlayerDataRefresh",
		"ResolverMiss",
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
			local spikeN = 0
			for _ in pairs(M.lastSpikeAt) do
				spikeN = spikeN + 1
			end
			if spikeN > 80 then
				M.lastSpikeAt = {}
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
