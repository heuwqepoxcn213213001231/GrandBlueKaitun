#!/usr/bin/env python3
"""Compatibility wrapper. Production emit is tools/build_single.py."""

from __future__ import annotations

import runpy
from pathlib import Path


def main() -> None:
    root = Path(__file__).resolve().parent
    runpy.run_path(str(root / "build_single.py"), run_name="__main__")


if __name__ == "__main__":
    main()
