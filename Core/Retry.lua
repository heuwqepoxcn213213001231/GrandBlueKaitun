-- RunAction: Timeout, MaxRetries, Validate, Recovery. No infinite retry.

return function(GB)
	local M = {}
	local lastFire = {}

	function M.rateOk(key, gap)
		gap = gap or 0.6
		local t = lastFire[key] or 0
		if os.clock() - t < gap then
			return false
		end
		lastFire[key] = os.clock()
		return true
	end

	function M.mark(key)
		lastFire[key] = os.clock()
	end

	function M.run(opts)
		opts = opts or {}
		local name = opts.Name or "action"
		local timeout = opts.Timeout or GB.Config.ActionTimeout or 25
		local tries = opts.MaxRetries or GB.Config.MaxRetries or 3
		local exec = opts.Execute
		local validate = opts.Validate
		local recover = opts.Recovery
		if type(exec) ~= "function" then
			return false, "no execute"
		end
		local lastErr
		for i = 1, tries do
			if GB.dead and GB.dead() then
				return false, "unloaded"
			end
			local t0 = os.clock()
			local ok, err = pcall(exec, i)
			if not ok then
				lastErr = err
				GB.Log.warn("ERROR", name .. " pcall " .. tostring(err))
			elseif validate then
				local vok, vmsg
				repeat
					if os.clock() - t0 > timeout then
						vok, vmsg = false, "timeout"
						break
					end
					local v2, m2 = pcall(validate)
					if v2 and m2 then
						vok = true
						break
					end
					vok, vmsg = false, m2 or "validate"
					task.wait(0.2)
				until GB.dead and GB.dead()
				if vok then
					return true
				end
				lastErr = vmsg
			elseif ok then
				return true
			end
			if recover and i < tries then
				pcall(recover, i, lastErr)
			end
			task.wait(0.25)
		end
		return false, lastErr
	end

	return M
end
