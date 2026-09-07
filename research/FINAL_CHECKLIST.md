# FINAL Checklist — Acceptance features

| Feature | Status | Reason |
|---|---|---|
| Fresh bootstrap | PARTIAL | Wait character + StatReplication; live quest via GetData+tracker (1.0.6). Overlay dismiss 1.0.7. Planner 1.1.0. Kill-credit EnemyDrop 1.1.1. Dead-target + UI gates 1.1.2. SkillObtained close 1.1.4 |
| Tutorial | WORKING | Introduction Talk/Dummy/Dash/Block/turn-in; Basics EquipSkill scroll + Cast + Invest + OpenLogbookHelp; Gearing Up EquipFlintlock backpack+SaveOrder |
| Quest | WORKING | Goal+Acquire planner for all 151 QuestInfo stages. Collect KillUntilDrop uses EnemyDrop kill-credit (inventory/quest count; no world drop required). UNKNOWN_OBJECTIVE stops that loop |
| Auto level | WORKING | Story gates + repeatable `full_until` bands |
| Island | WORKING | Anchor → Setting Sail 30 → Clown → Journey 70 → Maple. Geometry API type-safe on Folder/Model/BasePart (`World.GetIsland*`) |
| Travel | PARTIAL | destOk hop/walk; island spawn; no invented teleport list |
| Combat | WORKING | AttackModule.Swing at CanSwing+0.42s; Dead attribute / Health<=0 release; no corpse lock; Dash PressKey Q, Block F |
| Stats | WORKING | `StatPoints("Invest", name, n)` MenuHandler |
| Skills | WORKING | Scroll: ConsumeSkillScroll(nil) + Skill("Equip", name) + hotbar Cast. EquipSkill RF still no invoke |
| Inventory | PARTIAL | Classify KEEP/EQUIP/QUEST; UNKNOWN=KEEP; no sell junk auto |
| Backpack | PARTIAL | Open/select/equip via BackpackToggle + SaveOrder. Slot-upgrade remote still UNRESOLVED |
| Equipment | PARTIAL | DIRECT_EQUIP HeldItem; UI_EQUIP SaveOrder(Weapon2) for Flintlock quest. Clothing Equip RF UNRESOLVED |
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
| Recovery | WORKING | Strategy cycle lookup→enemy→diagnostic→blocker then reset; next tick resumes hunt; DumpRuntimeIssue; void rescue on tick |
| Anti-stuck | WORKING | destOk, groundAt, water/void rescue, task timeout |
| Logging | WORKING | `[Kaitun][CAT]` rate-limited |
| Config | WORKING | GBConfig Auto* Build FruitMode Codes NeverSkip |
| Resolvers | WORKING | DisplayName + alias + DialogueNPCs + tags; skip RS create model; stream-pull; nearby dump after 3 |

**Counts:** WORKING **12** · PARTIAL **17** · DISABLED **3**.

UNRESOLVED (documented, not a 4th feature row): hard level cap, backpack upgrade, Equip RF, EquipSkill RF, Race FireServer, empty dailies ×4, Officer Investigation, Haki trainer, fishing cast, ship spawn index schema.
