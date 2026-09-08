# Data Integrity Report

**Version:** 1.1.42  
**Validator:** `tools/validate_game_data.py` + `tools/quest_route_validator.py`  
**Snapshot:** `research/_generated_snapshot.json`

## Counts (compiler)

| Entity | Count |
|---|---|
| Quests | 151 |
| Stages | 439 |
| NPCs | 156 |
| Items | 88 |
| Skills | 19 |
| Physical islands | 3 (Anchor Town, Clown Town, Maple Village) |
| Logical islands | Tutorial, Fighting Style, Crew, Skill Mastery |

## Coverage

| Slice | Stages | Implemented | Runtime verified | Unresolved |
|---|---|---|---|---|
| All | 439 | 373 | 12 | 66 |
| Anchor story | 58 | 58 | 12 | 0 |
| Clown story | 53 | 53 | 0 | 0 |
| Maple story | 53 | 52 | 0 | 1 |
| Main route | 164 | 163 | 12 | 1 |

Main-route unresolved: **The Black Noir Raid / Defend / Black Noir Raid**. Static validator does not fail this because status is UNRESOLVED (not STATIC_VERIFIED without a plan). Route validator PASSES.

## Repeatable start classification

| Kind | Notes |
|---|---|
| NPC_START | Granny's Nemesis, Officer Termination, Bullies in Suits, Clown/Maple repeats with AcceptNPC |
| AUTOMATIC | Story/logbook autos |
| UNRESOLVED_START | **Tyrannical Captain** — no AcceptNPC in QuestInfo. Farm must not kill the target to “start” it. |

## Validator rules

FAIL if:

- STATIC_VERIFIED / IMPLEMENTED main-route stage has no handler
- main-route missing validation
- AcquireItem with EnemyDrop/Shop/Mine and no source
- prerequisite cycle
- GeneratedData missing or stale banner
- unknown *physical* island (logical buckets allowed)

WARN only:

- UNKNOWN_NPC display-name drift
- REPEATABLE_NO_START (Tyrannical Captain)

## Diff

`tools/diff_game_data.py` writes `_generated_snapshot.prev.json` and reports NEW/REMOVED quest names on the next research change.

## Honesty

151 quest **definitions** are present and classified.  
373/439 stages have an executable handler in the audit table.  
66 stages remain UNRESOLVED (fighting-style mastery, arm wrestle, empty dailies, Defend raid, etc.). Those are fail-safe skips, not invented handlers.
