#!/usr/bin/env python3
"""Build kaitun_ui.lua without importing or executing generated headless source.

The modular factories remain the source of truth.  This builder emits one
readable Luau chunk in manifest order, adds the local UI factories, runs the
original bootstrap while Config.Enabled is false, and then transfers scheduler
ownership to the manual UI controller.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
import tempfile
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath
from typing import Any, Iterable, Sequence


PRODUCTION = "kaitun_ui.lua"
UI_MANIFEST = "ui_manifest.json"
UI_VERSION_FILE = "UI_VERSION"
HEADLESS_PRODUCTION = "kaitun.lua"
RAW_UI_URL = (
    "https://raw.githubusercontent.com/heuwqepoxcn213213001231/"
    "GrandBlueKaitun/refs/heads/main/kaitun_ui.lua"
)
NIAUI_URL = (
    "https://raw.githubusercontent.com/heuwqepoxcn213213001231/niauto/refs/heads/main/NiaUI"
)

UI_ADAPTER = "UI/NiaAdapter.lua"
UI_CONTROLLER = "UI/ManualController.lua"
UI_CATALOG = "UI/Catalog.lua"
UI_RESOLVER = "UI/Resolver.lua"
UI_RESOLVER_BASE = "UI/Resolver.base.sha256"
UI_EXTENSIONS = "UI/RuntimeExtensions.lua"
UI_HUB = "UI/Hub.lua"

GENERATED_ARTIFACTS = {
    "kaitun.lua",
    "dist/kaitun.lua",
    "kaitun_ui.lua",
    "dist/kaitun_ui.lua",
    "loader.lua",
    "VERSION",
    "manifest.json",
    "ui_manifest.json",
}

FACTORY_LINE = re.compile(r"(?m)^return\s+function\s*\(\s*GB\s*\)\s*$")
PROJECT_REQUIRE = re.compile(
    r"""require\s*\(\s*["'](?:\./|\.\./|Core[/\\.]|Game[/\\.]|Systems[/\\.]|Progression[/\\.]|UI[/\\.])"""
)
PROJECT_READ = re.compile(
    r"""(?:readfile|loadfile|dofile)\s*\(\s*["'](?:\./|\.\./|Core/|Game/|Systems/|Progression/|UI/|src/)"""
)

NS_MAP: dict[str, tuple[str, str] | None] = {
    "Config": None,
    "Log": ("Core", "Logger"),
    "Profiler": ("Core", "Profiler"),
    "Cache": ("Core", "Cache"),
    "Retry": ("Core", "Retry"),
    "Broker": ("Core", "RemoteBroker"),
    "Scheduler": ("Core", "Scheduler"),
    "Persist": ("Core", "Persist"),
    "State": ("Core", "State"),
    "Recovery": ("Core", "Recovery"),
    "Respawn": ("Systems", "Respawn"),
    "Remotes": ("Game", "Remotes"),
    "Resolver": ("Game", "Resolver"),
    "PlayerData": ("Game", "PlayerData"),
    "World": ("Game", "World"),
    "ItemData": ("Data", "Items"),
    "GeneratedData": ("Data", "Generated"),
    "Knowledge": ("Game", "Knowledge"),
    "QuestData": ("Data", "Quests"),
    "QuestSpecs": ("Data", "QuestSpecs"),
    "Inventory": ("Game", "Inventory"),
    "Combat": ("Systems", "Combat"),
    "Quest": ("Systems", "Quest"),
    "Acquire": ("Systems", "Acquire"),
    "Stats": ("Systems", "Stats"),
    "Skills": ("Systems", "Skills"),
    "Equipment": ("Systems", "Equipment"),
    "Shop": ("Systems", "Shop"),
    "Travel": ("Systems", "Travel"),
    "Boat": ("Systems", "Boat"),
    "Fruit": ("Systems", "Fruit"),
    "Haki": ("Systems", "Haki"),
    "RaceTrait": ("Systems", "RaceTrait"),
    "LifeSkills": ("Systems", "LifeSkills"),
    "Chest": ("Systems", "Chest"),
    "Treasure": ("Systems", "Treasure"),
    "Boss": ("Systems", "Boss"),
    "Codes": ("Systems", "Codes"),
    "Rewards": ("Systems", "Rewards"),
    "Backpack": ("Systems", "Backpack"),
    "Tutorial": ("Systems", "Tutorial"),
    "Planner": ("Progression", "Planner"),
    "Engine": ("Progression", "DecisionEngine"),
    "Picker": None,
}


class BuildError(RuntimeError):
    """Expected build failure with a concise user-facing message."""


def fail(message: str) -> None:
    raise BuildError(message)


def lua_quote(value: str) -> str:
    return (
        '"'
        + value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\r", "\\r")
        .replace("\n", "\\n")
        + '"'
    )


def normalized_source(text: str) -> str:
    return text.replace("\r\n", "\n").replace("\r", "\n")


def safe_path(root: Path, rel: str, *, must_exist: bool = True) -> Path:
    if not isinstance(rel, str) or not rel.strip():
        fail("source path must be a non-empty string")
    if "\\" in rel:
        fail(f"source path must use '/': {rel}")
    pure = PurePosixPath(rel)
    if pure.is_absolute() or ".." in pure.parts or "." in pure.parts:
        fail(f"unsafe source path: {rel}")
    path = (root / Path(*pure.parts)).resolve()
    try:
        path.relative_to(root.resolve())
    except ValueError:
        fail(f"source escapes repository: {rel}")
    if must_exist and not path.is_file():
        fail(f"missing source {rel}")
    return path


def read_json(path: Path, label: str) -> dict[str, Any]:
    if not path.is_file():
        fail(f"missing {label}")
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"{label} decode error: {exc}")
    if not isinstance(value, dict):
        fail(f"{label} root must be an object")
    return value


