#!/usr/bin/env python3
"""Static regression checks from prior live failures. Not a game session."""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FAILS: list[str] = []


def fail(msg: str) -> None:
    FAILS.append(msg)


def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding="utf-8")


def main() -> int:
    quest = read("Systems/Quest.lua")
    resolver = read("Game/Resolver.lua")
    combat = read("Systems/Combat.lua")
    stats = read("Systems/Stats.lua")
    respawn = read("Systems/Respawn.lua")
    remotes = read("Game/Remotes.lua")
    acquire = read("Systems/Acquire.lua")
    tutorial = read("Systems/Tutorial.lua")
    knowledge = read("Game/Knowledge.lua")
    engine = read("Progression/DecisionEngine.lua")
    recovery = read("Core/Recovery.lua")
    gen = read("Game/GeneratedData.lua")
    quest_data = read("Game/QuestData.lua")
    config = read("Config.lua")
    version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
    manifest = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))

    if version != manifest.get("version"):
        fail(f"VERSION {version} != manifest {manifest.get('version')}")
    if "Game/GeneratedData.lua" not in manifest.get("files", {}):
        fail("manifest missing GeneratedData")
    if "Game/Knowledge.lua" not in manifest.get("files", {}):
        fail("manifest missing Knowledge")

    if 'string.find' in quest and 'DECLINE' in quest:
        if re.search(r'string\.find\(\s*.*choice.*["\']No["\']', quest):
            fail("Quest dialogue still substring-matches No")
    if '["no"]' not in quest or '["no."]' not in quest:
        fail("DECLINE_EXACT missing no / no.")
    if "function M.unfinishedConditions" not in quest:
        fail("missing unfinishedConditions")
    if "function M.CurrentBlockers" not in quest:
        fail("missing CurrentBlockers")

    if '["Officer Graves"]' not in resolver:
        fail("Officer Graves alias missing")
    if "DebugResolverDeepScan" not in resolver:
        fail("Resolver deep scan not gated")
    if "indexes" not in resolver or "EnemyIndex" not in resolver:
        fail("Resolver semantic indexes missing")
    if "invalidateNegativeKindName" not in resolver:
        fail("scoped negative-cache invalidation missing")

    if "Pirate Fan Letter|3|Collect|Pirate Fan Letter" not in gen:
        fail("GeneratedData missing Pirate Fan Letter collect")
    if 'M = "EnemyDrop"' not in gen or 'Src = "Corrupt Marine"' not in gen:
        fail("Pirate Fan Letter acquire not EnemyDrop/Corrupt Marine")

    if "function M.IsEnemyAlive" not in combat:
        fail("IsEnemyAlive missing")
    if "function M.onTargetDead" not in combat:
        fail("onTargetDead missing")
    if "function M.pinHover" not in combat or "function M.travelHover" not in combat:
        fail("hover combat helpers missing")
    if 'def("CombatHoverHeight"' not in config:
        fail("CombatHoverHeight missing")
    if "questCombatDone" in combat and "Heartbeat:Connect" in combat:
        hb = combat.split("Heartbeat:Connect", 1)[1][:1200]
        if "questCombatDone" in hb or "refreshLive" in hb:
            fail("Heartbeat still refreshes quest state")

    if "Gearing Up" not in tutorial and "EquipFlintlock" not in tutorial:
        fail("Gearing Up / EquipFlintlock tutorial missing")
    if "SkillObtained" not in tutorial:
        fail("SkillObtained tutorial missing")
    if "Hide" in tutorial and "Enabled = false" in tutorial:
        # hide overlay to fake success is banned if used as primary complete
        if re.search(r"Enabled\s*=\s*false", tutorial) and "fake" in tutorial.lower():
            fail("tutorial hides GUI to fake success")

    if "Gate of Authority" not in quest and "Gate of Authority" not in knowledge:
        fail("Gate of Authority blocker missing")
    if "STAT_REQUIREMENT" not in knowledge:
        fail("Knowledge blockers missing STAT_REQUIREMENT")

    if "Granny" not in quest_data and "Granny's Nemesis" not in quest_data:
        fail("Granny's Nemesis start metadata missing")
    if "REPEAT_START" not in quest_data:
        fail("REPEAT_START missing")

    if "unfinishedConditions" not in quest:
        fail("multi-condition helper missing")

    if "Corrupt Guard" not in resolver and "Corrupt Marine" not in resolver:
        fail("Corrupt Guard / Marine aliases missing")

    if 'def("DebugResolverDeepScan", false)' not in config:
        fail("DebugResolverDeepScan default not false")

    if "function M.GetSnapshot" not in stats:
        fail("Stats.GetSnapshot missing")
    if "failed canary" not in stats:
        fail("Stats canary pause missing")
    if "GetDescendants" in stats:
        fail("Stats still uses GetDescendants")

    if 'phase = "ALIVE"' not in respawn:
        fail("Respawn phase machine missing")
    if "LoadCharacter" in respawn:
        fail("Respawn uses LoadCharacter")

    if 'if name == "BeginQuest"' not in remotes:
        fail("Remotes.fire does not ban BeginQuest")
    if "function M.neverBeginQuest" not in remotes:
        fail("neverBeginQuest missing")

    if "DebugAcquireDeepScan" not in acquire:
        fail("Acquire deep scan not gated")

    if "buildContext" not in knowledge:
        fail("Knowledge.buildContext missing")
    if "itemPolicy" not in knowledge:
        fail("Knowledge.itemPolicy missing")

    if "otherOrFarm" not in engine:
        fail("DecisionEngine blocked-goal fallback missing")
    if "fingerprint" not in recovery:
        fail("Recovery fingerprint defer missing")

    if "GENERATED by tools/build_game_data.py" not in gen:
        fail("GeneratedData not compiler output")

    if FAILS:
        print("FAIL")
        for row in FAILS:
            print(" ", row)
        return 1
    print("PASS regression_tests")
    print(f"  version={version}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
