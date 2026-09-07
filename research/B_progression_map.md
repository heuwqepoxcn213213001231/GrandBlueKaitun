# B. Progression Map

Gates lấy từ `data.json` → `level_plan.hard_gates` + `quests[].level_gates` / `Required` Level. Không invent đảo sau Maple.

## EXP

`formulas.LevelEXP` = **`10 + 10 * level^1.1`** (VERIFIED).

| Level | EXP (công thức) |
|---|---|
| 1 | 20.0 |
| 5 | 68.7 |
| 7 | 95.0 |
| 10 | 135.9 |
| 15 | 206.7 |
| 20 | 279.9 |
| 25 | 354.9 |
| 30 | 431.5 |
| 35 | 509.4 |
| 40 | 588.5 |
| 45 | 668.5 |
| 50 | 749.4 |
| 55 | 831.1 |
| 60 | 913.6 |
| 70 | 1080.6 |
| 80 | 1249.9 |
| 100 | 1594.9 |

Level cap: hard **UNKNOWN**. `Info.LEVEL_SOFT_CAP` = 125 (radar). Content dump kết thúc Maple Village (story accept 70). Repeatable Maple `full_until` 78 / 81. Sushi 8–9 là grind hit, không phải gate level.

Loader: Repeatable + Story ngoài Anchor → `round(exp*0.8)`. Số `exp` trong bảng dưới = field dump.

## Island by progress (`level_plan.island_by_progress`)

1. Chưa xong **Setting Sail** → Anchor Town  
2. Xong Setting Sail, chưa **Journey to Maple Village** → Clown Town (lv≥30)  
3. Xong Journey → Maple Village (lv≥70)

## Hard gates (`level_plan.hard_gates`)

| Quest | Level |
|---|---|
| Setting Sail | 30 |
| A Joke Gone Too Far | 30 |
| Journey to Maple Village | 70 |
| The Island's Protector | 70 |

## Pick order (`level_plan.pick_order`) — picker logic, không phải lore

1. Live quest nếu còn stage (repeatable thì lv≤full_until)  
2. Main story tiếp theo trên chain đảo hiện tại nếu lv≥need_level + prereq  
3. Repeatable EXP cao nhất trong band, NPC/mob đã stream  
4. Không lấy Test / Archived / Crew / Daily stub  

---

## Fresh (1–7) — Anchor Town

Mục tiêu: tutorial combat → Flintlock → Afuaru.

| Step | Quest | Auto | Gate | EXP | Gold | Notes |
|---|---|---|---|---|---|---|
| 1 | Introduction | Y | — | 10 | 8 | Dummy ×4, Dash, Block; drop Strong Punch |
| 2 | Basics | Y | — | 10 | 4 | EquipSkill/Cast Strong Punch; invest TotalStatPoints; Open Logbook |
| 3 | Pirate Fan Letter | Y | — | 31 | 8 | Koro; collect letter; drop Stolen Watch |
| — | Bullies in Suits (rep) | N | band 5–7, full_until 12 | 40 | 4 | Kill 6 Corrupt Marine; prereq Fan Letter |
| 4 | Gearing Up | Y | — | 43 | 9 | Sell watch, buy/equip Flintlock, shoot dummy |
| 5 | The Hoarder | Y | **7** | 95 | 11 | Kill Afuaru, key, gate, loot 5 chests |

Side hữu ích sớm: Wormless Terry, Feed The Hungry, Down on His Luck, Handle Recipe, miner/fisher nếu stream.

## Early (7–30) — Anchor Town

| Step | Quest | Gate | EXP | Gold | Combat |
|---|---|---|---|---|---|
| 6 | First Upgrade | — | 20 | 8 | Pickaxe, 2 Copper, smelt, Upgrade Flintlock |
| 7 | Tea Party Crashers | — | 20 | 8 | 7 Officer + Marine Snitch |
| — | Officer Termination (rep) | band 8–15, until 20 | 105 | 7 | 7 Officer |
| — | Advanced Training (side-branch) | — | 20 | 8 | Talk Graves [2], Wallace, Shiro |
| 8 | Captain's Brat | **15** | 207 | 14 | Blonde Goblin + 2 Guard |
| — | Granny's Nemesis (rep) | band 15–20, until 25 | 157 | 7 | Cùng mob |
| 9 | Feral Dog | **20** | 20 | 8 | Blonde Goblin + Soro |
| 10 | Gate of Authority | — | 310 | 17 | Open Marine Gate (timing) |
| 11 | Captive Swordsman | — | 325 | 18 | Lấy kiếm, trả |
| 12 | Axe-Handed Tyrant | — | 1065 | 56 | Kill Axe-Hand Logan; **không auto** |
| — | Tyrannical Captain (rep) | band 25–30, until 35 | 771 | 27 | Logan again; AutoComplete |
| 13 | A Voice in a Shell | — | 385 | 19 | Buy + Equip Transponder Snail |
| 14 | Setting Sail | **30** | 432 | 21 | Buy + Spawn Rowboat; Talk Mayor Kiyoshi |

Best EXP Anchor in-band: **Tyrannical Captain 771** (sau Logan) > Granny 157 > Officer 105 > Bullies 40.

Best Gold Anchor: Sushi late (900–2580) và miner sides (300–600) — one-shot, không repeat.

