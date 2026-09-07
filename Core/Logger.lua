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
		if last[key] and now - last[key] < 2.5 then
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
