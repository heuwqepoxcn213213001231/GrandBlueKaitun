# REMOTE REGISTRY

Rule: args only from Studio call sites / data.rules / StatSystem. FireServer ≠ success.

**Enforced at runtime (1.1.42):** `GeneratedData.Remotes` + `Remotes.fire` rejects `BeginQuest`. Status ≠ VERIFIED → do not add a wrapper that fires blindly.

| Action | Remote | Arguments | Evidence | Validation | Status |
|---|---|---|---|---|---|
| Talk NPC | `Events.ClientQuest` RE | `("Talk", DisplayName)` | PromptInformation.Dialogue: Humanoid.DisplayName or Name. Graves DisplayName=`Officer Graves` (instance `Officer Graves [2]`) | Live Talk count / stage | VERIFIED |
| Automatic Talk | `Events.ClientQuest` RE | `("Automatic Talk", DisplayName)` | PromptInformation.Dialogue | Stage complete | VERIFIED |
| Logbook accept | `Events.ClientQuest` RE | `("BeginAutomatic", questName)` | LogbookHandler | Quest appears in Cache.Data.Quests | VERIFIED |
| Closet visit | `Events.ClientQuest` RE | `("Closet", "Visit")` | PromptInformation.Closet | Tutorial Visit | VERIFIED |
| Enter zone | `Events.ClientQuest` RE | `(zoneName, "Enter Zone")` | StarterPlayer Zones | Quest Progress | VERIFIED |
| Delete/track | `Events.ClientQuest` RE | `("Delete"\|"Track", name)` | QuestLocal | UI | VERIFIED |
| Choice | `Events.ClientQuest` RE | `("Choice", name, choice)` | DialogueHandler | — | VERIFIED |
| Dialogue open | `DialogueBindable` | `Fire(Configuration)` | rules + Dialogue prompt | DialogueUI | VERIFIED |
| Dialogue close | `DialogueClosed` RE | `(InteractablePart)` | Dialogue ClientPromptHidden | — | VERIFIED |
| BeginQuest | `Events.BeginQuest` | — | rules.never_fire_beginquest | **do not fire** | BANNED |
| Stat invest | `Events.StatPoints` RE | `("Invest", child.Name, n)` | MenuHandler | GetStats unused drop | VERIFIED |
| Stat reset | `Events.StatPoints` RE | `("Reset")` | MenuHandler Reroll | needs Stat Reset item | VERIFIED |
| Stat replicate | `Events.StatReplication` RE | `FireServer()` | StatSystem client | OnClient snapshot | VERIFIED |
| Get stats | `Events.GetStats` RF | no-arg | MenuHandler | table + unused | VERIFIED |
| Shop buy | `Events.Shop` RE | `("Purchase", part, qty)` | Shop Item prompt | Inventory amount | VERIFIED |
| Rotating buy | `Events.RotatingShop` RE | `("Purchase", parentIndex, qty)` | Shop Item if Stock | Inventory | VERIFIED |
| Rowboat buy | `Events.Ships` RE | `("Purchase", {Type="Rowboat"})` | Shop Item Rowboat branch | owned ship | VERIFIED |
| Ship spawn | `Events.Ships` RE | `("Spawn", index)` | ShipViewer | boat exists | VERIFIED remote; index PARTIAL |
| Ship despawn | `Events.Ships` RE | `("Despawn")` | ShipViewer | — | VERIFIED |
| Held equip | `Events.HeldItem` RE | `("Equip", id)` | HeldClient.RequestEquip | Held tool; **not** Gearing Up Equip cond | VERIFIED |
| Held unequip | `Events.HeldItem` RE | `("Unequip")` | HeldClient | — | VERIFIED |
| Gear slot bind | `Events.SaveOrder` RE | `(slot, key)` | BackpackLocal.MoveToolToSlot / SaveOrder | Equips.Slots Title / Equip quest | VERIFIED |
| Open/close backpack | `Events.BackpackToggle` BE | `Fire(true\|false)` | BackpackLocal → TopbarPlus select → OpenStorage | Storage.Visible | VERIFIED |
| Sell | `Events.SellItem` RE | `(key)` / `(key, amount)` | MerchantHandler + BackpackLocal | Gold up / item down | VERIFIED |
| Upgrade | `Events.Upgrade` RE | `("Upgrade", key)` | Blacksmith LocalScript | item changed | VERIFIED |
| Refine/Freeze | `Events.Upgrade` RE | `("Refine"\|"Freeze", key, stat)` | Blacksmith | — | VERIFIED (not used auto) |
| Pickup fruit | `Events.PickupDF` RE | `(FruitId)` | Devil Fruit prompt | inventory fruit | VERIFIED |
| Store fruit | `Events.PermanentFruit` RE | `("Store Fruit"[, name[, force]])` | ClosetHandler | Fruit Storage | VERIFIED |
| Equip perm fruit | `Events.PermanentFruit` RE | `("Equip Permanent Fruit", name[, force])` | ClosetHandler | Data.Fruit | VERIFIED |
| Delete stored | `Events.PermanentFruit` RE | `("Delete Fruit", name)` | ClosetHandler | — | VERIFIED (not auto) |
| Change style | `Events.ChangeFightingStyle` RE | `(styleName)` | ClosetHandler | Attribute Style | VERIFIED |
| Prompt skill | `Events.PromptSkillEquip` RE | `(skillName)` | PassiveObtained Tool type | skill equipped | VERIFIED |
| Skill equip/unequip | `Events.Skill` RE | `("Equip"\|"Unequip", skillName)` | SkillHandler ToggleEquip | Skills[name].Equipped / hotbar | VERIFIED |
| Consume skill scroll | `Events.ConsumeSkillScroll` RE | `(nil)` | ScrollFrameSlide; server HeldItem.Name==Skill Scroll | Skills.Storage[name] | VERIFIED |
| Open logbook help | `Events.QuestEvents.OpenLogbookHelp` RE | no-arg | ForceOpenLogbook | Open Logbook cond | VERIFIED |
| Codes | `Events.Codes` RE | `(code)` | Codes LocalScript | OnClient text,ok | VERIFIED |
| CodeProg | `Events.CodeProg` RE | `()` or `(code, index)` | Codes LocalScript | pending list | VERIFIED |
| Trait reroll | `Events.Reroll` RE | `("Trait", slot)` | TraitHandler | trait change | VERIFIED |
| Aura color | `Events.RerollAuraColor` RE | no-arg | Aura Color Reroll item | — | VERIFIED (not Haki unlock) |
| Mine activate | `EquipAndActivateBindable` | `Fire("Pickaxe")` | Ore prompt | ore damage | VERIFIED |
| PickaxeHit | `Events.PickaxeHit` RE | `(instance, nil, nil, v67, v52)` | Pickaxe tool client | — | STUDIO; do not invent v67/v52 |
| Equip RF | `Events.Equip` RF | UNKNOWN | no InvokeServer site | — | UNRESOLVED |
| EquipSkill RF | `Events.EquipSkill` RF | UNKNOWN | no InvokeServer site | — | UNRESOLVED |
| Race reroll | `Events.Reroll` | `("Race", …)` not found | Trait only | — | UNRESOLVED |
| GetData | `Events.GetData` RF | `("Quests", "Completed Quests")` QuestInfo client; also single keys | QuestLocal LoadQuests | VERIFIED |
| Fishing | `Events.Fishing` | UNKNOWN | no safe args | — | UNRESOLVED |
| Plant/Water | `PlantSeed` etc. | UNKNOWN | — | UNRESOLVED |
| ClaimAchievement | RF | UNKNOWN | — | UNRESOLVED |
| Teleport list | `GetTeleportLocations` | UNKNOWN | — | UNRESOLVED |

Failure cases (common): rate-limit, GameplayPaused, not in range 16, 0 gold, 0 stat points, missing item key, Stock 0, faction lock on shop, fruit storage full (force=true destroys).