## Mid (30–70) — Clown Town

`accept_level` 30 cho story + hầu hết side. Story Automatic trừ `A Joke Gone Too Far`.

| Step | Quest | Gate | EXP | Gold | Combat / do |
|---|---|---|---|---|---|
| 1 | A Joke Gone Too Far | 30 | 346 | 21 | 7 Clown |
| — | This Is Personal (rep) | band 30–40, until 45 | 268 | 8 | 7 Clown |
| 2 | Sabotage The Cannon | **35** | 407 | 23 | Destroy Muggy Cannon |
| 3 | Lion's Victim | **40** | 942 | 50 | Lion + Beast Tamer |
| — | Cat Problem (rep) | band 40–45, until 50 | 827 | 21 | Cùng pair |
| 4 | Stephon's Tormentor | **43** | 509 | 26 | Kill `\` (tên UNKNOWN) |
| 5 | Butcher's Business | **45** | 534 | 27 | 7 Killer Clown |
| — | Billy's Business (rep) | band 45–55, until 60 | 494 | 12 | 7 Killer Clown |
| 6 | Circus Suppliers | **50** | 899 | 42 | 2 Circus Supplier |
| 7 | Clown Captives | — | 626 | 28 | Free captives |
| 8 | Revenge of the Nibblebottom | — | 665 | 29 | 5 Clown Officer + Air Balloon |
| — | Nibblebottom's Revenge (rep) | band 55–60, until 65 | 494 | 11 | 5 Officer |
| 9 | Escort The Mayor | **58** | 705 | 30 | Escort |
| 10 | Mayor's Stache | — | 611 | 34 | Collect mustache |
| 11 | Clown Town's Militia | — | 611 | 34 | Deliver 3 items to civilians |
| 12 | The Ringmaster | **60** | 2193 | 91 | Choppy The Clown |
| — | Choppy The Clown (rep) | band 60–70, until 75 | 1582 | 31 | Choppy |
| 13 | Journey to Maple Village | **70** | 2594 | 98 | Reach Maple Village |

Best EXP Clown: Journey **2594** (one-shot) / Ringmaster **2193** / Undermine 3 side **2741** / Choppy rep **1582** / Cat Problem **827**.

Side song song (không block story): Arm Wrestling 1–3, Explosive Research, Undermine 1–3, Tightrope/Ferris (kaitun HARD — escort/rescue), Militia Powerup (2–3 stages rỗng).

## Late (70+) — Maple Village

Mọi Maple story `accept_level` 70. Chỉ `The Island's Protector` không Automatic.

| Step | Quest | EXP | Gold | Combat / do |
|---|---|---|---|---|
| 1 | The Island's Protector | 865 | 33 | Kill Captain Esopo, rồi Talk |
| — | Clear the Road (rep) | 878 | 16 | 8 Black Noir Pirate; until 78 |
| — | Peace of Mind (rep) | 1215 | 22 | 5 Black Noir Officer; until 81 |
| 2 | Proof of Pirates | 878 | 33 | 7 Pirate + deliver Stolen Goods |
| 3 | Something Isn't Right | 891 | 33 | Talk villagers, 2 camps |
| 4 | Pirate Instructions | 891 | 33 | Collect instructions |
| 5 | The Wandering Hypnotist | 891 | 33 | Wake villagers; Kill `"Hypnotist" Mango` |
| 6 | The Beast of Maple Village | 905 | 33 | Kill The Beast? |
| 7 | Missing Servants | 918 | 34 | Investigate; Servant's Journal |
| 8 | Expose the Butler | 932 | 34 | Scratch + Grab |
| 9 | Raid Preparations | 932 | 34 | Warn NPCs; 6 Lead Ore |
| 10 | Stocked for a Siege | 932 | 34 | Donate 6 Dish |
| 11 | Destroy the Signalers | 946 | 34 | 3 signal fires |
| 12 | The Black Noir Raid | 959 | 34 | Defend raid; Talk Lady Maia |

Life-skill sides (Joe/Remy/Hank/Martha/Pip) chạy song song sau Protector (Big Shot cần Protector).

## Endgame (evidenced vs UNKNOWN)

**Có evidence:**

- Repeatable Maple đến ~81 rồi decay.
- Sushi 6–9 (hit 1e7–1e10) — grind vô hạn theo dump.
- Skill Mastery vs World Boss Buggy.
- Weekly Corruption Cleanse (Anchor bosses).
- Fruit / Haki / Race / Trait / Logia — hệ tồn tại (Studio), **không có route**.
- Không đảo 4 trong `Workspace.Islands`.

**UNKNOWN:** level cap, sea 2, Haki unlock, fruit spawn, crew progression rewards, world-boss rotation.

## Best EXP / Gold (dump, in-band)

**EXP one-shot:** Undermine 3 (2741) > Journey (2594) > Ringmaster (2193) > Axe-Handed Tyrant (1065) > Maple story ~865–959.

**EXP repeat:** Choppy 1582 (60–75) > Peace of Mind 1215 (70–81) > Cat Problem 827 (40–50) > Tyrannical Captain 771 (25–35) > Clear the Road 878 (70–78).

**Gold one-shot:** Undermine 3 (2700) > Sushi 9 (2580) > Sushi 8 (1860) > Arm Wrestling 3 (840). Story gold rất thấp (4–98).
