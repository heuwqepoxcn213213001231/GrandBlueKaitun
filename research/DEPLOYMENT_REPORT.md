# Deployment Report — Grand Blue Kaitun 1.0.0

## Quyết định repo

- Workspace `Tool/` **không** phải git repo (dump nhiều project).
- Không có remote GitHub sẵn cho Grand Blue.
- Chọn **repo riêng** `GrandBlueKaitun` (public) — raw URL sạch, không dính `.env` của Tool.

## GitHub auth (lúc build)

`gh auth status`: account `shuys1230sxmcsweiqpxcv` active nhưng **token keyring invalid**.

Chưa create/push được remote. Architecture + commit local đã xong.

**Một lệnh user phải chạy:**

```bash
gh auth refresh -h github.com
```

Sau đó, trong thư mục Grand Blue:

```bash
gh repo create GrandBlueKaitun --public --source=. --remote=origin --push
```

Default owner trong `loader.lua` = `shuys1230sxmcsweiqpxcv` (account `gh` đang trỏ). Raw URL **chưa tồn tại** cho đến khi push.

## Raw URL (sau khi push)

```
https://raw.githubusercontent.com/shuys1230sxmcsweiqpxcv/GrandBlueKaitun/main/loader.lua
```

Production:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/shuys1230sxmcsweiqpxcv/GrandBlueKaitun/main/loader.lua"))()
```

Nếu owner khác: `getgenv().GB_REPO = "owner/GrandBlueKaitun"` rồi HttpGet đúng owner.

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

## Local commit (đã xong)

- Branch: `main`
- Version: `1.0.0`
- Commit: `50d1add8de95930f5f851fe0cc268c0142dd5c93`
- Message: `feat: add portable GitHub remote loader`
- Working tree: clean
- Remote: chưa có (auth fail)

## Sau auth + push

```bash
gh auth refresh -h github.com
cd "/Users/lenguyenkhachuy/Downloads/Tool/NiaUISilent/Hub/Grand Blue"
gh repo create GrandBlueKaitun --public --source=. --remote=origin --push
```

Sau push:

- Repository URL: `https://github.com/shuys1230sxmcsweiqpxcv/GrandBlueKaitun`
- Raw loader URL: `https://raw.githubusercontent.com/shuys1230sxmcsweiqpxcv/GrandBlueKaitun/main/loader.lua`

Hai URL trên **chưa live** cho đến khi `gh repo create --push` thành công. Không dùng trước khi push.
