# FINAL Implementation Report — Grand Blue Kaitun

**Version:** `1.0.3`  
**Place:** `118635363908336` (Studio connected).  
**Entry:** `NiaUISilent/Hub/Grand Blue/kaitun.lua`  
**Ngôn ngữ log:** `[Kaitun][CAT]`.  
**Runtime fixes:** `research/RUNTIME_FIXES.md`.

## Architecture

```
Grand Blue/
  kaitun.lua                      -- loader + engine start + getgenv().GBKaitun
  Config.lua
  picker.lua                      -- optional pick()
  Core/   Logger Scheduler Retry Cache Recovery Persist State
  Game/   Remotes Resolver PlayerData World Inventory QuestData ItemData
  Systems/ Quest Combat Stats Skills Equipment Shop Travel Boat
           Fruit Haki RaceTrait LifeSkills Chest Treasure Boss Codes Rewards Backpack
  Progression/ DecisionEngine.lua
```

Load: `readfile` từ `GB_ROOT` / `NiaUISilent/Hub/Grand Blue/` / `Grand Blue/`. Mỗi module `return function(GB)`.

**PlayerState** (`Core/State.lua`): Character, Level, Exp, Gold, CelestialCoins, Stats, SkillPoints, Skills, Inventory, Backpack, Equipment, Weapon, FightingStyle, Fruit, StoredFruits, Race, Trait, Haki, CurrentIsland, PhysicalIsland, CurrentQuest, Boat, LifeSkills, Flags. GUI `guiNum` fallback cho level / unused stat points. `PhysicalIsland` từ `World.GetIslandFromPosition`; fail → `nil`, retry tick sau — không pcall-wrap.

**Island geometry** (`Game/World.lua`): `GetIslandPosition` / `GetIslandBounds` / `IsPositionInsideIsland` / `GetIslandFromPosition`. Studio: `Workspace.Islands.*` là **Folder** (Anchor Town, Clown Town, Maple Village) — không đọc `.PrimaryPart` trước `IsA("Model")`. Origin: `PersistentAnchor.Center` + `Radius` khi có; không thì `Island` centroid/AABB (median, bỏ part nhỏ/xa); fallback `Constants.Persistent` GetBoundingBox. Map chưa load → `nil`.

**DecisionEngine:** Recovery → Tutorial → Codes/Rewards → Shop unlock → Equip → Stats → Skills → Travel/Boat → live story → picker → next story → best repeat → Boss/Fruit/Chest/Treasure.

## Verified remotes (client call sites)

| Action | Remote | Arguments |
|---|---|---|
| Talk | `ClientQuest` | `("Talk", DisplayName)` |
| Automatic Talk | `ClientQuest` | `("Automatic Talk", DisplayName)` |
| Logbook start | `ClientQuest` | `("BeginAutomatic", questName)` — **not** `BeginQuest` |
| Closet visit | `ClientQuest` | `("Closet", "Visit")` |
| Dialogue UI | `DialogueBindable` | `Fire(Configuration)` |
| Stat invest | `StatPoints` | `("Invest", statName, n)` — MenuHandler |
| Stat reset | `StatPoints` | `("Reset")` |
| Stat snapshot | `StatReplication` | `FireServer()` no-arg |
| Unused stats | `GetStats` | `InvokeServer()` no-arg |
| Shop buy | `Shop` | `("Purchase", InteractablePart, qty)` |
| Rotating shop | `RotatingShop` | `("Purchase", tonumber(parent.Name), qty)` |
| Rowboat buy | `Ships` | `("Purchase", { Type = "Rowboat" })` |
| Ship spawn/despawn | `Ships` | `("Spawn", index)` / `("Despawn")` |
| Held equip | `HeldItem` | `("Equip", id)` / `("Unequip")` |
| Sell | `SellItem` | `(key)` or `(key, amount)` |
| Upgrade | `Upgrade` | `("Upgrade", itemKey)` |
| Fruit pickup | `PickupDF` | `(FruitId)` |
| Fruit store/equip | `PermanentFruit` | `("Store Fruit"[, name, force])` / `("Equip Permanent Fruit", name[, force])` |
| Style swap | `ChangeFightingStyle` | `(styleName)` |
| Tool skill popup | `PromptSkillEquip` | `(skillName)` |
| Codes | `Codes` | `(code)` ; OnClient `(text, ok)` |
| Code list/claim | `CodeProg` | `()` ; `(code, index)` |
| Trait reroll | `Reroll` | `("Trait", slotNumber)` |
| Mine start | `EquipAndActivateBindable` | `Fire("Pickaxe")` |
| Ore prompt | same bindable | from PromptInformation.Ore |

