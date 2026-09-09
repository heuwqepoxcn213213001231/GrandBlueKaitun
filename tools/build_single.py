#!/usr/bin/env python3
"""Emit repository-root kaitun.lua as a true single-file production chunk.

Developer sources stay modular. Runtime is one compile: no LoadModule,
no project HttpGet, no loadstring of project source.
"""

from __future__ import annotations

import hashlib
import json
import re
from datetime import datetime
from pathlib import Path
import subprocess
import sys


FACTORY_LINE = re.compile(r"^return function\(GB\)\s*$")

NS_MAP = {
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

SECTION_TITLE = {
    "Config.lua": "Config",
    "Core/Logger.lua": "Core.Logger",
    "Core/Profiler.lua": "Core.Profiler",
    "Core/Cache.lua": "Core.Cache",
    "Core/Retry.lua": "Core.Retry",
    "Core/RemoteBroker.lua": "Core.RemoteBroker",
    "Core/Scheduler.lua": "Core.Scheduler",
    "Core/Persist.lua": "Core.Persist",
    "Core/State.lua": "Core.State",
    "Core/Recovery.lua": "Core.Recovery",
    "Core/Invariants.lua": "Core.Invariants",
    "Systems/Respawn.lua": "Systems.Respawn",
    "Game/Remotes.lua": "Game.Remotes",
    "Game/Resolver.lua": "Game.Resolver",
    "Game/PlayerData.lua": "Game.PlayerData",
    "Game/World.lua": "Game.World",
    "Game/ItemData.lua": "Data.Items",
    "Game/GeneratedData.lua": "Data.Generated",
    "Game/Knowledge.lua": "Game.Knowledge",
    "Game/QuestData.lua": "Data.Quests",
    "Game/QuestSpecs.lua": "Data.QuestSpecs",
    "Game/Inventory.lua": "Game.Inventory",
    "Systems/Combat.lua": "Systems.Combat",
    "Systems/Quest.lua": "Systems.Quest",
    "Systems/Acquire.lua": "Systems.Acquire",
    "Systems/Stats.lua": "Systems.Stats",
    "Systems/Skills.lua": "Systems.Skills",
    "Systems/Equipment.lua": "Systems.Equipment",
    "Systems/Shop.lua": "Systems.Shop",
    "Systems/Travel.lua": "Systems.Travel",
    "Systems/Boat.lua": "Systems.Boat",
    "Systems/Fruit.lua": "Systems.Fruit",
    "Systems/Haki.lua": "Systems.Haki",
    "Systems/RaceTrait.lua": "Systems.RaceTrait",
    "Systems/LifeSkills.lua": "Systems.LifeSkills",
    "Systems/Chest.lua": "Systems.Chest",
    "Systems/Treasure.lua": "Systems.Treasure",
    "Systems/Boss.lua": "Systems.Boss",
    "Systems/Codes.lua": "Systems.Codes",
    "Systems/Rewards.lua": "Systems.Rewards",
    "Systems/Backpack.lua": "Systems.Backpack",
    "Systems/Tutorial.lua": "Systems.Tutorial",
    "Progression/Planner.lua": "Progression.Planner",
    "Progression/DecisionEngine.lua": "Progression.DecisionEngine",
    "picker.lua": "Picker",
    "src/boot.lua": "Bootstrap",
}

KAITUN_RAW = (
    "https://raw.githubusercontent.com/heuwqepoxcn213213001231/"
    "GrandBlueKaitun/main/kaitun.lua"
)


def fail(msg: str) -> None:
    print(f"[build_single] FAIL: {msg}")
    raise SystemExit(1)


def git_short_sha(root: Path) -> str:
    try:
        out = subprocess.check_output(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=root,
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip()
        return out or "unknown"
    except Exception:
        return "unknown"


def lua_quote(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def split_factory(src: str) -> tuple[str, str] | None:
    lines = src.replace("\r\n", "\n").replace("\r", "\n").split("\n")
    idx = None
    for i, line in enumerate(lines):
        if FACTORY_LINE.match(line):
            idx = i
            break
    if idx is None:
        return None
    header = "\n".join(lines[:idx]).rstrip()
    rest = "\n".join(lines[idx + 1 :])
    if not rest.rstrip().endswith("end"):
        fail("factory file must end with end")
    return header, rest


def source_hash(paths: list[Path]) -> str:
    h = hashlib.sha256()
    for path in paths:
        rel = path.as_posix()
        h.update(rel.encode("utf-8"))
        h.update(b"\0")
        h.update(path.read_bytes())
        h.update(b"\n")
    return h.hexdigest()[:16]


def assign_ns(key: str) -> str:
    mapped = NS_MAP.get(key)
    if not mapped:
        return ""
    ns, name = mapped
    return f"\t\t{ns}.{name} = inst\n"


def emit_factory(rel: str, src: str, key: str, kind: str, factory_ok: bool) -> str:
    title = SECTION_TITLE.get(rel, rel)
    banner = (
        "--==================================================\n"
        f"-- {title}\n"
        "--==================================================\n"
    )
    core = kind == "core"
    err_core = f'error("[Kaitun] init {rel} " .. tostring(inst))'
    err_opt = (
        f'print("[Kaitun] optional fail {rel} — " .. tostring(inst))\n'
        f"\t\tGB[{lua_quote(key)}] = optionalStub()"
        if key
        else f'print("[Kaitun] optional fail {rel} — " .. tostring(inst))'
    )
    assign = ""
    if key:
        assign = f"\t\tGB[{lua_quote(key)}] = inst\n" + assign_ns(key)

    split = split_factory(src) if factory_ok else None
    if factory_ok and split is None:
        fail(f"{rel} must start with return function(GB)")
    if factory_ok:
        header, rest = split
        header_block = (header + "\n") if header else ""
        return (
            f"{banner}do\n"
            f"{header_block}"
            "\tlocal factory = function(GB)\n"
            f"{rest}\n"
            "\tlocal ok, inst = pcall(factory, GB)\n"
            "\tif not ok then\n"
            f"\t\t{err_core if core else err_opt}\n"
            "\telse\n"
            f"{assign}"
            "\tend\n"
            "end\n\n"
        )

    picker_assign = ""
    if key:
        picker_assign = (
            f"\telseif type(inst) == \"table\" then\n"
            f"\t\tGB[{lua_quote(key)}] = inst\n"
        )
    else:
        picker_assign = "\telseif false then\n"
    return (
        f"{banner}do\n"
        "\tlocal chunk = function()\n"
        f"{src.rstrip()}\n"
        "\tend\n"
        "\tlocal ok, inst = pcall(chunk)\n"
        "\tif not ok then\n"
        f"\t\t{err_opt}\n"
        f"{picker_assign}"
        "\tend\n"
        "end\n\n"
    )


def preamble(version: str, commit: str, built_at: str, source_hash_value: str) -> str:
    requeue = (
        'loadstring(game["HttpGet"]("'
        + KAITUN_RAW
        + '?cb=" .. tostring(os.time())))()'
    )
    return f"""--==================================================
-- GRAND BLUE KAITUN
-- VERSION / BOOT
--==================================================
-- GENERATED by tools/build_single.py — DO NOT MANUALLY EDIT
-- SOURCE_HASH: {source_hash_value}
-- Version: {version}
-- Commit: {commit}
-- BuiltAt: {built_at}

local VERSION = {lua_quote(version)}
local BUILD = {lua_quote(commit)}
local BUILD_AT = {lua_quote(built_at)}

if type(getgenv) ~= "function" then
	error("[Kaitun] getgenv missing")
end

getgenv().GB_VERSION = VERSION
getgenv().GB_COMMIT = BUILD
getgenv().GB_BUILD_AT = BUILD_AT

local function startSessionLog()
	if getgenv().GB_LOG_FILE == false then
		return
	end
	if typeof(writefile) ~= "function" then
		print("[Kaitun] writefile missing — console only")
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
	local path = "GBKaitun/logs/kaitun_" .. stamp .. ".txt"
	local latest = "GBKaitun/logs/latest.txt"
	local lines = {{}}
	local bytes = 0
	local lastFlush = 0
	local rawPrint = print
	local MAX_BYTES = 1500000

	local function clockPrefix()
		local ok, hm = pcall(os.date, "%H:%M:%S")
		if ok and type(hm) == "string" then
			return hm
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
		line = tostring(line or "")
		local row = clockPrefix() .. " " .. line .. "\\n"
		lines[#lines + 1] = row
		bytes = bytes + #row
		if bytes > MAX_BYTES then
			local keep = {{}}
			local acc = 0
			for i = #lines, 1, -1 do
				acc = acc + #lines[i]
				keep[#keep + 1] = lines[i]
				if acc > math.floor(MAX_BYTES * 0.6) then
					break
				end
			end
			local rev = {{}}
			for i = #keep, 1, -1 do
				rev[#rev + 1] = keep[i]
			end
			lines = rev
			bytes = acc
		end
		flush(false)
	end

	local header = string.format(
		"-- Grand Blue Kaitun session log\\n-- file=%s\\n-- also=%s\\n-- copy from executor workspace (GBKaitun/logs)\\n",
		path,
		latest
	)
	pcall(writefile, path, header)
	pcall(writefile, latest, header)
	lines[1] = header
	bytes = #header

	getgenv()._GBKaitunLogPath = path
	getgenv()._GBKaitunLogLatest = latest
	getgenv()._GBKaitunLogWrite = writeLine
	getgenv()._GBKaitunLogFlush = function()
		flush(true)
	end

	print = function(...)
		local n = select("#", ...)
		local parts = {{}}
		for i = 1, n do
			parts[i] = tostring(select(i, ...))
		end
		writeLine(table.concat(parts, " "))
		rawPrint(...)
	end
end

startSessionLog()

local function stopPreviousInstance()
	local prev = getgenv().GBKaitun
	local stopped = false
	if type(prev) == "table" then
		if type(prev.Stop) == "function" then
			pcall(prev.Stop)
			stopped = true
		elseif type(prev.Destroy) == "function" then
			pcall(prev.Destroy)
			stopped = true
		end
	end
	if not stopped and type(getgenv()._GBKaitunUnload) == "function" then
		pcall(getgenv()._GBKaitunUnload)
		stopped = true
	end
	if stopped then
		task.wait(0.12)
	end
end

stopPreviousInstance()

local GEN = (tonumber(getgenv()._GBKaitunGen) or 0) + 1
getgenv()._GBKaitunGen = GEN

local function dead()
	return getgenv()._GBKaitunGen ~= GEN
end

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
if not lp then
	repeat
		task.wait()
	until Players.LocalPlayer
	lp = Players.LocalPlayer
end

local Core = {{}}
local Game = {{}}
local Systems = {{}}
local Progression = {{}}
local Data = {{}}

local function optionalStub()
	local M = {{}}
	setmetatable(M, {{
		__index = function()
			return function() end
		end,
	}})
	return M
end

local GB = {{
	Version = VERSION,
	Build = BUILD,
	Running = true,
	Connections = {{}},
	Tasks = {{}},
	gen = GEN,
	dead = dead,
	lp = lp,
	conns = nil,
	Core = Core,
	Game = Game,
	Systems = Systems,
	Progression = Progression,
	Data = Data,
}}
GB.conns = GB.Connections
GB.Connections = GB.conns

getgenv()._GBKaitunMeta = {{
	VERSION = VERSION,
	COMMIT = BUILD,
	BUILD_AT = BUILD_AT,
	SOURCE_MODE = "SINGLE",
}}

-- Teleport requeue: next session loads the SAME one file. Not a boot-time project fetch.
local function queueSameFile()
	if type(queue_on_teleport) ~= "function" then
		return
	end
	local cmd = [[{requeue}]]
	pcall(queue_on_teleport, cmd)
end
queueSameFile()

print("[Kaitun] GrandBlueKaitun v" .. VERSION)
print("[Kaitun] Build " .. BUILD)
print("[Kaitun] Initializing...")
local bootAt = os.clock()

"""


def epilogue() -> str:
    return """--==================================================
-- Public API aliases
--==================================================
Systems.Movement = GB.World
Core.Invariants = GB.Recovery
Data.NPCs = GB.GeneratedData
Data.Skills = GB.GeneratedData
Data.Tutorials = GB.GeneratedData

getgenv().GBKaitun = GB
getgenv().GBConfig = GB.Config
getgenv().GB_VERSION = VERSION

print(string.format("[Kaitun] Ready in %.2fs", os.clock() - bootAt))
"""


def collect_source_paths(root: Path, manifest: dict) -> list[Path]:
    paths: list[Path] = []
    files = manifest.get("files") or {}
    for rel in files:
        if rel in {"kaitun.lua", "dist/kaitun.lua", "loader.lua"}:
            continue
        path = root / rel
        if not path.is_file():
            fail(f"missing source {rel}")
        paths.append(path)
    boot = root / "src" / "boot.lua"
    if boot.is_file() and boot not in paths:
        paths.append(boot)
    paths.append(root / "VERSION")
    unique: list[Path] = []
    seen = set()
    for p in paths:
        key = p.resolve()
        if key in seen:
            continue
        seen.add(key)
        unique.append(p)
    return unique


def main() -> None:
    root = Path(__file__).resolve().parent.parent
    version_path = root / "VERSION"
    manifest_path = root / "manifest.json"
    if not version_path.is_file():
        fail("missing VERSION")
    if not manifest_path.is_file():
        fail("missing manifest.json")

    version = version_path.read_text(encoding="utf-8").strip()
    if not version:
        fail("VERSION empty")

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if str(manifest.get("version", "")).strip() != version:
        fail("VERSION != manifest.version")

    order = manifest.get("order")
    if not isinstance(order, list) or not order:
        fail("manifest.order invalid")

    commit = git_short_sha(root)
    built_at = datetime.now().astimezone().isoformat(timespec="seconds")
    boot_rel = str(manifest.get("entry") or "src/boot.lua")
    boot_path = root / boot_rel
    if not boot_path.is_file():
        fail(f"missing entry {boot_rel}")

    hashed_paths = collect_source_paths(root, manifest)
    digest = source_hash(hashed_paths)

    parts = [preamble(version, commit, built_at, digest)]
    for row in order:
        if not isinstance(row, dict):
            fail("order row must be object")
        rel = row.get("path")
        key = row.get("key")
        kind = row.get("kind") or "core"
        factory_ok = row.get("factory") is not False
        if not isinstance(rel, str):
            fail("order row missing path")
        if rel in {"kaitun.lua", "dist/kaitun.lua", "src/boot.lua"}:
            fail(f"{rel} must not be in runtime order — boot is appended last")
        path = root / rel
        if not path.is_file():
            fail(f"missing {rel}")
        src = path.read_text(encoding="utf-8")
        parts.append(emit_factory(rel, src, key, kind, factory_ok))

    boot_src = boot_path.read_text(encoding="utf-8")
    parts.append(emit_factory(boot_rel, boot_src, None, "core", True))
    parts.append(epilogue())

    out = "".join(parts)
    if "function LoadModule" in out or "local function LoadModule" in out:
        fail("generated file contains LoadModule")
    if "GB_USE_BUNDLE" in out:
        fail("generated file contains GB_USE_BUNDLE")
    if "GB_BASE_URL" in out:
        fail("generated file contains GB_BASE_URL")

    dest = root / "kaitun.lua"
    dest.write_text(out, encoding="utf-8")

    manifest.setdefault("build", {})
    manifest["build"]["commit"] = commit
    manifest["build"]["built_at"] = built_at
    manifest["build"]["generated"] = version
    manifest["build"]["source_hash"] = digest
    manifest["build"]["bundle"] = "kaitun.lua"
    manifest["bundle"] = "kaitun.lua"
    manifest["production"] = "kaitun.lua"
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    print("[build_single] OK")
    print(f"[build_single] version={version}")
    print(f"[build_single] commit={commit}")
    print(f"[build_single] source_hash={digest}")
    print(f"[build_single] lines={out.count(chr(10)) + 1}")
    print(f"[build_single] bytes={len(out.encode('utf-8'))}")


if __name__ == "__main__":
    try:
        main()
    except json.JSONDecodeError as exc:
        fail(f"manifest decode error: {exc}")
    except KeyboardInterrupt:
        fail("interrupted")
