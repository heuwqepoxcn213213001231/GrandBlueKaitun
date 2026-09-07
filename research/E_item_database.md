# E. Item Database

**Phần 1 = data.json only.** Usefulness = quest/progression role, không invent DPS.

Rows đầy đủ: `items.json`.  
Phần 2 = STUDIO ItemInfo names — không có stats/price trừ khi trùng data.

---

## 1. Drops (quests[].drops)

| Item | Type | Source quest | Island | Prereq / lv | Usefulness (evidence) |
|---|---|---|---|---|---|
| Strong Punch | Skill | Introduction | Anchor | — | Starter skill; Basics bắt equip/cast |
| Stolen Watch | Drop | Pirate Fan Letter | Anchor | Basics | Gearing Up **Sell** để lấy gold mua Flintlock |
| Treasure Map (Easy) | Drop | Finders Keepers | Anchor | accept 8 | Treasure system; Medium+ không có trong dump |
| Pirate's Ruby | Drop | Finding Denver | Anchor | Overdue Payment | Overdue Payment **Collect** nộp Smuggler |
| Carbon Rod | Drop | Fisherman Jack's Challenge | Anchor | Fish Carp | Rod; stats UNKNOWN |
| Handle | Recipe | Handle Recipe | Anchor | 2 Stick + Cloth | Craft UNKNOWN output |
| Telescope | Drop | Keeper of the Flame | Anchor | Lamp Oil | Remote TelescopeZoomed; stats UNKNOWN |
| Stone Ring | Recipe | Miners Bracelet | Anchor | Silver bracelet | Miners Stone Ring = Craft Stone Ring |
| [50%] Smuggler's Coupon | Drop | Overdue Payment | Anchor | Ruby | Shop discount? UNKNOWN |
| 100 … 1,000,000,000 Rep Punch | Passive | Sushi 1–8 | Anchor | chain | ReplacePassive bậc trước |
| King's Punch | Skill | Sushi's Training 5 | Anchor | 1e6 hits | Skill; remote KingsPunchCharge |
| Terry's Ring | Recipe | Terry vs. The Tide | Anchor | Wormless | Craft UNKNOWN |
| Terry's Hat | Drop | Terry's White Whale | Anchor | Mythic+ Fish | Hat |
| Calvin's Treasure | Drop | Wizards Apprentice | Anchor | 4 shells | Cũng là Developer Product STUDIO |
| Arm Wrestle | Emote | Arm Wrestling 3 | Clown | chain | Emote |
| Muggy Ball | Recipe | Explosive Research 3 | Clown | Gunpowder from Choppy | Subweapon STUDIO |
| Clown Laughter | Emote | Tightrope Trouble | Clown | Rescue Augustine | Emote |
| Joe's Overalls (Outfit) | Drop | The Full Harvest | Maple | Farm chain | Outfit |
| Chef Apron (Outfit) | Drop | The Perfect Dish | Maple | Cook chain | Outfit |

Sushi 9: không drop.

---

## 2. Condition items (quest cần có / dùng)

### Combat / story objects

| Item / object | Type | Quest | Notes |
|---|---|---|---|
| Flintlock | Purchase + Equip + Upgrade | Gearing Up / First Upgrade | Starter gun |
| Transponder Snail | Purchase + Equip | A Voice in a Shell | Travel comms |
| Rowboat | Purchase + Spawn | Setting Sail | Gate Clown |
| Rusty Pickaxe | Collect (buy in mines) | First Upgrade | Mining |
| Copper Ore / Copper Bar | Collect / Smelt | First Upgrade | Upgrade Flintlock |
| Afuaru's Key | Collect | The Hoarder | Unlock Afuaru's Gate |
| Afuaru's Chests | Loot ×5 | The Hoarder | Chest |
| Pirate Fan Letter | Collect | Pirate Fan Letter | From Marines |
| Captive Swordsman's Swords | CollectLocal | Captive Swordsman | Return |
| Mayor's Mustache | CollectLocal | Mayor's Stache | — |
| Pirate Instructions | Collect | Pirate Instructions | From officers |
| Servant's Journal | CollectLocal | Missing Servants | — |
| Stolen Goods | Deliver Object ×2 | Proof of Pirates | — |
| Trust Strongbox | Deliver Object | Collections | Docks |
| Sealed Satchel | CollectLocal timed | Courier's Test | Strongbox ship |
| Lamp Oil | CollectLocal | Keeper of the Flame | Harbor crates |
| Denver The Dog | CollectLocal | Finding Denver | — |
| Henrietta | CollectLocal | Trouble Down the Well | — |
| Wade's Belongings | Dig/Collect | Finders Keepers | — |
| Silver Miners Bracelet | CollectLocal | Miners Bracelet | — |

