#!/usr/bin/env python3
"""Diff previous vs current research snapshot."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SNAP = ROOT / "research" / "_generated_snapshot.json"
PREV = ROOT / "research" / "_generated_snapshot.prev.json"


def names_from_quests() -> set[str]:
    data = json.loads((ROOT / "research" / "quests.json").read_text(encoding="utf-8"))
    return {q["name"] for q in data["quests"]}


def main() -> int:
    current = names_from_quests()
    prev_names = set()
    if PREV.is_file():
        prev = json.loads(PREV.read_text(encoding="utf-8"))
        prev_names = set(prev.get("quest_names") or [])
    elif SNAP.is_file():
        print("no previous snapshot; write current as baseline")
    added = sorted(current - prev_names) if prev_names else []
    removed = sorted(prev_names - current) if prev_names else []
    print(f"NEW quests: {len(added)}")
    for n in added:
        print("  +", n)
    print(f"REMOVED quests: {len(removed)}")
    for n in removed:
        print("  -", n)
    payload = {"quest_names": sorted(current)}
    if SNAP.is_file():
        cur = json.loads(SNAP.read_text(encoding="utf-8"))
        payload.update(cur)
    PREV.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
