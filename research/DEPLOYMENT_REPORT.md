# Deployment Report — Grand Blue Kaitun 1.0.0

Current shipped version: **1.0.2** (Graves resolve + quest executor). See `RUNTIME_FIXES.md`.

## Quyết định repo

- Workspace `Tool/` **không** phải git repo (dump nhiều project).
- Repo riêng `GrandBlueKaitun` (public) — raw URL sạch, không dính `.env` của Tool.

## GitHub auth + push

`gh auth status`: account **`heuwqepoxcn213213001231`** active (scopes: gist, read:org, repo, workflow).

`gh repo create GrandBlueKaitun --public --source=. --remote=origin --push` thành công.

| Field | Value |
|---|---|
| Repository | https://github.com/heuwqepoxcn213213001231/GrandBlueKaitun |
| Branch | `main` |
| Version | `1.0.0` |
| Commit | `d8563b42d09f07e48522201eb9a7097aa9287cb0` |
| Raw loader URL | https://raw.githubusercontent.com/heuwqepoxcn213213001231/GrandBlueKaitun/main/loader.lua |

## Production command

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/heuwqepoxcn213213001231/GrandBlueKaitun/main/loader.lua"))()
```

`GBConfig` **không bắt buộc**. Loader dùng default trong `Config.lua`. Override trước loadstring nếu cần:

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
loadstring(game:HttpGet("https://raw.githubusercontent.com/heuwqepoxcn213213001231/GrandBlueKaitun/main/loader.lua"))()
```

Loader default: owner `heuwqepoxcn213213001231`, repo `GrandBlueKaitun`, branch `main`. Override: `GB_REPO`, `GB_BRANCH`, hoặc `GB_BASE_URL`.

## Architecture

| File | Vai trò |
|---|---|
| `loader.lua` | One-liner duy nhất. Check executor, fetch VERSION+manifest, `LoadModule`, inject GB, boot. |
| `manifest.json` | version, entry, files map, order. Không URL rời. |
| `kaitun.lua` | `return function(GB)` — persist, remotes, unload, scheduler. Không `readfile`. |
| `Core/Persist.lua` | `writefile` optional. |
| `picker.lua` | Optional, cùng loader. |

### Modes

- `GB_SOURCE_MODE = "REMOTE"` (default): HTTP only. Máy trống chạy được.
- `LOCAL` / `GB_DEV_LOCAL`: `readfile` bắt buộc. Fail to nếu thiếu FS.

### Loader rules

- Cache RAM: cùng path compile/execute một lần.
- Disk cache optional (`GBKaitun_cache/<ver>/`).
- Cache bust: `?v=<manifest version>`.
- HTTP: 3 retries. Lỗi: `[Kaitun][Loader] Failed to download <path>`.
- CORE fail → abort. OPTIONAL → log + stub.
- Path chỉ từ manifest; BASE khóa `raw.githubusercontent.com/OWNER/REPO/BRANCH/`.
- Không search `NiaUISilent/Hub/Grand Blue/`, `/Users/`, `C:\`.

## Phân loại FS (grep)

| API / path | File | Class | Action |
|---|---|---|---|
| `readfile`/`isfile` module load | `kaitun.lua` (cũ) | REQUIRED | Xóa. Qua loader. |
| `writefile`/`readfile` persist | `Core/Persist.lua` | OPTIONAL persist | Giữ, no-op nếu không có FS. |
| `NiaUISilent/Hub/Grand Blue/` | `kaitun.lua` (cũ) | DEV ONLY | Xóa khỏi production. LOCAL chỉ `GB_ROOT`. |
| comment `data.json` | `QuestData.lua`, `picker.lua` | N/A | Data đã inline. Không đọc file. |
| `require(RS.Modules.*)` | `picker.lua` | game module | Không phải filesystem workspace. |

## Clean-machine verify

Production import: `loader.lua` → `fetchRemote` → `HttpGet(BASE + path + ?v=ver)`. Không còn `readfile` sibling trên đường REMOTE. Persist/cache chỉ chạy nếu executor có FS.
