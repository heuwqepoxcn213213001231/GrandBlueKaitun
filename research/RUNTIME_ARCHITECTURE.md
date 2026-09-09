# Runtime Architecture — 1.3.0

```
main/kaitun.lua?cb=os.time()
  → one HttpGet
  → one compile
  → session log + singleton replace
  → inline Core / Data / Game / Systems / Progression
  → Ready
```

No VERSION fetch. No manifest. No `dist/` module-string bundle. No `GB.Load` / `LoadModule`. `loader.lua` is retired.

```
Events (BeginQuest/ClearQuest/QuestProgress/…)
  → PlayerData dirty + Broker.request GetData
  → Scheduler.nudge
  → DecisionEngine FAST or SLOW
Combat Heartbeat
  → alive / hover / CanSwing only
  → no GetData
DecisionEngine
  → cache only
  → FarmSession fast path when optimal
RemoteBroker
  → single-flight GetStats / GetData
  → generation ignored after reload
```

Owner priority: RESPAWN → TUTORIAL → DIALOGUE → QUEST_TURNIN → QUEST_ACCEPT → QUEST_OBJECTIVE → COMBAT → TRAVEL → SUBGOAL → FARM.

`GBKaitun:SelfCheck()` reports Enabled, Alive, Version, Build, Intent, Owner, Quest, FarmSession, IdleReason, RemotePending, LastProgress, ProfilerWorst.

Teleport: `queue_on_teleport` queues the same `main/kaitun.lua` one-liner.
