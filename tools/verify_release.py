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
    kaitun_path = root / "kaitun.lua"
    profiler_path = root / "Core" / "Profiler.lua"
    stats_path = root / "Systems" / "Stats.lua"
    quest_path = root / "Systems" / "Quest.lua"
    player_data_path = root / "Game" / "PlayerData.lua"
    combat_path = root / "Systems" / "Combat.lua"
    engine_path = root / "Progression" / "DecisionEngine.lua"
    dist_path = root / "dist" / "kaitun.lua"

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
    kaitun_src = kaitun_path.read_text(encoding="utf-8")
    profiler_src = profiler_path.read_text(encoding="utf-8")
    player_src = player_data_path.read_text(encoding="utf-8")
    combat_src = combat_path.read_text(encoding="utf-8")
    engine_src = engine_path.read_text(encoding="utf-8")
    if re.search(r'local\s+versionText\s*=\s*"[\d.]+"', loader_src):
        fail("loader.lua still has hardcoded version fallback")
    if "api.github.com/repos/" in loader_src:
        fail("loader.lua still resolves commit via GitHub API at runtime")
    if "[Kaitun][Loader][FATAL] VERSION mismatch file=" not in loader_src:
        fail("loader.lua missing fatal VERSION mismatch guard")
    if "GB_VERSION or \"1." in kaitun_src:
        fail("kaitun.lua still has numeric GB_VERSION fallback")
    if "GB.Scheduler.add(\"stats\"" in kaitun_src:
        fail("kaitun.lua still has dedicated stats scheduler job")
    if "function M.report(force)" not in profiler_src or "SourceHttpAfterBoot=" not in profiler_src:
        fail("Profiler missing perf report + SourceHttpAfterBoot")
    if "function M.questDirty()" not in player_src:
        fail("PlayerData missing questDirty()")
    if "LIVE_SAFETY_TTL" not in player_src:
        fail("PlayerData missing event-driven safety TTL")
    if "QUEST_CHECK_MIN_GAP" not in combat_src or "combat_tick" not in combat_src:
        fail("Combat missing slow quest validation path")
    if "GB.Stats.tick()" not in engine_src:
        fail("DecisionEngine missing single-owner stats tick")

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

    bundle_rel = str(manifest.get("bundle", "")).strip()
    if bundle_rel != "dist/kaitun.lua":
        fail("manifest.bundle must be dist/kaitun.lua")
    if manifest["files"].get("dist/kaitun.lua") != "dist/kaitun.lua":
        fail("manifest.files missing dist/kaitun.lua")
    if not dist_path.is_file():
        fail("dist/kaitun.lua missing")
    dist_src = dist_path.read_text(encoding="utf-8")
    if f"-- Version: {version}" not in dist_src:
        fail("bundle header version mismatch")
    build = manifest.get("build")
    if not isinstance(build, dict):
        fail("manifest.build missing")
    commit = str(build.get("commit", "")).strip()
    built_at = str(build.get("built_at", "")).strip()
    if not commit:
        fail("manifest.build.commit empty")
    if not built_at:
        fail("manifest.build.built_at empty")
    if f"-- Commit: {commit}" not in dist_src:
        fail("bundle header commit mismatch")

    print("[verify_release] OK")
    print(f"[verify_release] version={version}")
    print(f"[verify_release] files={len(files)} order={len(order)}")


if __name__ == "__main__":
    try:
        main()
    except json.JSONDecodeError as exc:
        fail(f"manifest.json decode error: {exc}")
