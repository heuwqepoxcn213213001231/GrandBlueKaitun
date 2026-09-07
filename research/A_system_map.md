# A. Complete Game System Map

Mọi hệ dưới đây: **không bịa**. Không có trong data → UNKNOWN. Tên Studio ghi **STUDIO**.

Data path gốc: `data.json` keys `source`, `count`, `rules`, `formulas`, `story_chains`, `training_chains`, `quests[]`, `level_plan`.

Studio modules đã verify khi data/picker nhắc tới: `ReplicatedStorage.Modules.QuestInfo`, `StatSystem`, `ClientCache`, `ItemInfo`.

---

## 1. Player Progression

**Là gì:** Level + EXP + Gold + Celestial Coins + quest unlocks. Stat Points / Skill Points tồn tại như hệ (tutorial + remotes) nhưng công thức không nằm trong `data.json`.

| Field | Evidence | Confidence |
|---|---|---|
| Level | Quest condition `Required` target `Level`; `Cache.Data.Level`; StatSystem `Level` | VERIFIED |
| EXP to next | `formulas.LevelEXP` = `10 + 10 * level^1.1` | VERIFIED |
| Gold | `quests[].gold` | VERIFIED |
| Celestial Coins | Daily **10**, Weekly **25** (`formulas.celestial`); quests Daily/Weekly field `celestial` | VERIFIED |
| Stat Points | Basics stage `Required` `TotalStatPoints`; ClientCache keys `StatPoints` / `Stat Points` / `UnusedStatPoints` (picker/kaitun) | VERIFIED tồn tại; cost UNKNOWN |
| Skill Points | ItemInfo Developer Product `Skill Point Reset` | STUDIO; grant/cost UNKNOWN |
| Mastery | Skill type quests `Chop Chop Punch`, `Liberation` (island `Skill Mastery`); archived `Leveling Skill` levels Strong Punch / Gunshot | Partial |
| Reputation / Bounty | Sushi passives tên `N Rep Punch` (hit-count, không phải bounty). Remote `WantedLevel` | UNKNOWN bounty/rep economy |
| Pirate / Marine / Faction | Quest type `Faction` stub `The Stolen Tip Jar` (stages rỗng). Remote `FactionRemote`. NPC `Marine Recruiter` (DialogueNPCs) | UNKNOWN join/rank |
| Level cap | Không có | **UNKNOWN** |
| Unlocks | Story chain + `accept_level` + `level_gates` / `Required Level` | VERIFIED |
| Best EXP | Xem B + C. Repeatable band + story gates. Side `Undermine The Circus 3` exp **2741** (one-shot) | VERIFIED numbers |
| Best Gold | Side >> Story. `Undermine The Circus 3` gold **2700**; Sushi 9 gold **2580** | VERIFIED |

**EXP scale (VERIFIED rules):**

- Repeatable + Story **ngoài Anchor Town**: loader `math.round(exp * 0.8)`.
- Repeatable decay khi `lv > rangeMax+5`.

**Level-gated content (dump):** 7, 15, 20, 30, 35, 40, 43, 45, 50, 58, 60, 70. `Finders Keepers` `accept_level` 8. Mọi Clown side `accept_level` 30. Mọi Maple side `accept_level` 70.

**Remotes (tồn tại, args chủ yếu UNKNOWN):** `UpdateXP`, `EXPGained`, `GoldChanged`, `StatPoints`, `StatReplication`, `GetExp`, `GetStats`, `GetData`.

---

## 2. Stats

**StatSystem** (`RS.Modules.StatSystem`) defaults:

Investable (cùng group base 0): **Health, Strength, Agility, Precision, Energy, Willpower**.

Khác: Level, MovementSpeed (16), CastSpeed (1), AttackSpeed (1), CooldownReduction (0), Time (1), M1Damage (1), MaxHealth (100), MaxEnergy (100), **MaxHaki (100)**, MaxBreath (100), HealthRegen/EnergyRegen/HakiRegen/BreathRegen (1), Antiheal, percents.

