#!/usr/bin/env python3
"""Verify the generated Grand Blue UI single-file release."""

from __future__ import annotations

import json
import re
import shutil
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Any

from build_ui import (
    BuildError,
    HEADLESS_PRODUCTION,
    PRODUCTION,
    PROJECT_READ,
    PROJECT_REQUIRE,
    RAW_UI_URL,
    UI_CONTROLLER,
    UI_CATALOG,
    UI_EXTENSIONS,
    UI_HUB,
    UI_MANIFEST,
    NIAUI_URL,
    UI_ADAPTER,
    UI_RESOLVER,
    UI_RESOLVER_BASE,
    UI_VERSION_FILE,
    expected_hash_relpaths,
    expected_source_relpaths,
    manifest_rows,
    normalized_source,
    sha256_file,
    source_hash,
)


REQUIRED_TABS = (
    "Home",
    "Quests",
    "Mobs",
    "Bosses",
    "Teleport",
    "Items",
    "Equipment",
    "Skills",
    "Stats",
    "Life Skills",
    "Fruit",
    "Misc",
    "Shop",
    "Chest / Treasure",
    "Codes / Rewards",
    "Auto Progress",
    "Settings",
    "Debug",
)

CONTROLLER_OWNERS = (
    "IDLE",
    "FULL_AUTO",
    "MANUAL_QUEST",
    "MANUAL_MOB",
    "MANUAL_BOSS",
    "MANUAL_CHEST",
)

ADAPTER_API = (
    "function Adapter:CreateWindow",
    "function wrapped:AddTab",
    "function wrapped:AddToggle",
    "function wrapped:AddDropdown",
    "function wrapped:AddMultiSelect",
    "function wrapped:AddButton",
    "function Adapter:Notify",
    "function Adapter:Unload",
    "GB.NiaLibrary",
)

CONTROLLER_API = (
    "function M.setOwner",
    "function M.stop",
    "function M.pause",
    "function M.resume",
    "function M.enqueue",
    "function M.tick",
    "function M.destroy",
    "function M.describeBlocker",
)

HUB_API = (
    "Window",
    "Controls",
    "Refresh",
    "SaveConfig",
    "LoadConfig",
    "ResetConfig",
    "Notify",
    "Destroy",
)

PROJECT_PATH_STRING = re.compile(
    r"""["'](?:\./|\.\./|Core/|Game/|Systems/|Progression/|UI/|src/)[A-Za-z0-9_./-]+\.lua["']"""
)
RUNTIME_COPIED_NIA_URL = re.compile(
    r"""https?://[^\s"'[\]]*(?:NiaInline|/Nia\.lua)[^\s"'[\]]*""",
    re.I,
)
QUEUE_STRING = re.compile(r"local\s+cmd\s*=\s*\[\[(.*?)\]\]", re.S)
SOURCE_HASH_HEADER = re.compile(r"^-- SOURCE_HASH: ([0-9a-f]{16})$", re.M)
FEATURE_MATRIX = "research/UI_FEATURE_MATRIX.md"


class Checks:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.notes: list[str] = []

    def require(self, condition: bool, message: str) -> bool:
        if not condition:
            self.errors.append(message)
            return False
        return True

    def note(self, message: str) -> None:
        self.notes.append(message)


def verify_feature_matrix(matrix: str, checks: Checks) -> None:
    lines = [line for line in matrix.splitlines() if line.startswith("|")]
    checks.require(len(lines) >= 3, "UI feature matrix has no data rows")
    if len(lines) < 2:
        return
    header = [cell.strip() for cell in lines[0].strip("|").split("|")]
    expected = [
        "Feature",
        "Game system",
        "Research source",
        "Runtime status",
        "UI control",
        "Tab",
        "Implementation status",
        "Validation method",
    ]
    checks.require(header == expected, "UI feature matrix columns are not exact")
    allowed = {"IMPLEMENTED", "STATUS_ONLY", "DISABLED"}
    for index, line in enumerate(lines[2:], start=3):
        cells = [cell.strip() for cell in line.strip("|").split("|")]
        checks.require(len(cells) == 8, f"UI feature matrix row {index} does not have 8 columns")
        if len(cells) == 8:
            checks.require(all(cells), f"UI feature matrix row {index} contains an empty cell")
            checks.require(
                cells[6] in allowed,
                f"UI feature matrix row {index} has invalid implementation status {cells[6]}",
            )


