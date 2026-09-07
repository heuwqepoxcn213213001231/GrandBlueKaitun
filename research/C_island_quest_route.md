# C. Island / Quest Route

Nguồn: `data.json` `story_chains`, `training_chains`, `level_plan`, `quests[]`.  
`need_level` = max(`level_gates`) hoặc `accept_level`.  
`full_until` = `exp_range[1] + 5` khi `exp_range` là `[min,max]`.

Chi tiết stage: `quests.json`.

---

## Route chính (3 đảo)

```
Anchor Town  --Setting Sail lv30-->  Clown Town  --Journey lv70-->  Maple Village
```

### Anchor Town story (`story_chains[0].order`)

| # | Quest | NPC accept → turnin | need | EXP | Gold | Target / do | Prereq | Next |
|---|---|---|---|---|---|---|---|---|
| 1 | Introduction | Officer Graves | 0 | 10 | 8 | Dummy×4, Dash, Block | — | Basics |
| 2 | Basics | Officer Graves | 0 | 10 | 4 | Strong Punch, invest stats, Logbook | Introduction | Pirate Fan Letter |
| 3 | Pirate Fan Letter | Graves → Koro | 0 | 31 | 8 | Collect letter; drop Stolen Watch | Basics | Gearing Up |
| 4 | Gearing Up | (auto) | 0 | 43 | 9 | Sell watch, buy Flintlock | Fan Letter | The Hoarder |
| 5 | The Hoarder | Troubled Civilian | 7 | 95 | 11 | Afuaru + key + 5 chests | Gearing Up | First Upgrade |
| 6 | First Upgrade | Blacksmith Shinozaki | 0 | 20 | 8 | Mine/smelt/Upgrade Flintlock | The Hoarder | Tea Party Crashers |
| 7 | Tea Party Crashers | Maeve | 0 | 20 | 8 | 7 Officer + Snitch | First Upgrade | Captain's Brat |
| 8 | Captain's Brat | Granny Todo | 15 | 207 | 14 | Goblin + 2 Guard | Tea Party | Feral Dog |
| 9 | Feral Dog | (auto) | 20 | 20 | 8 | Goblin + Soro | Captain's Brat | Gate of Authority |
| 10 | Gate of Authority | (auto) | 0 | 310 | 17 | Open Marine Gate | Feral Dog | — (Captive via prereq) |
| 11 | Captive Swordsman | Captive Swordsman | 0 | 325 | 18 | Retrieve swords | Gate | — |
| 12 | Axe-Handed Tyrant | (auto, not Automatic talk) | 0 | 1065 | 56 | Axe-Hand Logan | Captive | A Voice in a Shell |
| 13 | A Voice in a Shell | Officer Graves | 0 | 385 | 19 | Buy+Equip Transponder Snail | Logan quest | Setting Sail |
| 14 | Setting Sail | Graves → Mayor Kiyoshi | 30 | 432 | 21 | Rowboat + talk Clown mayor | Voice | — |

Side-branch: **Advanced Training** (prereq Tea Party Crashers) — Wallace + Shiro. Không trên main order.

Archived (không pick): Aim Training, Leveling Skill (prereq **Officer Investigation** — quest thiếu).

### Clown Town story (`story_chains[1].order`)