Damage types: Blunt, Sharp, Heat, Cold, Internal, Mental, Posture.  
SubTypes: Physical, Fire, Ice, Light, Snow, Dark, Smoke, Swamp, Poison.  
ChangeTypes: Add, Multiply, Divide, Base. Formula: `(Base * Multiply + Add) / Divide`.

| Câu hỏi | Status |
|---|---|
| How to increase | Basics: invest Stat Points (UI). **VERIFIED** `StatPoints:FireServer("Invest", child.Name, n)` MenuHandler |
| Cost per point | 1 unused point per `n` (UI). Grant-per-level UNKNOWN |
| Cap | UNKNOWN (radar soft 125) |
| Scaling (1 Str = ?) | UNKNOWN |
| Requirements | Basics bắt invest trước khi mở Logbook |
| Reset | ItemInfo `Stat Reset` Developer Product — STUDIO; giá UNKNOWN |
| Optimal allocation | UNKNOWN / không có evidence |

Tutorial remote: `Events.QuestEvents.InvestStats` + module `QuestInfo.Functions.TutorialFolder.InvestStats`.

---

## 3. Skill Tree / Skills

**Không có skill tree đầy đủ trong data.json.** Skills hiện qua quest drops / conditions / Fighting Style chains.

### Starter (VERIFIED)

| Skill | Source | Notes |
|---|---|---|
| Strong Punch | Introduction drop `item_type=Skill` | EquipSkill + Cast trong Basics |
| Gunshot | Archived Aim Training / Leveling Skill | Đi với Flintlock (Gearing Up) |

### Sushi chain — passives + King's Punch (VERIFIED)

Hit Training Dummy, talk Sushi. Mỗi bậc ReplacePassive bậc trước.

| Quest | Hits | Drop |
|---|---|---|
| Sushi's Training 1 | 100 | Passive `100 Rep Punch` |
| 2 | 1,000 | `1,000 Rep Punch` |
| 3 | 10,000 | `10,000 Rep Punch` |
| 4 | 100,000 | `100,000 Rep Punch` |
| 5 | 1,000,000 | `1,000,000 Rep Punch` + Skill `King's Punch` |
| 6–8 | 1e7 / 1e8 / 1e9 | Rep Punch tương ứng |
| 9 | 1e10 | **không có drop trong dump** |

### Fighting Style skills (VERIFIED quest conditions)

| Style | Trainer | Skills / mechanics named |
|---|---|---|
| Brawler | Wallace | Pushup/Situp emotes; Take Damage + Damage quotas |
| Novice Swordsman | Shiro | Power Slash, Sword Lunge, Whirlwind Slash (Unlock Skill bằng kill, rồi Damage) |
| Trickster | Loki [2] | Pocket Sand, Cheap Shot, Party Trick (Deceive), Poison / Poisoned Shiv, Fear, Trap while stealthed, Pickpocket Gold |
| Marksman | Captain Esopo | Projectile Land; Hunter's Timing; Hunter's Mark; Quickdraw |
| Big Shot | Pip (Side, Maple) | Lead Ball / Pepper Ball / Oil Ball / Flame Ball materials — không drop skill trong dump |

### Skill Mastery (VERIFIED)

| Quest | Condition | Folder Studio |
|---|---|---|
| Chop Chop Punch | Defeat `World Boss Buggy` | `QuestInfo.Quests.Skill Mastery Quests.Chop Chop` |
| Liberation | Defeat `World Boss Buggy` | `...Darkness` |

Prereq/cost/unlock level cho hai quest này: **không có** (accept_level 0, exp 0, không NPC).

