# Continuous Execution Audit — 1.2.0

Rule: zero **unnecessary** idle. Required waits stay. Arbitrary `task.wait(1/2/5)` between ready tasks is a bug.

## Architecture

| Path | When | Work |
|---|---|---|
| FAST | FarmSession still optimal; no higher-priority turn-in | accept / objective / turn-in same quest |
| SLOW | context dirty, level gate, death, tutorial, miss | full DecisionEngine plan |
| ASYNC | GetData / GetStats | RemoteBroker single-flight; engine reads cache |

`Scheduler.nudge()` runs the next step as soon as a quest/stat/death event arrives. Tick budget is 0.15s cooperative, not a 2–5s rest.

## IdleReason

| Reason | Meaning |
|---|---|
| NONE | actionable intent running |
| WAIT_SERVER_REQUIRED | remote rate / replication |
| WAIT_CAN_SWING | combat cadence / lock in range |
| WAIT_STREAMING | target not loaded |
| WAIT_RESPAWN | death / revive / character |
| WAIT_DIALOGUE | accept / turn-in UI |
| WAIT_DATA | broker pending; other work may continue |
| NO_VALID_GOAL | nothing legal to do |
| UNNECESSARY | must not occur while Alive+Enabled+ProgressPossible |
| BUG_NO_PLAN | intent nil with progress possible → one diagnostic + replan |

`lock_active` is IN_PROGRESS, not real progress.

Real progress: quest count/stage/complete, EXP/level/gold/item/stat/tutorial, verified travel.

## Deliberate waits

| Site | Class | Condition |
|---|---|---|
| `Config.Tick` 0.15 | PERFORMANCE | cooperative scheduler; nudge breaks early |
| `Remotes.fire` gaps (Talk 0.8, Shop, Codes, …) | RATE_LIMIT | verified remote cadence |
| `CanSwing` / `minSwingInterval` | GAME_REQUIRED | server accepted M1 |
| `firePrompt` HoldDuration+0.12 | GAME_REQUIRED | proximity hold |
| `waitQuestAccepted` ≤2.4, poll 0.05 | GAME_REQUIRED | BeginQuest / live row |
| `waitProgress` ≤1.2, poll 0.05 | GAME_REQUIRED | QuestProgress / signature |
| dialogue linger ≤0.9 | GAME_REQUIRED | DialogueBindable / overlay |
| Broker minGap GetStats 0.35 / GetData 0.2 | RATE_LIMIT | single-flight |
| `Retry` 0.2/0.25 | RETRY_BACKOFF | exact failing resource |
| loader HttpGet retry 0.35 | RETRY_BACKOFF | source fetch only |
| loader previous-instance 0.12 | PERFORMANCE | unload before new GEN |
| Combat hover pin 1.8 deadzone | PERFORMANCE | avoid CFrame spam |
| World tween duration | GAME_REQUIRED | travel |
| Respawn character/HRP ready | GAME_REQUIRED | no 5–10s rest |
| `LIVE_SAFETY_TTL` 8s | RATE_LIMIT | async GetData only, not decide-thread Invoke |

## Removed / replaced

| Old | Replacement |
|---|---|
| `GB_BASE_URL = <old SHA>` production pin | main loader → manifest → `build.commit` bundle |
| Modular 40× HttpGet production | `dist/kaitun.lua` default |
| `refreshLive` InvokeServer on decide | cache + `Broker.request` |
| `pullStats` sync on decide | `requestStats` |
| `lock_active` → progressed=true | progressed=false |
| Post-talk `task.wait(0.35)` + 2.4 linger | dialogue-ready poll 0.05 |
| Accept wait 5.4 + 0.9 force refresh | event + async request |
| World `WorkspaceDeepScan` geo/spawn | FindFirstChildWhichIsA / children |
| PlayerGui full descendant scan | known overlay cache; debug flag only |
| Full replan every farm cycle | FarmSession fast path |
| Tick 0.4 hard wait | 0.15 + nudge |

## Game-native (do not suppress)

- `Crack` → `PerformanceModeStash` while parent is `BaseRock` — engine/VFX.
- `StateService` `GettingUp` — character state, not Kaitun Recovery.
- `TelemetryClient VOID` if movement still sky-yanks — travel clamp Y>120 + hover floor ray; remaining VOID is game or residual stream.

## Latency targets (static)

| Transition | Target |
|---|---|
| QuestClear → reaccept start | next scheduler cycle + dialogue ready |
| Target death → next mob | next combat tick / ChildAdded |
| Level gate met → story | same decide after `farmSessionClear` |
| Slow GetStats (~2s) | engine stays on cache; no decide stall |