| # | Quest | NPC | need | EXP | Gold | Target | Prereq |
|---|---|---|---|---|---|---|---|
| 1 | A Joke Gone Too Far | Clowny D. Clown | 30 | 346 | 21 | 7 Clown | — |
| 2 | Sabotage The Cannon | Clowny | 35 | 407 | 23 | Muggy Cannon | Joke |
| 3 | Lion's Victim | Stephon | 40 | 942 | 50 | Lion + Tamer | Sabotage |
| 4 | Stephon's Tormentor | Stephon | 43 | 509 | 26 | Kill `"Barrel Clown" Binki` | Lion |
| 5 | Butcher's Business | Billy B. | 45 | 534 | 27 | 7 Killer Clown | Tormentor |
| 6 | Circus Suppliers | Mayor Kiyoshi | 50 | 899 | 42 | 2 Circus Supplier | Butcher |
| 7 | Clown Captives | Mayor Kiyoshi | 30 | 626 | 28 | Free 2 child + 4 adult | Suppliers |
| 8 | Revenge of the Nibblebottom | Johnny Nibblebottom | 30 | 665 | 29 | 5 Officer + Balloon | Captives |
| 9 | Escort The Mayor | Kiyoshi → Kiyoshi [2] | 58 | 705 | 30 | Escort | Revenge |
| 10 | Mayor's Stache | Kiyoshi [2] | 30 | 611 | 34 | Mayor's Mustache | Escort |
| 11 | Clown Town's Militia | Kiyoshi [2] → Civilian 3 | 30 | 611 | 34 | Stick/Tomato/Wraps → 3 civilians | Stache |
| 12 | The Ringmaster | Kiyoshi [2] | 60 | 2193 | 91 | Choppy The Clown | Militia |
| 13 | Journey to Maple Village | Mayor Kiyoshi | 70 | 2594 | 98 | Reach Maple Village | Ringmaster |

### Maple Village story (`story_chains[2].order`)

| # | Quest | NPC | EXP | Gold | Target | Prereq |
|---|---|---|---|---|---|---|
| 1 | The Island's Protector | Captain Esopo | 865 | 33 | Kill then Talk Esopo | — |
| 2 | Proof of Pirates | Esopo | 878 | 33 | 7 Black Noir Pirate + 2 Stolen Goods | Protector |
| 3 | Something Isn't Right | Joe/Tara/Martha → Esopo | 891 | 33 | 2 camps (crates + pirates) | Proof |
| 4 | Pirate Instructions | Esopo | 891 | 33 | Collect Pirate Instructions | Something |
| 5 | The Wandering Hypnotist | Esopo | 891 | 33 | Wake villagers; Kill `"Hypnotist" Mango` | Instructions |
| 6 | The Beast of Maple Village | Barry → Esopo | 905 | 33 | The Beast? | Hypnotist |
| 7 | Missing Servants | Kuro → Esopo | 918 | 34 | Journal | Beast |
| 8 | Expose the Butler | Servant → Esopo | 932 | 34 | Scratch + Grab | Servants |
| 9 | Raid Preparations | Remy/Joe/Pip/Maia → Esopo | 932 | 34 | 6 Lead Ore | Expose |
| 10 | Stocked for a Siege | Esopo | 932 | 34 | Donate 6 Dish | Raid Prep |
| 11 | Destroy the Signalers | Esopo | 946 | 34 | 3 Signal Fires | Stocked |
| 12 | The Black Noir Raid | Lady Maia | 959 | 34 | Defend Black Noir Raid | Signalers |

---

## Repeatable EXP band (picker `full_until`)

| Quest | Island | accept | exp_range | full_until | EXP | Gold | Kill | NPC | Prereq |
|---|---|---|---|---|---|---|---|---|---|
| Bullies in Suits | Anchor | 0 | 5–7 | 12 | 40 | 4 | 6 Corrupt Marine | Koro | Pirate Fan Letter |
| Officer Termination | Anchor | 0 | 8–15 | 20 | 105 | 7 | 7 Officer | Maeve | Tea Party Crashers |
| Granny's Nemesis | Anchor | 0 | 15–20 | 25 | 157 | 7 | Goblin + 2 Guard | Granny Todo | Captain's Brat |
| Tyrannical Captain | Anchor | 0 | 25–30 | 35 | 771 | 27 | Axe-Hand Logan | (none, AutoComplete) | Axe-Handed Tyrant |
| This Is Personal | Clown | 30 | 30–40 | 45 | 268 | 8 | 7 Clown | Clowny | A Joke Gone Too Far |
| Cat Problem | Clown | 30 | 40–45 | 50 | 827 | 21 | Lion + Tamer | Stephon | Lion's Victim |
| Billy's Business | Clown | 30 | 45–55 | 60 | 494 | 12 | 7 Killer Clown | Billy B. | Butcher's Business |
| Nibblebottom's Revenge | Clown | 30 | 55–60 | 65 | 494 | 11 | 5 Officer | Johnny | Revenge of the Nibblebottom |
| Choppy The Clown | Clown | 30 | 60–70 | 75 | 1582 | 31 | Choppy | Mayor Kiyoshi [2] | The Ringmaster |
| Clear the Road | Maple | 70 | 70–73 | 78 | 878 | 16 | 8 Black Noir Pirate | Nell | Protector |
| Peace of Mind | Maple | 70 | 72–76 | 81 | 1215 | 22 | 5 Black Noir Officer | Gus | Protector |
| Debug Quest / 2 | Test | 0 | 0 | — | 8 | 5 | 1–2 Marine | — | SKIP |