Remotes STUDIO: `Skill`, `EquipSkill` (RF), `UnequipSkill`, `CheckSkillSlots`, `GetSkills`, `ResetSkillUpgrade`, `ConsumeSkillScroll`, `PromptSkillEquip`, `OpenSkillMenu`. Args UNKNOWN trừ kaitun `EquipSkill:InvokeServer("Strong Punch")` (INFERRED).

---

## 4. Inventory / Backpack

Data: tutorial `[TUTORIAL] Fruit/Style Storage` — **Closet** store fruits + swap fighting styles.

Remotes STUDIO: `Inventory`, `Equip` (RF), `GetEquip`, `Unequip`, `Equipped`, `EquipToolRemote`, `ForceEquip`, `SellItem`, `DeleteItem`, `LockItem`, `ShareItem`, `TransferItemToSlot`, `ChangeItemAmount`, `HeldItem`.

| Slot size / stack / buy slots | UNKNOWN |
| Categories | ItemInfo folders STUDIO — xem `studio_iteminfo_index.json` |
| Rarity / value / upgrade | Upgrade Flintlock (First Upgrade). `UpgradeBonusPools` module. Prices UNKNOWN |

---

## 5. Equipment

Chỉ item **có trong data.json** (drop/condition). Full Gear folders = STUDIO appendix.

| Slot (inferred from names) | Data items | Source |
|---|---|---|
| Hat | Terry's Hat | Terry's White Whale drop |
| Outfit | Joe's Overalls (Outfit); Chef Apron (Outfit) | The Full Harvest; The Perfect Dish |
| Accessory / ring | Stone Ring (Recipe); Terry's Ring (Recipe); Silver Miners Bracelet (collect) | Miner / Terry quests |
| Weapon / gun | Flintlock (purchase + upgrade); Slingshot materials (Lead Ball…) | Gearing Up / First Upgrade / Big Shot |
| Tool | Rusty Pickaxe (collect/purchase in mines); Carbon Rod (drop) | First Upgrade; Fisherman Jack's Challenge |
| Misc | Telescope; Transponder Snail; Handle (Recipe); Muggy Ball (Recipe) | Keeper / Voice in a Shell / Henry / Explosive 3 |

Req / stats: UNKNOWN. Shop prices (world Price): Flintlock 150, Cutlass 200, Rowboat 50, Snail 100, Pickaxe 25.

Studio Gear counts (không dump stats): Clothing 30, Accessories 16, Weapons 19, Subweapons 8, Hats 9, Back 3. Xem E appendix.

---

## 6. Weapons & Fighting Styles

### Starter gun

Gearing Up: Sell `Stolen Watch` → Purchase `Flintlock` → Equip → Shoot Training Dummy.  
First Upgrade: Rusty Pickaxe → 2 Copper Ore → Smelt 2 Copper Bar → **Upgrade Flintlock**.

Trainer/price Flintlock: “weapon shop” — NPC **UNKNOWN**. Merchant chỉ được nêu khi sell watch.

### Style trainers (VERIFIED)

| Style | NPC | Island (quest.island) | Location | Price | Reqs |
|---|---|---|---|---|---|
| Brawler | Wallace | Fighting Style | Advanced Training: “two trainers on the island” (Anchor) | UNKNOWN | Talk; emote/damage quests |
| Novice Swordsman | Shiro | Fighting Style | Cùng Advanced Training | UNKNOWN | Kill Corrupt Marine / Officer để unlock skill |
| Trickster | Loki [2] | Fighting Style | UNKNOWN map pin | UNKNOWN | 5 quests, không prereq trong dump |
| Marksman | Captain Esopo | Fighting Style | Marker `Captain Esopo (Dialogue)` — Esopo cũng là Maple story NPC | UNKNOWN | 4 quests |
| Big Shot | Pip | Maple Village Side | Maple, prereq The Island's Protector | UNKNOWN | Collect materials |

`training_chains` keys: sushi_training, arm_wrestling, undermine, explosive_research, militia_powerup, brawler, novice_swordsman, trickster, marksman, big_shot.

