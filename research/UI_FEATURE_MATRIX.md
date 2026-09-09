# Grand Blue UI Feature Matrix

Generated from the current 1.3.2 runtime, `data.json`, generated catalogs, and the complete research corpus. Implementation status is checked by `tools/verify_ui.py` and `tools/ui_scenario_tests.py`.

Status:

- `RUNTIME_VERIFIED`: observed working in live runtime logs or tutorial execution.
- `STATIC_VERIFIED`: exact data/path/remote is known, but the UI action still needs live validation.
- `PARTIAL`: only the evidenced subset is exposed.
- `UNRESOLVED`: status is visible; no action is emitted.
- `DISABLED`: unsafe or insufficiently specified action is intentionally absent.

| Feature | Game system | Research source | Runtime status | UI control | Tab | Implementation status | Validation method |
|---|---|---|---|---|---|---|---|
| Live player status | State / PlayerData | `A_system_map.md`, runtime `State.lua` | RUNTIME_VERIFIED | Live paragraph | Home | IMPLEMENTED | State snapshot and async quest/stat caches |
| Full Auto / pause / resume / stop all | Scheduler | `RUNTIME_ARCHITECTURE.md`, `FULL_SYSTEM_AUDIT.md` | RUNTIME_VERIFIED | Toggle / buttons | Home | IMPLEMENTED | Scheduler enabled state, owner and intent reset |
| Auto respawn | Respawn | `RUNTIME_FIXES.md`, `REGRESSION_TESTS.md` | RUNTIME_VERIFIED | Toggle | Home | IMPLEMENTED | Respawn phase and restored character |
| Safe fast attack | Combat | `REMOTE_REGISTRY.md`, `RUNTIME_FIXES.md` | RUNTIME_VERIFIED | Toggle | Home / Mobs | IMPLEMENTED | Accepted attacks and target HP delta |
| Anti-AFK | Client utility | Current runtime policy | STATIC_VERIFIED | Toggle | Home | IMPLEMENTED | Local idle connection remains active |
| Self check | Boot diagnostics | `FULL_SYSTEM_AUDIT.md` | RUNTIME_VERIFIED | Button / paragraph | Home / Debug | IMPLEMENTED | `GB.SelfCheck()` result |
| Story quest catalog | QuestData | `quests.json`, `C_island_quest_route.md` | STATIC_VERIFIED | Searchable dropdown | Quests | IMPLEMENTED | 39 actionable Main-chain quests; archived/skipped rows remain in All Quest Lookup |
| Story quest details | QuestData / QuestSpecs | `quests.json`, `quest_specs.json` | STATIC_VERIFIED | Paragraph | Quests | IMPLEMENTED | Exact metadata and stage rows |
| Teleport to quest NPC | Resolver / World | `npcs.json`, `QUEST_EXECUTION_MATRIX.md` | STATIC_VERIFIED | Button | Quests | IMPLEMENTED | Resolved NPC and movement destination |
| Accept selected quest | Quest | `QUEST_EXECUTION_MATRIX.md`, `REMOTE_REGISTRY.md` | STATIC_VERIFIED | Button | Quests | IMPLEMENTED | Quest becomes live; automatic quests use verified path |
| Run selected quest once | Quest / Planner | `PROGRESSION_FINAL.md`, current runtime | PARTIAL | Button | Quests | IMPLEMENTED | Stage signature or completion changes |
| Auto-complete selected quest | Quest / Planner | `QUEST_EXECUTION_MATRIX.md` | PARTIAL | Toggle | Quests | IMPLEMENTED | Repeated live stage progress; unresolved stages stop truthfully |
| Repeatable quest catalog | QuestData | `quests.json`, `C_island_quest_route.md` | STATIC_VERIFIED | Searchable dropdown | Quests | IMPLEMENTED | 11 production repeatables; two debug rows remain lookup-only |
| Repeat selected quest | Quest / Planner | `PROGRESSION_FINAL.md`, current Engine | STATIC_VERIFIED | Toggle | Quests | IMPLEMENTED | Accept → progress → turn-in → reaccept |
| Repeatable multi-select | QuestData | `quests.json` | STATIC_VERIFIED | Multi-select dropdown | Quests | IMPLEMENTED | Selected set retained and consumed |
| Repeat mode: one | Manual controller | UI requirement | STATIC_VERIFIED | Dropdown | Quests | IMPLEMENTED | Selected quest remains sticky |
| Repeat mode: rotate | Manual controller | UI requirement | STATIC_VERIFIED | Dropdown | Quests | IMPLEMENTED | Cycle advances only after quest cycle completion |
| Repeat mode: best | Manual controller | Repeat rewards/ranges in `quests.json` | STATIC_VERIFIED | Dropdown | Quests | IMPLEMENTED | Score uses reward, level band, progress and distance |
| Repeat mode: nearest | Resolver / Manual controller | NPC and marker indexes | STATIC_VERIFIED | Dropdown | Quests | IMPLEMENTED | Lowest resolved planar distance |
| Farm until level | State / Manual controller | Level formula and state | RUNTIME_VERIFIED | Textbox / toggle | Quests | IMPLEMENTED | Stop immediately when live level reaches target |
| Active quest manager | PlayerData / Quest | Current runtime | RUNTIME_VERIFIED | Dropdown / details / buttons | Quests | IMPLEMENTED | All `activeNames()` entries, not only current quest |
| Quest blocker reason | Knowledge / Quest | `KNOWLEDGE_MODEL.md`, Quest requirements | STATIC_VERIFIED | Paragraph | Quests | IMPLEMENTED | Level, prerequisite, item, stat, unresolved status |
| Enemy catalog | Resolver / GeneratedData | `quest_specs.json`, live enemy index | STATIC_VERIFIED | Searchable multi-select | Mobs | IMPLEMENTED | Generated targets merged with indexed live names |
| Selected mob farm | Combat | `REMOTE_REGISTRY.md`, current Combat | RUNTIME_VERIFIED | Toggle | Mobs | IMPLEMENTED | Index-only select; alive=0 enters WAIT_TARGET; no Combat.findTarget / deep scan |
| Mob mode: nearest | Resolver / Combat | Current enemy index | RUNTIME_VERIFIED | Dropdown | Mobs | IMPLEMENTED | Lowest alive distance |
| Mob mode: round robin | Manual controller | UI requirement | STATIC_VERIFIED | Dropdown | Mobs | IMPLEMENTED | Cursor advances after target release |
| Mob mode: finish spawn group | Manual controller / Resolver | UI requirement | STATIC_VERIFIED | Dropdown | Mobs | IMPLEMENTED | Keeps current name while alive copies remain |
| Mob mode: priority | Manual controller | UI requirement | STATIC_VERIFIED | Dropdown | Mobs | IMPLEMENTED | User selection order |
| Live mob counts | Resolver | Current indexed resolver | STATIC_VERIFIED | Refreshable paragraph | Mobs | IMPLEMENTED | Shallow EnemyIndex snapshot only |
| Combat range | World / Combat | Current Config | RUNTIME_VERIFIED | Slider | Mobs / Settings | IMPLEMENTED | Applied movement distance |
| Target stickiness / switch distance | Manual controller | Current intent design | STATIC_VERIFIED | Sliders | Mobs / Settings | IMPLEMENTED | Retain target, then switch only when distance threshold is exceeded |
| Boss catalog | Boss / GeneratedData | Kill/Defeat/BossDrop stages | STATIC_VERIFIED | Searchable multi-select | Bosses | IMPLEMENTED | Derived boss candidates plus verified Boss map |
| Teleport to boss | Resolver / World | Quest marker data | PARTIAL | Button | Bosses | IMPLEMENTED | Marker or alive instance resolves |
| Kill / farm boss | Combat / Manual controller | Current Boss and Combat | PARTIAL | Button / toggle | Bosses | IMPLEMENTED | One-kill limit or continuous owner; spawn timer remains UNKNOWN |
| Wait for boss spawn | Resolver | Current indexed resolver | PARTIAL | Toggle | Bosses | IMPLEMENTED | WAIT_TARGET + one marker travel; EnemyIndex events wake the next select |
| Physical island list | GeneratedData / World | `studio_iteminfo_index.json`, route research | STATIC_VERIFIED | Dropdown / buttons | Teleport | IMPLEMENTED | Anchor Town, Clown Town, Maple Village |
| Island travel | Travel / World | `C_island_quest_route.md`, current Travel | PARTIAL | Button | Teleport | IMPLEMENTED | Destination island state changes |
| NPC catalog and travel | GeneratedData / Resolver | `npcs.json` | STATIC_VERIFIED | Searchable dropdown / button | Teleport | IMPLEMENTED | NPC resolve and centralized movement |
| Important locations | QuestSpecs / Resolver | Stage markers and shop data | STATIC_VERIFIED | Searchable dropdown / button | Teleport | IMPLEMENTED | Marker/place resolves before movement |
| Movement cancel | World | Current World controller | RUNTIME_VERIFIED | Button | Teleport / Home | IMPLEMENTED | Active tween cleared |
| Quest item inventory | Inventory / GeneratedData | `items.json`, current Inventory | STATIC_VERIFIED | Searchable list | Items | IMPLEMENTED | Live inventory rows |
| Item source details | QuestSpecs | `quest_specs.json` | STATIC_VERIFIED | Paragraph | Items | IMPLEMENTED | Method/source/location/status |
| Acquire selected item | Acquire | Current Acquire handlers | PARTIAL | Button | Items | IMPLEMENTED | Only non-UNKNOWN acquisition methods execute |
| Owned equipment list | Inventory / ItemData | `studio_iteminfo_index.json` | PARTIAL | Dropdowns | Equipment | IMPLEMENTED | Live owned entries intersect embedded static categories |
| Equip preferred item | Equipment | `REMOTE_REGISTRY.md`, current Equipment | STATIC_VERIFIED | Dropdown / button | Equipment | IMPLEMENTED | Held/equipped state changes |
| Upgrade selected weapon | Equipment | `D_upgrade_route.md`, current Equipment | STATIC_VERIFIED | Button | Equipment | IMPLEMENTED | Upgrade objective/item state changes |
| Auto equip preferred | Equipment / Manual controller | Current Equipment | PARTIAL | Toggle | Equipment | IMPLEMENTED | Explicit user selection only; no invented ranking |
| Skill catalog | GeneratedData | `skills.json` | STATIC_VERIFIED | Searchable dropdown | Skills | IMPLEMENTED | 19 generated skill names |
| Equip selected skill | Skills | `REMOTE_REGISTRY.md`, tutorial runtime | RUNTIME_VERIFIED | Button | Skills | IMPLEMENTED | Skill storage/equipped state |
| Cast selected skill | Skills | `TUTORIAL_FLOW.md`, current Skills | RUNTIME_VERIFIED | Button | Skills | IMPLEMENTED | Cast condition/progress |
| Skill requirement progression | Quest / Skills | Skill-linked quest data | PARTIAL | Button | Skills | IMPLEMENTED | Only implemented linked objectives execute |
| Live six-stat status | Stats | `A_system_map.md`, current Stats | RUNTIME_VERIFIED | Live paragraph | Stats | IMPLEMENTED | Async authoritative snapshot |
| Stat presets | Stats | Current Config and stat names | RUNTIME_VERIFIED | Dropdown | Stats | IMPLEMENTED | Verified invest calls with before/after canary |
| Custom stat weights | Stats | Current Stats | RUNTIME_VERIFIED | Six textboxes | Stats | IMPLEMENTED | Applied config consumed by Stats tick |
| Quick stat investment | Stats | `REMOTE_REGISTRY.md`, current Stats | RUNTIME_VERIFIED | Buttons | Stats | IMPLEMENTED | Live unused/stat delta; pre-canary bursts clamp to one |
| Auto stats | Stats | Current Stats | RUNTIME_VERIFIED | Toggle | Stats | IMPLEMENTED | Stops at zero unused and validates each action |
| Verified shop catalog | ItemData / GeneratedData | `E_item_database.md`, GeneratedData Shops | STATIC_VERIFIED | Dropdown / quantity / buy | Shop | IMPLEMENTED | Gold decreases and inventory increases |
| Sell selected safe item | Shop / ItemData | Current KEEP policy | PARTIAL | Conditional controls / status | Shop | STATUS_ONLY | Current policy exposes no explicitly sellable general item |
| Rowboat buy/spawn | Boat / Travel | `REMOTE_REGISTRY.md`, `PROGRESSION_FINAL.md` | PARTIAL | Buttons | Teleport / Shop | IMPLEMENTED | Ownership and boat instance; despawn remains unavailable |
| Chest index and current-map route | Chest / Resolver | `RUNTIME_FIXES.md`, current Chest | RUNTIME_VERIFIED | Button | Chest / Treasure | IMPLEMENTED | Indexed nearest available chest; no deep scan |
| Auto chest current map | Chest / Manual controller | Current Chest | RUNTIME_VERIFIED | Toggle | Chest / Treasure | IMPLEMENTED | One chest per step, cancellable owner |
| Selected-map chest route | Travel / Chest | Verified Afuaru index | PARTIAL | Dropdown / button | Chest / Treasure | IMPLEMENTED | CURRENT or Anchor Town only; Clown/Maple are not advertised |
| Treasure map inventory | Inventory | `items.json`, `E_item_database.md` | STATIC_VERIFIED | Paragraph | Chest / Treasure | IMPLEMENTED | Owned map entries |
| Treasure dig | Treasure | `G_missing.md`, remote research | UNRESOLVED | Status only | Chest / Treasure | DISABLED | Dig payload unresolved |
| Redeem known codes once | Codes | `REMOTE_REGISTRY.md`, current Codes | STATIC_VERIFIED | Button / dropdown | Codes / Rewards | IMPLEMENTED | Per-code callback and persisted result |
| Redeem manual code | Codes / Remotes | `REMOTE_REGISTRY.md` | STATIC_VERIFIED | Textbox / button | Codes / Rewards | IMPLEMENTED | Verified code remote result |
| Auto codes on join | Codes | Current Codes / Persist | STATIC_VERIFIED | Toggle | Codes / Rewards | IMPLEMENTED | Once per session unless list changes |
| Claim verified rewards | Rewards | Current Rewards and safe daily list | PARTIAL | Button | Codes / Rewards | IMPLEMENTED | Quest/reward state changes |
| Battlepass claim | Battlepass | `G_missing.md`, `F_remote_map.md` | UNRESOLVED | Status only | Codes / Rewards | DISABLED | Claim arguments and reward model unknown |
| Mining targets | LifeSkills / QuestSpecs | `quest_specs.json`, `D_upgrade_route.md` | PARTIAL | Multi-select / toggle | Life Skills | IMPLEMENTED | Verified mine handler and ore inventory delta |
| Smelting targets | LifeSkills | First Upgrade route | STATIC_VERIFIED | Button | Life Skills | IMPLEMENTED | Copper Bar inventory delta |
| Fishing targets | LifeSkills | `quest_specs.json`, `G_missing.md` | PARTIAL | Dropdown / button | Life Skills | IMPLEMENTED | Existing handler only; unresolved cast paths disclosed |
| Farming targets | LifeSkills | `quests.json`, `quest_specs.json` | PARTIAL | Dropdown / button | Life Skills | IMPLEMENTED | Existing prompt handler and crop progress |
| Cooking targets | LifeSkills | `quests.json`, `quest_specs.json` | PARTIAL | Dropdown / button | Life Skills | IMPLEMENTED | Existing navigation handler and dish progress |
| General crafting | LifeSkills / Craft | `E_item_database.md`, `G_missing.md` | UNRESOLVED | Status only | Life Skills | DISABLED | General Craft payload unresolved |
| Fruit state/catalog | Fruit / Inventory | `studio_iteminfo_index.json`, current Fruit | PARTIAL | Paragraph / dropdown | Fruit | IMPLEMENTED | Live inventory/current fruit where available |
| Fruit pickup | Fruit | `REMOTE_REGISTRY.md` | STATIC_VERIFIED | Button / toggle | Fruit | IMPLEMENTED | Inventory fruit appears |
| Store/equip permanent fruit | Closet / Fruit | `REMOTE_REGISTRY.md` | PARTIAL | Explicit buttons | Fruit | IMPLEMENTED | Storage/equipped fruit state; destructive replace never automatic |
| Eat/replace fruit | Fruit | `G_missing.md` | UNRESOLVED | Status only | Fruit | DISABLED | No safe replacement policy/payload |
| NiaUI presentation | UI adapter | Live NiaUI 2.7.7 | STATIC_VERIFIED | External library + thin adapter | All | IMPLEMENTED | One HttpGet at UI startup; no inline renderer |
| Full Auto home toggle | DecisionEngine | Current 1.3.2 runtime | RUNTIME_VERIFIED | Toggle | Home | IMPLEMENTED | Same exclusive FULL_AUTO owner as Auto Progress |
| Resume paused owner | Manual controller | Current controller pause/resume | RUNTIME_VERIFIED | Button | Home | IMPLEMENTED | Resumes paused owner only |
| Haki state | Haki | `A_system_map.md`, `FULL_SYSTEM_AUDIT.md` | UNRESOLVED | Status only | Misc | DISABLED | Trainer/unlock route unknown |
| Aura color reroll | Haki | `REMOTE_REGISTRY.md` | PARTIAL | Confirmed explicit button | Misc | IMPLEMENTED | Requires one-shot confirmation; resulting color changes |
| Race state/reroll | Race | `G_missing.md` | UNRESOLVED | Status only | Misc | DISABLED | Race reroll FireServer unresolved |
| Trait state/reroll | Trait | `G_missing.md`, `REMOTE_REGISTRY.md` | PARTIAL | Confirmed explicit button | Misc | IMPLEMENTED | Trait change; never automatic |
| Full auto progression | DecisionEngine | Current 1.3.2 runtime | RUNTIME_VERIFIED | Master toggle / mode | Auto Progress | IMPLEMENTED | Same Engine; current owner FULL_AUTO |
| Auto-progress blocker | Knowledge / Quest | `KNOWLEDGE_MODEL.md` | STATIC_VERIFIED | Live paragraph | Auto Progress | IMPLEMENTED | Current blockers and idle reason |
| Replan / resume story | Planner / Engine | Current runtime | RUNTIME_VERIFIED | Buttons | Auto Progress | IMPLEMENTED | Context dirty and next decision |
| Exclusive automation owner | Manual controller | `CONTINUOUS_EXECUTION_AUDIT.md` | STATIC_VERIFIED | Owner state | All automation tabs | IMPLEMENTED | Mode transition cancels old lock/movement/task |
| UI configuration persistence | UI | Executor file API requirement | STATIC_VERIFIED | Save/load/reset buttons | Settings | IMPLEMENTED | `GBKaitun/UIConfig.json` round trip |
| UI update rate | UI | `PERFORMANCE_AUDIT.md` | STATIC_VERIFIED | 3 Hz status loop | Settings | IMPLEMENTED | No RenderStepped label loop |
| Clean UI/runtime reload | Boot / UI | Current singleton pattern | STATIC_VERIFIED | Re-execute script | Settings / Debug | IMPLEMENTED | Old UI, jobs, locks, tween and connections destroyed |
| Runtime diagnostics | SelfCheck / Profiler | `PERFORMANCE_AUDIT.md`, current boot | RUNTIME_VERIFIED | Paragraph / buttons | Debug | IMPLEMENTED | SelfCheck, profiler snapshot, remote pending |
| Refresh resolver indexes | Resolver | Current Resolver | STATIC_VERIFIED | Button | Debug | IMPLEMENTED | Bounded index rebuild; no workspace deep scan |
| Runtime issue dump | Diagnostics | Current boot | RUNTIME_VERIFIED | Button | Debug | IMPLEMENTED | Session log diagnostic emitted |
| Pets | Pets | `G_missing.md`, pet tutorial | UNRESOLVED | Status only | Items | DISABLED | Obtain/equip remote arguments unknown |
| Bank deposit/withdraw | Bank | `G_missing.md`, Tomoe talk stage | UNRESOLVED | Status only | Items | DISABLED | Only NPC talk is evidenced |
| Fighting-style purchase/unlock | Skills | Fighting Style quest chains | PARTIAL | Linked quest details only | Skills | DISABLED | Emote/Damage/Unlock Skill stages unresolved |
| Arm wrestling | Minigame | `G_missing.md`, quest stages | UNRESOLVED | Status only | Debug | DISABLED | Win payload unresolved |
| Tip-jar steal/cash-out | Daily quest | `G_missing.md`, quest stages | UNRESOLVED | Status only | Codes / Rewards | DISABLED | Steal/Cash Out handlers unresolved |
| Black Noir Raid defend | Story quest | `QUEST_EXECUTION_MATRIX.md` | UNRESOLVED | Blocker status | Quests / Auto Progress | DISABLED | Defend objective semantics unresolved |