def manifest_rows(manifest: dict[str, Any]) -> list[dict[str, Any]]:
    order = manifest.get("order")
    if not isinstance(order, list) or not order:
        fail("manifest.order must be a non-empty array")
    rows: list[dict[str, Any]] = []
    seen: set[str] = set()
    for index, raw in enumerate(order):
        if not isinstance(raw, dict):
            fail(f"manifest.order[{index}] must be an object")
        rel = raw.get("path")
        key = raw.get("key")
        kind = raw.get("kind", "core")
        factory = raw.get("factory") is not False
        if not isinstance(rel, str) or not rel:
            fail(f"manifest.order[{index}] has no path")
        if rel in GENERATED_ARTIFACTS or rel == str(manifest.get("entry") or "src/boot.lua"):
            fail(f"generated/entry path is not a factory-order source: {rel}")
        if rel in seen:
            fail(f"duplicate manifest.order path: {rel}")
        if key is not None and (not isinstance(key, str) or not key):
            fail(f"manifest.order[{index}] key is invalid")
        if kind not in {"core", "optional"}:
            fail(f"manifest.order[{index}] kind must be core or optional")
        seen.add(rel)
        rows.append({"path": rel, "key": key, "kind": kind, "factory": factory})
    return rows


def expected_source_relpaths(manifest: dict[str, Any]) -> list[str]:
    """Return the exact source-hash/build order, excluding generated files."""

    rows = manifest_rows(manifest)
    boot_rel = str(manifest.get("entry") or "src/boot.lua")
    ordered = [UI_RESOLVER if row["path"] == "Game/Resolver.lua" else row["path"] for row in rows]
    ordered.extend([UI_CONTROLLER, UI_CATALOG, UI_EXTENSIONS, boot_rel, UI_ADAPTER, UI_HUB, UI_VERSION_FILE])
    if len(ordered) != len(set(ordered)):
        fail("UI source order contains a duplicate path")
    forbidden = [rel for rel in ordered if rel in GENERATED_ARTIFACTS]
    if forbidden:
        fail("generated artifact entered UI source hash: " + ", ".join(forbidden))
    return ordered


def expected_hash_relpaths(manifest: dict[str, Any]) -> list[str]:
    inputs = expected_source_relpaths(manifest)
    inputs.extend(
        [
            "manifest.json",
            "tools/build_ui.py",
            UI_RESOLVER_BASE,
            "research/UI_FEATURE_MATRIX.md",
            "research/UI_CURRENT_FEATURES.md",
        ]
    )
    if len(inputs) != len(set(inputs)):
        fail("UI hash inputs contain a duplicate path")
    return inputs


