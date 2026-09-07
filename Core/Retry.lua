-- RunAction: Timeout, MaxRetries, Validate, Recovery. No infinite retry.

return function(GB)
	local M = {}
	local lastFire = {}
	local order = {}
	local orderPos = {}
	local MAX_KEYS = 2400
	local TTL = 90
	local PRUNE_STRIDE = 32
	local PRUNE_GAP = 0.2

	local function dropKey(key)
		lastFire[key] = nil
		local pos = orderPos[key]
		if not pos then
			return
		end
		local last = #order
		local lastKey = order[last]
		order[pos] = lastKey
		order[last] = nil
		orderPos[key] = nil
		if lastKey and lastKey ~= key then
			orderPos[lastKey] = pos
		end
	end

	local function touchKey(key, now)
		dropKey(key)
		lastFire[key] = now
		order[#order + 1] = key
		orderPos[key] = #order
	end

	local function prune()
		local now = os.clock()
		if now - (M._lastPruneAt or 0) < PRUNE_GAP then
			return
		end
		M._lastPruneAt = now
		local n = math.min(PRUNE_STRIDE, #order)
		for _ = 1, n do
			local key = table.remove(order, 1)
			if not key then
				break
			end
			orderPos[key] = nil
			local ts = lastFire[key]
			if ts and now - ts <= TTL then
				order[#order + 1] = key
				orderPos[key] = #order
			else
				lastFire[key] = nil
			end
		end
	end

	local function enforceMax()
		while #order > MAX_KEYS do
			local key = table.remove(order, 1)
			if not key then
				break
			end
			orderPos[key] = nil
			lastFire[key] = nil
		end
		for i = 1, #order do
			orderPos[order[i]] = i
		end
	end

	function M.rateOk(key, gap)
		prune()
		gap = gap or 0.6
		local t = lastFire[key] or 0
		if os.clock() - t < gap then
			return false
		end
		touchKey(key, os.clock())
		enforceMax()
		return true
	end

	function M.mark(key)
		touchKey(key, os.clock())
		enforceMax()
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
