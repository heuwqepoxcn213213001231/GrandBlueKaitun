-- FindTarget / MoveToTarget / AttackTarget / ValidateKill / RecoverCombat.
-- Death = Dead attribute / Health<=0 / StateService Dead. Parent nil is despawn, not death.
-- AttackModule.Swing only at CanSwing + swingStateDuration.

return function(GB)
	local RS = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local M = {
		lockMob = nil,
		lockConn = nil,
		lockQuest = nil,
		lastSwing = 0,
		lastDash = 0,
		lastBlock = 0,
		lastStandAt = 0,
		lastTargetPos = nil,
		Attack = nil,
		State = nil,
		ActiveTarget = nil,
		deadTargets = {},
		diedConn = nil,
		deadAttrConn = nil,
		_released = nil,
		_hpLogged = nil,
		lastKillBefore = nil,
		KillTypes = {
			Kill = true,
			Defeat = true,
			Hit = true,
			Destroy = true,
			Shoot = true,
		},
	}

	local SWING_GAP = 0.42
	local REPOS_DIST = 4.2
	local TARGET_MOVED = 3.5
	local DEAD_TTL = 12

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

	function M.isPet(inst)
		return GB.Resolver.isPet and GB.Resolver.isPet(inst)
	end

	function M.pruneDeadCache()
		local now = os.clock()
		for inst, t in pairs(M.deadTargets) do
			if typeof(inst) ~= "Instance" or not inst.Parent or now - t > DEAD_TTL then
				M.deadTargets[inst] = nil
			end
		end
	end

	function M.isRecentlyDead(target)
		if not target then
			return false
		end
		local t = M.deadTargets[target]
		return t ~= nil and os.clock() - t < DEAD_TTL
	end

	function M.markDead(target, reason)
		if not target then
			return
		end
		if M.deadTargets[target] then
			return
		end
		M.deadTargets[target] = os.clock()
		if GB.Cache and GB.Cache.invalidate then
			GB.Cache.invalidate()
		end
		if GB.Resolver and GB.Resolver.invalidateDummy and isDummy(target.Name) then
			GB.Resolver.invalidateDummy()
		end
		local label = (GB.Resolver and GB.Resolver.displayName(target)) or target.Name
		if M._hpLogged ~= target then
			M._hpLogged = target
			GB.Log.log("COMBAT", string.format("%s hp=0 — dead", tostring(label)))
		end
		GB.Log.log("COMBAT", "Clearing dead target")
	end

	function M.readHealth(target)
		if not target then
			return nil
		end
		local h = target:FindFirstChildOfClass("Humanoid")
		if h then
			return h.Health, h.MaxHealth
		end
		local attr = target:GetAttribute("Health")
		if type(attr) == "number" then
			return attr, target:GetAttribute("MaxHealth")
		end
		local nv = target:FindFirstChild("Health")
		if nv and nv:IsA("NumberValue") then
			return nv.Value, nil
		end
		return nil, nil
	end

	function M.hasDeadFlag(target)
		if not target then
			return false
		end
		if target:GetAttribute("Dead") == true then
			return true
		end
		local st = M.State or (pcall(loadState) and M.State)
		if st and st.CheckForState then
			local ok, dead = pcall(st.CheckForState, st, target, "Dead")
			if ok and dead then
				return true
			end
		end
		return false
	end

	-- Central live/dead. Parent nil is despawn, not the death signal.
	function M.IsEnemyAlive(target)
		if typeof(target) ~= "Instance" then
			return false
		end
		if M.isRecentlyDead(target) then
			return false
		end
		if M.hasDeadFlag(target) then
			return false
		end
		if not target.Parent then
			return false
		end
		if M.isPet(target) then
			return false
		end
		local hp = M.readHealth(target)
		if type(hp) == "number" and hp <= 0 then
			return false
		end
		local h = target:FindFirstChildOfClass("Humanoid")
		if h then
			local ok, state = pcall(function()
				return h:GetState()
			end)
			if ok and state == Enum.HumanoidStateType.Dead then
				return false
			end
		end
		return true
	end

	function M.IsValidTarget(target, context)
		context = context or {}
		if typeof(target) ~= "Instance" then
			return false
		end
		if not M.IsEnemyAlive(target) then
			return false
		end
		if M.isPet(target) then
			return false
		end
		if GB.Resolver and GB.Resolver.part and not GB.Resolver.part(target) then
			return false
		end
		if context.Name then
			local want = context.Name
			if GB.Resolver and GB.Resolver.isDummyName and GB.Resolver.isDummyName(want) and isDummy(target.Name) then
				return true
			end
			local names = GB.Resolver and GB.Resolver.namesFor and GB.Resolver.namesFor(want, {})
			if GB.Resolver and GB.Resolver.nameMatches then
				if not GB.Resolver.nameMatches(target, names or { want }) then
					return false
				end
			else
				local disp = GB.Resolver and GB.Resolver.displayName(target)
				local npc = target:GetAttribute("NPCName")
				if target.Name ~= want and disp ~= want and npc ~= want then
					return false
				end
			end
		end
		return true
	end

	-- Compat for older call sites
	function M.aliveEnemy(mob)
		return M.IsEnemyAlive(mob)
	end

	function M.clearDeathWatch()
		if M.diedConn then
			M.diedConn:Disconnect()
			M.diedConn = nil
		end
		if M.deadAttrConn then
			M.deadAttrConn:Disconnect()
			M.deadAttrConn = nil
		end
	end

	function M.watchDeath(target)
		M.clearDeathWatch()
		if typeof(target) ~= "Instance" then
			return
		end
		local hum = target:FindFirstChildOfClass("Humanoid")
		if hum then
			M.diedConn = hum.Died:Connect(function()
				if M.lockMob == target then
					M.onTargetDead(target, "Died")
				else
					M.markDead(target, "Died")
				end
			end)
		end
		M.deadAttrConn = target:GetAttributeChangedSignal("Dead"):Connect(function()
			if target:GetAttribute("Dead") == true then
				if M.lockMob == target then
					M.onTargetDead(target, "Dead")
				else
					M.markDead(target, "Dead")
				end
			end
		end)
	end

	function M.setActive(target, questName)
		M.ActiveTarget = {
			Instance = target,
			Humanoid = target and target:FindFirstChildOfClass("Humanoid"),
			Root = GB.Resolver and GB.Resolver.part(target),
			Name = target and ((GB.Resolver and GB.Resolver.displayName(target)) or target.Name),
			AcquiredAt = os.clock(),
			LastHealth = target and M.readHealth(target),
			Dead = false,
			Quest = questName,
		}
		M.lockQuest = questName
		M._released = nil
		M._hpLogged = nil
		if target then
			local hp = M.readHealth(target)
			GB.Log.log("COMBAT", string.format("Target %s hp=%s", M.ActiveTarget.Name, tostring(hp or "?")))
			M.watchDeath(target)
		end
	end

	function M.stopLock()
		M.clearDeathWatch()
		M.lockMob = nil
		M.lastTargetPos = nil
		M.lockQuest = nil
		if M.ActiveTarget then
			M.ActiveTarget.Dead = true
			M.ActiveTarget = nil
		end
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

	function M.questCombatDone(questName)
		questName = questName or M.lockQuest
		if not questName or not GB.Quest then
			return false
		end
		if GB.PlayerData and GB.PlayerData.invalidateLive then
			GB.PlayerData.invalidateLive()
		end
		if GB.PlayerData and GB.PlayerData.finished and GB.PlayerData.finished(questName) then
			return true
		end
		local qs = GB.Quest.questState(questName)
		if not qs then
			return false
		end
		if qs.IsComplete then
			return true
		end
		local o = qs.Objective
		if not o then
			return true
		end
		if not M.KillTypes[o.Type] then
			return true
		end
		if type(o.Current) == "number" and type(o.Amount) == "number" and o.Current >= o.Amount then
			return true
		end
		if o.Complete == true then
			return true
		end
		return false
	end

	function M.logKillCredit(questName, before)
		if not (questName and GB.Quest) then
			return
		end
		if GB.PlayerData and GB.PlayerData.invalidateLive then
			GB.PlayerData.invalidateLive()
		end
		if GB.PlayerData and GB.PlayerData.refreshLive then
			GB.PlayerData.refreshLive(true)
		end
		local after = GB.Quest.questState(questName)
		local prevCur = type(before) == "table" and before.Current or (type(before) == "number" and before) or 0
		local prevAmt = type(before) == "table" and before.Amount or 0
		if after and after.IsComplete then
			GB.Log.log("QUEST", string.format("kill credited %s/%s -> done", tostring(prevCur), tostring(prevAmt)))
			return true
		end
		local o = after and after.Objective
		if type(before) == "table" and before.StageIndex and after and after.StageIndex and after.StageIndex ~= before.StageIndex then
			GB.Log.log(
				"QUEST",
				string.format("kill credited %s/%s -> stage %s", tostring(prevCur), tostring(prevAmt), tostring(after.StageIndex))
			)
			return true
		end
		if o and type(o.Current) == "number" and o.Current > prevCur then
			GB.Log.log(
				"QUEST",
				string.format("Kill credited %s/%s -> %s/%s", tostring(prevCur), tostring(o.Amount or prevAmt), tostring(o.Current), tostring(o.Amount or prevAmt))
			)
			return true
		end
		local label = M.ActiveTarget and M.ActiveTarget.Name or (M.lockMob and M.lockMob.Name) or "?"
		GB.Log.log("QUEST", "kill not credited target=" .. tostring(label))
		return false
	end

	function M.onTargetDead(target, reason)
		if not target then
			return
		end
		if M._released == target then
			return
		end
		M._released = target
		M.markDead(target, reason)
		if M.ActiveTarget and M.ActiveTarget.Instance == target then
			M.ActiveTarget.Dead = true
			M.ActiveTarget.LastHealth = 0
		end
		local qn = M.lockQuest
		local before = M.lastKillBefore
		M.stopLock()
		if qn then
			M.logKillCredit(qn, before)
		end
	end

	function M.findTarget(name, questName)
		name = GB.QuestData.killName(questName, name)
		if not name then
			GB.Log.warn("COMBAT", "kill name unresolved")
			return nil
		end
		M.pruneDeadCache()
		if isDummy(name) then
			local d = GB.Resolver.dummy()
			if d and M.IsValidTarget(d, { Name = name }) then
				return d
			end
			return nil
		end
		if GB.Resolver.enemies then
			local list = GB.Resolver.enemies(name)
			if type(list) == "table" then
				for _, inst in ipairs(list) do
					if M.IsValidTarget(inst, { Name = name }) then
						return inst
					end
				end
			end
		end
		local mob = GB.Resolver.enemy(name)
		if mob and M.IsValidTarget(mob, { Name = name }) then
			return mob
		end
		return nil
	end

	function M.needReposition(mob)
		if not M.IsEnemyAlive(mob) then
			return false
		end
		local root = GB.World.hrp()
		local part = GB.Resolver.part(mob)
		if not (root and part and part:IsA("BasePart")) then
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
		if not M.IsEnemyAlive(mob) then
			return false
		end
		local root = GB.World.hrp()
		local part = GB.Resolver.part(mob)
		if not (root and part and part:IsA("BasePart")) then
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
		if M.lockMob and not M.IsEnemyAlive(M.lockMob) then
			return
		end
		M.lastSwing = os.clock()
		local atk = loadAttack()
		if atk and atk.Swing then
			atk.Swing(c)
		end
	end

	function M.startLock(mob, questName)
		if not mob or M.isPet(mob) then
			return
		end
		if not M.IsEnemyAlive(mob) then
			M.markDead(mob, "lock")
			return
		end
		if M.lockMob == mob and M.lockConn then
			M.lockQuest = questName or M.lockQuest
			return
		end
		if M.lockConn then
			M.stopLock()
		end
		M.lockMob = mob
		M.setActive(mob, questName)
		GB.Log.log("STATE", string.format("doing=combat target=%s", mob.Name))
		M.lockConn = RunService.Heartbeat:Connect(function()
			if GB.dead and GB.dead() then
				M.stopLock()
				return
			end
			local snap = GB.State and GB.State.get and GB.State.get()
			if snap and snap.Alive == false then
				M.stopLock()
				return
			end
			local mob2 = M.lockMob
			if not mob2 then
				M.stopLock()
				return
			end
			if not M.IsEnemyAlive(mob2) then
				M.onTargetDead(mob2, "poll")
				return
			end
			if M.lockQuest and M.questCombatDone(M.lockQuest) then
				M.stopLock()
				return
			end
			if M.needReposition(mob2) then
				M.standPose(mob2)
			end
			if M.IsEnemyAlive(mob2) then
				M.swing()
			else
				M.onTargetDead(mob2, "post-swing")
			end
		end)
	end

	function M.hunt(name, questName)
		local mob = M.findTarget(name, questName)
		if not mob then
			return false
		end
		if not M.IsValidTarget(mob, { Name = name }) then
			return false
		end
		GB.Log.log("COMBAT", "Next target " .. tostring(name))
		GB.Log.log("STATE", string.format("doing=combat target=%s", mob.Name))
		if not M.IsEnemyAlive(mob) then
			M.markDead(mob, "pre-travel")
			return false
		end
		if GB.World.ToEnemy then
			if not GB.World.ToEnemy(mob, GB.Config.CombatRange or 5.5) then
				if not M.IsEnemyAlive(mob) then
					M.markDead(mob, "travel")
					return false
				end
				if not GB.World.moveTo(mob, 12) then
					return false
				end
			end
		elseif not GB.World.moveTo(mob, 12) then
			return false
		end
		if not M.IsEnemyAlive(mob) then
			M.markDead(mob, "post-travel")
			return false
		end
		M.startLock(mob, questName)
		return true
	end

	function M.huntUntilDead(name, timeout, questName)
		timeout = timeout or 14
		if questName and GB.Quest then
			local qs = GB.Quest.questState(questName)
			M.lastKillBefore = qs and qs.Objective and {
				Current = qs.Objective.Current or 0,
				Amount = qs.Objective.Amount or 1,
				StageIndex = qs.StageIndex,
			} or nil
		end
		local mob = M.findTarget(name, questName)
		if not M.IsEnemyAlive(mob) then
			return false, "no_enemy"
		end
		if not M.hunt(name, questName) then
			return false, "travel"
		end
		local t0 = os.clock()
		local tracked = M.lockMob or mob
		while os.clock() - t0 < timeout do
			if questName and M.questCombatDone(questName) then
				M.stopLock()
				return true, "quest_done"
			end
			local cur = M.lockMob or tracked
			if not M.IsEnemyAlive(cur) then
				if cur then
					M.onTargetDead(cur, "wait")
				else
					M.stopLock()
				end
				return true, "dead"
			end
			task.wait(0.12)
		end
		if not M.IsEnemyAlive(M.lockMob or tracked) then
			M.onTargetDead(M.lockMob or tracked, "timeout-dead")
			return true, "dead"
		end
		return true, "timeout"
	end

	function M.shootStance(mob)
		if not M.IsEnemyAlive(mob) then
			return false
		end
		local root = GB.World.hrp()
		local part = GB.Resolver.part(mob)
		if not (root and part and part:IsA("BasePart")) then
			return false
		end
		local range = GB.Config.ShootRange or 9
		local look = part.CFrame.LookVector
		local off = Vector3.new(look.X, 0, look.Z)
		if off.Magnitude < 0.2 then
			off = Vector3.new(range, 0, 0)
		else
			off = off.Unit * range
		end
		local dest = part.Position + off
		if not GB.World.destOk(dest) then
			dest = part.Position + Vector3.new(range, 0, 0)
		end
		local g = GB.World.groundAt(dest)
		if g then
			dest = g
		end
		root.CFrame = CFrame.new(dest, Vector3.new(part.Position.X, dest.Y, part.Position.Z))
		if GB.Skills and GB.Skills.aimAt then
			GB.Skills.aimAt(mob)
		end
		return true
	end

	function M.shootUntilCredit(name, questName, timeout)
		timeout = timeout or 22
		local skill = (GB.Skills and GB.Skills.resolveShootSkill and GB.Skills.resolveShootSkill()) or "Gunshot"
		if questName and GB.Quest then
			local qs = GB.Quest.questState(questName)
			M.lastKillBefore = qs and qs.Objective and {
				Current = qs.Objective.Current or 0,
				Amount = qs.Objective.Amount or 1,
				StageIndex = qs.StageIndex,
			} or nil
		end
		M.stopLock()
		local mob = M.findTarget(name, questName)
		if not M.IsEnemyAlive(mob) then
			return false, "no_enemy"
		end
		GB.Log.log("COMBAT", "Shoot " .. skill .. " -> " .. tostring(mob.Name))
		if GB.World.ToEnemy then
			GB.World.ToEnemy(mob, GB.Config.ShootRange or 9)
		end
		M.shootStance(mob)
		local t0 = os.clock()
		while os.clock() - t0 < timeout do
			if questName and M.questCombatDone(questName) then
				M.logKillCredit(questName, M.lastKillBefore)
				return true, "quest_done"
			end
			mob = M.findTarget(name, questName) or mob
			if not M.IsEnemyAlive(mob) then
				return false, "no_enemy"
			end
			M.shootStance(mob)
			if GB.Skills and GB.Skills.castHold then
				GB.Skills.castHold(skill, {
					keepLock = true,
					target = mob,
					hold = 0.5,
					cooldown = 6.1,
				})
			end
			task.wait(0.9)
			if questName and M.questCombatDone(questName) then
				M.logKillCredit(questName, M.lastKillBefore)
				return true, "quest_done"
			end
			task.wait(5.2)
		end
		if questName and M.questCombatDone(questName) then
			M.logKillCredit(questName, M.lastKillBefore)
			return true, "quest_done"
		end
		return false, "timeout"
	end

	function M.attack(name, questName)
		if questName then
			local qs = GB.Quest.questState(questName)
			local typ = qs and qs.Objective and qs.Objective.Type
			if typ and not M.KillTypes[typ] then
				M.stopLock()
				return false
			end
			M.lastKillBefore = qs and qs.Objective and {
				Current = qs.Objective.Current or 0,
				Amount = qs.Objective.Amount or 1,
				StageIndex = qs.StageIndex,
			} or nil
		end
		return M.hunt(name, questName)
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
		M.pruneDeadCache()
		if M.lockMob then
			if not M.IsEnemyAlive(M.lockMob) then
				M.onTargetDead(M.lockMob, "tick")
			elseif M.lockQuest and M.questCombatDone(M.lockQuest) then
				M.stopLock()
			end
		end
	end

	return M
end
