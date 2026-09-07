# F. Remote / Function Map

**Rule:** không đoán args. Studio xác nhận **path tồn tại**. Args chỉ ghi khi data/StatSystem/rules nói rõ.

`RS` = `ReplicatedStorage`. Hầu hết remote: `RS.Events.<Name>`.

Return value: hầu hết UNKNOWN (không hook server).

---

## Confidence

| Tag | Nghĩa |
|---|---|
| VERIFIED | data.rules / StatSystem source / picker modules |
| STUDIO | instance tồn tại trên place |
| INFERRED | kaitun.lua đã gọi — **không** coi là spec server |
| UNKNOWN | chưa RE |

---

## Master table

| System | Data Path | Remote / Function | Arguments | Return | Requirements | Related Modules | Notes |
|---|---|---|---|---|---|---|---|
| Quest accept talk | `rules.accept_talk` | `Events.ClientQuest` RE | `("Talk", DisplayName)` VERIFIED | UNKNOWN | Prompt Dialogue dist=16 | QuestInfo, Dialogue | Không thay BeginQuest |
| Quest begin | `rules.never_fire_beginquest` | Dialogue Command **BeginQuest** | Server-only từ dialogue | — | Click Accept | QuestInfo | **Không** FireServer BeginQuest |
| Quest begin remote | — | `Events.BeginQuest` RE | UNKNOWN — **do not fire** | UNKNOWN | — | — | Tồn tại STUDIO; rules cấm executor |
| Quest dialogue UI | `rules.accept_talk` | `DialogueBindable` (bindable, kaitun) | `Fire(Configuration Dialogue)` VERIFIED in rules | — | Configuration trên NPC | PromptInformation | Class STUDIO bindable; không nằm list RE |
| Quest dialogue | — | `Events.DialogueRemote` RE | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Quest dialogue close | `rules.turnin_talk` | `Events.DialogueClosed` RE | UNKNOWN | UNKNOWN | After Complete | — | STUDIO |
| Quest dialogue RF | — | `Events.RunDialogueFunctionOnServer` RF | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Quest dialogue RF | — | `Events.ValidateDialogueConditionOnServer` RF | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Quest prompt | `rules.accept_talk` | `Events.PromptRemote` RF | UNKNOWN | UNKNOWN | ProximityPrompt | — | kaitun fire INFERRED |
| Quest prompt | — | `Events.ProximityPrompt` RE | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Quest progress | `quests[].stages` | `Events.QuestProgress` RE | UNKNOWN | UNKNOWN | — | QuestInfo | STUDIO |
| Quest complete | `rules.turnin_*` | `Events.CompleteQuest` RE | UNKNOWN | UNKNOWN | Conditions xong | — | Thường do Talk/AutoComplete |
| Quest turn-in | `formulas.turnin` | `Events.TurnIn` RE | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Quest clear | — | `Events.ClearQuest` RE | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Quest client helper | — | `QuestInfo.ClientQuestFunctions.RemoteEvent` | UNKNOWN | UNKNOWN | — | QuestInfo | STUDIO |
| Quest prereq check | — | `Events.CheckQuestPrereqs` RF | UNKNOWN | UNKNOWN | — | QuestInfo | STUDIO |
| Quest prompt RF | — | `Events.PromptQuest` RF | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Quest collect | conditions Collect* | `Events.CollectQuestItem` RE | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Quest state | picker `Cache.Data.Quests` | `Events.UpdateQuestState` RE | UNKNOWN | UNKNOWN | — | ClientCache | STUDIO |
| Quest zone | Enter Zone / Investigate | `Events.QuestZoneEntered` RE | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Logbook | Basics Open Logbook | `Events.QuestEvents.OpenLogbookHelp` RE | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Markers | `rules.marker_circle` | `Events.Markers` RE; `Modules.Markers.RemoteEvent` | UNKNOWN | UNKNOWN | CollectionService tag | Markers | CreateMarker beam=true |
| Markers get | — | `Events.GetMarkers` RF | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Completed Quests | picker `Cache.Data["Completed Quests"]` | `Events.GetData` RF | kaitun `("Completed Quests")` INFERRED | table? UNKNOWN | — | ClientCache | Key name VERIFIED in picker |
| Player data | picker Cache.Data.Level | `Events.GetData` RF | UNKNOWN besides INFERRED key | UNKNOWN | — | ClientCache | |
| Level / EXP | `formulas.LevelEXP` | `Events.UpdateXP` / `EXPGained` RE | UNKNOWN | UNKNOWN | — | StatSystem | Formula trong QuestInfo dump |
| Gold | `quests[].gold` | `Events.GoldChanged` / `UnsecuredGold` RE | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Stats invest | Basics TotalStatPoints | `Events.StatPoints` RE | `("Invest", statName, n)` **VERIFIED** MenuHandler | unused via GetStats | Unused stat points | StatSystem | Reset `("Reset")` |
| Stats tutorial | — | `Events.QuestEvents.InvestStats` RE | UNKNOWN | UNKNOWN | Tutorial | QuestInfo.Functions.TutorialFolder.InvestStats | STUDIO |
| Stats replicate | StatSystem | `Events.StatReplication` RE | Client `FireServer()` **no args** VERIFIED | snapshot via OnClientEvent (char, stat, delta) | — | StatSystem | |
| Stats get | — | `Events.GetStats` / `GetExp` RF | UNKNOWN | UNKNOWN | — | StatSystem | STUDIO |
| Skill equip | Basics EquipSkill | `Events.EquipSkill` RF | UNKNOWN; kaitun `("Strong Punch")` INFERRED | UNKNOWN | Owned skill | — | |
| Skill unequip | — | `Events.UnequipSkill` RF | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Skill slots | — | `Events.CheckSkillSlots` RF | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Skills get | — | `Events.GetSkills` RF | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Skill use | — | `Events.Skill` RE | UNKNOWN | UNKNOWN | Energy | — | STUDIO |
| Skill scroll | — | `Events.ConsumeSkillScroll` RE | UNKNOWN | UNKNOWN | Scroll item | ItemInfo.Scrolls | STUDIO |
| Skill reset | — | `Events.ResetSkillUpgrade` RE | UNKNOWN | UNKNOWN | — | Product Skill Upgrade Reset | STUDIO |
| Fighting style | Closet tutorial | `Events.ChangeFightingStyle` RE | UNKNOWN | UNKNOWN | Unlocked style | Closet | STUDIO |
| Inventory | — | `Events.Inventory` RE | UNKNOWN | UNKNOWN | — | ItemInfo | STUDIO |
| Equip item | Gearing Up Equip Flintlock | `Events.Equip` RF | UNKNOWN; kaitun name or `{Name=}` INFERRED | UNKNOWN | — | ItemInfo | |
| Get equip | — | `Events.GetEquip` RF | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Unequip | — | `Events.Unequip` / `ForceEquip` / `EquipToolRemote` | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Sell | Gearing Up Sell watch | `Events.SellItem` RE | UNKNOWN | UNKNOWN | Merchant | — | STUDIO |
| Shop | Purchase * | `Events.Shop` RE | `("Purchase", InteractablePart, qty)` VERIFIED Shop Item | item in Inventory | Price attr / ItemInfo | PromptInformation.Shop Item | Rowboat uses Ships |
| Craft | Craft Stone Ring | `Events.Craft` / `Recipe` RE | UNKNOWN | UNKNOWN | Recipe + table | ItemInfo | STUDIO |
| Upgrade | Upgrade Flintlock | `Events.Upgrade` RE | UNKNOWN | UNKNOWN | Copper Bar×2 | UpgradeBonusPools | STUDIO |
| Delete/lock | — | `DeleteItem` / `LockItem` / `ShareItem` / `TransferItemToSlot` | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Codes | — | `Events.Codes` RE | kaitun `(code)` INFERRED | UNKNOWN | — | — | strings không trong data |
| Codes prog | — | `Events.CodeProg` RE | kaitun `(row.Code, row.Index)` INFERRED | list OnClient INFERRED | — | — | |
| Fruit pickup | Closet / DF | `Events.PickupDF` RE | UNKNOWN | UNKNOWN | World fruit? | FruitInformation | STUDIO |
| Fruit chest | — | `Events.FruitChest` RE; `ToolFunctions.Functions.Fruit Chest.OpenFruitChest` | UNKNOWN; kaitun `(model)` INFERRED | UNKNOWN | — | — | STUDIO |
| Fruit perm | — | `Events.PermanentFruit` RE | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Logia tree | — | `UnlockLogiaNode` / `RespecLogia` / `GetLogiaData` | UNKNOWN | UNKNOWN | Fruit? | — | STUDIO |
| Fishing | Fish * | `Events.Fishing` RE; `PromptFishing` RF | UNKNOWN | UNKNOWN | Rod + water | — | STUDIO |
| Fishing extra | — | `FishingCutscene` / `ChumFish` | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Mining | Copper/Iron/Lead | `Events.PickaxeHit` / `PickaxeDoubleStrike` | UNKNOWN | UNKNOWN | Pickaxe | — | STUDIO |
| Treasure | Treasure Map (Easy) | `DisplayTreasureMapRemote` / `MeetTreasureMapCondition` / `GetTreasureMapDisplay` | UNKNOWN | UNKNOWN | Map item | — | STUDIO |
| Dig | Dig belongings | `Events.ShovelHit` RE | UNKNOWN | UNKNOWN | Shovel | — | STUDIO |
| Farm | Plant/Water/Fertilize | `PlantSeed` / `WaterCrop` / `FertilizeCrop` / `RefillCan` | UNKNOWN | UNKNOWN | Seed / can | — | STUDIO |
| Lifeskill XP | `lifeskill_exp` | `Events.LifeskillEXP` RE; `GetLifeskillEXP` RF | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Lifeskill tree | — | `UnlockLifeskillNode` / `RespecLifeskill` / `RebirthLifeskill` / `BuyRebirthPerk` | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Boats | Purchase/Spawn Rowboat | `Events.Ships` RE | `("Purchase",{Type="Rowboat"})` VERIFIED; `("Spawn", index)` ShipViewer | boat out | 50G world Price | Shop Item + ShipViewer | index from owned list |
| Teleport | Setting Sail / Journey | `TeleportService` / `CustomTravelEvent` / `GetTeleportLocations` | UNKNOWN | UNKNOWN | GameplayPaused wait | `rules.gameplay_paused` | STUDIO |
| Chests | Afuaru loot | `Events.AfuaruChest` / `FastOpenChest` | UNKNOWN | UNKNOWN | Key / inside | — | STUDIO |
| World chest | — | `WorldBossChest` RE; `OpenWorldBossChest` | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Daily reset | Daily quests | `GetTimeUntilDailyReset` RF | UNKNOWN | UNKNOWN | — | — | celestial 10 |
| Weekly reset | Weekly | `GetTimeUntilWeeklyReset` RF | UNKNOWN | UNKNOWN | — | — | celestial 25 |
| Faction | The Stolen Tip Jar | `Events.FactionRemote` RE; `GetFaction` RF | UNKNOWN | UNKNOWN | — | — | stub quest |
| Crew | Crew quests | `CrewRemote` + Crew* RFs | UNKNOWN | UNKNOWN | — | — | exp 0 |
| Race/Trait | — | `Reroll` / `TraitChoice` / `TraitStorage` / `GetRerolls` | UNKNOWN | UNKNOWN | Product? | RaceInfo | STUDIO |
| Haki | MaxHaki stat | `RerollAuraColor` RE | UNKNOWN | UNKNOWN | — | ConquerorHaki effect | no trainer remote named Haki |
| Pets | Chicken Pet | `Events.Pets` RE | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Arm wrestle | Arm Wrestling 1–3 | `Events.ArmWrestle` RE | UNKNOWN | UNKNOWN | — | — | STUDIO |
| Titles | Guest of Honor, etc. | `Events.Titles` RE; `GetTitles` RF | UNKNOWN | UNKNOWN | Quest complete | — | STUDIO |
| Combat | — | `Combat` / `AttackPlayer` / `DamageFromClient` / `SwingEvent` | UNKNOWN | UNKNOWN | — | AttackModule (kaitun require) | không document PoC |
| Emote | Brawler Pushup/Situp | `Events.Emote` RE | UNKNOWN | UNKNOWN | — | — | STUDIO |

