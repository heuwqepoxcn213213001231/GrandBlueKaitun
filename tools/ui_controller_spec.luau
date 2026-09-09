local spawned = {}

task = {
	spawn = function(target, ...)
		local thread = type(target) == "thread" and target or coroutine.create(target)
		spawned[#spawned + 1] = thread
		local ok, err = coroutine.resume(thread, ...)
		assert(ok, tostring(err))
		return thread
	end,
	cancel = function(thread)
		if type(thread) == "thread" and coroutine.status(thread) ~= "dead" then
			pcall(coroutine.close, thread)
		end
	end,
}

game = {
	GetService = function()
		return nil
	end,
}

local function noop()
	return true
end

local GB = {
	Config = {
		Enabled = true,
		AutoQuest = true,
		AutoLevel = true,
		AutoStats = true,
		AutoEquip = true,
		AutoCodes = true,
		AutoBoss = true,
		AutoChest = true,
		AutoRewards = true,
	},
	Tasks = {},
	Log = {
		log = noop,
		warn = noop,
		err = noop,
	},
	Scheduler = {
		nudge = noop,
	},
	Combat = {
		stopLock = noop,
	},
	World = {
		cancelTween = noop,
	},
	Knowledge = {
		invalidateContext = noop,
	},
	Engine = {
		markContextDirty = noop,
	},
	Respawn = {
		Detect = noop,
		isBusy = function()
			return false
		end,
	},
	State = {
		get = function()
			return { Alive = true, Level = 1 }
		end,
		refresh = function()
			return { Alive = true, Level = 1 }
		end,
	},
	dead = function()
		return false
	end,
}
GB.Engine.decide = function()
	GB.Engine.decisions = (GB.Engine.decisions or 0) + 1
end

local factory = require("../UI/ManualController")
assert(type(factory) == "function", "ManualController module must return a factory")
local moduleEnvironment = getfenv(factory)
setfenv(factory, setmetatable({
	task = task,
	game = game,
}, { __index = moduleEnvironment }))
local controller = factory(GB)

assert(controller.owner == controller.OWNER.IDLE, "controller must start IDLE")
assert(GB.Config.AutoQuest == false, "dangerous autos must be gated at construction")
assert(GB.Config.AutoStats == false, "utility autos must default off")

assert(controller:setSelectedMobs({ "Bandit", "Marine", "Bandit" }))
assert(#controller.selectedMobs == 2, "mob selection must deduplicate")
assert(controller:setMobMode("PRIORITY"))
assert(controller:setOwner(controller.OWNER.MANUAL_MOB, "spec"))
assert(controller.owner == controller.OWNER.MANUAL_MOB)

local ran = 0
local queued, handle = controller:enqueue("instant", function()
	ran = ran + 1
	return true, "done"
end, { cancelActive = false })
assert(queued and handle, "instant action must queue")
controller:tick()
assert(ran == 1, "queued action must execute")
assert(handle.Completed == true and handle.Running == false, "completed handle state must commit")

local blockedQueued, blocked = controller:enqueue("blocked", function()
	coroutine.yield("waiting")
	return true
end)
assert(blockedQueued and blocked)
controller:tick()
assert(blocked.Running == true, "yielded action must be tracked")
assert(controller:getSnapshot().workTask ~= nil, "snapshot must expose active work")
controller:setOwner(controller.OWNER.IDLE, "cancel")
assert(blocked.Cancelled == true and blocked.Running == false, "owner change must cancel exact worker")
assert(controller:getSnapshot().workTask == nil, "cancelled work must clear")

assert(controller:setUtilityAuto("AutoStats", true))
assert(GB.Config.AutoStats == true, "safe utility selection must be consumed while IDLE")
controller:setOwner(controller.OWNER.FULL_AUTO, "full")
controller:tick()
assert(GB.Engine.decisions == 1, "FULL_AUTO must call the proven Engine")
controller:stop("off")
assert(controller.owner == controller.OWNER.IDLE)

controller:destroy()
assert(controller._destroyed == true)
assert(controller.owner == controller.OWNER.IDLE)

print("PASS ui_controller_spec")
