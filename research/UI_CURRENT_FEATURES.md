# Grand Blue UI — Current Features (pre-NiaUI migration audit)

Audited from `UI/Hub.lua`, `UI/ManualController.lua`, `UI/RuntimeExtensions.lua`, and generated catalogs at HEAD `9ce9788` / UI 1.0.0. Game logic listed here must survive the NiaUI presentation swap.

## Home

- Live status: version, build, level, EXP, gold, island, quest, stage, objective, owner, target, movement, combat, farm session, last progress, respawn
- Start / Resume
- Pause
- Stop Current
- Stop All
- Refresh
- Self Check + result paragraph
- Auto Respawn
- Safe Fast Attack
- Auto Equip (utility flag)
- Auto Stats (utility flag)
- Anti AFK

## Auto Progress

- FULL_AUTO master toggle (DecisionEngine)
- Progress mode: Story First / Balanced / Level Rush / Manual Requirements
- Current intent / blocker
- Resume Story
- Farm Current Requirement (level / prerequisite / item / stat)
- Replan
- Stop Auto Progress

## Quests

- Story quest dropdown (39 actionable Main-chain)
- All-quest lookup
- Selected quest details + blocker
- Teleport to accept NPC
- Accept
- Run Once
- Auto-complete selected
- Stop
- Repeatable single + multi-select
- Repeat modes: ONE / ROTATE / BEST / NEAREST
- Farm until target level
- Resume Full Auto after level
- Auto Repeat continuous cycle
- Active quest manager (run / turn in / teleport objective / teleport turn-in)
- Completed quest lookup

## Mobs

- Multi-select from generated + EnemyIndex
- Modes: NEAREST / PRIORITY / ROUND_ROBIN / FINISH_GROUP
- Auto farm selected
- Stop
- Refresh live counts
- Combat range / tween speed / stickiness / switch distance

## Bosses

- Evidence-backed boss list
- Focus dropdown
- Status (alive / distance / island / quest / drops where known)
- Teleport
- Kill once
- Wait for spawn
- Auto farm
- Stop

## Teleport

- Physical islands (Anchor Town, Clown Town, Maple Village)
- Map dropdown + teleport
- Per-island buttons
- Searchable NPC teleport + related quests
- Important locations
- Cancel movement
- Buy / spawn rowboat

## Items / Equipment / Skills / Stats

- Searchable item list, source/status, acquire when method is allowed
- Live inventory paragraph
- Owned equipment, equip, unequip held, upgrade
- Preferred equipment + auto preferred
- Generated skills, equip, cast, linked quest
- Six-stat live status, presets, custom weights, quick invest, auto stats

## Life Skills / Fruit / Shop

- Mining multi-select + auto + mine once
- Verified copper smelt
- Partial fishing / farming / cooking steps
- Fruit status, catalog, pickup, auto pickup, store, permanent equip (eat disabled)
- Shop catalog, quantity, buy, quick buy, rowboat; sell status-only

## Haki / Race / Trait (Misc)

- Status paragraph
- Explicit confirmed aura-color reroll
- Explicit confirmed trait-slot reroll
- Race reroll status-only

## Chest / Treasure

- Map: CURRENT / Anchor Town
- Collect selected map / collect current map
- Auto chest
- Cancel
- Indexed status
- Treasure map inventory (dig unresolved)

## Codes / Rewards

- Known codes, redeem selected, redeem all, manual redeem
- Auto redeem on join (once)
- Verified reward claim
- Auto rewards (FULL_AUTO only)
- Battlepass / achievements status-only

## Settings / Debug

- Save / load / reset `GBKaitun/UIConfig.json`
- Resume actions on load (default false)
- Mirrored combat/tween/stickiness sliders
- Diagnostics, self check, dump, refresh indexes, clear intent

## Automation owners

`IDLE`, `FULL_AUTO`, `MANUAL_QUEST`, `MANUAL_MOB`, `MANUAL_BOSS`, `MANUAL_CHEST`

Exclusive owner. Mode switch cancels combat lock, movement, and the active worker.

## Custom UI to remove

`UI/NiaInline.lua` — window, tabs, toggle, dropdown, slider, textbox, paragraph, notifications, drag/resize. Not Grand Blue PlayerGui inspection.
