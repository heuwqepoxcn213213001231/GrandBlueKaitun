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
		findTarget = function()
			error("Combat.findTarget must not run from Manual Mob selection")
		end,
		IsEnemyAlive = function(inst)
			return type(inst) == "table" and inst.alive ~= false
		end,
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

local findTargetCalls = 0
GB.Combat.findTarget = function()
	findTargetCalls = findTargetCalls + 1
	return nil
end
GB.Resolver = {
	_enemyRevision = 1,
	_chestRevision = 1,
	enemies = function()
		return {}
	end,
	positionOf = function()
		return nil
	end,
}
GB.Profiler = {
	begin = function()
		return os.clock()
	end,
	done = function()
		return 0
	end,
	count = function()
	end,
}

local fresh = factory(GB)
assert(fresh:setSelectedMobs({ '"Barrel Clown" Binki' }))
assert(fresh:setMobMode("NEAREST"))
assert(fresh:setOwner(fresh.OWNER.MANUAL_MOB, "binki_zero"))
fresh:tick()
assert(fresh.status == "WAIT_TARGET", "alive=0 must enter WAIT_TARGET")
assert(fresh._mobFarmState == "WAIT_TARGET")
assert(findTargetCalls == 0, "Manual Mob must not call Combat.findTarget")
local serialAfterWait = fresh._workSerial
for _ = 1, 24 do
	fresh:tick()
end
assert(fresh.status == "WAIT_TARGET", "missing target must stay WAIT_TARGET")
assert(fresh._workSerial == serialAfterWait, "WAIT_TARGET must not spawn extra workers")
assert(fresh._work == nil)
assert(findTargetCalls == 0)

GB.Resolver.enemies = function()
	return { { alive = true, Parent = true, Name = '"Barrel Clown" Binki' } }
end
GB.Resolver._enemyRevision = (GB.Resolver._enemyRevision or 1) + 1
fresh:tick()
assert(fresh.status ~= "WAIT_TARGET", "spawned live target must leave WAIT_TARGET")
assert(findTargetCalls == 0, "spawned target must use EnemyIndex only")

fresh:setSelectedMobs({})
fresh:tick()
assert(fresh.status == "WAIT_SELECTION", "empty selection must wait, not farm")
local emptySerial = fresh._workSerial
for _ = 1, 12 do
	fresh:tick()
end
assert(fresh._workSerial == emptySerial, "WAIT_SELECTION must not respawn workers")

local toggleSpawned = #spawned
local toggleSerial = fresh._workSerial
for _ = 1, 100 do
	fresh:setOwner(fresh.OWNER.MANUAL_MOB, "toggle_on")
	fresh:stop("toggle_off")
end
assert(fresh.owner == fresh.OWNER.IDLE)
assert(fresh._work == nil)
assert(#spawned == toggleSpawned, "100 toggles must not leak workers")
assert(fresh._workSerial == toggleSerial, "toggles must not start farm workers")

GB.Resolver.enemies = function()
	return {}
end
GB.Resolver._enemyRevision = (GB.Resolver._enemyRevision or 1) + 1
fresh:setSelectedBosses({ "Choppy The Clown" })
assert(fresh:setOwner(fresh.OWNER.MANUAL_BOSS, "boss_empty"))
fresh:tick()
assert(fresh.status == "WAIT_TARGET", "empty boss farm must WAIT_TARGET")
assert(findTargetCalls == 0)
local bossSerial = fresh._workSerial
for _ = 1, 8 do
	fresh:tick()
end
assert(fresh._workSerial == bossSerial)

fresh:destroy()
assert(fresh._destroyed == true)

controller:destroy()
assert(controller._destroyed == true)
assert(controller.owner == controller.OWNER.IDLE)

print("PASS ui_controller_spec")
