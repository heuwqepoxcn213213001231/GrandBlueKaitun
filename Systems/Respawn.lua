-- Death / revive lifecycle. One CharacterAdded + one Humanoid.Died.
-- Revive uses the same client UI/remote path as a normal player. No fake local alive.

return function(GB)
	local Players = game:GetService("Players")
	local M = {
		phase = "ALIVE",
		_bound = false,
		_humDied = nil,
		_charAdded = nil,
		_charRemoving = nil,
		_ctx = nil,
		_deathAt = 0,
		_reviveAt = 0,
		_charToken = 0,
		_lastClick = 0,
		_lastRemote = 0,
		_readyAt = 0,
	}

	local PHASE = {
		ALIVE = "ALIVE",
		DYING = "DYING",
		DEAD = "DEAD",
		REVIVE_UI = "REVIVE_UI",
		RESPAWNING = "RESPAWNING",
		CHARACTER_LOADING = "CHARACTER_LOADING",
		RESTORE_CONTEXT = "RESTORE_CONTEXT",
	}

	local DEATH_GUI = {
		"DeathScreen",
		"Death",
		"YouDied",
		"You Died",
		"Dead",
		"DeathUI",
		"DeathGui",
		"Respawn",
		"Revive",
	}

	local REVIVE_BTN = {
		"Respawn",
		"Revive",
		"Retry",
		"Continue",
		"Return",
		"Spawn",
		"RespawnButton",
		"ReviveButton",
		"Play",
	}

	local function log(msg)
		if GB.Log and GB.Log.log then
			GB.Log.log("RESPAWN", msg)
		end
	end

	local function warn(msg)
		if GB.Log and GB.Log.warn then
			GB.Log.warn("RESPAWN", msg)
		end
	end

	local function deathLog(msg)
		if GB.Log and GB.Log.log then
			GB.Log.log("DEATH", msg)
		end
	end

	function M.aliveNow()
		local lp = GB.lp
		local char = lp and lp.Character
		if not char or not char.Parent then
			return false
		end
		if char:GetAttribute("Dead") == true then
			return false
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then
			return false
		end
		if GB.Combat and GB.Combat.hasDeadFlag and GB.Combat.hasDeadFlag(char) then
			return false
		end
		return char:FindFirstChild("HumanoidRootPart") ~= nil
	end

	function M.isBusy()
		return M.phase ~= PHASE.ALIVE
	end

	function M.currentPhase()
		return M.phase
	end

	function M.context()
		return M._ctx
	end

	local function snapshotContext()
		local qs, obj
		local qn = GB.PlayerData and GB.PlayerData.current and GB.PlayerData.current()
		if qn and GB.Quest and GB.Quest.questState then
			qs = GB.Quest.questState(qn)
			obj = qs and qs.Objective
		end
		local island = (qs and qs.Island)
			or (GB.State and GB.State.snap and GB.State.snap.CurrentIsland)
		local goal = GB.Engine and (GB.Engine.task or (GB.Engine.goal and GB.Engine.goal.Note))
		M._ctx = {
			At = os.clock(),
			Goal = goal,
			Quest = qn,
			Stage = qs and qs.StageIndex,
			Objective = obj and obj.Type,
			Target = obj and obj.TargetName,
			Island = island,
			Farm = GB.Engine and GB.Engine.goal and GB.Engine.goal.Note,
		}
		if GB.Persist and GB.Persist.data and type(GB.Persist.data.checkpoint) == "table" then
			local ck = GB.Persist.data.checkpoint
			ck.quest = qn
			ck.stage = M._ctx.Stage
			ck.objective = M._ctx.Objective
			ck.target = M._ctx.Target
			ck.island = island
			ck.goal = goal
			ck.respawn = {
				quest = qn,
				stage = M._ctx.Stage,
				objective = M._ctx.Objective,
				target = M._ctx.Target,
				island = island,
				goal = goal,
			}
			if GB.Persist.save then
				GB.Persist.save()
			end
		end
		return M._ctx
	end

	local function releaseActions()
		if GB.Combat and GB.Combat.stopLock then
			pcall(GB.Combat.stopLock)
		end
		if GB.World and GB.World.cancelTween then
			pcall(GB.World.cancelTween)
		end
	end

	local function setPhase(next)
		if M.phase == next then
			return
		end
		M.phase = next
		log(string.lower(next))
	end

	function M.onDeath(reason)
		if M.phase ~= PHASE.ALIVE and M.phase ~= PHASE.DYING then
			return
		end
		setPhase(PHASE.DYING)
		M._deathAt = os.clock()
		deathLog(tostring(reason or "dead"))
		snapshotContext()
		releaseActions()
		setPhase(PHASE.DEAD)
	end

	local function disconnectHum()
		if M._humDied then
			pcall(function()
				M._humDied:Disconnect()
			end)
			M._humDied = nil
		end
	end

	local function bindHumanoid(char)
		disconnectHum()
		if not char then
			return
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then
			return
		end
		M._humDied = hum.Died:Connect(function()
			M.onDeath("humanoid died")
		end)
		if GB.conns then
			GB.conns[#GB.conns + 1] = M._humDied
		end
	end

	local function pg()
		return GB.lp and GB.lp:FindFirstChild("PlayerGui")
	end

	local function findDeathGui()
		local root = pg()
		if not root then
			return nil
		end
		for _, name in ipairs(DEATH_GUI) do
			local ui = root:FindFirstChild(name)
			if ui and ui.Parent then
				if ui:IsA("LayerCollector") then
					if ui.Enabled == true then
						return ui
					end
				else
					return ui
				end
			end
		end
		for _, ui in ipairs(root:GetChildren()) do
			local nm = string.lower(tostring(ui.Name or ""))
			if string.find(nm, "death", 1, true) or string.find(nm, "died", 1, true) or string.find(nm, "respawn", 1, true) or string.find(nm, "revive", 1, true) then
				if ui:IsA("LayerCollector") then
					if ui.Enabled == true then
						return ui
					end
				else
					return ui
				end
			end
		end
		return nil
	end

	local function findReviveButton(ui)
		if not ui then
			return nil
		end
		for _, name in ipairs(REVIVE_BTN) do
			local btn = ui:FindFirstChild(name, true)
			if btn and btn:IsA("GuiButton") then
				return btn
			end
		end
		return ui:FindFirstChildWhichIsA("GuiButton", true)
	end

	local function fireDeathRemote()
		local now = os.clock()
		if now - (M._lastRemote or 0) < 1.4 then
			return false
		end
		M._lastRemote = now
		local ev = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
		local rf = ev and ev:FindFirstChild("DeathScreen")
		if not (rf and rf:IsA("RemoteFunction")) then
			return false
		end
		warn("activating DeathScreen remote")
		pcall(function()
			rf:InvokeServer()
		end)
		return true
	end

	function M.GetReviveAction()
		local ui = findDeathGui()
		if ui then
			local btn = findReviveButton(ui)
			if btn then
				return {
					Kind = "button",
					Gui = ui,
					Button = btn,
					Name = ui.Name .. "." .. btn.Name,
				}
			end
			return { Kind = "gui", Gui = ui, Name = ui.Name }
		end
		local ev = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
		if ev and ev:FindFirstChild("DeathScreen") then
			return { Kind = "remote", Name = "Events.DeathScreen" }
		end
		return nil
	end

	function M.ExecuteRevive()
		local action = M.GetReviveAction()
		if not action then
			return false
		end
		local now = os.clock()
		if now - (M._lastClick or 0) < 0.85 then
			return false
		end
		M._lastClick = now
		if action.Kind == "button" and GB.State and GB.State.clickGui then
			warn("activating " .. tostring(action.Name))
			return GB.State.clickGui(action.Button) == true
		end
		if action.Kind == "gui" and GB.State and GB.State.invokeContinueInput then
			warn("activating overlay " .. tostring(action.Name))
			local ok = GB.State.invokeContinueInput(action.Gui, "owner")
			return ok == true
		end
		if action.Kind == "remote" then
			return fireDeathRemote()
		end
		return false
	end

	function M.WaitCharacter()
		return M.aliveNow()
	end

	local function restore()
		if M.phase == PHASE.ALIVE and os.clock() - (M._readyAt or 0) < 0.8 then
			return
		end
		if GB.Cache and GB.Cache.invalidatePrefix then
			GB.Cache.invalidatePrefix("res:enemy:")
		end
		if GB.Remotes and GB.Remotes.statReplicate then
			pcall(GB.Remotes.statReplicate)
		end
		if GB.Equipment and GB.Equipment.tick then
			pcall(GB.Equipment.tick)
		end
		if GB.PlayerData and GB.PlayerData.forceQuestRefresh then
			GB.PlayerData.forceQuestRefresh("respawn")
		elseif GB.PlayerData and GB.PlayerData.refreshLive then
			GB.PlayerData.refreshLive(true, "respawn")
		end
		local ctx = M._ctx
		local label = (ctx and (ctx.Quest or ctx.Goal)) or "progression"
		if GB.Log and GB.Log.log then
			GB.Log.log("STATE", "resuming " .. tostring(label))
		end
		if GB.State and GB.State.track then
			GB.State.track.TaskStartedAt = os.clock()
			GB.State.track.SuccessfulAction = os.clock()
		end
		if GB.Recovery and GB.Recovery.markSuccess then
			GB.Recovery.markSuccess()
		end
		M._readyAt = os.clock()
		setPhase(PHASE.ALIVE)
	end

	function M.Restore()
		restore()
	end

	function M.Detect()
		if M.aliveNow() then
			return false
		end
		if M.phase == PHASE.ALIVE then
			M.onDeath("detect")
		end
		return true
	end

	function M.tick()
		if GB.dead and GB.dead() then
			return
		end
		if M.phase == PHASE.ALIVE then
			if not M.aliveNow() then
				M.onDeath("tick")
			end
			return
		end
		if M.aliveNow() then
			if M.phase == PHASE.RESTORE_CONTEXT then
				restore()
				return
			end
			if M.phase == PHASE.CHARACTER_LOADING or M.phase == PHASE.RESPAWNING or M.phase == PHASE.REVIVE_UI or M.phase == PHASE.DEAD then
				setPhase(PHASE.RESTORE_CONTEXT)
				restore()
				return
			end
		end
		if M.phase == PHASE.DEAD or M.phase == PHASE.REVIVE_UI then
			local action = M.GetReviveAction()
			if action then
				if M.phase == PHASE.DEAD then
					warn("death screen detected")
					setPhase(PHASE.REVIVE_UI)
				end
				if M.ExecuteRevive() then
					setPhase(PHASE.RESPAWNING)
				end
			else
				fireDeathRemote()
			end
			return
		end
		if M.phase == PHASE.RESPAWNING or M.phase == PHASE.CHARACTER_LOADING then
			if os.clock() - (M._lastClick or 0) > 2.4 then
				M.ExecuteRevive()
			end
		end
	end

	function M.onCharacterAdded(char)
		M._charToken = M._charToken + 1
		setPhase(PHASE.CHARACTER_LOADING)
		log("new character")
		releaseActions()
		bindHumanoid(char)
		task.defer(function()
			local t0 = os.clock()
			while os.clock() - t0 < 6 and not M.aliveNow() do
				task.wait(0.12)
			end
			if M.aliveNow() then
				log("character ready")
				setPhase(PHASE.RESTORE_CONTEXT)
				restore()
			end
		end)
	end

	function M.bind()
		if M._bound then
			return
		end
		M._bound = true
		local lp = GB.lp or Players.LocalPlayer
		if not lp then
			return
		end
		if lp.Character then
			bindHumanoid(lp.Character)
			if not M.aliveNow() then
				M.onDeath("boot dead")
			end
		end
		M._charAdded = lp.CharacterAdded:Connect(function(char)
			if GB.dead and GB.dead() then
				return
			end
			M.onCharacterAdded(char)
		end)
		M._charRemoving = lp.CharacterRemoving:Connect(function(char)
			if GB.dead and GB.dead() then
				return
			end
			if M.phase ~= PHASE.ALIVE then
				return
			end
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if (hum and hum.Health <= 0) or (char and char:GetAttribute("Dead") == true) then
				M.onDeath("character removed")
			end
		end)
		if GB.conns then
			GB.conns[#GB.conns + 1] = M._charAdded
			GB.conns[#GB.conns + 1] = M._charRemoving
		end
	end

	function M.unbind()
		disconnectHum()
		if M._charAdded then
			pcall(function()
				M._charAdded:Disconnect()
			end)
			M._charAdded = nil
		end
		if M._charRemoving then
			pcall(function()
				M._charRemoving:Disconnect()
			end)
			M._charRemoving = nil
		end
		M._bound = false
	end

	function M.connectionCounts()
		return {
			CharacterAdded = M._charAdded ~= nil,
			CharacterRemoving = M._charRemoving ~= nil,
			HumanoidDied = M._humDied ~= nil,
			Phase = M.phase,
		}
	end

	return M
end
