# Grand Blue Kaitun

One remote Lua file. One compile. Full Kaitun.

## Install

```lua
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/heuwqepoxcn213213001231/GrandBlueKaitun/main/kaitun.lua?cb="
    .. tostring(os.time())
))()
```

No second project-source HttpGet. No manifest. No `GB_BASE_URL`. No `GB_USE_BUNDLE`. `loader.lua` is retired.

Override config before load if needed:

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
```

After boot you can still mutate `getgenv().GBConfig.AutoQuest = false`.

## Globals

| Name | Meaning |
|---|---|
| `GBKaitun` | Runtime (`Stop`, `Destroy`, systems) |
| `GBConfig` | Mutable config |
| `GB_VERSION` | Embedded version string |
| `GBPick` / `_GBPicker` | Optional picker |

## Developer sources

Modular files under `Config.lua`, `Core/`, `Game/`, `Systems/`, `Progression/`, `src/boot.lua` are **edit sources**. Production `kaitun.lua` is generated:

```bash
python3 tools/build_game_data.py
python3 tools/build_single.py
python3 tools/run_hardening.py
```

If those sources change and root `kaitun.lua` is not regenerated, `tools/verify_single.py` fails.

## Diagnostics

Session log (if `writefile` exists): `GBKaitun/logs/kaitun_<time>.txt` and `latest.txt`. Disable: `getgenv().GB_LOG_FILE = false`.

`GBKaitun:DumpRuntimeIssue()` / `GBKaitun:SelfCheck()`. Watcher: `python3 tools/runtime_log_watcher.py`.

## Unload

Re-running the one-liner calls `GBKaitun:Stop()` first. One instance.
