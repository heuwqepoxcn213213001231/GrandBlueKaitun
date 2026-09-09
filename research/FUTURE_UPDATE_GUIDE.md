# Future Game-Update Guide

Research JSON / `data.json` stay the source of truth. Generated Lua is never hand-edited.

## When QuestInfo / dump changes

1. Replace `research/quests.json` (and `quest_specs.json` / `npcs.json` / `items.json` / `skills.json` if those dumps change).
2. `python3 tools/build_game_data.py`
3. `python3 tools/diff_game_data.py` — expect NEW / REMOVED / count drift.
4. `python3 tools/validate_game_data.py` — FAIL means a STATIC_VERIFIED main-route stage lost its plan.
5. `python3 tools/quest_route_validator.py`
6. `python3 tools/regression_tests.py`
7. Rebuild production file: `python3 tools/build_single.py && python3 tools/verify_single.py && python3 tools/verify_release.py`
8. Production is `main/kaitun.lua?cb=os.time()`. Do not publish a module-loader command.

## Resolver / path drift

If an island folder, tag, or DisplayName changes:

- Resolver logs a semantic miss (`RESOLVE` / `resolve miss`).
- It must **not** crash.
- Do not re-enable world `GetDescendants` to “just find it”.
- Add an alias or marker from Studio evidence, then regenerate.

## New quest

Prefer a new row in research JSON (Type, NPC, AcquireMethod, Marker, Validation).  
A new `if quest == "..."` branch in `Quest.lua` is a last resort for a unique mechanic (escort tag, jail smash), not for ordinary Talk/Kill/Collect.

## New remote

Add to `REMOTE_REGISTRY.md` and `build_game_data.py` `REMOTES` with Status.  
If Status ≠ VERIFIED, do not call it. `BeginQuest` stays BANNED.

## New tutorial overlay class

Add the module name to `TUTORIALS` in the compiler and `Tutorial.lua` overlay table.  
`getgc` / `getconnections` at most once per unknown class, then cache.

## Island 4

Do not invent. Current Studio `Workspace.Islands` has three folders. A fourth island is a dump+Studio event, then route tables update.
