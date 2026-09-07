-- Boss = named kill on live/story quest. No invented HP/loot.

return function(GB)
	local M = {}

	local BOSSES = {
		["The Hoarder"] = "Afuaru, The Hoarder",
		["Axe-Handed Tyrant"] = "Axe-Hand Logan",
		["Tyrannical Captain"] = "Axe-Hand Logan",
		["Feral Dog"] = "Soro",
		["Captain's Brat"] = "Blonde Goblin",
		["The Ringmaster"] = "Choppy The Clown",
		["Choppy The Clown"] = "Choppy The Clown",
		["Stephon's Tormentor"] = "\"Barrel Clown\" Binki",
		["The Wandering Hypnotist"] = "\"Hypnotist\" Mango",
		["The Island's Protector"] = "Captain Esopo",
		["Undermine The Circus 3"] = "Choppy The Clown",
	}

	function M.tick()
		if not GB.Config.AutoBoss then
			return
		end
		local snap = GB.State.get()
		for name, target in pairs(BOSSES) do
			if GB.PlayerData.live(name) then
				if GB.Combat.lockMob and GB.Combat.IsEnemyAlive and not GB.Combat.IsEnemyAlive(GB.Combat.lockMob) then
					GB.Combat.stopLock()
				end
				GB.Combat.attack(target, name)
				return
			end
		end
	end

	return M
end