---

## Training chains (`training_chains`)

### Sushi (Anchor, Side)

Sushi → Hit Dummy → Talk. Xem A/D cho hits + passives.

### Arm Wrestling (Clown, Side, accept 30)

1 Beginner → 2 Intermediate → 3 Champion (drop Emote `Arm Wrestle`). EXP 382 / 668 / 831.

### Undermine The Circus (Clown, Gambit)

1: 6 Clown + 2 Balloon + Free 2 Captive + Destroy 6 crates + Muggy Cannon.  
2: Bazaji + Lion + Tamer.  
3: Choppy. EXP 668 / 831 / **2741**. Gold **2700** ở bậc 3.

### Explosive Research (Clown, Mei)

1: Deliver 5 Explosive Wooden Crate.  
2: Collect Clown Cannon Ball.  
3: Gunpowder from Choppy → Recipe `Muggy Ball`.

### Militia Powerup (Clown, prereq Militia)

1: Collect Dumbbell → Civilian 1.  
2–3: **stages rỗng** — UNKNOWN. EXP 457 each.

### Fighting Style (island field = `Fighting Style`)

Brawler 1–4 Wallace; Novice Swordsman 1–4 Shiro; Trickster 1–5 Loki [2]; Marksman 1–4 Esopo. EXP/gold 0.

### Big Shot (Maple Side, Pip, prereq Protector)

1: 2 Lead. 2: Lead Ball + 10 Pepper. 3: Lead Ball + 3 Oil (cooked from Sardines — text). 4: Lead Ball + 2 Gunpowder. Title `Big Shot`.

---

## Side / life / title (không block story)

### Anchor Town

