-- Afuaru loot + opportunistic nearby chests. No far junk travel.

return function(GB)
	local M = {}

	function M.openNearby()
		if not GB.Config.AutoChest then
			return false
		end
		local chest = GB.Resolver.chest()
		if not chest then
			return false
		end
		local root = GB.World.hrp()
		local p = GB.Resolver.part(chest)
		if not (root and p) then
			return false
		end
		if (root.Position - p.Position).Magnitude > 80 then
			if not GB.PlayerData.live("The Hoarder") then
				return false
			end
		end
		GB.World.moveTo(chest, 6)
		local pr = GB.Resolver.prompt(chest)
		if pr then
			pcall(function()
				fireproximityprompt(pr)
			end)
		end
		GB.Log.log("CHEST", "loot " .. chest.Name)
		return true
	end

	function M.tick()
		if GB.PlayerData.live("The Hoarder") then
			M.openNearby()
		end
	end

	return M
end