def load_json(path: Path, checks: Checks, label: str) -> dict[str, Any]:
    if not path.is_file():
        checks.errors.append(f"missing {label}")
        return {}
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        checks.errors.append(f"cannot read {label}: {exc}")
        return {}
    if not isinstance(value, dict):
        checks.errors.append(f"{label} root is not an object")
        return {}
    return value


def metadata_consistency(ui_manifest: dict[str, Any], checks: Checks) -> None:
    build = ui_manifest.get("build")
    checks.require(isinstance(build, dict), "ui_manifest.build must be an object")
    if not isinstance(build, dict):
        return
    if not ui_manifest.get("source_hash"):
        # A checked-in skeleton is valid before the first successful build.
        checks.require(
            ui_manifest.get("version") == build.get("version"),
            "ui_manifest.version disagrees with ui_manifest.build.version",
        )
        checks.require(
            ui_manifest.get("production") == build.get("production"),
            "ui_manifest.production disagrees with ui_manifest.build.production",
        )
        return
    for key in (
        "version",
        "core_version",
        "commit",
        "built_at",
        "source_hash",
        "production",
        "sources",
        "hash_inputs",
        "headless_sha256",
        "artifact_sha256",
        "line_count",
        "byte_count",
    ):
        checks.require(
            ui_manifest.get(key) == build.get(key),
            f"ui_manifest.{key} disagrees with ui_manifest.build.{key}",
        )


def verify_metadata(
    root: Path,
    main_manifest: dict[str, Any],
    ui_manifest: dict[str, Any],
    ui_version: str,
    checks: Checks,
) -> tuple[list[str], str | None]:
    checks.require(ui_manifest.get("version") == ui_version, "UI_VERSION != ui_manifest.version")
    checks.require(
        ui_manifest.get("core_version") == main_manifest.get("version"),
        "ui_manifest.core_version != manifest.version",
    )
    checks.require(ui_manifest.get("production") == PRODUCTION, "ui_manifest.production must be kaitun_ui.lua")
    commit = str(ui_manifest.get("commit") or "").strip()
    checks.require(
        re.fullmatch(r"[0-9a-f]{7,40}", commit) is not None,
        "ui_manifest.commit is not a source Git SHA",
    )
    built_at = ui_manifest.get("built_at")
    checks.require(isinstance(built_at, str) and bool(built_at), "ui_manifest.built_at is empty")
    if isinstance(built_at, str) and built_at:
        try:
            datetime.fromisoformat(built_at)
        except ValueError:
            checks.errors.append("ui_manifest.built_at is not ISO-8601")

    metadata_consistency(ui_manifest, checks)
    try:
        expected_sources = expected_source_relpaths(main_manifest)
        expected_hash_inputs = expected_hash_relpaths(main_manifest)
    except BuildError as exc:
        checks.errors.append(str(exc))
        return [], None

    checks.require(
        ui_manifest.get("sources") == expected_sources,
        "ui_manifest.sources is not the current manifest/UI source order",
    )
    checks.require(
        ui_manifest.get("hash_inputs") == expected_hash_inputs,
        "ui_manifest.hash_inputs is not the current build graph",
    )
    try:
        current_hash = source_hash(root, expected_hash_inputs)
    except (BuildError, OSError) as exc:
        checks.errors.append(f"cannot hash current UI sources: {exc}")
        return expected_sources, None
    checks.require(
        ui_manifest.get("source_hash") == current_hash,
        "ui_manifest.source_hash is stale",
    )
    return expected_sources, current_hash


def verify_headless(root: Path, ui_manifest: dict[str, Any], checks: Checks) -> str | None:
    headless = root / HEADLESS_PRODUCTION
    if not headless.is_file():
        checks.errors.append("missing kaitun.lua; UI build must not create it")
        return None
    current = sha256_file(headless)
    recorded = ui_manifest.get("headless_sha256")
    checks.require(
        isinstance(recorded, str) and re.fullmatch(r"[0-9a-f]{64}", recorded) is not None,
        "ui_manifest.headless_sha256 is not recorded",
    )
    if isinstance(recorded, str):
        checks.require(
            recorded == current,
            f"kaitun.lua changed after the first UI build (recorded={recorded}, current={current})",
        )
    return current


