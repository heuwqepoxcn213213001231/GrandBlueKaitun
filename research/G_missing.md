# G. Missing Information

Mọi thứ **chưa reverse-engineer** đủ để auto-progression Phase 4. Không đoán.

---

## Progression

- Hard level cap (soft `LEVEL_SOFT_CAP=125` = radar only)
- EXP loader: dump `exp` đã `*0.8` hay raw? (rule nói loader scale)
- Stat point **grant per level** / hard cap (invest API VERIFIED; 1 unused = 1 point)
- Skill point grant / skill upgrade cost; EquipSkill RF invoke (PromptSkillEquip VERIFIED for Tool skills)
- Reputation / bounty / WantedLevel economy
- Pirate vs Marine join, ranks, Faction `The Stolen Tip Jar` (stages rỗng)
- Content sau Maple Village / sea 2 (không có đảo 4 trong `Workspace.Islands`)

---

## Quests / dump holes

| Gap | Detail |
|---|---|
| Officer Investigation | Prereq của archived Leveling Skill — **không có** trong 151 |
| Militia Powerup 2 | VERIFIED: Dialogue Civilian 2 + GiveItemTo `Muggy Ball` |
| Militia Powerup 3 | VERIFIED: Dialogue Civilian 3 + GiveItemTo `Slingshot` |
| Jack's Daily Haul | empty (Studio module, no stages) |
| Kim Wu's Daily Quota | empty |
| Joe's Daily Chores | empty |
| Remy's Daily Order | empty |
| The Stolen Tip Jar | Faction stub empty; AddReputation Anchor Town 15 |
| Stephon's Tormentor kill | VERIFIED `"Barrel Clown" Binki` |
| Wandering Hypnotist kill | VERIFIED `"Hypnotist" Mango` |
| Skill Mastery accept | không NPC; cách nhận quest UNKNOWN |
| Fighting Style unlock | quest tồn tại; điều kiện **mua/mở style** UNKNOWN |
| Big Shot | không drop skill; style unlock UNKNOWN |
| Sushi 9 | không drop |
| Crew rewards | exp/gold/celestial 0 |
| Paper Route | deliver sang Clown + Maple trước khi story tới — timing/stream UNKNOWN |

DialogueNPCs Clown/Maple folders rỗng snapshot — vị trí NPC runtime UNKNOWN (Entities stream).

---

## Combat / AI

- Mob HP, damage, spawn tables, respawn
- Party/crew assist rules
- World Boss Buggy: spawn, location, schedule, loot
- World Boss Logan/Choppy/Kuro (chỉ ItemInfo chest names)
- Black Noir Raid: wave count, fail condition
- Gate of Authority: open schedule
- AttackPlayer / Combat packet format — **UNKNOWN** (không đoán)

---

## Items / shops / inventory

- Full rotating + clothing catalogs beyond world Price dump (core story prices VERIFIED — see E / FINAL)
- Backpack size, stack, buy slots (searched MaxSlots / InventorySlots / BuySlot — none)
- Equip slot rules, level/stat req, upgrade trees (trừ Flintlock 1 bước)
- Full ItemInfo stats (chỉ có tên module)
- Treasure Map Medium/Hard/Expert sources + dig spots
- Afuaru / Fruit / World Boss loot tables
- Smuggler coupon effect
- Bank (Tomoe) mechanics

---

## Fruit / Haki / Race / Trait

- Eat = tool ServerActivated + Prompt (Store & Eat / Eat Anyway). No client Eat remote.
- Fruit spawn/chest odds/shop
- Fruit skills (trừ Chop Chop Punch / Liberation names). FruitInformation.Fruits + Light.
- Haki types, trainer, quests, mastery (RerollAuraColor ≠ unlock)
- RaceOdds VERIFIED (Human remainder / Fishman 15 / Skypiean 5 / Mink 1). Race FireServer UNRESOLVED. RaceInfo.Races folder still Human only.
- TraitOdds rarities VERIFIED; Trait `Reroll("Trait", slot)` VERIFIED. Buff list / when to reroll UNKNOWN.
- Logia / Sulong / Zoan node costs

---

## Life skills

- Node trees, rebirth perks
- Rod/pickaxe/sickle tier stats
- Fish rarity table (Mythic+ definition)
- Crop grow times, fertilizer math
- Cook timing windows (Perfect = “golden glow” only)
- Jack/Kim/Joe/Remy daily actual objectives

---

## Travel / boats

- Rowboat price, other ships, upgrades (`Ship Part`)
- Dock spawn IDs
- Teleport unlock list (`GetTeleportLocations`)
- Ocean / sea beast (Seabeast Bait STUDIO)

---

## Codes / monetization

- Live code list (kaitun 8 strings **unverified**)
- CodeProg row schema
- Battlepass, CashShop, Gifts
- Developer Product ↔ in-game item mapping

---

## Remotes

Hầu hết `RS.Events.*` args + return = UNKNOWN. Chỉ chắc:

- `ClientQuest("Talk", DisplayName)`
- BeginQuest không fire từ client executor
- `DialogueBindable:Fire(Configuration)`
- `StatReplication:FireServer()` no-arg

Cần hook/dialogue dump: Shop, Equip, StatPoints, Craft, Upgrade, Boats, PickupDF, FruitChest, Codes, GetData keys.

---

## Studio chưa đọc (có module)

Không dump turn này (tránh bịa từ tên):

- `FruitInformation` (full fruit skills)
- `ItemInfo` từng item module (stats)
- `WeightedRNG.RaceOdds` / Trait tables
- `QuestInfo` từng quest ModuleScript (có thể stages đầy hơn dump JSON — Militia/Dailies)
- Shop modules / PromptInformation catalogs

**Next RE (nếu Phase research tiếp):** đọc QuestInfo source cho 6 quest rỗng; dump Shop + ItemInfo.Flintlock/Rowboat prices; GetData key list; FruitInformation names+rarity only; RaceOdds; World Boss spawn.

---

## Closed this turn (see FINAL_*)

Kaitun implemented. Shop prices + invest + HeldItem + Ships Rowboat + kill-name `\`. Empty dailies / Officer Investigation / Haki trainer / backpack upgrade / Equip RF / Race remote remain UNRESOLVED — features disabled or skipped.