### Materials / food / life

| Item | Type | Quest |
|---|---|---|
| Apple ×5 / Apple Pot Pie | Collect / Deliver | Apple Pot Pie |
| Apple, Carrot, Lemon, Banana | Collect | Feed The Hungry |
| Stick ×2, Cloth | Collect (barrels/crates) | Handle Recipe |
| Iron Ore ×3 | Collect | Dwindling Iron Supply |
| Worm ×20 | Collect | Wormless Terry |
| Carp | Fish | Jack's Challenge |
| Mythic+ Fish | Fish | Terry's White Whale |
| Soggy Boot ×3 | Collect | Priceless Haul |
| Red/Yellow/White/Black Shell | CollectLocal | Wizards Apprentice |
| Explosive Wooden Crate ×5 | Deliver Object | Explosive Research 1 |
| Clown Cannon Ball | Collect | Explosive Research 2 |
| Gunpowder | Collect | Explosive 3; Big Shot 4 ×2 |
| Clown Propaganda Poster ×10 | CollectLocal | Clown Propaganda |
| Dumbbell | CollectLocal | Militia Powerup 1 |
| Sturdy Stick, Tomato Crate, Fist Wraps | CollectLocal | Militia |
| Lead ×2 / Lead Ore ×6 / Lead Ball | Collect | Big Shot / Raid Prep |
| Pepper ×10 | Collect | Big Shot 2 (Pepper Seeds text) |
| Oil ×3 | Collect | Big Shot 3 (cooked from Sardines — quest text) |
| Seed ×4 / Crop | Plant/Harvest/Water/Fertilize | Green Thumb chain |
| Tomato, Carrot, Cabbage, Wheat | Harvest | A Balanced Field |
| Egg ×2 | Collect | Balanced / Fresh From the Farm |
| Raw Chicken | Collect | Fresh From the Farm |
| Grilled Fish, Omelette, Roast Chicken | Cook | Remy chain |
| Dish | Perfect Cook / Donate ×6 | Perfect Dish / Siege |
| Chicken Pet | Obtain (very rare) | Pecking Order |
| Gold ×100 | Donate | Down on His Luck |
| Tip Jar | Steal + Cash Out | Easy Pickings |

### Skills as “items” in conditions

Strong Punch, Gunshot, Power Slash, Sword Lunge, Whirlwind Slash, Pocket Sand, Cheap Shot, Projectile, Sword, Poison, Pushup, Situp — xem `skills.json`.

---

## 3. Usefulness ranking (data-only)

**Story-critical:** Strong Punch, Stolen Watch, Flintlock, Rusty Pickaxe, Copper, Transponder Snail, Rowboat, Afuaru's Key.

**Progression gear named:** Carbon Rod, Terry's Hat, Stone Ring, Joe's Overalls, Chef Apron, King's Punch, Muggy Ball recipe.

**Map/system unlock:** Treasure Map (Easy), Closet (not an item).

**Unknown usefulness (có tên, không stats):** Telescope, Calvin's Treasure, Smuggler Coupon, Terry's Ring recipe, Handle recipe, emotes.

---

## 4. STUDIO appendix (không phải data)

Xem `studio_iteminfo_index.json`.

Tồn tại module, **chưa dump stats/source/req**:

- Devil Fruits (15): Flame, Darkness, Invisibility, Spin, Chop, Bomb, Wolf, Clothing, Strength, Swim, Weight, Spike, Cannon, Drain, Light
- World shop Price (Anchor): Flintlock 150, Cutlass 200, Rowboat 50, Transponder Snail 100, Rusty Pickaxe 25, Rusty Shovel 25, Wooden Rod 75, Worm/food 5
- Treasure Map Medium/Hard/Expert
- World Boss Chest (Logan / Choppy / Kuro)
- Rods: Wooden, Fiberglass, Silverline, Deep-Sea, Terry's Trusted, Celestial (+ Carbon trong data)
- Ores/bars/pickaxes/gems lists
- Gear: 19 weapons, 8 subweapons (Flintlock, Muggy Ball trùng data), 9 hats (Terry's Hat trùng), clothing/accessories
- Fish 38 names (Carp trùng)
- Seeds 6; watering cans; sickles
- Developer Products: Stat/Trait/Race/Height/Aura rerolls, Fruit Chest, Skill resets

**Không** coi list Studio là shop inventory hay drop table.
