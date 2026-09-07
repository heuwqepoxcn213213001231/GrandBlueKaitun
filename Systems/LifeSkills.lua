-- Mining: hold MouseButton1 through the QTE bar, release in the crit zone.
-- EquipAndActivateBindable("Pickaxe") only starts the swing — a tap cancels the charge.
-- PickaxeHit args stay on the tool client. Do not invent them.

return function(GB)
	local RS = game:GetService("ReplicatedStorage")
	local VIM = game:GetService("VirtualInputManager")
	local RunService = game:GetService("RunService")
	local M = {
		_busy = false,
		_mouse = false,
	}

	local function fireActivate(kind)
		local b = RS:FindFirstChild("Events") and RS.Events:FindFirstChild("EquipAndActivateBindable")
		if not b then
			return false
		end
		return pcall(function()
			b:Fire(kind)
		end)
	end

	local function pickaxeName()
		for _, n in ipairs({
			"Rusty Pickaxe",
			"Steel Pickaxe",
			"Silver Pickaxe",
			"Golden Pickaxe",
			"Obsidian Pickaxe",
			"Emerald Pickaxe",
			"Diamond Pickaxe",
		}) do
			if GB.PlayerData.hasItem(n) then
				return n
			end
		end
		return nil
	end

	local function oreHp(ore)
		if not ore then
			return nil
		end
		local n
		pcall(function()
			n = ore:GetAttribute("Health") or ore:GetAttribute("HP") or ore:GetAttribute("OreHealth")
		end)
		if type(n) == "number" then
			return n
		end
		local hum = ore:FindFirstChildOfClass("Humanoid")
		if hum then
			return hum.Health
		end
		return nil
	end

	local function distTo(ore)
		local root = GB.World and GB.World.hrp and GB.World.hrp()
		local pos = ore and GB.Resolver.positionOf and GB.Resolver.positionOf(ore)
		if not (root and pos) then
			return math.huge
		end
		return (root.Position - pos).Magnitude
	end

	local function chargeGui()
		local char = GB.World and GB.World.char and GB.World.char()
		if not char then
			return nil
		end
		local pp = char.PrimaryPart or char:FindFirstChild("HumanoidRootPart")
		if pp then
			local g = pp:FindFirstChild("Mining")
			if g and g:FindFirstChild("Frame") then
				return g
			end
		end
		for _, d in ipairs(char:GetDescendants()) do
			if d.Name == "Mining" and d:FindFirstChild("Frame") then
				return d
			end
		end
		return nil
	end

	-- QTE cursor is 1 - Amount.Scale.Y. Zone is Critical Zone Y scale + height.
	local function inCritZone(gui)
		local frame = gui and gui:FindFirstChild("Frame")
		local amount = frame and frame:FindFirstChild("Amount")
		local zone = frame and frame:FindFirstChild("Critical Zone")
		if not (amount and zone) then
			return false, 0
		end
		local fill = amount.Size.Y.Scale
		local cursor = 1 - fill
		local top = zone.Position.Y.Scale
		local bot = top + zone.Size.Y.Scale
		return cursor >= top and cursor <= bot, fill
	end

	local function mouseAt(down)
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
		local x, y = vp.X * 0.5, vp.Y * 0.58
		pcall(function()
			if VIM.SendMouseMoveEvent then
				VIM:SendMouseMoveEvent(x, y, game)
			end
			VIM:SendMouseButtonEvent(x, y, 0, down, game, 1)
		end)
		M._mouse = down
	end

	local function waitClearStun(sec)
		local char = GB.World and GB.World.char and GB.World.char()
		if not char then
			return
		end
		local ok, SS = pcall(function()
			return require(RS.Modules.StateService)
		end)
		if not (ok and type(SS) == "table" and SS.CheckForState) then
			return
		end
		local t0 = os.clock()
		while os.clock() - t0 < (sec or 1.2) do
			local stunned
			pcall(function()
				stunned = SS.CheckForState(char, "Stun")
			end)
			if not stunned then
				return
			end
			task.wait(0.08)
		end
	end

	local function waitReleaseWindow()
		local t0 = os.clock()
		local seen = false
		while os.clock() - t0 < 2.4 do
			local gui = chargeGui()
			if gui then
				seen = true
				local hit, fill = inCritZone(gui)
				if hit then
					return true, fill
				end
				if fill >= 0.93 then
					return true, fill
				end
			elseif seen then
				return false, 0
			elseif os.clock() - t0 > 0.9 then
				return false, 0
			end
			RunService.RenderStepped:Wait()
		end
		return seen, 0
	end

	function M.mineToward(target)
		if not GB.Config.AutoMining then
			return false
		end
		if M._busy then
			return true
		end
		if GB.State and GB.State.tutorialOverlayVisible and GB.State.tutorialOverlayVisible() then
			if GB.State.dismissTutorialOverlay then
				GB.State.dismissTutorialOverlay()
			end
			return false
		end
		M._busy = true
		local ok = false
		local did = pcall(function()
			if GB.Combat and GB.Combat.stopLock then
				GB.Combat.stopLock()
			end
			local axe = pickaxeName()
			if axe and (not GB.Equipment.heldName or GB.Equipment.heldName() ~= axe) then
				GB.Equipment.equipNamed(axe)
				task.wait(0.15)
			end
			local ore = GB.Resolver.byName(target) or GB.Resolver.ore()
			if not ore then
				GB.Log.warn("MINING", "ore miss " .. tostring(target))
				return
			end
			if distTo(ore) > 7 then
				if GB.World.ToInteractable then
					GB.World.ToInteractable(ore, 5)
				else
					GB.World.moveTo(ore, 7)
				end
				task.wait(0.2)
			end
			waitClearStun(1.2)
			if GB.Skills and GB.Skills.aimAt then
				GB.Skills.aimAt(ore)
			end
			local hp0 = oreHp(ore)
			mouseAt(true)
			task.wait(0.06)
			fireActivate("Pickaxe")
			GB.Log.log("MINING", "hold charge at " .. ore.Name)
			local released, fill = waitReleaseWindow()
			mouseAt(false)
			GB.Log.log(
				"MINING",
				string.format("release fill=%.2f zone=%s", tonumber(fill) or 0, released and "yes" or "timeout")
			)
			task.wait(0.85)
			local hp1 = oreHp(ore)
			if hp0 and hp1 and hp1 < hp0 then
				GB.Log.log("MINING", string.format("hit hp %s->%s", tostring(hp0), tostring(hp1)))
				if GB.Recovery and GB.Recovery.markSuccess then
					GB.Recovery.markSuccess()
				end
			end
			ok = true
		end)
		if M._mouse then
			mouseAt(false)
		end
		M._busy = false
		return did and ok
	end

	function M.smeltToward(target)
		local station = (GB.Resolver.taggedAny and GB.Resolver.taggedAny("Furnace")) or GB.Resolver.byName("Furnace")
		if not station then
			GB.Log.warn("SMELT", "furnace miss " .. tostring(target))
			return false
		end
		if GB.World.interact then
			GB.World.interact(station, 8)
		else
			GB.World.moveTo(station, 8)
		end
		GB.Log.log("SMELT", tostring(target) .. " at Furnace")
		return true
	end

	function M.fishToward(target)
		if not GB.Config.AutoFishing then
			return false
		end
		local rod = GB.PlayerData.hasItem("Carbon Rod") and "Carbon Rod" or (GB.PlayerData.hasItem("Wooden Rod") and "Wooden Rod")
		if rod then
			GB.Equipment.equipNamed(rod)
		end
		local shop = GB.Resolver.byName("Anchor Town Fishing Shop") or GB.Resolver.shopItem("Wooden Rod")
		if shop then
			GB.World.moveTo(shop, 12)
		end
		GB.Log.log("FISHING", "at water for " .. tostring(target) .. " (cast remote args UNRESOLVED)")
		return true
	end

	function M.farmToward(typ, target)
		if not GB.Config.AutoFarming then
			return false
		end
		local obj = GB.Resolver.byName(target) or GB.Resolver.byName("Seed")
		if obj then
			GB.World.moveTo(obj, 8)
			local pr = GB.Resolver.prompt(obj)
			if pr then
				GB.World.firePrompt(pr)
			end
			return true
		end
		GB.Log.warn("FARMING", typ .. " miss " .. tostring(target))
		return false
	end

	function M.cookToward(target)
		if not GB.Config.AutoCooking then
			return false
		end
		local obj = GB.Resolver.byName(target) or GB.Resolver.byName("Remy")
		if obj then
			GB.World.moveTo(obj, 8)
			return true
		end
		return false
	end

	function M.tick()
	end

	return M
end
