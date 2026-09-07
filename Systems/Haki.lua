-- Trainer / unlock quests UNRESOLVED after Studio search (no HakiTrainer, no Haki quest).
-- RerollAuraColor:FireServer() is color product, not unlock.

return function(GB)
	local M = { disabled = true, reason = "UNRESOLVED trainer/reqs" }

	function M.tick()
		if not GB.Config.AutoHaki then
			return
		end
		-- remain disabled even if flag flipped without evidence
		if M.disabled then
			return
		end
	end

	return M
end
