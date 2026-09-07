-- Shop:FireServer("Purchase", InteractablePart, qty)
-- Rowboat: Ships:FireServer("Purchase", {Type="Rowboat"})
-- Sell: SellItem:FireServer(key [, amount])

return function(GB)
	local M = {}

	function M.buy(name, qty)
		qty = qty or 1
		if name == "Rowboat" then
			return GB.Boat.buyRowboat()
		end
		local price = GB.ItemData.shopPrice(name)
		local gold = GB.State.get().Gold or 0
		if price and gold < price * qty then
			GB.Log.log("SHOP", "need " .. tostring(price) .. "G for " .. name)
			return false
		end
		local part = GB.Resolver.shopItem(name)
		if not part then
			GB.Log.warn("SHOP", "no display " .. tostring(name))
			return false
		end
		local interact = (GB.Resolver.interactableOf and GB.Resolver.interactableOf(part)) or part
		if GB.World.ToInteractable then
			GB.World.ToInteractable(interact, 6)
		elseif not GB.World.moveTo(interact, 12) then
			GB.Log.warn("SHOP", "travel fail " .. tostring(name))
			return false
		end
		task.wait(0.15)
		local stock = interact:GetAttribute("Stock") or part:GetAttribute("Stock")
		local before = select(2, GB.PlayerData.hasItem(name))
		if stock then
			local idx = tonumber(interact.Parent and interact.Parent.Name)
			GB.Remotes.rotatingPurchase(idx, qty)
		else
			GB.Remotes.shopPurchase(interact, qty)
		end
		local pr = GB.Resolver.prompt(interact, "Shop Item") or GB.Resolver.prompt(interact)
		if pr and GB.World.firePrompt then
			GB.World.firePrompt(pr, pr.HoldDuration or 0, interact)
		end
		GB.Log.log("SHOP", "Purchase " .. name .. " x" .. qty)
		task.wait(0.45)
		local _, after = GB.PlayerData.hasItem(name)
		if after > before then
			GB.Recovery.markSuccess()
			return true
		end
		GB.Log.warn("SHOP", "purchase fired, item not in inventory yet")
		return false
	end

	function M.sellNamed(name)
		local inv = GB.PlayerData.cache().Inventory
		if type(inv) ~= "table" then
			return false
		end
		for k, v in pairs(inv) do
			local nm = type(v) == "table" and v.Name or k
			if nm == name then
				local key = type(v) == "table" and (v.Key or k) or k
				GB.Log.log("SHOP", "Sell " .. tostring(nm))
				return GB.Remotes.sell(key)
			end
		end
		return false
	end

	function M.tick()
		if not GB.Config.AutoShop then
			return
		end
		local gold = GB.State.get().Gold or 0
		-- save for progression buys
		for _, name in ipairs(GB.ItemData.PROGRESS_BUY) do
			local spec = GB.ItemData.SHOP[name]
			if spec and spec.need and GB.PlayerData.live(spec.need) then
				if not GB.PlayerData.hasItem(name) then
					if spec.gold and gold >= spec.gold then
						M.buy(name)
					end
				end
			end
		end
	end

	return M
end
