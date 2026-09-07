# PERFORMANCE AUDIT — GrandBlueKaitun

Scope: static root-cause audit + instrumentation pass on current `main` source, with runtime counters wired for 15-30 minute validation sessions (`PerfDebug=true`).

## 1) Combat Heartbeat → Quest Polling Hitch

- **Hotspot:** `Systems/Combat.lua` previously called `questCombatDone()` from `RunService.Heartbeat` and `huntUntilDead()` loops.
- **Old frequency:** up to frame rate (`~60Hz`) in heartbeat + extra `~8Hz` in hunt loop.
- **Why it hitches:** old path invalidated quest cache and forced refresh path, creating repeated quest-state work and potential `GetData` pressure under combat.
- **Fix:** heartbeat is now combat-local only (alive check, distance/reposition, swing). Quest validation moved to slow path (`Combat.tick`) with bounded gaps (`QUEST_CHECK_MIN_GAP`, `QUEST_CHECK_SAFETY`) and dirty/safety policy via `PlayerData`.
- **New frequency:** bounded slow checks (target ~2-4Hz), event/dirty-driven refresh; force refresh only on meaningful events (kill credit, explicit validation).
- **Verification status:** IMPLEMENTED (static), runtime counters required.

## 2) PlayerData Live Refresh Model

- **Hotspot:** `Game/PlayerData.lua` used aggressive TTL polling (`0.85s`) even without quest changes.
- **Old frequency:** periodic live refresh opportunities regardless of actual quest updates.
- **Why it hitches:** repeated remote-read attempts and quest reconstruction while state is unchanged.
- **Fix:** event-driven model with `_questDirty` + `LIVE_SAFETY_TTL` fallback; quest events mark dirty (`BeginQuest`, `ClearQuest`, `QuestProgress`, `UpdateQuestState`, `QuestsChanged`). Added `forceQuestRefresh()` for post-action validation only.
- **New frequency:** one fetch on dirty transition, otherwise cached reads; safety refresh on slow interval.
- **Verification status:** IMPLEMENTED (static), runtime counters required.

## 3) Stats Ownership + Validation Semantics

- **Hotspot A:** duplicate ownership of `Stats.tick` (`kaitun` scheduler + decision cycle).
- **Hotspot B:** optimistic/predicted success logging risk in stat investment flow.
- **Old frequency:** multiple independent tick callsites; potential overlapping behavior and noisy retries.
- **Fix A:** removed dedicated scheduler stats job; DecisionEngine owns one stat pass per decision cycle.
- **Fix B:** stats path remains strict before/after validation with pending verification; no success unless real delta is observed.
- **Fix C:** added stat dirty flags (`markDirty`) tied to state transitions/events.
- **New frequency:** single pipeline, one point per action path until verified.
- **Verification status:** IMPLEMENTED_UNVERIFIED (requires live 1-point canary evidence).

## 4) Stats GUI Scan Cost

- **Hotspot:** GUI fallback path in stats/tuto overlays could trigger broad scans repeatedly.
- **Old frequency:** frequent fallback checks with short GUI cache windows.
- **Fix:** GUI fallback remains diagnostic-only with longer cache windows and counters (`PlayerGuiFullScan`), while primary source is remote/stat replication state.
- **New frequency:** only when authoritative sources are missing/stale and fallback path is needed.
- **Verification status:** IMPLEMENTED (static), runtime counters required.

## 5) Resolver Deep Scan Repetition

- **Hotspot:** resolver miss paths and diagnostics can repeatedly deep-scan descendants.
- **Old frequency:** repeated deep scans for identical misses.
- **Fix:** added negative miss cache with TTL + invalidation on relevant world changes; added scoped cache invalidation and deep-scan counters (`ResolverDeepScan`).
- **New frequency:** repeated misses are throttled; deep scan mostly discovery/diagnostic path.
- **Verification status:** IMPLEMENTED (static), runtime counters required.

## 6) Tutorial Introspection (`getgc` / `getconnections`)

- **Hotspot:** continuation handling can be expensive if introspection repeats every attempt.
- **Old frequency:** potential repeated scans on same overlay when unresolved.
- **Fix:** continuation handler cache keyed by overlay type (`SkillObtained`, `TutorialScreen`); retry backoff before re-running heavy discovery; counters for `getgc` and `getconnections`.
- **New frequency:** first-discovery heavy, then cached replay unless cached handler fails.
- **Verification status:** IMPLEMENTED (static), runtime counters required.

## 7) File I/O and Runtime Logs

- **Hotspot:** runtime diagnostics and persist writes can grow or write too often during long sessions.
- **Fix A:** runtime diagnostics now configurable (`RuntimeDiagnostics`), bounded by `RuntimeLogMaxBytes` and `RuntimeLogMaxFiles`, with rotating files and throttled `latest` writes.
- **Fix B:** `Persist.save()` dedupes unchanged payloads; checkpoint/failRemote/code-state avoid redundant writes.
- **Fix C:** counters wired (`RuntimeFileWrite`, `PersistWrite`).
- **Verification status:** IMPLEMENTED (static), runtime counters required.

## 8) Cache/Retry/Logger Memory Boundedness

- **Hotspot:** unbounded key growth in cache/retry/logger dedupe maps.
- **Fix:** incremental pruning + max-key caps across `Core/Cache.lua`, `Core/Retry.lua`, `Core/Logger.lua`; added scoped invalidate helpers.
- **Verification status:** IMPLEMENTED (static), long-run runtime recommended.

## 9) Source HTTP After Boot

- **Hotspot hypothesis:** periodic freezes suspected to be GitHub/source HTTP.
- **Fix:** loader now counts source HTTP calls (`_GBSourceHttpCount`), profiler reports `SourceHttp` rate/min and `SourceHttpAfterBoot`.
- **Expected runtime:** after `[Kaitun][BOOT]`, `SourceHttpAfterBoot` should remain `0` unless explicit source fetch is triggered.
- **Verification status:** IMPLEMENTED (instrumented), runtime proof required.

## 10) Static Search Classification (Current Pass)

- **BUILD/BOOT path:** `loader.lua` (`HttpGet*`, source fetch), build scripts in `tools/`.
- **HOT path (must stay cheap):** `Combat.startLock` heartbeat body, `Scheduler.step`, `DecisionEngine.decide`.
- **SLOW/EVENT path:** `Combat` quest slow validation (`combat_tick`), `PlayerData` dirty refresh, tutorial gate execution.
- **DISCOVERY/DIAGNOSTIC path:** resolver deep scans, `dumpNearby`, broad workspace scans.
- **FILE I/O path:** runtime diagnostics in `kaitun.lua`, persistence writes in `Core/Persist.lua`.

## Runtime Validation Checklist (PerfDebug Session)

- Confirm `SourceHttpAfterBoot=0`.
- Confirm `HeartbeatQuestCheck` is bounded and no per-frame `GetDataQuests`.
- Confirm `GetDataQuests`, `GetStats`, `StatInvest` rates are stable and action-driven.
- Confirm `PlayerGuiFullScan`, `ResolverDeepScan`, `WorkspaceDeepScan`, `getgc`, `getconnections` are low in steady state.
- Confirm spikes print as `[Kaitun][PERF][SPIKE] <op> <ms>`.

Overall status: IMPLEMENTED instrumentation + root-cause refactors complete in source; runtime verification remains mandatory before claiming `RUNTIME_VERIFIED`.
