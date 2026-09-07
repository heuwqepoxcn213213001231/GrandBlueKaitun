-- Islands, move, destOk, groundAt, water/void rescue.

return function(GB)
	local M = {
		lastSafe = nil,
		anchorSafe = nil,
	}

	local ISLANDS = { "Anchor Town", "Clown Town", "Maple Village" }

	function M.char()
		return GB.lp and GB.lp.Character
	end

	function M.hrp()
		local c = M.char()
		return c and (c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart)
	end

	function M.hum()
		local c = M.char()
		return c and c:FindFirstChildOfClass("Humanoid")
	end

	function M.waterY()
		return workspace.FallenPartsDestroyHeight and math.max(workspace.FallenPartsDestroyHeight + 20, 0) or 0
	end

	function M.destOk(pos)
		if typeof(pos) ~= "Vector3" then
			return false
		end
		local y = pos.Y
		if y < (GB.Config.DestYMin or 8) or y > (GB.Config.DestYMax or 180) then
			return false
		end
		return true
	end

	function M.groundAt(pos)
		if typeof(pos) ~= "Vector3" then
			return nil
		end
		local origin = Vector3.new(pos.X, pos.Y + 40, pos.Z)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local c = M.char()
		params.FilterDescendantsInstances = c and { c } or {}
		local hit = workspace:Raycast(origin, Vector3.new(0, -220, 0), params)
		if not hit then
			return nil
		end
		if hit.Material == Enum.Material.Water then
			return nil
		end
		if hit.Instance and string.find(string.lower(hit.Instance.Name), "water", 1, true) then
			return nil
		end
		local p = hit.Position + Vector3.new(0, 4, 0)
		if not M.destOk(p) then
			return nil
		end
		return p
	end

	function M.rememberSafe()
		local root = M.hrp()
		if not root then
			return
		end
		local y = root.Position.Y
		if y > M.waterY() + 10 and y < 250 and M.destOk(root.Position) then
			M.lastSafe = root.CFrame
		end
	end

	function M.ensureAnchorSafe()
		if M.anchorSafe then
			return
		end
		local g = GB.Resolver.npc("Officer Graves [2]")
		local p = g and GB.Resolver.part(g)
		if p then
			M.anchorSafe = CFrame.new(p.Position + Vector3.new(0, 0, 6))
		end
	end

	function M.rescue()
		local root = M.hrp()
		if not root then
			return
		end
		local y = root.Position.Y
		local wet = y < M.waterY() + 8 or y < (GB.Config.DestYMin or 8) - 2 or y > 240
		if not wet then
			M.rememberSafe()
			return
		end
		M.ensureAnchorSafe()
		local dest = M.lastSafe or M.anchorSafe
		if not dest then
			return
		end
		if GB.Combat then
			pcall(GB.Combat.stopLock)
		end
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = dest
		GB.Log.warn("TRAVEL", "rescue swim/void")
		GB.Recovery.markSuccess()
	end

	function M.goSafe()
		M.ensureAnchorSafe()
		local root = M.hrp()
		local dest = M.lastSafe or M.anchorSafe
		if root and dest then
			root.CFrame = dest
		end
	end

	function M.waitUnpause()
		local t = os.clock()
		while GB.lp and GB.lp:GetAttribute("GameplayPaused") and os.clock() - t < 12 do
			task.wait(0.2)
		end
	end

	function M.setPos(cf)
		local root = M.hrp()
		if not root then
			return false
		end
		local pos = typeof(cf) == "CFrame" and cf.Position or cf
		if not M.destOk(pos) then
			return false
		end
		local g = M.groundAt(pos)
		if g then
			root.CFrame = CFrame.new(g)
		else
			root.CFrame = typeof(cf) == "CFrame" and cf or CFrame.new(pos)
		end
		M.rememberSafe()
		return true
	end

	function M.moveTo(instOrPos, range)
		range = range or 6
		local root = M.hrp()
		local hum = M.hum()
		if not root then
			return false
		end
		local pos
		if typeof(instOrPos) == "Vector3" then
			pos = instOrPos
		elseif typeof(instOrPos) == "CFrame" then
			pos = instOrPos.Position
		else
			local p = GB.Resolver.part(instOrPos)
			pos = p and p.Position
		end
		if not pos then
			return false
		end
		if not M.destOk(pos) then
			local g = M.groundAt(pos)
			if not g then
				return false
			end
			pos = g
		end
		local dist = (root.Position - pos).Magnitude
		if dist <= range then
			return true
		end
		M.waitUnpause()
		if dist > 220 then
			local hop = GB.Config.MoveHop or 45
			local dir = (pos - root.Position)
			dir = Vector3.new(dir.X, 0, dir.Z)
			if dir.Magnitude < 1 then
				return M.setPos(pos)
			end
			local step = root.Position + dir.Unit * math.min(hop, dist - range)
			step = Vector3.new(step.X, pos.Y, step.Z)
			M.setPos(step)
			return (root.Position - pos).Magnitude <= range
		end
		if hum then
			hum:MoveTo(pos)
		end
		if dist > 40 then
			M.setPos(pos + Vector3.new(0, 0, 0))
		end
		return (root.Position - pos).Magnitude <= range + 4
	end

	function M.islandFromProgress(snap)
		snap = snap or GB.State.get()
		if not GB.PlayerData.finished("Setting Sail") then
			return "Anchor Town"
		end
		if not GB.PlayerData.finished("Journey to Maple Village") then
			return "Clown Town"
		end
		return "Maple Village"
	end

	function M.islandFromPosition(pos)
		if typeof(pos) ~= "Vector3" then
			return nil
		end
		local isles = workspace:FindFirstChild("Islands")
		if not isles then
			return nil
		end
		local best, bestD
		for _, name in ipairs(ISLANDS) do
			local isl = isles:FindFirstChild(name)
			local p = isl and (isl.PrimaryPart or isl:FindFirstChildWhichIsA("BasePart", true))
			if p then
				local d = (p.Position - pos).Magnitude
				if not bestD or d < bestD then
					best, bestD = name, d
				end
			end
		end
		return best
	end

	function M.islandSpawn(name)
		local isl = GB.Resolver.island(name)
		if not isl then
			return nil
		end
		local sp = isl:FindFirstChild("SpawnLocations") or isl:FindFirstChild("SpawnLocation", true)
		if sp then
			if sp:IsA("SpawnLocation") or sp:IsA("BasePart") then
				return sp.Position
			end
			local p = sp:FindFirstChildWhichIsA("BasePart", true)
			if p then
				return p.Position
			end
		end
		local p = isl.PrimaryPart or isl:FindFirstChildWhichIsA("BasePart", true)
		return p and p.Position
	end

	return M
end