| Quest | lv | EXP | Gold | NPC | Do / drop | Title / extra |
|---|---|---|---|---|---|---|
| [TUTORIAL] Fruit/Style Storage | 0 | 0 | 0 | — | Visit Closet | island Tutorial |
| Down on His Luck | 0 | 82 | 162 | Pete | Donate 100 Gold | — |
| A Dish Best Served Cold | 0 | 96 | 174 | Pete | Convince Blonde Goblin | prereq Down on His Luck |
| Apple Pot Pie | 0 | 136 | 300 | Granny | 5 Apple → pie → Jay Vonera | — |
| Feed The Hungry | 0 | 136 | 300 | Loki | Apple, Carrot, Lemon, Banana | — |
| Finders Keepers | 8 | 115 | 282 | Wade | Dig + 4 Treasure Hunter | drop Treasure Map (Easy) |
| The 'Priceless' Haul | 0 | 129 | 294 | Merchant → Wade | 3 Soggy Boot | prereq Finders |
| Finding Denver | 0 | 69 | 240 | Jokic | Denver The Dog | drop Pirate's Ruby; prereq Overdue |
| Overdue Payment | 0 | 136 | 300 | Smuggler | Pirate's Ruby | drop 50% Coupon |
| Fisherman Jack's Challenge | 0 | 136 | 300 | Jack | Fish Carp | Carbon Rod; Fishing +100 |
| Wormless Terry | 0 | 69 | 240 | Terry | 20 Worm | — |
| Terry vs. The Tide | 0 | 95 | 264 | Terry | Return boat | Recipe Terry's Ring |
| Terry's White Whale | 0 | 280 | 420 | Terry | Mythic+ Fish | Terry's Hat; Fishing +250 |
| Handle Recipe | 0 | 136 | 300 | Henry | 2 Stick + Cloth | Recipe Handle |
| Keeper of the Flame | 0 | 136 | 300 | Otis | Lamp Oil | Telescope |
| Miners Bracelet | 0 | 136 | 300 | Jil Wu | Silver bracelet | Recipe Stone Ring; Mining +100 |
| Miners Stone Ring | 0 | 136 | 300 | — | Craft Stone Ring | — |
| Dwindling Iron Supply | 0 | 272 | 600 | Kim Wu | 3 Iron Ore | — |
| Guest List | 0 | 207 | 360 | Granny → Maeve | Invites + 2 Party Crasher | title Guest of Honor |
| Mina's Request | 0 | 207 | 360 | — | 3 zones + Escort Mina | — |
| Message for the Strongbox | 30 | 216 | 270 | Arashi → Jones | Talk Arashi, Tomoe, Jones | — |
| Paper Route | 0 | 294 | 330 | Nessa → Nagi | Notices 3 islands | prereq Voice |
| Collections | 0 | 334 | 360 | Nagi | 4 Marine + Strongbox | prereq Paper Route |
| Courier's Test | 0 | 375 | 390 | Nagi | Sealed Satchel timed | title Preferred Client; unlock_contact Nagi |
| Wizards Apprentice | 0 | 108 | 276 | Calvin | 4 shells | Calvin's Treasure |
| Sushi 1–9 | 0 | 20–3407 | 192–2580 | Sushi | Dummy hits | passives + King's Punch @5 |

### Clown Town sides (accept 30)

| Quest | EXP | Gold | Notes |
|---|---|---|---|
| Clown Imposter | 509 | 600 | Escort Fake Clown |
| Clown Propaganda | 382 | 450 | 10 Posters → Benny |
| Emergency Deliveries | 685 | 732 | 3 customers; prereq Butcher |
| Ferris Wheel Standoff | 848 | 852 | Lash → Marnie (kaitun HARD) |
| Tightrope Trouble | 668 | 720 | Rescue Augustine; Emote Clown Laughter |

### Maple Village sides (accept 70)

| Quest | EXP | Gold | Life | Drop / title |
|---|---|---|---|---|
| Green Thumb | 540 | 510 | Farm 20 | — |
| A Balanced Field | 557 | 522 | Farm 35 | — |
| The Full Harvest | 574 | 534 | Farm 50 | Joe's Overalls |
| Kitchen Helper | 540 | 510 | Cook 20 | — |
| Fresh From the Farm | 557 | 522 | Cook 35 | — |
| The Perfect Dish | 574 | 534 | Cook 50 | Chef Apron |
| Pecking Order | 540 | 510 | — | Obtain Chicken Pet (very rare) |
| Trouble Down the Well | 540 | 510 | — | Henrietta |
| Big Shot 1–4 | 540×4 | 510×4 | — | title Big Shot @4 |

---

## Daily / Weekly / Crew / Skill / Faction

Xem A §20. Crew: Defeat 25/50/75 Marines (exp 0); Cross Server 10 Marines → Koro.  
Skill: Chop Chop Punch, Liberation — Defeat World Boss Buggy.  
Faction: The Stolen Tip Jar — **empty stub**.

---

## Boss gắn route

| Phase | Island | Boss / elite | Quest |
|---|---|---|---|
| Fresh | Anchor | Afuaru, The Hoarder | The Hoarder |
| Early | Anchor | Blonde Goblin, Soro, Axe-Hand Logan | Brat / Dog / Tyrant |
| Mid | Clown | Lion, Tamer, barrel clown `\`, Choppy, Bazaji | Lion → Ringmaster / Undermine |
| Late | Maple | Esopo (duel), `"Hypnotist" Mango`, The Beast?, Scratch/Grab, Raid | Protector → Raid |
| World | ? | World Boss Buggy | Skill Mastery |
