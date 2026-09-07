-- KEEP_CURRENT default. PickupDF(FruitId) VERIFIED.
-- Store/equip via PermanentFruit. Eat = tool activate (server Prompt) — do not eat blindly.

return function(GB)
	local M = {}

	function M.pickupNearby()
		local found
		pcall(function()
			for _, d in ipairs(workspace:GetDescendants()) do
				if d:GetAttribute("FruitId") and d:GetAttribute("Interaction") == "Devil Fruit" then
					found = d
					break
				end
			end
		end)
		if not found then
			return false
		end
		if not GB.World.moveTo(found, 10) then
			return false
		end
		local id = found:GetAttribute("FruitId")
		GB.Log.log("FRUIT", "PickupDF " .. tostring(id))
		return GB.Remotes.pickupFruit(id)
	end

	function M.tick()
		if not GB.Config.AutoFruit then
			return
		end
		M.pickupNearby()
		local snap = GB.State.get()
		if GB.Config.FruitMode ~= "DesiredFruits" then
			return
		end
		-- Eat path unverified as a dedicated remote (tool ServerActivated + Prompt).
		-- Do not Fire eat. Store current if Desired differs and Closet store is safe.
		local want = GB.Config.DesiredFruits
		if type(want) ~= "table" or not snap.Fruit then
			return
		end
		local desired
		for _, n in ipairs(want) do
			if n == snap.Fruit then
				return
			end
			if GB.ItemData.FRUITS[n] then
				desired = desired or n
			end
		end
		if desired and snap.Fruit ~= desired then
			GB.Log.log("FRUIT", "KEEP_CURRENT override — eat disabled; store via Closet only if you hold desired")
		end
	end

	return M
end
