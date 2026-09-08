# Grand Blue Kaitun

Portable GitHub RAW loader. A clean machine needs one line — no local `NiaUISilent/Hub/Grand Blue/` folder.

## Install

```lua
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/heuwqepoxcn213213001231/GrandBlueKaitun/main/loader.lua?cb=" ..
    tostring(os.time())
))()
```

Loader reads VERSION + manifest from `main`, then executes `dist/kaitun.lua` from `manifest.build.commit`. Do not set `GB_BASE_URL` to an old commit.

DEV pin only:

```lua
getgenv().GB_DEV = true
getgenv().GB_DEV_MODULAR = true
getgenv().GB_PIN_COMMIT = "<sha>"
```

## Globals

| Name | Meaning |
|---|---|
| `GBKaitun` | Engine table (systems, `unload`, `Require`) |
| `GBConfig` | Mutable config (set before load to override defaults) |
| `GB_VERSION` | Manifest version string |
| `GBPick` / `_GBPicker` | Optional picker if `picker.lua` loaded |

## GBConfig examples

```lua
getgenv().GBConfig = {
	Enabled = true,
	Build = "Fruit",
	FruitMode = "KEEP_CURRENT",
	AutoHaki = false,
	AutoRaceTrait = false,
	AutoBackpack = false,
	LogLevel = "INFO",
}
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/heuwqepoxcn213213001231/GrandBlueKaitun/main/loader.lua?cb=" ..
    tostring(os.time())
))()
```

After boot you can still mutate `getgenv().GBConfig.AutoQuest = false`.

## Source modes

Default is **REMOTE** (HTTP only). A fresh executor with no workspace folder must work.

```lua
getgenv().GB_SOURCE_MODE = "REMOTE"  -- default
getgenv().GB_SOURCE_MODE = "LOCAL"   -- or getgenv().GB_DEV_LOCAL = true
getgenv().GB_ROOT = "path/to/this/folder/"
```

LOCAL uses `readfile` / `isfile` only. If those APIs are missing or the file is absent, it **errors** — no silent HTTP fallback.

REMOTE uses `game:HttpGet` only. It does **not** search `NiaUISilent/Hub/Grand Blue/`. Optional disk cache (`GBKaitun_cache/`) is write-after-success if `writefile` exists.

Cache bust is `?v=<manifest version>` only. No random timestamps.

## Version update

1. Bump `VERSION` and `manifest.json` `"version"` together.
2. Add/remove modules in `manifest.json` `files` + `order` (no scattered URLs).
3. Commit, push `main`.
4. Clients pick up the new tree on the next `HttpGet` of `loader.lua` (module URLs include `?v=`).

## Layout

```
loader.lua          -- the only file users copy
manifest.json
VERSION
kaitun.lua          -- boot (return function(GB))
Config.lua
picker.lua          -- optional
Core/ Game/ Systems/ Progression/
research/
```

`GB.Require("Core.State")` / `LoadModule("Core/State")` resolve to `BASE_URL + path`.

## Diagnostics

`GBKaitun.DumpRuntimeIssue()` writes a serializable dump (version, place, quest/stage/plan, inventory names — no cookies). Watcher: `python3 tools/runtime_log_watcher.py` — see `tools/README.md`.

## Persist

`Core/Persist.lua` writes `GBKaitun_persist.json` only when `writefile` exists. No filesystem → no crash.

## Unload

Re-running the loader calls `_GBKaitunUnload` first (same generation pattern as before).
