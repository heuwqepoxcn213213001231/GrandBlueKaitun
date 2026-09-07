-- Daily/weekly live quests only if they have stages.
-- Empty stubs skipped via Config.SkipQuests.
-- ClaimAchievement RF args UNKNOWN — do not invent.

return function(GB)
	local M = {}

	local SAFE_DAILY = {
		"Easy Pickings",
		"Noise Complaint",
		"Corruption Cleanse",
	}

	function M.tick()
		if not GB.Config.AutoRewards then
			return
		end
		for _, name in ipairs(SAFE_DAILY) do
			if GB.PlayerData.live(name) then
				GB.Quest.doLive(name)
				return
			end
		end
	end

	return M
end
