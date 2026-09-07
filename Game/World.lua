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
		if not c then
			return nil
		end
		local hrp = c:FindFirstChild("HumanoidRootPart")
		if hrp then
			return hrp
		end
		if c:IsA("Model") then
			return c.PrimaryPart
		end
		return nil
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
		local g = GB.Resolver.npc("Officer Graves") or GB.Resolver.npc("Officer Graves [2]")
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
			if GB.State and GB.State.dismissTutorialOverlay then
				GB.State.dismissTutorialOverlay()
			end
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

	local geoCache = {}
	local geoLogged = {}

	local function isPart(inst)
		return inst and inst:IsA("BasePart")
	end

	local function isModel(inst)
		return inst and inst:IsA("Model")
	end

	local function modelPivot(inst)
		if not isModel(inst) then
			return nil
		end
		local ok, cf = pcall(inst.GetPivot, inst)
		if ok and typeof(cf) == "CFrame" then
			return cf
		end
		return nil
	end

	local function modelBoundingBox(inst)
		if not isModel(inst) then
			return nil
		end
		local ok, cf, size = pcall(inst.GetBoundingBox, inst)
		if ok and typeof(cf) == "CFrame" and typeof(size) == "Vector3" then
			return cf, size
		end
		return nil
	end

	local function instancePosition(inst)
		if not inst then
			return nil
		end
		if isPart(inst) then
			return inst.Position
		end
		if isModel(inst) then
			local pp = inst.PrimaryPart
			if pp then
				return pp.Position
			end
			local pivot = modelPivot(inst)
			if pivot then
				return pivot.Position
			end
		end
		return nil
	end

	local function resolveIslandInst(island)
		if typeof(island) == "Instance" then
			return island
		end
		if type(island) ~= "string" or island == "" then
			return nil
		end
		if GB.Resolver and GB.Resolver.island then
			return GB.Resolver.island(island)
		end
		local isles = workspace:FindFirstChild("Islands")
		return isles and isles:FindFirstChild(island)
	end

	local function aabbFromCenterSize(center, size)
		local h = size * 0.5
		return center - h, center + h
	end

	local function aabbFromRadius(center, radius)
		local r = Vector3.new(radius, math.max(radius * 0.35, 120), radius)
		return center - r, center + r
	end

	local function aabbContains(minV, maxV, pos, pad)
		pad = pad or 0
		return pos.X >= minV.X - pad
			and pos.X <= maxV.X + pad
			and pos.Y >= minV.Y - pad
			and pos.Y <= maxV.Y + pad
			and pos.Z >= minV.Z - pad
			and pos.Z <= maxV.Z + pad
	end

	local function median(t)
		local n = #t
		if n == 0 then
			return 0
		end
		table.sort(t)
		if n % 2 == 1 then
			return t[(n + 1) / 2]
		end
		return (t[n / 2] + t[n / 2 + 1]) / 2
	end

	local function harvestIslandFolder(folder)
		local samples = {}
		for _, c in ipairs(folder:GetChildren()) do
			if isPart(c) then
				local vol = math.abs(c.Size.X * c.Size.Y * c.Size.Z)
				if vol >= 200 then
					samples[#samples + 1] = { pos = c.Position, size = c.Size }
				end
			elseif isModel(c) then
				local cf, size = modelBoundingBox(c)
				if cf and size then
					local vol = math.abs(size.X * size.Y * size.Z)
					if vol >= 200 then
						samples[#samples + 1] = { pos = cf.Position, size = size }
					end
				end
			end
		end
		return samples
	end

	local function samplesToGeo(samples)
		if #samples == 0 then
			return nil
		end
		local xs, ys, zs = {}, {}, {}
		for i, s in ipairs(samples) do
			xs[i], ys[i], zs[i] = s.pos.X, s.pos.Y, s.pos.Z
		end
		local mid = Vector3.new(median(xs), median(ys), median(zs))
		local used = {}
		for _, s in ipairs(samples) do
			local dx = s.pos.X - mid.X
			local dz = s.pos.Z - mid.Z
			if math.sqrt(dx * dx + dz * dz) < 900 then
				used[#used + 1] = s
			end
		end
		if #used < 3 then
			used = samples
		end
		local minV, maxV
		local sx, sy, sz, n = 0, 0, 0, 0
		for _, s in ipairs(used) do
			local p = s.pos
			sx, sy, sz, n = sx + p.X, sy + p.Y, sz + p.Z, n + 1
			local half = s.size and (s.size * 0.5) or Vector3.new(4, 4, 4)
			local a, b = p - half, p + half
			if not minV then
				minV, maxV = a, b
			else
				minV = Vector3.new(math.min(minV.X, a.X), math.min(minV.Y, a.Y), math.min(minV.Z, a.Z))
				maxV = Vector3.new(math.max(maxV.X, b.X), math.max(maxV.Y, b.Y), math.max(maxV.Z, b.Z))
			end
		end
		return Vector3.new(sx / n, sy / n, sz / n), minV, maxV, n
	end

	local function countParts(inst)
		local n = 0
		if not inst then
			return 0
		end
		for _, d in ipairs(inst:GetDescendants()) do
			if isPart(d) then
				n = n + 1
			end
		end
		return n
	end

	local function usablePos(pos)
		if typeof(pos) ~= "Vector3" then
			return nil
		end
		if M.destOk(pos) then
			return pos
		end
		local ymin = (GB.Config and GB.Config.DestYMin) or 8
		local ymax = (GB.Config and GB.Config.DestYMax) or 180
		local y = pos.Y
		if y < ymin then
			y = ymin + 4
		elseif y > ymax then
			y = ymax
		end
		return Vector3.new(pos.X, y, pos.Z)
	end

	local function computeGeo(island)
		local islandChild = island:FindFirstChild("Island")
		local islandKids = islandChild and #islandChild:GetChildren() or 0

		if isPart(island) then
			local minV, maxV = aabbFromCenterSize(island.Position, island.Size)
			return {
				pos = island.Position,
				min = minV,
				max = maxV,
				center = island.Position,
				method = "BasePart",
				parts = 1,
				islandKids = islandKids,
			}
		end

		if isModel(island) then
			local pos = instancePosition(island)
			local cf, size = modelBoundingBox(island)
			if cf and size then
				local minV, maxV = aabbFromCenterSize(cf.Position, size)
				local method = "Model.GetBoundingBox"
				if island.PrimaryPart then
					method = "Model.PrimaryPart"
				end
				return {
					pos = pos or cf.Position,
					min = minV,
					max = maxV,
					center = cf.Position,
					method = method,
					parts = 1,
					islandKids = islandKids,
				}
			end
			if pos then
				local pad = Vector3.new(80, 80, 80)
				return {
					pos = pos,
					min = pos - pad,
					max = pos + pad,
					center = pos,
					method = "Model.GetPivot",
					parts = 1,
					islandKids = islandKids,
				}
			end
		end

		local spawn
		local spawnRoot = island:FindFirstChild("SpawnLocations")
		if spawnRoot then
			for _, d in ipairs(spawnRoot:GetDescendants()) do
				if d:IsA("SpawnLocation") or isPart(d) then
					spawn = d
					break
				end
			end
		end
		if not spawn then
			for _, c in ipairs(island:GetChildren()) do
				if c:IsA("SpawnLocation") or (c.Name == "Spawn" and isPart(c)) then
					spawn = c
					break
				end
			end
		end

		local paPos, paRadius
		local pa = island:FindFirstChild("PersistentAnchor")
		if pa then
			local center = pa:FindFirstChild("Center")
			if isPart(center) then
				paPos = center.Position
			elseif isModel(pa) then
				paPos = instancePosition(pa)
			elseif isPart(pa) then
				paPos = pa.Position
			end
			local r = pa:FindFirstChild("Radius")
			if r and r:IsA("ValueBase") then
				paRadius = tonumber(r.Value)
			end
		end

		local persPos, persSize
		local cons = island:FindFirstChild("Constants")
		local pers = cons and cons:FindFirstChild("Persistent")
		if pers then
			if isModel(pers) then
				local cf, size = modelBoundingBox(pers)
				if cf then
					persPos, persSize = cf.Position, size
				else
					persPos = instancePosition(pers)
				end
			elseif isPart(pers) then
				persPos, persSize = pers.Position, pers.Size
			end
		end

		local samplePos, sampleMin, sampleMax, sampleN
		if islandChild then
			if isPart(islandChild) then
				samplePos = islandChild.Position
				sampleMin, sampleMax = aabbFromCenterSize(islandChild.Position, islandChild.Size)
				sampleN = 1
			elseif isModel(islandChild) then
				local cf, size = modelBoundingBox(islandChild)
				samplePos = instancePosition(islandChild) or (cf and cf.Position)
				if cf and size then
					sampleMin, sampleMax = aabbFromCenterSize(cf.Position, size)
					sampleN = 1
				end
			else
				local samples = harvestIslandFolder(islandChild)
				if #samples > 0 then
					samplePos, sampleMin, sampleMax, sampleN = samplesToGeo(samples)
				end
			end
		end

		local namedPos
		for _, key in ipairs({ "Main", "Ground", "Dock", "Teleport" }) do
			local n = island:FindFirstChild(key)
			if not n and islandChild then
				n = islandChild:FindFirstChild(key)
			end
			if n then
				namedPos = instancePosition(n)
				if namedPos then
					break
				end
			end
		end

		local method, pos, minV, maxV, center, radius
		if spawn then
			pos = instancePosition(spawn)
			method = "SpawnLocation"
		end
		if paPos then
			if not pos then
				pos = paPos
				method = "PersistentAnchor.Center"
			end
			center = paPos
			radius = paRadius
			if paRadius then
				minV, maxV = aabbFromRadius(paPos, paRadius)
			end
		end
		-- Game-authored Persistent volume beats a thin streamed Island cluster.
		if not minV and persPos and persSize then
			minV, maxV = aabbFromCenterSize(persPos, persSize)
			if not pos then
				pos = persPos
				method = "Constants.Persistent"
			end
		end
		if not minV and sampleMin then
			minV, maxV = sampleMin, sampleMax
			if not pos then
				pos = samplePos
				method = "IslandBounds"
			end
		elseif not pos and persPos then
			pos = persPos
			method = "Constants.Persistent"
			if not minV then
				local pad = Vector3.new(200, 80, 200)
				minV, maxV = persPos - pad, persPos + pad
			end
		end
		if not pos and namedPos then
			pos = namedPos
			method = "NamedMarker"
		end
		if not pos and samplePos then
			pos = samplePos
			method = "IslandBounds"
		end

		if not pos then
			return {
				failed = true,
				parts = countParts(island),
				islandKids = islandKids,
			}
		end
		if not minV then
			local pad = Vector3.new(120, 80, 120)
			minV, maxV = pos - pad, pos + pad
		end
		return {
			pos = pos,
			min = minV,
			max = maxV,
			center = center or pos,
			radius = radius,
			method = method,
			parts = sampleN or 0,
			islandKids = islandKids,
		}
	end

	local function rememberGeo(island, geo)
		geoCache[island] = geo
		local name = island.Name
		if not geo or geo.failed or not geo.pos then
			if geoLogged[name] ~= "fail" and geoLogged[name] ~= "ok" then
				geoLogged[name] = "fail"
				GB.Log.warn(
					"World",
					string.format(
						"Unable to resolve island position: %s class=%s descendantParts=%s",
						name,
						island.ClassName,
						tostring(geo and geo.parts or 0)
					)
				)
			end
			return geo
		end
		if geoLogged[name] ~= "ok" then
			geoLogged[name] = "ok"
			local msg = string.format("Island resolved: %s via %s", name, tostring(geo.method))
			GB.Log.debug("World", msg)
			GB.Log.log("World", msg)
		end
		return geo
	end

	function M.getIslandGeo(island)
		island = resolveIslandInst(island)
		if not island then
			return nil
		end
		local cached = geoCache[island]
		local islandChild = island:FindFirstChild("Island")
		local kids = islandChild and #islandChild:GetChildren() or 0
		if cached and cached.islandKids == kids then
			if cached.failed then
				return nil
			end
			return cached
		end
		local geo = computeGeo(island)
		rememberGeo(island, geo)
		if not geo or geo.failed then
			return nil
		end
		return geo
	end

	function M.GetIslandPosition(island)
		local geo = M.getIslandGeo(island)
		return geo and usablePos(geo.pos) or nil
	end

	function M.GetIslandBounds(island)
		local geo = M.getIslandGeo(island)
		if not geo or not geo.min then
			return nil
		end
		return geo.min, geo.max, geo.center, geo.radius
	end

	function M.IsPositionInsideIsland(position, island)
		if typeof(position) ~= "Vector3" then
			return false
		end
		local geo = M.getIslandGeo(island)
		if not geo then
			return false
		end
		if geo.radius and geo.center then
			local dx = position.X - geo.center.X
			local dz = position.Z - geo.center.Z
			if dx * dx + dz * dz <= geo.radius * geo.radius then
				return position.Y >= geo.center.Y - 80 and position.Y <= geo.center.Y + 450
			end
			return false
		end
		if geo.min and geo.max then
			return aabbContains(geo.min, geo.max, position, 40)
		end
		return false
	end

	function M.GetIslandFromPosition(position)
		if typeof(position) ~= "Vector3" then
			return nil
		end
		local isles = workspace:FindFirstChild("Islands")
		if not isles then
			return nil
		end
		local list, seen = {}, {}
		for _, name in ipairs(ISLANDS) do
			local isl = isles:FindFirstChild(name)
			if isl then
				seen[isl] = true
				list[#list + 1] = isl
			end
		end
		for _, isl in ipairs(isles:GetChildren()) do
			if not seen[isl] then
				list[#list + 1] = isl
			end
		end
		local best, bestD
		for _, isl in ipairs(list) do
			if M.IsPositionInsideIsland(position, isl) then
				local geo = geoCache[isl]
				local c = geo and (geo.center or geo.pos)
				local d = 0
				if c then
					local dx, dz = position.X - c.X, position.Z - c.Z
					d = math.sqrt(dx * dx + dz * dz)
				end
				if not bestD or d < bestD then
					best, bestD = isl.Name, d
				end
			end
		end
		return best
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
		return M.GetIslandFromPosition(pos)
	end

	function M.islandSpawn(name)
		local isl = resolveIslandInst(name)
		if not isl then
			return nil
		end
		local spawnRoot = isl:FindFirstChild("SpawnLocations") or isl:FindFirstChild("SpawnLocation")
		if spawnRoot then
			if spawnRoot:IsA("SpawnLocation") or isPart(spawnRoot) then
				return usablePos(spawnRoot.Position)
			end
			for _, d in ipairs(spawnRoot:GetDescendants()) do
				if d:IsA("SpawnLocation") or isPart(d) then
					return usablePos(d.Position)
				end
			end
		end
		return M.GetIslandPosition(isl)
	end

	function M.ToPosition(pos, range)
		return M.moveTo(pos, range or 6)
	end

	function M.ToInstance(inst, range)
		return M.moveTo(inst, range or 8)
	end

	function M.safeOffset(inst, dist)
		dist = dist or (GB.Config.TalkOffset or 5)
		local part = GB.Resolver.part(inst)
		if not part or not part:IsA("BasePart") then
			local pos = GB.Resolver.positionOf(inst)
			return pos and (pos + Vector3.new(0, 0, dist))
		end
		local look = part.CFrame.LookVector
		local off = Vector3.new(look.X, 0, look.Z)
		if off.Magnitude < 0.2 then
			off = Vector3.new(0, 0, 1)
		end
		return part.Position + off.Unit * dist
	end

	function M.ToNPC(resolved, range)
		local inst = type(resolved) == "table" and resolved.Instance or resolved
		if not inst then
			return false
		end
		local dest = M.safeOffset(inst, range or (GB.Config.TalkOffset or 5))
		if not dest then
			return M.moveTo(inst, range or 8)
		end
		if not M.destOk(dest) then
			local g = M.groundAt(dest)
			if g then
				dest = g
			end
		end
		GB.Log.log("TRAVEL", "Teleport -> " .. (M.displayLabel(resolved) or inst.Name))
		return M.setPos(dest)
	end

	function M.displayLabel(resolved)
		if type(resolved) == "table" then
			return resolved.DisplayName or resolved.InternalName
		end
		if typeof(resolved) == "Instance" then
			return GB.Resolver.displayName(resolved)
		end
		return nil
	end

	function M.ToEnemy(inst, range)
		if not inst then
			return false
		end
		if GB.Combat and GB.Combat.IsEnemyAlive and not GB.Combat.IsEnemyAlive(inst) then
			return false
		end
		if GB.Resolver.isPet and GB.Resolver.isPet(inst) then
			return false
		end
		local dest = M.safeOffset(inst, range or (GB.Config.CombatRange or 5.5))
		if not dest then
			return M.moveTo(inst, range or 8)
		end
		if not M.destOk(dest) then
			local g = M.groundAt(dest)
			if g then
				dest = g
			end
		end
		GB.Log.log("TRAVEL", "Teleport -> " .. (GB.Resolver.displayName(inst) or inst.Name))
		return M.setPos(dest)
	end

	function M.ToInteractable(inst, range)
		return M.moveTo(inst, range or 8)
	end

	function M.sameIsland(a, b)
		return a and b and a == b
	end

	function M.pullStream(island)
		if type(island) ~= "string" or island == "" then
			return false
		end
		local dests = {}
		local function addPos(pos)
			if typeof(pos) == "Vector3" then
				local u = usablePos(pos)
				if u and M.destOk(u) then
					dests[#dests + 1] = u
				end
			end
		end
		addPos(M.islandSpawn(island))
		local aa = workspace:FindFirstChild("AA IMPORTANT")
		local sl = aa and aa:FindFirstChild("Spawn Locations")
		if sl then
			for _, c in ipairs(sl:GetChildren()) do
				if string.find(c.Name, island, 1, true) then
					if isPart(c) then
						addPos(c.Position)
					else
						addPos(instancePosition(c))
					end
				end
			end
		end
		local dlg = aa and aa:FindFirstChild("DialogueNPCs")
		local folder = dlg and dlg:FindFirstChild(island)
		if folder then
			for _, c in ipairs(folder:GetChildren()) do
				addPos(GB.Resolver.positionOf(c))
			end
		end
		if #dests == 0 then
			return false
		end
		local root = M.hrp()
		local start = root and root.Position
		local pick = dests[1]
		if start then
			local bestD = (pick - start).Magnitude
			for i = 2, #dests do
				local d = (dests[i] - start).Magnitude
				if d > 40 and d < bestD then
					pick, bestD = dests[i], d
				end
			end
			if bestD < 18 then
				for i = 1, #dests do
					if (dests[i] - start).Magnitude > 80 then
						pick = dests[i]
						break
					end
				end
			end
		end
		GB.Log.log("TRAVEL", "stream pull " .. island)
		return M.setPos(pick)
	end

	return M
end