---

## Quest flow (VERIFIED, không remote-spam)

1. Tìm NPC / CollectionService tag (`markers[].tag`).
2. Đợi `GameplayPaused` hết nếu vừa tele xa.
3. ProximityPrompt Interaction=Dialogue, dist=16.
4. `ClientQuest:FireServer("Talk", DisplayName)`.
5. `DialogueBindable:Fire(Configuration)`.
6. Click option Accept / Thank — **không** Decline.
7. Server chạy BeginQuest / Complete.
8. Automatic quests: không bước 4–6 khi đủ prereq; marker beam dẫn đường.

---

## Data getters (picker VERIFIED keys, remote args UNKNOWN)

`ClientCache.Data` fields picker đọc:

- `Level` / `level` / `Stats.Level`
- `Completed Quests` / `CompletedQuests` (list hoặc map)
- `Quests` (live)

StatSystem `GetValue(character, "Level")`.

Character attribute `Level`.

---

## Studio Events inventory

- RemoteEvent dưới `RS.Events`: **244** (kể cả nested).
- RemoteFunction: **86** (list đầy đủ lúc dump: GetMouse, GetOrder, GetEquip, PromptRemote, GetEffects, GetActionCache, GetControllers, GetExp, GetStats, GetCrew, GetSettings, CreateParty, GetParty, GetUpdateParty, GetTargetRemote, GetTitles, GetFaction, GetRerolls, GetData, Equip, GetNPCPresets, GetBattlepass, RunDialogueFunctionOnServer, ValidateDialogueConditionOnServer, GetDummy, GetMobileButtons, PromptFishing, Charge, WaitForGroundedRemote, GetCFrame, GetController, GetMarkers, GetRecipes, GetLifeskillEXP, CheckImpactServer, LeapSmash, GetClosestCharToMouse, GetServers, GetSkills, GetInvisibilityCache, QuickTimeEvent, GetRandomFriend, GetKeybinds, GetJollyRoger, EquipSkill, CheckSkillSlots, UnequipSkill, GetMiscData, CheckQuestPrereqs, OwnershipBindable, GetNPCInfo, PromptQuest, GetEmotes, GetTimeUntilDailyReset, GetTimeUntilWeeklyReset, GetCosmetics, RequestAmountFromSliderRemote, BatchValidation, BatchDialogue, DeathScreen, GetTreasureMapDisplay, GetTargetAndMouse, GetCooldown, ChargeRelease, GetSlotData, GetShipInfo, ClaimAchievement, RequestBankAmountRemote, GetTeleportLocations, GetTreasureDebugInfo, GetTimelineDialogueOptions, Loadouts, GetSulongData, GetWorldType, GetLifeskillEffects, GetBarber, GetTransferSlots, GetLogiaData, GetLifeskillDailyOffers, ResetMenuRemote, GetCharacterSheet, CrewDirectory, GetCrewDepositables, CrewChatHistory, CrewFilterPreview, CrewPresence).

Args/return tất cả RF trên: **UNKNOWN** trừ ghi chú riêng.

---

## Module map (verify)

| Module | Path | Role |
|---|---|---|
| QuestInfo | `RS.Modules.QuestInfo` | Quest dump source |
| QuestInfoUtilities | `...QuestInfo.QuestInfoUtilities` | — |
| LevelGateConfig | `...QuestInfo.LevelGateConfig` | `MidIslandGate(N)` → 1 if Consolidated |
| StatSystem | `RS.Modules.StatSystem` | Stats + StatReplication |
| ClientCache | `RS.Modules.ClientCache` | picker Data |
| ItemInfo | `RS.Modules.ItemInfo` | Item modules (STUDIO list) |
| FruitInformation | `RS.Modules.FruitInformation` | Fruit (chưa dump) |
| RaceInfo | `RS.Modules.RaceInfo` | Races folder (Human only in snapshot) |
| AttackModule / StateService | required by kaitun | combat/state — không RE ở turn này |
