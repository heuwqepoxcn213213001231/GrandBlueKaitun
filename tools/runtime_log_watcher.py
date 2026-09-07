#!/usr/bin/env python3
"""Watch executor Kaitun diagnostics and copy into the repo.

No credentials in this file. Git push only if this machine already has git auth.

Usage on the test PC:

  cd /path/to/GrandBlueKaitun
  python3 tools/runtime_log_watcher.py

Config (first match wins):
  env GBKAITUN_RUNTIME_DIR
  tools/runtime_watcher.local.json  (gitignored)
  default: ./GBKaitun/runtime

  env GBKAITUN_MACHINE_ALIAS or local json machine_alias (default: hostname)
  env GBKAITUN_WATCHER_GIT=1 or local json git_push to commit+push copies
"""

from __future__ import annotations

import json
import os
import shutil
import socket
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOCAL_CFG = ROOT / "tools" / "runtime_watcher.local.json"
SECRET_KEYS = {
    "cookie",
    "cookies",
    "token",
    "secret",
    "password",
    "credential",
    "authorization",
    "sessionid",
}


def load_local() -> dict:
    if not LOCAL_CFG.exists():
        return {}
    try:
        return json.loads(LOCAL_CFG.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        print("invalid tools/runtime_watcher.local.json", file=sys.stderr)
        return {}


def watch_dir(cfg: dict) -> Path:
    env = os.environ.get("GBKAITUN_RUNTIME_DIR", "").strip()
    if env:
        return Path(env).expanduser()
    if cfg.get("watch_dir"):
        return Path(str(cfg["watch_dir"])).expanduser()
    return ROOT / "GBKaitun" / "runtime"


def alias(cfg: dict) -> str:
    env = os.environ.get("GBKAITUN_MACHINE_ALIAS", "").strip()
    if env:
        return env
    if cfg.get("machine_alias"):
        return str(cfg["machine_alias"])
    return socket.gethostname().split(".")[0]


def want_git(cfg: dict) -> bool:
    if os.environ.get("GBKAITUN_WATCHER_GIT", "").strip() in {"1", "true", "yes"}:
        return True
    return bool(cfg.get("git_push"))


def is_diag(path: Path) -> bool:
    if path.name.startswith("."):
        return False
    if path.suffix not in {".json", ".jsonl"}:
        return False
    if "credential" in path.name.lower() or "secret" in path.name.lower():
        return False
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return False
    low = text.lower()
    for k in SECRET_KEYS:
        if f'"{k}"' in low:
            print(f"skip {path.name}: secret key {k}")
            return False
    if path.suffix == ".jsonl":
        return '"PlaceId"' in text or '"Version"' in text
    return '"PlaceId"' in text and '"Quest"' in text


def git_ok() -> bool:
    r = subprocess.run(
        ["git", "-C", str(ROOT), "status", "--porcelain"],
        capture_output=True,
        text=True,
    )
    return r.returncode == 0


def maybe_push(dest_files: list[Path], machine: str) -> None:
    if not dest_files:
        return
    if not git_ok():
        print("git auth/repo not available — skip commit")
        return
    rels = [str(p.relative_to(ROOT)) for p in dest_files]
    subprocess.run(["git", "-C", str(ROOT), "add", "--"] + rels, check=False)
    msg = f"chore: import kaitun runtime diagnostics ({machine})"
    c = subprocess.run(["git", "-C", str(ROOT), "commit", "-m", msg], capture_output=True, text=True)
    if c.returncode != 0:
        print(c.stdout or c.stderr or "nothing to commit")
        return
    p = subprocess.run(["git", "-C", str(ROOT), "push"], capture_output=True, text=True)
    if p.returncode != 0:
        print("git push failed (no stored credentials in watcher).")
        print(p.stderr)
    else:
        print("pushed diagnostics")


def copy_new(src: Path, dest_root: Path, seen: dict) -> list[Path]:
    copied = []
    if not src.exists():
        return copied
    dest_root.mkdir(parents=True, exist_ok=True)
    for path in src.rglob("*"):
        if not path.is_file() or not is_diag(path):
            continue
        key = str(path)
        mtime = path.stat().st_mtime
        if seen.get(key) == mtime:
            continue
        rel = path.name
        dest = dest_root / rel
        shutil.copy2(path, dest)
        seen[key] = mtime
        copied.append(dest)
        print(f"copied {path} -> {dest}")
    return copied


def main() -> int:
    cfg = load_local()
    src = watch_dir(cfg)
    machine = alias(cfg)
    dest = ROOT / "runtime_reports" / machine
    interval = float(cfg.get("interval") or os.environ.get("GBKAITUN_WATCH_INTERVAL") or 5)
    print(f"watch {src}")
    print(f"copy  {dest}")
    print(f"alias {machine}")
    print("Ctrl+C to stop")
    seen: dict = {}
    while True:
        copied = copy_new(src, dest, seen)
        reports = ROOT / "runtime_reports"
        if reports.exists():
            copied += copy_new(reports, dest, seen)
        if copied and want_git(cfg):
            maybe_push(copied, machine)
        time.sleep(interval)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("stopped")
        raise SystemExit(0)