def source_hash(root: Path, relpaths: Sequence[str]) -> str:
    """Hash ordered relative names and bytes; match build_single's short SHA form."""

    digest = hashlib.sha256()
    for rel in relpaths:
        path = safe_path(root, rel)
        digest.update(rel.encode("utf-8"))
        digest.update(b"\0")
        digest.update(path.read_bytes())
        digest.update(b"\n")
    return digest.hexdigest()[:16]


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def git_short_sha(root: Path) -> str:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=root,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            check=False,
        )
    except OSError:
        return "unknown"
    value = result.stdout.strip()
    return value if result.returncode == 0 and value else "unknown"


def build_timestamp() -> str:
    raw = os.environ.get("SOURCE_DATE_EPOCH")
    if raw:
        try:
            epoch = int(raw)
        except ValueError:
            fail("SOURCE_DATE_EPOCH must be an integer")
        return datetime.fromtimestamp(epoch, tz=timezone.utc).isoformat(timespec="seconds")
    return datetime.now().astimezone().isoformat(timespec="seconds")


def target_expressions(key: str | None, aliases: Iterable[str]) -> list[str]:
    if not key:
        return []
    targets = [f"GB[{lua_quote(key)}]"]
    mapped = NS_MAP.get(key)
    if mapped:
        namespace, name = mapped
        targets.append(f"{namespace}.{name}")
    targets.extend(aliases)
    return targets


def assignment_block(
    key: str | None,
    aliases: Iterable[str],
    value: str,
    indent: str = "\t\t",
) -> str:
    return "".join(f"{indent}{target} = {value}\n" for target in target_expressions(key, aliases))


def source_banner(rel: str, key: str | None, kind: str) -> str:
    target = f"GB.{key}" if key else "bootstrap"
    return (
        "--==================================================\n"
        f"-- {rel} -> {target} [{kind}]\n"
        "--==================================================\n"
    )


def emit_source(
    rel: str,
    source: str,
    key: str | None,
    kind: str,
    factory: bool,
    aliases: Sequence[str] = (),
) -> str:
    """Emit one source directly into the production chunk without dynamic loading."""

    source = normalized_source(source).rstrip()
    if factory and not FACTORY_LINE.search(source):
        fail(f"{rel} must contain top-level 'return function(GB)'")
    core = kind == "core"
    targets = target_expressions(key, aliases)
    if factory:
        execute = (
            "\tlocal ok, inst = pcall(function()\n"
            "\t\tlocal factory = (function()\n"
            f"-- BEGIN SOURCE: {rel}\n"
            f"{source}\n"
            f"-- END SOURCE: {rel}\n"
            "\t\tend)()\n"
            "\t\tif type(factory) ~= \"function\" then\n"
            f"\t\t\terror({lua_quote(rel + ' did not return a factory')})\n"
            "\t\tend\n"
            "\t\treturn factory(GB)\n"
            "\tend)\n"
        )
    else:
        execute = (
            "\tlocal ok, inst = pcall(function()\n"
            f"-- BEGIN SOURCE: {rel}\n"
            f"{source}\n"
            f"-- END SOURCE: {rel}\n"
            "\tend)\n"
        )

    if core:
        failure = (
            "\tif not ok then\n"
            f"\t\terror(\"[Kaitun UI] init {rel}: \" .. tostring(inst), 0)\n"
            "\tend\n"
            + assignment_block(key, aliases, "inst", "\t")
        )
    else:
        fallback = assignment_block(key, aliases, "optionalStub()", "\t\t")
        failure = (
            "\tif not ok then\n"
            f"\t\tprint(\"[Kaitun UI] optional fail {rel}: \" .. tostring(inst))\n"
            f"{fallback}"
            "\telse\n"
            + assignment_block(key, aliases, "inst", "\t\t")
            + "\tend\n"
        )
    if not targets and core:
        # The bootstrap return value is intentionally ignored; its side effects
        # publish diagnostics and lifecycle functions on the existing GB table.
        pass
    return source_banner(rel, key, kind) + "do\n" + execute + failure + "end\n\n"


