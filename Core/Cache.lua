-- World / scan cache. Refresh on island, quest, target-lost, timeout, state change.

return function(GB)
	local M = {
		_store = {},
		_at = {},
		_order = {},
		_orderPos = {},
	}

	local DEFAULT_TTL = 2.5
	local MAX_KEYS = 2200
	local PRUNE_STRIDE = 28
	local PRUNE_GAP = 0.2

	local function removeOrderKey(key)
		local pos = M._orderPos[key]
		if not pos then
			return
		end
		local last = #M._order
		local lastKey = M._order[last]
		M._order[pos] = lastKey
		M._order[last] = nil
		M._orderPos[key] = nil
		if lastKey and lastKey ~= key then
			M._orderPos[lastKey] = pos
		end
	end

	local function touchOrder(key)
		removeOrderKey(key)
		M._order[#M._order + 1] = key
		M._orderPos[key] = #M._order
	end

	local function dropKey(key)
		M._store[key] = nil
		M._at[key] = nil
		removeOrderKey(key)
	end

	local function enforceMax()
		while #M._order > MAX_KEYS do
			local drop = table.remove(M._order, 1)
			if drop then
				M._orderPos[drop] = nil
				M._store[drop] = nil
				M._at[drop] = nil
			end
			for i = 1, #M._order do
				M._orderPos[M._order[i]] = i
			end
		end
	end

	local function pruneIncremental()
		local now = os.clock()
		if now - (M._lastPruneAt or 0) < PRUNE_GAP then
			return
		end
		M._lastPruneAt = now
		local steps = math.min(PRUNE_STRIDE, #M._order)
		for _ = 1, steps do
			local key = table.remove(M._order, 1)
			if not key then
				break
			end
			M._orderPos[key] = nil
			if M._store[key] ~= nil then
				if now - (M._at[key] or 0) > DEFAULT_TTL * 3 then
					M._store[key] = nil
					M._at[key] = nil
				else
					M._order[#M._order + 1] = key
					M._orderPos[key] = #M._order
				end
			end
		end
	end

	function M.get(key, ttl)
		pruneIncremental()
		local row = M._store[key]
		if not row then
			return nil
		end
		if os.clock() - (M._at[key] or 0) > (ttl or DEFAULT_TTL) then
			dropKey(key)
			return nil
		end
		return row
	end

	function M.set(key, value)
		pruneIncremental()
		M._store[key] = value
		M._at[key] = os.clock()
		touchOrder(key)
		enforceMax()
		return value
	end

	function M.invalidate(key)
		if key then
			dropKey(key)
			return
		end
		M._store = {}
		M._at = {}
		M._order = {}
		M._orderPos = {}
	end

	function M.invalidatePrefix(prefix)
		if type(prefix) ~= "string" or prefix == "" then
			return
		end
		local drops = {}
		for key in pairs(M._store) do
			if string.sub(key, 1, #prefix) == prefix then
				drops[#drops + 1] = key
			end
		end
		for _, key in ipairs(drops) do
			dropKey(key)
		end
	end

	function M.memo(key, ttl, fn)
		local hit = M.get(key, ttl)
		if hit ~= nil then
			return hit
		end
		local v = fn()
		if v ~= nil then
			M.set(key, v)
		end
		return v
	end

	function M.stats()
		return {
			keys = #M._order,
			max = MAX_KEYS,
		}
	end

	return M
end
