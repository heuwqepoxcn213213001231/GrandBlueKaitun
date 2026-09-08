# Scenario Tests — 1.2.0

Runner: `python3 tools/scenario_tests.py`

Static behavioral contracts. Not a live 30-minute profile.

| Scenario | Assertion |
|---|---|
| Repeat cycle zero-idle | FarmSession + `cycle_reaccept` after clear |
| Complete → turn-in | `pickTurnInActive` / `QUEST_TURNIN` before new combat |
| Turn-in → accept | fast path `quest_accept` same quest; no 2–5s sleep |
| Level gate → story | `farmSessionClear("level_met")` then story |
| Death → revive | Respawn owner; no `LoadCharacter`; resume from live cache |
| Target dead → next | `onTargetDead` dirty + nudge; lock released |
| Multi active quests | `scoreActive` remaining/turn-in/story/locality |
| Server delay | Broker pending → WAIT_DATA; decide returns cache |
| Streaming delay | SkipStream/marker; no WorkspaceDeepScan |
| lock_active | progressed=false |
| Loader | no DEFAULT_BOOTSTRAP_REF; PinBuild; ignore GB_BASE_URL |
| SelfCheck | present |

Timing (mocked / static): next accept begins on next scheduler cycle after QuestClear, not after `task.wait(2)`.
