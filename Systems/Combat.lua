-- FindTarget / MoveToTarget / AttackTarget / ValidateKill / RecoverCombat.
-- AttackModule.Swing only. Dummy stand beside. destOk. Reacquire. Don't hang.

return function(GB)
	local RS = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local M = {
		lockMob = nil,
		lockConn = nil,
		lastSwing = 0,
		Attack = nil,
	}

	local function loadAttack()
		if M.Attack then
			return M.Attack
		end
		pcall(function()
			M.Attack = require(RS.Modules.AttackModule)
		end)
		return M.Attack
	end

	local function isDummy(name)
		return type(name) == "string" and string.find(name, "Dummy", 1, true) ~= nil
	end

	function M.stopLock()
		M.lockMob = nil
		if M.lockConn then
			M.lockConn:Disconnect()
			M.lockConn = nil
		end
		local hum = GB.World.hum()
		if hum then
			hum.AutoRotate = true
			hum.PlatformStand = false
		end
	end

	function M.findTarget(name, questName)
		name = GB.QuestData.killName(questName, name)
		if not name then
			GB.Log.warn("COMBAT", "kill name unresolved")
			return nil
		end
		local m = GB.Resolver.enemy(name)
		if m then
			return m
		end
		-- Training Dummy variants
		if isDummy(name) or name == "Training Dummy" then
			local ents = workspace:FindFirstChild("Entities")
			if ents then
				for _, c in ipairs(ents:GetChildren()) do
					if string.find(c.Name, "Dummy", 1, true) then
						local h = c:FindFirstChildOfClass("Humanoid")
						if not h or h.Health > 0 then
							return c
						end
					end
				end
			end
			return GB.Resolver.byName("Training Dummy1") or GB.Resolver.byName("Training Dummy")
		end
		return nil
	end

	function M.standPose(mob)
		local root = GB.World.hrp()
		local part = GB.Resolver.part(mob)
		if not (root and part) then
			return false
		end
		local name = mob.Name
		local offset
		if isDummy(name) then
			-- stand beside, not under
			offset = Vector3.new(GB.Config.DummyBeside or 3.2, 0, 0)
		else
			local look = part.CFrame.LookVector
			offset = -Vector3.new(look.X, 0, look.Z)
			if offset.Magnitude < 0.2 then
				offset = Vector3.new(0, 0, GB.Config.CombatRange or 5.5)
			else
				offset = offset.Unit * (GB.Config.CombatRange or 5.5)
			end
		end
		local dest = part.Position + offset
		if not GB.World.destOk(dest) then
			dest = part.Position + Vector3.new(GB.Config.DummyBeside or 3.2, 0, 0)
		end
		local g = GB.World.groundAt(dest)
		if g then
			dest = g
		end
		if (root.Position - dest).Magnitude > 2.2 then
			root.CFrame = CFrame.new(dest, Vector3.new(part.Position.X, dest.Y, part.Position.Z))
		else
			root.CFrame = CFrame.new(root.Position, Vector3.new(part.Position.X, root.Position.Y, part.Position.Z))
		end
		return true
	end

	function M.swing()
		local c = GB.World.char()
		if not c then
			return
		end
		if os.clock() - M.lastSwing < 0.28 then
			return
		end
		M.lastSwing = os.clock()
		local atk = loadAttack()
		if atk and atk.Swing then
			pcall(atk.Swing, c)
		end
	end

	function M.startLock(mob)
		M.lockMob = mob
		if M.lockConn then
			return
		end
		M.lockConn = RunService.Heartbeat:Connect(function()
			if GB.dead and GB.dead() then
				M.stopLock()
				return
			end
			local mob2 = M.lockMob
			if not (mob2 and mob2.Parent) then
				M.stopLock()
				GB.Cache.invalidate()
				return
			end
			local h = mob2:FindFirstChildOfClass("Humanoid")
			if h and h.Health <= 0 then
				M.stopLock()
				return
			end
			M.standPose(mob2)
			M.swing()
		end)
	end

	function M.attack(name, questName)
		local mob = M.findTarget(name, questName)
		if not mob then
			GB.Log.warn("COMBAT", "no target " .. tostring(name))
			return false
		end
		if not GB.World.moveTo(mob, 12) then
			return false
		end
		M.startLock(mob)
		return true
	end

	function M.validateKill(name, questName, before)
		local live = GB.PlayerData.live(questName)
		if not live then
			return true
		end
		if GB.PlayerData.finished(questName) then
			return true
		end
		local _, st = GB.QuestData.currentStage(live)
		if not st then
			return true
		end
		if st.Complete then
			return true
		end
		local conds = st.Conditions or st.conditions or {}
		for _, cond in ipairs(conds) do
			if type(cond) == "table" and not cond.Complete then
				local cur = GB.QuestData.conditionCurrent(cond)
				local prev = type(before) == "number" and before or 0
				return cur > prev
			end
		end
		return false
	end

	function M.tick()
		if M.lockMob and not M.lockMob.Parent then
			M.stopLock()
		end
	end

	return M
end
