-- Grand Blue (Eternal Pose) — engine boot
-- Production: run loader.lua (HttpGet). Do not load this file as the one-liner.
-- Modules are injected by the loader. This file only starts the engine.

return function(GB)
	if type(GB) ~= "table" or type(GB.Config) ~= "table" then
		error("[Kaitun][BOOT] run loader.lua — modules not injected")
	end

	GB.Persist.load()
	GB.Remotes.statReplicate()

	function GB.unload()
		getgenv()._GBKaitunGen = (GB.gen or 0) + 1
		if GB.Scheduler then
			GB.Scheduler.stop()
		end
		if GB.Combat then
			pcall(GB.Combat.stopLock)
		end
		for _, c in ipairs(GB.conns) do
			pcall(function()
				c:Disconnect()
			end)
		end
		GB.conns = {}
		if GB.Persist then
			GB.Persist.save()
		end
		print("[Kaitun][BOOT] unloaded")
	end

	getgenv()._GBKaitunUnload = GB.unload

	GB.conns[#GB.conns + 1] = GB.lp.CharacterAdded:Connect(function()
		task.wait(0.4)
		if GB.dead() then
			return
		end
		GB.Cache.invalidate()
		GB.Remotes.statReplicate()
		if GB.Combat then
			GB.Combat.stopLock()
		end
		GB.Log.log("STATE", "respawn")
	end)

	GB.Scheduler.add("recovery", function()
		GB.Recovery.tick()
		GB.World.rememberSafe()
	end, 0.5)

	GB.Scheduler.add("combat", function()
		GB.Combat.tick()
	end, 0.2)

	GB.Scheduler.add("engine", function()
		GB.Engine.decide()
	end, 0)

	GB.Scheduler.start()

	getgenv().GBKaitun = GB
	getgenv().GBConfig = GB.Config
	getgenv().GB_VERSION = getgenv().GB_VERSION or (getgenv()._GBKaitunLoader and getgenv()._GBKaitunLoader.VERSION)

	local s = GB.State.refresh()
	GB.Log.log("BOOT", string.format("lv%s island=%s gold=%s", tostring(s.Level), tostring(s.CurrentIsland), tostring(s.Gold)))
	print("[Kaitun][BOOT] ready — GBKaitun / GBConfig / GB_VERSION")
	return GB
end
