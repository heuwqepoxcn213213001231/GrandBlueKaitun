# Runtime Fixes

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
