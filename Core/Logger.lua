-- [Kaitun][CAT] message

return function(GB)
	local LEVEL = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 }
	local last = {}
	local M = {}

	function M.log(cat, msg, lvl)
		lvl = lvl or "INFO"
		local want = LEVEL[GB.Config.LogLevel or "INFO"] or 2
		if (LEVEL[lvl] or 2) < want then
			return
		end
		local line = string.format("[Kaitun][%s] %s", cat, tostring(msg))
		local key = cat .. "|" .. tostring(msg)
		local now = os.clock()
		local gap = 2.5
		if cat == "ERROR" then
			gap = 8
		elseif cat == "PLAN" or cat == "ACQUIRE" or cat == "DROP" or cat == "PICKUP" then
			gap = 1.1
		elseif cat == "STATE" and string.find(tostring(msg), "doing=", 1, true) then
			gap = 1.1
		elseif cat == "QUEST" then
			local m = tostring(msg)
			if string.find(m, "not credited", 1, true) or string.find(m, "resolve miss", 1, true) then
				gap = 8
			end
		end
		if last[key] and now - last[key] < gap then
			return
		end
		last[key] = now
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
