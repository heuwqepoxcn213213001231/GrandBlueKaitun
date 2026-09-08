#!/usr/bin/env python3
"""Run the static hardening suite. Does not build the production bundle."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STEPS = (
    ["python3", "tools/build_game_data.py"],
    ["python3", "tools/validate_game_data.py"],
    ["python3", "tools/quest_route_validator.py"],
    ["python3", "tools/perf_static_audit.py"],
    ["python3", "tools/regression_tests.py"],
    ["python3", "tools/scenario_tests.py"],
    ["python3", "tools/diff_game_data.py"],
)


def main() -> int:
    for cmd in STEPS:
        print("+", " ".join(cmd), flush=True)
        r = subprocess.run(cmd, cwd=ROOT)
        if r.returncode != 0:
            print("FAIL", cmd[1])
            return r.returncode
    print("PASS hardening suite")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
