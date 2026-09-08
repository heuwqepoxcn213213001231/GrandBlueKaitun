# Game Knowledge Model

**Version:** 1.1.42  
**Compiler:** `tools/build_game_data.py`  
**Runtime:** `Game/GeneratedData.lua` (GENERATED) + `Game/Knowledge.lua`

Authority order:

1. `data.json` / QuestInfo / verified Studio callsite
2. research JSON (`quests.json`, `quest_specs.json`, `npcs.json`, `items.json`, `skills.json`)
3. live runtime state
4. current implementation
5. old reports

## Shape

```
GameKnowledge = {
  Quests, NPCs, Items, Skills, Islands, Story,
  Tutorials, Remotes, Shops, Subgoals, Coverage, Stages
}
```

Runtime does not HttpGet or JSON-parse research files after boot. Rebuild when research changes.

## QuestSpec (compact generated)

| Field | Source |
|---|---|
| Name, Type, Island, Automatic | `quests.json` |
| AcceptLevel, RangeMin/Max, NeedLevel | `quests.json` |
| Prerequisites, AcceptNPC, TurnInNPC | `quests.json` + `npcs.json` |
| Start | AUTOMATIC / NPC_START / UNRESOLVED_START |
| Stages | `quest_audit_lib.classify_all` + runtime overlays |

Stage row: Type, Goal, Target, Amount, AcquireMethod, Source, Marker, Handler, Validation, Status.

Do not encode hundreds of quest names in `Quest.lua`. Handlers are generic (`Talk`, `Kill`, `AcquireFromEnemyDrop`, `escort`, …).

## NPCSpec

From `npcs.json`: DisplayName, Islands, Accept, TurnIn, Talk, Markers.

Resolver consumes aliases + indexes. It does not rediscover NPC↔quest graphs every tick.

## ItemSpec

From `items.json` + classified acquire rows.

Policy default **UNKNOWN → KEEP**. Never auto-sell/drop UNKNOWN.

`Pirate Fan Letter` is **EnemyDrop / Corrupt Marine**, not a workspace name hunt.

## SkillSpec

From `skills.json`. No invented prerequisites. Fighting-style mastery chains stay UNRESOLVED unless research names the unlock action.

## Dialogue

Decline set is exact normalized phrases (`no`, `no.`, `cancel`, `bye`, …). No substring `"No"` match.

Priority: quest-linked metadata → command hints → Quest Glow → exact phrase → last-resort heuristic.

Click success ≠ quest success. Accept/turn-in wait for live ACTIVE / stage change.

## Blockers / subgoals

`Knowledge.currentBlockers()` + `Quest.CurrentBlockers()` emit `STAT_REQUIREMENT` / `LEVEL_REQUIREMENT`.  
Planner uses `GeneratedData.Subgoals` (First Upgrade stack already compiled). Recursive farm→buy→mine→smelt is bounded in `Planner.lua`.
