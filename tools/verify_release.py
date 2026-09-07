#!/usr/bin/env python3
"""Release sanity checks for Grand Blue Kaitun."""

from __future__ import annotations

import json
from pathlib import Path
import re
import sys


def fail(msg: str) -> None:
    print(f"[verify_release] FAIL: {msg}")
    raise SystemExit(1)


def main() -> None:
    root = Path(__file__).resolve().parent.parent
    version_path = root / "VERSION"
    manifest_path = root / "manifest.json"
    loader_path = root / "loader.lua"
    stats_path = root / "Systems" / "Stats.lua"
    quest_path = root / "Systems" / "Quest.lua"

    if not version_path.is_file():
        fail("missing VERSION")
    if not manifest_path.is_file():
        fail("missing manifest.json")

    version = version_path.read_text(encoding="utf-8").strip()
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

    manifest_version = str(manifest.get("version", "")).strip()
    if not version or not manifest_version:
        fail("empty version string")
    if version != manifest_version:
        fail(f"VERSION ({version}) != manifest.version ({manifest_version})")

    files = manifest.get("files")
    order = manifest.get("order")
    if not isinstance(files, dict) or not files:
        fail("manifest.files invalid")
    if not isinstance(order, list) or not order:
        fail("manifest.order invalid")

    for rel, mapped in files.items():
        if rel != mapped:
            fail(f"manifest files entry must be path=path: {rel} -> {mapped}")
        if not (root / rel).is_file():
            fail(f"manifest file missing on disk: {rel}")

    for row in order:
        if not isinstance(row, dict):
            fail("manifest.order row must be object")
        rel = row.get("path")
        if not isinstance(rel, str) or rel not in files:
            fail(f"manifest.order path invalid: {rel}")

    loader_src = loader_path.read_text(encoding="utf-8")
    if re.search(r'local\s+versionText\s*=\s*"[\d.]+"', loader_src):
        fail("loader.lua still has hardcoded version fallback")

    stats_src = stats_path.read_text(encoding="utf-8")
    quest_src = quest_path.read_text(encoding="utf-8")
    required_markers = [
        ("Systems/Stats.lua", "function M.ReadStatState"),
        ("Systems/Stats.lua", "function M.Invest"),
        ("Systems/Stats.lua", "VERIFIED src="),
        ("Systems/Quest.lua", "Gate of Authority BLOCKED Strength="),
        ("Systems/Quest.lua", "function M.CurrentBlockers"),
        ("Systems/Quest.lua", "gate sealed waiting window"),
    ]
    for file_name, marker in required_markers:
        source = stats_src if "Stats.lua" in file_name else quest_src
        if marker not in source:
            fail(f"missing marker `{marker}` in {file_name}")

    print("[verify_release] OK")
    print(f"[verify_release] version={version}")
    print(f"[verify_release] files={len(files)} order={len(order)}")


if __name__ == "__main__":
    try:
        main()
    except json.JSONDecodeError as exc:
        fail(f"manifest.json decode error: {exc}")
