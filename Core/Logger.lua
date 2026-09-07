-- [Kaitun][CAT] message

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
