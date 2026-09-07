# Progression FINAL — Fresh → Endgame

Gates + EXP từ `data.json`. Shop prices từ Studio world attributes. Kill names từ QuestInfo modules.

```
Anchor Town  --Setting Sail lv30 + Rowboat 50G-->  Clown Town  --Journey lv70-->  Maple Village
```

Hard level cap: **UNKNOWN**. Soft visual `LEVEL_SOFT_CAP=125` (radar only). Content dump ends Maple.

## Fresh (1–7) Anchor

1. **Introduction** — Talk Officer Graves (world instance `Officer Graves [2]`, DisplayName `Officer Graves`) → Dummy×4, Dash, Block → Talk Graves; Strong Punch drop → `PromptSkillEquip` if popup.
2. **Basics** — EquipStrongPunch scroll (`ConsumeSkillScroll` + `Skill("Equip","Strong Punch")`); Cast hotbar; `StatPoints Invest` ≥1; ForceOpenLogbook + `OpenLogbookHelp`.
3. **Pirate Fan Letter** — Talk Graves → Talk Koro → KillUntilDrop **Corrupt Marine** until letter (Stolen Watch side drop) → Talk Koro.
4. Repeat **Bullies in Suits** (band 5–12) if need EXP.
5. **Gearing Up** — Sell watch (`SellItem`); buy **Flintlock 150G**; backpack + `SaveOrder(Weapon2)` (HeldItem does not credit Equip); shoot dummy.
6. **The Hoarder** (lv7) — Kill Afuaru; key; loot 5 chests.

## Early (7–30) Anchor

7. **First Upgrade** — Buy **Rusty Pickaxe 25G** in mines; 2 Copper Ore; smelt; `Upgrade("Upgrade", Flintlock)`.
8. **Tea Party Crashers** — Officers + Marine Snitch. Repeat **Officer Termination**.
9. **Captain's Brat** (15) — Blonde Goblin. Repeat Granny's Nemesis.
10. **Feral Dog** (20) — Goblin + Soro.
11. **Gate of Authority** — Open Marine Gate (timing).
12. **Captive Swordsman** — retrieve swords.
13. **Axe-Handed Tyrant** — Axe-Hand Logan. Repeat **Tyrannical Captain** (771 EXP to 35).
14. **A Voice in a Shell** — Buy **Transponder Snail 100G**; HeldItem Equip.
15. **Setting Sail** (30) — `Ships Purchase {Type=Rowboat}` **50G**; Spawn; Talk Mayor Kiyoshi (Clown).

Sides (not blocking): Terry/Jack fish, miner bracelet, Finders Keepers (Treasure Map Easy), Sushi (slow), Advanced Training (Wallace/Shiro).

## Mid (30–70) Clown

1. **A Joke Gone Too Far** — 7 Clown. Repeat This Is Personal.
2. **Sabotage The Cannon** (35) — Muggy Cannon.
3. **Lion's Victim** (40) — Lion + Tamer. Repeat Cat Problem.
4. **Stephon's Tormentor** (43) — Kill **`"Barrel Clown" Binki`**.
5. **Butcher's Business** (45) — Killer Clown. Repeat Billy's Business.
6. **Circus Suppliers** (50).
7. **Clown Captives** — free captives.
8. **Revenge of the Nibblebottom** — Officers + Balloon.
9. **Escort The Mayor** (58) — follow Kiyoshi (do **not** skip).
10. **Mayor's Stache** / **Clown Town's Militia**.
11. **The Ringmaster** (60) — Choppy. Repeat Choppy The Clown (1582).
12. **Journey to Maple Village** (70) — Reach Maple.

Sides: Undermine 3 (2741 EXP / 2700G), Explosive Research (Muggy Ball recipe), Militia Powerup 2–3 (Muggy Ball / Slingshot deliver), Arm Wrestling.

## Late (70+) Maple

1. **The Island's Protector** — Kill then Talk Captain Esopo.
2. Repeats: Clear the Road / **Peace of Mind** (1215 to 81).
3. **Proof of Pirates** → Something Isn't Right → Pirate Instructions.
4. **The Wandering Hypnotist** — Wake villagers; Kill **`"Hypnotist" Mango`** (do **not** skip).
5. **The Beast of Maple Village** → Missing Servants → Expose the Butler (Scratch/Grab).
6. **Raid Preparations** (6 Lead Ore) → Stocked (6 Dish) → Signalers → **The Black Noir Raid**.

Life: Joe farm / Remy cook / Pip Big Shot after Protector.

## After Maple (evidenced)

- Repeats until ~81 then decay.
- Sushi 6–9 hit grind (not a level route).
- Skill Mastery vs World Boss Buggy (spawn UNKNOWN).
- Weekly Corruption Cleanse.
- Fruit/Haki/Race exist; **no progression route** — AutoHaki/Race off; fruit KEEP_CURRENT.
- No island 4 in `Workspace.Islands`.

## Money for gates

Keep gold for Flintlock 150, Pickaxe 25, Snail 100, Rowboat 50 (total **325G** story shop). Food 5G optional. Do not dump gold on 250G outfits unless config.

## Empty / skip

Jack/Kim/Joe/Remy dailies — stub modules, no stages. Faction Stolen Tip Jar — stub. Officer Investigation — missing (archived Leveling Skill blocked).