def preamble(
    core_version: str,
    ui_version: str,
    commit: str,
    built_at: str,
    digest: str,
) -> str:
    requeue = (
        'loadstring(game["HttpGet"]("'
        + RAW_UI_URL
        + '?cb=" .. tostring(os.time())))()'
    )
    template = """--==================================================
-- GRAND BLUE KAITUN UI
-- VERSION / BOOT
--==================================================
-- GENERATED by tools/build_ui.py - DO NOT MANUALLY EDIT
-- SOURCE_HASH: @@SOURCE_HASH@@
-- UI-Version: @@UI_VERSION_TEXT@@
-- Core-Version: @@CORE_VERSION_TEXT@@
-- Commit: @@COMMIT_TEXT@@
-- BuiltAt: @@BUILT_AT_TEXT@@

local VERSION = @@CORE_VERSION@@
local UI_VERSION = @@UI_VERSION@@
local BUILD = @@COMMIT@@
local BUILD_AT = @@BUILT_AT@@

if type(getgenv) ~= "function" then
	error("[Kaitun UI] getgenv missing")
end

local ENV = getgenv()
ENV.GB_VERSION = VERSION
ENV.GB_UI_VERSION = UI_VERSION
ENV.GB_COMMIT = BUILD
ENV.GB_BUILD_AT = BUILD_AT

local function startSessionLog()
	if ENV.GB_LOG_FILE == false then
		return
	end
	if typeof(writefile) ~= "function" then
		print("[Kaitun UI] writefile missing - console only")
		return
	end
	if typeof(makefolder) == "function" then
		pcall(makefolder, "GBKaitun")
		pcall(makefolder, "GBKaitun/logs")
	end
	local stamp = tostring(os.time())
	pcall(function()
		stamp = os.date("%Y%m%d_%H%M%S")
	end)
	local path = "GBKaitun/logs/kaitun_ui_" .. stamp .. ".txt"
	local latest = "GBKaitun/logs/ui_latest.txt"
	local lines = {}
	local bytes = 0
	local lastFlush = 0
	local rawPrint = ENV._GBKaitunRawPrint or print
	local MAX_BYTES = 1500000

	ENV._GBKaitunRawPrint = rawPrint

	local function clockPrefix()
		local ok, value = pcall(os.date, "%H:%M:%S")
		if ok and type(value) == "string" then
			return value
		end
		return string.format("%.2f", os.clock())
	end

	local function flush(force)
		local now = os.clock()
		if not force and now - lastFlush < 0.25 and bytes < 8192 then
			return
		end
		lastFlush = now
		local body = table.concat(lines)
		pcall(writefile, path, body)
		pcall(writefile, latest, body)
	end

	local function writeLine(line)
		local row = clockPrefix() .. " " .. tostring(line or "") .. "\\n"
		lines[#lines + 1] = row
		bytes = bytes + #row
		if bytes > MAX_BYTES then
			local keep = {}
			local keptBytes = 0
			for index = #lines, 1, -1 do
				keptBytes = keptBytes + #lines[index]
				keep[#keep + 1] = lines[index]
				if keptBytes > math.floor(MAX_BYTES * 0.6) then
					break
				end
			end
			lines = {}
			for index = #keep, 1, -1 do
				lines[#lines + 1] = keep[index]
			end
			bytes = keptBytes
		end
		flush(false)
	end

	local header = string.format(
		"-- Grand Blue Kaitun UI session log\\n-- file=%s\\n-- also=%s\\n",
		path,
		latest
	)
	pcall(writefile, path, header)
	pcall(writefile, latest, header)
	lines[1] = header
	bytes = #header

	ENV._GBKaitunLogPath = path
	ENV._GBKaitunLogLatest = latest
	ENV._GBKaitunLogWrite = writeLine
	ENV._GBKaitunLogFlush = function()
		flush(true)
	end

	print = function(...)
		local parts = {}
		for index = 1, select("#", ...) do
			parts[index] = tostring(select(index, ...))
		end
		writeLine(table.concat(parts, " "))
		rawPrint(...)
	end
end

startSessionLog()

local function stopPreviousInstances()
	local seen = {}
	local stopped = false

	local function stopOne(previous)
		if type(previous) ~= "table" or seen[previous] then
			return
		end
		seen[previous] = true
		for _, method in ipairs({ "Stop", "Destroy", "unload" }) do
			local callback = previous[method]
			if type(callback) == "function" then
				local ok = pcall(callback)
				if not ok then
					ok = pcall(callback, previous)
				end
				if ok then
					stopped = true
					return
				end
			end
		end
	end

	stopOne(ENV.GBKaitunUI)
	stopOne(ENV.GBKaitun)
	if not stopped and type(ENV._GBKaitunUnload) == "function" then
		pcall(ENV._GBKaitunUnload)
		stopped = true
	end
	if stopped then
		task.wait(0.12)
	end
end

stopPreviousInstances()

local GEN = (tonumber(ENV._GBKaitunGen) or 0) + 1
ENV._GBKaitunGen = GEN

local function dead()
	return ENV._GBKaitunGen ~= GEN
end

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
if not lp then
	repeat
		task.wait()
	until Players.LocalPlayer
	lp = Players.LocalPlayer
end

local Core = {}
local Game = {}
local Systems = {}
local Progression = {}
local Data = {}
local UI = {}

local function optionalStub()
	local stub = {}
	setmetatable(stub, {
		__index = function()
			return function() end
		end,
	})
	return stub
end

local GB = {
	Version = VERSION,
	UIVersion = UI_VERSION,
	Build = BUILD,
	Running = true,
	Connections = {},
	Tasks = {},
	gen = GEN,
	dead = dead,
	lp = lp,
	conns = nil,
	Core = Core,
	Game = Game,
	Systems = Systems,
	Progression = Progression,
	Data = Data,
	UI = UI,
}
GB.conns = GB.Connections
GB.Connections = GB.conns

ENV._GBKaitunMeta = {
	VERSION = VERSION,
	UI_VERSION = UI_VERSION,
	COMMIT = BUILD,
	BUILD_AT = BUILD_AT,
	SOURCE_HASH = "@@SOURCE_HASH@@",
	SOURCE_MODE = "UI_SINGLE",
}

-- The queued command is inert until Roblox teleports to a new session.
local function queueSameFile()
	if type(queue_on_teleport) ~= "function" then
		return
	end
	local cmd = [[@@REQUEUE@@]]
	pcall(queue_on_teleport, cmd)
end
queueSameFile()

if type(getgenv().GBConfig) ~= "table" then
	getgenv().GBConfig = {}
end
getgenv().GBConfig.Enabled = false

print("[Kaitun UI] GrandBlueKaitun UI v" .. UI_VERSION .. " core " .. VERSION)
print("[Kaitun UI] Build " .. BUILD)
print("[Kaitun UI] Initializing...")
local bootAt = os.clock()

"""
    replacements = {
        "@@SOURCE_HASH@@": digest,
        "@@UI_VERSION_TEXT@@": ui_version,
        "@@CORE_VERSION_TEXT@@": core_version,
        "@@COMMIT_TEXT@@": commit,
        "@@BUILT_AT_TEXT@@": built_at,
        "@@CORE_VERSION@@": lua_quote(core_version),
        "@@UI_VERSION@@": lua_quote(ui_version),
        "@@COMMIT@@": lua_quote(commit),
        "@@BUILT_AT@@": lua_quote(built_at),
        "@@REQUEUE@@": requeue,
    }
    for token, value in replacements.items():
        template = template.replace(token, value)
    return template