def verify_source_sections(
    root: Path,
    generated: str,
    sources: list[str],
    checks: Checks,
) -> None:
    positions: list[int] = []
    for rel in sources:
        if rel == UI_VERSION_FILE:
            continue
        marker = f"-- BEGIN SOURCE: {rel}"
        position = generated.find(marker)
        checks.require(position >= 0, f"generated output missing section {rel}")
        checks.require(generated.count(marker) == 1, f"generated output section marker count != 1 for {rel}")
        if position >= 0:
            positions.append(position)
        path = root / rel
        if path.is_file():
            exact = normalized_source(path.read_text(encoding="utf-8")).rstrip()
            checks.require(exact in generated, f"generated output does not inline current {rel} exactly")
    checks.require(positions == sorted(positions), "generated source sections are out of order")
    checks.require(len(positions) == len(set(positions)), "generated source section marker is duplicated")


def verify_network_shape(generated: str, checks: Checks) -> tuple[int, int]:
    http_count = generated.count("HttpGet")
    loadstring_count = generated.count("loadstring")
    checks.require(http_count == 2, f"expected two HttpGet tokens, found {http_count}")
    checks.require(loadstring_count == 2, f"expected two loadstring tokens, found {loadstring_count}")

    queue = QUEUE_STRING.search(generated)
    checks.require(queue is not None, "teleport requeue command string is missing")
    if queue:
        body = queue.group(1)
        checks.require(body.count("HttpGet") == 1, "queued command must contain one HttpGet token")
        checks.require(body.count("loadstring") == 1, "queued command must contain one loadstring token")
        checks.require(
            RAW_UI_URL + '?cb=" .. tostring(os.time())' in body,
            "queued command does not target raw kaitun_ui.lua with cache busting",
        )
        outside = generated[: queue.start(1)] + generated[queue.end(1) :]
        checks.require(outside.count("HttpGet") == 1, "UI build must have exactly one NiaUI HttpGet")
        checks.require(outside.count("loadstring") == 1, "UI build must have exactly one NiaUI loadstring")
        checks.require(NIAUI_URL in outside, "NiaUI URL missing outside teleport requeue")

    project_raw_count = generated.count(
        "https://raw.githubusercontent.com/heuwqepoxcn213213001231/GrandBlueKaitun/"
    )
    checks.require(project_raw_count == 1, f"expected one project raw URL, found {project_raw_count}")
    checks.require("/kaitun_ui.lua?cb=" in generated, "requeue URL is not kaitun_ui.lua")
    checks.require("/kaitun.lua?cb=" not in generated, "requeue points at headless kaitun.lua")
    checks.require(generated.count(NIAUI_URL) == 1, "NiaUI URL count != 1")
    checks.require(RUNTIME_COPIED_NIA_URL.search(generated) is None, "copied Nia source URL found")
    checks.require("function Nia:CreateWindow" not in generated, "inlined Nia renderer still present")
    checks.require('Instance.new("ScreenGui")' not in generated, "custom ScreenGui renderer still present")
    return http_count, loadstring_count


def verify_no_project_loading(generated: str, checks: Checks) -> int:
    for marker in (
        "function LoadModule",
        "local function LoadModule",
        "GB_BASE_URL",
        "GB_USE_BUNDLE",
        "return function(meta)",
        '["Config.lua"] = [[',
    ):
        checks.require(marker not in generated, f"forbidden generated marker: {marker}")
    checks.require(PROJECT_REQUIRE.search(generated) is None, "project-owned require() found")
    checks.require(PROJECT_READ.search(generated) is None, "direct project file loading found")
    checks.require(PROJECT_PATH_STRING.search(generated) is None, "quoted project source path found")
    return generated.count("require(")


