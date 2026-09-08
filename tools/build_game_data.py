#!/usr/bin/env python3
"""Compile research JSON into Game/GeneratedData.lua. Do not edit the Lua by hand."""

from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path
import subprocess
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from quest_audit_lib import (  # noqa: E402
    ANCHOR_STORY,
    CLOWN_STORY,
    MAIN_ROUTE,
    MAPLE_STORY,
    ROOT,
    SHOP,
    SKIP,
    classify_all,
    coverage,
    item_specs,
    load_quests,
    subgoals,
)

OUT_LUA = ROOT / "Game" / "GeneratedData.lua"
OUT_SNAP = ROOT / "research" / "_generated_snapshot.json"

RUNTIME_OVERRIDES = {
    ("Escort The Mayor", "Escort", "Mayor Kiyoshi"): {
        "status": "IMPLEMENTED",
        "handler": "Quest.escort",
        "marker": "Mayor Kiyoshi Escort",
        "note": "CS tag Mayor Kiyoshi - PlayerName; dest Mayor Kiyoshi Escort; defend Clown Pirates",
    },
    ("Mina's Request", "Escort", "Mina"): {
        "status": "IMPLEMENTED",
        "handler": "Quest.escort",
        "marker": "Mina Escort",
    },
    ("Clown Imposter", "Escort", "Fake Clown"): {
        "status": "IMPLEMENTED",
        "handler": "Quest.escort",
        "marker": "Clown Imposter Escort",
    },
}

TUTORIALS = {
    "PunchTraining": {"Type": "ActionRequired", "Quest": "Introduction", "Status": "IMPLEMENTED"},
    "EquipStrongPunch": {"Type": "UISelection", "Quest": "Basics", "Status": "RUNTIME_VERIFIED"},
    "CastStrongPunch": {"Type": "InputRequired", "Quest": "Basics", "Status": "RUNTIME_VERIFIED"},
    "InvestStats": {"Type": "ActionRequired", "Quest": "Basics", "Status": "RUNTIME_VERIFIED"},
    "ForceOpenLogbook": {"Type": "ActionRequired", "Quest": "Basics", "Status": "RUNTIME_VERIFIED"},
    "EquipFlintlock": {"Type": "EquipRequired", "Quest": "Gearing Up", "Status": "IMPLEMENTED"},
    "SellWatch": {"Type": "Dialogue", "Quest": "Gearing Up", "Status": "IMPLEMENTED"},
    "UpgradeFlintlock": {"Type": "ActionRequired", "Quest": "First Upgrade", "Status": "IMPLEMENTED"},
    "EquippedWeapon": {"Type": "ActionRequired", "Quest": "First Upgrade", "Status": "IMPLEMENTED"},
    "SmeltTutorial": {"Type": "ActionRequired", "Quest": "First Upgrade", "Status": "IMPLEMENTED"},
    "CraftStoneRing": {"Type": "UISelection", "Quest": "Miners Stone Ring", "Status": "PARTIAL"},
    "UnsheathWeapon": {"Type": "InputRequired", "Quest": "", "Status": "UNRESOLVED"},
    "UpgradeSkill": {"Type": "ActionRequired", "Quest": "", "Status": "UNRESOLVED"},
    "Pets": {"Type": "ActionRequired", "Quest": "", "Status": "DISABLED"},
    "Mining": {"Type": "ContinueOverlay", "Quest": "First Upgrade", "Status": "IMPLEMENTED"},
    "SkillObtained": {"Type": "ContinueOverlay", "Quest": "Gearing Up", "Status": "IMPLEMENTED"},
}

