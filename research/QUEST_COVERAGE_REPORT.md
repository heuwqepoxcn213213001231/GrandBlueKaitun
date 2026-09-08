# Quest Coverage Report

**Version:** 1.1.42  
**Source:** `research/quests.json` (151 QuestInfo modules) + `tools/build_game_data.py` → `Game/GeneratedData.lua`.

Quests dumped: **151**

## Repeatable Startability (1.1.24)

Repeatable farm selection now uses explicit `QuestData.REPEAT_START` metadata and does **not** auto-fallback to direct combat for NPC-start quests.

Historical `Completed Quests` membership is **not** treated as “already complete forever”. `QuestData.isRepeatable()` applies to every `REPEATS` entry (Granny's Nemesis, Officer Termination, Clown/Maple repeats, etc.). After one clear, the planner re-accepts via AcceptNPC and runs the live cycle again. Story quests still use `finished()` as terminal.

| Repeatable | Automatic | Accept NPC | Turn-in NPC | Status | Notes |
|---|---|---|---|---|---|
| Bullies in Suits | false | Koro | Koro | STARTABLE | quest-mode only |
| Officer Termination | false | Maeve | Maeve | STARTABLE | quest-mode only |
| Granny's Nemesis | false | Granny Todo | Granny Todo | STARTABLE | multi-condition stage 1 |
| Tyrannical Captain | false | — | — | UNRESOLVED_START | not auto-direct; skipped until verified |
| This Is Personal | false | Clowny D. Clown | Clowny D. Clown | STARTABLE | quest-mode only |
| Cat Problem | false | Stephon | Stephon | STARTABLE | quest-mode only |
| Billy's Business | false | Billy B. | Billy B. | STARTABLE | quest-mode only |
| Nibblebottom's Revenge | false | Johnny Nibblebottom | Johnny Nibblebottom | STARTABLE | quest-mode only |
| Choppy The Clown | false | Mayor Kiyoshi [2] | Mayor Kiyoshi [2] | STARTABLE | quest-mode only |
| Clear the Road | false | Nell | Nell | STARTABLE | quest-mode only |
| Peace of Mind | false | Gus | Gus | STARTABLE | quest-mode only |

### All stages

| Metric | Count |
|---|---|
| Stages | 439 |
| Planned | 424 |
| Implemented | 373 |
| Runtime verified | 12 |
| Runtime required | 0 |
| Unresolved | 66 |


### Anchor story (Introduction → Setting Sail)

| Metric | Count |
|---|---|
| Stages | 58 |
| Planned | 58 |
| Implemented | 58 |
| Runtime verified | 12 |
| Runtime required | 0 |
| Unresolved | 0 |


### Clown story

| Metric | Count |
|---|---|
| Stages | 53 |
| Planned | 53 |
| Implemented | 53 |
| Runtime verified | 0 |
| Runtime required | 0 |
| Unresolved | 0 |


### Maple story

| Metric | Count |
|---|---|
| Stages | 53 |
| Planned | 52 |
| Implemented | 52 |
| Runtime verified | 0 |
| Runtime required | 0 |
| Unresolved | 1 |


### Main route (Anchor+Clown+Maple story)

| Metric | Count |
|---|---|
| Stages | 164 |
| Planned | 163 |
| Implemented | 163 |
| Runtime verified | 12 |
| Runtime required | 0 |
| Unresolved | 1 |


## Unresolved stages

| Quest | Stage | Objective | Target | Note |
|---|---|---|---|---|
| Aim Training | 1 | Talk | Officer Graves | skip stub |
| Aim Training | 2 | Shoot | Training Dummy | skip stub |
| Aim Training | 3 | Talk | Officer Graves | skip stub |
| Leveling Skill | 1 | Level | Strong Punch | skip stub |
| Leveling Skill | 1 | Level | Gunshot | skip stub |
| Leveling Skill | 2 | Talk | Officer Graves | skip stub |
| The Black Noir Raid | 1 | Defend | Black Noir Raid | UNKNOWN |
| A Dish Best Served Cold | 1 | Convince | Blonde Goblin | UNKNOWN |
| Apple Pot Pie | 4 | Deliver Jay Vonera | Apple Pot Pie | UNKNOWN |
| Finders Keepers | 1 | Dig | up Wade's Belongings | UNKNOWN |
| Mina's Request | 1 | Enter Zone | Anchor Town Fishing Shop | UNKNOWN |
| Mina's Request | 1 | Enter Zone | Anchor Town Food Foo | UNKNOWN |
| Mina's Request | 1 | Enter Zone | Anchor Town Plaza | UNKNOWN |
| Miners Stone Ring | 1 | Craft | Stone Ring | Craft remote args UNKNOWN |
| Terry vs. The Tide | 1 | Return | Terry's Boat | UNKNOWN |
| Arm Wrestling 1 | 1 | Win Arm Wrestle | Beginner Arm Wrestler | UNKNOWN |
| Arm Wrestling 2 | 1 | Win Arm Wrestle | Intermediate Arm Wrestler | UNKNOWN |
| Arm Wrestling 3 | 1 | Win Arm Wrestle | Arm Wrestling Champion | UNKNOWN |
| Militia Powerup 2 | 1 | Unknown | — | UNKNOWN |
| Militia Powerup 2 | 2 | Unknown | — | UNKNOWN |
| Militia Powerup 3 | 1 | Unknown | — | UNKNOWN |
| Militia Powerup 3 | 2 | Unknown | — | UNKNOWN |
| Tightrope Trouble | 2 | Rescue | Augustine | UNKNOWN |
| Pecking Order | 1 | Obtain | Chicken Pet | UNKNOWN |
| Debug Quest | 1 | Kill | Corrupt Marine | skip stub |
| Debug Quest 2 | 1 | Kill | Corrupt Marine | skip stub |
| Brawler 1 | 1 | Emote | Pushup | UNKNOWN |
| Brawler 1 | 1 | Emote | Situp | UNKNOWN |
| Brawler 2 | 1 | Take Damage | — | UNKNOWN |
| Brawler 2 | 1 | Damage | — | UNKNOWN |
| Brawler 3 | 1 | Take Damage | — | UNKNOWN |
| Brawler 3 | 1 | Damage | — | UNKNOWN |
| Brawler 4 | 1 | Take Damage | — | UNKNOWN |
| Brawler 4 | 1 | Damage | — | UNKNOWN |
| Marksman 1 | 1 | Land | Projectile | UNKNOWN |
| Marksman 2 | 1 | Proc Hunter's Timing Passive | — | UNKNOWN |
| Marksman 3 | 1 | Land a projectile on a marked target | — | UNKNOWN |
| Marksman 4 | 1 | Reduce the cooldown of 25 skills, using quickdraw. | — | UNKNOWN |
| Marksman 4 | 1 | Speed up the windup of 25 skills, using quickdraw. | — | UNKNOWN |
| Novice Swordsman 1 | 1 | Unlock Skill | Power Slash | UNKNOWN |
| Novice Swordsman 1 | 2 | Damage | Power Slash | UNKNOWN |
| Novice Swordsman 2 | 1 | Unlock Skill | Sword Lunge | UNKNOWN |
| Novice Swordsman 2 | 2 | Damage | Sword Lunge | UNKNOWN |
| Novice Swordsman 3 | 1 | Unlock Skill | Whirlwind Slash | UNKNOWN |
| Novice Swordsman 3 | 2 | Damage | Whirlwind Slash | UNKNOWN |
| Novice Swordsman 4 | 1 | Damage | Power Slash | UNKNOWN |
| Novice Swordsman 4 | 1 | Damage | Sword Lunge | UNKNOWN |
| Novice Swordsman 4 | 1 | Damage | Whirlwind Slash | UNKNOWN |
| Novice Swordsman 4 | 1 | Damage | Sword | UNKNOWN |
| Trickster 1 | 1 | Pickpocket | Gold | UNKNOWN |
| Trickster 1 | 1 | Land | Pocket Sand | UNKNOWN |
| Trickster 2 | 1 | Land | Cheap Shot | UNKNOWN |
| Trickster 3 | 1 | Deceive | Hostile Enemy | UNKNOWN |
| Trickster 4 | 1 | Damage | Poison | UNKNOWN |
| Trickster 4 | 1 | Land Poisoned Shiv While Stealthed | — | UNKNOWN |
| Trickster 5 | 1 | Fear | Enemy | UNKNOWN |
| Trickster 5 | 1 | Place Down Trap While Stealthed | — | UNKNOWN |
| Easy Pickings | 1 | Steal | Tip Jar | UNKNOWN |
| Easy Pickings | 2 | Cash Out | Tip Jar | UNKNOWN |
| Jack's Daily Haul | 0 | — | — | no stages in QuestInfo |
| Kim Wu's Daily Quota | 0 | — | — | no stages in QuestInfo |
| Joe's Daily Chores | 0 | — | — | no stages in QuestInfo |
| Remy's Daily Order | 0 | — | — | no stages in QuestInfo |
| Daily Quest Test | 1 | Hit | Training Dummy | skip stub |
| Weekly Quest Test | 1 | Hit | Training Dummy | skip stub |
| The Stolen Tip Jar | 0 | — | — | no stages in QuestInfo |

## Pirate Fan Letter

- Goal: AcquireItem
- Method: EnemyDrop
- Source: **Corrupt Marine** (QuestInfo stage marker, CollectionService tag)
- Credit: kill → inventory **or** Collect `Target.Amount` (no world drop required; CollectQuestItem is not this quest)
- Validation: inventory/quest count 0/1 → 1/1

