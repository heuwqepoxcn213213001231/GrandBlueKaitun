-- FindTarget / MoveToTarget / AttackTarget / ValidateKill / RecoverCombat.
-- Death = Dead attribute / Health<=0 / StateService Dead. Parent nil is despawn, not death.
-- AttackModule.Swing only at CanSwing + swingStateDuration.
-- UNSAFE / NOT ENABLED: clearing SwingCD/Endlag, forging attack remotes, Swing spam.

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
		lastQuestCheck = 0,
		lastQuestRefresh = 0,
		lastQuestDone = nil,
		KillTypes = {
			Kill = true,
			Defeat = true,
			Hit = true,
			Destroy = true,
			Shoot = true,
		},
	}

	-- Verified AttackModule basic: swingStateDuration = 0.35 * 1.05 ≈ 0.3675. CanSwing is authoritative.
	local SWING_GAP = 0.42
	local SWING_VERIFIED = 0.3675
	local SWING_FLOOR = 0.05
	local REPOS_DIST = 4.2
	local TARGET_MOVED = 3.5
	local DEAD_TTL = 12
	local SWING_RANGE_PAD = 1.8
	local APPROACH_SWING_PAD = 10
	local APPROACH_SWING_GAP = 0.95
	local QUEST_CHECK_MIN_GAP = 0.32
	local QUEST_CHECK_SAFETY = 2.8
	M._tel = { attempt = 0, accepted = 0, reject = 0, damage = 0, at = 0 }
	M._noCredit = 0

	local function pbegin()
		return GB.Profiler and GB.Profiler.begin and GB.Profiler.begin() or nil
	end

	local function pdone(name, t0)
		if t0 and GB.Profiler and GB.Profiler.done then
			GB.Profiler.done(name, t0)
		end
	end

	local function perfCount(name, n)
		if GB.Profiler and GB.Profiler.count then
			GB.Profiler.count(name, n or 1)
		end
	end

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

	function M.readSwingDuration()
		local atk = loadAttack()
		if type(atk) == "table" then
			local d = tonumber(atk.swingStateDuration or atk.SwingStateDuration or atk.SwingDuration)
			if d and d > 0.12 and d < 1.6 then
				return d
			end
		end
		return SWING_VERIFIED
	end

	function M.minSwingInterval()
		local mode = GB.Config and GB.Config.CombatMode or "SAFE_FAST"
		local verified = math.max(SWING_VERIFIED, M.readSwingDuration())
		if mode ~= "SAFE_FAST" then
			return math.max(verified, SWING_GAP)
		end
		if (M._noCredit or 0) >= 8 then
			return verified
		end
		return SWING_FLOOR
	end

	function M.preferredAction(questName)
		local qs = questName and GB.Quest and GB.Quest.questState and GB.Quest.questState(questName)
		local typ = qs and qs.Objective and qs.Objective.Type
		if typ == "Shoot" then
			return "GUN"
		end
		return "SWING"
	end

	local function noteSwing(accepted)
		local t = M._tel
		t.attempt = t.attempt + 1
		if accepted then
			t.accepted = t.accepted + 1
		else
			t.reject = t.reject + 1
		end
		if GB.Config and GB.Config.CombatDebug == true and os.clock() - (t.at or 0) >= 20 then
			t.at = os.clock()
			GB.Log.log(
				"COMBAT",
				string.format(
					"rate attempt=%d accepted=%d reject=%d damage=%d",
					t.attempt,
					t.accepted,
					t.reject,
					t.damage or 0
				)
			)
			t.attempt, t.accepted, t.reject, t.damage = 0, 0, 0, 0
		end
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
		if GB.Cache and GB.Cache.invalidatePrefix then
			GB.Cache.invalidatePrefix("res:enemy:")
		elseif GB.Cache and GB.Cache.invalidate then
			GB.Cache.invalidate("res:enemy:" .. tostring(target and target.Name or "?"))
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
			if GB.Resolver and GB.Resolver.isBinkiRequest and GB.Resolver.isBinkiRequest(want) then
				if GB.Resolver.isBinkiRequest(target.Name) then
					return true
				end
				if GB.Resolver.isBarrelName and (GB.Resolver.isBarrelName(target.Name) or GB.Resolver.isBarrelName(GB.Resolver.displayName(target))) then
					return true
				end
				local npc = target:GetAttribute("NPCName") or target:GetAttribute("DisplayName")
				if type(npc) == "string" and (string.find(npc, "Binki", 1, true) or string.find(npc, "Barrel Clown", 1, true)) then
					return true
				end
			end
			if context.Object and GB.Resolver then
				local ot = target:GetAttribute("ObjectType")
				if type(ot) == "string" and (ot == want or string.lower(ot) == string.lower(want)) then
					return true
				end
				local spec = GB.QuestData and GB.QuestData.objectSpec and GB.QuestData.objectSpec(want)
				local tags = { want }
				if spec and type(spec.Tags) == "table" then
					for _, t in ipairs(spec.Tags) do
						tags[#tags + 1] = t
					end
				end
				local cur = target
				while cur and cur ~= workspace do
					local cot = cur:GetAttribute("ObjectType")
					if type(cot) == "string" and (cot == want or string.lower(cot) == string.lower(want)) then
						return true
					end
					for _, tag in ipairs(tags) do
						local ok, hit = pcall(function()
							return cur:HasTag(tag)
						end)
						if ok and hit and (cur.Name == want or cot == want) then
							return true
						end
					end
					if cur.Name == want then
						return true
					end
					cur = cur.Parent
				end
				return false
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
		M.lastQuestDone = nil
		M.lastQuestCheck = 0
		M.lastQuestRefresh = 0
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

	function M.questCombatDone(questName, opts)
		opts = opts or {}
		questName = questName or M.lockQuest
		if not questName or not GB.Quest then
			return false
		end
		local now = os.clock()
		local force = opts.force == true
		if not force then
			if now - (M.lastQuestCheck or 0) < QUEST_CHECK_MIN_GAP then
				return false
			end
			local dirty = GB.PlayerData and GB.PlayerData.questDirty and GB.PlayerData.questDirty() or false
			if not dirty and now - (M.lastQuestRefresh or 0) < QUEST_CHECK_SAFETY then
				return false
			end
		end
		M.lastQuestCheck = now
		M.lastQuestRefresh = now
		perfCount("HeartbeatQuestCheck", 1)
		local t0 = pbegin()
		if GB.PlayerData and GB.PlayerData.refreshLive then
			GB.PlayerData.refreshLive(force, opts.source or "combat")
		end
		local cycleDone = GB.PlayerData and (GB.PlayerData.cycleFinished or GB.PlayerData.finished)
		if cycleDone and cycleDone(questName, true) then
			pdone("Combat Heartbeat slow path", t0)
			return true
		end
		local qs = GB.Quest.questState(questName)
		pdone("Combat Heartbeat slow path", t0)
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
		if GB.PlayerData and GB.PlayerData.forceQuestRefresh then
			GB.PlayerData.forceQuestRefresh("kill_credit")
		elseif GB.PlayerData and GB.PlayerData.refreshLive then
			GB.PlayerData.refreshLive(true, "kill_credit")
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
			local ok = M.logKillCredit(qn, before)
			if ok or M.questCombatDone(qn, { force = true, source = "target_dead" }) then
				M.lastQuestDone = qn
			end
		end
	end

	local function markerForPlan(plan)
		if type(plan) ~= "table" then
			return nil
		end
		local marker = plan.Marker
		if type(marker) ~= "string" or marker == "" then
			return nil
		end
		local pack = GB.Resolver.resolveMarker and GB.Resolver.resolveMarker(marker, { Island = plan.Island }) or nil
		if pack and pack.Instance then
			return pack.Instance
		end
		local byTag = GB.Resolver.taggedAny and GB.Resolver.taggedAny(marker)
		if byTag then
			return byTag
		end
		local byName = GB.Resolver.byName and GB.Resolver.byName(marker, "marker")
		return byName
	end

	local function findWorldTarget(name, plan)
		if GB.Resolver and GB.Resolver.findDestroyable then
			local obj = GB.Resolver.findDestroyable(name, { Island = plan and plan.Island })
			if obj and M.IsValidTarget(obj, { Name = name, Object = true }) then
				return obj
			end
		end
		if GB.Resolver and GB.Resolver.taggedAny then
			local tagged = GB.Resolver.taggedAny(name)
			if tagged and M.IsValidTarget(tagged, { Name = name, Object = true }) then
				if not (GB.Resolver.isMarkerTree and GB.Resolver.isMarkerTree(tagged)) then
					return tagged
				end
			end
		end
		return nil
	end

	function M.approachMarker(plan, targetName)
		local marker = markerForPlan(plan)
		if not marker then
			return false
		end
		local hrp = GB.World and GB.World.hrp and GB.World.hrp()
		local pos = GB.Resolver and GB.Resolver.positionOf and GB.Resolver.positionOf(marker)
		if hrp and pos then
			local dx = hrp.Position.X - pos.X
			local dz = hrp.Position.Z - pos.Z
			if math.sqrt(dx * dx + dz * dz) < 16 then
				return true
			end
		end
		local key = tostring(plan and plan.Marker or targetName)
		local now = os.clock()
		if M._markerAt and M._markerName == key and now - M._markerAt < 6.5 then
			return true
		end
		M._markerAt = now
		M._markerName = key
		if not M._markerLog or now - M._markerLog > 4 then
			M._markerLog = now
			GB.Log.log("COMBAT", "wait stream " .. tostring(targetName))
			GB.Log.log("TRAVEL", "marker " .. tostring(plan and plan.Marker or targetName))
		end
		if GB.World and GB.World.moveTo then
			GB.World.moveTo(marker, 10)
		end
		return true
	end

	function M.findTarget(name, questName, targetPlan)
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
		local obj = findWorldTarget(name, targetPlan)
		if obj then
			return obj
		end
		if GB.Resolver and GB.Resolver.findDisguisedEnemy then
			local hidden = GB.Resolver.findDisguisedEnemy(name)
			if hidden and M.IsValidTarget(hidden, { Name = name }) then
				return hidden
			end
		end
		local wantObject = (targetPlan and targetPlan.ObjectiveType == "Destroy")
			or (GB.QuestData and GB.QuestData.isObjectTarget and GB.QuestData.isObjectTarget(name))
		local hiddenKill = GB.Resolver and GB.Resolver.isBinkiRequest and GB.Resolver.isBinkiRequest(name)
		local skipBlock = type(targetPlan) == "table" and targetPlan.SkipStream == true
		if wantObject or hiddenKill or not skipBlock then
			M.approachMarker(targetPlan, name)
			local again = findWorldTarget(name, targetPlan)
			if again then
				GB.Log.log("COMBAT", tostring(name) .. " loaded")
				return again
			end
			if hiddenKill then
				again = GB.Resolver.findDisguisedEnemy and GB.Resolver.findDisguisedEnemy(name)
				if again and M.IsValidTarget(again, { Name = name }) then
					GB.Log.log("COMBAT", tostring(name) .. " revealed")
					return again
				end
				M.pokeReveal(name, targetPlan)
			end
		end
		return nil
	end

	function M.pokeReveal(name, plan)
		if not (GB.Resolver and GB.Resolver.isBinkiRequest and GB.Resolver.isBinkiRequest(name)) then
			return false
		end
		local now = os.clock()
		if M._pokeAt and now - M._pokeAt < 0.75 then
			return false
		end
		M._pokeAt = now
		local origin
		local hrp = GB.World and GB.World.hrp and GB.World.hrp()
		if hrp then
			origin = hrp.Position
		end
		if not origin then
			return false
		end
		local list = GB.Resolver.nearbyBarrelProps and GB.Resolver.nearbyBarrelProps(origin, 72) or {}
		if #list == 0 then
			M.approachMarker(plan, name)
			if not M._pokeLog or now - M._pokeLog > 4 then
				M._pokeLog = now
				GB.Log.log("COMBAT", "no barrel near " .. tostring(name))
			end
			return false
		end
		M._pokeI = (M._pokeI or 0) % #list + 1
		local barrel = list[M._pokeI].inst
		if not barrel then
			return false
		end
		if not M._pokeLog or now - M._pokeLog > 3 then
			M._pokeLog = now
			GB.Log.log("COMBAT", string.format("poke barrel %s d=%.0f", tostring(barrel.Name), list[M._pokeI].dist or 0))
		end
		if GB.World.ToEnemy then
			GB.World.ToEnemy(barrel, 4.2)
		elseif GB.World.moveTo then
			GB.World.moveTo(barrel, 5)
		end
		M.swing()
		return true
	end

	local function nameHits(inst, name)
		if not (inst and type(name) == "string" and name ~= "") then
			return false
		end
		if GB.Resolver and GB.Resolver.nameMatches and GB.Resolver.namesFor then
			return GB.Resolver.nameMatches(inst, GB.Resolver.namesFor(name, {})) == true
		end
		local n = inst.Name or ""
		return n == name or string.find(n, name, 1, true) ~= nil
	end

	function M.findNearestOf(names)
		if type(names) ~= "table" or #names == 0 then
			return nil, nil
		end
		M.pruneDeadCache()
		local origin
		local hrp = GB.World and GB.World.hrp and GB.World.hrp()
		if hrp then
			origin = hrp.Position
		end
		local best, bestName, bestD
		for _, raw in ipairs(names) do
			local name = GB.QuestData and GB.QuestData.killName and GB.QuestData.killName(nil, raw) or raw
			if type(name) == "string" and name ~= "" then
				local list = GB.Resolver and GB.Resolver.enemies and GB.Resolver.enemies(name)
				if type(list) == "table" then
					for _, inst in ipairs(list) do
						if M.IsValidTarget(inst, { Name = name }) then
							local pos = GB.Resolver.positionOf and GB.Resolver.positionOf(inst)
							local d = (origin and pos) and (pos - origin).Magnitude or 1e9
							if not bestD or d < bestD then
								best, bestName, bestD = inst, name, d
							end
						end
					end
				end
			end
		end
		return best, bestName, bestD
	end

	function M.lockMatchesNames(names)
		local mob = M.lockMob
		if not (mob and M.IsEnemyAlive(mob) and type(names) == "table") then
			return nil
		end
		for _, raw in ipairs(names) do
			local name = GB.QuestData and GB.QuestData.killName and GB.QuestData.killName(nil, raw) or raw
			if nameHits(mob, name) then
				return name
			end
		end
		return nil
	end

	function M.huntNearestOf(names, timeout, questOf, planOf)
		if type(names) ~= "table" or #names == 0 then
			return false, "no_names"
		end
		local lockedName = M.lockMatchesNames(names)
		local mob, name, dist
		if lockedName and M.lockMob then
			mob, name = M.lockMob, lockedName
		else
			mob, name, dist = M.findNearestOf(names)
		end
		if not (mob and name and M.IsEnemyAlive(mob)) then
			return false, "no_enemy"
		end
		local qn = type(questOf) == "table" and questOf[name] or nil
		if type(dist) == "number" and (not M._nearLog or os.clock() - M._nearLog > 2.4) then
			M._nearLog = os.clock()
			GB.Log.log("COMBAT", string.format("nearest %s d=%.0f quest=%s", tostring(name), dist, tostring(qn or "-")))
		end
		local plan = (type(planOf) == "table" and planOf[name]) or {}
		plan.Target = name
		plan.Quest = qn or plan.Quest
		plan.Instance = mob
		plan.SkipStream = true
		if timeout == 0 or timeout == false then
			local ok = M.hunt(name, qn, plan)
			return ok == true, ok and "engaged" or "travel"
		end
		return M.huntUntilDead(name, timeout or 16, qn, plan)
	end

	function M.engageNearestOf(names, questOf, planOf)
		return M.huntNearestOf(names, 0, questOf, planOf)
	end

	local function standDest(mob)
		local part = GB.Resolver.part(mob)
		if not (part and part:IsA("BasePart")) then
			return nil
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
		if not GB.World.destOk(dest) then
			dest = part.Position + Vector3.new(GB.Config.DummyBeside or 3.2, 0, 0)
		end
		if GB.World.floorAt then
			dest = GB.World.floorAt(dest, part.Position.Y) or Vector3.new(dest.X, part.Position.Y, dest.Z)
		end
		return dest, part
	end

	function M.needReposition(mob)
		if not M.IsEnemyAlive(mob) then
			return false
		end
		local root = GB.World.hrp()
		local dest, part = standDest(mob)
		if not (root and dest and part) then
			return false
		end
		local moved = M.lastTargetPos and (M.lastTargetPos - part.Position).Magnitude or 99
		if GB.World.tweenPlaying and GB.World.tweenPlaying() then
			return moved > TARGET_MOVED
		end
		local far = (root.Position - dest).Magnitude > REPOS_DIST
		return far or moved > TARGET_MOVED
	end

	function M.standPose(mob)
		if not M.IsEnemyAlive(mob) then
			return false
		end
		local root = GB.World.hrp()
		local dest, part = standDest(mob)
		if not (root and dest and part) then
			return false
		end
		M.lastTargetPos = part.Position
		M.lastStandAt = os.clock()
		if (root.Position - dest).Magnitude <= 2.2 then
			root.CFrame = CFrame.new(root.Position, Vector3.new(part.Position.X, root.Position.Y, part.Position.Z))
			return true
		end
		if GB.World.tweenTo then
			return GB.World.tweenTo(dest, part.Position, { wait = false, range = 2.2 })
		end
		root.CFrame = CFrame.new(dest, Vector3.new(part.Position.X, dest.Y, part.Position.Z))
		return true
	end

	function M.swing()
		local c = GB.World.char()
		if not c then
			return
		end
		if GB.Respawn and GB.Respawn.isBusy and GB.Respawn.isBusy() then
			return
		end
		if os.clock() - M.lastSwing < M.minSwingInterval() then
			return
		end
		if not M.canSwing(c) then
			return
		end
		if M.lockMob and not M.IsEnemyAlive(M.lockMob) then
			return
		end
		if M.lockMob then
			local root = GB.World.hrp and GB.World.hrp()
			local part = GB.Resolver and GB.Resolver.part and GB.Resolver.part(M.lockMob) or nil
			if root and part and part:IsA("BasePart") then
				local maxRange = (GB.Config.CombatRange or 5.5) + SWING_RANGE_PAD
				local maxApproach = maxRange + APPROACH_SWING_PAD
				local dist = (root.Position - part.Position).Magnitude
				if dist > maxApproach then
					return
				end
				local moving = GB.World.tweenPlaying and GB.World.tweenPlaying()
				if dist > maxRange and not moving then
					return
				end
				if dist > maxRange and moving then
					if os.clock() - (M.lastApproachSwing or 0) < APPROACH_SWING_GAP then
						return
					end
					M.lastApproachSwing = os.clock()
				elseif dist <= maxRange then
					M.lastApproachSwing = 0
				end
			end
		end
		M.lastSwing = os.clock()
		local atk = loadAttack()
		if atk and atk.Swing then
			atk.Swing(c)
		end
		local accepted = M.canSwing(c) ~= true
		noteSwing(accepted)
		if accepted then
			M._noCredit = 0
		else
			M._noCredit = (M._noCredit or 0) + 1
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
			if GB.Profiler and GB.Profiler.count then
				GB.Profiler.count("HeartbeatCallbacks", 1)
			end
			if GB.dead and GB.dead() then
				M.stopLock()
				return
			end
			if GB.Respawn and GB.Respawn.isBusy and GB.Respawn.isBusy() then
				M.stopLock()
				return
			end
			local snap = GB.State and GB.State.get and GB.State.get()
			if snap and snap.Alive == false then
				M.stopLock()
				return
			end
			if GB.Quest and GB.Quest.dialogueOpen and GB.Quest.dialogueOpen() then
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
			if M.needReposition(mob2) then
				M.standPose(mob2)
			end
			if M.IsEnemyAlive(mob2) then
				local hp = M.readHealth(mob2)
				if hp and M._hpBefore and hp < M._hpBefore then
					M._tel.damage = (M._tel.damage or 0) + 1
					M._noCredit = 0
				end
				M._hpBefore = hp
				M.swing()
			else
				M.onTargetDead(mob2, "post-swing")
			end
		end)
	end

	function M.hunt(name, questName, targetPlan)
		local objectHunt = (type(targetPlan) == "table" and (targetPlan.Object == true or targetPlan.ObjectiveType == "Destroy"))
			or (GB.QuestData and GB.QuestData.isObjectTarget and GB.QuestData.isObjectTarget(name))
		local ctx = { Name = name, Object = objectHunt == true }
		local preset = type(targetPlan) == "table" and targetPlan.Instance or nil
		local mob = (preset and M.IsValidTarget(preset, ctx) and preset) or M.findTarget(name, questName, targetPlan)
		if not mob then
			return false
		end
		if not M.IsValidTarget(mob, ctx) then
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

	function M.huntUntilDead(name, timeout, questName, targetPlan)
		timeout = timeout or 14
		if questName and GB.Quest then
			local qs = GB.Quest.questState(questName)
			M.lastKillBefore = qs and qs.Objective and {
				Current = qs.Objective.Current or 0,
				Amount = qs.Objective.Amount or 1,
				StageIndex = qs.StageIndex,
			} or nil
		end
		local preset = type(targetPlan) == "table" and targetPlan.Instance or nil
		local mob = (preset and M.IsEnemyAlive(preset) and preset) or M.findTarget(name, questName, targetPlan)
		if (not M.IsEnemyAlive(mob)) and type(targetPlan) == "table" and type(targetPlan.Alternatives) == "table" then
			for _, alt in ipairs(targetPlan.Alternatives) do
				if type(alt) == "string" and alt ~= "" and alt ~= name then
					local altPlan = {
						Quest = targetPlan.Quest,
						Target = alt,
						Island = targetPlan.Island,
						Marker = GB.QuestData and GB.QuestData.combatMarker and GB.QuestData.combatMarker(
							questName,
							targetPlan.Stage,
							targetPlan.ObjectiveType,
							alt
						) or targetPlan.Marker,
					}
					local altMob = M.findTarget(alt, questName, altPlan)
					if M.IsEnemyAlive(altMob) then
						name = alt
						targetPlan = altPlan
						mob = altMob
						break
					end
				end
			end
		end
		if not M.IsEnemyAlive(mob) then
			return false, "no_enemy"
		end
		if not M.hunt(name, questName, targetPlan) then
			return false, "travel"
		end
		local t0 = os.clock()
		local tracked = M.lockMob or mob
		while os.clock() - t0 < timeout do
			if GB.Respawn and GB.Respawn.isBusy and GB.Respawn.isBusy() then
				M.stopLock()
				return false, "respawn"
			end
			if questName and M.lastQuestDone == questName then
				M.stopLock()
				return true, "quest_done"
			end
			if questName and not M.lockConn and M.questCombatDone(questName, { source = "hunt", force = true }) then
				M.lastQuestDone = questName
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
		if GB.World.floorAt then
			dest = GB.World.floorAt(dest, part.Position.Y) or Vector3.new(dest.X, part.Position.Y, dest.Z)
		end
		if GB.World.tweenTo then
			GB.World.tweenTo(dest, part.Position, { wait = false, range = 2.5 })
		else
			root.CFrame = CFrame.new(dest, Vector3.new(part.Position.X, dest.Y, part.Position.Z))
		end
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
		if GB.PlayerData.cycleFinished and GB.PlayerData.cycleFinished(questName, true) then
			return true
		elseif (not GB.PlayerData.cycleFinished) and GB.PlayerData.finished(questName, true) then
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
			elseif M.lockQuest and M.questCombatDone(M.lockQuest, { source = "combat_tick" }) then
				M.lastQuestDone = M.lockQuest
				M.stopLock()
			end
		end
	end

	return M
end
