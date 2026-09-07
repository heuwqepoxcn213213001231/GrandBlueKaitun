-- Tick loop. No giant while-true spaghetti in systems.

return function(GB)
	local M = {
		_jobs = {},
		_order = {},
		_conn = nil,
		_last = 0,
		_running = false,
	}

	local function pbegin()
		return GB.Profiler and GB.Profiler.begin and GB.Profiler.begin() or nil
	end

	local function pdone(name, t0)
		if t0 and GB.Profiler and GB.Profiler.done then
			GB.Profiler.done(name, t0)
		end
	end

	function M.add(name, fn, every)
		M._jobs[name] = {
			fn = fn,
			every = every or 0,
			at = 0,
		}
		local found
		for _, n in ipairs(M._order) do
			if n == name then
				found = true
				break
			end
		end
		if not found then
			table.insert(M._order, name)
		end
	end

	function M.remove(name)
		M._jobs[name] = nil
	end

	function M.step()
		local t0 = pbegin()
		if not GB.Config.Enabled then
			pdone("Scheduler.step", t0)
			return
		end
		if GB.dead and GB.dead() then
			pdone("Scheduler.step", t0)
			return
		end
		local now = os.clock()
		for _, name in ipairs(M._order) do
			local j = M._jobs[name]
			if j and now - j.at >= (j.every or 0) then
				j.at = now
				local jt = pbegin()
				local ok, err = pcall(j.fn)
				pdone("Scheduler.job." .. tostring(name), jt)
				if not ok then
					GB.Log.err("ERROR", name .. " " .. tostring(err))
				end
			end
		end
		if GB.Profiler and GB.Profiler.tick then
			GB.Profiler.tick()
		end
		pdone("Scheduler.step", t0)
	end

	function M.start()
		if M._running then
			return
		end
		M._running = true
		task.spawn(function()
			while M._running and not (GB.dead and GB.dead()) do
				M.step()
				task.wait(GB.Config.Tick or 0.4)
			end
		end)
	end

	function M.stop()
		M._running = false
	end

	return M
end
