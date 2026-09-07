#!/usr/bin/env python3
"""Generate quest_specs.json, Game/QuestSpecs.lua, matrix, coverage from QuestInfo."""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from quest_audit_lib import (  # noqa: E402
    ROOT,
    classify_all,
    coverage,
    item_specs,
    load_quests,
    subgoals,
)

OUT_JSON = ROOT / "research" / "quest_specs.json"
OUT_LUA = ROOT / "Game" / "QuestSpecs.lua"
OUT_MATRIX = ROOT / "research" / "QUEST_EXECUTION_MATRIX.md"
OUT_COV = ROOT / "research" / "QUEST_COVERAGE_REPORT.md"


def lua_str(s) -> str:
    if s is None:
        return "nil"
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ") + '"'


def lua_bool(v) -> str:
    return "true" if v else "false"


def write_specs_json(rows, items, subs) -> None:
    payload = {
        "version": "1.1.0",
        "source": "research/quests.json QuestInfo Studio dump",
        "items": items,
        "subgoals": subs,
        "stages": rows,
    }
    OUT_JSON.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def write_questspecs_lua(rows, items, subs) -> None:
    lines = [
        "-- Generated from research/quests.json. Item sources are QuestInfo markers/conditions only.",
        "return function(GB)",
        "	local M = { ITEMS = {}, STAGES = {}, SUBGOALS = {} }",
        "",
    ]
    for name, spec in sorted(items.items()):
        lines.append(
            "	M.ITEMS[{k}] = {{ method = {m}, source = {s}, location = {loc}, gold = {g} }}".format(
                k=lua_str(name),
                m=lua_str(spec.get("method")),
                s=lua_str(spec.get("source")),
                loc=lua_str(spec.get("source_location")),
                g=spec["gold"] if isinstance(spec.get("gold"), int) else "nil",
            )
        )
    lines.append("")
    for qn, stack in subs.items():
        lines.append(f"	M.SUBGOALS[{lua_str(qn)}] = {{")
        for step in stack:
            lines.append(
                "		{{ goal = {g}, item = {i}, method = {m}, amount = {a} }},".format(
                    g=lua_str(step.get("goal")),
                    i=lua_str(step.get("item")),
                    m=lua_str(step.get("method")),
                    a=step.get("amount") or 1,
                )
            )
        lines.append("	}")
    lines.append("")
    for r in rows:
        key = f"{r['quest']}|{r['stage']}|{r['objective']}|{r['target']}"
        lines.append(
            "	M.STAGES[{k}] = {{ quest = {q}, stage = {st}, island = {isl}, objective = {o}, goal = {g}, target = {t}, amount = {a}, acquire = {ac}, source = {s}, location = {loc}, marker = {mk}, handler = {h}, status = {stat} }}".format(
                k=lua_str(key),
                q=lua_str(r["quest"]),
                st=r["stage"],
                isl=lua_str(r["island"]),
                o=lua_str(r["objective"]),
                g=lua_str(r["goal"]),
                t=lua_str(r["target"]),
                a=r["amount"],
                ac=lua_str(r["acquire"]),
                s=lua_str(r["source"]),
                loc=lua_str(r["source_location"]),
                mk=lua_str(r["marker"]),
                h=lua_str(r["handler"]),
                stat=lua_str(r["status"]),
            )
        )
    lines += [
        "",
        "	function M.itemOf(name)",
        "		return name and M.ITEMS[name]",
        "	end",
        "",
        "	function M.lookup(quest, stage, typ, target)",
        "		if not quest then",
        "			return nil",
        "		end",
        '		local key = string.format("%s|%s|%s|%s", quest, tostring(stage or 1), tostring(typ or ""), tostring(target or ""))',
        "		local hit = M.STAGES[key]",
        "		if hit then",
        "			return hit",
        "		end",
        "		for _, row in pairs(M.STAGES) do",
        "			if row.quest == quest and row.target == target and row.objective == typ then",
        "				return row",
        "			end",
        "		end",
        "		if target and M.ITEMS[target] then",
        "			local it = M.ITEMS[target]",
        "			return {",
        "				quest = quest,",
        "				stage = stage,",
        "				goal = \"AcquireItem\",",
        "				target = target,",
        "				acquire = it.method,",
        "				source = it.source,",
        "				location = it.location,",
        "				handler = \"Acquire.AcquireItem\",",
        "			}",
        "		end",
        "		return nil",
        "	end",
        "",
        "	function M.subgoalsOf(quest)",
        "		return quest and M.SUBGOALS[quest]",
        "	end",
        "",
        "	return M",
        "end",
        "",
    ]
    OUT_LUA.write_text("\n".join(lines), encoding="utf-8")