REMOTES = {
    "Talk": {"Remote": "Events.ClientQuest", "Args": '("Talk", DisplayName)', "Status": "VERIFIED", "Banned": False},
    "AutomaticTalk": {"Remote": "Events.ClientQuest", "Args": '("Automatic Talk", DisplayName)', "Status": "VERIFIED", "Banned": False},
    "BeginAutomatic": {"Remote": "Events.ClientQuest", "Args": '("BeginAutomatic", questName)', "Status": "VERIFIED", "Banned": False},
    "BeginQuest": {"Remote": "Events.BeginQuest", "Args": "", "Status": "BANNED", "Banned": True},
    "StatInvest": {"Remote": "Events.StatPoints", "Args": '("Invest", name, n)', "Status": "VERIFIED", "Banned": False},
    "GetStats": {"Remote": "Events.GetStats", "Args": "()", "Status": "VERIFIED", "Banned": False},
    "ShopPurchase": {"Remote": "Events.Shop", "Args": '("Purchase", part, qty)', "Status": "VERIFIED", "Banned": False},
    "SellItem": {"Remote": "Events.SellItem", "Args": "(key[, amount])", "Status": "VERIFIED", "Banned": False},
    "Upgrade": {"Remote": "Events.Upgrade", "Args": '("Upgrade", key)', "Status": "VERIFIED", "Banned": False},
    "GetData": {"Remote": "Events.GetData", "Args": '("Quests", "Completed Quests")', "Status": "VERIFIED", "Banned": False},
    "DashInput": {"Remote": "Events.Input", "Args": '{Input="Dash", ID="Dash", State=bool, Character}', "Status": "VERIFIED", "Banned": False},
}

DIALOGUE = {
    "DeclineExact": ["no", "no.", "decline", "cancel", "bye", "goodbye", "never mind", "not now"],
    "DeclinePhrases": ["good luck with that"],
    "AcceptExact": ["accept", "yes", "yeah", "thank you", "thanks"],
}

ISLANDS = [
    "Anchor Town",
    "Clown Town",
    "Maple Village",
    "Tutorial",
    "Fighting Style",
    "Crew",
    "Skill Mastery",
]


def git_short() -> str:
    try:
        return subprocess.check_output(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=ROOT,
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip() or "unknown"
    except Exception:
        return "unknown"


def esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ")


def lua_val(v, depth=1) -> str:
    if v is None:
        return "nil"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, int):
        return str(v)
    if isinstance(v, float):
        return str(v)
    if isinstance(v, str):
        return '"' + esc(v) + '"'
    pad = "\t" * depth
    inner = "\t" * (depth + 1)
    if isinstance(v, list):
        if not v:
            return "{}"
        if all(not isinstance(x, (dict, list)) for x in v):
            return "{ " + ", ".join(lua_val(x, depth + 1) for x in v) + " }"
        parts = [lua_val(x, depth + 1) for x in v]
        return "{\n" + ",\n".join(inner + p for p in parts) + ",\n" + pad + "}"
    if isinstance(v, dict):
        if not v:
            return "{}"
        parts = []
        for k, val in v.items():
            key = k if isinstance(k, str) and k.isidentifier() else f'[{lua_val(str(k))}]'
            parts.append(f"{key} = {lua_val(val, depth + 1)}")
        return "{\n" + ",\n".join(inner + p for p in parts) + ",\n" + pad + "}"
    return "nil"


def load_json(rel: str):
    p = ROOT / rel
    return json.loads(p.read_text(encoding="utf-8"))


def start_method(q: dict) -> dict:
    automatic = q.get("automatic") is True
    qtype = q.get("type") or ""
    accept = q.get("accept") or {}
    npc = accept.get("npc") or q.get("unlock_contact")
    if q["name"] in SKIP:
        kind = "UNRESOLVED_START"
    elif automatic:
        kind = "AUTOMATIC"
    elif npc:
        kind = "NPC_START"
    else:
        kind = "UNRESOLVED_START"
    return {
        "Kind": kind,
        "Automatic": automatic,
        "NPC": npc,
        "TurnIn": (q.get("turnin") or {}).get("npc"),
        "Repeatable": qtype == "Repeatable",
    }