def verify_contract_markers(
    generated: str,
    adapter: str,
    controller: str,
    hub: str,
    checks: Checks,
) -> None:
    for marker in ADAPTER_API:
        checks.require(marker in adapter and marker in generated, f"missing adapter marker: {marker}")
    for marker in CONTROLLER_API:
        checks.require(marker in controller and marker in generated, f"missing controller marker: {marker}")
    for owner in CONTROLLER_OWNERS:
        checks.require(
            re.search(rf"\b{re.escape(owner)}\s*=\s*{re.escape(json.dumps(owner))}", controller) is not None,
            f"controller owner constant missing: {owner}",
        )
        checks.require(owner in generated, f"generated owner marker missing: {owner}")
    for field in HUB_API:
        checks.require(re.search(rf"\b{re.escape(field)}\b", hub) is not None, f"Hub API missing: {field}")
        checks.require(re.search(rf"\b{re.escape(field)}\b", generated) is not None, f"generated Hub API missing: {field}")
    for tab in REQUIRED_TABS:
        literal = json.dumps(tab)
        checks.require(literal in hub, f"Hub tab missing: {tab}")
        checks.require(literal in generated, f"generated Hub tab missing: {tab}")

    markers = (
        "GB[\"UIAdapter\"] = inst",
        "GB[\"UIController\"] = inst",
        "GB[\"UICatalog\"] = inst",
        "GB[\"UIExtensions\"] = inst",
        f"-- BEGIN SOURCE: {UI_RESOLVER}",
        "GB[\"UIHub\"] = inst",
        'GB.Scheduler.remove("engine")',
        "GB.UIController.tick()",
        'GB.Scheduler.remove("respawn")',
        "GB.Config.AutoRespawn ~= false",
        "GB._uiLifecycleWrapped = true",
        "destroyComponent(GB.UIHub",
        "destroyComponent(GB.UIAdapter",
        "destroyComponent(GB.NiaLibrary",
        "destroyComponent(GB.Nia",
        "destroyComponent(GB.UIController",
        "destroyComponent(GB.UIExtensions",
        "getgenv()._GBKaitunUnload = GB.unload",
        "getgenv().GBKaitunUI = GB",
        "getgenv().GBKaitun = GB",
        "GB.Config.Enabled = true",
        "UI Ready",
        "SourceHttpAfterBoot=0",
        "function GB.Stop",
        "function GB.Destroy",
        "function GB.SelfCheck",
    )
    for marker in markers:
        checks.require(marker in generated, f"required runtime marker missing: {marker}")

    disabled = generated.find("getgenv().GBConfig.Enabled = false")
    config = generated.find("-- BEGIN SOURCE: Config.lua")
    controller_at = generated.find(f"-- BEGIN SOURCE: {UI_CONTROLLER}")
    catalog_at = generated.find(f"-- BEGIN SOURCE: {UI_CATALOG}")
    extensions_at = generated.find(f"-- BEGIN SOURCE: {UI_EXTENSIONS}")
    boot_at = generated.find("-- BEGIN SOURCE: src/boot.lua")
    handoff_at = generated.find("-- UI scheduler ownership")
    niaui_at = generated.find("-- NiaUI external load (once)")
    adapter_at = generated.find(f"-- BEGIN SOURCE: {UI_ADAPTER}")
    hub_at = generated.find(f"-- BEGIN SOURCE: {UI_HUB}")
    lifecycle_at = generated.find("-- UI lifecycle and public API")
    checks.require(
        min(disabled, config, controller_at, catalog_at, extensions_at, boot_at, handoff_at, niaui_at, adapter_at, hub_at, lifecycle_at) >= 0,
        "one or more ordered runtime sections are missing",
    )
    if min(disabled, config, controller_at, catalog_at, extensions_at, boot_at, handoff_at, niaui_at, adapter_at, hub_at, lifecycle_at) >= 0:
        checks.require(
            disabled < config < controller_at < catalog_at < extensions_at < boot_at < handoff_at < niaui_at < adapter_at < hub_at < lifecycle_at,
            "runtime construction/handoff order is invalid",
        )
    pre_config = generated[disabled:config] if disabled >= 0 and config >= 0 else ""
    checks.require(
        not re.search(r"GBConfig\.Auto[A-Za-z0-9_]*\s*=", pre_config),
        "preamble erases auto defaults before controller snapshot",
    )


