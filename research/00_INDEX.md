# Grand Blue (Eternal Pose) — Research Pack

**Turn scope:** Phase 4 RE + Phase 5–9 Kaitun implemented. Entry `kaitun.lua`. Version **1.0.6**. Reports: `FINAL_IMPLEMENTATION_REPORT.md`, `FINAL_CHECKLIST.md`, `REMOTE_REGISTRY.md`, `PROGRESSION_FINAL.md`, `RUNTIME_FIXES.md`, `QUEST_EXECUTION_MATRIX.md`.

**Place (Studio):** `place 118635363908336 Game.rbxl` — connected. `Workspace.Islands` chỉ có 3 đảo.

## Cách đọc pack

| File | Nội dung |
|---|---|
| `00_INDEX.md` | Overview, nguồn, legend |
| `A_system_map.md` | 21 hệ + extras |
| `B_progression_map.md` | Fresh → Endgame + gates |
| `C_island_quest_route.md` | Route đảo / quest / boss từ `level_plan` |
| `D_upgrade_route.md` | Upgrade chỉ nơi có evidence |
| `E_item_database.md` | Item từ `data.json` (+ phụ lục Studio) |
| `F_remote_map.md` | Action → remote → args |
| `G_missing.md` | Chưa RE |
| `RUNTIME_FIXES.md` | Crash/runtime fixes (1.0.1–1.0.5 prior; **1.0.6** live GetData+tracker + EquipSkill scroll) |
| `QUEST_EXECUTION_MATRIX.md` | Mọi stage verified: handler / resolver / validation |
| `quests.json` | 151 quest đã flatten |
| `items.json` | Drop + condition item rows |
| `skills.json` | Skill/passive rows từ quest |
| `npcs.json` | NPC ↔ quest |
| `studio_iteminfo_index.json` | Tên module ItemInfo/Race (Studio, không phải data) |

## Nguồn (thứ tự authority)

1. **`data.json`** — `ReplicatedStorage.Modules.QuestInfo + Dialogue/Prompt Studio dump`. 151 quests. **Nguồn chính.**
2. `picker.lua` — logic pick quest; phản ánh `rules` / `level_plan`.
3. `kaitun.lua` — **secondary only.** Dùng để liệt kê remote đã từng gọi, không coi args là fact.
4. Roblox Studio MCP (place connected) — **verify** path/tên đã có trong data, hoặc ghi nhận module tồn tại. Không bịa hệ từ tên Studio.
5. Transcript cũ — không dùng guess chưa verify.

`data.json` **không** chứa item DB / fruit DB / shop price / skill tree đầy đủ. Những hệ đó: tên module Studio = STUDIO, gameplay = UNKNOWN.

## Confidence legend

| Tag | Nghĩa |
|---|---|
| **VERIFIED** | Có trong `data.json` (key/path/string đúng) và/hoặc Studio xác nhận đúng tên đó |
| **INFERRED** | Suy từ formula/rule/picker; hoặc kaitun gọi remote (ghi rõ) |
| **STUDIO** | Tồn tại trên place (module/remote/folder). Không có trong data.json |
| **UNKNOWN** | Không có evidence. `NEED INVESTIGATION` |

Không đoán Remote arguments. Không bịa item/NPC/quest/fruit.

## Quick facts (VERIFIED trừ khi ghi khác)

- **3 đảo:** Anchor Town → Clown Town (gate **30**) → Maple Village (gate **70**). Không có đảo 4 trong `Workspace.Islands`.
- **LevelEXP:** `10 + 10 * level^1.1` (`formulas.LevelEXP`).
- **Level cap:** hard UNKNOWN. Studio `Info.LEVEL_SOFT_CAP` = **125** (radar scale only).
- **Gold** = money trong dump. **Celestial:** Daily **10**, Weekly **25** (`formulas.celestial`).
- **Story Auto:** hầu hết Main story `Automatic=true` vào logbook khi đủ prereq + level. **Không** `FireServer BeginQuest` từ executor (`rules.never_fire_beginquest`).
- **EXP scale:** Repeatable + Story ngoài Anchor Town: `math.round(exp * 0.8)` trong QuestInfo loader. Giá trị `exp` trong dump = field module; có thể là pre-scale.
- **Repeatable decay:** `player > rangeMax+5` → `floor(exp * max(0.1, 1/(1+(lv-(rangeMax+5))*0.15)))`. `full_until` (picker) = `rangeMax + 5`.
- **MidIslandGate(N):** dump `Consolidated=true` → runtime trả **1**; level ý định = argument N (7/15/20/30/35/40/43/45/50/58/60/70). Studio `LevelGateConfig` xác nhận.
- **Stats (StatSystem):** Strength, Willpower, Agility, Precision, Energy, Health. Invest **VERIFIED** `StatPoints("Invest", name, n)` (MenuHandler). Cost = unused points 1:1. Cap/grant curve UNKNOWN.
- **Haki trainer / backpack size:** UNKNOWN. Shop prices + RaceOdds + fruit names: Studio VERIFIED (xem FINAL / E / G).

## Systems snapshot

| # | Hệ | Trong data.json? | Status |
|---|---|---|---|
| 1 | Player Progression | Có (Level, EXP, Gold, Celestial, gates) | Một phần VERIFIED |
| 2 | Stats | Basics invest; StatSystem | Tên VERIFIED; cost UNKNOWN |
| 3 | Skills / Fighting Style | Quest drops + FS chains | Một phần |
| 4 | Inventory / Backpack | Closet tutorial only | UNKNOWN size |
| 5 | Equipment | Một vài drop/quest | Partial |
| 6 | Weapons / Styles | Flintlock, 4 FS trainers, Big Shot | Partial |
| 7 | Cursed / Devil Fruit | Closet + Skill Mastery | List STUDIO; eat rules UNKNOWN |
| 8 | Race & Trait | Không | STUDIO modules; list UNKNOWN |
| 9 | Haki | Stat MaxHaki only | UNKNOWN trainer |
| 10 | Quests | 151 | VERIFIED dump |
| 11 | Islands | 3 | VERIFIED |
| 12 | Boats | Rowboat purchase/spawn | Partial |
| 13 | Mining | First Upgrade + miner sides | Partial |
| 14 | Fishing | Jack / Terry | Partial |
| 15 | Farming / Cooking | Maple sides | Partial |
| 16 | Chests | Afuaru loot | Partial |
| 17 | Treasure Maps | Treasure Map (Easy) drop | Partial |
| 18 | Bosses | Nhiều kill-target | Partial |
| 19 | Codes | Không trong data | Remote STUDIO; codes INFERRED kaitun |
| 20 | Daily / Weekly | Có, vài stub rỗng | Partial |
| 21 | Shops | Purchase conditions | Core prices VERIFIED (Studio Price) |

**Extras trong dump/Studio:** Closet, Crew, Pets, World Boss, Battlepass, Bank (Tomoe), Barber, Logia/Sulong nodes, Lifeskill tree remotes.
