# Runtime Fixes

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
