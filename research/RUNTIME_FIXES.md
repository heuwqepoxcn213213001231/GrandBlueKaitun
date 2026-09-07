# Runtime Fixes

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
