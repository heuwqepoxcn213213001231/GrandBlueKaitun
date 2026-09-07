# Quest Execution Matrix

Source: `research/quests.json` (QuestInfo Studio dump) + live Studio place `118635363908336`.
Runtime identity: world Graves = `Workspace.AA IMPORTANT.DialogueNPCs.Anchor Town.Officer Graves [2]` (Model, tag `Officer Graves [2]`, Humanoid.DisplayName `Officer Graves`).
Talk remote: `ClientQuest:FireServer("Talk", DisplayName)` + `DialogueBindable:Fire(Configuration)` — never `BeginQuest`.

| Quest | Stage | Objective | Target | Handler | Resolver | Validation | Status |
|---|---|---|---|---|---|---|---|
| Introduction | 1 | Talk | Officer Graves | Talk | ResolveNPC DisplayName + alias Officer Graves [2] DialogueNPCs | live Talk Officer Graves count 1 | VERIFIED |
| Introduction | 2 | Hit | Training Dummy | Kill | Entities Training Dummy1–8 tag TrainingDummy | live Hit Training Dummy count 4 | VERIFIED |
| Introduction | 3 | Dash | Press Q to perform a dash. | Combat.dash PressKey Q | — | live Dash count 2 | VERIFIED |
| Introduction | 4 | Block | Hold F to perform a block. | Combat.block PressKey F | — | live Block count 1 | VERIFIED |
| Introduction | 5 | Talk | Officer Graves | Talk | ResolveNPC DisplayName + alias Officer Graves [2] DialogueNPCs | live Talk Officer Graves count 1 | VERIFIED |
| Basics | 1 | Talk | Officer Graves | Talk | ResolveNPC DisplayName + alias Officer Graves [2] DialogueNPCs | live Talk Officer Graves count 1 | VERIFIED |
| Basics | 2 | EquipSkill | Strong Punch | Equip | ResolveShop/Item | live EquipSkill Strong Punch count 1 | VERIFIED |
| Basics | 3 | Cast | Strong Punch | Equip | ResolveShop/Item | live Cast Strong Punch count 1 | VERIFIED |
| Basics | 4 | Talk | Officer Graves | Talk | ResolveNPC DisplayName + alias Officer Graves [2] DialogueNPCs | live Talk Officer Graves count 1 | VERIFIED |
| Basics | 5 | Required | TotalStatPoints | Equip | ResolveShop/Item | live Required TotalStatPoints count 1 | VERIFIED |
| Basics | 6 | Talk | Officer Graves | Talk | ResolveNPC DisplayName + alias Officer Graves [2] DialogueNPCs | live Talk Officer Graves count 1 | VERIFIED |
| Basics | 7 | Open | Logbook | Interact | ResolveShop/Item | live Open Logbook count 1 | VERIFIED |
| Pirate Fan Letter | 1 | Talk | Officer Graves | Talk | ResolveNPC DisplayName + alias Officer Graves [2] DialogueNPCs | live Talk Officer Graves count 1 | VERIFIED |
| Pirate Fan Letter | 2 | Talk | Koro | Talk | ResolveNPC | live Talk Koro count 1 | VERIFIED |
| Pirate Fan Letter | 3 | Collect | Pirate Fan Letter | Collect | ResolveShop/Item | live Collect Pirate Fan Letter count 1 | VERIFIED |
| Pirate Fan Letter | 4 | Talk | Koro | Talk | ResolveNPC | live Talk Koro count 1 | VERIFIED |
| Gearing Up | 1 | Sell | Stolen Watch | Purchase | ResolveShop/Item | live Sell Stolen Watch count 1 | VERIFIED |
| Gearing Up | 2 | Purchase | Flintlock | Purchase | ResolveShop/Item | live Purchase Flintlock count 1 | VERIFIED |
| Gearing Up | 3 | Equip | Flintlock | Equip | ResolveShop/Item | live Equip Flintlock count 1 | VERIFIED |
| Gearing Up | 4 | Shoot | Training Dummy | Kill | Entities Training Dummy* | live Shoot Training Dummy count 1 | VERIFIED |
| The Hoarder | 1 | Required | Level | Equip | ResolveShop/Item | live Required Level count 1 | VERIFIED |
| The Hoarder | 2 | Talk | Troubled Civilian | Talk | ResolveNPC | live Talk Troubled Civilian count 1 | VERIFIED |
| The Hoarder | 3 | Kill | Afuaru, The Hoarder | Kill | ResolveEnemy | live Kill Afuaru, The Hoarder count 1 | VERIFIED |
| The Hoarder | 3 | Collect | Afuaru's Key | Collect | ResolveShop/Item | live Collect Afuaru's Key count 1 | VERIFIED |
| The Hoarder | 4 | Unlock | Afuaru's Gate | UNKNOWN | — | live Unlock Afuaru's Gate count 1 | UNVERIFIED_HANDLER |
| The Hoarder | 5 | Loot | Afuaru's Chests | Collect | ResolveShop/Item | live Loot Afuaru's Chests count 5 | VERIFIED |
| The Hoarder | 6 | Talk | Troubled Civilian | Talk | ResolveNPC | live Talk Troubled Civilian count 1 | VERIFIED |
| First Upgrade | 1 | Talk | Blacksmith Shinozaki | Talk | ResolveNPC | live Talk Blacksmith Shinozaki count 1 | VERIFIED |
| First Upgrade | 2 | Collect | Rusty Pickaxe | Collect | ResolveShop/Item | live Collect Rusty Pickaxe count 1 | VERIFIED |
| First Upgrade | 3 | Collect | Copper Ore | Collect | ResolveShop/Item | live Collect Copper Ore count 2 | VERIFIED |
| First Upgrade | 4 | Talk | Blacksmith Shinozaki | Talk | ResolveNPC | live Talk Blacksmith Shinozaki count 1 | VERIFIED |
| First Upgrade | 5 | Smelt | Copper Bar | Mine | ResolveShop/Item | live Smelt Copper Bar count 2 | VERIFIED |
| First Upgrade | 6 | Upgrade | Flintlock | Upgrade | — | live Upgrade Flintlock count 1 | VERIFIED |
| Tea Party Crashers | 1 | Talk | Maeve | Talk | ResolveNPC | live Talk Maeve count 1 | VERIFIED |
| Tea Party Crashers | 2 | Kill | Corrupt Marine Officer | Kill | ResolveEnemy | live Kill Corrupt Marine Officer count 7 | VERIFIED |
| Tea Party Crashers | 2 | Kill | Marine Snitch | Kill | ResolveEnemy | live Kill Marine Snitch count 1 | VERIFIED |
| Tea Party Crashers | 3 | Talk | Maeve | Talk | ResolveNPC | live Talk Maeve count 1 | VERIFIED |
| Captain's Brat | 1 | Required | Level | Equip | ResolveShop/Item | live Required Level count 1 | VERIFIED |
| Captain's Brat | 2 | Talk | Granny Todo | Talk | ResolveNPC | live Talk Granny Todo count 1 | VERIFIED |
| Captain's Brat | 3 | Kill | Blonde Goblin | Kill | ResolveEnemy | live Kill Blonde Goblin count 1 | VERIFIED |
| Captain's Brat | 3 | Kill | Corrupt Guard | Kill | ResolveEnemy | live Kill Corrupt Guard count 2 | VERIFIED |
| Captain's Brat | 4 | Talk | Granny Todo | Talk | ResolveNPC | live Talk Granny Todo count 1 | VERIFIED |
| Feral Dog | 1 | Required | Level | Equip | ResolveShop/Item | live Required Level count 1 | VERIFIED |
| Feral Dog | 2 | Kill | Blonde Goblin | Kill | ResolveEnemy | live Kill Blonde Goblin count 1 | VERIFIED |
| Feral Dog | 2 | Kill | Soro | Kill | ResolveEnemy | live Kill Soro count 1 | VERIFIED |
| Gate of Authority | 1 | Open | Marine Gate | Interact | ResolveShop/Item | live Open Marine Gate count 1 | VERIFIED |
| Captive Swordsman | 1 | Talk | Captive Swordsman | Talk | ResolveNPC | live Talk Captive Swordsman count 1 | VERIFIED |
| Captive Swordsman | 2 | CollectLocalItem | Captive Swordsman's Swords | Collect | ResolveShop/Item | live CollectLocalItem Captive Swordsman's Swords count 1 | VERIFIED |
| Captive Swordsman | 3 | Talk | Captive Swordsman | Talk | ResolveNPC | live Talk Captive Swordsman count 1 | VERIFIED |
| Axe-Handed Tyrant | 1 | Kill | Axe-Hand Logan | Kill | ResolveEnemy | live Kill Axe-Hand Logan count 1 | VERIFIED |
| A Voice in a Shell | 1 | Talk | Officer Graves | Talk | ResolveNPC DisplayName + alias Officer Graves [2] DialogueNPCs | live Talk Officer Graves count 1 | VERIFIED |
| A Voice in a Shell | 2 | Purchase | Transponder Snail | Purchase | ResolveShop/Item | live Purchase Transponder Snail count 1 | VERIFIED |
| A Voice in a Shell | 3 | Equip | Transponder Snail | Equip | ResolveShop/Item | live Equip Transponder Snail count 1 | VERIFIED |
| Setting Sail | 1 | Required | Level | Equip | ResolveShop/Item | live Required Level count 30 | VERIFIED |
| Setting Sail | 2 | Talk | Officer Graves | Talk | ResolveNPC DisplayName + alias Officer Graves [2] DialogueNPCs | live Talk Officer Graves count 1 | VERIFIED |
| Setting Sail | 3 | Purchase | Rowboat | Purchase | ResolveShop/Item | live Purchase Rowboat count 1 | VERIFIED |
| Setting Sail | 4 | Spawn | Rowboat | Travel | Island | live Spawn Rowboat count 1 | VERIFIED |
| Setting Sail | 5 | Talk | Mayor Kiyoshi | Talk | ResolveNPC | live Talk Mayor Kiyoshi count 1 | VERIFIED |
| A Joke Gone Too Far | 1 | Talk | Clowny D. Clown | Talk | ResolveNPC | live Talk Clowny D. Clown count 1 | VERIFIED |
| A Joke Gone Too Far | 2 | Kill | Clown | Kill | ResolveEnemy | live Kill Clown count 7 | VERIFIED |
| A Joke Gone Too Far | 3 | Talk | Clowny D. Clown | Talk | ResolveNPC | live Talk Clowny D. Clown count 1 | VERIFIED |
| Sabotage The Cannon | 1 | Required | Level | Equip | ResolveShop/Item | live Required Level count 1 | VERIFIED |
| Sabotage The Cannon | 2 | Talk | Clowny D. Clown | Talk | ResolveNPC | live Talk Clowny D. Clown count 1 | VERIFIED |
| Sabotage The Cannon | 3 | Destroy | Muggy Cannon | Kill | ResolveEnemy | live Destroy Muggy Cannon count 1 | VERIFIED |
| Sabotage The Cannon | 4 | Talk | Clowny D. Clown | Talk | ResolveNPC | live Talk Clowny D. Clown count 1 | VERIFIED |
| Lion's Victim | 1 | Required | Level | Equip | ResolveShop/Item | live Required Level count 1 | VERIFIED |
| Lion's Victim | 2 | Talk | Stephon | Talk | ResolveNPC | live Talk Stephon count 1 | VERIFIED |
| Lion's Victim | 3 | Kill | Circus Lion | Kill | ResolveEnemy | live Kill Circus Lion count 1 | VERIFIED |
| Lion's Victim | 3 | Kill | Beast Tamer | Kill | ResolveEnemy | live Kill Beast Tamer count 1 | VERIFIED |
| Lion's Victim | 4 | Talk | Stephon | Talk | ResolveNPC | live Talk Stephon count 1 | VERIFIED |
| Stephon's Tormentor | 1 | Required | Level | Equip | ResolveShop/Item | live Required Level count 1 | VERIFIED |
| Stephon's Tormentor | 2 | Talk | Stephon | Talk | ResolveNPC | live Talk Stephon count 1 | VERIFIED |
| Stephon's Tormentor | 3 | Kill | \ | Kill | ResolveEnemy | live Kill \ count 1 | VERIFIED |
| Stephon's Tormentor | 4 | Talk | Stephon | Talk | ResolveNPC | live Talk Stephon count 1 | VERIFIED |
| Butcher's Business | 1 | Required | Level | Equip | ResolveShop/Item | live Required Level count 1 | VERIFIED |
| Butcher's Business | 2 | Talk | Billy B. | Talk | ResolveNPC | live Talk Billy B. count 1 | VERIFIED |
| Butcher's Business | 3 | Kill | Killer Clown | Kill | ResolveEnemy | live Kill Killer Clown count 7 | VERIFIED |
| Butcher's Business | 4 | Talk | Billy B. | Talk | ResolveNPC | live Talk Billy B. count 1 | VERIFIED |
| Circus Suppliers | 1 | Required | Level | Equip | ResolveShop/Item | live Required Level count 1 | VERIFIED |
| Circus Suppliers | 2 | Talk | Mayor Kiyoshi | Talk | ResolveNPC | live Talk Mayor Kiyoshi count 1 | VERIFIED |
| Circus Suppliers | 3 | Kill | Circus Supplier | Kill | ResolveEnemy | live Kill Circus Supplier count 2 | VERIFIED |
| Circus Suppliers | 4 | Talk | Mayor Kiyoshi | Talk | ResolveNPC | live Talk Mayor Kiyoshi count 1 | VERIFIED |
| Clown Captives | 1 | Talk | Mayor Kiyoshi | Talk | ResolveNPC | live Talk Mayor Kiyoshi count 1 | VERIFIED |
| Clown Captives | 2 | Free | Child Captive | Interact | ResolveShop/Item | live Free Child Captive count 2 | VERIFIED |
| Clown Captives | 2 | Free | Adult Captive | Interact | ResolveShop/Item | live Free Adult Captive count 4 | VERIFIED |
| Clown Captives | 3 | Talk | Mayor Kiyoshi | Talk | ResolveNPC | live Talk Mayor Kiyoshi count 1 | VERIFIED |
| Revenge of the Nibblebottom | 1 | Talk | Johnny Nibblebottom | Talk | ResolveNPC | live Talk Johnny Nibblebottom count 1 | VERIFIED |
| Revenge of the Nibblebottom | 2 | Kill | Clown Officer | Kill | ResolveEnemy | live Kill Clown Officer count 5 | VERIFIED |
| Revenge of the Nibblebottom | 2 | Destroy | Air Balloon | Kill | ResolveEnemy | live Destroy Air Balloon count 1 | VERIFIED |
| Revenge of the Nibblebottom | 3 | Talk | Johnny Nibblebottom | Talk | ResolveNPC | live Talk Johnny Nibblebottom count 1 | VERIFIED |
| Escort The Mayor | 1 | Required | Level | Equip | ResolveShop/Item | live Required Level count 1 | VERIFIED |
| Escort The Mayor | 2 | Talk | Mayor Kiyoshi | Talk | ResolveNPC | live Talk Mayor Kiyoshi count 1 | VERIFIED |
| Escort The Mayor | 3 | Escort | Mayor Kiyoshi | Escort | ResolveNPC | live Escort Mayor Kiyoshi count 1 | RUNTIME_REQUIRED — NeverSkip; do not fake Talk/Kill |
| Escort The Mayor | 4 | Talk | Mayor Kiyoshi [2] | Talk | ResolveNPC | live Talk Mayor Kiyoshi [2] count 1 | VERIFIED |
| Mayor's Stache | 1 | Talk | Mayor Kiyoshi [2] | Talk | ResolveNPC | live Talk Mayor Kiyoshi [2] count 1 | VERIFIED |
| Mayor's Stache | 2 | CollectLocalItem | Mayor's Mustache | Collect | ResolveShop/Item | live CollectLocalItem Mayor's Mustache count 1 | VERIFIED |
| Mayor's Stache | 3 | Talk | Mayor Kiyoshi [2] | Talk | ResolveNPC | live Talk Mayor Kiyoshi [2] count 1 | VERIFIED |
| Clown Town's Militia | 1 | Talk | Mayor Kiyoshi [2] | Talk | ResolveNPC | live Talk Mayor Kiyoshi [2] count 1 | VERIFIED |
| Clown Town's Militia | 2 | CollectLocalItem | Sturdy Stick | Collect | ResolveShop/Item | live CollectLocalItem Sturdy Stick count 1 | VERIFIED |
| Clown Town's Militia | 2 | CollectLocalItem | Tomato Crate | Collect | ResolveShop/Item | live CollectLocalItem Tomato Crate count 1 | VERIFIED |
| Clown Town's Militia | 2 | CollectLocalItem | Fist Wraps | Collect | ResolveShop/Item | live CollectLocalItem Fist Wraps count 1 | VERIFIED |
| Clown Town's Militia | 3 | Talk | Clown Town Angry Civilian 1 | Talk | ResolveNPC | live Talk Clown Town Angry Civilian 1 count 1 | VERIFIED |
| Clown Town's Militia | 3 | Talk | Clown Town Angry Civilian 2 | Talk | ResolveNPC | live Talk Clown Town Angry Civilian 2 count 1 | VERIFIED |
| Clown Town's Militia | 3 | Talk | Clown Town Angry Civilian 3 | Talk | ResolveNPC | live Talk Clown Town Angry Civilian 3 count 1 | VERIFIED |
| The Ringmaster | 1 | Required | Level | Equip | ResolveShop/Item | live Required Level count 1 | VERIFIED |
| The Ringmaster | 2 | Talk | Mayor Kiyoshi [2] | Talk | ResolveNPC | live Talk Mayor Kiyoshi [2] count 1 | VERIFIED |
| The Ringmaster | 3 | Kill | Choppy The Clown | Kill | ResolveEnemy | live Kill Choppy The Clown count 1 | VERIFIED |
| The Ringmaster | 4 | Talk | Mayor Kiyoshi [2] | Talk | ResolveNPC | live Talk Mayor Kiyoshi [2] count 1 | VERIFIED |
| Journey to Maple Village | 1 | Talk | Mayor Kiyoshi | Talk | ResolveNPC | live Talk Mayor Kiyoshi count 1 | VERIFIED |
| Journey to Maple Village | 2 | Required | Level | Equip | ResolveShop/Item | live Required Level count 70 | VERIFIED |
| Journey to Maple Village | 3 | Reach Maple Village | Set sail for Maple Village. | UNKNOWN | — | live Reach Maple Village  count 1 | UNVERIFIED_HANDLER |
| The Island's Protector | 1 | Kill | Captain Esopo | Kill | ResolveEnemy | live Kill Captain Esopo count 1 | VERIFIED |
| The Island's Protector | 2 | Talk | Captain Esopo | Talk | ResolveNPC | live Talk Captain Esopo count 1 | VERIFIED |
| Proof of Pirates | 1 | Kill | Black Noir Pirate | Kill | ResolveEnemy | live Kill Black Noir Pirate count 7 | VERIFIED |
| Proof of Pirates | 2 | Deliver Object | Stolen Goods | UNKNOWN | — | live Deliver Object Stolen Goods count 2 | UNVERIFIED_HANDLER |
| Proof of Pirates | 3 | Talk | Captain Esopo | Talk | ResolveNPC | live Talk Captain Esopo count 1 | VERIFIED |
| Something Isn't Right | 1 | Talk | Farmer Joe | Talk | ResolveNPC | live Talk Farmer Joe count 1 | VERIFIED |
| Something Isn't Right | 1 | Talk | Tara | Talk | ResolveNPC | live Talk Tara count 1 | VERIFIED |
| Something Isn't Right | 1 | Talk | Martha | Talk | ResolveNPC | live Talk Martha count 1 | VERIFIED |
| Something Isn't Right | 2 | Investigate The Footsteps (1) | Follow the trail of footsteps back to their origin. | UNKNOWN | — | live Investigate The Footsteps (1)  count 1 | UNVERIFIED_HANDLER |
| Something Isn't Right | 3 | Destroy | Supply Crate | Kill | ResolveEnemy | live Destroy Supply Crate count 2 | VERIFIED |
| Something Isn't Right | 3 | Kill | Black Noir Pirate | Kill | ResolveEnemy | live Kill Black Noir Pirate count 2 | VERIFIED |
| Something Isn't Right | 4 | Investigate The Footsteps (2) | Follow the second trail of footsteps back to their origin. | UNKNOWN | — | live Investigate The Footsteps (2)  count 1 | UNVERIFIED_HANDLER |
| Something Isn't Right | 5 | Destroy | Supply Crate | Kill | ResolveEnemy | live Destroy Supply Crate count 2 | VERIFIED |
| Something Isn't Right | 5 | Kill | Black Noir Pirate | Kill | ResolveEnemy | live Kill Black Noir Pirate count 2 | VERIFIED |
| Something Isn't Right | 6 | Talk | Captain Esopo | Talk | ResolveNPC | live Talk Captain Esopo count 1 | VERIFIED |
| Pirate Instructions | 1 | Collect | Pirate Instructions | Collect | ResolveShop/Item | live Collect Pirate Instructions count 1 | VERIFIED |
| Pirate Instructions | 2 | Talk | Captain Esopo | Talk | ResolveNPC | live Talk Captain Esopo count 1 | VERIFIED |
| The Wandering Hypnotist | 1 | Wake | Clucking Villager | Interact | ResolveShop/Item | live Wake Clucking Villager count 1 | VERIFIED |
| The Wandering Hypnotist | 1 | Check On | Sleeping Villager | Interact | ResolveShop/Item | live Check On Sleeping Villager count 1 | VERIFIED |
| The Wandering Hypnotist | 1 | CollectLocalItem | Bucket of Water | Collect | ResolveShop/Item | live CollectLocalItem Bucket of Water count 1 | VERIFIED |
| The Wandering Hypnotist | 1 | Wake | Sleeping Villager | Interact | ResolveShop/Item | live Wake Sleeping Villager count 1 | VERIFIED |
| The Wandering Hypnotist | 2 | Kill | \ | Kill | ResolveEnemy | live Kill \ count 1 | VERIFIED |
| The Wandering Hypnotist | 3 | Talk | Captain Esopo | Talk | ResolveNPC | live Talk Captain Esopo count 1 | VERIFIED |
| The Beast of Maple Village | 1 | Investigate The Wreckage | Investigate the wreckage the beast left behind. | UNKNOWN | — | live Investigate The Wreckage  count 1 | UNVERIFIED_HANDLER |
| The Beast of Maple Village | 2 | Investigate The Beast's Den | Follow the beast's tracks back to its den. | UNKNOWN | — | live Investigate The Beast's Den  count 1 | UNVERIFIED_HANDLER |
| The Beast of Maple Village | 3 | Kill | The Beast? | Kill | ResolveEnemy | live Kill The Beast? count 1 | VERIFIED |
| The Beast of Maple Village | 3 | Talk | Barry | Talk | ResolveNPC | live Talk Barry count 1 | VERIFIED |
| The Beast of Maple Village | 4 | Talk | Captain Esopo | Talk | ResolveNPC | live Talk Captain Esopo count 1 | VERIFIED |
| Missing Servants | 1 | Talk | Kuro | Talk | ResolveNPC | live Talk Kuro count 1 | VERIFIED |
| Missing Servants | 2 | Investigate The Garden | The butler claims he dismissed the entire staff. Search the mansion grounds for any trace of the missing servants. | UNKNOWN | — | live Investigate The Garden  count 1 | UNVERIFIED_HANDLER |
| Missing Servants | 2 | Investigate The Fountain | The butler claims he dismissed the entire staff. Search the mansion grounds for any trace of the missing servants. | UNKNOWN | — | live Investigate The Fountain  count 1 | UNVERIFIED_HANDLER |
| Missing Servants | 3 | CollectLocalItem | Servant's Journal | Collect | ResolveShop/Item | live CollectLocalItem Servant's Journal count 1 | VERIFIED |
| Missing Servants | 4 | Talk | Captain Esopo | Talk | ResolveNPC | live Talk Captain Esopo count 1 | VERIFIED |
| Expose the Butler | 1 | Investigate The Garden | The journal was dumped in the garden hedges — whoever dropped it may still be hiding on the grounds. Search the mansion garden. | UNKNOWN | — | live Investigate The Garden  count 1 | UNVERIFIED_HANDLER |
| Expose the Butler | 2 | Talk | Frightened Servant | Talk | ResolveNPC | live Talk Frightened Servant count 1 | VERIFIED |
| Expose the Butler | 2 | Kill | Scratch | Kill | ResolveEnemy | live Kill Scratch count 1 | VERIFIED |
| Expose the Butler | 2 | Kill | Grab | Kill | ResolveEnemy | live Kill Grab count 1 | VERIFIED |
| Expose the Butler | 3 | Talk | Frightened Servant | Talk | ResolveNPC | live Talk Frightened Servant count 1 | VERIFIED |
| Expose the Butler | 4 | Talk | Captain Esopo | Talk | ResolveNPC | live Talk Captain Esopo count 1 | VERIFIED |
| Raid Preparations | 1 | Talk | Remy | Talk | ResolveNPC | live Talk Remy count 1 | VERIFIED |
| Raid Preparations | 1 | Talk | Farmer Joe | Talk | ResolveNPC | live Talk Farmer Joe count 1 | VERIFIED |
| Raid Preparations | 1 | Talk | Pip | Talk | ResolveNPC | live Talk Pip count 1 | VERIFIED |
| Raid Preparations | 1 | Talk | Lady Maia | Talk | ResolveNPC | live Talk Lady Maia count 1 | VERIFIED |
| Raid Preparations | 2 | Collect | Lead Ore | Collect | ResolveShop/Item | live Collect Lead Ore count 6 | VERIFIED |
| Raid Preparations | 3 | Talk | Captain Esopo | Talk | ResolveNPC | live Talk Captain Esopo count 1 | VERIFIED |
| Stocked for a Siege | 1 | Donate | Dish | Deliver | ResolveNPC | live Donate Dish count 6 | VERIFIED |
| Stocked for a Siege | 2 | Talk | Captain Esopo | Talk | ResolveNPC | live Talk Captain Esopo count 1 | VERIFIED |
| Destroy the Signalers | 1 | Destroy | North Camp Signal Fire | Kill | ResolveEnemy | live Destroy North Camp Signal Fire count 1 | VERIFIED |
| Destroy the Signalers | 1 | Destroy | South Camp Signal Fire | Kill | ResolveEnemy | live Destroy South Camp Signal Fire count 1 | VERIFIED |
| Destroy the Signalers | 1 | Destroy | Overlook Signal Fire | Kill | ResolveEnemy | live Destroy Overlook Signal Fire count 1 | VERIFIED |
| Destroy the Signalers | 2 | Talk | Captain Esopo | Talk | ResolveNPC | live Talk Captain Esopo count 1 | VERIFIED |
| The Black Noir Raid | 1 | Defend | Black Noir Raid | UNKNOWN | — | live Defend Black Noir Raid count 1 | UNVERIFIED_HANDLER |
| The Black Noir Raid | 2 | Talk | Lady Maia | Talk | ResolveNPC | live Talk Lady Maia count 1 | VERIFIED |
| Bullies in Suits | 1 | Kill | Corrupt Marine | Kill | ResolveEnemy | live Kill Corrupt Marine count 6 | VERIFIED |
| Bullies in Suits | 2 | Talk | Koro | Talk | ResolveNPC | live Talk Koro count 1 | VERIFIED |
| Officer Termination | 1 | Kill | Corrupt Marine Officer | Kill | ResolveEnemy | live Kill Corrupt Marine Officer count 7 | VERIFIED |
| Officer Termination | 2 | Talk | Maeve | Talk | ResolveNPC | live Talk Maeve count 1 | VERIFIED |
| Granny's Nemesis | 1 | Kill | Blonde Goblin | Kill | ResolveEnemy | live Kill Blonde Goblin count 1 | VERIFIED |
| Granny's Nemesis | 1 | Kill | Corrupt Guard | Kill | ResolveEnemy | live Kill Corrupt Guard count 2 | VERIFIED |
| Granny's Nemesis | 2 | Talk | Granny Todo | Talk | ResolveNPC | live Talk Granny Todo count 1 | VERIFIED |
| Tyrannical Captain | 1 | Kill | Axe-Hand Logan | Kill | ResolveEnemy | live Kill Axe-Hand Logan count 1 | VERIFIED |
| This Is Personal | 1 | Kill | Clown | Kill | ResolveEnemy | live Kill Clown count 7 | VERIFIED |
| This Is Personal | 2 | Talk | Clowny D. Clown | Talk | ResolveNPC | live Talk Clowny D. Clown count 1 | VERIFIED |
| Cat Problem | 1 | Kill | Circus Lion | Kill | ResolveEnemy | live Kill Circus Lion count 1 | VERIFIED |
| Cat Problem | 1 | Kill | Beast Tamer | Kill | ResolveEnemy | live Kill Beast Tamer count 1 | VERIFIED |
| Cat Problem | 2 | Talk | Stephon | Talk | ResolveNPC | live Talk Stephon count 1 | VERIFIED |
| Billy's Business | 1 | Kill | Killer Clown | Kill | ResolveEnemy | live Kill Killer Clown count 7 | VERIFIED |
| Billy's Business | 2 | Talk | Billy B. | Talk | ResolveNPC | live Talk Billy B. count 1 | VERIFIED |
| Nibblebottom's Revenge | 1 | Kill | Clown Officer | Kill | ResolveEnemy | live Kill Clown Officer count 5 | VERIFIED |
| Nibblebottom's Revenge | 2 | Talk | Johnny Nibblebottom | Talk | ResolveNPC | live Talk Johnny Nibblebottom count 1 | VERIFIED |
| Choppy The Clown | 1 | Kill | Choppy The Clown | Kill | ResolveEnemy | live Kill Choppy The Clown count 1 | VERIFIED |
| Choppy The Clown | 2 | Talk | Mayor Kiyoshi [2] | Talk | ResolveNPC | live Talk Mayor Kiyoshi [2] count 1 | VERIFIED |
| Clear the Road | 1 | Kill | Black Noir Pirate | Kill | ResolveEnemy | live Kill Black Noir Pirate count 8 | VERIFIED |
| Clear the Road | 2 | Talk | Nell | Talk | ResolveNPC | live Talk Nell count 1 | VERIFIED |
| Peace of Mind | 1 | Kill | Black Noir Officer | Kill | ResolveEnemy | live Kill Black Noir Officer count 5 | VERIFIED |
| Peace of Mind | 2 | Talk | Gus | Talk | ResolveNPC | live Talk Gus count 1 | VERIFIED |

## Notes

- **Officer Graves** quest target / DisplayName ≠ instance Name. Instance is `Officer Graves [2]`. ReplicatedStorage `Officer Graves` is character-create.
- **Escort The Mayor**: handler `Escort`, `NeverSkip`. Follow only. Do not substitute Talk/Kill.
- **The Wandering Hypnotist**: `NeverSkip`. Kill target verified `"Hypnotist" Mango`.
- **Stephon's Tormentor**: Kill target verified `"Barrel Clown" Binki`.
- Resume from any live quest / completed set. Do not assume lv0.
- Open Logbook: no verified remote; enable PlayerGui.Logbook / menu button.
- Craft / unverified types: `UNKNOWN_OBJECTIVE` + stop that loop.