**Never:** `BeginQuest` FireServer.

## Shop prices (world `Price` attribute, Studio)

Flintlock **150**, Cutlass **200**, Rowboat **50**, Transponder Snail **100**, Rusty Pickaxe **25**, Rusty Shovel **25**, Wooden Rod **75**, Worm **5**, food **5**, Pet Food **100**, clothing shop outfits **250**, Marine Choreboy **750**. Rotating: Daddy's Gift **750** stock 1, Hoarders Amethyst Ring **10** stock 1.

## Quest RE closes

- Stephon's Tormentor kill = `"Barrel Clown" Binki` (dump `\` = quoted name).
- Wandering Hypnotist kill = `"Hypnotist" Mango`.
- Militia Powerup 2: talk Civilian 2 + GiveItemTo **Muggy Ball**.
- Militia Powerup 3: talk Civilian 3 + GiveItemTo **Slingshot**.
- Jack/Kim/Joe/Remy dailies + Stolen Tip Jar: still **empty stubs** in Studio modules.
- Officer Investigation: **no module** in 151.

## Stats / level

- Invest API VERIFIED. Cost = unused points (1:1 with UI `n`). Grant/cap curve **UNKNOWN** (server).
- Agility move bonus: `max(0,agi)*6/(agi+300)`. Resist: `x/(x+10)`.
- `Info.LEVEL_SOFT_CAP` = **125** — used by radar hexagon scale, **not** proven hard level cap.

## Race / Trait / Fruit

- RaceOdds: Human remainder, Fishman 15, Skypiean 5, Mink 1. Variants in `RaceVariantOdds` (Lunarian listed in variants only).
- TraitOdds: Common remainder, Uncommon 30, Rare 15, Epic 2, Legendary 0.5, Mythic 0.15.
- Fruits (FruitInformation.Fruits): Flame Darkness Invisibility Spin Chop Bomb Wolf Clothing Strength Swim Weight Spike Cannon Drain **Light**.
- Eat = held fruit tool `ServerActivated` + Prompt (`Store & Eat` / `Eat Anyway`). No client Eat remote. AutoFruit default KEEP_CURRENT.

## Combat / travel (kept from prior kaitun)

AttackModule.Swing only. Dummy stand **beside**. destOk Y 8–180. groundAt skip water. lastSafe + Graves rescue. World Graves = DialogueNPCs `Officer Graves [2]` / DisplayName `Officer Graves`. Talk fires DisplayName. Never skip Escort / Hypnotist after RE.

## Remaining UNKNOWN / DISABLED

Haki trainer, backpack slot buy, Equip RF (clothing) args, EquipSkill RF invoke, Race FireServer, fishing cast packet, PickaxeHit computed args (use bindable instead), ship spawn index schema, empty dailies, Officer Investigation, world-boss schedule, hard level cap.

## Config

`getgenv().GBConfig` — see `Config.lua`. `AutoRaceTrait=false`, `AutoHaki=false`, `AutoBackpack=false`, `FruitMode=KEEP_CURRENT`, `Build=Balanced`.

## Limitations

Executor must `readfile` the folder (or set `GB_ROOT`). Dialogue Accept is GUI Activate best-effort. Boat Spawn tries index `1`. FireServer ≠ success — systems re-check inventory/quest. No invented remote args.