def aggregate_items(rows: list[dict], raw_items: list) -> dict:
    items = {}
    for spec_name, spec in item_specs(rows).items():
        items[spec_name] = {
            "Name": spec_name,
            "Method": spec.get("method") or "UNKNOWN",
            "Source": spec.get("source"),
            "Location": spec.get("source_location"),
            "Gold": spec.get("gold") if isinstance(spec.get("gold"), int) else SHOP.get(spec_name),
            "Keep": spec.get("method") not in {"ShopPurchase"} or spec_name in SHOP,
            "Policy": "PROGRESSION" if spec.get("method") else "UNKNOWN",
        }
    for row in raw_items:
        name = row.get("item")
        if not name:
            continue
        cur = items.setdefault(
            name,
            {
                "Name": name,
                "Method": "UNKNOWN",
                "Source": None,
                "Location": row.get("island"),
                "Gold": SHOP.get(name),
                "Keep": True,
                "Policy": "UNKNOWN",
            },
        )
        cur.setdefault("QuestUse", [])
        qn = row.get("source_quest")
        if qn and qn not in cur["QuestUse"]:
            cur["QuestUse"].append(qn)
        if cur["Policy"] == "UNKNOWN" and row.get("item_type"):
            cur["Policy"] = "QUEST_REQUIRED"
    for name, rec in items.items():
        if rec.get("Policy") == "UNKNOWN":
            rec["Keep"] = True
    return items


def aggregate_skills(raw: list) -> dict:
    out = {}
    for row in raw:
        name = row.get("name")
        if not name:
            continue
        rec = out.setdefault(
            name,
            {"Name": name, "Kinds": [], "Quests": [], "Island": row.get("island")},
        )
        kind = row.get("kind")
        if kind and kind not in rec["Kinds"]:
            rec["Kinds"].append(kind)
        qn = row.get("source_quest")
        if qn and qn not in rec["Quests"]:
            rec["Quests"].append(qn)
    return out


def apply_overrides(rows: list[dict]) -> None:
    for r in rows:
        key = (r.get("quest"), r.get("objective"), r.get("target"))
        ov = RUNTIME_OVERRIDES.get(key)
        if ov:
            r.update(ov)


def compact_quest(q: dict, start: dict) -> dict:
    return {
        "Name": q["name"],
        "Type": q.get("type"),
        "Island": q.get("island"),
        "Automatic": q.get("automatic") is True,
        "AcceptLevel": q.get("accept_level") or 0,
        "RangeMin": q.get("range_min"),
        "RangeMax": q.get("range_max"),
        "NeedLevel": q.get("need_level") or 0,
        "Prerequisites": list(q.get("prerequisites") or []),
        "AcceptNPC": start.get("NPC"),
        "TurnInNPC": start.get("TurnIn"),
        "Start": start.get("Kind"),
        "Repeatable": start.get("Repeatable") is True,
        "Exp": q.get("exp"),
        "Gold": q.get("gold"),
        "Unlocks": q.get("unlocks_next"),
    }


def compact_stage(r: dict) -> dict:
    return {
        "Q": r["quest"],
        "S": r["stage"],
        "T": r["objective"],
        "G": r["goal"],
        "A": r["target"],
        "N": r["amount"],
        "M": r.get("acquire"),
        "Src": r.get("source"),
        "Loc": r.get("source_location"),
        "Mk": r.get("marker"),
        "H": r.get("handler"),
        "V": r.get("validation"),
        "St": r.get("status"),
    }


def compact_npc(name: str, rec: dict) -> dict:
    return {
        "Name": name,
        "Islands": rec.get("islands") or [],
        "Accept": rec.get("accept_quests") or [],
        "TurnIn": rec.get("turnin_quests") or [],
        "Talk": rec.get("talk_in_stages") or [],
        "Markers": rec.get("marker_quests") or [],
    }


