# Runtime Fixes

## 1.1.32 — Barrel Clown Binki: poke barrels, don't hunt a missing name

`Stephon's Tormentor` HUD is `Defeat "Barrel Clown" Binki (0/1)`. Binki hides in a barrel. Combat looked for an Entities enemy by that name, missed, and stood still next to crates. Kill-stage marker was nil.

**Fix**

- Resolve Binki via tag / NPCName / Entities barrel+Humanoid.
- On miss, swing nearby `Barrel*` props (`GetPartBoundsInRadius`) to reveal him. Cycle barrels, stay in Stephon's yard.
- Hidden-kill quests never defer. Marker for the kill stage is Stephon.

## 1.1.31 — Never defer live Destroy; no findTarget wait

Reload of 1.1.30 still logged `defer Sabotage The Cannon deferred_after_fail`. After boot, live quest payload can be empty so `Objective.Type` was not `Destroy` and `noteFail` still deferred 30s. Engine then `otherOrFarm` — tele away. `findTarget` also `task.wait` 0.35–2.2s (`Quest.doLive` 271ms).

**Fix**

- `keepTrying`: any quest with a Destroy stage (or object target) never defers, even if live/objective is missing.
- Existing defer is cleared. DecisionEngine does not farm-away from those quests.
- Tracker text `Destroy Muggy Cannon (0/1)` infers the Destroy objective after empty GetData.
- `findTarget` approaches the marker once and returns. No wait-loop on the scheduler.

## 1.1.30 — Destroy objects (Muggy Cannon): stay at marker, no stream-pull loop

`Sabotage The Cannon` / Destroy Muggy Cannon treated the cannon as an `Entities` enemy. It is a CollectionService tag / world object. `findTarget` missed, `streamToMarker` called `pullStream(Clown Town)`, then `noteFail` deferred after 5 misses. Teleport loop + `Quest.doLive` 3s spikes. Deep scan saw Benny / barrels, never the cannon.

**Fix**

- Resolve Destroy targets via tag / `OBJECT_TARGETS` (`Muggy Cannon`, balloons, crates, signal fires). Not the enemy index.
- Go to the quest marker and wait for the object to stream in. Do not `pullStream` on miss.
- Story Destroy miss does not Recovery / 30s defer. Stay on the marker and retry.

## 1.1.29 — No 16s kill wait; don't tween through dialogue

`A Joke Gone Too Far` kill used `huntUntilDead(16)` so `Quest.doLive` / `Scheduler.step` hung ~16s. Mid-wait Clown dialogue opened; after timeout the bot clicked then immediately Tweened again. Recovery fired `stuck quest`.

**Fix**

- Story/farm kill engages once. Heartbeat swings. Engine does not wait for the corpse.
- Dialogue open: stop combat lock, click progress, settle 1.3s before the next tween.
- Recovery ignores live combat lock and open dialogue.

## 1.1.28 — Stop re-accepting finished story; sides then farm

Lv26 picker looped `Introduction` via Graves flavor / tracker leftover (`Talk to Officer Graves to get started`). Recovery `enemy stuck pick:Introduction` reset accept. Setting Sail is the real next beat (level 30).

**Fix**

- Tracker text cannot become `current` unless the quest is live.
- `finished()` includes level-implied story completion when Completed Quests is empty.
- Dead story accept is marked local-done. Recovery does not enemy-unstick accept/pick.
- Side quests on the island (`Advanced Training`) run if still startable; otherwise farm to the next gate.

## 1.1.27 — Respawn resume, no 16s scheduler hang

Death mid-farm: `huntUntilDead(16)` blocked `Scheduler.step` (~16382ms), `GameplayPaused` waited 12s more, empty `GetData Quests` wiped live repeats, planner sat `wait_level:Setting Sail`. Telemetry `moved 1613 studs` was the game respawn, then the bot never re-engaged the pack.

**Fix**

- Farm engage is one `hunt()` — combat Heartbeat kills. Engine does not wait 16s per mob.
- `waitUnpause` capped at 0.8s. Paused ticks still try the farm pool.
- Empty quest refresh after respawn keeps the last live set for 12s.
- CharacterAdded returns to `lastSafe` and replans the island farm pool.

## 1.1.26 — Parallel island farm, no wait_level stall

