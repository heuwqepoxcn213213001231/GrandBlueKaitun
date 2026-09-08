-- KEEP_CURRENT default. PickupDF(FruitId) VERIFIED.
-- Store/equip via PermanentFruit. Eat = tool activate (server Prompt) — do not eat blindly.

return function(GB)
	local CS = game:GetService("CollectionService")
	local M = {}
	local DEEP_SCAN_GAP = 8

	local function perfCount(name, n)
		if GB.Profiler and GB.Profiler.count then
			GB.Profiler.count(name, n or 1)
		end
	end

	local function isFruit(inst)
		return inst
			and inst.Parent
			and inst:GetAttribute("FruitId")
			and inst:GetAttribute("Interaction") == "Devil Fruit"
	end

	local function taggedFruit()
		for _, tag in ipairs({ "Devil Fruit", "Drop", "DroppedItem", "ClientInteractable" }) do
			local ok, tagged = pcall(CS.GetTagged, CS, tag)
			if ok and type(tagged) == "table" then
				for _, inst in ipairs(tagged) do
					if isFruit(inst) then
						return inst
					end
				end
			end
		end
		return nil
	end

	local function folderFruit()
		for _, folderName in ipairs({ "Drops", "DroppedItems", "QuestItems", "WorldDrops" }) do
			local root = workspace:FindFirstChild(folderName)
			if root then
				for _, child in ipairs(root:GetChildren()) do
					if isFruit(child) then
						return child
					end
				end
			end
		end
		return nil
	end

	function M.pickupNearby()
		local found = taggedFruit() or folderFruit()
		if not found and GB.Config and GB.Config.DebugWorldDeepScan == true and os.clock() - (M._deepAt or 0) >= DEEP_SCAN_GAP then
			M._deepAt = os.clock()
			perfCount("WorkspaceDeepScan", 1)
			pcall(function()
				for _, d in ipairs(workspace:GetDescendants()) do -- diagnostic DebugWorldDeepScan only
					if isFruit(d) then
						found = d
						break
					end
				end
			end)
		end
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