def scheduler_handoff() -> str:
    return """--==================================================
-- UI scheduler ownership
--==================================================
Systems.Movement = GB.World
Core.Invariants = GB.Recovery
Data.NPCs = GB.GeneratedData
Data.Skills = GB.GeneratedData
Data.Tutorials = GB.GeneratedData

if type(GB.Scheduler) ~= "table"
	or type(GB.Scheduler.remove) ~= "function"
	or type(GB.Scheduler.add) ~= "function"
then
	error("[Kaitun UI] scheduler unavailable after bootstrap")
end
if type(GB.UIController) ~= "table" or type(GB.UIController.tick) ~= "function" then
	error("[Kaitun UI] UI controller unavailable after bootstrap")
end

GB.Scheduler.remove("engine")
GB.Scheduler.add("engine", function()
	GB.UIController.tick()
end, 0)

GB.Scheduler.remove("respawn")
GB.Scheduler.add("respawn", function()
	if GB.Config.AutoRespawn ~= false and GB.Respawn and GB.Respawn.tick then
		GB.Respawn.tick()
	end
end, 0.25, { critical = true, first = true })

"""


def niaui_loader() -> str:
    return f"""--==================================================
-- NiaUI external load (once)
--==================================================
do
	local NIAUI_URL = {lua_quote(NIAUI_URL)}
	local okGet, source = pcall(function()
		return game:HttpGet(NIAUI_URL)
	end)
	if not okGet or type(source) ~= "string" or #source < 32 then
		print("[NiaUI] failed to load")
		print("[GBUI] abort: NiaUI unavailable")
		if type(GB.Stop) == "function" then
			pcall(GB.Stop)
		end
		error("[NiaUI] failed to load", 0)
	end
	local okLoad, library = pcall(function()
		return loadstring(source)()
	end)
	if not okLoad or type(library) ~= "table" or type(library.CreateWindow) ~= "function" then
		print("[NiaUI] failed to load")
		print("[GBUI] abort: NiaUI init failed: " .. tostring(library))
		if type(GB.Stop) == "function" then
			pcall(GB.Stop)
		end
		error("[NiaUI] failed to load", 0)
	end
	GB.NiaLibrary = library
	print("[GBUI] NiaUI loaded")
end

"""


