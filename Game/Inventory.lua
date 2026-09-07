-- Inventory classify + helpers.

return function(GB)
	local M = {}

	function M.list()
		local inv = GB.PlayerData.cache().Inventory
		local rows = {}
		if type(inv) ~= "table" then
			return rows
		end
		for k, v in pairs(inv) do
			if type(v) == "table" then
				table.insert(rows, {
					key = v.Key or v.Name or k,
					name = v.Name or k,
					amount = tonumber(v.Amount) or 1,
					lock = v.BackpackLock,
				})
			end
		end
		return rows
	end

	function M.full()
		-- slot upgrade UNRESOLVED; heuristic only
		local n = #M.list()
		return n >= 40
	end

	function M.classify(name)
		return GB.ItemData.kind(name)
	end

	return M
end
