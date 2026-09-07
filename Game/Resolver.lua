-- Resolve NPC / enemy / item / island / shop / trainer / remote.
-- Search name, tag, attribute, known parent. On fail log candidates.

return function(GB)
	local CS = game:GetService("CollectionService")
	local RS = game:GetService("ReplicatedStorage")
	local M = {}

	-- ReplicatedStorage "Officer Graves" is character-create, not world.
	M.NPC_ALIAS = {
		["Officer Graves"] = "Officer Graves [2]",
		["Graves"] = "Officer Graves [2]",
	}

	local function aliveModel(m)
		if not (m and m.Parent) then
			return false
		end
		if m:IsA("Model") then
			local h = m:FindFirstChildOfClass("Humanoid")
			if h and h.Health <= 0 then
				return false
			end
			return m.PrimaryPart or m:FindFirstChild("HumanoidRootPart") or m:FindFirstChildWhichIsA("BasePart")
		end
		return m:IsA("BasePart")
	end

	local function partOf(inst)
		if not inst then
			return nil
		end
		if inst:IsA("BasePart") then
			return inst
		end
		if inst:IsA("Model") then
			return inst.PrimaryPart or inst:FindFirstChild("HumanoidRootPart") or inst:FindFirstChildWhichIsA("BasePart")
		end
		if inst:IsA("ProximityPrompt") then
			return inst.Parent and (inst.Parent:IsA("BasePart") and inst.Parent or inst.Parent:FindFirstChildWhichIsA("BasePart"))
		end
		return inst:FindFirstChildWhichIsA("BasePart", true)
	end

	function M.part(inst)
		return partOf(inst)
	end

	function M.displayName(model)
		if not model then
			return nil
		end
		local h = model:FindFirstChildOfClass("Humanoid")
		if h and h.DisplayName and h.DisplayName ~= "" then
			return h.DisplayName
		end
		return model.Name
	end

	local function scan(pred, limit)
		limit = limit or 8
		local hits = {}
		local folders = {
			workspace:FindFirstChild("Entities"),
			workspace:FindFirstChild("Islands"),
			workspace,
		}
		for _, root in ipairs(folders) do
			if root then
				for _, d in ipairs(root:GetDescendants()) do
					if pred(d) then
						table.insert(hits, d)
						if #hits >= limit then
							return hits
						end
					end
				end
			end
		end
		return hits
	end

	function M.byName(name, kind)
		if not name or name == "" or name == "\\" then
			return nil
		end
		name = M.NPC_ALIAS[name] or name
		local cacheKey = "res:" .. (kind or "any") .. ":" .. name
		local hit = GB.Cache.get(cacheKey, 1.8)
		if hit and hit.Parent then
			return hit
		end

		-- CollectionService tag
		local ok, tagged = pcall(CS.GetTagged, CS, name)
		if ok then
			for _, t in ipairs(tagged) do
				if aliveModel(t) and not RS:IsAncestorOf(t) then
					GB.Cache.set(cacheKey, t)
					return t
				end
			end
		end

		local function match(d)
			if RS:IsAncestorOf(d) then
				return false
			end
			if not aliveModel(d) then
				return false
			end
			if d.Name == name then
				return true
			end
			local h = d:FindFirstChildOfClass("Humanoid")
			if h and h.DisplayName == name then
				return true
			end
			if d:GetAttribute("Item") == name then
				return true
			end
			return false
		end

		local ents = workspace:FindFirstChild("Entities")
		if ents then
			local c = ents:FindFirstChild(name)
			if c and aliveModel(c) then
				GB.Cache.set(cacheKey, c)
				return c
			end
		end

		local found = scan(match, 4)
		if found[1] then
			GB.Cache.set(cacheKey, found[1])
			return found[1]
		end

		-- fuzzy
		local lower = string.lower(name)
		local cand = scan(function(d)
			if RS:IsAncestorOf(d) or not d:IsA("Model") then
				return false
			end
			return string.find(string.lower(d.Name), lower, 1, true) ~= nil
		end, 6)
		if #cand > 0 then
			GB.Log.warn("ERROR", "resolve fail exact '" .. name .. "' candidates=" .. table.concat((function()
				local n = {}
				for i, v in ipairs(cand) do
					n[i] = v.Name
				end
				return n
			end)(), ","))
			if cand[1] then
				GB.Cache.set(cacheKey, cand[1])
				return cand[1]
			end
		else
			GB.Log.warn("ERROR", "resolve miss " .. tostring(name))
		end
		return nil
	end

	function M.npc(name)
		return M.byName(name, "npc")
	end

	function M.enemy(name)
		-- Kill-name fixes from Studio quest modules (dump used `\`)
		if name == "\\" or name == "" then
			return nil
		end
		return M.byName(name, "enemy")
	end

	function M.shopItem(name)
		name = name or ""
		local cacheKey = "shop:" .. name
		local hit = GB.Cache.get(cacheKey, 4)
		if hit and hit.Parent then
			return hit
		end
		local function isShop(d)
			if d:IsA("ProximityPrompt") and d.Name == "Shop Item" then
				local p = d.Parent
				local item = p and (p:GetAttribute("Item") or p.Name)
				return item == name or (p and p.Name == name)
			end
			if d:GetAttribute("Interaction") == "Shop Item" then
				return (d:GetAttribute("Item") or d.Name) == name
			end
			return false
		end
		local found = scan(isShop, 6)
		if found[1] then
			local part = found[1]
			if part:IsA("ProximityPrompt") then
				part = part.Parent
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

	function M.ore()
		return M.byName("Copper Ore", "ore")
			or M.byName("Iron Ore", "ore")
			or M.byName("Lead Ore", "ore")
	end

	function M.chest()
		local tagged
		pcall(function()
			tagged = CS:GetTagged("Afuaru's Chests")
		end)
		if tagged and tagged[1] then
			return tagged[1]
		end
		return M.byName("Afuaru's Chests", "chest")
	end

	return M
end
