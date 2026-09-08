# Full System Audit

**Version:** 1.1.42  
**Map:** `research/A_system_map.md`

Status vocabulary: RUNTIME_VERIFIED · STATIC_VERIFIED · IMPLEMENTED_UNVERIFIED · PARTIAL · DISABLED · UNRESOLVED.

| System | Status | Notes |
|---|---|---|
| Player progression | PARTIAL | Level/EXP/Gold/gates VERIFIED. Cap UNKNOWN. |
| Quests | STATIC_VERIFIED dump / PARTIAL runtime | 151 QuestInfo. Engine data-driven. 66 stages UNRESOLVED. |
| Tutorial | PARTIAL | Internal IDs from GeneratedData.Tutorials + Tutorial.lua. ContinueOverlay cached. |
| Stats | IMPLEMENTED_UNVERIFIED | GetStats + StatPoints event. Canary required before RUNTIME_VERIFIED. |
| Combat | IMPLEMENTED | CanSwing + SAFE_FAST. Dead target via Health/Dead. Heartbeat does not refresh quests. |
| Resolver | IMPLEMENTED_UNVERIFIED | Semantic indexes. Deep scan debug-only. |
| Inventory / item policy | PARTIAL | UNKNOWN=KEEP. Quest sell is explicit. |
| Equipment | PARTIAL | Flintlock/watch paths implemented. Clothing Equip RF UNRESOLVED. |
| Shop / boat | IMPLEMENTED | Purchase validates inventory delta. Rowboat VERIFIED. |
| Skills | PARTIAL | Scroll consume + Skill Equip. Style buy/unlock UNRESOLVED. |
| Mining / smelt | IMPLEMENTED | First Upgrade chain in Planner subgoals. |
| Fishing / farm / cook | PARTIAL | Used only if quest/upgrade requires. Cast/perfect window UNRESOLVED. |
| Chest / treasure | PARTIAL | Nearby opportunistic only. Dig args UNRESOLVED. |
| Fruit | PARTIAL | Pickup/store/equip verified paths. Eat disabled. |
| Haki | DISABLED | Trainer UNKNOWN. |
| Race / Trait | DISABLED | AutoRaceTrait false. Race FireServer UNRESOLVED. |
| Respawn | IMPLEMENTED | Phase machine. Real revive UI/remote. No fake Health. |
| Remotes | STATIC_VERIFIED | BeginQuest banned at Remotes.fire. |
| Codes / rewards | PARTIAL | Codes VERIFIED. Empty dailies skipped. |
| Recovery | IMPLEMENTED | Fingerprint defer after 4 identical fails. |
| Scheduler / ownership | PARTIAL | One engine decide. Respawn owns death. Talk/escort lock. Not a full single-owner token yet. |
| Bundle / version | IMPLEMENTED | VERSION == manifest == GeneratedData.Version. Loader abort on mismatch. |

## Bug-class audit (current HEAD, not assumed fixed)

| Class | Current HEAD |
|---|---|
| Dialogue `"No"` substring | REMOVED. Exact `no` / `no.` only. |
| Resolver recursive GetDescendants | Debug/diagnostic only. |
| Generic resolver mix | Separate enemy/NPC/object/marker indexes. |
| Global negative-cache clear | Scoped by kind+name. |
| Stale StatPoints MAX aggregate | Removed. First authoritative unused source. |
| Predicted AutoStats success | Canary before/after. Pause on fail. |
| Duplicate Stats tick | Engine owns `Stats.tick`. |
| PlayerGui full scan | Targeted FindFirstChild only. Cached label. |
| Quest InvokeServer in Heartbeat | No. Dirty + safety TTL. |
| Repeated getgc | Tutorial cache; once per unknown overlay class. |
| Attack corpse until despawn | `IsEnemyAlive` + `onTargetDead`. |
| Combat quest check on Heartbeat | Slow path only. |
| Blocked quest monopoly | `otherOrFarm`. |
| Combat before repeatable accept | Accept SM + REPEAT_START. |
| UI click = progression | Accept waits ACTIVE. Shop buy/sell checks inventory/gold. |
| Stale refs after death | Respawn rebind. |
| Duplicate loops after reload | `stopPreviousInstance` + gen bump. |
| Log growth | Ring + rotate + fingerprint cap. |
| Version/manifest mismatch | Fatal in loader + GeneratedData boot check. |
