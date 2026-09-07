-- Resolve NPC / enemy / item / island / shop / trainer / remote.
-- World Graves is DialogueNPCs "Officer Graves [2]" (DisplayName "Officer Graves").
-- ReplicatedStorage "Officer Graves" is character-create — never interact.

return function(GB)
	local CS = game:GetService("CollectionService")
	local RS = game:GetService("ReplicatedStorage")
	local M = {}

	-- Verified only. Studio + QuestInfo + DialogueUtilities.GetNPCName.
	M.NPC_ALIAS = {
		["Officer Graves"] = { "Officer Graves [2]", "Graves" },
		["Officer Graves [2]"] = { "Officer Graves", "Graves" },
		["Graves"] = { "Officer Graves", "Officer Graves [2]" },
	}

	M.ENEMY_ALIAS = {
		["Barrel Clown"] = { '"Barrel Clown" Binki', "Binki" },
		["Binki"] = { '"Barrel Clown" Binki', "Barrel Clown" },
		['"Barrel Clown" Binki'] = { "Barrel Clown", "Binki" },
		["Hypnotist"] = { '"Hypnotist" Mango', "Mango" },
		["Mango"] = { '"Hypnotist" Mango', "Hypnotist" },
		['"Hypnotist" Mango'] = { "Hypnotist", "Mango" },
		-- Studio: Workspace.Entities.Training Dummy1..8, CollectionService tag TrainingDummy
		["Training Dummy"] = {
			"TrainingDummy",
			"Training Dummy1",
			"Training Dummy2",
			"Training Dummy3",
			"Training Dummy4",
			"Training Dummy5",
			"Training Dummy6",
			"Training Dummy7",
			"Training Dummy8",
		},
		["TrainingDummy"] = { "Training Dummy", "Training Dummy1" },
		-- Quest/mob-zone name. Live models: Corrupt Swordsman Officer N / Corrupt Sniper Officer N.
		-- Tag + NPCName are the variant, not "Corrupt Marine Officer". Foot soldier is "Corrupt Marine" only.
		["Corrupt Marine Officer"] = {
			"Corrupt Swordsman Officer",
			"Corrupt Sniper Officer",
		},
		["Corrupt Swordsman Officer"] = { "Corrupt Marine Officer", "Corrupt Sniper Officer" },
		["Corrupt Sniper Officer"] = { "Corrupt Marine Officer", "Corrupt Swordsman Officer" },
	}

	local missLog = {}
	local dummyCache = nil
	local dummyPos = nil
	local dummyMiss = 0
	M.lastCandidates = {}

	function M.isDummyName(name)
		if type(name) ~= "string" or name == "" then
			return false
		end
		if name == "Training Dummy" or name == "TrainingDummy" then
			return true
		end
		return string.find(name, "Dummy", 1, true) ~= nil
	end

	function M.invalidateDummy()
		dummyCache = nil
	end

	function M.lastDummyPos()
		return dummyPos
	end

	function M.dummyMissCount()
		return dummyMiss
	end

	local function aliases()
		if GB.QuestData and GB.QuestData.NPC_ALIAS then
			return GB.QuestData.NPC_ALIAS
		end
		return M.NPC_ALIAS
	end

	local function pushName(list, seen, name)
		if type(name) ~= "string" or name == "" or name == "\\" then
			return
		end
		if seen[name] then
			return
		end
		seen[name] = true
		list[#list + 1] = name
	end

	function M.namesFor(request, opts)
		opts = opts or {}
		local list, seen = {}, {}
		pushName(list, seen, request)
		pushName(list, seen, opts.DisplayName)
		pushName(list, seen, opts.InternalName)
		pushName(list, seen, opts.QuestName)
		local src = aliases()
		local function addMapped(key)
			local v = src[key] or M.NPC_ALIAS[key] or M.ENEMY_ALIAS[key]
			if type(v) == "string" then
				pushName(list, seen, v)
			elseif type(v) == "table" then
				for _, n in ipairs(v) do
					pushName(list, seen, n)
				end
			end
		end
		for _, n in ipairs({ request, opts.DisplayName, opts.InternalName }) do
			if type(n) == "string" then
				addMapped(n)
			end
		end
		for key, v in pairs(src) do
			if v == request or (type(v) == "table" and table.find(v, request)) then
				pushName(list, seen, key)
			end
		end
		return list
	end

	local function inRS(inst)
		return inst and RS:IsAncestorOf(inst)
	end

	function M.displayName(model)
		if not model then
			return nil
		end
		local attr = model:GetAttribute("NPCName") or model:GetAttribute("DisplayName")
		if type(attr) == "string" and attr ~= "" then
			return attr
		end
		local h = model:FindFirstChildOfClass("Humanoid")
		if h and h.DisplayName and h.DisplayName ~= "" then
			return h.DisplayName
		end
		return model.Name
	end

	local function isDialogue(inst)
		if not inst then
			return false
		end
		if inst:GetAttribute("Interaction") == "Dialogue" then
			return true
		end
		if inst:FindFirstChild("Dialogue") then
			return true
		end
		if inst:HasTag("Dialogue") or inst:HasTag("Interactable") then
			return true
		end
		return false
	end

	local function partOf(inst)
		if not inst then
			return nil
		end
		if inst:IsA("BasePart") then
			return inst
		end
		if inst:IsA("Attachment") then
			local host = inst.Parent
			if host and host:IsA("BasePart") then
				return host
			end
			return host and host:FindFirstChildWhichIsA("BasePart", true)
		end
		if inst:IsA("Model") then
			if inst.PrimaryPart and inst.PrimaryPart:IsA("BasePart") then
				return inst.PrimaryPart
			end
			local hrp = inst:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") then
				return hrp
			end
			return inst:FindFirstChildWhichIsA("BasePart", true)
		end
		if inst:IsA("ProximityPrompt") then
			local p = inst.Parent
			if p and p:IsA("BasePart") then
				return p
			end
			if p and p:IsA("Attachment") then
				local host = p.Parent
				if host and host:IsA("BasePart") then
					return host
				end
			end
			return p and p:FindFirstChildWhichIsA("BasePart", true)
		end
		if inst:IsA("Folder") or inst:IsA("Configuration") then
			return inst:FindFirstChildWhichIsA("BasePart", true)
		end
		return inst:FindFirstChildWhichIsA("BasePart", true)
	end

	function M.part(inst)
		return partOf(inst)
	end

	function M.positionOf(inst)
		if not inst then
			return nil
		end
		if inst:IsA("BasePart") then
			return inst.Position
		end
		if inst:IsA("Attachment") then
			return inst.WorldPosition
		end
		local p = partOf(inst)
		if p and p:IsA("BasePart") then
			return p.Position
		end
		if inst:IsA("Model") then
			local ok, cf = pcall(inst.GetPivot, inst)
			if ok and typeof(cf) == "CFrame" then
				return cf.Position
			end
		end
		return nil
	end

	local function climbRoot(inst)
		if not inst then
			return nil
		end
		if inst:IsA("Model") then
			return inst
		end
		local m = inst:FindFirstAncestorOfClass("Model")
		if m and not inRS(m) then
			return m
		end
		if inst:IsA("BasePart") or inst:IsA("Folder") or inst:IsA("Configuration") then
			return inst
		end
		return inst
	end

	-- Studio: Workspace.Entities."<Player> Slot N Pet" tagged Pet (+ NPC/Character).
	function M.isPet(inst)
		if not inst then
			return false
		end
		local root = climbRoot(inst) or inst
		if root:HasTag("Pet") then
			return true
		end
		local n = root.Name
		if type(n) == "string" and string.find(n, " Slot ", 1, true) and string.sub(n, -4) == " Pet" then
			return true
		end
		return false
	end

	local function enemyAlive(root)
		if GB.Combat and GB.Combat.IsEnemyAlive then
			return GB.Combat.IsEnemyAlive(root)
		end
		if not (root and root.Parent) then
			return false
		end
		if root:GetAttribute("Dead") == true then
			return false
		end
		local h = root:FindFirstChildOfClass("Humanoid")
		if h and h.Health <= 0 then
			return false
		end
		return true
	end

	local function usable(inst, kind)
		if not (inst and inst.Parent) or inRS(inst) then
			return false
		end
		local root = climbRoot(inst)
		if not root or inRS(root) then
			return false
		end
		if M.isPet(root) then
			return false
		end
		if kind == "enemy" then
			if GB.Combat and GB.Combat.isRecentlyDead and GB.Combat.isRecentlyDead(root) then
				return false
			end
			if not enemyAlive(root) then
				return false
			end
		end
		if root:IsA("Model") or root:IsA("BasePart") or root:IsA("Folder") or root:IsA("Configuration") then
			return M.positionOf(root) ~= nil or partOf(root) ~= nil or isDialogue(root)
		end
		return false
	end

	function M.dummy()
		if dummyCache and dummyCache.Parent and usable(dummyCache, "enemy") then
			return dummyCache
		end
		dummyCache = nil

		local tagged = CS:GetTagged("TrainingDummy")
		if type(tagged) == "table" then
			for _, t in ipairs(tagged) do
				if usable(t, "enemy") then
					dummyCache = climbRoot(t) or t
					dummyPos = M.positionOf(dummyCache)
					dummyMiss = 0
					GB.Cache.set("res:enemy:Training Dummy", dummyCache)
					GB.Log.log("RESOLVE", "Training Dummy -> " .. dummyCache:GetFullName())
					return dummyCache
				end
			end
		end

		local ents = workspace:FindFirstChild("Entities")
		if ents then
			for _, c in ipairs(ents:GetChildren()) do
				if string.find(c.Name, "Dummy", 1, true) and usable(c, "enemy") then
					dummyCache = c
					dummyPos = M.positionOf(c)
					dummyMiss = 0
					GB.Cache.set("res:enemy:Training Dummy", dummyCache)
					GB.Log.log("RESOLVE", "Training Dummy -> " .. c:GetFullName())
					return c
				end
			end
		end

		dummyMiss = dummyMiss + 1
		local now = os.clock()
		local mk = "miss:Training Dummy"
		if not missLog[mk] or now - missLog[mk] > 8 then
			missLog[mk] = now
			GB.Log.warn("ERROR", "resolve miss Training Dummy")
		end
		return nil
	end

	local function islandOf(inst)
		if not inst then
			return nil
		end
		local p = inst
		while p and p ~= workspace do
			local n = p.Name
			if n == "Anchor Town" or n == "Clown Town" or n == "Maple Village" then
				return n
			end
			p = p.Parent
		end
		local pos = M.positionOf(inst)
		if pos and GB.World and GB.World.GetIslandFromPosition then
			return GB.World.GetIslandFromPosition(pos)
		end
		return nil
	end

	function M.pack(inst, request)
		local root = climbRoot(inst) or inst
		return {
			Instance = root,
			Root = root,
			Position = M.positionOf(root),
			DisplayName = M.displayName(root),
			InternalName = root.Name,
			Interaction = root:GetAttribute("Interaction"),
			Island = islandOf(root),
			Request = request,
		}
	end

	local function npcRoots()
		local roots, seen = {}, {}
		local function add(inst)
			if inst and not seen[inst] then
				seen[inst] = true
				roots[#roots + 1] = inst
			end
		end
		local aa = workspace:FindFirstChild("AA IMPORTANT")
		if aa then
			add(aa:FindFirstChild("DialogueNPCs"))
			add(aa:FindFirstChild("Markers"))
			add(aa:FindFirstChild("NPCAreas"))
			add(aa:FindFirstChild("PointsOfInterest"))
		end
		add(workspace:FindFirstChild("DialogueNPCs"))
		add(workspace:FindFirstChild("Entities"))
		add(workspace:FindFirstChild("Islands"))
		return roots
	end

	function M.baseName(s)
		if type(s) ~= "string" then
			return ""
		end
		return (string.gsub(s, " %d+$", ""))
	end

	function M.isCorruptOfficer(inst)
		if not inst then
			return false
		end
		if inst:HasTag("Corrupt Swordsman Officer") or inst:HasTag("Corrupt Sniper Officer") then
			return true
		end
		for _, s in ipairs({ inst:GetAttribute("NPCName"), inst.Name, M.displayName(inst) }) do
			if type(s) == "string" and string.find(s, "Officer", 1, true) and string.find(s, "Corrupt", 1, true) then
				return true
			end
		end
		return false
	end

	function M.nameMatches(inst, names)
		if not (inst and type(names) == "table") then
			return false
		end
		local nm = inst.Name
		local disp = M.displayName(inst)
		local npc = inst:GetAttribute("NPCName")
		local bases = { M.baseName(nm), M.baseName(disp or ""), M.baseName(type(npc) == "string" and npc or "") }
		for _, n in ipairs(names) do
			if type(n) == "string" and n ~= "" then
				if n == "Corrupt Marine Officer" and M.isCorruptOfficer(inst) then
					return true
				end
				if nm == n or disp == n or npc == n then
					return true
				end
				local tagged
				pcall(function()
					tagged = inst:HasTag(n)
				end)
				if tagged then
					return true
				end
				for _, b in ipairs(bases) do
					if b == n then
						return true
					end
				end
				if #n > 3 and string.sub(nm, 1, #n) == n then
					local ch = string.sub(nm, #n + 1, #n + 1)
					if ch == "" or ch == " " then
						return true
					end
				end
			end
		end
		return false
	end

	local function nameHit(inst, names)
		return M.nameMatches(inst, names)
	end

	local function dialogueNameHit(inst, names)
		local cfg = inst:FindFirstChild("Dialogue")
		if not (cfg and cfg:IsA("Configuration")) then
			return false
		end
		local qn = cfg:FindFirstChild("QuestName2") or cfg:FindFirstChild("QuestName")
		if qn then
			local v = qn:FindFirstChild("QuestName")
			local val = v and v.Value
			-- quest-name node is evidence the model is a quest NPC, not a name match
			if type(val) == "string" then
				for _, n in ipairs(names) do
					if val == n then
						return true
					end
				end
			end
		end
		return false
	end

	local function firstWorldTagged(tag)
		local ok, tagged = pcall(CS.GetTagged, CS, tag)
		if not ok or type(tagged) ~= "table" then
			return nil
		end
		for _, t in ipairs(tagged) do
			if usable(t, "npc") then
				return climbRoot(t)
			end
		end
		return nil
	end

	local function scanRoots(pred, limit)
		limit = limit or 8
		local hits = {}
		for _, root in ipairs(npcRoots()) do
			if pred(root) then
				hits[#hits + 1] = root
				if #hits >= limit then
					return hits
				end
			end
			for _, d in ipairs(root:GetDescendants()) do
				if pred(d) then
					hits[#hits + 1] = d
					if #hits >= limit then
						return hits
					end
				end
			end
		end
		return hits
	end

	local function scoreInst(inst, names, opts)
		local s = 0
		local nm = inst.Name
		local disp = M.displayName(inst)
		for i, n in ipairs(names) do
			local w = (#names - i + 1)
			if nm == n then
				s = s + 50 + w
			end
			if disp == n then
				s = s + 45 + w
			end
			if inst:HasTag(n) then
				s = s + 40 + w
			end
			if inst:GetAttribute("NPCName") == n then
				s = s + 42 + w
			end
		end
		if isDialogue(inst) then
			s = s + 8
		end
		local parent = inst.Parent
		if parent and parent.Parent and parent.Parent.Name == "DialogueNPCs" then
			s = s + 12
		end
		if opts and opts.Island and islandOf(inst) == opts.Island then
			s = s + 6
		end
		if inRS(inst) then
			s = s - 200
		end
		return s
	end

	function M.dumpNearby(request, opts)
		opts = opts or {}
		local names = M.namesFor(request, opts)
		local origin
		local hrp = GB.World and GB.World.hrp and GB.World.hrp()
		if hrp then
			origin = hrp.Position
		end
		local cand = {}
		for _, root in ipairs(npcRoots()) do
			for _, d in ipairs(root:GetDescendants()) do
				if d:IsA("Model") and not inRS(d) then
					local disp = M.displayName(d)
					local low = string.lower(d.Name .. " " .. tostring(disp or ""))
					local want = false
					for _, n in ipairs(names) do
						if string.find(low, string.lower(n), 1, true) then
							want = true
							break
						end
					end
					if not want and (isDialogue(d) or d:FindFirstChildOfClass("Humanoid")) then
						local pos = M.positionOf(d)
						if origin and pos and (pos - origin).Magnitude < 90 then
							want = true
						end
					end
					if want then
						local pos = M.positionOf(d)
						local dist = (origin and pos) and math.floor((pos - origin).Magnitude) or -1
						cand[#cand + 1] = {
							Name = d.Name,
							ClassName = d.ClassName,
							DisplayName = disp,
							Parent = d.Parent and d.Parent.Name,
							Position = pos,
							Dist = dist,
							Score = scoreInst(d, names, opts),
						}
					end
				end
			end
		end
		table.sort(cand, function(a, b)
			if a.Score ~= b.Score then
				return a.Score > b.Score
			end
			local da = a.Dist >= 0 and a.Dist or 1e9
			local db = b.Dist >= 0 and b.Dist or 1e9
			return da < db
		end)
		local n = math.min(#cand, 8)
		local bits = {}
		for i = 1, n do
			local c = cand[i]
			bits[i] = string.format(
				"%s [%s] disp=%s parent=%s d=%s",
				c.Name,
				c.ClassName,
				tostring(c.DisplayName),
				tostring(c.Parent),
				tostring(c.Dist)
			)
		end
		GB.Log.warn(
			"RESOLVE",
			string.format("miss '%s' nearby=%d %s", tostring(request), #cand, table.concat(bits, " | "))
		)
		M.lastCandidates = {}
		for i = 1, n do
			local c = cand[i]
			M.lastCandidates[i] = {
				Name = c.Name,
				DisplayName = c.DisplayName,
				Parent = c.Parent,
				Dist = c.Dist,
			}
		end
		return cand
	end

	function M.resolve(request, opts)
		opts = opts or {}
		if type(request) ~= "string" or request == "" or request == "\\" then
			return nil
		end
		local kind0 = opts.ExpectedRole or opts.kind or "npc"
		if (kind0 == "enemy" or kind0 == "any") and M.isDummyName(request) then
			local d = M.dummy()
			return d and M.pack(d, request)
		end
		local names = M.namesFor(request, opts)
		local kind = opts.ExpectedRole or opts.kind or "npc"
		local cacheKey = "res:" .. kind .. ":" .. table.concat(names, "|")
		local hit = GB.Cache.get(cacheKey, opts.deep and 0.4 or 2.0)
		if hit and hit.Parent and usable(hit, kind) then
			return M.pack(hit, request)
		end

		local best, bestS
		local function consider(inst)
			if not usable(inst, kind) then
				return
			end
			local root = climbRoot(inst)
			if not root then
				return
			end
			if not (nameHit(root, names) or dialogueNameHit(root, names)) then
				return
			end
			local s = scoreInst(root, names, opts)
			if not bestS or s > bestS then
				best, bestS = root, s
			end
		end

		for _, n in ipairs(names) do
			local tagged = firstWorldTagged(n)
			if tagged then
				consider(tagged)
			end
		end

		local ents = workspace:FindFirstChild("Entities")
		if ents then
			for _, n in ipairs(names) do
				local c = ents:FindFirstChild(n)
				if c then
					consider(c)
				end
			end
		end

		local aa = workspace:FindFirstChild("AA IMPORTANT")
		local dlg = (aa and aa:FindFirstChild("DialogueNPCs")) or workspace:FindFirstChild("DialogueNPCs")
		if dlg then
			if opts.Island then
				local folder = dlg:FindFirstChild(opts.Island)
				if folder then
					for _, c in ipairs(folder:GetChildren()) do
						consider(c)
					end
				end
			end
			for _, islandFolder in ipairs(dlg:GetChildren()) do
				for _, c in ipairs(islandFolder:GetChildren()) do
					consider(c)
				end
			end
		end

		if not best or opts.deep then
			scanRoots(function(d)
				if d:IsA("Model") or d:IsA("Folder") or d:IsA("BasePart") then
					consider(d)
				end
				return false
			end, 1)
		end

		if best then
			GB.Cache.set(cacheKey, best)
			local pack = M.pack(best, request)
			GB.Log.log("RESOLVE", string.format("%s -> %s", request, best:GetFullName()))
			return pack
		end

		local now = os.clock()
		local mk = "miss:" .. request
		if not missLog[mk] or now - missLog[mk] > 8 then
			missLog[mk] = now
			GB.Log.warn("ERROR", "resolve miss " .. table.concat(names, " / "))
		end
		return nil
	end

	function M.byName(name, kind)
		local pack = M.resolve(name, { kind = kind or "any", ExpectedRole = kind })
		return pack and pack.Instance
	end

	function M.npc(name, opts)
		opts = opts or {}
		opts.ExpectedRole = opts.ExpectedRole or "npc"
		opts.kind = "npc"
		local pack = M.resolve(name, opts)
		return pack and pack.Instance
	end

	function M.resolveNPC(name, opts)
		opts = opts or {}
		opts.ExpectedRole = opts.ExpectedRole or "npc"
		opts.kind = "npc"
		return M.resolve(name, opts)
	end

	function M.enemies(name)
		local out = {}
		if name == "\\" or name == "" then
			return out
		end
		if M.isDummyName(name) then
			local d = M.dummy()
			if d then
				out[1] = d
			end
			return out
		end
		local origin
		local hrp = GB.World and GB.World.hrp and GB.World.hrp()
		if hrp then
			origin = hrp.Position
		end
		local seen = {}
		local names = M.namesFor(name, {})
		local function consider(inst)
			if not usable(inst, "enemy") then
				return
			end
			local root = climbRoot(inst) or inst
			if seen[root] or M.isPet(root) then
				return
			end
			if GB.Combat and GB.Combat.isRecentlyDead and GB.Combat.isRecentlyDead(root) then
				return
			end
			if GB.Combat and GB.Combat.IsEnemyAlive and not GB.Combat.IsEnemyAlive(root) then
				return
			end
			seen[root] = true
			local pos = M.positionOf(root)
			local d = (origin and pos) and (pos - origin).Magnitude or 1e9
			out[#out + 1] = { inst = root, dist = d }
		end
		for _, n in ipairs(names) do
			local ok, tagged = pcall(CS.GetTagged, CS, n)
			if ok and type(tagged) == "table" then
				for _, inst in ipairs(tagged) do
					consider(inst)
				end
			end
		end
		local ents = workspace:FindFirstChild("Entities")
		if ents then
			for _, c in ipairs(ents:GetChildren()) do
				if nameHit(c, names) then
					consider(c)
				end
			end
		end
		if #out == 0 then
			local pack = M.resolve(name, { kind = "enemy", ExpectedRole = "enemy" })
			if pack and pack.Instance then
				consider(pack.Instance)
			end
		end
		table.sort(out, function(a, b)
			return a.dist < b.dist
		end)
		local flat = {}
		for i, row in ipairs(out) do
			flat[i] = row.inst
		end
		return flat
	end

	function M.enemy(name)
		if name == "\\" or name == "" then
			return nil
		end
		if M.isDummyName(name) then
			return M.dummy()
		end
		local list = M.enemies(name)
		local best = list[1]
		if best then
			GB.Log.log("RESOLVE", string.format("%s -> %s", name, best:GetFullName()))
			return best
		end
		return nil
	end

	function M.taggedAny(tag)
		if type(tag) ~= "string" or tag == "" then
			return nil
		end
		for _, inst in ipairs(CS:GetTagged(tag)) do
			if inst.Parent and not inRS(inst) and not M.isPet(inst) then
				return inst
			end
		end
		return nil
	end

	function M.waitTagged(tag, timeout)
		timeout = timeout or 4
		local hit = firstWorldTagged(tag)
		if hit then
			return hit
		end
		local t0 = os.clock()
		local got
		local conn = CS:GetInstanceAddedSignal(tag):Connect(function(inst)
			if usable(inst, "npc") then
				got = climbRoot(inst)
			end
		end)
		while not got and os.clock() - t0 < timeout do
			got = firstWorldTagged(tag)
			if got then
				break
			end
			task.wait(0.15)
		end
		conn:Disconnect()
		return got
	end

	function M.shopItem(name)
		name = name or ""
		local cacheKey = "shop:" .. name
		local hit = GB.Cache.get(cacheKey, 4)
		if hit and hit.Parent then
			return hit
		end
		local tagged = M.taggedAny(name)
		if tagged and (tagged:GetAttribute("Interaction") == "Shop Item" or M.prompt(tagged, "Shop Item")) then
			local root = M.interactableOf and M.interactableOf(tagged) or tagged
			GB.Cache.set(cacheKey, root)
			return root
		end
		local function isShop(d)
			if d:IsA("ProximityPrompt") and d.Name == "Shop Item" then
				local p = d.Parent
				local item = p and (p:GetAttribute("Item") or p.Name)
				local climb = M.interactableOf and M.interactableOf(d)
				return item == name or (p and p.Name == name) or (climb and climb.Name == name)
			end
			if d:GetAttribute("Interaction") == "Shop Item" then
				return (d:GetAttribute("Item") or d.Name) == name
			end
			return false
		end
		local found = scanRoots(isShop, 6)
		if found[1] then
			local part = found[1]
			if part:IsA("ProximityPrompt") then
				part = (M.interactableOf and M.interactableOf(part)) or part.Parent
			end
			GB.Cache.set(cacheKey, part)
			return part
		end
		return M.byName(name, "shop")
	end

	function M.island(name)
		local isles = workspace:FindFirstChild("Islands")
		return isles and isles:FindFirstChild(name)
	end

	function M.dialogueConfig(model)
		if not model then
			return nil
		end
		local cfg = model:FindFirstChildWhichIsA("Configuration")
		if cfg then
			return cfg
		end
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("Configuration") then
				return d
			end
		end
		return nil
	end

	function M.prompt(model, interaction)
		if not model then
			return nil
		end
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("ProximityPrompt") then
				if not interaction or d.Name == interaction or d:GetAttribute("Interaction") == interaction then
					return d
				end
			end
		end
		return nil
	end

	function M.interactableOf(inst)
		local cur = inst
		while cur do
			if cur:HasTag("Interactable") or cur:HasTag("ClientInteractable") then
				return cur
			end
			cur = cur.Parent
		end
		return inst
	end

	function M.promptAnchor(inst)
		if not inst then
			return nil, nil
		end
		local pr = inst:IsA("ProximityPrompt") and inst or M.prompt(inst)
		if pr then
			local p = pr.Parent
			if p and p:IsA("Attachment") then
				return p.WorldPosition, p.WorldCFrame.LookVector, pr
			end
			if p and p:IsA("BasePart") then
				return p.Position, p.CFrame.LookVector, pr
			end
		end
		local hrp = inst:FindFirstChild("HumanoidRootPart", true)
		if hrp and hrp:IsA("Attachment") then
			return hrp.WorldPosition, hrp.WorldCFrame.LookVector, pr
		end
		if hrp and hrp:IsA("BasePart") then
			return hrp.Position, hrp.CFrame.LookVector, pr
		end
		return M.positionOf(inst), nil, pr
	end

	function M.ore()
		return M.byName("Copper Ore", "ore")
			or M.byName("Iron Ore", "ore")
			or M.byName("Lead Ore", "ore")
	end

	local function chestOpened(inst)
		return inst and inst:GetAttribute("Opened") == true
	end

	function M.chests()
		local out = {}
		local seen = {}
		local function add(inst)
			if not inst or seen[inst] or inRS(inst) or not inst.Parent then
				return
			end
			if chestOpened(inst) then
				return
			end
			seen[inst] = true
			out[#out + 1] = inst
		end
		for i = 1, 8 do
			local tagged
			pcall(function()
				tagged = CS:GetTagged("Afuaru's Chest " .. i)
			end)
			if tagged then
				for _, t in ipairs(tagged) do
					add(t)
				end
			end
		end
		local folder = workspace:FindFirstChild("Afuaru's Chests")
		if folder then
			for _, c in ipairs(folder:GetChildren()) do
				add(c)
			end
		end
		local interact
		pcall(function()
			interact = CS:GetTagged("ClientInteractable")
		end)
		if interact then
			for _, t in ipairs(interact) do
				local n = t.Name
				if string.find(n, "Afuaru", 1, true) and string.find(n, "Chest", 1, true) then
					add(t)
				end
			end
		end
		return out
	end

	function M.chest()
		local list = M.chests()
		if list[1] then
			return list[1]
		end
		return M.byName("Afuaru's Chests", "chest")
	end

	return M
end
