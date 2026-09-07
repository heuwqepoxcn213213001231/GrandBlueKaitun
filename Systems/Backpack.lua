-- Backpack UI exists. Slot / size upgrade UNRESOLVED (searched MaxSlots, InventorySlots, BuySlot).

return function(GB)
	local M = {
		disabled = true,
		reason = "UNRESOLVED backpack upgrade remote/price",
	}

	function M.tick()
		if not GB.Config.AutoBackpack then
			return
		end
		-- keep disabled
	end

	return M
end
