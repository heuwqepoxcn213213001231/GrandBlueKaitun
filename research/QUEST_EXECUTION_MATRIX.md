# Quest Execution Matrix

Source: `research/quests.json` (QuestInfo Studio dump) + live Studio place `118635363908336`.
Planner: Goal + AcquireMethod. Collect is not ResolveShop/Item.
Pirate Fan Letter Collect source = **Corrupt Marine** (QuestInfo marker). Not Strong Marine.
Collect credits on kill (inventory / `Target.Amount`). No world pickup / CollectQuestItem.
Runtime identity: world Graves = `Workspace.AA IMPORTANT.DialogueNPCs.Anchor Town.Officer Graves [2]` (DisplayName `Officer Graves`).
Talk remote: `ClientQuest:FireServer("Talk", DisplayName)` + `DialogueBindable:Fire(Configuration)` — never `BeginQuest`.

| Quest | Stage | Island | ObjectiveType | Goal | Target | AcquireMethod | SourceTarget | SourceLocation | Prerequisites | Handler | Validation | Confidence | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| A Voice in a Shell | 1 | Anchor Town | Talk | Talk | Officer Graves | — | Officer Graves | Anchor Town | Axe-Handed Tyrant | Quest.talk | live Talk Officer Graves count 1 | STATIC_VERIFIED | IMPLEMENTED |
| A Voice in a Shell | 2 | Anchor Town | Purchase | AcquireItem | Transponder Snail | ShopPurchase | Transponder Snail | Anchor Town | Axe-Handed Tyrant | Shop.buy | inventory/quest Transponder Snail 1 | STATIC_VERIFIED | IMPLEMENTED |
| A Voice in a Shell | 3 | Anchor Town | Equip | Equip | Transponder Snail | — | Transponder Snail | Anchor Town | Axe-Handed Tyrant | Equipment.equipNamed | live Equip Transponder Snail count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Advanced Training | 1 | Anchor Town | Talk | Talk | Officer Graves [2] | — | Officer Graves [2] | Anchor Town | Tea Party Crashers | Quest.talk | live Talk Officer Graves [2] count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Advanced Training | 2 | Anchor Town | Talk | Talk | Wallace | — | Wallace | Anchor Town | Tea Party Crashers | Quest.talk | live Talk Wallace count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Advanced Training | 2 | Anchor Town | Talk | Talk | Shiro | — | Shiro | Anchor Town | Tea Party Crashers | Quest.talk | live Talk Shiro count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Aim Training | 1 | Anchor Town | Talk | Talk | Officer Graves | — | Officer Graves | Anchor Town | Gearing Up | Quest.talk | live Talk Officer Graves count 1 | STATIC_VERIFIED | UNRESOLVED |
| Aim Training | 2 | Anchor Town | Shoot | Kill | Training Dummy | — | Training Dummy | Anchor Town | Gearing Up | Combat.attack | live Shoot Training Dummy count 1 | STATIC_VERIFIED | UNRESOLVED |
| Aim Training | 3 | Anchor Town | Talk | Talk | Officer Graves | — | Officer Graves | Anchor Town | Gearing Up | Quest.talk | live Talk Officer Graves count 1 | STATIC_VERIFIED | UNRESOLVED |
| Axe-Handed Tyrant | 1 | Anchor Town | Kill | Kill | Axe-Hand Logan | — | Axe-Hand Logan | Anchor Town | Captive Swordsman | Combat.attack | live Kill Axe-Hand Logan count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Basics | 1 | Anchor Town | Talk | Talk | Officer Graves | — | Officer Graves | Anchor Town | Introduction | Quest.talk | live Talk Officer Graves count 1 | STATIC_VERIFIED | RUNTIME_VERIFIED |
| Basics | 2 | Anchor Town | EquipSkill | Skill | Strong Punch | — | Strong Punch | Anchor Town | Introduction | Skills.equip/cast | live EquipSkill Strong Punch count 1 | STATIC_VERIFIED | RUNTIME_VERIFIED |
| Basics | 3 | Anchor Town | Cast | Skill | Strong Punch | — | Strong Punch | Anchor Town | Introduction | Skills.equip/cast | live Cast Strong Punch count 1 | STATIC_VERIFIED | RUNTIME_VERIFIED |
| Basics | 4 | Anchor Town | Talk | Talk | Officer Graves | — | Officer Graves | Anchor Town | Introduction | Quest.talk | live Talk Officer Graves count 1 | STATIC_VERIFIED | RUNTIME_VERIFIED |
| Basics | 5 | Anchor Town | Required | Invest | TotalStatPoints | — | — | Anchor Town | Introduction | Stats.investMinimum | live Required TotalStatPoints count 1 | STATIC_VERIFIED | RUNTIME_VERIFIED |
| Basics | 6 | Anchor Town | Talk | Talk | Officer Graves | — | Officer Graves | Anchor Town | Introduction | Quest.talk | live Talk Officer Graves count 1 | STATIC_VERIFIED | RUNTIME_VERIFIED |
| Basics | 7 | Anchor Town | Open | OpenLogbook | Logbook | — | Logbook | Anchor Town | Introduction | Quest.openLogbook | live Open Logbook count 1 | STATIC_VERIFIED | RUNTIME_VERIFIED |
| Captain's Brat | 1 | Anchor Town | Required | LevelGate | Level | — | — | Anchor Town | Tea Party Crashers | DecisionEngine.levelFarm | live Required Level count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Captain's Brat | 2 | Anchor Town | Talk | Talk | Granny Todo | — | Granny Todo | Anchor Town | Tea Party Crashers | Quest.talk | live Talk Granny Todo count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Captain's Brat | 3 | Anchor Town | Kill | Kill | Blonde Goblin | — | Blonde Goblin | Anchor Town | Tea Party Crashers | Combat.attack | live Kill Blonde Goblin count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Captain's Brat | 3 | Anchor Town | Kill | Kill | Corrupt Guard | — | Corrupt Guard | Anchor Town | Tea Party Crashers | Combat.attack | live Kill Corrupt Guard count 2 | STATIC_VERIFIED | IMPLEMENTED |
| Captain's Brat | 4 | Anchor Town | Talk | Talk | Granny Todo | — | Granny Todo | Anchor Town | Tea Party Crashers | Quest.talk | live Talk Granny Todo count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Captive Swordsman | 1 | Anchor Town | Talk | Talk | Captive Swordsman | — | Captive Swordsman | Anchor Town | Gate of Authority | Quest.talk | live Talk Captive Swordsman count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Captive Swordsman | 2 | Anchor Town | CollectLocalItem | AcquireItem | Captive Swordsman's Swords | WorldPickup | Captive Swordsman's Swords | Anchor Town | Gate of Authority | Acquire.WorldPickup | inventory/quest Captive Swordsman's Swords 1 | STATIC_VERIFIED | IMPLEMENTED |
| Captive Swordsman | 3 | Anchor Town | Talk | Talk | Captive Swordsman | — | Captive Swordsman | Anchor Town | Gate of Authority | Quest.talk | live Talk Captive Swordsman count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Feral Dog | 1 | Anchor Town | Required | LevelGate | Level | — | — | Anchor Town | Captain's Brat | DecisionEngine.levelFarm | live Required Level count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Feral Dog | 2 | Anchor Town | Kill | Kill | Blonde Goblin | — | Blonde Goblin | Anchor Town | Captain's Brat | Combat.attack | live Kill Blonde Goblin count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Feral Dog | 2 | Anchor Town | Kill | Kill | Soro | — | Soro | Anchor Town | Captain's Brat | Combat.attack | live Kill Soro count 1 | STATIC_VERIFIED | IMPLEMENTED |
| First Upgrade | 1 | Anchor Town | Talk | Talk | Blacksmith Shinozaki | — | Blacksmith Shinozaki | Anchor Town | The Hoarder | Quest.talk | live Talk Blacksmith Shinozaki count 1 | STATIC_VERIFIED | IMPLEMENTED |
| First Upgrade | 2 | Anchor Town | Collect | AcquireItem | Rusty Pickaxe | ShopPurchase | Rusty Pickaxe | Anchor Town | The Hoarder | Shop.buy | inventory/quest Rusty Pickaxe 1 | STATIC_VERIFIED | IMPLEMENTED |
| First Upgrade | 3 | Anchor Town | Collect | AcquireItem | Copper Ore | Mining | Copper Ore | Anchor Town | The Hoarder | LifeSkills.mineToward | inventory/quest Copper Ore 2 | STATIC_VERIFIED | IMPLEMENTED |
| First Upgrade | 4 | Anchor Town | Talk | Talk | Blacksmith Shinozaki | — | Blacksmith Shinozaki | Anchor Town | The Hoarder | Quest.talk | live Talk Blacksmith Shinozaki count 1 | STATIC_VERIFIED | IMPLEMENTED |
| First Upgrade | 5 | Anchor Town | Smelt | AcquireItem | Copper Bar | Crafting | Furnace | Anchor Town | The Hoarder | LifeSkills.mineToward | inventory/quest Copper Bar 2 | STATIC_VERIFIED | IMPLEMENTED |
| First Upgrade | 6 | Anchor Town | Upgrade | Upgrade | Flintlock | — | Flintlock | Anchor Town | The Hoarder | Equipment.upgradeNamed | live Upgrade Flintlock count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Gate of Authority | 1 | Anchor Town | Open | Interact | Marine Gate | — | Marine Metal Gate | Anchor Town | Feral Dog | Quest.goTagged | live Open Marine Gate count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Gearing Up | 1 | Anchor Town | Sell | Sell | Stolen Watch | — | Stolen Watch | Anchor Town | Pirate Fan Letter | Shop.sellNamed | live Sell Stolen Watch count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Gearing Up | 2 | Anchor Town | Purchase | AcquireItem | Flintlock | ShopPurchase | Flintlock | Anchor Town | Pirate Fan Letter | Shop.buy | inventory/quest Flintlock 1 | STATIC_VERIFIED | IMPLEMENTED |
| Gearing Up | 3 | Anchor Town | Equip | Equip | Flintlock | — | Flintlock | Anchor Town | Pirate Fan Letter | Equipment.equipNamed | live Equip Flintlock count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Gearing Up | 4 | Anchor Town | Shoot | Kill | Training Dummy | — | Training Dummy | Anchor Town | Pirate Fan Letter | Combat.attack | live Shoot Training Dummy count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Introduction | 1 | Anchor Town | Talk | Talk | Officer Graves | — | Officer Graves | Anchor Town | — | Quest.talk | live Talk Officer Graves count 1 | STATIC_VERIFIED | RUNTIME_VERIFIED |
| Introduction | 2 | Anchor Town | Hit | Kill | Training Dummy | — | Training Dummy | Anchor Town | — | Combat.attack | live Hit Training Dummy count 4 | STATIC_VERIFIED | RUNTIME_VERIFIED |
| Introduction | 3 | Anchor Town | Dash | CombatAction | Press Q | — | — | Anchor Town | — | Combat.dash/block | live Dash Press Q count 2 | STATIC_VERIFIED | RUNTIME_VERIFIED |
| Introduction | 4 | Anchor Town | Block | CombatAction | Hold F | — | — | Anchor Town | — | Combat.dash/block | live Block Hold F count 1 | STATIC_VERIFIED | RUNTIME_VERIFIED |
| Introduction | 5 | Anchor Town | Talk | Talk | Officer Graves | — | Officer Graves | Anchor Town | — | Quest.talk | live Talk Officer Graves count 1 | STATIC_VERIFIED | RUNTIME_VERIFIED |
| Leveling Skill | 1 | Anchor Town | Level | Other | Strong Punch | — | Strong Punch | Anchor Town | Officer Investigation | UNKNOWN | live Level Strong Punch count 1 | UNKNOWN | UNRESOLVED |
| Leveling Skill | 1 | Anchor Town | Level | Other | Gunshot | — | Gunshot | Anchor Town | Officer Investigation | UNKNOWN | live Level Gunshot count 1 | UNKNOWN | UNRESOLVED |
| Leveling Skill | 2 | Anchor Town | Talk | Talk | Officer Graves | — | Officer Graves | Anchor Town | Officer Investigation | Quest.talk | live Talk Officer Graves count 1 | STATIC_VERIFIED | UNRESOLVED |
| Pirate Fan Letter | 1 | Anchor Town | Talk | Talk | Officer Graves | — | Officer Graves | Anchor Town | Basics | Quest.talk | live Talk Officer Graves count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Pirate Fan Letter | 2 | Anchor Town | Talk | Talk | Koro | — | Koro | Anchor Town | Basics | Quest.talk | live Talk Koro count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Pirate Fan Letter | 3 | Anchor Town | Collect | AcquireItem | Pirate Fan Letter | EnemyDrop | Corrupt Marine | Anchor Town | Basics | Acquire.AcquireFromEnemyDrop | inventory/quest Pirate Fan Letter 1 | STATIC_VERIFIED | IMPLEMENTED |
| Pirate Fan Letter | 4 | Anchor Town | Talk | Talk | Koro | — | Koro | Anchor Town | Basics | Quest.talk | live Talk Koro count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Setting Sail | 1 | Anchor Town | Required | LevelGate | Level | — | — | Anchor Town | A Voice in a Shell | DecisionEngine.levelFarm | live Required Level count 30 | STATIC_VERIFIED | IMPLEMENTED |
| Setting Sail | 2 | Anchor Town | Talk | Talk | Officer Graves | — | Officer Graves | Anchor Town | A Voice in a Shell | Quest.talk | live Talk Officer Graves count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Setting Sail | 3 | Anchor Town | Purchase | AcquireItem | Rowboat | ShopPurchase | Rowboat | Anchor Town | A Voice in a Shell | Shop.buy | inventory/quest Rowboat 1 | STATIC_VERIFIED | IMPLEMENTED |
| Setting Sail | 4 | Anchor Town | Spawn | Spawn | Rowboat | — | Rowboat | Anchor Town | A Voice in a Shell | Boat.spawnRowboat | live Spawn Rowboat count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Setting Sail | 5 | Anchor Town | Talk | Talk | Mayor Kiyoshi | — | Mayor Kiyoshi | Anchor Town | A Voice in a Shell | Quest.talk | live Talk Mayor Kiyoshi count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Tea Party Crashers | 1 | Anchor Town | Talk | Talk | Maeve | — | Maeve | Anchor Town | First Upgrade | Quest.talk | live Talk Maeve count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Tea Party Crashers | 2 | Anchor Town | Kill | Kill | Corrupt Marine Officer | — | Corrupt Marine Officer | Anchor Town | First Upgrade | Combat.attack | live Kill Corrupt Marine Officer count 7 | STATIC_VERIFIED | IMPLEMENTED |
| Tea Party Crashers | 2 | Anchor Town | Kill | Kill | Marine Snitch | — | Marine Snitch | Anchor Town | First Upgrade | Combat.attack | live Kill Marine Snitch count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Tea Party Crashers | 3 | Anchor Town | Talk | Talk | Maeve | — | Maeve | Anchor Town | First Upgrade | Quest.talk | live Talk Maeve count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Hoarder | 1 | Anchor Town | Required | LevelGate | Level | — | — | Anchor Town | Gearing Up | DecisionEngine.levelFarm | live Required Level count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Hoarder | 2 | Anchor Town | Talk | Talk | Troubled Civilian | — | Troubled Civilian | Anchor Town | Gearing Up | Quest.talk | live Talk Troubled Civilian count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Hoarder | 3 | Anchor Town | Kill | Kill | Afuaru, The Hoarder | — | Afuaru, The Hoarder | Anchor Town | Gearing Up | Combat.attack | live Kill Afuaru, The Hoarder count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Hoarder | 3 | Anchor Town | Collect | AcquireItem | Afuaru's Key | BossDrop | Afuaru, The Hoarder | Anchor Town | Gearing Up | Acquire.AcquireFromEnemyDrop | inventory/quest Afuaru's Key 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Hoarder | 4 | Anchor Town | Unlock | Interact | Afuaru's Gate | — | Afuaru's Gate | Anchor Town | Gearing Up | Quest.goTagged | live Unlock Afuaru's Gate count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Hoarder | 5 | Anchor Town | Loot | AcquireItem | Afuaru's Chests | Chest | Afuaru's Chests | Anchor Town | Gearing Up | Chest.openNearby | inventory/quest Afuaru's Chests 5 | STATIC_VERIFIED | IMPLEMENTED |
| The Hoarder | 6 | Anchor Town | Talk | Talk | Troubled Civilian | — | Troubled Civilian | Anchor Town | Gearing Up | Quest.talk | live Talk Troubled Civilian count 1 | STATIC_VERIFIED | IMPLEMENTED |
| A Joke Gone Too Far | 1 | Clown Town | Talk | Talk | Clowny D. Clown | — | Clowny D. Clown | Clown Town | — | Quest.talk | live Talk Clowny D. Clown count 1 | STATIC_VERIFIED | IMPLEMENTED |
| A Joke Gone Too Far | 2 | Clown Town | Kill | Kill | Clown | — | Clown | Clown Town | — | Combat.attack | live Kill Clown count 7 | STATIC_VERIFIED | IMPLEMENTED |
| A Joke Gone Too Far | 3 | Clown Town | Talk | Talk | Clowny D. Clown | — | Clowny D. Clown | Clown Town | — | Quest.talk | live Talk Clowny D. Clown count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Butcher's Business | 1 | Clown Town | Required | LevelGate | Level | — | — | Clown Town | Stephon's Tormentor | DecisionEngine.levelFarm | live Required Level count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Butcher's Business | 2 | Clown Town | Talk | Talk | Billy B. | — | Billy B. | Clown Town | Stephon's Tormentor | Quest.talk | live Talk Billy B. count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Butcher's Business | 3 | Clown Town | Kill | Kill | Killer Clown | — | Killer Clown | Clown Town | Stephon's Tormentor | Combat.attack | live Kill Killer Clown count 7 | STATIC_VERIFIED | IMPLEMENTED |
| Butcher's Business | 4 | Clown Town | Talk | Talk | Billy B. | — | Billy B. | Clown Town | Stephon's Tormentor | Quest.talk | live Talk Billy B. count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Circus Suppliers | 1 | Clown Town | Required | LevelGate | Level | — | — | Clown Town | Butcher's Business | DecisionEngine.levelFarm | live Required Level count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Circus Suppliers | 2 | Clown Town | Talk | Talk | Mayor Kiyoshi | — | Mayor Kiyoshi | Clown Town | Butcher's Business | Quest.talk | live Talk Mayor Kiyoshi count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Circus Suppliers | 3 | Clown Town | Kill | Kill | Circus Supplier | — | Circus Supplier | Clown Town | Butcher's Business | Combat.attack | live Kill Circus Supplier count 2 | STATIC_VERIFIED | IMPLEMENTED |
| Circus Suppliers | 4 | Clown Town | Talk | Talk | Mayor Kiyoshi | — | Mayor Kiyoshi | Clown Town | Butcher's Business | Quest.talk | live Talk Mayor Kiyoshi count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Clown Captives | 1 | Clown Town | Talk | Talk | Mayor Kiyoshi | — | Mayor Kiyoshi | Clown Town | Circus Suppliers | Quest.talk | live Talk Mayor Kiyoshi count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Clown Captives | 2 | Clown Town | Free | Interact | Child Captive | — | Child Captive | Clown Town | Circus Suppliers | Quest.goTagged | live Free Child Captive count 2 | STATIC_VERIFIED | IMPLEMENTED |
| Clown Captives | 2 | Clown Town | Free | Interact | Adult Captive | — | Adult Captive | Clown Town | Circus Suppliers | Quest.goTagged | live Free Adult Captive count 4 | STATIC_VERIFIED | IMPLEMENTED |
| Clown Captives | 3 | Clown Town | Talk | Talk | Mayor Kiyoshi | — | Mayor Kiyoshi | Clown Town | Circus Suppliers | Quest.talk | live Talk Mayor Kiyoshi count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Clown Town's Militia | 1 | Clown Town | Talk | Talk | Mayor Kiyoshi [2] | — | Mayor Kiyoshi [2] | Clown Town | Mayor's Stache | Quest.talk | live Talk Mayor Kiyoshi [2] count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Clown Town's Militia | 2 | Clown Town | CollectLocalItem | AcquireItem | Sturdy Stick | WorldPickup | Sturdy Stick | Clown Town | Mayor's Stache | Acquire.WorldPickup | inventory/quest Sturdy Stick 1 | STATIC_VERIFIED | IMPLEMENTED |
| Clown Town's Militia | 2 | Clown Town | CollectLocalItem | AcquireItem | Tomato Crate | WorldPickup | Tomato Crate | Clown Town | Mayor's Stache | Acquire.WorldPickup | inventory/quest Tomato Crate 1 | STATIC_VERIFIED | IMPLEMENTED |
| Clown Town's Militia | 2 | Clown Town | CollectLocalItem | AcquireItem | Fist Wraps | WorldPickup | Fist Wraps | Clown Town | Mayor's Stache | Acquire.WorldPickup | inventory/quest Fist Wraps 1 | STATIC_VERIFIED | IMPLEMENTED |
| Clown Town's Militia | 3 | Clown Town | Talk | Talk | Clown Town Angry Civilian 1 | — | Clown Town Angry Civilian 1 | Clown Town | Mayor's Stache | Quest.talk | live Talk Clown Town Angry Civilian 1 count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Clown Town's Militia | 3 | Clown Town | Talk | Talk | Clown Town Angry Civilian 2 | — | Clown Town Angry Civilian 2 | Clown Town | Mayor's Stache | Quest.talk | live Talk Clown Town Angry Civilian 2 count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Clown Town's Militia | 3 | Clown Town | Talk | Talk | Clown Town Angry Civilian 3 | — | Clown Town Angry Civilian 3 | Clown Town | Mayor's Stache | Quest.talk | live Talk Clown Town Angry Civilian 3 count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Escort The Mayor | 1 | Clown Town | Required | LevelGate | Level | — | — | Clown Town | Revenge of the Nibblebottom | DecisionEngine.levelFarm | live Required Level count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Escort The Mayor | 2 | Clown Town | Talk | Talk | Mayor Kiyoshi | — | Mayor Kiyoshi | Clown Town | Revenge of the Nibblebottom | Quest.talk | live Talk Mayor Kiyoshi count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Escort The Mayor | 3 | Clown Town | Escort | Escort | Mayor Kiyoshi | — | Mayor Kiyoshi | Clown Town | Revenge of the Nibblebottom | Quest.escort | live Escort Mayor Kiyoshi count 1 | STATIC_VERIFIED | RUNTIME_REQUIRED |
| Escort The Mayor | 4 | Clown Town | Talk | Talk | Mayor Kiyoshi [2] | — | Mayor Kiyoshi [2] | Clown Town | Revenge of the Nibblebottom | Quest.talk | live Talk Mayor Kiyoshi [2] count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Journey to Maple Village | 1 | Clown Town | Talk | Talk | Mayor Kiyoshi | — | Mayor Kiyoshi | Clown Town | The Ringmaster | Quest.talk | live Talk Mayor Kiyoshi count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Journey to Maple Village | 2 | Clown Town | Required | LevelGate | Level | — | — | Clown Town | The Ringmaster | DecisionEngine.levelFarm | live Required Level count 70 | STATIC_VERIFIED | IMPLEMENTED |
| Journey to Maple Village | 3 | Clown Town | Reach Maple Village | Travel | — | — | Maple Village | Clown Town | The Ringmaster | Travel.goIsland | live Reach Maple Village - count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Lion's Victim | 1 | Clown Town | Required | LevelGate | Level | — | — | Clown Town | Sabotage The Cannon | DecisionEngine.levelFarm | live Required Level count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Lion's Victim | 2 | Clown Town | Talk | Talk | Stephon | — | Stephon | Clown Town | Sabotage The Cannon | Quest.talk | live Talk Stephon count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Lion's Victim | 3 | Clown Town | Kill | Kill | Circus Lion | — | Circus Lion | Clown Town | Sabotage The Cannon | Combat.attack | live Kill Circus Lion count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Lion's Victim | 3 | Clown Town | Kill | Kill | Beast Tamer | — | Beast Tamer | Clown Town | Sabotage The Cannon | Combat.attack | live Kill Beast Tamer count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Lion's Victim | 4 | Clown Town | Talk | Talk | Stephon | — | Stephon | Clown Town | Sabotage The Cannon | Quest.talk | live Talk Stephon count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Mayor's Stache | 1 | Clown Town | Talk | Talk | Mayor Kiyoshi [2] | — | Mayor Kiyoshi [2] | Clown Town | Escort The Mayor | Quest.talk | live Talk Mayor Kiyoshi [2] count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Mayor's Stache | 2 | Clown Town | CollectLocalItem | AcquireItem | Mayor's Mustache | WorldPickup | Mayor's Mustache | Clown Town | Escort The Mayor | Acquire.WorldPickup | inventory/quest Mayor's Mustache 1 | STATIC_VERIFIED | IMPLEMENTED |
| Mayor's Stache | 3 | Clown Town | Talk | Talk | Mayor Kiyoshi [2] | — | Mayor Kiyoshi [2] | Clown Town | Escort The Mayor | Quest.talk | live Talk Mayor Kiyoshi [2] count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Revenge of the Nibblebottom | 1 | Clown Town | Talk | Talk | Johnny Nibblebottom | — | Johnny Nibblebottom | Clown Town | Clown Captives | Quest.talk | live Talk Johnny Nibblebottom count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Revenge of the Nibblebottom | 2 | Clown Town | Kill | Kill | Clown Officer | — | Clown Officer | Clown Town | Clown Captives | Combat.attack | live Kill Clown Officer count 5 | STATIC_VERIFIED | IMPLEMENTED |
| Revenge of the Nibblebottom | 2 | Clown Town | Destroy | Kill | Air Balloon | — | Air Balloon | Clown Town | Clown Captives | Combat.attack | live Destroy Air Balloon count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Revenge of the Nibblebottom | 3 | Clown Town | Talk | Talk | Johnny Nibblebottom | — | Johnny Nibblebottom | Clown Town | Clown Captives | Quest.talk | live Talk Johnny Nibblebottom count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Sabotage The Cannon | 1 | Clown Town | Required | LevelGate | Level | — | — | Clown Town | A Joke Gone Too Far | DecisionEngine.levelFarm | live Required Level count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Sabotage The Cannon | 2 | Clown Town | Talk | Talk | Clowny D. Clown | — | Clowny D. Clown | Clown Town | A Joke Gone Too Far | Quest.talk | live Talk Clowny D. Clown count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Sabotage The Cannon | 3 | Clown Town | Destroy | Kill | Muggy Cannon | — | Muggy Cannon | Clown Town | A Joke Gone Too Far | Combat.attack | live Destroy Muggy Cannon count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Sabotage The Cannon | 4 | Clown Town | Talk | Talk | Clowny D. Clown | — | Clowny D. Clown | Clown Town | A Joke Gone Too Far | Quest.talk | live Talk Clowny D. Clown count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Stephon's Tormentor | 1 | Clown Town | Required | LevelGate | Level | — | — | Clown Town | Lion's Victim | DecisionEngine.levelFarm | live Required Level count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Stephon's Tormentor | 2 | Clown Town | Talk | Talk | Stephon | — | Stephon | Clown Town | Lion's Victim | Quest.talk | live Talk Stephon count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Stephon's Tormentor | 3 | Clown Town | Kill | Kill | "Barrel Clown" Binki | — | "Barrel Clown" Binki | Clown Town | Lion's Victim | Combat.attack | live Kill "Barrel Clown" Binki count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Stephon's Tormentor | 4 | Clown Town | Talk | Talk | Stephon | — | Stephon | Clown Town | Lion's Victim | Quest.talk | live Talk Stephon count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Ringmaster | 1 | Clown Town | Required | LevelGate | Level | — | — | Clown Town | Clown Town's Militia | DecisionEngine.levelFarm | live Required Level count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Ringmaster | 2 | Clown Town | Talk | Talk | Mayor Kiyoshi [2] | — | Mayor Kiyoshi [2] | Clown Town | Clown Town's Militia | Quest.talk | live Talk Mayor Kiyoshi [2] count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Ringmaster | 3 | Clown Town | Kill | Kill | Choppy The Clown | — | Choppy The Clown | Clown Town | Clown Town's Militia | Combat.attack | live Kill Choppy The Clown count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Ringmaster | 4 | Clown Town | Talk | Talk | Mayor Kiyoshi [2] | — | Mayor Kiyoshi [2] | Clown Town | Clown Town's Militia | Quest.talk | live Talk Mayor Kiyoshi [2] count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Destroy the Signalers | 1 | Maple Village | Destroy | Kill | North Camp Signal Fire | — | North Camp Signal Fire | Maple Village | Stocked for a Siege | Combat.attack | live Destroy North Camp Signal Fire count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Destroy the Signalers | 1 | Maple Village | Destroy | Kill | South Camp Signal Fire | — | South Camp Signal Fire | Maple Village | Stocked for a Siege | Combat.attack | live Destroy South Camp Signal Fire count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Destroy the Signalers | 1 | Maple Village | Destroy | Kill | Overlook Signal Fire | — | Overlook Signal Fire | Maple Village | Stocked for a Siege | Combat.attack | live Destroy Overlook Signal Fire count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Destroy the Signalers | 2 | Maple Village | Talk | Talk | Captain Esopo | — | Captain Esopo | Maple Village | Stocked for a Siege | Quest.talk | live Talk Captain Esopo count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Expose the Butler | 1 | Maple Village | Investigate The Garden | Interact | — | — | Mansion Garden Marker | Maple Village | Missing Servants | Quest.goTagged | live Investigate The Garden - count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Expose the Butler | 2 | Maple Village | Talk | Talk | Frightened Servant | — | Frightened Servant | Maple Village | Missing Servants | Quest.talk | live Talk Frightened Servant count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Expose the Butler | 2 | Maple Village | Kill | Kill | Scratch | — | Scratch | Maple Village | Missing Servants | Combat.attack | live Kill Scratch count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Expose the Butler | 2 | Maple Village | Kill | Kill | Grab | — | Grab | Maple Village | Missing Servants | Combat.attack | live Kill Grab count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Expose the Butler | 3 | Maple Village | Talk | Talk | Frightened Servant | — | Frightened Servant | Maple Village | Missing Servants | Quest.talk | live Talk Frightened Servant count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Expose the Butler | 4 | Maple Village | Talk | Talk | Captain Esopo | — | Captain Esopo | Maple Village | Missing Servants | Quest.talk | live Talk Captain Esopo count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Missing Servants | 1 | Maple Village | Talk | Talk | Kuro | — | Kuro | Maple Village | The Beast of Maple Village | Quest.talk | live Talk Kuro count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Missing Servants | 2 | Maple Village | Investigate The Garden | Interact | — | — | Mansion Garden Marker | Maple Village | The Beast of Maple Village | Quest.goTagged | live Investigate The Garden - count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Missing Servants | 2 | Maple Village | Investigate The Fountain | Interact | — | — | Mansion Fountain Marker | Maple Village | The Beast of Maple Village | Quest.goTagged | live Investigate The Fountain - count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Missing Servants | 3 | Maple Village | CollectLocalItem | AcquireItem | Servant's Journal | WorldPickup | Servant's Journal Spawn | Maple Village | The Beast of Maple Village | Acquire.WorldPickup | inventory/quest Servant's Journal 1 | STATIC_VERIFIED | IMPLEMENTED |
| Missing Servants | 4 | Maple Village | Talk | Talk | Captain Esopo | — | Captain Esopo | Maple Village | The Beast of Maple Village | Quest.talk | live Talk Captain Esopo count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Pirate Instructions | 1 | Maple Village | Collect | AcquireItem | Pirate Instructions | EnemyDrop | Black Noir Officer | Maple Village | Something Isn't Right | Acquire.AcquireFromEnemyDrop | inventory/quest Pirate Instructions 1 | STATIC_VERIFIED | IMPLEMENTED |
| Pirate Instructions | 2 | Maple Village | Talk | Talk | Captain Esopo | — | Captain Esopo | Maple Village | Something Isn't Right | Quest.talk | live Talk Captain Esopo count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Proof of Pirates | 1 | Maple Village | Kill | Kill | Black Noir Pirate | — | Black Noir Pirate | Maple Village | The Island's Protector | Combat.attack | live Kill Black Noir Pirate count 7 | STATIC_VERIFIED | IMPLEMENTED |
| Proof of Pirates | 2 | Maple Village | Deliver Object | DeliverObject | Stolen Goods | — | Stolen Goods | Maple Village | The Island's Protector | Quest.goTagged | live Deliver Object Stolen Goods count 2 | STATIC_VERIFIED | IMPLEMENTED |
| Proof of Pirates | 3 | Maple Village | Talk | Talk | Captain Esopo | — | Captain Esopo | Maple Village | The Island's Protector | Quest.talk | live Talk Captain Esopo count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Raid Preparations | 1 | Maple Village | Talk | Talk | Remy | — | Remy | Maple Village | Expose the Butler | Quest.talk | live Talk Remy count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Raid Preparations | 1 | Maple Village | Talk | Talk | Farmer Joe | — | Farmer Joe | Maple Village | Expose the Butler | Quest.talk | live Talk Farmer Joe count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Raid Preparations | 1 | Maple Village | Talk | Talk | Pip | — | Pip | Maple Village | Expose the Butler | Quest.talk | live Talk Pip count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Raid Preparations | 1 | Maple Village | Talk | Talk | Lady Maia | — | Lady Maia | Maple Village | Expose the Butler | Quest.talk | live Talk Lady Maia count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Raid Preparations | 2 | Maple Village | Collect | AcquireItem | Lead Ore | Mining | Lead Ore | Maple Village | Expose the Butler | LifeSkills.mineToward | inventory/quest Lead Ore 6 | STATIC_VERIFIED | IMPLEMENTED |
| Raid Preparations | 3 | Maple Village | Talk | Talk | Captain Esopo | — | Captain Esopo | Maple Village | Expose the Butler | Quest.talk | live Talk Captain Esopo count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Something Isn't Right | 1 | Maple Village | Talk | Talk | Farmer Joe | — | Farmer Joe | Maple Village | Proof of Pirates | Quest.talk | live Talk Farmer Joe count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Something Isn't Right | 1 | Maple Village | Talk | Talk | Tara | — | Tara | Maple Village | Proof of Pirates | Quest.talk | live Talk Tara count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Something Isn't Right | 1 | Maple Village | Talk | Talk | Martha | — | Martha | Maple Village | Proof of Pirates | Quest.talk | live Talk Martha count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Something Isn't Right | 2 | Maple Village | Investigate The Footsteps (1) | Interact | — | — | Campsite Footsteps Marker | Maple Village | Proof of Pirates | Quest.goTagged | live Investigate The Footsteps (1) - count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Something Isn't Right | 3 | Maple Village | Destroy | Kill | Supply Crate | — | Supply Crate | Maple Village | Proof of Pirates | Combat.attack | live Destroy Supply Crate count 2 | STATIC_VERIFIED | IMPLEMENTED |
| Something Isn't Right | 3 | Maple Village | Kill | Kill | Black Noir Pirate | — | Black Noir Pirate | Maple Village | Proof of Pirates | Combat.attack | live Kill Black Noir Pirate count 2 | STATIC_VERIFIED | IMPLEMENTED |
| Something Isn't Right | 4 | Maple Village | Investigate The Footsteps (2) | Interact | — | — | Campsite Footsteps Marker | Maple Village | Proof of Pirates | Quest.goTagged | live Investigate The Footsteps (2) - count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Something Isn't Right | 5 | Maple Village | Destroy | Kill | Supply Crate | — | Supply Crate | Maple Village | Proof of Pirates | Combat.attack | live Destroy Supply Crate count 2 | STATIC_VERIFIED | IMPLEMENTED |
| Something Isn't Right | 5 | Maple Village | Kill | Kill | Black Noir Pirate | — | Black Noir Pirate | Maple Village | Proof of Pirates | Combat.attack | live Kill Black Noir Pirate count 2 | STATIC_VERIFIED | IMPLEMENTED |
| Something Isn't Right | 6 | Maple Village | Talk | Talk | Captain Esopo | — | Captain Esopo | Maple Village | Proof of Pirates | Quest.talk | live Talk Captain Esopo count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Stocked for a Siege | 1 | Maple Village | Donate | Deliver | Dish | — | Dish | Maple Village | Raid Preparations | Quest.talk | live Donate Dish count 6 | STATIC_VERIFIED | IMPLEMENTED |
| Stocked for a Siege | 2 | Maple Village | Talk | Talk | Captain Esopo | — | Captain Esopo | Maple Village | Raid Preparations | Quest.talk | live Talk Captain Esopo count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Beast of Maple Village | 1 | Maple Village | Investigate The Wreckage | Interact | — | — | Beast Wreckage Marker | Maple Village | The Wandering Hypnotist | Quest.goTagged | live Investigate The Wreckage - count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Beast of Maple Village | 2 | Maple Village | Investigate The Beast's Den | Interact | — | — | Beast Den Marker | Maple Village | The Wandering Hypnotist | Quest.goTagged | live Investigate The Beast's Den - count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Beast of Maple Village | 3 | Maple Village | Kill | Kill | The Beast? | — | The Beast? | Maple Village | The Wandering Hypnotist | Combat.attack | live Kill The Beast? count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Beast of Maple Village | 3 | Maple Village | Talk | Talk | Barry | — | Barry | Maple Village | The Wandering Hypnotist | Quest.talk | live Talk Barry count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Beast of Maple Village | 4 | Maple Village | Talk | Talk | Captain Esopo | — | Captain Esopo | Maple Village | The Wandering Hypnotist | Quest.talk | live Talk Captain Esopo count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Black Noir Raid | 1 | Maple Village | Defend | Unresolved | Black Noir Raid | — | Black Noir Raid | Maple Village | Destroy the Signalers | UNKNOWN | live Defend Black Noir Raid count 1 | UNKNOWN | UNRESOLVED |
| The Black Noir Raid | 2 | Maple Village | Talk | Talk | Lady Maia | — | Lady Maia | Maple Village | Destroy the Signalers | Quest.talk | live Talk Lady Maia count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Island's Protector | 1 | Maple Village | Kill | Kill | Captain Esopo | — | Captain Esopo | Maple Village | — | Combat.attack | live Kill Captain Esopo count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Island's Protector | 2 | Maple Village | Talk | Talk | Captain Esopo | — | Captain Esopo | Maple Village | — | Quest.talk | live Talk Captain Esopo count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Wandering Hypnotist | 1 | Maple Village | Wake | Interact | Clucking Villager | — | Clucking Villager | Maple Village | Pirate Instructions | Quest.goTagged | live Wake Clucking Villager count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Wandering Hypnotist | 1 | Maple Village | Check On | Interact | Sleeping Villager | — | Sleeping Villager | Maple Village | Pirate Instructions | Quest.goTagged | live Check On Sleeping Villager count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Wandering Hypnotist | 1 | Maple Village | CollectLocalItem | AcquireItem | Bucket of Water | WorldPickup | Clucking Villager | Maple Village | Pirate Instructions | Acquire.WorldPickup | inventory/quest Bucket of Water 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Wandering Hypnotist | 1 | Maple Village | Wake | Interact | Sleeping Villager | — | Sleeping Villager | Maple Village | Pirate Instructions | Quest.goTagged | live Wake Sleeping Villager count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Wandering Hypnotist | 2 | Maple Village | Kill | Kill | "Hypnotist" Mango | — | "Hypnotist" Mango | Maple Village | Pirate Instructions | Combat.attack | live Kill "Hypnotist" Mango count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Wandering Hypnotist | 3 | Maple Village | Talk | Talk | Captain Esopo | — | Captain Esopo | Maple Village | Pirate Instructions | Quest.talk | live Talk Captain Esopo count 1 | STATIC_VERIFIED | IMPLEMENTED |
| A Dish Best Served Cold | 1 | Anchor Town | Convince | Unresolved | Blonde Goblin | — | Blonde Goblin | Anchor Town | Down on His Luck | UNKNOWN | live Convince Blonde Goblin count 1 | UNKNOWN | UNRESOLVED |
| A Dish Best Served Cold | 2 | Anchor Town | Talk | Talk | Penniless Pete | — | Penniless Pete | Anchor Town | Down on His Luck | Quest.talk | live Talk Penniless Pete count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Apple Pot Pie | 1 | Anchor Town | Talk | Talk | Granny Todo | — | Granny Todo | Anchor Town | — | Quest.talk | live Talk Granny Todo count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Apple Pot Pie | 2 | Anchor Town | Collect | AcquireItem | Apple | ShopPurchase | Apple | Anchor Town | — | Shop.buy | inventory/quest Apple 5 | STATIC_VERIFIED | IMPLEMENTED |
| Apple Pot Pie | 3 | Anchor Town | Collect | AcquireItem | Apple Pot Pie | Farming | Apple Pot Pie | Anchor Town | — | LifeSkills.farmToward | inventory/quest Apple Pot Pie 1 | STATIC_VERIFIED | IMPLEMENTED |
| Apple Pot Pie | 4 | Anchor Town | Deliver Jay Vonera | Other | Apple Pot Pie | — | Apple Pot Pie | Anchor Town | — | UNKNOWN | live Deliver Jay Vonera Apple Pot Pie count 1 | UNKNOWN | UNRESOLVED |
| Collections | 1 | Anchor Town | Kill | Kill | Corrupt Marine | — | Corrupt Marine | Anchor Town | Paper Route | Combat.attack | live Kill Corrupt Marine count 4 | STATIC_VERIFIED | IMPLEMENTED |
| Collections | 2 | Anchor Town | Deliver Object | DeliverObject | Trust Strongbox | — | Trust Strongbox | Anchor Town | Paper Route | Quest.goTagged | live Deliver Object Trust Strongbox count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Collections | 3 | Anchor Town | Talk | Talk | Nagi | — | Nagi | Anchor Town | Paper Route | Quest.talk | live Talk Nagi count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Courier's Test | 1 | Anchor Town | CollectLocalItem | AcquireItem | Sealed Satchel | WorldPickup | Trust Dock Delivery | Anchor Town | Collections | Acquire.WorldPickup | inventory/quest Sealed Satchel 1 | STATIC_VERIFIED | IMPLEMENTED |
| Courier's Test | 2 | Anchor Town | Talk | Talk | Nagi | — | Nagi | Anchor Town | Collections | Quest.talk | live Talk Nagi count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Down on His Luck | 1 | Anchor Town | Donate | Deliver | Gold | — | Gold | Anchor Town | — | Quest.talk | live Donate Gold count 100 | STATIC_VERIFIED | IMPLEMENTED |
| Down on His Luck | 2 | Anchor Town | Talk | Talk | Penniless Pete | — | Penniless Pete | Anchor Town | — | Quest.talk | live Talk Penniless Pete count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Dwindling Iron Supply | 1 | Anchor Town | Collect | AcquireItem | Iron Ore | Mining | Iron Ore | Anchor Town | — | LifeSkills.mineToward | inventory/quest Iron Ore 3 | STATIC_VERIFIED | IMPLEMENTED |
| Dwindling Iron Supply | 2 | Anchor Town | Talk | Talk | Miner Song Kim Wu | — | Miner Song Kim Wu | Anchor Town | — | Quest.talk | live Talk Miner Song Kim Wu count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Feed The Hungry | 1 | Anchor Town | Collect | AcquireItem | Apple | ShopPurchase | Apple | Anchor Town | — | Shop.buy | inventory/quest Apple 1 | STATIC_VERIFIED | IMPLEMENTED |
| Feed The Hungry | 2 | Anchor Town | Talk | Talk | Loki | — | Loki | Anchor Town | — | Quest.talk | live Talk Loki count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Feed The Hungry | 3 | Anchor Town | Collect | AcquireItem | Carrot | ShopPurchase | Carrot | Anchor Town | — | Shop.buy | inventory/quest Carrot 1 | STATIC_VERIFIED | IMPLEMENTED |
| Feed The Hungry | 4 | Anchor Town | Talk | Talk | Loki | — | Loki | Anchor Town | — | Quest.talk | live Talk Loki count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Feed The Hungry | 5 | Anchor Town | Collect | AcquireItem | Lemon | ShopPurchase | Lemon | Anchor Town | — | Shop.buy | inventory/quest Lemon 1 | STATIC_VERIFIED | IMPLEMENTED |
| Feed The Hungry | 6 | Anchor Town | Talk | Talk | Loki | — | Loki | Anchor Town | — | Quest.talk | live Talk Loki count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Feed The Hungry | 7 | Anchor Town | Collect | AcquireItem | Banana | ShopPurchase | Banana | Anchor Town | — | Shop.buy | inventory/quest Banana 1 | STATIC_VERIFIED | IMPLEMENTED |
| Feed The Hungry | 8 | Anchor Town | Talk | Talk | Loki | — | Loki | Anchor Town | — | Quest.talk | live Talk Loki count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Finders Keepers | 1 | Anchor Town | Dig | Unresolved | up Wade's Belongings | — | up Wade's Belongings | Anchor Town | — | UNKNOWN | live Dig up Wade's Belongings count 5 | UNKNOWN | UNRESOLVED |
| Finders Keepers | 1 | Anchor Town | Collect | AcquireItem | Wade's Belongings | EnemyDrop | Treasure Hunter | Anchor Town | — | Acquire.AcquireFromEnemyDrop | inventory/quest Wade's Belongings 1 | STATIC_VERIFIED | IMPLEMENTED |
| Finders Keepers | 2 | Anchor Town | Kill | Kill | Treasure Hunter | — | Treasure Hunter | Anchor Town | — | Combat.attack | live Kill Treasure Hunter count 4 | STATIC_VERIFIED | IMPLEMENTED |
| Finders Keepers | 3 | Anchor Town | Talk | Talk | Wade | — | Wade | Anchor Town | — | Quest.talk | live Talk Wade count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Finding Denver | 1 | Anchor Town | CollectLocalItem | AcquireItem | Denver The Dog | WorldPickup | Denver The Dog | Anchor Town | Overdue Payment | Acquire.WorldPickup | inventory/quest Denver The Dog 1 | STATIC_VERIFIED | IMPLEMENTED |
| Finding Denver | 2 | Anchor Town | Talk | Talk | Jokic | — | Jokic | Anchor Town | Overdue Payment | Quest.talk | live Talk Jokic count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Fisherman Jack's Challenge | 1 | Anchor Town | Fish | AcquireItem | Carp | Fishing | Carp | Anchor Town | — | LifeSkills.fishToward | inventory/quest Carp 1 | STATIC_VERIFIED | IMPLEMENTED |
| Fisherman Jack's Challenge | 2 | Anchor Town | Talk | Talk | Fisherman Jack | — | Fisherman Jack | Anchor Town | — | Quest.talk | live Talk Fisherman Jack count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Guest List | 1 | Anchor Town | Talk | Talk | Granny Todo | — | Granny Todo | Anchor Town | Tea Party Crashers | Quest.talk | live Talk Granny Todo count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Guest List | 1 | Anchor Town | Talk | Talk | Terry | — | Terry | Anchor Town | Tea Party Crashers | Quest.talk | live Talk Terry count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Guest List | 1 | Anchor Town | Talk | Talk | Aria | — | Aria | Anchor Town | Tea Party Crashers | Quest.talk | live Talk Aria count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Guest List | 2 | Anchor Town | Talk | Talk | Maeve | — | Maeve | Anchor Town | Tea Party Crashers | Quest.talk | live Talk Maeve count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Guest List | 3 | Anchor Town | Kill | Kill | Party Crasher | — | Party Crasher | Anchor Town | Tea Party Crashers | Combat.attack | live Kill Party Crasher count 2 | STATIC_VERIFIED | IMPLEMENTED |
| Guest List | 4 | Anchor Town | Talk | Talk | Maeve | — | Maeve | Anchor Town | Tea Party Crashers | Quest.talk | live Talk Maeve count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Handle Recipe | 1 | Anchor Town | Collect | AcquireItem | Stick | WorldPickup | Stick | Anchor Town | — | Acquire.WorldPickup | inventory/quest Stick 2 | STATIC_VERIFIED | IMPLEMENTED |
| Handle Recipe | 1 | Anchor Town | Collect | AcquireItem | Cloth | WorldPickup | Cloth | Anchor Town | — | Acquire.WorldPickup | inventory/quest Cloth 1 | STATIC_VERIFIED | IMPLEMENTED |
| Handle Recipe | 2 | Anchor Town | Talk | Talk | Craftsman Henry | — | Craftsman Henry | Anchor Town | — | Quest.talk | live Talk Craftsman Henry count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Keeper of the Flame | 1 | Anchor Town | CollectLocalItem | AcquireItem | Lamp Oil | WorldPickup | Lamp Oil Spawn | Anchor Town | — | Acquire.WorldPickup | inventory/quest Lamp Oil 1 | STATIC_VERIFIED | IMPLEMENTED |
| Keeper of the Flame | 2 | Anchor Town | Talk | Talk | Keeper Otis | — | Keeper Otis | Anchor Town | — | Quest.talk | live Talk Keeper Otis count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Message for the Strongbox | 1 | Anchor Town | Talk | Talk | Captain Arashi | — | Captain Arashi | Anchor Town | — | Quest.talk | live Talk Captain Arashi count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Message for the Strongbox | 2 | Anchor Town | Talk | Talk | Tomoe | — | Tomoe | Anchor Town | — | Quest.talk | live Talk Tomoe count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Message for the Strongbox | 3 | Anchor Town | Talk | Talk | Captain Jones | — | Captain Jones | Anchor Town | — | Quest.talk | live Talk Captain Jones count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Mina's Request | 1 | Anchor Town | Enter Zone | Other | Anchor Town Fishing Shop | — | Anchor Town Fishing Shop | Anchor Town | — | UNKNOWN | live Enter Zone Anchor Town Fishing Shop count 1 | UNKNOWN | UNRESOLVED |
| Mina's Request | 1 | Anchor Town | Enter Zone | Other | Anchor Town Food Foo | — | Anchor Town Food Foo | Anchor Town | — | UNKNOWN | live Enter Zone Anchor Town Food Foo count 1 | UNKNOWN | UNRESOLVED |
| Mina's Request | 1 | Anchor Town | Enter Zone | Other | Anchor Town Plaza | — | Anchor Town Plaza | Anchor Town | — | UNKNOWN | live Enter Zone Anchor Town Plaza count 1 | UNKNOWN | UNRESOLVED |
| Mina's Request | 2 | Anchor Town | Escort | Escort | Mina | — | Mina | Anchor Town | — | Quest.escort | live Escort Mina count 1 | STATIC_VERIFIED | RUNTIME_REQUIRED |
| Miners Bracelet | 1 | Anchor Town | CollectLocalItem | AcquireItem | Silver Miners Bracelet | WorldPickup | Silver Miners Bracelet | Anchor Town | — | Acquire.WorldPickup | inventory/quest Silver Miners Bracelet 1 | STATIC_VERIFIED | IMPLEMENTED |
| Miners Bracelet | 2 | Anchor Town | Talk | Talk | Miner Song Jil Wu | — | Miner Song Jil Wu | Anchor Town | — | Quest.talk | live Talk Miner Song Jil Wu count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Miners Stone Ring | 1 | Anchor Town | Craft | AcquireItem | Stone Ring | Crafting | Stone Ring | Anchor Town | — | UNKNOWN | inventory/quest Stone Ring 1 | UNKNOWN | UNRESOLVED |
| Overdue Payment | 1 | Anchor Town | Collect | AcquireItem | Pirate's Ruby | WorldPickup | Jokic | Anchor Town | — | Acquire.WorldPickup | inventory/quest Pirate's Ruby 1 | STATIC_VERIFIED | IMPLEMENTED |
| Overdue Payment | 2 | Anchor Town | Talk | Talk | Smuggler | — | Smuggler | Anchor Town | — | Quest.talk | live Talk Smuggler count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Paper Route | 1 | Anchor Town | Talk | Talk | Nessa | — | Nessa | Anchor Town | A Voice in a Shell | Quest.talk | live Talk Nessa count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Paper Route | 2 | Anchor Town | Talk | Talk | Billy B. | — | Billy B. | Anchor Town | A Voice in a Shell | Quest.talk | live Talk Billy B. count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Paper Route | 3 | Anchor Town | Talk | Talk | Farmer Joe | — | Farmer Joe | Anchor Town | A Voice in a Shell | Quest.talk | live Talk Farmer Joe count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Paper Route | 4 | Anchor Town | Talk | Talk | Nagi | — | Nagi | Anchor Town | A Voice in a Shell | Quest.talk | live Talk Nagi count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Sushi's Training 1 | 1 | Anchor Town | Hit | Kill | Training Dummy | — | Training Dummy | Anchor Town | — | Combat.attack | live Hit Training Dummy count 100 | STATIC_VERIFIED | IMPLEMENTED |
| Sushi's Training 1 | 2 | Anchor Town | Talk | Talk | Sushi | — | Sushi | Anchor Town | — | Quest.talk | live Talk Sushi count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Sushi's Training 2 | 1 | Anchor Town | Hit | Kill | Training Dummy | — | Training Dummy | Anchor Town | Sushi's Training 1 | Combat.attack | live Hit Training Dummy count 1000 | STATIC_VERIFIED | IMPLEMENTED |
| Sushi's Training 2 | 2 | Anchor Town | Talk | Talk | Sushi | — | Sushi | Anchor Town | Sushi's Training 1 | Quest.talk | live Talk Sushi count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Sushi's Training 3 | 1 | Anchor Town | Hit | Kill | Training Dummy | — | Training Dummy | Anchor Town | Sushi's Training 2 | Combat.attack | live Hit Training Dummy count 10000 | STATIC_VERIFIED | IMPLEMENTED |
| Sushi's Training 3 | 2 | Anchor Town | Talk | Talk | Sushi | — | Sushi | Anchor Town | Sushi's Training 2 | Quest.talk | live Talk Sushi count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Sushi's Training 4 | 1 | Anchor Town | Hit | Kill | Training Dummy | — | Training Dummy | Anchor Town | Sushi's Training 3 | Combat.attack | live Hit Training Dummy count 100000 | STATIC_VERIFIED | IMPLEMENTED |
| Sushi's Training 4 | 2 | Anchor Town | Talk | Talk | Sushi | — | Sushi | Anchor Town | Sushi's Training 3 | Quest.talk | live Talk Sushi count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Sushi's Training 5 | 1 | Anchor Town | Hit | Kill | Training Dummy | — | Training Dummy | Anchor Town | Sushi's Training 4 | Combat.attack | live Hit Training Dummy count 1000000 | STATIC_VERIFIED | IMPLEMENTED |
| Sushi's Training 5 | 2 | Anchor Town | Talk | Talk | Sushi | — | Sushi | Anchor Town | Sushi's Training 4 | Quest.talk | live Talk Sushi count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Sushi's Training 6 | 1 | Anchor Town | Hit | Kill | Training Dummy | — | Training Dummy | Anchor Town | Sushi's Training 5 | Combat.attack | live Hit Training Dummy count 10000000 | STATIC_VERIFIED | IMPLEMENTED |
| Sushi's Training 6 | 2 | Anchor Town | Talk | Talk | Sushi | — | Sushi | Anchor Town | Sushi's Training 5 | Quest.talk | live Talk Sushi count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Sushi's Training 7 | 1 | Anchor Town | Hit | Kill | Training Dummy | — | Training Dummy | Anchor Town | Sushi's Training 6 | Combat.attack | live Hit Training Dummy count 100000000 | STATIC_VERIFIED | IMPLEMENTED |
| Sushi's Training 7 | 2 | Anchor Town | Talk | Talk | Sushi | — | Sushi | Anchor Town | Sushi's Training 6 | Quest.talk | live Talk Sushi count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Sushi's Training 8 | 1 | Anchor Town | Hit | Kill | Training Dummy | — | Training Dummy | Anchor Town | Sushi's Training 7 | Combat.attack | live Hit Training Dummy count 1000000000 | STATIC_VERIFIED | IMPLEMENTED |
| Sushi's Training 8 | 2 | Anchor Town | Talk | Talk | Sushi | — | Sushi | Anchor Town | Sushi's Training 7 | Quest.talk | live Talk Sushi count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Sushi's Training 9 | 1 | Anchor Town | Hit | Kill | Training Dummy | — | Training Dummy | Anchor Town | Sushi's Training 8 | Combat.attack | live Hit Training Dummy count 10000000000 | STATIC_VERIFIED | IMPLEMENTED |
| Sushi's Training 9 | 2 | Anchor Town | Talk | Talk | Sushi | — | Sushi | Anchor Town | Sushi's Training 8 | Quest.talk | live Talk Sushi count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Terry vs. The Tide | 1 | Anchor Town | Return | Other | Terry's Boat | — | Terry's Boat | Anchor Town | Wormless Terry | UNKNOWN | live Return Terry's Boat count 1 | UNKNOWN | UNRESOLVED |
| Terry vs. The Tide | 2 | Anchor Town | Talk | Talk | Terry | — | Terry | Anchor Town | Wormless Terry | Quest.talk | live Talk Terry count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Terry's White Whale | 1 | Anchor Town | Fish | AcquireItem | Mythic+ Fish | Fishing | Mythic+ Fish | Anchor Town | Terry vs. The Tide | LifeSkills.fishToward | inventory/quest Mythic+ Fish 1 | STATIC_VERIFIED | IMPLEMENTED |
| Terry's White Whale | 2 | Anchor Town | Talk | Talk | Terry | — | Terry | Anchor Town | Terry vs. The Tide | Quest.talk | live Talk Terry count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The 'Priceless' Haul | 1 | Anchor Town | Collect | AcquireItem | Soggy Boot | EnemyDrop | Treasure Hunter | Anchor Town | Finders Keepers | Acquire.AcquireFromEnemyDrop | inventory/quest Soggy Boot 3 | STATIC_VERIFIED | IMPLEMENTED |
| The 'Priceless' Haul | 2 | Anchor Town | Talk | Talk | Merchant | — | Merchant | Anchor Town | Finders Keepers | Quest.talk | live Talk Merchant count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The 'Priceless' Haul | 3 | Anchor Town | Talk | Talk | Wade | — | Wade | Anchor Town | Finders Keepers | Quest.talk | live Talk Wade count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Wizards Apprentice | 1 | Anchor Town | CollectLocalItem | AcquireItem | Red Shell | WorldPickup | Red Shell Spawn | Anchor Town | — | Acquire.WorldPickup | inventory/quest Red Shell 1 | STATIC_VERIFIED | IMPLEMENTED |
| Wizards Apprentice | 1 | Anchor Town | CollectLocalItem | AcquireItem | Yellow Shell | WorldPickup | Red Shell Spawn | Anchor Town | — | Acquire.WorldPickup | inventory/quest Yellow Shell 1 | STATIC_VERIFIED | IMPLEMENTED |
| Wizards Apprentice | 1 | Anchor Town | CollectLocalItem | AcquireItem | White Shell | WorldPickup | Red Shell Spawn | Anchor Town | — | Acquire.WorldPickup | inventory/quest White Shell 1 | STATIC_VERIFIED | IMPLEMENTED |
| Wizards Apprentice | 1 | Anchor Town | CollectLocalItem | AcquireItem | Black Shell | WorldPickup | Red Shell Spawn | Anchor Town | — | Acquire.WorldPickup | inventory/quest Black Shell 1 | STATIC_VERIFIED | IMPLEMENTED |
| Wizards Apprentice | 2 | Anchor Town | Talk | Talk | Almighty Calvin | — | Almighty Calvin | Anchor Town | — | Quest.talk | live Talk Almighty Calvin count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Wormless Terry | 1 | Anchor Town | Collect | AcquireItem | Worm | ShopPurchase | Worm | Anchor Town | — | Shop.buy | inventory/quest Worm 20 | STATIC_VERIFIED | IMPLEMENTED |
| Wormless Terry | 2 | Anchor Town | Talk | Talk | Terry | — | Terry | Anchor Town | — | Quest.talk | live Talk Terry count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Arm Wrestling 1 | 1 | Clown Town | Win Arm Wrestle | Other | Beginner Arm Wrestler | — | Beginner Arm Wrestler | Clown Town | — | UNKNOWN | live Win Arm Wrestle Beginner Arm Wrestler count 1 | UNKNOWN | UNRESOLVED |
| Arm Wrestling 1 | 2 | Clown Town | Talk | Talk | Beginner Arm Wrestler | — | Beginner Arm Wrestler | Clown Town | — | Quest.talk | live Talk Beginner Arm Wrestler count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Arm Wrestling 2 | 1 | Clown Town | Win Arm Wrestle | Other | Intermediate Arm Wrestler | — | Intermediate Arm Wrestler | Clown Town | Arm Wrestling 1 | UNKNOWN | live Win Arm Wrestle Intermediate Arm Wrestler count 1 | UNKNOWN | UNRESOLVED |
| Arm Wrestling 2 | 2 | Clown Town | Talk | Talk | Intermediate Arm Wrestler | — | Intermediate Arm Wrestler | Clown Town | Arm Wrestling 1 | Quest.talk | live Talk Intermediate Arm Wrestler count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Arm Wrestling 3 | 1 | Clown Town | Win Arm Wrestle | Other | Arm Wrestling Champion | — | Arm Wrestling Champion | Clown Town | Arm Wrestling 2 | UNKNOWN | live Win Arm Wrestle Arm Wrestling Champion count 1 | UNKNOWN | UNRESOLVED |
| Arm Wrestling 3 | 2 | Clown Town | Talk | Talk | Arm Wrestling Champion | — | Arm Wrestling Champion | Clown Town | Arm Wrestling 2 | Quest.talk | live Talk Arm Wrestling Champion count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Clown Imposter | 1 | Clown Town | Escort | Escort | Fake Clown | — | Fake Clown | Clown Town | — | Quest.escort | live Escort Fake Clown count 1 | STATIC_VERIFIED | RUNTIME_REQUIRED |
| Clown Propaganda | 1 | Clown Town | CollectLocalItem | AcquireItem | Clown Propaganda Poster | WorldPickup | Clown Propaganda Poster | Clown Town | — | Acquire.WorldPickup | inventory/quest Clown Propaganda Poster 10 | STATIC_VERIFIED | IMPLEMENTED |
| Clown Propaganda | 2 | Clown Town | Talk | Talk | Benny | — | Benny | Clown Town | — | Quest.talk | live Talk Benny count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Emergency Deliveries | 1 | Clown Town | Talk | Talk | Billy's Customer 1 | — | Billy's Customer 1 | Clown Town | Butcher's Business | Quest.talk | live Talk Billy's Customer 1 count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Emergency Deliveries | 1 | Clown Town | Talk | Talk | Billy's Customer 2 | — | Billy's Customer 2 | Clown Town | Butcher's Business | Quest.talk | live Talk Billy's Customer 2 count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Emergency Deliveries | 1 | Clown Town | Talk | Talk | Billy's Customer 3 | — | Billy's Customer 3 | Clown Town | Butcher's Business | Quest.talk | live Talk Billy's Customer 3 count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Emergency Deliveries | 2 | Clown Town | Talk | Talk | Billy B. | — | Billy B. | Clown Town | Butcher's Business | Quest.talk | live Talk Billy B. count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Explosive Research 1 | 1 | Clown Town | Deliver Object | DeliverObject | Explosive Wooden Crate | — | Explosive Wooden Crate | Clown Town | — | Quest.goTagged | live Deliver Object Explosive Wooden Crate count 5 | STATIC_VERIFIED | IMPLEMENTED |
| Explosive Research 1 | 2 | Clown Town | Talk | Talk | Mei | — | Mei | Clown Town | — | Quest.talk | live Talk Mei count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Explosive Research 2 | 1 | Clown Town | Collect | AcquireItem | Clown Cannon Ball | WorldPickup | Clown Cannon Ball | Clown Town | Explosive Research 1 | Acquire.WorldPickup | inventory/quest Clown Cannon Ball 1 | STATIC_VERIFIED | IMPLEMENTED |
| Explosive Research 2 | 2 | Clown Town | Talk | Talk | Mei | — | Mei | Clown Town | Explosive Research 1 | Quest.talk | live Talk Mei count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Explosive Research 3 | 1 | Clown Town | Collect | AcquireItem | Gunpowder | WorldPickup | Gunpowder | Clown Town | Explosive Research 2 | Acquire.WorldPickup | inventory/quest Gunpowder 1 | STATIC_VERIFIED | IMPLEMENTED |
| Explosive Research 3 | 2 | Clown Town | Talk | Talk | Mei | — | Mei | Clown Town | Explosive Research 2 | Quest.talk | live Talk Mei count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Ferris Wheel Standoff | 1 | Clown Town | Talk | Talk | Lash | — | Lash | Clown Town | — | Quest.talk | live Talk Lash count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Ferris Wheel Standoff | 2 | Clown Town | Talk | Talk | Marnie | — | Marnie | Clown Town | — | Quest.talk | live Talk Marnie count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Militia Powerup 1 | 1 | Clown Town | CollectLocalItem | AcquireItem | Dumbbell | WorldPickup | Dumbbell | Clown Town | Clown Town's Militia | Acquire.WorldPickup | inventory/quest Dumbbell 1 | STATIC_VERIFIED | IMPLEMENTED |
| Militia Powerup 1 | 2 | Clown Town | Talk | Talk | Clown Town Angry Civilian 1 | — | Clown Town Angry Civilian 1 | Clown Town | Clown Town's Militia | Quest.talk | live Talk Clown Town Angry Civilian 1 count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Militia Powerup 2 | 1 | Clown Town | Unknown | Other | — | — | — | Clown Town | Clown Town's Militia | UNKNOWN | live Unknown - count 1 | UNKNOWN | UNRESOLVED |
| Militia Powerup 2 | 2 | Clown Town | Unknown | Other | — | — | — | Clown Town | Clown Town's Militia | UNKNOWN | live Unknown - count 1 | UNKNOWN | UNRESOLVED |
| Militia Powerup 3 | 1 | Clown Town | Unknown | Other | — | — | — | Clown Town | Clown Town's Militia | UNKNOWN | live Unknown - count 1 | UNKNOWN | UNRESOLVED |
| Militia Powerup 3 | 2 | Clown Town | Unknown | Other | — | — | — | Clown Town | Clown Town's Militia | UNKNOWN | live Unknown - count 1 | UNKNOWN | UNRESOLVED |
| Tightrope Trouble | 1 | Clown Town | Talk | Talk | Augustine | — | Augustine | Clown Town | — | Quest.talk | live Talk Augustine count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Tightrope Trouble | 2 | Clown Town | Rescue | Other | Augustine | — | Augustine | Clown Town | — | UNKNOWN | live Rescue Augustine count 1 | UNKNOWN | UNRESOLVED |
| Tightrope Trouble | 3 | Clown Town | Talk | Talk | Augustine [2] | — | Augustine [2] | Clown Town | — | Quest.talk | live Talk Augustine [2] count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Undermine The Circus 1 | 1 | Clown Town | Kill | Kill | Clown | — | Clown | Clown Town | — | Combat.attack | live Kill Clown count 6 | STATIC_VERIFIED | IMPLEMENTED |
| Undermine The Circus 1 | 1 | Clown Town | Destroy | Kill | Air Balloon | — | Air Balloon | Clown Town | — | Combat.attack | live Destroy Air Balloon count 2 | STATIC_VERIFIED | IMPLEMENTED |
| Undermine The Circus 1 | 1 | Clown Town | Free | Interact | Captive | — | Muggy Cannon | Clown Town | — | Quest.goTagged | live Free Captive count 2 | STATIC_VERIFIED | IMPLEMENTED |
| Undermine The Circus 1 | 1 | Clown Town | Destroy | Kill | Explosive Wooden Crate | — | Explosive Wooden Crate | Clown Town | — | Combat.attack | live Destroy Explosive Wooden Crate count 6 | STATIC_VERIFIED | IMPLEMENTED |
| Undermine The Circus 1 | 1 | Clown Town | Destroy | Kill | Muggy Cannon | — | Muggy Cannon | Clown Town | — | Combat.attack | live Destroy Muggy Cannon count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Undermine The Circus 1 | 2 | Clown Town | Talk | Talk | Gambit | — | Gambit | Clown Town | — | Quest.talk | live Talk Gambit count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Undermine The Circus 2 | 1 | Clown Town | Kill | Kill | Bazaji | — | Bazaji | Clown Town | Undermine The Circus 1 | Combat.attack | live Kill Bazaji count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Undermine The Circus 2 | 1 | Clown Town | Kill | Kill | Circus Lion | — | Circus Lion | Clown Town | Undermine The Circus 1 | Combat.attack | live Kill Circus Lion count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Undermine The Circus 2 | 1 | Clown Town | Kill | Kill | Beast Tamer | — | Beast Tamer | Clown Town | Undermine The Circus 1 | Combat.attack | live Kill Beast Tamer count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Undermine The Circus 2 | 2 | Clown Town | Talk | Talk | Gambit | — | Gambit | Clown Town | Undermine The Circus 1 | Quest.talk | live Talk Gambit count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Undermine The Circus 3 | 1 | Clown Town | Kill | Kill | Choppy The Clown | — | Choppy The Clown | Clown Town | Undermine The Circus 2 | Combat.attack | live Kill Choppy The Clown count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Undermine The Circus 3 | 2 | Clown Town | Talk | Talk | Gambit | — | Gambit | Clown Town | Undermine The Circus 2 | Quest.talk | live Talk Gambit count 1 | STATIC_VERIFIED | IMPLEMENTED |
| A Balanced Field | 1 | Maple Village | Harvest | AcquireItem | Tomato | Farming | Tomato | Maple Village | Green Thumb | LifeSkills.farmToward | inventory/quest Tomato 1 | STATIC_VERIFIED | IMPLEMENTED |
| A Balanced Field | 1 | Maple Village | Harvest | AcquireItem | Carrot | Farming | Carrot | Maple Village | Green Thumb | LifeSkills.farmToward | inventory/quest Carrot 1 | STATIC_VERIFIED | IMPLEMENTED |
| A Balanced Field | 1 | Maple Village | Harvest | AcquireItem | Cabbage | Farming | Cabbage | Maple Village | Green Thumb | LifeSkills.farmToward | inventory/quest Cabbage 1 | STATIC_VERIFIED | IMPLEMENTED |
| A Balanced Field | 1 | Maple Village | Harvest | AcquireItem | Wheat | Farming | Wheat | Maple Village | Green Thumb | LifeSkills.farmToward | inventory/quest Wheat 1 | STATIC_VERIFIED | IMPLEMENTED |
| A Balanced Field | 1 | Maple Village | Water | AcquireItem | Crop | Farming | Crop | Maple Village | Green Thumb | LifeSkills.farmToward | inventory/quest Crop 4 | STATIC_VERIFIED | IMPLEMENTED |
| A Balanced Field | 2 | Maple Village | Collect | AcquireItem | Egg | WorldPickup | Egg | Maple Village | Green Thumb | Acquire.WorldPickup | inventory/quest Egg 2 | STATIC_VERIFIED | IMPLEMENTED |
| A Balanced Field | 3 | Maple Village | Talk | Talk | Farmer Joe | — | Farmer Joe | Maple Village | Green Thumb | Quest.talk | live Talk Farmer Joe count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Big Shot 1 | 1 | Maple Village | Collect | AcquireItem | Lead | Crafting | Furnace | Maple Village | The Island's Protector | LifeSkills.mineToward | inventory/quest Lead 2 | STATIC_VERIFIED | IMPLEMENTED |
| Big Shot 1 | 2 | Maple Village | Talk | Talk | Pip | — | Pip | Maple Village | The Island's Protector | Quest.talk | live Talk Pip count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Big Shot 2 | 1 | Maple Village | Collect | AcquireItem | Lead Ball | WorldPickup | Lead Ball | Maple Village | Big Shot 1 | Acquire.WorldPickup | inventory/quest Lead Ball 1 | STATIC_VERIFIED | IMPLEMENTED |
| Big Shot 2 | 1 | Maple Village | Collect | AcquireItem | Pepper | WorldPickup | Pepper | Maple Village | Big Shot 1 | Acquire.WorldPickup | inventory/quest Pepper 10 | STATIC_VERIFIED | IMPLEMENTED |
| Big Shot 2 | 2 | Maple Village | Talk | Talk | Pip | — | Pip | Maple Village | Big Shot 1 | Quest.talk | live Talk Pip count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Big Shot 3 | 1 | Maple Village | Collect | AcquireItem | Lead Ball | WorldPickup | Lead Ball | Maple Village | Big Shot 2 | Acquire.WorldPickup | inventory/quest Lead Ball 1 | STATIC_VERIFIED | IMPLEMENTED |
| Big Shot 3 | 1 | Maple Village | Collect | AcquireItem | Oil | WorldPickup | Oil | Maple Village | Big Shot 2 | Acquire.WorldPickup | inventory/quest Oil 3 | STATIC_VERIFIED | IMPLEMENTED |
| Big Shot 3 | 2 | Maple Village | Talk | Talk | Pip | — | Pip | Maple Village | Big Shot 2 | Quest.talk | live Talk Pip count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Big Shot 4 | 1 | Maple Village | Collect | AcquireItem | Lead Ball | WorldPickup | Lead Ball | Maple Village | Big Shot 3 | Acquire.WorldPickup | inventory/quest Lead Ball 1 | STATIC_VERIFIED | IMPLEMENTED |
| Big Shot 4 | 1 | Maple Village | Collect | AcquireItem | Gunpowder | WorldPickup | Gunpowder | Maple Village | Big Shot 3 | Acquire.WorldPickup | inventory/quest Gunpowder 2 | STATIC_VERIFIED | IMPLEMENTED |
| Big Shot 4 | 2 | Maple Village | Talk | Talk | Pip | — | Pip | Maple Village | Big Shot 3 | Quest.talk | live Talk Pip count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Fresh From the Farm | 1 | Maple Village | Collect | AcquireItem | Egg | WorldPickup | Egg | Maple Village | Kitchen Helper | Acquire.WorldPickup | inventory/quest Egg 2 | STATIC_VERIFIED | IMPLEMENTED |
| Fresh From the Farm | 1 | Maple Village | Collect | AcquireItem | Raw Chicken | WorldPickup | Raw Chicken | Maple Village | Kitchen Helper | Acquire.WorldPickup | inventory/quest Raw Chicken 1 | STATIC_VERIFIED | IMPLEMENTED |
| Fresh From the Farm | 2 | Maple Village | Cook | AcquireItem | Omelette | Cooking | Omelette | Maple Village | Kitchen Helper | LifeSkills.cookToward | inventory/quest Omelette 1 | STATIC_VERIFIED | IMPLEMENTED |
| Fresh From the Farm | 2 | Maple Village | Cook | AcquireItem | Roast Chicken | Cooking | Roast Chicken | Maple Village | Kitchen Helper | LifeSkills.cookToward | inventory/quest Roast Chicken 1 | STATIC_VERIFIED | IMPLEMENTED |
| Fresh From the Farm | 3 | Maple Village | Talk | Talk | Remy | — | Remy | Maple Village | Kitchen Helper | Quest.talk | live Talk Remy count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Green Thumb | 1 | Maple Village | Plant | AcquireItem | Seed | Farming | Seed | Maple Village | — | LifeSkills.farmToward | inventory/quest Seed 4 | STATIC_VERIFIED | IMPLEMENTED |
| Green Thumb | 2 | Maple Village | Harvest | AcquireItem | Crop | Farming | Crop | Maple Village | — | LifeSkills.farmToward | inventory/quest Crop 4 | STATIC_VERIFIED | IMPLEMENTED |
| Green Thumb | 3 | Maple Village | Talk | Talk | Farmer Joe | — | Farmer Joe | Maple Village | — | Quest.talk | live Talk Farmer Joe count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Kitchen Helper | 1 | Maple Village | Cook | AcquireItem | Grilled Fish | Cooking | Grilled Fish | Maple Village | — | LifeSkills.cookToward | inventory/quest Grilled Fish 1 | STATIC_VERIFIED | IMPLEMENTED |
| Kitchen Helper | 2 | Maple Village | Talk | Talk | Remy | — | Remy | Maple Village | — | Quest.talk | live Talk Remy count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Pecking Order | 1 | Maple Village | Obtain | Other | Chicken Pet | — | Chicken Pet | Maple Village | — | UNKNOWN | live Obtain Chicken Pet count 1 | UNKNOWN | UNRESOLVED |
| Pecking Order | 2 | Maple Village | Talk | Talk | Chicken Hank | — | Chicken Hank | Maple Village | — | Quest.talk | live Talk Chicken Hank count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Full Harvest | 1 | Maple Village | Fertilize | AcquireItem | Crop | Farming | Crop | Maple Village | A Balanced Field | LifeSkills.farmToward | inventory/quest Crop 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Full Harvest | 1 | Maple Village | Harvest | AcquireItem | Crop | Farming | Crop | Maple Village | A Balanced Field | LifeSkills.farmToward | inventory/quest Crop 12 | STATIC_VERIFIED | IMPLEMENTED |
| The Full Harvest | 2 | Maple Village | Talk | Talk | Farmer Joe | — | Farmer Joe | Maple Village | A Balanced Field | Quest.talk | live Talk Farmer Joe count 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Perfect Dish | 1 | Maple Village | Perfect Cook | AcquireItem | Dish | Cooking | Dish | Maple Village | Fresh From the Farm | LifeSkills.cookToward | inventory/quest Dish 1 | STATIC_VERIFIED | IMPLEMENTED |
| The Perfect Dish | 2 | Maple Village | Talk | Talk | Remy | — | Remy | Maple Village | Fresh From the Farm | Quest.talk | live Talk Remy count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Trouble Down the Well | 1 | Maple Village | CollectLocalItem | AcquireItem | Henrietta | WorldPickup | Martha Chicken | Maple Village | — | Acquire.WorldPickup | inventory/quest Henrietta 1 | STATIC_VERIFIED | IMPLEMENTED |
| Trouble Down the Well | 2 | Maple Village | Talk | Talk | Martha | — | Martha | Maple Village | — | Quest.talk | live Talk Martha count 1 | STATIC_VERIFIED | IMPLEMENTED |
| [TUTORIAL] Fruit/Style Storage | 1 | Tutorial | Visit | Interact | Closet | — | Closet | Tutorial | — | Quest.goTagged | live Visit Closet count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Bullies in Suits | 1 | Anchor Town | Kill | Kill | Corrupt Marine | — | Corrupt Marine | Anchor Town | Pirate Fan Letter | Combat.attack | live Kill Corrupt Marine count 6 | STATIC_VERIFIED | IMPLEMENTED |
| Bullies in Suits | 2 | Anchor Town | Talk | Talk | Koro | — | Koro | Anchor Town | Pirate Fan Letter | Quest.talk | live Talk Koro count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Granny's Nemesis | 1 | Anchor Town | Kill | Kill | Blonde Goblin | — | Blonde Goblin | Anchor Town | Captain's Brat | Combat.attack | live Kill Blonde Goblin count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Granny's Nemesis | 1 | Anchor Town | Kill | Kill | Corrupt Guard | — | Corrupt Guard | Anchor Town | Captain's Brat | Combat.attack | live Kill Corrupt Guard count 2 | STATIC_VERIFIED | IMPLEMENTED |
| Granny's Nemesis | 2 | Anchor Town | Talk | Talk | Granny Todo | — | Granny Todo | Anchor Town | Captain's Brat | Quest.talk | live Talk Granny Todo count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Officer Termination | 1 | Anchor Town | Kill | Kill | Corrupt Marine Officer | — | Corrupt Marine Officer | Anchor Town | Tea Party Crashers | Combat.attack | live Kill Corrupt Marine Officer count 7 | STATIC_VERIFIED | IMPLEMENTED |
| Officer Termination | 2 | Anchor Town | Talk | Talk | Maeve | — | Maeve | Anchor Town | Tea Party Crashers | Quest.talk | live Talk Maeve count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Tyrannical Captain | 1 | Anchor Town | Kill | Kill | Axe-Hand Logan | — | Axe-Hand Logan | Anchor Town | Axe-Handed Tyrant | Combat.attack | live Kill Axe-Hand Logan count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Billy's Business | 1 | Clown Town | Kill | Kill | Killer Clown | — | Killer Clown | Clown Town | Butcher's Business | Combat.attack | live Kill Killer Clown count 7 | STATIC_VERIFIED | IMPLEMENTED |
| Billy's Business | 2 | Clown Town | Talk | Talk | Billy B. | — | Billy B. | Clown Town | Butcher's Business | Quest.talk | live Talk Billy B. count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Cat Problem | 1 | Clown Town | Kill | Kill | Circus Lion | — | Circus Lion | Clown Town | Lion's Victim | Combat.attack | live Kill Circus Lion count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Cat Problem | 1 | Clown Town | Kill | Kill | Beast Tamer | — | Beast Tamer | Clown Town | Lion's Victim | Combat.attack | live Kill Beast Tamer count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Cat Problem | 2 | Clown Town | Talk | Talk | Stephon | — | Stephon | Clown Town | Lion's Victim | Quest.talk | live Talk Stephon count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Choppy The Clown | 1 | Clown Town | Kill | Kill | Choppy The Clown | — | Choppy The Clown | Clown Town | The Ringmaster | Combat.attack | live Kill Choppy The Clown count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Choppy The Clown | 2 | Clown Town | Talk | Talk | Mayor Kiyoshi [2] | — | Mayor Kiyoshi [2] | Clown Town | The Ringmaster | Quest.talk | live Talk Mayor Kiyoshi [2] count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Nibblebottom's Revenge | 1 | Clown Town | Kill | Kill | Clown Officer | — | Clown Officer | Clown Town | Revenge of the Nibblebottom | Combat.attack | live Kill Clown Officer count 5 | STATIC_VERIFIED | IMPLEMENTED |
| Nibblebottom's Revenge | 2 | Clown Town | Talk | Talk | Johnny Nibblebottom | — | Johnny Nibblebottom | Clown Town | Revenge of the Nibblebottom | Quest.talk | live Talk Johnny Nibblebottom count 1 | STATIC_VERIFIED | IMPLEMENTED |
| This Is Personal | 1 | Clown Town | Kill | Kill | Clown | — | Clown | Clown Town | A Joke Gone Too Far | Combat.attack | live Kill Clown count 7 | STATIC_VERIFIED | IMPLEMENTED |
| This Is Personal | 2 | Clown Town | Talk | Talk | Clowny D. Clown | — | Clowny D. Clown | Clown Town | A Joke Gone Too Far | Quest.talk | live Talk Clowny D. Clown count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Clear the Road | 1 | Maple Village | Kill | Kill | Black Noir Pirate | — | Black Noir Pirate | Maple Village | The Island's Protector | Combat.attack | live Kill Black Noir Pirate count 8 | STATIC_VERIFIED | IMPLEMENTED |
| Clear the Road | 2 | Maple Village | Talk | Talk | Nell | — | Nell | Maple Village | The Island's Protector | Quest.talk | live Talk Nell count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Peace of Mind | 1 | Maple Village | Kill | Kill | Black Noir Officer | — | Black Noir Officer | Maple Village | The Island's Protector | Combat.attack | live Kill Black Noir Officer count 5 | STATIC_VERIFIED | IMPLEMENTED |
| Peace of Mind | 2 | Maple Village | Talk | Talk | Gus | — | Gus | Maple Village | The Island's Protector | Quest.talk | live Talk Gus count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Debug Quest | 1 | Test | Kill | Kill | Corrupt Marine | — | Corrupt Marine | Test | — | Combat.attack | live Kill Corrupt Marine count 1 | STATIC_VERIFIED | UNRESOLVED |
| Debug Quest 2 | 1 | Test | Kill | Kill | Corrupt Marine | — | Corrupt Marine | Test | — | Combat.attack | live Kill Corrupt Marine count 2 | STATIC_VERIFIED | UNRESOLVED |
| Brawler 1 | 1 | Fighting Style | Emote | Unresolved | Pushup | — | Pushup | Fighting Style | — | UNKNOWN | live Emote Pushup count 20 | UNKNOWN | UNRESOLVED |
| Brawler 1 | 1 | Fighting Style | Emote | Unresolved | Situp | — | Situp | Fighting Style | — | UNKNOWN | live Emote Situp count 20 | UNKNOWN | UNRESOLVED |
| Brawler 1 | 2 | Fighting Style | Talk | Talk | Wallace | — | Wallace | Fighting Style | — | Quest.talk | live Talk Wallace count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Brawler 2 | 1 | Fighting Style | Take Damage | Other | — | — | — | Fighting Style | — | UNKNOWN | live Take Damage - count 200 | UNKNOWN | UNRESOLVED |
| Brawler 2 | 1 | Fighting Style | Damage | Other | — | — | — | Fighting Style | — | UNKNOWN | live Damage - count 200 | UNKNOWN | UNRESOLVED |
| Brawler 2 | 2 | Fighting Style | Talk | Talk | Wallace | — | Wallace | Fighting Style | — | Quest.talk | live Talk Wallace count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Brawler 3 | 1 | Fighting Style | Take Damage | Other | — | — | — | Fighting Style | — | UNKNOWN | live Take Damage - count 300 | UNKNOWN | UNRESOLVED |
| Brawler 3 | 1 | Fighting Style | Damage | Other | — | — | — | Fighting Style | — | UNKNOWN | live Damage - count 300 | UNKNOWN | UNRESOLVED |
| Brawler 3 | 2 | Fighting Style | Talk | Talk | Wallace | — | Wallace | Fighting Style | — | Quest.talk | live Talk Wallace count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Brawler 4 | 1 | Fighting Style | Take Damage | Other | — | — | — | Fighting Style | — | UNKNOWN | live Take Damage - count 400 | UNKNOWN | UNRESOLVED |
| Brawler 4 | 1 | Fighting Style | Damage | Other | — | — | — | Fighting Style | — | UNKNOWN | live Damage - count 400 | UNKNOWN | UNRESOLVED |
| Brawler 4 | 2 | Fighting Style | Talk | Talk | Wallace | — | Wallace | Fighting Style | — | Quest.talk | live Talk Wallace count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Marksman 1 | 1 | Fighting Style | Land | Other | Projectile | — | Projectile | Fighting Style | — | UNKNOWN | live Land Projectile count 50 | UNKNOWN | UNRESOLVED |
| Marksman 1 | 2 | Fighting Style | Talk | Talk | Captain Esopo | — | Captain Esopo | Fighting Style | — | Quest.talk | live Talk Captain Esopo count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Marksman 2 | 1 | Fighting Style | Proc Hunter's Timing Passive | Other | — | — | — | Fighting Style | — | UNKNOWN | live Proc Hunter's Timing Passive - count 50 | UNKNOWN | UNRESOLVED |
| Marksman 2 | 2 | Fighting Style | Talk | Talk | Captain Esopo | — | Captain Esopo | Fighting Style | — | Quest.talk | live Talk Captain Esopo count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Marksman 3 | 1 | Fighting Style | Land a projectile on a marked target | Other | — | — | — | Fighting Style | — | UNKNOWN | live Land a projectile on a marked target - count 25 | UNKNOWN | UNRESOLVED |
| Marksman 3 | 2 | Fighting Style | Talk | Talk | Captain Esopo | — | Captain Esopo | Fighting Style | — | Quest.talk | live Talk Captain Esopo count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Marksman 4 | 1 | Fighting Style | Reduce the cooldown of 25 skills, using quickdraw. | Other | — | — | — | Fighting Style | — | UNKNOWN | live Reduce the cooldown of 25 skills, using quickdraw. - count 25 | UNKNOWN | UNRESOLVED |
| Marksman 4 | 1 | Fighting Style | Speed up the windup of 25 skills, using quickdraw. | Other | — | — | — | Fighting Style | — | UNKNOWN | live Speed up the windup of 25 skills, using quickdraw. - count 25 | UNKNOWN | UNRESOLVED |
| Marksman 4 | 2 | Fighting Style | Talk | Talk | Captain Esopo | — | Captain Esopo | Fighting Style | — | Quest.talk | live Talk Captain Esopo count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Novice Swordsman 1 | 1 | Fighting Style | Unlock Skill | Unresolved | Power Slash | — | Power Slash | Fighting Style | — | UNKNOWN | live Unlock Skill Power Slash count 1 | UNKNOWN | UNRESOLVED |
| Novice Swordsman 1 | 2 | Fighting Style | Damage | Other | Power Slash | — | Power Slash | Fighting Style | — | UNKNOWN | live Damage Power Slash count 200 | UNKNOWN | UNRESOLVED |
| Novice Swordsman 1 | 3 | Fighting Style | Talk | Talk | Shiro | — | Shiro | Fighting Style | — | Quest.talk | live Talk Shiro count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Novice Swordsman 2 | 1 | Fighting Style | Unlock Skill | Unresolved | Sword Lunge | — | Sword Lunge | Fighting Style | — | UNKNOWN | live Unlock Skill Sword Lunge count 1 | UNKNOWN | UNRESOLVED |
| Novice Swordsman 2 | 2 | Fighting Style | Damage | Other | Sword Lunge | — | Sword Lunge | Fighting Style | — | UNKNOWN | live Damage Sword Lunge count 200 | UNKNOWN | UNRESOLVED |
| Novice Swordsman 2 | 3 | Fighting Style | Talk | Talk | Shiro | — | Shiro | Fighting Style | — | Quest.talk | live Talk Shiro count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Novice Swordsman 3 | 1 | Fighting Style | Unlock Skill | Unresolved | Whirlwind Slash | — | Whirlwind Slash | Fighting Style | — | UNKNOWN | live Unlock Skill Whirlwind Slash count 1 | UNKNOWN | UNRESOLVED |
| Novice Swordsman 3 | 2 | Fighting Style | Damage | Other | Whirlwind Slash | — | Whirlwind Slash | Fighting Style | — | UNKNOWN | live Damage Whirlwind Slash count 200 | UNKNOWN | UNRESOLVED |
| Novice Swordsman 3 | 3 | Fighting Style | Talk | Talk | Shiro | — | Shiro | Fighting Style | — | Quest.talk | live Talk Shiro count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Novice Swordsman 4 | 1 | Fighting Style | Damage | Other | Power Slash | — | Power Slash | Fighting Style | — | UNKNOWN | live Damage Power Slash count 200 | UNKNOWN | UNRESOLVED |
| Novice Swordsman 4 | 1 | Fighting Style | Damage | Other | Sword Lunge | — | Sword Lunge | Fighting Style | — | UNKNOWN | live Damage Sword Lunge count 200 | UNKNOWN | UNRESOLVED |
| Novice Swordsman 4 | 1 | Fighting Style | Damage | Other | Whirlwind Slash | — | Whirlwind Slash | Fighting Style | — | UNKNOWN | live Damage Whirlwind Slash count 200 | UNKNOWN | UNRESOLVED |
| Novice Swordsman 4 | 1 | Fighting Style | Damage | Other | Sword | — | Sword | Fighting Style | — | UNKNOWN | live Damage Sword count 1000 | UNKNOWN | UNRESOLVED |
| Novice Swordsman 4 | 2 | Fighting Style | Talk | Talk | Shiro | — | Shiro | Fighting Style | — | Quest.talk | live Talk Shiro count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Trickster 1 | 1 | Fighting Style | Pickpocket | Other | Gold | — | Gold | Fighting Style | — | UNKNOWN | live Pickpocket Gold count 100 | UNKNOWN | UNRESOLVED |
| Trickster 1 | 1 | Fighting Style | Land | Other | Pocket Sand | — | Pocket Sand | Fighting Style | — | UNKNOWN | live Land Pocket Sand count 20 | UNKNOWN | UNRESOLVED |
| Trickster 1 | 2 | Fighting Style | Talk | Talk | Loki [2] | — | Loki [2] | Fighting Style | — | Quest.talk | live Talk Loki [2] count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Trickster 2 | 1 | Fighting Style | Land | Other | Cheap Shot | — | Cheap Shot | Fighting Style | — | UNKNOWN | live Land Cheap Shot count 25 | UNKNOWN | UNRESOLVED |
| Trickster 2 | 2 | Fighting Style | Talk | Talk | Loki [2] | — | Loki [2] | Fighting Style | — | Quest.talk | live Talk Loki [2] count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Trickster 3 | 1 | Fighting Style | Deceive | Other | Hostile Enemy | — | Hostile Enemy | Fighting Style | — | UNKNOWN | live Deceive Hostile Enemy count 25 | UNKNOWN | UNRESOLVED |
| Trickster 3 | 2 | Fighting Style | Talk | Talk | Loki [2] | — | Loki [2] | Fighting Style | — | Quest.talk | live Talk Loki [2] count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Trickster 4 | 1 | Fighting Style | Damage | Other | Poison | — | Poison | Fighting Style | — | UNKNOWN | live Damage Poison count 750 | UNKNOWN | UNRESOLVED |
| Trickster 4 | 1 | Fighting Style | Land Poisoned Shiv While Stealthed | Other | — | — | — | Fighting Style | — | UNKNOWN | live Land Poisoned Shiv While Stealthed - count 25 | UNKNOWN | UNRESOLVED |
| Trickster 4 | 2 | Fighting Style | Talk | Talk | Loki [2] | — | Loki [2] | Fighting Style | — | Quest.talk | live Talk Loki [2] count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Trickster 5 | 1 | Fighting Style | Fear | Other | Enemy | — | Enemy | Fighting Style | — | UNKNOWN | live Fear Enemy count 50 | UNKNOWN | UNRESOLVED |
| Trickster 5 | 1 | Fighting Style | Place Down Trap While Stealthed | Other | — | — | — | Fighting Style | — | UNKNOWN | live Place Down Trap While Stealthed - count 10 | UNKNOWN | UNRESOLVED |
| Trickster 5 | 2 | Fighting Style | Talk | Talk | Loki [2] | — | Loki [2] | Fighting Style | — | Quest.talk | live Talk Loki [2] count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Chop Chop Punch | 1 | Skill Mastery | Defeat | Kill | World Boss Buggy | — | World Boss Buggy | Skill Mastery | — | Combat.attack | live Defeat World Boss Buggy count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Liberation | 1 | Skill Mastery | Defeat | Kill | World Boss Buggy | — | World Boss Buggy | Skill Mastery | — | Combat.attack | live Defeat World Boss Buggy count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Easy Pickings | 1 | Anchor Town | Steal | Unresolved | Tip Jar | — | Tip Jar | Anchor Town | — | UNKNOWN | live Steal Tip Jar count 1 | UNKNOWN | UNRESOLVED |
| Easy Pickings | 2 | Anchor Town | Cash Out | Unresolved | Tip Jar | — | Tip Jar | Anchor Town | — | UNKNOWN | live Cash Out Tip Jar count 1 | UNKNOWN | UNRESOLVED |
| Jack's Daily Haul | 0 | Anchor Town | — | Unresolved | — | — | — | Anchor Town | — | UNKNOWN | none | UNKNOWN | UNRESOLVED |
| Kim Wu's Daily Quota | 0 | Anchor Town | — | Unresolved | — | — | — | Anchor Town | — | UNKNOWN | none | UNKNOWN | UNRESOLVED |
| Noise Complaint | 1 | Anchor Town | Kill | Kill | Sushi | — | Sushi | Anchor Town | — | Combat.attack | live Kill Sushi count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Joe's Daily Chores | 0 | Maple Village | — | Unresolved | — | — | — | Maple Village | — | UNKNOWN | none | UNKNOWN | UNRESOLVED |
| Remy's Daily Order | 0 | Maple Village | — | Unresolved | — | — | — | Maple Village | — | UNKNOWN | none | UNKNOWN | UNRESOLVED |
| Daily Quest Test | 1 | Test | Hit | Kill | Training Dummy | — | Training Dummy | Test | — | Combat.attack | live Hit Training Dummy count 5 | STATIC_VERIFIED | UNRESOLVED |
| Corruption Cleanse | 1 | Anchor Town | Kill | Kill | Corrupt Marine | — | Corrupt Marine | Anchor Town | — | Combat.attack | live Kill Corrupt Marine count 6 | STATIC_VERIFIED | IMPLEMENTED |
| Corruption Cleanse | 2 | Anchor Town | Kill | Kill | Afuaru, The Hoarder | — | Afuaru, The Hoarder | Anchor Town | — | Combat.attack | live Kill Afuaru, The Hoarder count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Corruption Cleanse | 3 | Anchor Town | Kill | Kill | Corrupt Marine Officer | — | Corrupt Marine Officer | Anchor Town | — | Combat.attack | live Kill Corrupt Marine Officer count 5 | STATIC_VERIFIED | IMPLEMENTED |
| Corruption Cleanse | 4 | Anchor Town | Kill | Kill | Blonde Goblin | — | Blonde Goblin | Anchor Town | — | Combat.attack | live Kill Blonde Goblin count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Corruption Cleanse | 4 | Anchor Town | Kill | Kill | Soro | — | Soro | Anchor Town | — | Combat.attack | live Kill Soro count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Corruption Cleanse | 5 | Anchor Town | Kill | Kill | Axe-Hand Logan | — | Axe-Hand Logan | Anchor Town | — | Combat.attack | live Kill Axe-Hand Logan count 1 | STATIC_VERIFIED | IMPLEMENTED |
| Weekly Quest Test | 1 | Test | Hit | Kill | Training Dummy | — | Training Dummy | Test | — | Combat.attack | live Hit Training Dummy count 5 | STATIC_VERIFIED | UNRESOLVED |
| The Stolen Tip Jar | 0 | Anchor Town | — | Unresolved | — | — | — | Anchor Town | — | UNKNOWN | none | UNKNOWN | UNRESOLVED |
| Defeat 25 Corrupt Marines | 1 | Crew | Kill | Kill | Corrupt Marine | — | Corrupt Marine | Crew | — | Combat.attack | live Kill Corrupt Marine count 25 | STATIC_VERIFIED | IMPLEMENTED |
| Defeat 50 Corrupt Marines | 1 | Crew | Kill | Kill | Corrupt Marine | — | Corrupt Marine | Crew | — | Combat.attack | live Kill Corrupt Marine count 50 | STATIC_VERIFIED | IMPLEMENTED |
| Defeat 75 Corrupt Marines | 1 | Crew | Kill | Kill | Corrupt Marine | — | Corrupt Marine | Crew | — | Combat.attack | live Kill Corrupt Marine count 75 | STATIC_VERIFIED | IMPLEMENTED |
| Crew: Defeat Corrupt Marines | 1 | Crew | Kill | Kill | Corrupt Marine | — | Corrupt Marine | Crew | — | Combat.attack | live Kill Corrupt Marine count 10 | STATIC_VERIFIED | IMPLEMENTED |
| Crew: Defeat Corrupt Marines | 2 | Crew | Talk | Talk | Koro | — | Koro | Crew | — | Quest.talk | live Talk Koro count 1 | STATIC_VERIFIED | IMPLEMENTED |

## Notes

- **Officer Graves** quest target / DisplayName ≠ instance Name. Instance is `Officer Graves [2]`. ReplicatedStorage `Officer Graves` is character-create.
- **Pirate Fan Letter** Collect = KillUntilDrop **Corrupt Marine** (QuestInfo `markers[].tag`). Credit = inventory or Collect `Target.Amount` after kill. Do not require world pickup / CollectQuestItem.
- **Pirate Instructions** Collect = KillUntilDrop **Black Noir Officer** (marker `Black Noir Officer Marker`).
- **Escort The Mayor**: handler `Escort`, `NeverSkip`. Follow only. Do not substitute Talk/Kill.
- **The Wandering Hypnotist**: `NeverSkip`. Kill target verified `"Hypnotist" Mango`.
- **Stephon's Tormentor**: Kill target verified `"Barrel Clown" Binki`.
- Resume from any live quest / completed set. Do not assume lv0.
- **Live truth:** `GetData("Quests","Completed Quests")` + `BeginQuest`/`ClearQuest`/`QuestProgress` + PlayerGui.Quests tracker.
- Craft / Defend / Emote / Convince / Dig / Steal / Cash Out / Unlock Skill: `UNKNOWN_OBJECTIVE` + skip, no infinite loop.