def epilogue() -> str:
    return """--==================================================
-- UI lifecycle and public API
--==================================================
if GB._uiLifecycleWrapped then
	error("[Kaitun UI] lifecycle already wrapped")
end
if type(GB.Stop) ~= "function"
	or type(GB.Destroy) ~= "function"
	or type(GB.unload) ~= "function"
then
	error("[Kaitun UI] original lifecycle unavailable")
end

GB._uiLifecycleWrapped = true
local originalStop = GB.Stop
local originalDestroy = GB.Destroy
local originalUnload = GB.unload
local uiCleaned = false

local function destroyComponent(component, methods)
	if type(component) ~= "table" then
		return
	end
	for _, method in ipairs(methods) do
		local callback = component[method]
		if type(callback) == "function" then
			local ok = pcall(callback, component)
			if not ok then
				pcall(callback)
			end
			return
		end
	end
end

local function cleanupUI()
	if uiCleaned then
		return
	end
	uiCleaned = true
	destroyComponent(GB.UIHub, { "Destroy", "destroy", "Unload", "unload" })
	destroyComponent(GB.UIAdapter, { "Unload", "Destroy", "destroy" })
	destroyComponent(GB.NiaLibrary, { "Unload", "Destroy", "destroy" })
	destroyComponent(GB.Nia, { "Unload", "Destroy", "destroy" })
	destroyComponent(GB.UIController, { "destroy", "Destroy", "Stop", "stop" })
	destroyComponent(GB.UIExtensions, { "destroy", "Destroy" })
end

GB._cleanupUI = cleanupUI
GB.Stop = function(...)
	cleanupUI()
	return originalStop(...)
end
GB.Destroy = function(...)
	cleanupUI()
	return originalDestroy(...)
end
GB.unload = function(...)
	cleanupUI()
	return originalUnload(...)
end

getgenv()._GBKaitunUnload = GB.unload
getgenv().GBKaitunUI = GB
getgenv().GBKaitun = GB
getgenv().GBConfig = GB.Config
getgenv().GB_VERSION = VERSION
getgenv().GB_UI_VERSION = UI_VERSION

GB.Config.Enabled = true
GB.UIReady = true

print(string.format("[Kaitun UI] UI Ready in %.2fs", os.clock() - bootAt))
print("[Kaitun UI] SourceHttpAfterBoot=0")
"""


