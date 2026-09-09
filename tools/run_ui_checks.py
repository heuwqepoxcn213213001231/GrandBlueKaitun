#!/usr/bin/env python3
"""Verify both UI and pinned headless releases without rebuilding kaitun.lua."""

from __future__ import annotations

import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
STEPS = (
    ["python3", "tools/validate_game_data.py"],
    ["python3", "tools/quest_route_validator.py"],
    ["python3", "tools/perf_static_audit.py"],
    ["python3", "tools/regression_tests.py"],
    ["python3", "tools/scenario_tests.py"],
    ["python3", "tools/syntax_check.py"],
    ["python3", "tools/verify_release.py"],
    ["python3", "tools/verify_single.py"],
    ["python3", "tools/verify_ui.py"],
    ["python3", "tools/ui_scenario_tests.py"],
)


def main() -> int:
    for command in STEPS:
        print("+", " ".join(command), flush=True)
        result = subprocess.run(command, cwd=ROOT, check=False)
        if result.returncode != 0:
            print("FAIL", command[1])
            return result.returncode
    print("PASS UI + headless release checks")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
