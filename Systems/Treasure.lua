-- Treasure Map (Easy) from Finders Keepers. Dig remotes args UNKNOWN.
-- Move to map/dig if live quest; no invented ShovelHit payload.

return function(GB)
	local M = {}

	function M.tick()
		if not GB.Config.AutoTreasure then
			return
		end
		if GB.PlayerData.live("Finders Keepers") or GB.PlayerData.live("The 'Priceless' Haul") then
			local obj = GB.Resolver.byName("Wade's Belongings") or GB.Resolver.byName("Wade")
			if obj then
				GB.World.moveTo(obj, 8)
			end
		end
	end

	return M
end