Arm Wrestling = Side Clown (emote reward), không phải FS.

Unlock-style vs chỉ làm quest: **UNKNOWN** (không có “buy style” field).

Remote: `ChangeFightingStyle`. Closet swap styles.

---

## 7. Cursed Fruit / Devil Fruit

**Trong data.json:**

- Closet stores fruits (tutorial text).
- Skill Mastery: Chop Chop Punch, Liberation vs World Boss Buggy.
- Không eat/replace/spawn table.

**Không bịa eat/replace rules.** UNKNOWN.

**STUDIO ItemInfo.Items.Devil Fruits modules (tên file, không phải rarity/skills):**  
Flame, Darkness, Invisibility, Spin, Chop, Bomb, Wolf, Clothing, Strength, Swim, Weight, Spike, Cannon, Drain.

Modules: `FruitInformation`, `FruitInfoUtilities`.  
Remotes: `PickupDF`, `FruitChest`, `PermanentFruit`, `CannonFruit`, `OpenFruitChest` (ToolFunctions), `ZoanUIToggle`, `PlayZoanAnimation`, `LogiaData`, `UnlockLogiaNode`, `RespecLogia`.

Obtain methods **evidenced:** Closet implies player can hold fruits; Fruit Chest product/remote; PickupDF. Spawn/chest/quest/boss/shop maps: **UNKNOWN** (không có trong data).

---

## 8. Race & Trait

Không có trong data.json.

| | Evidence | Status |
|---|---|---|
| Races | `RaceInfo.Races` snapshot chỉ **Human**. `WeightedRNG.RaceOdds` / `RaceVariantOdds` tồn tại, chưa dump | List UNKNOWN |
| Traits | Không TraitInfo. Products `Trait Reroll`. Remotes `TraitChoice`, `TraitStorage` | UNKNOWN |
| Reroll currency | Race Reroll / Trait Reroll = Developer Products | Robux? UNKNOWN in-game currency |
| When to reroll | UNKNOWN | |

---

## 9. Haki

Không quest/trainer/Haki tree trong data.json.

- StatSystem: MaxHaki, HakiRegen.
- UI: `ScreenGuis.UI.MainMenu.Background.Haki`.
- Effect: `Modules.Effects.Effects.Misc.ConquerorHaki`.
- Remote: `RerollAuraColor`.

Types / trainer / quests / mastery / upgrade: **UNKNOWN**.

---

## 10. Quest System

**151 quests.** Dump đầy đủ: `research/quests.json`.

Types: Story 42, Side 63, Fighting Style 17, Repeatable 13, Daily 7, Weekly 2, Skill 2, Crew 3, Cross Server Crew 1, Faction 1.

Folders: Main / Side / Repeatable / Daily / Weekly / Other / Archived / Tutorial.

**Accept (VERIFIED `rules`):**

- `Automatic=true` → vào logbook khi Prerequisites.Level + Prerequisites.Quests. Không click Accept.
- Else: Talk NPC, ProximityPrompt Dialogue dist=16. Client: `ClientQuest:FireServer("Talk", DisplayName)` + `DialogueBindable:Fire(Configuration)`. Click **Accept** (không Decline / Good luck with / Bye). Server Dialogue Command **BeginQuest**.
- Một số Fighting Style / Automatic Talk: Logbook BeginAutomatic.
- **Never FireServer BeginQuest** từ executor.

**Turn-in:**

- Stage cuối Talk / Automatic Talk → nói lại NPC.
- `AutoComplete` khi hết Kill/Hit/Collect (vd. Tyrannical Captain).
- Repeatable: nhận lại ngay nếu còn prereq + level.

**Markers:** `CreateMarker(cond, tag, nil, true)` = beam. CollectionService tag.

Bảng quest: `C_island_quest_route.md` + `quests.json`.

**Quest ID:** dump dùng **name string**, không numeric ID.

