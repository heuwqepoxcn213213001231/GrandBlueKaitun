#!/usr/bin/env python3
"""Static route validator: Fresh → Anchor → Clown → Maple.

FAIL if a VERIFIED main-route stage has no execution strategy.
"""

from __future__ import annotations

import json
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from quest_audit_lib import (  # noqa: E402
    ANCHOR_STORY,
    CLOWN_STORY,
    MAIN_ROUTE,
    MAPLE_STORY,
    ROOT,
    SKIP,
    classify_all,
    load_quests,
)

ACQUIRE_NEEDS_SOURCE = {"EnemyDrop", "BossDrop", "ShopPurchase", "Interactable", "Chest", "Mining"}
VERIFIED_STATUS = {"STATIC_VERIFIED", "IMPLEMENTED", "RUNTIME_VERIFIED"}


def fail(code: str, msg: str, errors: list) -> None:
    errors.append(f"{code}: {msg}")


def validate(rows: list[dict], quests: list[dict]) -> list[str]:
    errors: list[str] = []
    by_quest = defaultdict(list)
    names = {q["name"] for q in quests}
    for r in rows:
        by_quest[r["quest"]].append(r)

    for qn in MAIN_ROUTE:
        if qn not in by_quest:
            fail("UNHANDLED_STAGE", f"main-route quest missing from dump: {qn}", errors)
            continue
        for r in by_quest[qn]:
            verified = r["status"] in VERIFIED_STATUS or r["confidence"] == "STATIC_VERIFIED"
            if r["status"] == "UNRESOLVED" and r["objective"] in {"Defend", "Craft"}:
                continue
            if not r["goal"] or r["goal"] == "Unresolved":
                if verified:
                    fail("UNHANDLED_STAGE", f"{qn} stage {r['stage']} {r['objective']} {r['target']}", errors)
                continue
            if not r["handler"] or r["handler"] == "UNKNOWN":
                if verified:
                    fail("MISSING_HANDLER", f"{qn} stage {r['stage']} {r['objective']} {r['target']}", errors)
            if not r.get("validation"):
                fail("MISSING_VALIDATION", f"{qn} stage {r['stage']}", errors)
            if r["goal"] == "AcquireItem" and r["acquire"] in ACQUIRE_NEEDS_SOURCE and not r.get("source"):
                fail("MISSING_SOURCE", f"{qn} stage {r['stage']} {r['target']} method={r['acquire']}", errors)
            for p in r.get("prerequisites") or []:
                if p not in names and p not in SKIP:
                    fail("UNRESOLVED_DEPENDENCY", f"{qn} prereq {p}", errors)

    # cycles on prereq graph (story only)
    prereq = {q["name"]: list(q.get("prerequisites") or []) for q in quests if q["name"] in MAIN_ROUTE}
    visiting, seen = set(), set()

    def dfs(n: str, stack: list[str]) -> None:
        if n in seen:
            return
        if n in visiting:
            fail("CYCLE", " -> ".join(stack + [n]), errors)
            return
        visiting.add(n)
        for p in prereq.get(n, []):
            if p in prereq:
                dfs(p, stack + [n])
        visiting.remove(n)
        seen.add(n)

    for n in MAIN_ROUTE:
        dfs(n, [])

    # Dead end = main-route stage with no executable plan (not dump unlocks_next quirks).
    for qn in MAIN_ROUTE:
        for r in by_quest.get(qn, []):
            if r["status"] == "UNRESOLVED" and r["objective"] in {"Defend", "Craft"}:
                continue
            if r["status"] == "UNRESOLVED" and not r.get("handler"):
                fail("DEAD_END", f"{qn} stage {r['stage']} no plan", errors)
            if r["goal"] == "AcquireItem" and not r.get("acquire") and r["status"] in VERIFIED_STATUS:
                fail("DEAD_END", f"{qn} stage {r['stage']} acquire missing", errors)

    return errors


def main() -> int:
    quests = load_quests()
    rows = classify_all(quests)
    errors = validate(rows, quests)
    specs = ROOT / "research" / "quest_specs.json"
    if specs.exists():
        data = json.loads(specs.read_text(encoding="utf-8"))
        if data.get("stages") and len(data["stages"]) != len(rows):
            errors.append(f"MISSING_HANDLER: quest_specs.json stages {len(data['stages'])} != live classify {len(rows)}")
    print(f"route quests: Anchor {len(ANCHOR_STORY)} Clown {len(CLOWN_STORY)} Maple {len(MAPLE_STORY)}")
    print(f"classified stages: {len(rows)}")
    if errors:
        print("FAIL")
        for e in errors:
            print(e)
        return 1
    print("PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
