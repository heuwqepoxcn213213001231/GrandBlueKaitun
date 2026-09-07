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
	end

	function M.save()
		if not GB.Config.Persist or not canIO() then
			return
		end
		local s = encode(M.data)
		if s then
			pcall(writefile, M.path, s)
		end
	end

	function M.codeState(code, state)
		M.data.codes[code] = {
			state = state,
			at = os.time(),
		}
		getgenv().GBCodes = M.data.codes
		M.save()
	end

	function M.failRemote(name, why)
		M.data.failedRemotes[name] = {
			why = tostring(why),
			at = os.time(),
		}
		M.save()
	end

	function M.checkpoint(key, value)
		M.data.checkpoint[key] = value
		M.save()
	end

	return M
end