def validate_generated(source: str, source_order: Sequence[str]) -> None:
    if not source.startswith("--==================================================\n-- GRAND BLUE KAITUN UI"):
        fail("generated header is invalid")
    for forbidden in ("function LoadModule", "local function LoadModule", "GB_BASE_URL", "GB_USE_BUNDLE"):
        if forbidden in source:
            fail(f"generated output contains forbidden marker {forbidden}")
    if PROJECT_REQUIRE.search(source):
        fail("generated output contains a project-owned require")
    if PROJECT_READ.search(source):
        fail("generated output contains direct project file loading")
    if source.count("HttpGet") != 2 or source.count("loadstring") != 2:
        fail("generated output must contain exactly two request/compile token pairs")
    if "/kaitun_ui.lua?cb=" not in source:
        fail("teleport requeue does not target kaitun_ui.lua")
    if source.count(NIAUI_URL) != 1:
        fail("generated output must load NiaUI from the official URL exactly once")
    if re.search(r"""https?://[^\s"'[\]]*(?:NiaInline|/Nia\.lua)[^\s"'[\]]*""", source, re.I):
        fail("generated output contains a copied Nia source URL")
    if "function Nia:CreateWindow" in source or "Instance.new(\"ScreenGui\")" in source:
        fail("generated output still contains an inlined hub renderer")
    positions: list[int] = []
    for rel in source_order:
        if rel == UI_VERSION_FILE:
            continue
        marker = f"-- BEGIN SOURCE: {rel}"
        position = source.find(marker)
        if position < 0:
            fail(f"generated output missing source marker {rel}")
        positions.append(position)
    if positions != sorted(positions):
        fail("generated source sections are out of order")


def atomic_write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp_name: str | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            newline="\n",
            dir=path.parent,
            prefix=f".{path.name}.",
            suffix=".tmp",
            delete=False,
        ) as handle:
            temp_name = handle.name
            handle.write(text)
            handle.flush()
            os.fsync(handle.fileno())
        os.chmod(temp_name, 0o644)
        os.replace(temp_name, path)
    finally:
        if temp_name and os.path.exists(temp_name):
            os.unlink(temp_name)


def stored_headless_hash(ui_manifest: dict[str, Any]) -> str | None:
    direct = ui_manifest.get("headless_sha256")
    nested = (ui_manifest.get("build") or {}).get("headless_sha256") if isinstance(ui_manifest.get("build"), dict) else None
    values = {str(value) for value in (direct, nested) if value not in (None, "")}
    if len(values) > 1:
        fail("ui_manifest has conflicting headless_sha256 values")
    if not values:
        return None
    value = values.pop()
    if not re.fullmatch(r"[0-9a-f]{64}", value):
        fail("ui_manifest headless_sha256 is invalid")
    return value