def main() -> None:
    quests = load_quests()
    rows = classify_all(quests)
    apply_overrides(rows)
    npcs = load_json("research/npcs.json")
    raw_items = load_json("research/items.json")
    raw_skills = load_json("research/skills.json")
    items = aggregate_items(rows, raw_items)
    skills = aggregate_skills(raw_skills)
    starts = {q["name"]: start_method(q) for q in quests}
    quest_tbl = {q["name"]: compact_quest(q, starts[q["name"]]) for q in quests}
    npc_tbl = {n: compact_npc(n, rec) for n, rec in npcs.items()}
    cov = coverage(rows)
    version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
    commit = git_short()
    built_at = datetime.now().astimezone().isoformat(timespec="seconds")

    payload = {
        "version": version,
        "commit": commit,
        "built_at": built_at,
        "coverage": cov,
        "quests": len(quest_tbl),
        "stages": len(rows),
        "npcs": len(npc_tbl),
        "items": len(items),
        "skills": len(skills),
    }
    OUT_SNAP.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    stages_map = {}
    for r in rows:
        key = f"{r['quest']}|{r['stage']}|{r['objective']}|{r['target']}"
        stages_map[key] = compact_stage(r)

    lua = []
    lua.append("-- GENERATED by tools/build_game_data.py — DO NOT MANUALLY EDIT")
    lua.append(f"-- Version: {version} Commit: {commit} BuiltAt: {built_at}")
    lua.append("return function(GB)")
    lua.append("	local M = {}")
    lua.append(f"	M.Version = {lua_val(version)}")
    lua.append(f"	M.Commit = {lua_val(commit)}")
    lua.append(f"	M.BuiltAt = {lua_val(built_at)}")
    lua.append(f"	M.Islands = {lua_val(ISLANDS)}")
    lua.append("	M.Story = {")
    lua.append(f"		Anchor = {lua_val(ANCHOR_STORY, 2)},")
    lua.append(f"		Clown = {lua_val(CLOWN_STORY, 2)},")
    lua.append(f"		Maple = {lua_val(MAPLE_STORY, 2)},")
    lua.append(f"		Main = {lua_val(MAIN_ROUTE, 2)},")
    lua.append("	}")
    lua.append(f"	M.Skip = {lua_val(sorted(SKIP))}")
    lua.append(f"	M.Dialogue = {lua_val(DIALOGUE)}")
    lua.append(f"	M.Tutorials = {lua_val(TUTORIALS)}")
    lua.append(f"	M.Remotes = {lua_val(REMOTES)}")
    lua.append(f"	M.Shops = {lua_val(SHOP)}")
    lua.append(f"	M.Subgoals = {lua_val(subgoals())}")
    lua.append(f"	M.Coverage = {lua_val(cov)}")
    lua.append(f"	M.Quests = {lua_val(quest_tbl)}")
    lua.append(f"	M.NPCs = {lua_val(npc_tbl)}")
    lua.append(f"	M.Items = {lua_val(items)}")
    lua.append(f"	M.Skills = {lua_val(skills)}")
    lua.append(f"	M.Stages = {lua_val(stages_map)}")
    lua.append("	function M.quest(name)")
    lua.append("		return name and M.Quests[name]")
    lua.append("	end")
    lua.append("	function M.npc(name)")
    lua.append("		return name and M.NPCs[name]")
    lua.append("	end")
    lua.append("	function M.item(name)")
    lua.append("		return name and M.Items[name]")
    lua.append("	end")
    lua.append("	function M.skill(name)")
    lua.append("		return name and M.Skills[name]")
    lua.append("	end")
    lua.append("	function M.stage(quest, stage, typ, target)")
    lua.append('		local key = string.format("%s|%s|%s|%s", tostring(quest or ""), tostring(stage or 1), tostring(typ or ""), tostring(target or ""))')
    lua.append("		return M.Stages[key]")
    lua.append("	end")
    lua.append("	function M.remoteAllowed(action)")
    lua.append("		local r = action and M.Remotes[action]")
    lua.append("		return r and r.Banned ~= true and r.Status ~= \"BANNED\"")
    lua.append("	end")
    lua.append("	return M")
    lua.append("end")
    lua.append("")
    OUT_LUA.write_text("\n".join(lua), encoding="utf-8")
    print("[build_game_data] OK")
    print(f"[build_game_data] quests={len(quest_tbl)} stages={len(rows)} npcs={len(npc_tbl)} items={len(items)} skills={len(skills)}")
    print(f"[build_game_data] out={OUT_LUA.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
