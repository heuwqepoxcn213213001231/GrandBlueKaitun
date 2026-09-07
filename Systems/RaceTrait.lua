-- Trait: Reroll:FireServer("Trait", slotNumber) VERIFIED.
-- Race reroll FireServer("Race") NOT found. AutoRaceTrait default false. No spam.

return function(GB)
	local M = {
		rolled = false,
	}

	function M.tick()
		if not GB.Config.AutoRaceTrait then
			return
		end
		if M.rolled then
			return
		end
		GB.Log.warn("RACE", "AutoRaceTrait on but race remote UNRESOLVED; trait reroll not auto-fired")
		M.rolled = true
	end

	return M
end