def build_metadata(
    *,
    ui_version: str,
    core_version: str,
    commit: str,
    built_at: str,
    digest: str,
    sources: Sequence[str],
    hash_inputs: Sequence[str],
    headless_digest: str,
    output: str,
) -> dict[str, Any]:
    return {
        "version": ui_version,
        "core_version": core_version,
        "commit": commit,
        "built_at": built_at,
        "source_hash": digest,
        "production": PRODUCTION,
        "sources": list(sources),
        "hash_inputs": list(hash_inputs),
        "headless_sha256": headless_digest,
        "artifact_sha256": hashlib.sha256(output.encode("utf-8")).hexdigest(),
        "line_count": len(output.splitlines()),
        "byte_count": len(output.encode("utf-8")),
    }


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    main_manifest = read_json(root / "manifest.json", "manifest.json")
    ui_manifest = read_json(root / UI_MANIFEST, UI_MANIFEST)

    ui_version_path = safe_path(root, UI_VERSION_FILE)
    ui_version = ui_version_path.read_text(encoding="utf-8").strip()
    if not ui_version:
        fail("UI_VERSION is empty")
    if str(ui_manifest.get("version") or "").strip() != ui_version:
        fail("UI_VERSION != ui_manifest.version")

    core_version = str(main_manifest.get("version") or "").strip()
    if not core_version:
        fail("manifest.version is empty")

    rows = manifest_rows(main_manifest)
    sources = expected_source_relpaths(main_manifest)
    hash_inputs = expected_hash_relpaths(main_manifest)
    for rel in hash_inputs:
        safe_path(root, rel)

    resolver_base = safe_path(root, UI_RESOLVER_BASE).read_text(encoding="utf-8").strip()
    if not re.fullmatch(r"[0-9a-f]{64}", resolver_base):
        fail(f"{UI_RESOLVER_BASE} is invalid")
    resolver_core = sha256_file(safe_path(root, "Game/Resolver.lua"))
    if resolver_core != resolver_base:
        fail(
            "Game/Resolver.lua changed; rebase UI/Resolver.lua and update "
            f"{UI_RESOLVER_BASE}"
        )

    headless_path = safe_path(root, HEADLESS_PRODUCTION)
    headless_before = sha256_file(headless_path)
    recorded_headless = stored_headless_hash(ui_manifest)
    if recorded_headless and recorded_headless != headless_before:
        fail(
            "kaitun.lua changed since the first UI build "
            f"(recorded={recorded_headless}, current={headless_before})"
        )
    locked_headless = recorded_headless or headless_before

    digest = source_hash(root, hash_inputs)
    commit = os.environ.get("GB_UI_SOURCE_COMMIT", "").strip() or git_short_sha(root)
    if not re.fullmatch(r"[0-9a-f]{7,40}", commit):
        fail("UI source commit must be a 7-40 character lowercase Git SHA")
    built_at = build_timestamp()
    boot_rel = str(main_manifest.get("entry") or "src/boot.lua")

    parts = [preamble(core_version, ui_version, commit, built_at, digest)]
    for row in rows:
        rel = row["path"]
        source_rel = UI_RESOLVER if rel == "Game/Resolver.lua" else rel
        source = safe_path(root, source_rel).read_text(encoding="utf-8")
        parts.append(
            emit_source(
                source_rel,
                source,
                row["key"],
                row["kind"],
                bool(row["factory"]),
            )
        )

    parts.append(
        emit_source(
            UI_CONTROLLER,
            safe_path(root, UI_CONTROLLER).read_text(encoding="utf-8"),
            "UIController",
            "core",
            True,
            aliases=("UI.Controller",),
        )
    )
    parts.append(
        emit_source(
            UI_CATALOG,
            safe_path(root, UI_CATALOG).read_text(encoding="utf-8"),
            "UICatalog",
            "core",
            True,
            aliases=("UI.Catalog",),
        )
    )
    parts.append(
        emit_source(
            UI_EXTENSIONS,
            safe_path(root, UI_EXTENSIONS).read_text(encoding="utf-8"),
            "UIExtensions",
            "core",
            True,
            aliases=("UI.Extensions",),
        )
    )
    parts.append(
        emit_source(
            boot_rel,
            safe_path(root, boot_rel).read_text(encoding="utf-8"),
            None,
            "core",
            True,
        )
    )
    parts.append(scheduler_handoff())
    parts.append(niaui_loader())
    parts.append(
        emit_source(
            UI_ADAPTER,
            safe_path(root, UI_ADAPTER).read_text(encoding="utf-8"),
            "UIAdapter",
            "core",
            True,
            aliases=("UI.Adapter",)
        )
    )
    parts.append(
        emit_source(
            UI_HUB,
            safe_path(root, UI_HUB).read_text(encoding="utf-8"),
            "UIHub",
            "core",
            True,
            aliases=("UI.Hub",),
        )
    )
    parts.append(epilogue())
    output = "".join(parts)
    validate_generated(output, sources)

    destination = root / PRODUCTION
    atomic_write_text(destination, output)

    headless_after = sha256_file(headless_path)
    if headless_after != headless_before or headless_after != locked_headless:
        fail("kaitun.lua changed during UI build")

    metadata = build_metadata(
        ui_version=ui_version,
        core_version=core_version,
        commit=commit,
        built_at=built_at,
        digest=digest,
        sources=sources,
        hash_inputs=hash_inputs,
        headless_digest=locked_headless,
        output=output,
    )
    ui_manifest.update(metadata)
    ui_manifest["name"] = str(ui_manifest.get("name") or "GrandBlueKaitunUI")
    ui_manifest["schema"] = 1
    ui_manifest["build"] = dict(metadata)
    manifest_text = json.dumps(ui_manifest, indent=2, ensure_ascii=False) + "\n"
    atomic_write_text(root / UI_MANIFEST, manifest_text)

    print("[build_ui] OK")
    print(f"[build_ui] ui_version={ui_version} core_version={core_version}")
    print(f"[build_ui] commit={commit}")
    print(f"[build_ui] source_hash={digest}")
    print(f"[build_ui] headless_sha256={locked_headless}")
    print(f"[build_ui] lines={metadata['line_count']}")
    print(f"[build_ui] bytes={metadata['byte_count']}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except BuildError as exc:
        print(f"[build_ui] FAIL: {exc}")
        raise SystemExit(1)
    except (OSError, UnicodeError) as exc:
        print(f"[build_ui] FAIL: {exc}")
        raise SystemExit(1)