def write_matrix(rows) -> None:
    lines = [
        "# Quest Execution Matrix",
        "",
        "Source: `research/quests.json` (QuestInfo Studio dump) + live Studio place `118635363908336`.",
        "Planner: Goal + AcquireMethod. Collect is not ResolveShop/Item.",
        "Pirate Fan Letter Collect source = **Corrupt Marine** (QuestInfo marker). Not Strong Marine.",
        "Runtime identity: world Graves = `Workspace.AA IMPORTANT.DialogueNPCs.Anchor Town.Officer Graves [2]` (DisplayName `Officer Graves`).",
        "Talk remote: `ClientQuest:FireServer(\"Talk\", DisplayName)` + `DialogueBindable:Fire(Configuration)` — never `BeginQuest`.",
        "",
        "| Quest | Stage | Island | ObjectiveType | Goal | Target | AcquireMethod | SourceTarget | SourceLocation | Prerequisites | Handler | Validation | Confidence | Status |",
        "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|",
    ]
    for r in rows:
        pr = ", ".join(r.get("prerequisites") or []) or "—"
        lines.append(
            "| {q} | {st} | {isl} | {o} | {g} | {t} | {ac} | {s} | {loc} | {pr} | {h} | {v} | {c} | {stat} |".format(
                q=r["quest"],
                st=r["stage"],
                isl=r["island"] or "—",
                o=r["objective"] or "—",
                g=r["goal"] or "—",
                t=r["target"] or "—",
                ac=r["acquire"] or "—",
                s=r["source"] or "—",
                loc=r["source_location"] or "—",
                pr=pr,
                h=r["handler"] or "—",
                v=r["validation"] or "—",
                c=r["confidence"] or "—",
                stat=r["status"] or "—",
            )
        )
    lines += [
        "",
        "## Notes",
        "",
        "- **Officer Graves** quest target / DisplayName ≠ instance Name. Instance is `Officer Graves [2]`. ReplicatedStorage `Officer Graves` is character-create.",
        "- **Pirate Fan Letter** Collect = KillUntilDrop **Corrupt Marine** (QuestInfo `markers[].tag`). Pickup via drop-container prompt. Do not `byName` the letter as a world rock.",
        "- **Pirate Instructions** Collect = KillUntilDrop **Black Noir Officer** (marker `Black Noir Officer Marker`).",
        "- **Escort The Mayor**: handler `Escort`, `NeverSkip`. Follow only. Do not substitute Talk/Kill.",
        "- **The Wandering Hypnotist**: `NeverSkip`. Kill target verified `\"Hypnotist\" Mango`.",
        "- **Stephon's Tormentor**: Kill target verified `\"Barrel Clown\" Binki`.",
        "- Resume from any live quest / completed set. Do not assume lv0.",
        "- **Live truth:** `GetData(\"Quests\",\"Completed Quests\")` + `BeginQuest`/`ClearQuest`/`QuestProgress` + PlayerGui.Quests tracker.",
        "- Craft / Defend / Emote / Convince / Dig / Steal / Cash Out / Unlock Skill: `UNKNOWN_OBJECTIVE` + skip, no infinite loop.",
        "",
    ]
    OUT_MATRIX.write_text("\n".join(lines), encoding="utf-8")


def write_coverage(rows, cov) -> None:
    def block(title, b):
        return (
            f"### {title}\n\n"
            f"| Metric | Count |\n|---|---|\n"
            f"| Stages | {b['stages']} |\n"
            f"| Planned | {b['planned']} |\n"
            f"| Implemented | {b['implemented']} |\n"
            f"| Runtime verified | {b['runtime_verified']} |\n"
            f"| Runtime required | {b['runtime_required']} |\n"
            f"| Unresolved | {b['unresolved']} |\n"
        )

    a = cov["all"]
    lines = [
        "# Quest Coverage Report",
        "",
        "**Version:** 1.1.0  ",
        "**Source:** `research/quests.json` (151 QuestInfo modules) + planner Goal/AcquireMethod.",
        "",
        f"Quests dumped: **{cov['quests']}**",
        "",
        block("All stages", a),
        "",
        block("Anchor story (Introduction → Setting Sail)", cov["anchor"]),
        "",
        block("Clown story", cov["clown"]),
        "",
        block("Maple story", cov["maple"]),
        "",
        block("Main route (Anchor+Clown+Maple story)", cov["main_route"]),
        "",
        "## Unresolved stages",
        "",
    ]
    unresolved = [r for r in rows if r["status"] == "UNRESOLVED"]
    if not unresolved:
        lines.append("None.")
    else:
        lines.append("| Quest | Stage | Objective | Target | Note |")
        lines.append("|---|---|---|---|---|")
        for r in unresolved:
            lines.append(
                f"| {r['quest']} | {r['stage']} | {r['objective'] or '—'} | {r['target'] or '—'} | {r.get('note') or r['handler']} |"
            )
    lines += [
        "",
        "## Pirate Fan Letter",
        "",
        "- Goal: AcquireItem",
        "- Method: EnemyDrop",
        "- Source: **Corrupt Marine** (QuestInfo stage marker, CollectionService tag)",
        "- Pickup: drop-container / prompt semantic match (not nearest BaseRock)",
        "- Validation: inventory/quest count 0/1 → 1/1",
        "",
    ]
    OUT_COV.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    quests = load_quests()
    rows = classify_all(quests)
    items = item_specs(rows)
    subs = subgoals()
    cov = coverage(rows)
    write_specs_json(rows, items, subs)
    write_questspecs_lua(rows, items, subs)
    write_matrix(rows)
    write_coverage(rows, cov)
    print(
        f"quests={cov['quests']} stages={cov['all']['stages']} planned={cov['all']['planned']} "
        f"impl={cov['all']['implemented']} rt={cov['all']['runtime_verified']} "
        f"need={cov['all']['runtime_required']} unresolved={cov['all']['unresolved']}"
    )
    print(f"wrote {OUT_JSON}")
    print(f"wrote {OUT_LUA}")
    print(f"wrote {OUT_MATRIX}")
    print(f"wrote {OUT_COV}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