**Missing prereq:** `Leveling Skill` prereq `Officer Investigation` — quest này **không có** trong 151.

---

## 11. Islands / World

| Island | Studio `Workspace.Islands` | Story |
|---|---|---|
| Anchor Town | VERIFIED | Start → Setting Sail |
| Clown Town | VERIFIED | After Setting Sail, lv≥30 |
| Maple Village | VERIFIED | After Journey to Maple Village, lv≥70 |

Không sea / đảo 4 trong snapshot. Travel: mua **Rowboat**, Spawn tại dock, nói Mayor Kiyoshi (Clown); `Reach Maple Village` condition; remotes `TeleportService`, `CustomTravelEvent`, `GetTeleportLocations`, `DiscoverArea` — args UNKNOWN.

Spawns: mỗi đảo có `SpawnLocations`.  
Docks: Anchor docks (Trust Strongbox, lamp oil, boat shop).  
Shops named as zones: `Anchor Town Fishing Shop`, `Anchor Town Food Foo`, `Anchor Town Plaza`.

NPCs: `npcs.json` + DialogueNPCs Anchor (27 models). Clown/Maple DialogueNPCs folders **rỗng** snapshot này; entities stream `Workspace.Entities`.

---

## 12. Boats / Ships

| Evidence | Confidence |
|---|---|
| Purchase `Rowboat` + Spawn `Rowboat` (Setting Sail) | VERIFIED |
| Captain Jones = “Anchor Town boat shop” (Message for the Strongbox) | VERIFIED text |
| Terry's Boat Return | VERIFIED |
| Air Balloon Destroy (circus) | VERIFIED entity, không phải player boat |
| Remotes `Boats`, `Ships`, `GetShipInfo`, `CannonSeat`, `CannonFruit` | STUDIO |

Ship list / prices / upgrades: UNKNOWN. ItemInfo có `Ship Part` scroll.

---

## 13. Mining

| Evidence | |
|---|---|
| First Upgrade: purchase pickaxe in mines, mine Copper Ore, smelt Copper Bar | VERIFIED |
| Dwindling Iron Supply: 3 Iron Ore → Miner Song Kim Wu | VERIFIED |
| Miners Bracelet: Silver Miners Bracelet → Recipe Stone Ring; lifeskill Mining +100 | VERIFIED |
| Raid Preparations: 6 Lead Ore | VERIFIED |
| Big Shot: Lead (smelt Lead Ore) | VERIFIED |
| Remotes `PickaxeHit`, `PickaxeDoubleStrike` | STUDIO |

Pickaxe/ore list đầy đủ: STUDIO ItemInfo (xem index). Năng suất / node HP: UNKNOWN.

---

## 14. Fishing

| Quest | Do | Reward | Lifeskill |
|---|---|---|---|
| Wormless Terry | Collect 20 Worm | — | — |
| Terry vs. The Tide | Return Terry's Boat | Recipe Terry's Ring | — |
| Terry's White Whale | Fish Mythic+ Fish | Terry's Hat | Fishing +250 |
| Fisherman Jack's Challenge | Fish Carp | Carbon Rod | Fishing +100 |
| Jack's Daily Haul | stages **rỗng** | celestial 10 | UNKNOWN objectives |

Zones: Anchor Town Fishing Shop. Remotes: `Fishing`, `PromptFishing`, `FishingCutscene`, `ChumFish`.

Rods/fish names: STUDIO index. Rarity table: UNKNOWN (chỉ “Mythic+ Fish” trong data).

---

## 15. Farming / Cooking / life skills

Lifeskill keys trong dump: **Fishing, Mining, Farming, Cooking**.

Maple chain (VERIFIED):

