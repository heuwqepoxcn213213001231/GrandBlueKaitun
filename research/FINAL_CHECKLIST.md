# FINAL Checklist — Acceptance features

| Feature | Status | Reason |
|---|---|---|
| Fresh bootstrap | PARTIAL | Wait character + StatReplication; Introduction via live quest. 1.0.1: Folder islands no longer crash `State.refresh` |
| Tutorial | PARTIAL | Introduction/Basics handlers (dummy, stats, Strong Punch prompt) |
| Quest | WORKING | Generic Talk/Kill/Collect/Purchase/Equip/Upgrade/… from live stages |
| Auto level | WORKING | Story gates + repeatable `full_until` bands |
| Island | WORKING | Anchor → Setting Sail 30 → Clown → Journey 70 → Maple. Geometry API type-safe on Folder/Model/BasePart (`World.GetIsland*`) |
| Travel | PARTIAL | destOk hop/walk; island spawn; no invented teleport list |
| Combat | WORKING | AttackModule.Swing, lock beside dummy, reacquire, destOk |
| Stats | WORKING | `StatPoints("Invest", name, n)` MenuHandler |
| Skills | PARTIAL | `PromptSkillEquip(name)` only; EquipSkill RF no client invoke |
| Inventory | PARTIAL | Classify KEEP/EQUIP/QUEST; UNKNOWN=KEEP; no sell junk auto |
| Backpack | DISABLED | No MaxSlots / buy-slot remote after Studio search |
| Equipment | PARTIAL | HeldItem Equip/Unequip; clothing Equip RF UNRESOLVED |
| Shops | WORKING | Shop/RotatingShop/Ships Purchase + world prices |
| Weapons | PARTIAL | Flintlock 150 / Cutlass 200 shop; upgrade Flintlock remote |
| Fighting Styles | PARTIAL | `ChangeFightingStyle(name)`; unlock/buy style UNRESOLVED |
| Fruits | PARTIAL | PickupDF + PermanentFruit store/equip; eat disabled (KEEP_CURRENT) |
| Haki | DISABLED | No trainer/quest/unlock remote |
| Race/Trait | DISABLED | Odds VERIFIED; AutoRaceTrait false; Race FireServer missing |
| Bosses | PARTIAL | Named kill targets on live story/repeat; loot tables UNKNOWN |
| Mining | PARTIAL | Equip pickaxe + EquipAndActivateBindable("Pickaxe") |
| Fishing | PARTIAL | Move to shop/rod; cast packet UNRESOLVED |
| Farming | PARTIAL | Move + proximity; grow math UNKNOWN |
| Cooking | PARTIAL | Move to target; perfect window UNKNOWN |
| Chest | PARTIAL | Afuaru / nearby prompt; loot UNKNOWN |
| Treasure | PARTIAL | Move on Finders/Priceless; ShovelHit args UNKNOWN |
| Codes | WORKING | Codes(code) + CodeProg; states SUCCESS/INVALID/EXPIRED/ALREADY_USED/ERROR |
| Daily/rewards | PARTIAL | Easy Pickings / Noise Complaint / Corruption Cleanse only; 4 dailies empty |
| Recovery | WORKING | Stuck levels, cooldown, rescue, rebuild |
| Anti-stuck | WORKING | destOk, groundAt, water/void rescue, task timeout |
| Logging | WORKING | `[Kaitun][CAT]` rate-limited |
| Config | WORKING | GBConfig Auto* Build FruitMode Codes NeverSkip |
| Resolvers | WORKING | Name/tag/alias; log candidates on fail |

**Counts:** WORKING **12** · PARTIAL **17** · DISABLED **3**.

UNRESOLVED (documented, not a 4th feature row): hard level cap, backpack upgrade, Equip RF, EquipSkill RF, Race FireServer, empty dailies ×4, Officer Investigation, Haki trainer, fishing cast, ship spawn index schema.
