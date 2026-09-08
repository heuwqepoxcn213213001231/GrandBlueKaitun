-- [Kaitun][CAT] message

return function(GB)
	local LEVEL = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 }
	local last = {}
	local order = {}
	local MAX_KEYS = 1000
	local KEY_TTL = 75
	local PRUNE_STEP = 24
	local PRUNE_GAP = 0.2
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
		last[key] = { at = now }
		if #order <= MAX_KEYS then
			return
		end
		local drop = table.remove(order, 1)
		if drop then
			last[drop] = nil
		end
	end

	local function pruneKeys(now)
		if now - (M._lastPruneAt or 0) < PRUNE_GAP then
			return
		end
		M._lastPruneAt = now
		local n = math.min(PRUNE_STEP, #order)
		for _ = 1, n do
			local key = table.remove(order, 1)
			if not key then
				break
			end
			local row = last[key]
			if row and now - (row.at or 0) <= KEY_TTL then
				order[#order + 1] = key
			else
				last[key] = nil
			end
		end
	end

	local function writeFile(line)
		local fn = rawget(getgenv(), "_GBKaitunLogWrite")
		if type(fn) == "function" then
			pcall(fn, line)
		end
	end

	function M.log(cat, msg, lvl)
		lvl = lvl or "INFO"
		local line = string.format("[Kaitun][%s] %s", cat, tostring(msg))
		local want = LEVEL[GB.Config.LogLevel or "INFO"] or 2
		if (LEVEL[lvl] or 2) < want then
			writeFile(line)
			return
		end
		local key = dedupeKey(cat, msg)
		local now = os.clock()
		pruneKeys(now)
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
		local row = last[key]
		if row and now - (row.at or 0) < gap then
			writeFile(line)
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
