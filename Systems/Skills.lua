-- AutoSkills. PromptSkillEquip(name) VERIFIED for Tool skills after obtain popup.
-- EquipSkill RF: no client InvokeServer in Studio — do not invent.

return function(GB)
	local M = {
		tried = {},
	}

	function M.ensure(name)
		if not name then
			return false
		end
		if M.tried[name] and os.clock() - M.tried[name] < 8 then
			return false
		end
		M.tried[name] = os.clock()
		GB.Log.log("SKILL", "PromptSkillEquip " .. name)
		return GB.Remotes.promptSkillEquip(name)
	end

	function M.tick()
		if not GB.Config.AutoSkills then
			return
		end
		local live = GB.PlayerData.live("Basics")
		if live then
			M.ensure("Strong Punch")
		end
	end

	return M
end