- Green Thumb: Plant 4 Seed, Harvest 4 Crop, Farming +20
- A Balanced Field: Harvest Tomato/Carrot/Cabbage/Wheat, Water 4, 2 Egg, Farming +35
- The Full Harvest: Fertilize + Harvest 12, Joe's Overalls, Farming +50
- Kitchen Helper: Cook Grilled Fish, Cooking +20
- Fresh From the Farm: Egg, Raw Chicken, Cook Omelette + Roast Chicken, Cooking +35
- The Perfect Dish: Perfect Cook Dish (golden glow), Chef Apron, Cooking +50

Remotes: `PlantSeed`, `WaterCrop`, `FertilizeCrop`, `RefillCan`, `LifeskillEXP`, `GetLifeskillEXP`, `UnlockLifeskillNode`, `RespecLifeskill`, `RebirthLifeskill`, `BuyRebirthPerk`, `Craft`.

Lifeskill tree nodes / rebirth: UNKNOWN (remote only).

Wood / axe: ItemInfo `Oak Log`, `Rusty Axe`, remote `AxeHit` — không quest trong data.

---

## 16. Chests

| Chest | Evidence |
|---|---|
| Afuaru's Chests | The Hoarder: Loot 5 after key + gate |
| Fruit Chest | Remote + Developer Product |
| World Boss Chest | Remote `WorldBossChest`, `OpenWorldBossChest`; ItemInfo Logan/Choppy/Kuro |
| FastOpenChest | Remote |

Loot tables: UNKNOWN.

---

## 17. Treasure Maps

- Finders Keepers drop **Treasure Map (Easy)** (accept_level 8, Dig + kill Treasure Hunter).
- The 'Priceless' Haul: 3 Soggy Boot → Merchant appraise → wedding ring về Wade.
- ItemInfo cũng có Medium / Hard / Expert — STUDIO, không quest drop trong dump.
- Remotes: `DisplayTreasureMapRemote`, `MeetTreasureMapCondition`, `GetTreasureMapDisplay`, `GetTreasureDebugInfo`, `ShovelHit`.
- Wizards Apprentice: dig 4 shells (Calvin) — không phải Treasure Map item.

Dig mechanics / map spawn: UNKNOWN.

---

## 18. Bosses

Phân loại theo island/gate, không invent HP.

**Early (Anchor):**

| Target | Context | Gate |
|---|---|---|
| Afuaru, The Hoarder | Story The Hoarder + Weekly | 7 |
| Blonde Goblin | Captain's Brat, Feral Dog, Granny's Nemesis, weekly | 15 / 20 |
| Soro | Feral Dog + weekly | 20 |
| Axe-Hand Logan | Axe-Handed Tyrant, Tyrannical Captain, weekly | after Captive |
| Marine Snitch | Tea Party Crashers | — |
| Corrupt Marine / Officer / Guard | Repeatables + story | — |

**Mid (Clown):**

| Target | Context |
|---|---|
| Clown ×7 | A Joke / This Is Personal |
| Muggy Cannon | Sabotage |
| Circus Lion + Beast Tamer | Lion's Victim, Cat Problem, Undermine 2 |
| `"Barrel Clown" Binki` | Stephon's Tormentor — VERIFIED QuestInfo module |
| Killer Clown ×7 | Butcher / Billy's Business |
| Circus Supplier ×2 | Circus Suppliers |
| Clown Officer ×5 | Revenge / Nibblebottom's Revenge |
| Bazaji | Undermine 2 |
| Choppy The Clown | The Ringmaster, Undermine 3, Choppy repeatable |

**Late (Maple):**

| Target | Context |
|---|---|
| Captain Esopo | The Island's Protector — **Kill rồi Talk** (duel) |
| Black Noir Pirate / Officer | Proof, camps, Clear the Road, Peace of Mind |
| `"Hypnotist" Mango` | The Wandering Hypnotist — VERIFIED QuestInfo module |
| The Beast? | The Beast of Maple Village |
| Scratch, Grab | Expose the Butler |
| Black Noir Raid | Defend event |
| Kuro | Talk (butler), không kill trong dump |

