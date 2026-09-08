-- Single-flight async remote reads. Engine never InvokeServer on the decide thread.

return function(GB)
	local M = {
		_pending = {},
		_gen = {},
		_cache = {},
		_at = {},
		_err = {},
		_backoffUntil = {},
		_lastStart = {},
	}

	local DEFAULT_BACKOFF = 0.45

	local function dead()
		return GB.dead and GB.dead()
	end

	local function now()
		return os.clock()
	end

	function M.pendingCount()
		local n = 0
		for _ in pairs(M._pending) do
			n = n + 1
		end
		return n
	end

	function M.pendingNames()
		local out = {}
		for name in pairs(M._pending) do
			out[#out + 1] = name
		end
		return out
	end

	function M.isPending(name)
		return M._pending[name] == true
	end

	function M.cached(name)
		return M._cache[name], M._at[name]
	end

	function M.backoffUntil(name)
		return M._backoffUntil[name] or 0
	end

	function M.invalidate(name)
		if name then
			M._cache[name] = nil
			M._at[name] = nil
			return
		end
		M._cache = {}
		M._at = {}
	end

	function M.request(name, worker, opts)
		opts = type(opts) == "table" and opts or {}
		if type(name) ~= "string" or name == "" or type(worker) ~= "function" then
			return false, "bad_request"
		end
		if dead() then
			return false, "dead"
		end
		if M._pending[name] then
			return false, "pending"
		end
		if now() < (M._backoffUntil[name] or 0) then
			return false, "backoff"
		end
		local minGap = tonumber(opts.minGap) or 0
		if minGap > 0 and now() - (M._lastStart[name] or 0) < minGap then
			return false, "gap"
		end
		local gen = (M._gen[name] or 0) + 1
		M._gen[name] = gen
		M._pending[name] = true
		M._lastStart[name] = now()
		local bootGen = tonumber(getgenv()._GBKaitunGen) or 0
		task.spawn(function()
			local ok, a, b, c = pcall(worker)
			M._pending[name] = nil
			if dead() or (tonumber(getgenv()._GBKaitunGen) or 0) ~= bootGen then
				return
			end
			if M._gen[name] ~= gen then
				return
			end
			if not ok then
				M._err[name] = a
				M._backoffUntil[name] = now() + (tonumber(opts.failBackoff) or DEFAULT_BACKOFF)
				if opts.onError then
					pcall(opts.onError, a)
				end
				return
			end
			M._cache[name] = { a, b, c }
			M._at[name] = now()
			M._err[name] = nil
			M._backoffUntil[name] = now() + (tonumber(opts.okBackoff) or 0)
			if opts.onDone then
				pcall(opts.onDone, a, b, c)
			end
			if GB.Scheduler and GB.Scheduler.nudge then
				GB.Scheduler.nudge()
			end
		end)
		return true, "queued"
	end

	return M
end
