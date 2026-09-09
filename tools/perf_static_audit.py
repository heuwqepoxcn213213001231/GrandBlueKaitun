#!/usr/bin/env python3
"""Classify GetDescendants / getgc / InvokeServer / Heartbeat occurrences."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKIP = {"dist/kaitun.lua", "kaitun.lua"}
PATTERNS = (
    "GetDescendants",
    "HttpGet",
    "InvokeServer",
    "FireServer",
    "getgc",
    "getconnections",
    "Heartbeat",
    "RenderStepped",
    "workspace:GetDescendants",
    "PlayerGui",
)


def classify(path: str, line: str, pat: str) -> str:
    s = line.lower()
    if "perfcount" in s and "getdescendants" in s:
        return "DIAGNOSTIC"
    if "allowdeep" in s or "debug" in s or "dumpnearby" in s or "diagnostic" in s:
        return "DIAGNOSTIC"
    if path.endswith("loader.lua") and pat == "HttpGet":
        return "ONE_TIME"
    if path.endswith("src/boot.lua") and pat == "HttpGet":
        return "ONE_TIME"
    if path.endswith("Core/Profiler.lua"):
        return "SAFE"
    if "connect" in s and pat in {"Heartbeat", "RenderStepped"}:
        return "EVENT"
    if pat == "GetDescendants" and "workspace:getdescendants" in s:
        return "HOT_PATH_BAD"
    if pat == "getgc":
        return "ONE_TIME" if "allowheavy" in s or "once" in s else "DIAGNOSTIC"
    if pat == "InvokeServer":
        return "EVENT"
    if pat == "FireServer":
        return "SAFE"
    return "SAFE"


def main() -> int:
    bad = []
    counts = {p: 0 for p in PATTERNS}
    for p in ROOT.rglob("*.lua"):
        rel = str(p.relative_to(ROOT))
        if rel in SKIP or "/dist/" in rel:
            continue
        text = p.read_text(encoding="utf-8", errors="replace")
        for i, line in enumerate(text.splitlines(), 1):
            for pat in PATTERNS:
                if pat in line:
                    counts[pat] += 1
                    kind = classify(rel, line, pat)
                    if kind == "HOT_PATH_BAD":
                        bad.append(f"{rel}:{i} {pat} {line.strip()[:120]}")
    print("counts:")
    for k, n in counts.items():
        print(f"  {k}: {n}")
    if bad:
        print("HOT_PATH_BAD:")
        for row in bad:
            print(" ", row)
        return 1
    print("PASS no HOT_PATH_BAD")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
