-- Optional persist. writefile/readfile if present; no crash without FS.
-- Live PlayerState always wins.

return function(GB)
	local M = {
		path = "GBKaitun_persist.json",
		data = {
			codes = {},
			checkpoint = {},
			failedRemotes = {},
			session = nil,
		},
		_lastSaved = nil,
		_lastSaveAt = 0,
	}

	local function canIO()
		return typeof(isfile) == "function" and typeof(readfile) == "function" and typeof(writefile) == "function"
	end

	local function encode(t)
		local ok, Http = pcall(function()
			return game:GetService("HttpService")
		end)
		if ok and Http then
			local s, r = pcall(Http.JSONEncode, Http, t)
			if s then
				return r
			end
		end
		return nil
	end

	local function decode(s)
		local ok, Http = pcall(function()
			return game:GetService("HttpService")
		end)
		if ok and Http then
			local s2, r = pcall(Http.JSONDecode, Http, s)
			if s2 and type(r) == "table" then
				return r
			end
		end
		return nil
	end

	local function sameValue(a, b)
		if type(a) ~= type(b) then
			return false
		end
		if type(a) ~= "table" then
			return a == b
		end
		local seen = {}
		for k, v in pairs(a) do
			if not sameValue(v, b[k]) then
				return false
			end
			seen[k] = true
		end
		for k in pairs(b) do
			if not seen[k] then
				return false
			end
		end
		return true
	end

	function M.load()
		if not M.data.session then
			M.data.session = "s" .. tostring(os.time())
		end
		if not GB.Config.Persist or not canIO() then
			return
		end
		if isfile(M.path) then
			local raw = readfile(M.path)
			local t = decode(raw)
			if type(t) == "table" then
				if type(t.codes) == "table" then
					M.data.codes = t.codes
				end
				if type(t.checkpoint) == "table" then
					M.data.checkpoint = t.checkpoint
				end
				if type(t.failedRemotes) == "table" then
					M.data.failedRemotes = t.failedRemotes
				end
				if type(t.session) == "string" then
					M.data.session = t.session
				end
			end
		end
		if not M.data.session then
			M.data.session = "s" .. tostring(os.time())
		end
		if type(getgenv().GBCodes) == "table" then
			for k, v in pairs(getgenv().GBCodes) do
				M.data.codes[k] = v
			end
		end
		getgenv().GBCodes = M.data.codes
		M._lastSaved = encode(M.data)
		M._lastSaveAt = os.clock()
	end

	function M.save(force)
		if not GB.Config.Persist or not canIO() then
			return false
		end
		local s = encode(M.data)
		if s then
			if not force and M._lastSaved == s and os.clock() - (M._lastSaveAt or 0) < 2.5 then
				return false
			end
			pcall(writefile, M.path, s)
			M._lastSaved = s
			M._lastSaveAt = os.clock()
			if GB.Profiler and GB.Profiler.count then
				GB.Profiler.count("PersistWrite", 1)
			end
			return true
		end
		return false
	end

	function M.codeState(code, state)
		local prev = M.data.codes[code]
		if type(prev) == "table" and prev.state == state then
			return false
		end
		M.data.codes[code] = {
			state = state,
			at = os.time(),
		}
		getgenv().GBCodes = M.data.codes
		return M.save()
	end

	function M.failRemote(name, why)
		local prev = M.data.failedRemotes[name]
		if type(prev) == "table" and tostring(prev.why) == tostring(why) then
			return false
		end
		M.data.failedRemotes[name] = {
			why = tostring(why),
			at = os.time(),
		}
		return M.save()
	end

	function M.checkpoint(key, value)
		if sameValue(M.data.checkpoint[key], value) then
			return false
		end
		M.data.checkpoint[key] = value
		return M.save()
	end

	return M
end
