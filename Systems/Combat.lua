-- FindTarget / MoveToTarget / AttackTarget / ValidateKill / RecoverCombat.
-- AttackModule.Swing only, at CanSwing + swingStateDuration — not every Heartbeat.
-- Dummy stand beside. destOk. Reacquire. Don't hang.

return function(GB)
	local RS = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local M = {
		lockMob = nil,
		lockConn = nil,
		lastSwing = 0,
		lastDash = 0,
		lastBlock = 0,
		lastStandAt = 0,
		lastTargetPos = nil,
		Attack = nil,
		State = nil,
	}

	-- AttackStyleUtilities.defaults.swingStateDuration = 0.35; Basic * 1.05
	local SWING_GAP = 0.42
	local REPOS_DIST = 4.2
	local TARGET_MOVED = 3.5

	local function loadAttack()
		if not M.Attack then
			M.Attack = require(RS.Modules.AttackModule)
		end
		return M.Attack
	end

	local function loadState()
		if not M.State then
			M.State = require(RS.Modules.StateService)
		end
		return M.State
	end

	local function pressKey()
		local ev = RS:FindFirstChild("Events")
		return ev and ev:FindFirstChild("PressKey")
	end

	local function isDummy(name)
		if GB.Resolver.isDummyName then
			return GB.Resolver.isDummyName(name)
		end
		return type(name) == "string" and string.find(name, "Dummy", 1, true) ~= nil
	end

	function M.canSwing(char)
		char = char or GB.World.char()
		if not char then
			return false
		end
		return loadState().GetPermission(char, "CanSwing") == true
	end

	function M.canDodge(char)
		char = char or GB.World.char()
		if not char then
			return false
		end
		return loadState().GetPermission(char, "CanDodge") == true
	end

	function M.stopLock()
		M.lockMob = nil
		M.lastTargetPos = nil
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

	function M.isPet(inst)
		return GB.Resolver.isPet and GB.Resolver.isPet(inst)
	end

	function M.aliveEnemy(mob)
		if not (mob and mob.Parent) then
			return false
		end
		if M.isPet(mob) then
			return false
		end
		local h = mob:FindFirstChildOfClass("Humanoid")
		if h and h.Health <= 0 then
			return false
		end
		return true
	end

	function M.findTarget(name, questName)
		name = GB.QuestData.killName(questName, name)
		if not name then
			GB.Log.warn("COMBAT", "kill name unresolved")
			return nil
		end
		if isDummy(name) then
			local d = GB.Resolver.dummy()
			if d and M.isPet(d) then
				return nil
			end
			return d
		end
		local mob = GB.Resolver.enemy(name)
		if mob and M.isPet(mob) then
			return nil
		end
		return mob
	end

	function M.needReposition(mob)
		local root = GB.World.hrp()
		local part = GB.Resolver.part(mob)
		if not (root and part) then
			return false
		end
		local dest
		if isDummy(mob.Name) then
			dest = part.Position + Vector3.new(GB.Config.DummyBeside or 3.2, 0, 0)
		else
			local look = part.CFrame.LookVector
			local off = -Vector3.new(look.X, 0, look.Z)
			if off.Magnitude < 0.2 then
				off = Vector3.new(0, 0, GB.Config.CombatRange or 5.5)
			else
				off = off.Unit * (GB.Config.CombatRange or 5.5)
			end
			dest = part.Position + off
		end
		local far = (root.Position - dest).Magnitude > REPOS_DIST
		local moved = M.lastTargetPos and (M.lastTargetPos - part.Position).Magnitude or 99
		return far or moved > TARGET_MOVED
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
		M.lastTargetPos = part.Position
		M.lastStandAt = os.clock()
		if (root.Position - dest).Magnitude > 2.2 then
			root.CFrame = CFrame.new(dest, Vector3.new(part.Position.X, dest.Y, part.Position.Z))
		end
		return true
	end

	function M.swing()
		local c = GB.World.char()
		if not c then
			return
		end
		if os.clock() - M.lastSwing < SWING_GAP then
			return
		end
		if not M.canSwing(c) then
			return
		end
		M.lastSwing = os.clock()
		local atk = loadAttack()
		if atk and atk.Swing then
			atk.Swing(c)
		end
	end

	function M.startLock(mob)
		if not mob or M.isPet(mob) then
			return
		end
		M.lockMob = mob
		GB.Log.log("STATE", string.format("doing=combat target=%s", mob.Name))
		if M.lockConn then
			return
		end
		M.lockConn = RunService.Heartbeat:Connect(function()
			if GB.dead and GB.dead() then
				M.stopLock()
				return
			end
			local mob2 = M.lockMob
			if not M.aliveEnemy(mob2) then
				M.stopLock()
				if GB.Resolver.invalidateDummy then
					GB.Resolver.invalidateDummy()
				end
				GB.Cache.invalidate()
				return
			end
			if M.needReposition(mob2) then
				M.standPose(mob2)
			end
			M.swing()
		end)
	end

	function M.hunt(name)
		local mob = M.findTarget(name, nil)
		if not mob then
			return false
		end
		if M.isPet(mob) then
			return false
		end
		GB.Log.log("COMBAT", tostring(name))
		GB.Log.log("STATE", string.format("doing=combat target=%s", mob.Name))
		if GB.World.ToEnemy then
			if not GB.World.ToEnemy(mob, GB.Config.CombatRange or 5.5) then
				if not GB.World.moveTo(mob, 12) then
					return false
				end
			end
		elseif not GB.World.moveTo(mob, 12) then
			return false
		end
		M.startLock(mob)
		return true
	end

	function M.huntUntilDead(name, timeout)
		timeout = timeout or 14
		local mob = M.findTarget(name, nil)
		if not M.aliveEnemy(mob) then
			return false, "no_enemy"
		end
		if not M.hunt(name) then
			return false, "travel"
		end
		local t0 = os.clock()
		while os.clock() - t0 < timeout do
			if not M.aliveEnemy(M.lockMob or mob) then
				M.stopLock()
				return true, "dead"
			end
			task.wait(0.15)
		end
		return true, "timeout"
	end

	function M.attack(name, questName)
		if questName then
			local qs = GB.Quest.questState(questName)
			local typ = qs and qs.Objective and qs.Objective.Type
			if typ and typ ~= "Kill" and typ ~= "Defeat" and typ ~= "Hit" and typ ~= "Destroy" and typ ~= "Shoot" then
				M.stopLock()
				return false
			end
		end
		return M.hunt(name)
	end

	function M.waitPermission(kind, timeout)
		timeout = timeout or 1.6
		local t0 = os.clock()
		while os.clock() - t0 < timeout do
			local c = GB.World.char()
			if c then
				if kind == "dodge" and M.canDodge(c) then
					return true
				end
				if kind == "swing" and M.canSwing(c) then
					return true
				end
			end
			task.wait(0.08)
		end
		return false
	end

	-- Controls.Dash → Events.PressKey:Fire(Enum.KeyCode.Q). Same bind as UI "Press Q".
	function M.dash()
		M.stopLock()
		if os.clock() - M.lastDash < 0.55 then
			return false
		end
		if not M.waitPermission("dodge", 1.6) then
			GB.Log.warn("COMBAT", "dash blocked CanDodge")
			return false
		end
		local ev = pressKey()
		if not ev then
			GB.Log.warn("COMBAT", "PressKey missing")
			return false
		end
		M.lastDash = os.clock()
		ev:Fire(Enum.KeyCode.Q)
		GB.Log.log("COMBAT", "Dash Q")
		return true
	end

	-- Controls.Block → PressKey F begin, then F end (hold).
	function M.block(hold)
		M.stopLock()
		if os.clock() - M.lastBlock < 0.7 then
			return false
		end
		local ev = pressKey()
		if not ev then
			GB.Log.warn("COMBAT", "PressKey missing")
			return false
		end
		M.lastBlock = os.clock()
		ev:Fire(Enum.KeyCode.F, Enum.KeyCode)
		task.wait(hold or 0.7)
		ev:Fire(Enum.KeyCode.F, Enum.KeyCode, false)
		GB.Log.log("COMBAT", "Block F")
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
		if M.lockMob and (not M.lockMob.Parent or M.isPet(M.lockMob)) then
			M.stopLock()
			if GB.Resolver.invalidateDummy then
				GB.Resolver.invalidateDummy()
			end
		end
	end

	return M
end
