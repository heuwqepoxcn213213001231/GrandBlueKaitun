# FINAL Checklist — Acceptance features

| Feature | Status | Reason |
|---|---|---|
| Fresh bootstrap | PARTIAL | Wait character + StatReplication; Introduction via live quest. 1.0.1 Folder islands. 1.0.2 Graves resolve + Talk validate. 1.0.3 Dialogue guiText. 1.0.4 clickGui Activated/Clicked (no Activate). 1.0.5 Dash Q + Dummy tag |
| Tutorial | PARTIAL | Introduction Talk Graves → dummy/Dash/Block → turn-in; Basics Talk/skill/stats/Logbook UI |
| Quest | WORKING | Generic live stage executor (Talk/Kill/Collect/Purchase/Equip/Upgrade/Mine/Fish/Farm/Cook/Deliver/Interact/Travel/Escort/Boss). UNKNOWN_OBJECTIVE stops that loop |
| Auto level | WORKING | Story gates + repeatable `full_until` bands |
| Island | WORKING | Anchor → Setting Sail 30 → Clown → Journey 70 → Maple. Geometry API type-safe on Folder/Model/BasePart (`World.GetIsland*`) |
| Travel | PARTIAL | destOk hop/walk; island spawn; no invented teleport list |
| Combat | WORKING | AttackModule.Swing at CanSwing+0.42s, lock beside dummy, no CFrame every Heartbeat, Dash PressKey Q, Block F |
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
| Resolvers | WORKING | DisplayName + alias + DialogueNPCs + tags; skip RS create model; stream-pull; nearby dump after 3 |

**Counts:** WORKING **12** · PARTIAL **17** · DISABLED **3**.

UNRESOLVED (documented, not a 4th feature row): hard level cap, backpack upgrade, Equip RF, EquipSkill RF, Race FireServer, empty dailies ×4, Officer Investigation, Haki trainer, fishing cast, ship spawn index schema.
