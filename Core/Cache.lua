-- World / scan cache. Refresh on island, quest, target-lost, timeout, state change.

return function(GB)
	local M = {
		_store = {},
		_at = {},
	}

	local DEFAULT_TTL = 2.5

	function M.get(key, ttl)
		local row = M._store[key]
		if not row then
			return nil
		end
		if os.clock() - (M._at[key] or 0) > (ttl or DEFAULT_TTL) then
			return nil
		end
		return row
	end

	function M.set(key, value)
		M._store[key] = value
		M._at[key] = os.clock()
		return value
	end

	function M.invalidate(key)
		if key then
			M._store[key] = nil
			M._at[key] = nil
			return
		end
		M._store = {}
		M._at = {}
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

	return M
end
