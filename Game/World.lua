-- Islands, move, destOk, floorAt, tweenTo. Combat does not snap to roofs.

return function(GB)
	local TweenService = game:GetService("TweenService")
	local M = {
		lastSafe = nil,
		anchorSafe = nil,
		_tween = nil,
		_tweenDest = nil,
	}

	local ISLANDS = { "Anchor Town", "Clown Town", "Maple Village" }

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
		local yMin = math.max(GB.Config.DestYMin or 0, M.waterY() + 2)
		if y < yMin or y > (GB.Config.DestYMax or 180) then
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

	-- Floor under the target. groundAt(+40) hits roofs first when the mob is indoors.
	function M.floorAt(pos, preferY)
		if typeof(pos) ~= "Vector3" then
			return nil
		end
		preferY = tonumber(preferY) or pos.Y
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local c = M.char()
		params.FilterDescendantsInstances = c and { c } or {}
		for _, lift in ipairs({ 2.4, 5, 9 }) do
			local origin = Vector3.new(pos.X, preferY + lift, pos.Z)
			local hit = workspace:Raycast(origin, Vector3.new(0, -(lift + 10), 0), params)
			if hit and hit.Material ~= Enum.Material.Water then
				if not (hit.Instance and string.find(string.lower(hit.Instance.Name), "water", 1, true)) then
					local p = hit.Position + Vector3.new(0, 3, 0)
					if p.Y <= preferY + 3.5 and M.destOk(p) then
						return p
					end
				end
			end
		end
		local flat = Vector3.new(pos.X, preferY, pos.Z)
		if M.destOk(flat) then
			return flat
		end
		return nil
	end

	function M.cancelTween()
		if M._tween then
			pcall(function()
				M._tween:Cancel()
			end)
			M._tween = nil
			M._tweenDest = nil
		end
	end

	function M.tweenPlaying()
		local tw = M._tween
		if not tw then
			return false
		end
		local ok, st = pcall(function()
			return tw.PlaybackState
		end)
		return ok and st == Enum.PlaybackState.Playing
	end

	function M.tweenTo(pos, lookAt, opts)
		opts = opts or {}
		local root = M.hrp()
		if not (root and typeof(pos) == "Vector3") then
			return false
		end
		if not M.destOk(pos) then
			return false
		end
		local range = tonumber(opts.range) or 3.5
		local here = root.Position
		local dist = (here - pos).Magnitude
		local function face()
			if typeof(lookAt) == "Vector3" then
				root.CFrame = CFrame.new(root.Position, Vector3.new(lookAt.X, root.Position.Y, lookAt.Z))
			end
		end
		if dist <= range then
			face()
			return true
		end
		if M.tweenPlaying() and M._tweenDest and (M._tweenDest - pos).Magnitude < 2.4 then
			return (root.Position - pos).Magnitude <= range + 3
		end
		M.cancelTween()
		local speed = tonumber(GB.Config.TweenSpeed) or 95
		local maxDur = tonumber(opts.maxDur) or tonumber(GB.Config.TweenMaxDur) or 1.8
		local dur = math.clamp(dist / math.max(speed, 20), 0.08, maxDur)
		local goal = typeof(lookAt) == "Vector3" and CFrame.new(pos, Vector3.new(lookAt.X, pos.Y, lookAt.Z))
			or CFrame.new(pos)
		pcall(function()
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end)
		local tw = TweenService:Create(
			root,
			TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CFrame = goal }
		)
		M._tween = tw
		M._tweenDest = pos
		tw:Play()
		if opts.wait == false then
			return (root.Position - pos).Magnitude <= range + 6
		end
		local t0 = os.clock()
		while os.clock() - t0 < dur + 0.06 do
			if not root.Parent then
				break
			end
			if (root.Position - pos).Magnitude <= range then
				break
			end
			task.wait()
		end
		if tw.PlaybackState == Enum.PlaybackState.Playing then
			pcall(function()
				tw:Cancel()
			end)
		end
		if M._tween == tw then
			M._tween = nil
			M._tweenDest = nil
		end
		face()
		M.rememberSafe()
		return (root.Position - pos).Magnitude <= range + 3
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
		local pos = g and GB.Resolver.positionOf(g)
		if pos then
			M.anchorSafe = CFrame.new(pos + Vector3.new(0, 0, 6))
		end
	end

	function M.rescue()
		local root = M.hrp()
		if not root then
			return
		end
		local y = root.Position.Y
		local wet = y < M.waterY() + 4 or y > 240
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
		M.cancelTween()
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = dest
		GB.Log.warn("TRAVEL", "rescue swim/void")
	end

	function M.goSafe()
		M.ensureAnchorSafe()
		local root = M.hrp()
		local dest = M.lastSafe or M.anchorSafe
		if root and dest then
			M.cancelTween()
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

	function M.setPos(cf, opts)
		opts = opts or {}
		local root = M.hrp()
		if not root then
			return false
		end
		local pos = typeof(cf) == "CFrame" and cf.Position or cf
		if not M.destOk(pos) then
			return false
		end
		-- NPC/talk dests already floor-snapped. groundAt(+40) hits tree canopy first.
		if opts.SkipGround then
			root.CFrame = typeof(cf) == "CFrame" and cf or CFrame.new(pos)
			M.rememberSafe()
			return true
		end
		local g = M.groundAt(pos)
		if g and opts.MaxGroundY and g.Y > opts.MaxGroundY then
			g = nil
		end
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
			pos = GB.Resolver.positionOf(instOrPos)
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
		local dest = M.floorAt(pos, pos.Y) or pos
		if dist > 16 then
			return M.tweenTo(dest, pos, { wait = true, range = range })
		end
		if hum then
			hum:MoveTo(dest)
		end
		return (root.Position - dest).Magnitude <= range + 4
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
		perfCount("WorkspaceDeepScan", 1)
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
			perfCount("WorkspaceDeepScan", 1)
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
		if not GB.PlayerData.finished("Setting Sail", true) then
			return "Anchor Town"
		end
		if not GB.PlayerData.finished("Journey to Maple Village", true) then
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
			perfCount("WorkspaceDeepScan", 1)
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

	function M.planarDist(a, b)
		if typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then
			return 1e9
		end
		local dx = a.X - b.X
		local dz = a.Z - b.Z
		return math.sqrt(dx * dx + dz * dz)
	end

	function M.atTalk(resolved, range)
		local inst = type(resolved) == "table" and resolved.Instance or resolved
		local root = M.hrp()
		local pos = inst and GB.Resolver and GB.Resolver.positionOf and GB.Resolver.positionOf(inst)
		if not (root and pos) then
			return false
		end
		range = tonumber(range) or (GB.Config.TalkRange or 14)
		-- Planar only: Y is ignored so a tree snap still counts as "already talking".
		return M.planarDist(root.Position, pos) <= range
	end

	function M.safeOffset(inst, dist)
		dist = dist or (GB.Config.TalkOffset or 5)
		local part = GB.Resolver.part(inst)
		local base
		if part and part:IsA("BasePart") then
			local look = part.CFrame.LookVector
			local off = Vector3.new(look.X, 0, look.Z)
			if off.Magnitude < 0.2 then
				off = Vector3.new(0, 0, 1)
			end
			base = part.Position + off.Unit * dist
		else
			local pos = GB.Resolver.positionOf(inst)
			base = pos and (pos + Vector3.new(0, 0, dist))
		end
		if not base then
			return nil
		end
		local npcY = (part and part.Position.Y) or base.Y
		return M.floorAt(base, npcY) or base
	end

	function M.ToNPC(resolved, range)
		local inst = type(resolved) == "table" and resolved.Instance or resolved
		if not inst then
			return false
		end
		local talkRange = GB.Config.TalkRange or 14
		local npcPos = GB.Resolver.positionOf(inst)
		local snapOpts = npcPos and { MaxGroundY = npcPos.Y + 4, SkipGround = true } or { SkipGround = true }
		if M.atTalk(resolved, talkRange) then
			local root = M.hrp()
			if root and npcPos and math.abs(root.Position.Y - npcPos.Y) > 6 then
				local now = os.clock()
				if now - (M._npcSnapAt or 0) >= 8 then
					M._npcSnapAt = now
					local dest = M.floorAt(root.Position, npcPos.Y) or M.safeOffset(inst, range or (GB.Config.TalkOffset or 5))
					if dest then
						return M.setPos(dest, snapOpts)
					end
				end
			end
			return true
		end
		local dest = M.safeOffset(inst, range or (GB.Config.TalkOffset or 5))
		if not dest then
			return M.moveTo(inst, range or 8)
		end
		if not M.destOk(dest) then
			local g = npcPos and M.floorAt(dest, npcPos.Y) or M.groundAt(dest)
			if g then
				dest = g
			end
		end
		if npcPos then
			dest = M.floorAt(dest, npcPos.Y) or dest
		end
		GB.Log.log("TRAVEL", "Teleport -> " .. (M.displayLabel(resolved) or inst.Name))
		return M.setPos(dest, snapOpts)
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
		range = range or (GB.Config.CombatRange or 5.5)
		local part = GB.Resolver.part(inst)
		local dest
		if part and part:IsA("BasePart") then
			local look = part.CFrame.LookVector
			local off = -Vector3.new(look.X, 0, look.Z)
			if off.Magnitude < 0.2 then
				off = Vector3.new(0, 0, range)
			else
				off = off.Unit * range
			end
			dest = part.Position + off
		else
			dest = M.safeOffset(inst, range)
		end
		if not dest then
			return M.moveTo(inst, range + 2)
		end
		local preferY = (part and part:IsA("BasePart") and part.Position.Y) or dest.Y
		dest = M.floorAt(dest, preferY) or Vector3.new(dest.X, preferY, dest.Z)
		if not M.destOk(dest) then
			return false
		end
		local root = M.hrp()
		if not root then
			return false
		end
		local look = part and part.Position or dest
		local dist = (root.Position - dest).Magnitude
		GB.Log.log("TRAVEL", "Tween -> " .. (GB.Resolver.displayName(inst) or inst.Name))
		local speed = tonumber(GB.Config.TweenSpeed) or 95
		local maxDur = tonumber(GB.Config.TweenMaxDur) or 1.8
		local maxStep = speed * maxDur
		if dist > maxStep + 10 then
			local flat = Vector3.new(dest.X - root.Position.X, 0, dest.Z - root.Position.Z)
			if flat.Magnitude > 1 then
				local mid = root.Position + flat.Unit * maxStep
				mid = M.floorAt(mid, preferY) or Vector3.new(mid.X, preferY, mid.Z)
				M.tweenTo(mid, look, { wait = true, range = 3 })
			end
		end
		return M.tweenTo(dest, look, { wait = true, range = range + 1.2 })
	end

	function M.ToInteractable(inst, range)
		range = range or 4
		local origin, look = nil, nil
		if GB.Resolver.promptAnchor then
			origin, look = GB.Resolver.promptAnchor(inst)
		end
		origin = origin or GB.Resolver.positionOf(inst)
		if not origin then
			return M.moveTo(inst, range)
		end
		local xz = look and Vector3.new(look.X, 0, look.Z)
		if not xz or xz.Magnitude < 0.2 then
			xz = Vector3.new(0, 0, 1)
		else
			xz = xz.Unit
		end
		local perp = Vector3.new(-xz.Z, 0, xz.X)
		local dist = math.clamp(range, 3, 6)
		local cands = {
			origin + xz * dist,
			origin - xz * dist,
			origin + perp * dist,
			origin - perp * dist,
		}
		local dest
		local best
		for i = 1, #cands do
			local c = cands[i]
			local g = M.groundAt(c)
			if g and g.Y > origin.Y + 4 then
				g = Vector3.new(c.X, origin.Y, c.Z)
			end
			local use = g or Vector3.new(c.X, origin.Y, c.Z)
			if M.destOk(use) then
				local dPrompt = (use - origin).Magnitude
				local lift = math.abs(use.Y - origin.Y)
				if dPrompt <= 7.6 and (not best or lift < best) then
					best = lift
					dest = use
				end
			end
		end
		dest = dest or Vector3.new(origin.X + xz.X * dist, origin.Y, origin.Z + xz.Z * dist)
		GB.Log.log("TRAVEL", "Teleport -> " .. (GB.Resolver.displayName(inst) or inst.Name))
		local ok = M.setPos(dest, { MaxGroundY = origin.Y + 4 })
		local root = M.hrp()
		if root and (root.Position - origin).Magnitude > 7.5 then
			root.CFrame = CFrame.new(dest)
			M.rememberSafe()
			ok = true
		end
		return ok
	end

	function M.firePrompt(pr, hold, inst)
		if not pr then
			return false
		end
		local dur = hold
		if dur == nil then
			local ok, hd = pcall(function()
				return pr.HoldDuration
			end)
			dur = (ok and type(hd) == "number" and hd) or 0
		end
		if type(dur) ~= "number" or dur < 0 then
			dur = 0
		end
		local ok = pcall(function()
			if dur > 0 then
				fireproximityprompt(pr, dur)
			else
				fireproximityprompt(pr)
			end
		end)
		task.wait(dur > 0 and (dur + 0.12) or 0.12)
		local target = inst or (GB.Resolver.interactableOf and GB.Resolver.interactableOf(pr))
		local ev = game.ReplicatedStorage:FindFirstChild("Events")
		local r = ev and ev:FindFirstChild("ProximityPrompt")
		if r then
			pcall(function()
				r:FireServer(pr, pr.Name, {
					ObjectName = target and target.Name or pr.Name,
				})
			end)
		end
		return ok
	end

	function M.interact(inst, range, hold)
		if not inst then
			return false
		end
		if not M.atTalk(inst, math.max(range or 4, GB.Config.TalkRange or 14)) then
			M.ToInteractable(inst, range or 4)
			task.wait(0.15)
		end
		local origin, _, pr = nil, nil, nil
		if GB.Resolver.promptAnchor then
			origin, _, pr = GB.Resolver.promptAnchor(inst)
		end
		pr = pr or GB.Resolver.prompt(inst)
		if not pr then
			return false
		end
		local root = M.hrp()
		local d = (root and origin) and (root.Position - origin).Magnitude or -1
		local planar = (root and origin) and M.planarDist(root.Position, origin) or 1e9
		if root and origin and planar > (GB.Config.TalkRange or 14) then
			local dest = M.floorAt(origin + Vector3.new(0, 0, 3), origin.Y) or (origin + Vector3.new(0, 0, 3))
			M.setPos(dest, { MaxGroundY = origin.Y + 4, SkipGround = true })
			d = (root.Position - origin).Magnitude
		end
		local dur = hold
		if dur == nil then
			local ok, hd = pcall(function()
				return pr.HoldDuration
			end)
			dur = (ok and type(hd) == "number" and hd) or 0
		end
		GB.Log.log("UI", string.format("%s %s d=%.1f", (dur and dur > 0) and "hold prompt" or "prompt", inst.Name or pr.Name, d))
		return M.firePrompt(pr, dur, inst)
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

	local _moveToRaw = M.moveTo
	function M.moveTo(instOrPos, range)
		local t0 = pbegin()
		local out = { pcall(_moveToRaw, instOrPos, range) }
		pdone("World travel operations", t0)
		if not out[1] then
			error(out[2])
		end
		return unpack(out, 2)
	end

	local _toEnemyRaw = M.ToEnemy
	function M.ToEnemy(inst, range)
		local t0 = pbegin()
		local out = { pcall(_toEnemyRaw, inst, range) }
		pdone("World travel operations", t0)
		if not out[1] then
			error(out[2])
		end
		return unpack(out, 2)
	end

	return M
end
