# Regression Tests

Runner: `python3 tools/regression_tests.py`  
These are **static** checks. A PASS means the current source still contains the fix. It is not a live playthrough.

| Case | What is asserted | Result |
|---|---|---|
| Officer Graves | Resolver alias `Officer Graves` ↔ `[2]` | STATIC |
| Dialogue ImageButton | Decline exact set includes `no` / `no.`; no substring `"No"` | STATIC |
| Pirate Fan Letter | Generated stage Collect = EnemyDrop / Corrupt Marine | STATIC |
| Dead enemy corpse | `IsEnemyAlive` + `onTargetDead`; Heartbeat does not `refreshLive` | STATIC |
| Gearing Up backpack | Tutorial IDs EquipFlintlock / SellWatch present | STATIC |
| SkillObtained continue | Tutorial ID present; ContinueOverlay path | STATIC |
| Gate of Authority | STAT_REQUIREMENT blocker in Knowledge/Quest | STATIC |
| Granny's Nemesis | REPEAT_START metadata | STATIC |
| Multi-condition | `Quest.unfinishedConditions` | STATIC |
| Corrupt Guard streaming | Resolver aliases + marker travel (no hot deep scan) | STATIC |
| Resolver freeze | `DebugResolverDeepScan` default false | STATIC |
| Stat allocation | `GetSnapshot` + canary pause | STATIC |
| Death / respawn | Phase machine; no `LoadCharacter` | STATIC |
| BeginQuest | `Remotes.fire` bans the name | STATIC |
| Version integrity | VERSION == manifest | STATIC |
| FarmSession / lock_active | session + progressed=false | STATIC |
| Loader pin | no DEFAULT_BOOTSTRAP_REF; PinBuild | STATIC |
| RemoteBroker | PlayerData cache-only refresh | STATIC |
| SelfCheck | `GB.SelfCheck` | STATIC |

Also: `python3 tools/scenario_tests.py`.

Live playthrough of Fresh→Anchor→Clown→Maple is still **RUNTIME required**.