**World:** `World Boss Buggy` (Skill Mastery). ItemInfo chests Logan / Choppy / Kuro → world-boss variants **INFERRED**, schedule UNKNOWN.

---

## 19. Codes

Không code string trong data.json.

STUDIO remotes: `Codes`, `CodeProg`.

kaitun.lua list (**INFERRED, chưa verify còn live**):  
`Release!`, `HappySunday`, `TwitterGoalReached`, `SorryForBreakingGame`, `10KCCU`, `WorldBossBroke`, `NewYouNewCrew`, `FruitBasket`.

kaitun: `Codes:FireServer(code)`; `CodeProg:FireServer(row.Code, row.Index)` — args **INFERRED**.

---

## 20. Daily / Rewards

| Quest | Island | celestial | exp | gold | Objectives |
|---|---|---|---|---|---|
| Easy Pickings | Anchor | 10 | 69 | 7 | Steal + Cash Out Tip Jar (Aria) |
| Noise Complaint | Anchor | 10 | 43 | 6 | Kill Sushi |
| Jack's Daily Haul | Anchor | 10 | 0 | 0 | **stages empty** |
| Kim Wu's Daily Quota | Anchor | 10 | 0 | 0 | **empty** |
| Joe's Daily Chores | Maple | 10 | 0 | 0 | **empty** |
| Remy's Daily Order | Maple | 10 | 0 | 0 | **empty** |
| Daily Quest Test | Test | 10 | 64 | 6 | Hit 5 Dummy |
| Corruption Cleanse | Anchor Weekly | 25 | 207 | 9 | Kill 6 Marine, Afuaru, 5 Officer, Blonde Goblin, Soro, Logan |
| Weekly Quest Test | Test | 25 | 127 | 13 | Hit 5 Dummy |

Reset: `GetTimeUntilDailyReset`, `GetTimeUntilWeeklyReset` — args UNKNOWN.

Battlepass / Gifts remotes: STUDIO, không trong data.

---

## 21. Shops / NPC purchases

Purchase conditions trong data:

| Item | Quest | Text |
|---|---|---|
| Flintlock | Gearing Up | “weapon shop” |
| Rusty Pickaxe | First Upgrade | “Purchase a pickaxe down in the mines” (condition type Collect) |
| Transponder Snail | A Voice in a Shell | “Purchase … from the shop” |
| Rowboat | Setting Sail | “boat shop” / Captain Jones |

Sell: Stolen Watch → Merchant.

Donate: 100 Gold → Penniless Pete; 6 Dish → Esopo pantry.

Named shop zones: Fishing Shop, Food Foo, Plaza.

Smuggler: Overdue Payment → `[50%] Smuggler's Coupon`.

Remotes: `Shop`, `RotatingShop`, `CashShop`, `SellItem`. Catalog/prices: **UNKNOWN**.

DialogueNPCs thêm (STUDIO, không quest): Marine Recruiter, Barber Bartolo, Qualalatina, Ricky. Barber remote `Barber` / `GetBarber`.

---

## Extras (không nằm trong 21)

| Hệ | Evidence | Status |
|---|---|---|
| Closet | Tutorial | VERIFIED purpose |
| Crew | 3 kill-count quests + Cross Server; remotes Crew* | Partial |
| Pets | Pecking Order Chicken Pet; ItemInfo pets | Partial |
| Bank / Tomoe | Message for the Strongbox — “opening an account” | Talk only |
| Arm Wrestling | 3 sides + emote Arm Wrestle; remote `ArmWrestle` | VERIFIED |
| World events / raid | Black Noir Raid, World Boss, `RaidStatus` | Partial |
| Logia / Sulong trees | Unlock/Respec remotes | UNKNOWN |
| Character slots | CharacterSlots remotes | UNKNOWN |
| Achievements | ClaimAchievement | UNKNOWN |
| Janken | Remote + kaitun HARD list; **không quest** trong dump | UNKNOWN |
