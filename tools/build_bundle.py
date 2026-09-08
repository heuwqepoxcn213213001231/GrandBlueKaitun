#!/usr/bin/env python3
"""Build deterministic production bundle for Grand Blue Kaitun."""

from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path
import subprocess
import sys


def fail(msg: str) -> None:
    print(f"[build_bundle] FAIL: {msg}")
    raise SystemExit(1)


def lua_quote(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def lua_long(s: str) -> str:
    eq = ""
    while f"]{eq}]" in s:
        eq += "="
    return f"[{eq}[{s}]{eq}]"


def row_to_lua(row: dict) -> str:
    parts: list[str] = []
    for key in ("key", "path", "kind", "factory"):
        if key not in row:
            continue
        value = row[key]
        if isinstance(value, bool):
            value_lua = "true" if value else "false"
        else:
            value_lua = lua_quote(str(value))
        parts.append(f"{key} = {value_lua}")
    return "{ " + ", ".join(parts) + " }"


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


def build_bundle(
    *,
    version: str,
    commit: str,
    built_at: str,
    owner: str,
    repo: str,
    branch: str,
    entry: str,
    order: list[dict],
    sources: dict[str, str],
) -> str:
    file_rows = []
    for rel in sorted(sources.keys()):
        file_rows.append(f'    ["{rel}"] = {lua_long(sources[rel])},')
    order_rows = []
    for row in order:
        order_rows.append("    " + row_to_lua(row) + ",")
    return f"""-- Grand Blue Kaitun bundle (generated).
-- Version: {version}
-- Commit: {commit}
-- BuiltAt: {built_at}
-- Source: {owner}/{repo}@{branch}

return function(meta)
	if type(getgenv) ~= "function" then
		error("[Kaitun][Bundle] getgenv missing")
	end
	if type(loadstring) ~= "function" then
		error("[Kaitun][Bundle] loadstring missing")
	end

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

	local BUILD_VERSION = {lua_quote(version)}
	local BUILD_COMMIT = {lua_quote(commit)}
	local BUILD_AT = {lua_quote(built_at)}
	local GEN = (tonumber(getgenv()._GBKaitunGen) or 0) + 1
	getgenv()._GBKaitunGen = GEN

	local function dead()
		return getgenv()._GBKaitunGen ~= GEN
	end

	local files = {{
{chr(10).join(file_rows)}
	}}

	local order = {{
{chr(10).join(order_rows)}
	}}

	local chunkCache = {{}}
	local function LoadModule(rel)
		if type(rel) ~= "string" then
			error("[Kaitun][Bundle] bad module path")
		end
		rel = rel:gsub("^/+", "")
		if not rel:match("%.lua$") then
			rel = rel .. ".lua"
		end
		if chunkCache[rel] ~= nil then
			return chunkCache[rel]
		end
		local src = files[rel]
		if type(src) ~= "string" then
			error("[Kaitun][Bundle] missing " .. rel)
		end
		local fn, err = loadstring(src, rel)
		if not fn then
			error("[Kaitun][Bundle] compile " .. rel .. " " .. tostring(err))
		end
		local out = fn()
		chunkCache[rel] = out
		return out
	end

	local function Require(dotted)
		local path = tostring(dotted):gsub("%.", "/")
		return LoadModule(path)
	end

	local Players = game:GetService("Players")
	local lp = Players.LocalPlayer
	if not lp then
		repeat
			task.wait()
		until Players.LocalPlayer
		lp = Players.LocalPlayer
	end

	local GB = {{
		gen = GEN,
		dead = dead,
		lp = lp,
		conns = {{}},
		LoadModule = LoadModule,
		Require = Require,
	}}

	local function optionalStub()
		local M = {{}}
		setmetatable(M, {{
			__index = function()
				return function() end
			end,
		}})
		return M
	end

	getgenv()._GBKaitunLoader = {{
		LoadModule = LoadModule,
		Require = Require,
		BASE_URL = tostring(meta and meta.BASE_URL or "bundle://dist"),
		VERSION = BUILD_VERSION,
		COMMIT = BUILD_COMMIT,
		BUILD_AT = BUILD_AT,
		SOURCE_MODE = "BUNDLE",
		OWNER = tostring(meta and meta.OWNER or ""),
		REPO = tostring(meta and meta.REPO or ""),
		BRANCH = tostring(meta and meta.BRANCH or ""),
		BUNDLE = "dist/kaitun.lua",
	}}
	getgenv().GB_VERSION = BUILD_VERSION
	getgenv().GB_COMMIT = BUILD_COMMIT
	getgenv().GB_BUILD_AT = BUILD_AT

	local loaded = 0
	for _, row in ipairs(order) do
		local key, rel, kind = row.key, row.path, row.kind or "core"
		local factoryOk = row.factory ~= false
		local ok, result = pcall(LoadModule, rel)
		if not ok then
			if kind == "core" then
				error(tostring(result))
			end
			if key then
				GB[key] = optionalStub()
			end
		else
			loaded = loaded + 1
			if factoryOk then
				if type(result) ~= "function" then
					if kind == "core" then
						error("[Kaitun][Bundle] " .. rel .. " must return function(GB)")
					end
					GB[key] = optionalStub()
				else
					local ok2, inst = pcall(result, GB)
					if not ok2 then
						if kind == "core" then
							error("[Kaitun][Bundle] init " .. rel .. " " .. tostring(inst))
						end
						GB[key] = optionalStub()
					else
						GB[key] = inst
					end
				end
			end
		end
	end

	print("[Kaitun][Loader] Loaded " .. loaded .. " modules (bundle)")
	local boot = LoadModule({lua_quote(entry)})
	if type(boot) ~= "function" then
		error("[Kaitun][Bundle] entry must return function(GB)")
	end
	boot(GB)

	getgenv().GBKaitun = GB
	getgenv().GBConfig = GB.Config
	getgenv().GB_VERSION = BUILD_VERSION
	return GB
end
"""


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
    manifest_version = str(manifest.get("version", "")).strip()
    if manifest_version != version:
        fail(f"VERSION ({version}) != manifest.version ({manifest_version})")

    files = manifest.get("files")
    order = manifest.get("order")
    if not isinstance(files, dict) or not files:
        fail("manifest.files invalid")
    if not isinstance(order, list) or not order:
        fail("manifest.order invalid")

    commit = git_short_sha(root)
    built_at = datetime.now().astimezone().isoformat(timespec="seconds")
    owner = "heuwqepoxcn213213001231"
    repo = "GrandBlueKaitun"
    branch = "main"
    entry = str(manifest.get("entry") or "kaitun.lua")

    src_files: dict[str, str] = {}
    for rel, mapped in files.items():
        if rel != mapped:
            fail(f"manifest files entry must be path=path: {rel} -> {mapped}")
        if rel == "dist/kaitun.lua":
            continue
        if not rel.endswith(".lua"):
            continue
        path = root / rel
        if not path.is_file():
            fail(f"missing source file: {rel}")
        src_files[rel] = path.read_text(encoding="utf-8")

    if entry not in src_files:
        fail(f"entry missing in bundle sources: {entry}")

    for row in order:
        if not isinstance(row, dict):
            fail("manifest.order row must be object")
        rel = row.get("path")
        if not isinstance(rel, str):
            fail("manifest.order row missing path")
        if rel not in src_files:
            fail(f"manifest.order path not in source set: {rel}")

    bundle_src = build_bundle(
        version=version,
        commit=commit,
        built_at=built_at,
        owner=owner,
        repo=repo,
        branch=branch,
        entry=entry,
        order=order,
        sources=src_files,
    )

    dist_dir = root / "dist"
    dist_dir.mkdir(parents=True, exist_ok=True)
    dist_path = dist_dir / "kaitun.lua"
    dist_path.write_text(bundle_src, encoding="utf-8")

    manifest.setdefault("build", {})
    manifest["build"]["commit"] = commit
    manifest["build"]["built_at"] = built_at
    manifest["build"]["generated"] = version
    manifest["build"]["bundle"] = "dist/kaitun.lua"
    manifest["bundle"] = "dist/kaitun.lua"
    manifest["files"]["dist/kaitun.lua"] = "dist/kaitun.lua"
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    print("[build_bundle] OK")
    print(f"[build_bundle] version={version}")
    print(f"[build_bundle] commit={commit}")
    print(f"[build_bundle] bundle={dist_path.relative_to(root)}")


if __name__ == "__main__":
    try:
        main()
    except json.JSONDecodeError as exc:
        fail(f"manifest decode error: {exc}")
    except KeyboardInterrupt:
        fail("interrupted")