def run_compiler(root: Path, output: Path, checks: Checks) -> str:
    compiler = shutil.which("luau-compile")
    if not compiler:
        checks.errors.append("luau-compile is required for UI release verification")
        return "unavailable"
    result = subprocess.run(
        [compiler, "-O0", str(output)],
        cwd=root,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or f"exit {result.returncode}"
        checks.errors.append(f"luau-compile failed: {detail}")
        return "failed"
    return "passed"


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    checks = Checks()
    main_manifest = load_json(root / "manifest.json", checks, "manifest.json")
    ui_manifest = load_json(root / UI_MANIFEST, checks, UI_MANIFEST)

    version_path = root / UI_VERSION_FILE
    if version_path.is_file():
        ui_version = version_path.read_text(encoding="utf-8").strip()
        checks.require(bool(ui_version), "UI_VERSION is empty")
    else:
        ui_version = ""
        checks.errors.append("missing UI_VERSION")

    sources: list[str] = []
    current_hash: str | None = None
    if main_manifest and ui_manifest:
        sources, current_hash = verify_metadata(root, main_manifest, ui_manifest, ui_version, checks)
    resolver_base_path = root / UI_RESOLVER_BASE
    if resolver_base_path.is_file() and (root / "Game" / "Resolver.lua").is_file():
        resolver_base = resolver_base_path.read_text(encoding="utf-8").strip()
        resolver_current = sha256_file(root / "Game" / "Resolver.lua")
        checks.require(resolver_base == resolver_current, "UI Resolver base is stale; rebase the UI variant")
    else:
        checks.errors.append("UI Resolver base guard is missing")
    headless_hash = verify_headless(root, ui_manifest, checks) if ui_manifest else None

    output_path = root / PRODUCTION
    generated = ""
    if output_path.is_file():
        try:
            generated = output_path.read_text(encoding="utf-8")
        except (OSError, UnicodeError) as exc:
            checks.errors.append(f"cannot read {PRODUCTION}: {exc}")
    else:
        checks.errors.append(f"missing {PRODUCTION}; run tools/build_ui.py")

    adapter_path = root / UI_ADAPTER
    controller_path = root / UI_CONTROLLER
    hub_path = root / UI_HUB
    adapter = adapter_path.read_text(encoding="utf-8") if adapter_path.is_file() else ""
    controller = controller_path.read_text(encoding="utf-8") if controller_path.is_file() else ""
    hub = hub_path.read_text(encoding="utf-8") if hub_path.is_file() else ""
    matrix_path = root / FEATURE_MATRIX
    matrix = matrix_path.read_text(encoding="utf-8") if matrix_path.is_file() else ""
    checks.require(bool(adapter), f"missing {UI_ADAPTER}")
    checks.require("Instance.new" not in adapter, "adapter contains renderer Instance.new")
    checks.require(bool(controller), f"missing {UI_CONTROLLER}")
    checks.require(bool(hub), f"missing {UI_HUB}")
    checks.require(bool(matrix), f"missing {FEATURE_MATRIX}")
    if matrix:
        verify_feature_matrix(matrix, checks)

    http_count = 0
    loadstring_count = 0
    require_count = 0
    compiler_status = "not-run"
    actual_lines = 0
    actual_bytes = 0
    if generated:
        checks.require(
            generated.startswith("--==================================================\n-- GRAND BLUE KAITUN UI"),
            "kaitun_ui.lua header/brand is invalid",
        )
        checks.require("GENERATED by tools/build_ui.py" in generated[:900], "generator banner missing")
        checks.require(f'local UI_VERSION = {json.dumps(ui_version)}' in generated, "UI_VERSION is not embedded")
        embedded = SOURCE_HASH_HEADER.search(generated)
        checks.require(embedded is not None, "SOURCE_HASH header is missing")
        if embedded and current_hash:
            checks.require(embedded.group(1) == current_hash, "generated SOURCE_HASH is stale")
        if sources:
            verify_source_sections(root, generated, sources, checks)
        http_count, loadstring_count = verify_network_shape(generated, checks)
        require_count = verify_no_project_loading(generated, checks)
        if adapter and controller and hub:
            verify_contract_markers(generated, adapter, controller, hub, checks)
        actual_lines = len(generated.splitlines())
        actual_bytes = len(generated.encode("utf-8"))
        checks.require(ui_manifest.get("line_count") == actual_lines, "ui_manifest.line_count is stale")
        checks.require(ui_manifest.get("byte_count") == actual_bytes, "ui_manifest.byte_count is stale")
        checks.require(
            ui_manifest.get("artifact_sha256") == sha256_file(output_path),
            "ui_manifest.artifact_sha256 is stale",
        )
        compiler_status = run_compiler(root, output_path, checks)

    if checks.errors:
        print("[verify_ui] FAIL")
        for error in checks.errors:
            print(f"[verify_ui]   - {error}")
    else:
        print("[verify_ui] OK")
    print(f"[verify_ui] ui_version={ui_version or 'missing'}")
    print(f"[verify_ui] source_hash={current_hash or 'unavailable'}")
    print(f"[verify_ui] headless_sha256={headless_hash or 'unavailable'}")
    print(f"[verify_ui] lines={actual_lines} bytes={actual_bytes}")
    print(
        f"[verify_ui] HttpGet_token={http_count} "
        f"loadstring_token={loadstring_count} require={require_count}"
    )
    print(f"[verify_ui] luau_compile={compiler_status}")
    return 1 if checks.errors else 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("[verify_ui] FAIL: interrupted")
        raise SystemExit(1)
