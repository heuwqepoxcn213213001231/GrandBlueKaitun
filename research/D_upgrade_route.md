# D. Upgrade Route

Chỉ bước **có evidence**. Còn lại UNKNOWN.

---

## Stats

1. Basics bắt `Required` `TotalStatPoints` (invest ≥1).
2. Sáu stat investable (StatSystem): Strength, Willpower, Agility, Precision, Energy, Health.
3. Cost / cap / soft-cap / respec in-game: UNKNOWN. Product `Stat Reset` = STUDIO.
4. Optimal: **không có** trong data. kaitun invest Strength — INFERRED habit, không phải fact game.

Remote: `StatPoints:FireServer("Invest", statName, n)` **VERIFIED** MenuHandler. Reset `("Reset")`. Replication: `StatReplication:FireServer()` no-arg — VERIFIED.

---

## Skills

| Khi | Làm gì | Evidence |
|---|---|---|
| Introduction | Nhận Strong Punch | drop Skill |
| Basics | EquipSkill + Cast Strong Punch | conditions |
| Gearing Up | Flintlock → Gunshot (archived Aim Training) | Shoot dummy |
| Advanced Training | Mở trainer Wallace + Shiro | Talk |
| FS quests | Unlock + practice skills từng style | Fighting Style 1–N |
| Sushi 5 | King's Punch | drop Skill |
| World Boss Buggy | Chop Chop Punch / Liberation mastery | Skill type quests |

Skill tree nodes, Skill Point grant, scroll use: remotes tồn tại (`ConsumeSkillScroll`, `ResetSkillUpgrade`). **UNKNOWN** cost/prereq.

---

## Weapon

| Order | Item | How | Quest |
|---|---|---|---|
| 1 | Flintlock | Purchase weapon shop + Equip | Gearing Up |
| 2 | Flintlock + | Upgrade after 2 Copper Bar | First Upgrade |
| 3 | Slingshot ammo | Lead / Pepper / Oil / Gunpowder balls | Big Shot 1–4 (text) |
| 4 | Muggy Ball | Recipe từ Explosive Research 3 | Craft UNKNOWN table |

Cutlass/Katana/Yoru/… = ItemInfo Weapons STUDIO — **không có shop/quest source trong data**.  
Novice Swordsman dùng skill kiếm, không drop named sword.

---

## Armor / Outfit / Hat

| Item | Source quest | Req |
|---|---|---|
| Terry's Hat | Terry's White Whale | Wormless → Tide → Mythic+ Fish |
| Joe's Overalls (Outfit) | The Full Harvest | Green Thumb → Balanced Field; lv70 |
| Chef Apron (Outfit) | The Perfect Dish | Kitchen Helper → Fresh From the Farm; Perfect Cook |

Stats/slot rules: UNKNOWN. Studio Hats/Clothing list: `studio_iteminfo_index.json`.

---

## Backpack / storage

- Closet: store fruits + swap fighting styles (tutorial).
- Size / extra slots: UNKNOWN.
- Bank: Tomoe “opening an account” (talk only).

---

## Fruit

- Hold/swap qua Closet — VERIFIED text.
- Eat / replace / drop-on-death: **UNKNOWN — do not invent**.
- Chest / PickupDF remotes: STUDIO.
- Mastery: Chop (Chop Chop Punch) + Darkness (Liberation) vs Buggy.
- 14 fruit module names: STUDIO index, không phải drop table.

---

## Haki

Không upgrade path trong data. MaxHaki stat tồn tại. Trainer/quest: UNKNOWN.

---

## Race / Trait

Không path. Products Race/Trait Reroll STUDIO. RaceInfo snapshot chỉ Human. Khi nào reroll: UNKNOWN.

---

## Life skills

Thứ tự Maple **Farming:** Green Thumb → A Balanced Field → The Full Harvest.  
**Cooking:** Kitchen Helper → Fresh From the Farm → The Perfect Dish.  
**Fishing:** Wormless Terry → Tide → White Whale; song song Jack's Challenge (Carp → Carbon Rod).  
**Mining:** First Upgrade (Copper) → Dwindling Iron / Miners Bracelet → Maple Lead Ore.

Lifeskill EXP numbers: Fishing 100/250, Mining 100, Farming 20/35/50, Cooking 20/35/50.

Node tree / rebirth (`UnlockLifeskillNode`, `RebirthLifeskill`): UNKNOWN.

---

## Fighting styles — practical order (evidenced)

1. Strong Punch (forced).  
2. Flintlock (forced story).  
3. Advanced Training → nói Wallace + Shiro (Anchor).  
4. Brawler / Swordsman quests khi cần skill.  
5. Trickster (Loki [2]) — không level gate trong dump.  
6. Marksman (Esopo) — Esopo cũng Maple; làm lúc nào UNKNOWN (không accept_level).  
7. Big Shot sau Protector (lv70).  
8. Sushi song song (King's Punch ở bậc 5 = 1e6 hits — cực chậm).

Price/stat req để **mở** style: UNKNOWN.

---

## Sushi (nếu grind)

Chỉ đáng nếu cần Rep Punch / King's Punch. Bậc 8–9 = 1e9–1e10 hits — không phải route level.

---

## Không đủ evidence để xếp

Shop armor progression, Haki color, fruit rolling order, crew reforge, world-boss gear (Logan/Choppy/Kuro chests STUDIO only).
