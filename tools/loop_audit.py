#!/usr/bin/env python3
"""Flag unbounded or zero-yield automation loops in UI sources.

This is a regression guard, not a proof of correctness. Suspicious hits fail
the build so a missing-target farm cannot ship another busy loop.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TARGETS = (
    ROOT / "UI" / "ManualController.lua",
    ROOT / "UI" / "Hub.lua",
    ROOT / "UI" / "Resolver.lua",
    ROOT / "UI" / "RuntimeExtensions.lua",
)

YIELD_MARKERS = (
    "task.wait",
    "task.delay",
    "Heartbeat",
    "RenderStepped",
    "Stepped",
    ":Wait(",
    ":wait(",
    "coroutine.yield",
    "os.clock()",
    "WAIT_TARGET",
    "WAIT_SELECTION",
    "WAIT_RESPAWN",
    "WAIT_STREAM",
    "statusToken",
    "_destroyed",
    "GB.dead",
)

ENABLED_WHILE = re.compile(
    r"while\s+[^\n]{0,120}(?:Enabled|enabled|Continuous|mobFarm|MobFarm|autoLoop|AutoFarm)[^\n]*\bdo\b",
    re.I,
)
REPEAT_UNTIL = re.compile(r"\brepeat\b")
WHILE_TRUE = re.compile(r"\bwhile\s+true\s+do\b")
FIND_TARGET_FALLBACK = re.compile(r"Combat\.findTarget|GB\.Combat\.findTarget")


def window_has_yield(text: str) -> bool:
    return any(marker in text for marker in YIELD_MARKERS)


def audit_file(path: Path) -> list[str]:
    issues: list[str] = []
    source = path.read_text(encoding="utf-8")
    rel = path.relative_to(ROOT).as_posix()
    if path.name == "ManualController.lua" and FIND_TARGET_FALLBACK.search(source):
        issues.append(f"{rel}: combat hunt fallback present in manual selection")
    for match in WHILE_TRUE.finditer(source):
        issues.append(f"{rel}:{source.count(chr(10), 0, match.start()) + 1}: while true")
    for match in ENABLED_WHILE.finditer(source):
        start = max(0, match.start() - 80)
        finish = min(len(source), match.end() + 360)
        chunk = source[start:finish]
        if not window_has_yield(chunk):
            line = source.count("\n", 0, match.start()) + 1
            issues.append(f"{rel}:{line}: enabled-while without cooperative yield")
    for match in REPEAT_UNTIL.finditer(source):
        finish = min(len(source), match.end() + 240)
        chunk = source[match.start() : finish]
        if "until" in chunk[5:] and not window_has_yield(chunk):
            if re.search(r"until\s+\w+", chunk) and "task.wait" not in chunk:
                line = source.count("\n", 0, match.start()) + 1
                if "pcall" in chunk and "until" in chunk:
                    issues.append(f"{rel}:{line}: repeat/pcall without yield")
    return issues


def main() -> int:
    issues: list[str] = []
    for path in TARGETS:
        if not path.is_file():
            issues.append(f"missing {path.relative_to(ROOT)}")
            continue
        issues.extend(audit_file(path))
    if issues:
        print("FAIL loop_audit")
        for issue in issues:
            print(f"  {issue}")
        return 1
    print("PASS loop_audit")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
