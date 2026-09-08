# Remote Latency Audit — 1.2.0

Live 1.1.53 evidence: `PlayerData.pullStats` avg ~1237ms max ~2144ms; `refreshLive` max ~2145ms; `DecisionEngine.decide` inherited 290–365ms spikes.

## Cause

`DecisionEngine.decide` and `Stats.tick` called `GetStats` / `GetData` via `InvokeServer` on the scheduler thread.

## Fix

| Remote | Thread | Policy |
|---|---|---|
| GetStats | Broker worker | single-flight, minGap 0.35, cache to `_liveStats` |
| GetData Quests | Broker worker | single-flight, minGap 0.2, apply on generation match |
| Talk / ClientQuest | FireServer | rate 0.8, unchanged |
| AttackPlayer | FireServer | CanSwing / pulse, no extra gap on wrapper |
| StatPoints Invest | FireServer | rate 0.2 + canary |

Engine `refreshLive(false, "engine_cycle")` only reads cache and may **queue** a fetch. It does not wait for the remote.

Slow GetStats 2s: **does not stall** DecisionEngine / Combat / Travel.

Generation: `_GBKaitunGen` bump on reload drops in-flight results.