Live loop quests on the same island (Officer Termination + Granny's Nemesis) were serialized. Miss on `Corrupt Guard` returned `retry_window` (`attempted=false`) and DecisionEngine dropped to `wait_level:Setting Sail`. Recovery/stream-pull after 5 misses teleported away from the pack.

**Fix**

- Farm pool = every live repeat on the island plus in-band startables. Ignore `full_until` while the quest is already accepted.
- Combat hunts the nearest mob matching any remaining kill target (`Corrupt Guard` or `Corrupt Marine Officer`).
- `retry_window` stays `attempted=true`. Repeatable resolve-miss does not Recovery/defer/stream-pull.
- Officer / Granny `full_until` raised to 30 so both stay in the Setting Sail grind.

## 1.1.25 — Accept stay: no re-tele while talking to NPC

Maeve / tree NPCs: bot arrived at talk range then `ToNPC` + `ToInteractable` + `setPos(groundAt+40)` every ~4s, snapping onto canopy then back.

**Fix**

- `atTalk` is planar range only. Already in front of the NPC = stay.
- `ToNPC` / accept loop do not teleport again while parked. Tree-height snap-down is once per 8s, floor-clamped, no `groundAt(+40)`.
- `interact` fires the prompt in place; no CFrame snap if planar-near.
- After Talk remote `sent`, linger and wait for accept/credit before leaving.

## 1.1.24 — Repeatable accept regression + resolver deep-scan stalls

Farm loop regressed after `342f877`: when `Granny's Nemesis` accept flow stalled, planner forced `farm_direct:Corrupt Guard` and triggered repeated resolver deep scans (~2s spikes) while the correct dialogue accept option was open.

**Observed bad path**

```
[Kaitun][STATE] task farm:Granny's Nemesis
[Kaitun][STATE] task farm_direct:Corrupt Guard
[Kaitun][PLANNER] fallback direct farm Granny's Nemesis -> Corrupt Guard
[Kaitun][PERF][SPIKE] Resolver deep scan 2053ms
[Kaitun][PERF][SPIKE] DecisionEngine.decide 2100-2400ms
```

**Root causes**

1. Dialogue classifier treated any text containing `"No"` as decline.
2. Quest glow/metadata never got scored because decline filter ran first.
3. `Quest.doLive=false` was interpreted as direct-combat permission.
4. Normal resolver miss path deep-scanned large roots (`Islands`, `Entities`, `DialogueNPCs`).
5. Negative miss cache was globally cleared on any entity add/remove.

**Fix**

- Dialogue choice classification now:
  - normalizes text first,
  - classifies standalone decline forms only (`No`, `No.`, `Decline`, `Cancel`, `Bye`, exact phrases),
  - scores metadata/quest-linked/glow options before fallback text heuristics,
  - never rejects a sentence only because it contains `"No"`.
- Accept flow now validates activation after click:
  - `PlayerData.live(quest)` exists OR `QuestState.IsAccepted == true`.
  - Logs explicit accept lifecycle (`Opening ...`, `accepting ... via ...`, `... ACTIVE`).
- Repeatable planner now uses `QuestData.repeatStartSpec` and keeps NPC-start repeatables in quest mode.
- Blind direct-farm fallback for startable repeatables is removed.
- Resolver now:
  - serves normal lookups from semantic indexes (`EnemyIndex`, `NPCIndex`, `MarkerIndex`, `ObjectIndex`),
  - deep-scans only under explicit diagnostic intent,
  - uses scoped negative invalidation by semantic key/kind.
- Combat kill flow now supports marker-first streaming via `CombatTargetPlan`.

**Expected good path**

```
[Kaitun][PLANNER] next=Granny's Nemesis
[Kaitun][STATE] task quest_accept:Granny Todo
[Kaitun][QUEST] Opening Granny's Nemesis
[Kaitun][QUEST] choice "No, I'm here to put that punk in his place again!"
[Kaitun][QUEST] Granny's Nemesis ACTIVE
```

---

## 1.1.17 — Player still on GitHub 1.1.13; Stats never ticked

HttpGet loader default REMOTE. Origin was `ef90654` (1.1.13). Local 1.1.14–1.1.16 never pushed → execute still `resolve miss Marine Gate`, no `[STAT]`, 26 unused.

**Fix:** push. `Stats.tick` on its own 0.55s job. Unused from `Stat Points: N` anywhere in PlayerGui. `StatPoints:FireServer("Invest", name, n)` no shared rate with other remotes. BOOT logs `VERSION 1.1.17`.

```
[Kaitun][BOOT] VERSION 1.1.17
[Kaitun][STAT] unused=26
[Kaitun][STAT] Invest Strength x21 now Str=23 Hp=1 target 8:2
```

---

## 1.1.16 — Log watcher ≠ game; dump rewrite froze client; defer Gate

`runtime_log_watcher.py` only copies executor JSON from `GBKaitun/runtime` into `runtime_reports/Mac`. It does not run in Roblox. Ctrl+C just stops the copier.

Client freeze after a long run: `DumpRuntimeIssue` did `readfile(entire latest.jsonl)+writefile` every recovery dump. File grew → hitch. Restart script = empty file = smooth. Also `inferObjective` walked all `PlayerGui` descendants. Recovery looped `resolve miss Marine Gate` → diagnostic dump.

Gate of Authority needs Strength 100 to push-open. Below that, defer and do other live (Advanced Training) then farm (`Officer Termination` at lv9).

**Fix:** `appendfile` / overwrite latest only. Dump throttle 25s. Infer only `Quests` GUI. `Quest.deferred` Gate if Str<100. Stats log `unused=N`.

```
[Kaitun][QUEST] defer Gate of Authority need Strength 100 to push-open
[Kaitun][STATE] doing=talk target=Officer Graves
[Kaitun][STATE] task farm:Officer Termination
[Kaitun][STAT] unused=26
```

---

## 1.1.15 — Gate of Authority + unused stats still 26

`resolve miss Marine Gate`. Quest target is `Open / Marine Gate`. Live instance is `Workspace.Islands.Anchor Town.Island.Gate` tagged **Marine Metal Gate**, prompt `Pushable Door`. No model named Marine Gate. `byName` miss → recovery loop. Mob-zone `Shell Town Marine Gate` is a 400+ stud volume — not the door.

`Pushable Door` server: Strength ≥ 100 → `Progress(..., "Open")`. Below 100 → fail anim, only `Push`. Tracker text is "Be at the Gate of Authority when it opens" — Open also credits anyone within 150 when the gate opens.

26 unused, no `[STAT]` line. `unused()` trusted GetStats=0 over Radar `Stat Points: 26`.

**Fix:** alias + `taggedAny("Marine Metal Gate")`. Stand on Gate.Anchor, fire prompt, stay (markSuccess). Stats unused = max(GetStats, Radar, cache). `Stats.tick` on first alive tick.

```
[Kaitun][STAT] Invest Strength xN now Str=.. Hp=.. target 8:2
[Kaitun][QUEST] at Marine Gate Str=22 need 100 to push-open
```

---

## 1.1.14 — Stats never spent mid-quest; ToEnemy snaps to roofs

`Stats.tick` lived after `Quest.doLive` `return`. Live story always has a current quest → AutoStats never ran. 20 unused, Strength 2 / Health 1. `GetStats` returns `(stats, unused)` — `invoke` kept only the first value. ClientCache `Data.StatPoints` is 0.

`ToEnemy` / `standPose` used `groundAt` (ray from Y+40). Indoor Marine Snitch → first hit is the roof → `Teleport -> Marine Snitch` onto the house.

**Fix:** `Stats.tick` before the quest return. Cache unused from `GetStats` + `StatPoints.OnClientEvent`. `floorAt` from the mob's Y. Tween HRP to that floor (`Tween -> name`). Reposition does not slam CFrame onto `groundAt`.

```
[Kaitun][STAT] Invest Strength x16 now Str=18 Hp=1 target 8:2
[Kaitun][TRAVEL] Tween -> Marine Snitch
```

---

## 1.1.13 — Tea Party Crashers: Corrupt Marine Officer is a family name

`Kill Corrupt Marine Officer` 7. Resolver exact-match on `Workspace.Entities` miss. Nearby dump had **Corrupt Swordsman Officer** d=56, Marine Snitch, Maeve. Live models: `Corrupt Swordsman Officer 3017`, `Corrupt Sniper Officer 3015`. Tags: variant name + `Corrupt Marine`. `NPCName` = variant. Mob zone part is named `Corrupt Marine Officer` — not the combatant. Foot soldier `Corrupt Marine N` is a different kill.

**Fix:** alias + `nameMatches` (strip trailing id, prefix, `isCorruptOfficer`). `IsValidTarget` uses the same matcher. Smelt Copper Bar aborts if no Copper Ore (0/1 GUI).

```
[Kaitun][RESOLVE] Corrupt Marine Officer -> Workspace.Entities.Corrupt Swordsman Officer 3017
```

---

## 1.1.12 — Mine is HOLD charge, stats 8:2 on current totals

Copper Ore 0/2. `EquipAndActivateBindable("Pickaxe")` tap started Swing then QTE died (`Beginning charge` / `bindable event fired`). Ore prompt HOLD. `TutorialLocal` already said hold then release at the top.

`Pickaxe.ClientActivated` → `StartMiningLoop` → `Swing` → after 0.29s `QuickTimeEvents.Mining`. Bar fills; release when `1-fill` is in Critical Zone. `PickaxeHit` stays on the tool. Teleport every tick + Stun interrupts the QTE. Acquire treated a tap as fail → `fail #4` / STUCK.

**Fix:** stand once, hold MB1, activate, release in zone (or fill≥0.93), do not teleport mid-charge. Mining in-progress returns `hunting` (no fail count). AutoStats spends unused points to keep current Strength:Health at 8:2.

```
[Kaitun][MINING] hold charge at OreBlockObjectId-...
[Kaitun][MINING] release fill=0.94 zone=yes
[Kaitun][MINING] hit hp 18->15
[Kaitun][STAT] Invest Strength x8 now Str=8 Hp=0 target 8:2
```

---

## 1.1.11 — Mining overlay: stop walking UIS.InputBegan

Ảnh 2 (stage 1+2 cùng lúc) là click tay. Bot vẫn loop `_src` + `skip ContinueOverlay`. 1.1.10 vẫn gọi `getconnections(UIS.InputBegan)` — executor index `_src` trên CorePackages `SchedulerHostConfig.default`, engine tick chết trước khi TutorialLocal chạy.

`TutorialLocal`: MouseButton1 / Touch / ButtonX. `gameProcessed=true` return trừ ButtonX. `Background.Active=false` — click nền = `gameProcessed=false` (đường click tay). Mining 3 folder; AdvanceStage không ẩn stage cũ; lần 3 `CloseGUI` + `TutorialEvent:FireServer("Mining")`.

**Fix:** không walk toàn bộ InputBegan. Chỉ invoke fn/conn có `Script.Name` = `TutorialLocal` / `PassiveObtained`. Click VIM vào nền + ButtonX mỗi tick. pcall toàn bộ invoke. Track stage 1→2→3. Không hide GUI.

```
[Kaitun][Loader] Manifest 1.1.11
[Kaitun][UI] continue TutorialScreen Mining via InputBegan:TutorialLocal ver=1.1.11
[Kaitun][GATE] TutorialScreen Mining stage 1->2
[Kaitun][GATE] TutorialScreen cleared
```

---

## 1.1.10 — Mining TutorialScreen: `_src` crash aborted continue

Pickaxe bought. `EquipAndActivate` opened **TutorialScreen Mining** — "Press anywhere to continue", 3 stages (hold / release at top / special materials). Detected ContinueOverlay + UIS.InputBegan. Overlay never closed.

Engine: ` _src is not a valid member of ModuleScript CorePackages...SchedulerHostConfig.default`. `ownerMatch` did `type(scr._src)` on every InputBegan connection. CorePackages ModuleScript throws. Scheduler pcall logged it and **the rest of `invokeContinueInput` never ran** — no ButtonX, no TutorialLocal invoke. Recovery correctly skipped the overlay and looped.

Mining `TutorialLocal`: same InputBegan as SkillObtained (MouseButton1/Touch/ButtonX; gameProcessed ignored only for ButtonX). `ShowContinue(0.75)`. Three folders; each press `AdvanceStage`, last press `CloseGUI` + `TutorialEvent:FireServer("Mining")`.

**Fix:** `_src` only on fake tables (`rawget`). Skip CorePackages. ButtonX fires **before** the connection walk. pcall each conn. Wait 0.85s for TutorialScreen continue prompt. Do not hide GUI.

```
[Kaitun][GATE] waiting TutorialScreen continue TutorialScreen Mining
[Kaitun][UI] continue TutorialScreen Mining via VirtualInput:ButtonX
[Kaitun][GATE] TutorialScreen cleared
```

---

## 1.1.9 — First Upgrade Collect Rusty Pickaxe: mines are below DestYMin

Unlock credited. Stage 2: **Purchase a pickaxe down in the mines** / Collect Rusty Pickaxe 0/1. Planner looped `Need item Rusty Pickaxe` → `CYCLE First Upgrade AcquireItem|Rusty Pickaxe`.

Verified shop: `Workspace.Islands.Anchor Town.Island.Rusty Pickaxe` Model, Interaction `Shop Item`, Price 25, tag `Rusty Pickaxe`. Pivot **Y=4.04**. Copper Ore **Y=4.67**. `DestYMin` was 8 → `destOk` reject. `rescue` treated `y < DestYMin-2` as void and would yank out of the mines. `Shop.buy` used `moveTo` hop 45 on a 600-stud path, returned false every tick. Subgoal stack incremented `seen` → CYCLE at 12. No `SHOP` log.

**Fix:** DestYMin 0. Rescue only water/high Y. Shop teleports via `ToInteractable` + `Shop:FireServer("Purchase", interactable, qty)`. First Upgrade Collect pickaxe goes `Shop.buy`, not the full subgoal stack. Dialogue accept includes "I need you to upgrade my flintlock".

```
[Kaitun][TRAVEL] Teleport -> Rusty Pickaxe
[Kaitun][SHOP] Purchase Rusty Pickaxe x1
[Kaitun][QUEST] Objective COLLECT Copper Ore
```

---

## 1.1.8 — Unlock stands at prompt, not on the gate arch

1.1.7 stopped the Model.Position crash. Live still `unlock not credited Afuaru's Gate` #1–#3. Screenshot: character clipped on the **arch roof**. Quest 0/1. Key is in the hotbar.

Verified: prompt `Locked Door` parent is Attachment `HumanoidRootPart` at **(69.1, 77.4, 548.7)**. Model pivot / first BasePart is **Y=85.5**. `ToInteractable` used pivot+(0,0,6) then `groundAt` snapped onto the arch. Server `ProximityPrompt.Triggered` rejects if HRP is farther than `MaxActivationDistance` **8** from the attachment. Roof is already ~8 studs vertical. `fireproximityprompt` ran; server dropped the packet.

Client packet is `Events.ProximityPrompt:FireServer(prompt, prompt.Name, { ObjectName = interactable.Name })`. `HoldDuration` is **0** — do not invent a 0.8s hold.

**Fix:** `Resolver.promptAnchor` = prompt WorldPosition. `ToInteractable` stands 3–6 studs beside that point, rejects ground hits >4 above the prompt (no roof). `firePrompt` uses real HoldDuration and the 3-arg FireServer.

```
[Kaitun][TRAVEL] Teleport -> Afuaru's Gate
[Kaitun][UI] prompt Afuaru's Gate d=4.1
[Kaitun][QUEST] Unlock credited 0/1 -> 1/1
```

---

## 1.1.7 — Model.Position crash class + Unlock Afuaru's Gate + loot chests

Live **The Hoarder** stage 4: `Unlock Afuaru's Gate (0/1)`. Engine loop:

```
Position is not a valid member of Model "Workspace.Islands.Anchor Town.Island.Model.Model.Afuaru's Gate"
```

Gate is a Model. Direct children = two door Models + `HumanoidRootPart` **Attachment**. No PrimaryPart. `Resolver.partOf` took `FindFirstChildWhichIsA("BasePart")` (non-recursive) → nil → returned the Model because `GetPivot` works. `World.moveTo` then did `part.Position`. Same class hits any Model without a direct BasePart: chests, Marine Gate, future interactables.

Unlock is not walk-to-marker. Prompt `Locked Door` on `HumanoidRootPart.PromptAttachment`. Key attribute `Afuaru's Key`, `ConsumeKey=false`. Server `Inventory.Has` + `ProgressQuestBindable(Unlock)`. `Close Afuaru's Gate` only flips Open→Closed. Stage 5 clones `Afuaru's Chests` tagged `Afuaru's Chest N` + `ClientInteractable`; loot is client prompt → `AfuaruChest`.

**Fix (class, not one site):**
- `partOf` never returns Model. Recursive BasePart. `positionOf` uses pivot when there is no part.
- `moveTo` / `ToInteractable` / `Chest` / Combat / Skills use `positionOf` or `IsA("BasePart")`.
- Unlock: teleport to pivot, hold `Locked Door`, validate live 0/1 → 1/1. FireServer fallback.
- Loot: `Chest.lootUntil` on real chest tags, not AcquireItem `"Afuaru's Chests"`.
- First Upgrade Smelt goes to Furnace (not mine `Copper Bar`). Upgrade stands at Anvil then remote + Blacksmith GUI.
- Recovery skips `enemy` on Unlock/Loot/Open/Interact.

```
[Kaitun][QUEST] Unlock Afuaru's Gate
[Kaitun][TRAVEL] Teleport -> Afuaru's Gate
[Kaitun][UI] hold prompt Afuaru's Gate
[Kaitun][QUEST] Unlock credited 0/1 -> 1/1
```

---

## 1.1.6 — Gearing Up Shoot Dummy is Gunshot HOLD, not melee

1.1.5 closed SkillObtained. Quest advanced to **Shoot Training Dummy (0/1)**. Combat then `Teleport` + `AttackModule.Swing` on `Training Dummy6`. Dummy has no Humanoid (`hp=?`) and never dies. Melee does not credit `Shoot`. Hotbar slot 5 **Gunshot** shows **HOLD**. `Fruit Chest` / Punch stayed selected. `state not found Ragdoll/GettingUp` is AttackModule swinging a dummy.

Verified: `CreateCondition(..., "Shoot", "Training Dummy", 1)`. Archived Aim Training text: "Land Gunshot on a Training Dummy". `Gunshot.ChargeInfo` = hold `Windup` 0.35s, max 15. `BackpackLocal.UseTool(slot, true)` + `ReleaseTool` → `Events.Input` State true/false + HeldDuration. Slot key `PressKey` Five is the fallback.

**Fix:** Shoot ≠ Hit. `Combat.shootUntilCredit` stands at `ShootRange` (9), aims, `Skills.castHold` (UseTool hold or PressKey), waits projectile + 6s cooldown, validates live Shoot count. No Swing. Dummy death is not the completion signal.

```
[Kaitun][COMBAT] Shoot Gunshot -> Training Dummy6
[Kaitun][SKILL] hold Gunshot slot=5 0.50s via UseTool
[Kaitun][SKILL] release Gunshot
[Kaitun][QUEST] Kill credited 0/1 -> 1/1
```

---

## 1.1.5 — ContinueOverlay: real press-anywhere, never hide GUI

1.1.4 hid `SkillObtained` (`Enabled=false`) and fired `PromptSkillEquip` as a fallback. That is not the game flow. The card is a **transient `PassiveDisplay` event**. Continuation is `PassiveObtained.Notify` after `task.wait(3)`:

```
UIS.InputBegan → Touch / MouseButton1 / ButtonX
gameProcessed=true returns unless ButtonX
Debris CantAttack, Event:Fire(true), disconnect,
Enabled=false + Attribute false, Unhide,
PromptSkillEquip if ModuleType==Tool, AdvanceQueue
```

`ContinueButton` is a TextLabel. Clicking GUI descendants does nothing. `firesignal(InputBegan, fakeTable)` reported success without running the closure.

**Fix:** `Tutorial.HandleContinuationOverlay` / `ExecuteGate` / `ValidateGateCompleted`. Gate type `ContinueOverlay` vs `ActionRequired` / `EquipRequired`. Invoke owner or ButtonX+MouseButton1 fingerprint connections, then VirtualInput **ButtonX** (only key accepted when processed). Success only if overlay actually closes. Then `PlayerData.refreshLive` + `State.refresh` + `Quest.Refresh` + `Planner.Replan`. Finite attempts → `BLOCKING_GATE_UNRESOLVED` dump. Recovery does not recycle lookup on the same overlay.

```
[Kaitun][GATE] detected ContinueOverlay SkillObtained payload=Gunshot
[Kaitun][GATE] continuation=UIS.InputBegan
[Kaitun][UI] continue SkillObtained Gunshot via InputBegan:connection
[Kaitun][GATE] SkillObtained cleared
[Kaitun][STATE] tutorial complete
[Kaitun][STATE] task quest:Gearing Up
```

`GBKaitun:DumpTutorialState()` returns DetectedGate / GateType / Payload / GuiPath / ContinuationMethod / Attempt / LastTransition / CachedState / ActualVisibleState.

---

## 1.1.4 — SkillObtained dismiss actually closes the card

1.1.3 logged `dismiss overlay SkillObtained Gunshot` then looped. `firesignal(UIS.InputBegan, fake, false)` returned success without running `PassiveObtained` (listener uses InputObject + `gameProcessed`). Card stayed up.

**Fix:** invoke `getconnections` on InputBegan (do not trust firesignal). If the GUI is still Enabled after that, run the same client close as the handler: `Event:Fire(true)`, `PromptSkillEquip:FireServer(skillName)` (Gunshot `ModuleType` default `Tool`), Debris `CantAttack`, `Enabled=false`. Unhide Menu tokens via `UI_Utilities.Unhide` upvalue if `debug.getupvalue` exists.

```
[Kaitun][UI] dismiss overlay SkillObtained Gunshot
[Kaitun][UI] closed SkillObtained Gunshot
```

---

## 1.1.3 — SkillObtained Gunshot press-anywhere after Equip Flintlock

After backpack + SaveOrder, `PassiveDisplay` queues **Gunshot**. Overlay: `PlayerGui.SkillObtained` — circular icon, "Gunshot", "Active Skill", "PRESS ANYWHERE TO CONTINUE". `ContinueButton` is a **TextLabel**.

`PassiveObtained.Notify`: `task.wait(3)` then `UIS.InputBegan`. `gameProcessed=true` returns unless ButtonX. `Queue` also `BackpackToggle:Fire(false)`.

1.1.2 treated leftover QuestOverlay backpack text as the gate and skipped dismiss. Real clicks on the card set gameProcessed and the handler no-ops. Listener is not connected for the first 3 seconds.

**Fix:** SkillObtained / TutorialScreen always beat backpack coach. Wait 3.15s after first see, then fire InputBegan MouseButton1 + ButtonX with `gameProcessed=false`. Overlay check before GameplayPaused wait.

### Expected log

```
[Kaitun][GATE] waiting SkillObtained listener SkillObtained Gunshot
[Kaitun][UI] dismiss overlay SkillObtained Gunshot
[Kaitun][GATE] Tutorial advanced SkillObtained -> none
```

---

## 1.1.2 — Dead combat targets + mandatory tutorial / UI gates

### Combat: corpse still attacked

Resolve + teleport + Swing worked. Enemy died. Model stayed in `Workspace.Entities` several seconds. Kaitun kept locking that instance until `Parent == nil`.

**Death signal (Studio):** `Model:GetAttribute("Dead") == true` — `TelemetryClient` corpse window, `LockOn` reject, `QuestLocal`, `DeathScreen`, `KnockedLocal`. Also `Humanoid.Health <= 0` and `StateService.CheckForState(char, "Dead")`. **Knock is not death.** Parent nil is despawn only.

`aliveEnemy` treated missing Humanoid as alive. Dummy/corpse with Dead flag or stripped Humanoid stayed valid. Resolver cache + closest-name pick re-acquired the same corpse.

**Fix:** `Combat.IsEnemyAlive` / `IsValidTarget` / instance `deadTargets` cache. Heartbeat + Died + Dead-attribute watch. `Resolver.enemies` ranks **alive** only (closest live, never closest corpse). Stop lock + movement the same tick. Quest kill refresh after death. EnemyDrop checks drop immediately (no wait-for-despawn). Dummy Shoot/Hit exits on quest count, not model removal.

### Gearing Up: Equip Flintlock 0/1 + "Open the backpack."

`[EQUIP] HeldItem Equip Flintlock` loop. Quest stayed 0/1. Overlay `QuestOverlay` from `TutorialFolder.EquipFlintlock`.

HeldItem ≠ gear equip. Tutorial completion = Flintlock in `Equips.Slots` (Weapon2). Client bind: `SaveOrder(slot, key)` after `BackpackToggle:Fire(true)` / topbar Backpack.

**Fix:** `Systems/Tutorial.lua` blocking-gate priority. `Equipment` DIRECT_EQUIP vs UI_EQUIP. Equip quest uses backpack + SaveOrder. Action success ≠ quest progress — change strategy, do not spam HeldItem. Recovery diagnostic can set `BLOCKING_UI`.

### Files

- `Systems/Combat.lua`, `Game/Resolver.lua`, `Game/World.lua`, `Systems/Acquire.lua`, `Systems/Boss.lua`
- `Systems/Tutorial.lua`, `Systems/Equipment.lua`, `Systems/Backpack.lua`, `Game/Remotes.lua`
- `Core/State.lua`, `Core/Recovery.lua`, `Progression/DecisionEngine.lua`, `Progression/Planner.lua`, `Systems/Quest.lua`
- `kaitun.lua`, `VERSION` / `manifest.json` / `loader.lua` → **1.1.2**

### Expected log (combat)

```
[Kaitun][COMBAT] Target Corrupt Marine 2436 hp=120
[Kaitun][COMBAT] Corrupt Marine 2436 hp=0 — dead
[Kaitun][COMBAT] Clearing dead target
[Kaitun][QUEST] Kill credited 2/5 -> 3/5
[Kaitun][COMBAT] Next target Corrupt Marine
```

### Expected log (Gearing Up)

```
[Kaitun][QUEST] Gearing Up stage=3
[Kaitun][GATE] Tutorial detected EquipFlintlock
[Kaitun][GATE] Instruction: Open the backpack.
[Kaitun][UI] Opening backpack
[Kaitun][EQUIP] Selecting Flintlock
[Kaitun][EQUIP] Equipping Flintlock slot=Weapon2
[Kaitun][QUEST] Equip Flintlock 0/1 -> 1/1
```

---

## 1.1.1 — Enemy-drop Collect credits on kill, engine froze after STUCK

### Issue

```
[Kaitun][PLAN] Need item Pirate Fan Letter
[Kaitun][ACQUIRE] source=Corrupt Marine
[Kaitun][RESOLVE] Corrupt Marine -> Workspace.Entities.Corrupt Marine 2436
[Kaitun][QUEST] Pirate Fan Letter fail #1..#5 acquire Pirate Fan Letter
[Kaitun][RESOLVE] miss 'Pirate Fan Letter' nearby=52 Officer Graves...
[Kaitun][QUEST] STUCK Pirate Fan Letter acquire Pirate Fan Letter
[Kaitun][RECOVERY] level=5 strategy=blocker
```

UI Collect 0/1. "Beat them up until one of them coughs it up." User: quest không làm, không nhận, không đánh quái.

### Root cause (Studio place `118635363908336`)

1. **Kill credit, no world drop.** QuestInfo stage 3: `CreateCondition(..., "Collect", "Pirate Fan Letter", 1)` + marker tag **Corrupt Marine**. ItemInfo: Type=`Quest Item`, ItemCap=1. Koro complete `Inventory.Remove(..., "Pirate Fan Letter")`. `CollectQuestItem` is only RetrieveLocalItem / Trouble Down the Well world prompts — **not** this quest. 1.1.0 waited for `findDrop` / pickup. Letter never appears as a world instance → fail #1–5 → STUCK.
2. **STUCK froze the engine.** `AcquireFromEnemyDrop` returned false on recovery `diagnostic`/`blocker`. `DecisionEngine` `return` after `Recovery.run`. No more hunt.
3. **Pet lock / highlight.** Live pets are `Workspace.Entities."<Player> Slot N Pet"` tagged **Pet** (also NPC/Character). `AttackModule.Swing` HitHighlight on whatever is in the hitbox. Resolver did not reject pets.
4. **Strong Marine** — 0 Studio instances / 0 scripts. Marker stays **Corrupt Marine**.

### Fix

- EnemyDrop success = inventory **or** live Collect `Target.Amount` / stage advance. World pickup optional. Do not require prompt.
- Hunt while 0/N and tagged enemies exist. `hunting` ≠ fail. STUCK only if no enemy AND no drop AND no progress after the budget.
- After STUCK/blocker: reset strategy, next tick resumes hunt. Recovery no longer aborts the story tick.
- Combat: reject `HasTag("Pet")` / `Slot N Pet`. Teleport to tagged enemy, Swing 0.42 + CanSwing, until dead, then next.
- `[STATE] doing=combat target=Corrupt Marine 2436` each decision. Auto-accept next Automatic story when current completes.

### Files

- `Systems/Acquire.lua`, `Systems/Combat.lua`, `Game/Resolver.lua`, `Game/World.lua`
- `Progression/DecisionEngine.lua`, `Progression/Planner.lua`, `Core/Recovery.lua`, `Core/Logger.lua`
- `VERSION` / `manifest.json` / `loader.lua` → **1.1.1**

### Expected log

```
[Kaitun][STATE] doing=combat target=Corrupt Marine 2436
[Kaitun][PLAN] Need item Pirate Fan Letter
[Kaitun][ACQUIRE] source=Corrupt Marine
[Kaitun][COMBAT] Corrupt Marine
[Kaitun][ACQUIRE] kill-credit Pirate Fan Letter
[Kaitun][QUEST] 0/1 -> 1/1
```

No `[DROP]` / `[PICKUP]` required. Then Talk Koro (Automatic).

---

## 1.1.0 — Collect treated as world item (Pirate Fan Letter → BaseRock)

### Issue

```
[Kaitun][QUEST] collect miss Pirate Fan Letter
[Kaitun][ERROR] resolve miss Pirate Fan Letter
[Kaitun][RECOVERY] level=1 stuck quest:Pirate Fan Letter
```

UI Collect Pirate Fan Letter (0/1). QuestInfo: "Beat them up until one of them coughs it up." Marker tag **Corrupt Marine**. Script `byName("Pirate Fan Letter")` on an item that does not exist yet.

### Root cause

Collect handler was ObjectiveType→`Resolver.byName(item)`. KillUntilDrop items are not world props. `Combat.attack` also refused non-Kill objectives, so even a one-off marine hunt would stop.

### Fix

Goal + Acquire plan for all 151 QuestInfo modules. `AcquireItem` methods (AlreadyOwned, WorldPickup, EnemyDrop, …). Drop scan is folder/tag/prompt + semantic match — not nearest BasePart.

Pirate Fan Letter Collect → `EnemyDrop` source=`Corrupt Marine` (QuestInfo marker). Pickup via drop-container prompt. Validate inventory/quest 0/1 → 1/1.

Recovery changes strategy: lookup drop → enemy → diagnostic → blocker. `GBKaitun.DumpRuntimeIssue()` JSONL. Fruit/Haki/Race gated by `StoryFirst`.

### Files

- `Game/QuestSpecs.lua`, `Systems/Acquire.lua`, `Progression/Planner.lua`
- `Systems/Quest.lua`, `Systems/Combat.lua` (`hunt`)
- `Progression/DecisionEngine.lua`, `Core/Recovery.lua`, `kaitun.lua`
- `VERSION` / `manifest.json` / `loader.lua` → **1.1.0**

### Expected log

```
[Kaitun][PLAN] Need item Pirate Fan Letter
[Kaitun][ACQUIRE] source=Corrupt Marine
[Kaitun][COMBAT] Corrupt Marine
[Kaitun][DROP] Pirate Fan Letter
[Kaitun][PICKUP] Pirate Fan Letter
[Kaitun][QUEST] 0/1 -> 1/1
```

---

## 1.0.7 — Basics Cast blocked by Unlock Skill tutorial overlay

### Issue

Live **Basics Cast Strong Punch**. Overlay **Unlock Skill** (Strong Punch / Active Skill) + "PRESS ANYWHERE TO CONTINUE" / "Press anywhere to continue". Instruction: "When a skill is unlocked, it will show up on your screen with a special effect".

Logs:

```
[Kaitun][QUEST] Basics fail #4 cast not credited Strong Punch
[Kaitun][QUEST] Basics fail #5 cast not credited Strong Punch
[Kaitun][QUEST] STUCK Basics cast not credited Strong Punch
[Kaitun][RECOVERY] level=1 quest Basics
[Kaitun][SKILL] cast hotbar Strong Punch
```

Hotbar click ran under the overlay. SkillObtained also sets `CantAttack` until dismissed. Five "casts" then STUCK.

`CLOSEST PART BaseRock` + table dumps are **not** from Kaitun. Game `PickaxeStrike` (`workspace:GetAttribute("DebugPrints")`).

### Root Cause (Studio place `118635363908336`)

| Surface | Path | Dismiss |
|---|---|---|
| Skill card (left) | `PlayerGui.SkillObtained` from `RS.ScreenGuis.SkillObtained` | `UIS.InputBegan` MouseButton1/Touch **after 3s**. `ContinueButton` is TextLabel, not a button. Sets `Enabled=false` + clears CantAttack. `Event:Fire(true)` is visuals only. |
| Tutorial (title + step + bottom prompt) | `PlayerGui.TutorialScreen` from `RS.ScreenGuis.TutorialScreen` | `TutorialLocal`: `UIS.InputBegan` MouseButton1/Touch. `ClickToContinue` TextLabel. `Background.Active=false` (click is not gameProcessed). **Unlock Skill** has 3 stages; last click `CloseGUI` → `TutorialEvent:FireServer("Unlock Skill")`. Same ScreenGui hosts Mining / Curse Fruits. |
| Equip leftover | `EquipStrongPunch` | ScreenShadow highlight on scroll/hotbar — not this overlay. |

No full-screen GuiButton. Do not invent remotes. Cast after overlay: `CastStrongPunch` clicks hotbar `ToolFrame.Title == "Strong Punch"` (same as `Skills.cast`).

Basics remaining after Cast (handlers already exist): Talk Graves → `Required TotalStatPoints` (`Stats.investMinimum`) → Talk Graves → `Open Logbook` (`ForceOpenLogbook` + `OpenLogbookHelp`).

### Fix

- `State.tutorialOverlayVisible` / `State.dismissTutorialOverlay`: TutorialScreen, SkillObtained, any Enabled LayerCollector with ClickToContinue / ContinueButton / "Press anywhere" / "Unlock Skill".
- Dismiss: `clickGui` if a GuiButton exists, then fire the same `UserInputService.InputBegan` (MouseButton1, gameProcessed=false). Rate 0.45s. Not Strong-Punch-only.
- Quest `doLive` + EquipSkill/Cast: dismiss first. Do **not** `noteFail` / STUCK while overlay is up.
- `Skills.equip` / `Skills.cast`: refuse until overlay is gone.

### Files

- `Core/State.lua`, `Systems/Quest.lua`, `Systems/Skills.lua`
- `VERSION` / `manifest.json` / `loader.lua` → **1.0.7**

### Expected next log

```
[Kaitun][UI] dismiss overlay TutorialScreen Unlock Skill
[Kaitun][UI] dismiss overlay SkillObtained Strong Punch
[Kaitun][SKILL] cast hotbar Strong Punch
[Kaitun][QUEST] Basics 0/1 -> 1/1
```

Then Talk Graves → Invest → Talk → Open Logbook.

---

## 1.0.6 — Live quest stuck on Introduction while UI is Basics EquipSkill

### Issue

UI: **Basics** — "Equip your new skill" / Equip Skill: Strong Punch. Overlay: **Select the 'Strong Punch' skill scroll**. Skill bar already shows Strong Punch. Graves nearby.

Logs still:

```
[Kaitun][RECOVERY] stuck quest:Introduction
[Kaitun][ERROR] resolve miss Training Dummy
```

### Root Cause (Studio place `118635363908336`)

1. **ClientCache.Quests is a boot snapshot.** `ClientCache` loads once via `GetData("Quests")`. `QuestBegan` / `QuestDeleted` / `QuestStageUpdated` are **empty**. Incremental updates go to QuestLocal (`BeginQuest`, `QuestProgress`, `ClearQuest`), not `Cache.Data.Quests`.
2. **DecisionEngine tutorial** iterated `{ Introduction, Basics, … }` and called `PlayerData.live(n)`. `live()` treated any leftover Introduction row as active → always executed Introduction Hit Dummy.
3. **Condition fields wrong.** Live conds are `Target = { Amount, Name, RequiredAmount }` (QuestInfoUtilities.CreateCondition). Executor read `cond.Current` / `cond.Amount` → Dummy always looked incomplete.
4. **EquipSkill path wrong.** Overlay is `EquipStrongPunch` (hotbar `Skill: Strong Punch` → `SkillScroll.Frame.ImageButton` → `ConsumeSkillScroll(nil)` → `Events.Skill("Equip", name)`). `PromptSkillEquip` is only the Tool-type obtain popup. `EquipSkill` RF has no client InvokeServer.

### Fix

- Refresh live set from `GetData("Quests","Completed Quests")` (TTL 0.85s) + tracker GUI / stage-title hints. Hook BeginQuest / ClearQuest / QuestProgress / UpdateQuestState.
- `live()` = GetData row, not completed, incomplete `Target.Amount`. `current()` prefers tracker then chain order then persist checkpoint.
- Tutorial/engine follows `current()` — never Introduction-first.
- Combat refuses Dummy unless objective is Hit/Kill/Shoot/Destroy.
- EquipSkill/Cast/Open Logbook/Unlock/Investigate/Deliver Object/Reach Maple Village handlers from Studio functions.
- Combat Heartbeat 0.42 + CanSwing from 1.0.5 kept. Resolve-miss still 8s.

### Files

- `Game/PlayerData.lua`, `Game/QuestData.lua`, `Game/Remotes.lua`, `Systems/Quest.lua`, `Systems/Skills.lua`, `Systems/Combat.lua`, `Progression/DecisionEngine.lua`, `picker.lua`, `Core/State.lua`, `kaitun.lua`
- `VERSION` / `manifest.json` / `loader.lua` → **1.0.6**

### Expected next log (current runtime = Basics EquipSkill)

```
[Kaitun][STATE] live quest Basics
[Kaitun][STATE] task quest:Basics
[Kaitun][QUEST] Basics stage=2
[Kaitun][QUEST] Objective EQUIPSKILL Strong Punch
[Kaitun][SKILL] scroll flow Strong Punch
[Kaitun][SKILL] Skill Equip Strong Punch
```

Then Cast → Talk Graves → Invest → Talk → Open Logbook.

---

## 1.0.5 — Combat Heartbeat lag + Introduction Dash stuck

### Issue

Live Introduction **Dash (0/2)** — "Press Q to perform a dash". Combat felt stuttery. Logs:

```
[Kaitun][ERROR] resolve miss Training Dummy
[Kaitun][QUEST] Kill not credited Training Dummy
[Kaitun][RECOVERY] level=1 stuck quest:Introduction
```

Game console: `-- Putting highlight on: ... Pet HitHighlight` dozens/sec. Memory ~2.7GB.

### Root Cause (Studio place `118635363908336`)

1. **Swing every Heartbeat.** `startLock` called `AttackModule.Swing` + `standPose` (CFrame + `groundAt` raycast) every frame. Gap was 0.28s and ignored `CanSwing`. Basic `swingStateDuration` = `0.35 * 1.05`. Extra Swing calls spawn `HighlightHitEffect` (`HitHighlight`) on dummy/pets → server + client hitch.
2. **Dash handler attacked Dummy.** `Quest.handleCondition` `Dash`/`Block` ran `Combat.attack("Training Dummy")`. Live objective was Dash, not Hit. Kill-credit check then spammed `Kill not credited`.
3. **Dummy name miss.** World models are `Workspace.Entities.Training Dummy1`–`8`, CollectionService tag **`TrainingDummy`**, no Humanoid. Quest name `"Training Dummy"` never matches. `Resolver.enemy` logged miss, then Combat scanned Entities (and `byName` logged again). `StreamingEnabled`: Dummy1 at ~(268, 22, -101) vs `PersistentAnchor.Center` ~(-184, -0.5, 39) — ~470 studs, same class as Graves miss.
4. **Logger.** Distinct `[ERROR] resolve miss` + `[QUEST] Kill not credited` keys every tick.

Dash client (verified): `Keybinds` default Q. `InputManager.Inputs.Dash.Client` binds `Enum.KeyCode.Q`. `Controls.Dash` → `Events.PressKey:Fire(Enum.KeyCode.Q)`. `PlayerInputHandler` PushInput. Do **not** invent `Events.Input` args. Block: `PressKey:Fire(Enum.KeyCode.F, Enum.KeyCode)` then `false` on release.

### Fix

- Swing only when `StateService.GetPermission(char, "CanSwing")` and `os.clock` gap ≥ 0.42. No `pcall` around Swing.
- `standPose` / CFrame / raycast only if far or target moved. No CFrame write every Heartbeat when already beside.
- Dummy: `Resolver.dummy()` — `GetTagged("TrainingDummy")`, cache until `Parent==nil`. Miss log once / 8s. After 3: hop `lastDummyPos` or island stream-pull, then `noteFail` → STUCK at 5. Not ERROR every 0.1s.
- Dash: `Combat.stopLock` + `PressKey` Q. Wait `CanDodge`. Validate live `0/2 → 1/2 → 2/2`.
- Block: `PressKey` F hold 0.7s. Do not attack Dummy on Dash/Block.
- Hit Dummy later: credit via quest count only (not `Parent==nil`).
- Logger: identical `[ERROR]` and `[QUEST] …not credited / resolve miss` gap 8s.

### Files

- `Systems/Combat.lua`, `Systems/Quest.lua`, `Game/Resolver.lua`, `Core/Logger.lua`
- `VERSION` / `manifest.json` / `loader.lua` → **1.0.5**

### Expected next log

```
[Kaitun][QUEST] Objective DASH
[Kaitun][COMBAT] Dash Q
[Kaitun][QUEST] Introduction 0/2 -> 1/2
[Kaitun][COMBAT] Dash Q
[Kaitun][QUEST] Introduction 1/2 -> 2/2
```

Then Block (`Hold F`). Resolve miss Training Dummy at most once / 8s, only if Dummy not streamed.

---

## 1.0.4 — Dialogue ImageButton `:Activate()` crash (choice found, click dies)

### Issue

Choice resolve worked. Dialogue open, label `"I can help change that!"`, path `DialogueUI.Main.1.ImageButton`. Engine:

```
[Kaitun][QUEST] Click I can help change that!
[Kaitun][ERROR] engine Activate is not a valid member of ImageButton "Players....PlayerGui.DialogueUI.Main.1.ImageButton"
[Kaitun][QUEST] Introduction fail #1 talk not credited Officer Graves
```

Talk 0/1 never became 1/1. Re-Talk/teleport did not run (dialogue-open branch). Click itself threw.

### Root Cause (Studio place `118635363908336`)

`DialogueHandler.setupButton` (choice ImageButton):

```
p44.Activated:Connect(u89)
p44.InputBegan → Touch → u89
p44:GetAttributeChangedSignal("Clicked"):Connect(u89)
```

Keyboard `1`–`7`: `Main[n].ImageButton:SetAttribute("Clicked", not GetAttribute("Clicked"))`.

`GuiButton:Activate()` is **not** a member on this executor ImageButton. Indexing `.Activate` / calling `:Activate()` throws the same class of error as `.Text` on ImageButton. Client never uses `Activate()`.

Do **not** invent `ClientQuest("Choice", …)` — that remote is the reward-picker path, not FirstAgree.

### Fix

- `State.clickGui(btn)`: never index `.Activate`.
- Prefer `firesignal` / `getconnections` on `Activated` (same hook `setupButton` uses). `MouseButton1Click` only if Activated had no fireable signal.
- Always flip `Clicked` after — same as KeyCode.One. `u89` no-ops if Activated already ran (`u12`/`u48`).
- `clickAccept` + Logbook menu button use `clickGui` only.
- Dialogue already open: click only, no re-Talk / teleport. `waitProgress` still validates 0/1 → 1/1.

### Files

- `Core/State.lua`, `Systems/Quest.lua`
- `VERSION` / `manifest.json` / `loader.lua` → **1.0.4**

### Expected next log

```
[Kaitun][QUEST] Click I can help change that!
[Kaitun][QUEST] Introduction 0/1 -> 1/1
```

Then next Introduction stage (Hit Training Dummy).

---

## 1.0.3 — Dialogue ImageButton `.Text` crash (Introduction stuck after Talk)

### Issue

NPC resolve + teleport worked. Player stood at Officer Graves with prompt **E Talk** and DialogueUI open, choice **"1. I can help change that!"**. Engine looped:

```
[Kaitun][QUEST] Talking Officer Graves
[Kaitun][RESOLVE] Officer Graves -> Workspace.AA IMPORTANT.DialogueNPCs.Anchor Town.Officer Graves
[Kaitun][TRAVEL] Teleport -> Officer Graves
[Kaitun][ERROR] engine Text is not a valid member of ImageButton "Players.<name>.PlayerGui.DialogueUI.DialogueHandler.NodeFrame.ImageButton"
[Kaitun][RECOVERY] level=4 stuck quest:Introduction
```

Talk 0/1 never became 1/1.

### Root Cause (Studio place `118635363908336`)

`DialogueUI` lives at `ReplicatedStorage.ScreenGuis.DialogueUI` (cloned to PlayerGui). Choice template:

| Path | Class | Role |
|---|---|---|
| `DialogueHandler.NodeFrame` | Frame | template (not the live choice) |
| `NodeFrame.TextLabel` | TextLabel | choice text (sibling) |
| `NodeFrame.Number` | TextLabel | `"1."` |
| `NodeFrame.ImageButton` | ImageButton | click target — **0 children, no `.Text`** |
| `NodeFrame.Background` | ImageLabel | hover chrome |

`DialogueHandler` clones `NodeFrame` into `DialogueUI.Main`, names the clone `1`/`2`, wires `ImageButton.Activated`. Client also listens `Clicked` attribute.

`clickAccept` did `btn.Text or btn.TextLabel.Text`. Lua evaluates `btn.Text` first. ImageButton has no `Text` → crash. `GetDescendants()` hit the **template** under `DialogueHandler.NodeFrame` first, so the live `Main` clone was never reached.

Even after a safe read, `"I can help change that!"` would not match `Accept`/`Thank`/`Yes`, and fallback `d.Name == "1"` looks at the ImageButton name (`"ImageButton"`), not the frame.

Officer Graves `Dialogue.Definition` FirstAgree: `Text = "I can help change that!"`. PromptQuest Accept/Decline frames use the same NodeFrame + sibling label.

### Fix

- `State.guiText` / `guiNum`: never index `.Text` unless `IsA("TextLabel"|"TextButton"|"TextBox")`. ImageButton/Frame → named `TextLabel` child, then descendant label, then sibling `TextLabel`, then `GetAttribute("Text")`.
- `clickAccept`: scan **`DialogueUI.Main` cloned frames only** (ignore template + Quest reward ImageButtons). Read label via `guiText`. Skip Decline / Good luck / Bye / No / Cancel. Prefer Accept / Thank / Yes / `"I can help change that"` / Quest Glow; else first numbered choice (`Name==1` / `Number` `"1."`).
- Click path: `ImageButton:Activate()` — same `Activated` hook the client uses.
- If DialogueUI is already Enabled, advance/click only. Do not re-`FireServer Talk` or re-teleport. Click rate 0.7s. `waitProgress` still validates 0/1 → 1/1.

Shop/Codes do not read button `.Text`. `guiNum` already gated class before `.Text`.

### Files

- `Systems/Quest.lua`, `Core/State.lua`
- `VERSION` / `manifest.json` / `loader.lua` → **1.0.3**

### Expected next log

```
[Kaitun][QUEST] Talking Officer Graves
[Kaitun][QUEST] Click I can help change that!
[Kaitun][QUEST] Introduction 0/1 -> 1/1
```

Then next Introduction stage (Hit Training Dummy).

---

## 1.0.2 — Officer Graves resolve miss (Introduction stuck)

### Issue

Modules loaded. Island resolver worked. Live quest Introduction on Anchor Town lv0. Loop:

```
[Kaitun][STATE] task quest:Introduction
[Kaitun][ERROR] resolve miss Officer Graves [2]
[Kaitun][QUEST] NPC miss Officer Graves [2]
```

UI: "Talk to Officer Graves" / "Talk To Officer Graves (0/1)". Never 0/1 → 1/1.

### Root Cause (Studio place `118635363908336`)

| What | Identity |
|---|---|
| Quest target / marker tag / Humanoid.DisplayName | `Officer Graves` |
| World model Name + CollectionService tag | `Officer Graves [2]` |
| Path | `Workspace.AA IMPORTANT.DialogueNPCs.Anchor Town.Officer Graves [2]` |
| Attributes | `Interaction=Dialogue`, `PromptAdded=true` |
| RS `Officer Graves` | character-create. Tag `Officer Graves` lives here. **Not** the world NPC. |

1. Resolver **replaced** the search key with alias `"Officer Graves [2]"` before matching. Humanoid.DisplayName is `"Officer Graves"`, so DisplayName match never ran.
2. `workspace.StreamingEnabled = true`. Graves is ~400+ studs from `PersistentAnchor.Center`. Client often has **no** DialogueNPC instance. `GetTagged("Officer Graves [2]")` empty → `resolve miss`.
3. Fuzzy required the literal substring `"officer graves [2]"` — a streamed name without `[2]` would also miss.
4. Scan skipped `DialogueNPCs` as a first-class container; treated missing Model/HRP as dead.

Game Talk (PromptInformation.Dialogue): `ClientQuest:FireServer("Talk", DisplayName)` then `DialogueBindable:Fire(Configuration)`. DisplayName = `"Officer Graves"`. Never `BeginQuest`.

### Fix

- `ResolveNPC`: names = request + verified aliases both ways + DisplayName + `NPCName` attr + tags. Skip ReplicatedStorage. Search `AA IMPORTANT.DialogueNPCs` / Entities / Islands / Markers first.
- Result object: Instance, Root, Position, DisplayName, InternalName, Interaction, Island. Root may be Model / BasePart / Folder / Configuration.
- After 3 misses: invalidate cache, ranked nearby dump (≤8), island stream-pull via runtime spawn/DialogueNPC positions (no hardcoded coords). After 5: STUCK + Recovery.
- Talk: `World.ToNPC` offset (not inside), unpause, Talk(DisplayName), DialogueBindable, wait live 0/1 → 1/1.
- Generic QuestExecutor: live state → stage → objective → handler → validate. Escort = NeverSkip follow only.

### Files

- `Game/Resolver.lua`, `Game/QuestData.lua`, `Game/World.lua`
- `Systems/Quest.lua`, `Systems/Combat.lua`, `Config.lua`
- `research/QUEST_EXECUTION_MATRIX.md`
- `VERSION` / `manifest.json` / `loader.lua` → **1.0.2**

---

## 1.0.1 — Folder island `PrimaryPart` crash

### Issue

After loader printed 35 modules and `[GB Pick] live Introduction lv0 Anchor Town`, engine died:

```
[Kaitun][ERROR] engine PrimaryPart is not a valid member of Folder "Workspace.Islands.Anchor Town"
```

Stack: `Game/World.lua` `islandFromPosition` → `Core/State.lua` `refresh` → `kaitun.lua` boot.

Bootstrap never reached `[Kaitun][BOOT] ready`.

### Root Cause

`Workspace.Islands.Anchor Town` / `Clown Town` / `Maple Village` are **Folder**, not Model.

`islandFromPosition` / `islandSpawn` evaluated `isl.PrimaryPart` before any `IsA("Model")` check. Lua `or` still reads the property; Folder has no `PrimaryPart`.

Studio (place `118635363908336`):

| Island | Class | Notes |
|---|---|---|
| Anchor Town | Folder | `PersistentAnchor.Center` + `Radius` IntValue; `Island` Folder (terrain); `SpawnLocations` empty |
| Clown Town | Folder | No PersistentAnchor; `Constants.Persistent` Model has GetBoundingBox; `Island` partially streamed |
| Maple Village | Folder | `Island` empty until stream; `Constants.Persistent` Model bounds exist |

No island attributes. No hardcoded coordinates used.

### Fix

Shared type-safe API in `Game/World.lua` (used everywhere, including aliases):

- `GetIslandPosition(island)`
- `GetIslandBounds(island)`
- `IsPositionInsideIsland(position, island)`
- `GetIslandFromPosition(position)`
- `islandFromPosition` → `GetIslandFromPosition`
- `islandSpawn` → spawn folder then `GetIslandPosition`

Resolution order (runtime, not baked coords):

1. `SpawnLocation` / `Spawn` under `SpawnLocations`
2. `PersistentAnchor.Center` (+ `Radius` for inside-test)
3. `Island` child: Model GetPivot/GetBoundingBox after `IsA("Model")`; Folder = median/AABB of large child parts/models (ignore tiny/far)
4. `Constants.Persistent` Model GetBoundingBox
5. Named `Main` / `Ground` / `Dock` / `Teleport`
6. Else `nil` — map not loaded; retry on later `State.refresh`

Never access `.PrimaryPart` unless `IsA("Model")`. Character HRP paths in `World.hrp` / `State.refresh` use the same guard.

`State.refresh`: `PhysicalIsland` fail → `nil` + retry next tick. No pcall around the resolver.

Log once per island:

- fail: `[Kaitun][World] Unable to resolve island position: Anchor Town class=Folder descendantParts=N`
- success: `[Kaitun][World] Island resolved: Anchor Town via <method>` (INFO once + DEBUG)

### Files Changed

- `Game/World.lua` — geometry API; `islandFromPosition` / `islandSpawn` no longer touch Folder.PrimaryPart
- `Core/State.lua` — `PhysicalIsland` nil on miss; Character PrimaryPart only if Model
- `VERSION`, `manifest.json`, `loader.lua` — `1.0.0` → `1.0.1` (`?v=` cache bust)
- `research/FINAL_CHECKLIST.md`, `research/FINAL_IMPLEMENTATION_REPORT.md`, `research/00_INDEX.md`, this file

`Game/Resolver.lua` already gated `PrimaryPart` behind `IsA("Model")` — no change.

### Regression Check

Startup path:

1. `loader.lua` fetch VERSION/manifest (`1.0.1`), inject modules
2. `kaitun.lua` boot → `State.refresh`
3. `CurrentIsland` from quest progress (`islandFromProgress`) — no workspace geometry
4. `PhysicalIsland` = `GetIslandFromPosition(HRP)` — Folder-safe; player on Anchor Town → `"Anchor Town"`
5. Scheduler `engine` → `DecisionEngine.decide` → `State.refresh` again
6. Live `Introduction` → `quest:Introduction`

Expected after modules (instead of PrimaryPart crash):

```
[Kaitun][World] Island resolved: Anchor Town via PersistentAnchor.Center
[Kaitun][World] Island resolved: Clown Town via Constants.Persistent
[Kaitun][World] Island resolved: Maple Village via Constants.Persistent
[Kaitun][BOOT] lv0 island=Anchor Town gold=...
[Kaitun][BOOT] ready — GBKaitun / GBConfig / GB_VERSION
[Kaitun][STATE] task quest:Introduction
```

(Clown/Maple resolve once during the scan; method can change later if `Island` child count streams in.)

Ignore `StateService` / `SmartBone` game warnings.
