-- Codes:FireServer(code) VERIFIED. OnClientEvent ShowFeedback(text, ok).
-- CodeProg:FireServer() list; CodeProg:FireServer(code, index) claim.
-- Finite retries. Migrate getgenv().GBCodes.

return function(GB)
	local M = {
		i = 1,
		hooked = false,
		lastAt = 0,
	}

	local function classify(text, ok)
		text = string.lower(tostring(text or ""))
		if ok then
			if string.find(text, "already") then
				return "ALREADY_USED"
			end
			return "SUCCESS"
		end
		if string.find(text, "invalid") or string.find(text, "not found") then
			return "INVALID"
		end
		if string.find(text, "expir") then
			return "EXPIRED"
		end
		if string.find(text, "already") or string.find(text, "used") then
			return "ALREADY_USED"
		end
		return "ERROR"
	end

	function M.hook()
		if M.hooked then
			return
		end
		local r = GB.Remotes.get("Codes")
		if r then
			r.OnClientEvent:Connect(function(text, ok)
				local st = classify(text, ok)
				local cur = GB.Config.Codes[M.i]
				if cur then
					GB.Persist.codeState(cur, st)
					GB.Log.log("REWARD", "code " .. cur .. " " .. st .. " " .. tostring(text))
				end
			end)
			M.hooked = true
		end
		GB.Remotes.codeProg()
	end

	function M.tick()
		if not GB.Config.AutoCodes then
			return
		end
		M.hook()
		local list = GB.Config.Codes
		if M.i > #list then
			return
		end
		local code = list[M.i]
		local prev = GB.Persist.data.codes[code]
		if prev and (prev.state == "SUCCESS" or prev.state == "INVALID" or prev.state == "EXPIRED" or prev.state == "ALREADY_USED") then
			M.i = M.i + 1
			return
		end
		if os.clock() - M.lastAt < 2.8 then
			return
		end
		local tries = prev and prev.tries or 0
		if tries >= 2 then
			GB.Persist.codeState(code, "ERROR")
			M.i = M.i + 1
			return
		end
		GB.Persist.data.codes[code] = GB.Persist.data.codes[code] or {}
		GB.Persist.data.codes[code].tries = tries + 1
		GB.Persist.data.codes[code].state = "UNKNOWN"
		GB.Log.log("REWARD", "redeem " .. code)
		M.lastAt = os.clock()
		GB.Remotes.code(code)
	end

	return M
end
