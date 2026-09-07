-- Generic handlers: Talk Kill Collect Purchase Equip Upgrade Mine Fish Farm Cook
-- Craft Travel Interact Boss Deliver. No Talk spam. Never BeginQuest.

return function(GB)
	local M = {
		lastTalk = {},
	}

	local DECLINE = {
		Decline = true,
		["Good luck with"] = true,
		Bye = true,
		No = true,
		Cancel = true,
	}

	local function clickAccept()
		local pg = GB.lp and GB.lp.PlayerGui
		local ui = pg and pg:FindFirstChild("DialogueUI")
		if not ui then
			return
		end
		local function try(btn)
			if not btn or not btn:IsA("GuiButton") then
				return false
			end
			local t = btn.Text or (btn:FindFirstChild("TextLabel") and btn.TextLabel.Text) or btn.Name
			if type(t) ~= "string" then
				return false
			end
			for bad in pairs(DECLINE) do
				if string.find(t, bad, 1, true) then
					return false
				end
			end
			if string.find(t, "Accept") or string.find(t, "Thank") or string.find(t, "Yes") or t == "1" then
				pcall(function()
					btn:Activate()
				end)
				return true
			end
			return false
		end
		for _, d in ipairs(ui:GetDescendants()) do
			if try(d) then
				return true
			end
		end
		-- numbered option 1
		for _, d in ipairs(ui:GetDescendants()) do
			if d:IsA("GuiButton") and (d.Name == "1" or d.Name == "Option1") then
				pcall(function()
					d:Activate()
				end)
				return true
			end
		end
		return false
	end

	function M.talk(displayName, automatic)
		displayName = GB.Resolver.NPC_ALIAS[displayName] or displayName
		local key = tostring(displayName)
		if os.clock() - (M.lastTalk[key] or 0) < 1.6 then
			return false
		end
		local npc = GB.Resolver.npc(displayName)
		if not npc then
			GB.Log.warn("QUEST", "NPC miss " .. tostring(displayName))
			return false
		end
		if not GB.World.moveTo(npc, GB.Config.TalkRange or 14) then
			return false
		end
		GB.World.waitUnpause()
		local cfg = GB.Resolver.dialogueConfig(npc)
		local shown = GB.Resolver.displayName(npc) or displayName
		if automatic then
			GB.Remotes.autoTalk(shown)
		else
			GB.Remotes.talk(shown)
		end
		if cfg then
			GB.Remotes.dialogueConfig(cfg)
		end
		task.wait(0.35)
		clickAccept()
		M.lastTalk[key] = os.clock()
		GB.Log.log("QUEST", "talk " .. shown)
		return true
	end

	function M.handleCondition(questName, cond, stage)
		if type(cond) ~= "table" then
			return false
		end
		if cond.Complete then
			return true
		end
		local typ = cond.Type or cond.type
		local target = GB.QuestData.conditionTarget(cond)
		if not typ then
			return false
		end

		if typ == "Talk" or typ == "Automatic Talk" then
			return M.talk(target, typ == "Automatic Talk")
		end
		if typ == "Kill" or typ == "Defeat" then
			return GB.Combat.attack(target, questName)
		end
		if typ == "Hit" then
			return GB.Combat.attack(target or "Training Dummy", questName)
		end
		if typ == "Purchase" then
			return GB.Shop.buy(target)
		end
		if typ == "Sell" then
			return GB.Shop.sellNamed(target)
		end
		if typ == "Equip" then
			return GB.Equipment.equipNamed(target)
		end
		if typ == "Upgrade" then
			return GB.Equipment.upgradeNamed(target)
		end
		if typ == "EquipSkill" or typ == "Cast" then
			return GB.Skills.ensure(target)
		end
		if typ == "Required" and target == "TotalStatPoints" then
			return GB.Stats.investMinimum(1)
		end
		if typ == "Required" and target == "Level" then
			return false -- wait level
		end
		if typ == "Collect" or typ == "CollectLocal" or typ == "CollectLocalItem" or typ == "Loot" then
			if target and (string.find(target, "Ore") or target == "Copper Bar") then
				return GB.LifeSkills.mineToward(target)
			end
			local obj = GB.Resolver.byName(target)
			if obj then
				GB.World.moveTo(obj, 8)
				local pr = GB.Resolver.prompt(obj)
				if pr then
					pcall(function()
						fireproximityprompt(pr)
					end)
				end
				return true
			end
			GB.Log.warn("QUEST", "collect miss " .. tostring(target))
			return false
		end
		if typ == "Mine" or typ == "Smelt" then
			return GB.LifeSkills.mineToward(target)
		end
		if typ == "Fish" then
			return GB.LifeSkills.fishToward(target)
		end
		if typ == "Plant" or typ == "Harvest" or typ == "Water" or typ == "Fertilize" then
			return GB.LifeSkills.farmToward(typ, target)
		end
		if typ == "Cook" or typ == "Perfect Cook" then
			return GB.LifeSkills.cookToward(target)
		end
		if typ == "Spawn" and target == "Rowboat" then
			return GB.Boat.spawnRowboat()
		end
		if typ == "Reach" then
			local isl = target or "Maple Village"
			return GB.Travel.goIsland(isl)
		end
		if typ == "Visit" and target == "Closet" then
			local c = GB.Resolver.byName("Closet")
			if c then
				GB.World.moveTo(c, 10)
				GB.Remotes.closetVisit()
				return true
			end
			return false
		end
		if typ == "Open" or typ == "Interact" or typ == "Investigate" or typ == "Wake" or typ == "Check On" then
			local obj = GB.Resolver.byName(target)
			if obj then
				GB.World.moveTo(obj, 8)
				local pr = GB.Resolver.prompt(obj)
				if pr then
					pcall(function()
						fireproximityprompt(pr)
					end)
				end
				return true
			end
			return false
		end
		if typ == "Deliver" or typ == "Donate" then
			local npc = GB.Resolver.npc(target)
			if npc then
				return M.talk(target)
			end
			return false
		end
		if typ == "Escort" then
			local npc = GB.Resolver.npc(target)
			if npc then
				GB.World.moveTo(npc, 8)
				return true
			end
			return false
		end
		if typ == "Dash" or typ == "Block" or typ == "Shoot" then
			-- combat/tutorial inputs: stand at dummy and swing / face
			GB.Combat.attack("Training Dummy", questName)
			return true
		end
		if typ == "Destroy" then
			return GB.Combat.attack(target, questName)
		end
		if typ == "Free" then
			local obj = GB.Resolver.byName(target)
			if obj then
				GB.World.moveTo(obj, 7)
				local pr = GB.Resolver.prompt(obj)
				if pr then
					pcall(function()
						fireproximityprompt(pr)
					end)
				end
				return true
			end
			return false
		end
		GB.Log.warn("QUEST", "unhandled type " .. tostring(typ) .. " " .. tostring(target))
		return false
	end

	function M.doLive(name)
		if GB.Config.SkipQuests[name] then
			return false
		end
		local q = GB.PlayerData.live(name)
		if not q then
			-- try accept via talk / automatic
			local npc = GB.QuestData.TALK_NPC[name]
			if npc then
				return M.talk(npc)
			end
			GB.Remotes.beginAutomatic(name)
			return false
		end
		local _, st = GB.QuestData.currentStage(q)
		if not st then
			local npc = GB.QuestData.TALK_NPC[name]
			if npc then
				return M.talk(npc)
			end
			return true
		end
		local conds = st.Conditions or st.conditions or {}
		for _, cond in ipairs(conds) do
			if type(cond) == "table" and not cond.Complete then
				M.handleCondition(name, cond, st)
				return true
			end
		end
		-- stage has no open cond — talk turn-in
		local npc = GB.QuestData.TALK_NPC[name]
		if npc then
			return M.talk(npc)
		end
		return false
	end

	return M
end
