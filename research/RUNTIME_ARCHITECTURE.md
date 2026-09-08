# Runtime Architecture — 1.2.0

```
main/loader.lua?cb=os.time()
  → VERSION + manifest.json (branch tip, cache-bust)
  → validate version match
  → build.commit (immutable)
  → ONE HttpGet dist/kaitun.lua from that SHA
  → execute bundle
```

Production does **not** download Systems/*.lua individually.

DEV modular: `getgenv().GB_DEV = true` and `GB_DEV_MODULAR = true`. Optional `GB_PIN_COMMIT`. Stale `GB_BASE_URL` is ignored unless `GB_DEV`.

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
