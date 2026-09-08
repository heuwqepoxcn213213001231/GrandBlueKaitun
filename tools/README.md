# Tools

## Hardening suite

From repo root:

```bash
python3 tools/run_hardening.py
```

That compiles `Game/GeneratedData.lua` from research JSON, then runs:

- `tools/validate_game_data.py`
- `tools/quest_route_validator.py`
- `tools/perf_static_audit.py`
- `tools/regression_tests.py`
- `tools/diff_game_data.py`

Do **not** run `gen_quest_artifacts.py` unless you re-apply escort marker overrides (`Mayor Kiyoshi Escort`). Runtime overlays live in `tools/build_game_data.py`.

## Quest route validator

From repo root:

```bash
python3 tools/build_game_data.py
python3 tools/quest_route_validator.py
```

`quest_route_validator.py` walks Fresh → Anchor → Clown → Maple. FAIL codes: `UNHANDLED_STAGE`, `MISSING_SOURCE`, `MISSING_HANDLER`, `MISSING_VALIDATION`, `UNRESOLVED_DEPENDENCY`, `CYCLE`, `DEAD_END`.

## Runtime log watcher (test PC)

Each script start writes a **new** human-readable dump (every `print` + every Logger line, including console-deduped repeats):

- `GBKaitun/logs/kaitun_<YYYYMMDD_HHMMSS>.txt`
- `GBKaitun/logs/latest.txt` (same run, overwrite-friendly)

Copy from the executor workspace folder. Disable with `getgenv().GB_LOG_FILE = false`.

Executor also writes diagnostics (no cookies/tokens) when `writefile` exists:

- `GBKaitun/runtime/latest.jsonl`
- `GBKaitun/runtime/<session>.jsonl`
- `runtime_reports/<session>/<quest>_<stage>.json` on dead-end once

That path is the **executor filesystem**, not this git tree. On the test PC, point the watcher at the folder Synapse/AW/your executor uses for `writefile`.

1. Copy `tools/runtime_watcher.local.json.example` to `tools/runtime_watcher.local.json` (gitignored).
2. Set `watch_dir` to the executor diagnostic folder and `machine_alias` to a short name.
3. Run:

```bash
cd /path/to/GrandBlueKaitun
python3 tools/runtime_log_watcher.py
```

Or with env only (no local json):

```bash
export GBKAITUN_RUNTIME_DIR="$HOME/Library/Application Support/YourExecutor/GBKaitun/runtime"
export GBKAITUN_MACHINE_ALIAS="testpc"
python3 tools/runtime_log_watcher.py
```

Optional git import (only if this machine already has `git push` auth — no tokens in source):

```bash
export GBKAITUN_WATCHER_GIT=1
python3 tools/runtime_log_watcher.py
```

The watcher copies only `*.json` / `*.jsonl` that look like Kaitun dumps (`PlaceId` + `Quest`/`Version`). It skips files that contain cookie/token/secret keys.

In-game dump: `GBKaitun:DumpRuntimeIssue()` (or `GBKaitun.DumpRuntimeIssue()`).
