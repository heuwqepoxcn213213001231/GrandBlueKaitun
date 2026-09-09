#!/usr/bin/env python3
"""Static shape check for generated kaitun.lua. Not a full Lua parser."""

from __future__ import annotations

from pathlib import Path
import re
import shutil
import subprocess
import sys


def fail(msg: str) -> None:
    print(f"[syntax_check] FAIL: {msg}")
    raise SystemExit(1)


def main() -> None:
    root = Path(__file__).resolve().parent.parent
    path = root / "kaitun.lua"
    src = path.read_text(encoding="utf-8")
    if not src.startswith("--==================================================\n-- GRAND BLUE KAITUN"):
        fail("missing single-file header")
    if src.count("local factory = function(GB)") < 30:
        fail("too few inlined factories")
    if "function LoadModule" in src:
        fail("LoadModule present")
    if "return function(meta)" in src:
        fail("old bundle wrapper")
    if src.count("end") < 1000:
        fail("suspiciously few end keywords")

    compiler = shutil.which("luau-compile")
    if compiler:
        r = subprocess.run(
            [compiler, "-O0", str(path)],
            capture_output=True,
            text=True,
        )
        err = (r.stderr or "").strip()
        if r.returncode != 0:
            fail(f"luau-compile: {err or (r.stdout or '')[-400:]}")
        print("[syntax_check] luau-compile OK")

    print("[syntax_check] OK")
    print(f"[syntax_check] lines={src.count(chr(10)) + 1}")
    print(f"[syntax_check] factories={src.count('local factory = function(GB)')}")


if __name__ == "__main__":
    main()
