#!/usr/bin/env python3
"""Initialize local-only configuration and data directories without downloading tools."""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
EXAMPLE = SCRIPT_DIR / "toolchain.example.toml"
LOCAL = SCRIPT_DIR / "toolchain.local.toml"
LOCAL_DIRS = (
    "LocalData/Incoming",
    "LocalData/Generated",
    "LocalData/Reviews",
    "LocalData/Cache",
    "LocalData/ThirdParty",
)

OFFICIAL_LINKS = {
    "Python": "https://www.python.org/downloads/",
    "Git": "https://git-scm.com/downloads",
    "Git LFS": "https://git-lfs.com/",
    "FFmpeg": "https://ffmpeg.org/download.html",
    "Blender": "https://www.blender.org/download/",
    "MPFB": "https://extensions.blender.org/add-ons/mpfb/",
    "PowerShell": "https://learn.microsoft.com/powershell/scripting/install/installing-powershell",
    "Unity": "https://unity.com/download",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--force-config", action="store_true", help="overwrite the local TOML from the example")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not EXAMPLE.is_file():
        print("ERROR: missing toolchain.example.toml")
        return 1

    if LOCAL.exists() and not args.force_config:
        print("KEEP  Tools/Environment/toolchain.local.toml")
    else:
        shutil.copyfile(EXAMPLE, LOCAL)
        print("CREATE Tools/Environment/toolchain.local.toml")

    for relative in LOCAL_DIRS:
        (REPO_ROOT / relative).mkdir(parents=True, exist_ok=True)
        print(f"CREATE {relative}/")

    print("\nNo software, models, ROMs, weights, or external assets were downloaded.")
    print("Edit toolchain.local.toml for machine-local commands and external_source_root.")
    print("\nOfficial installation links:")
    for name, url in OFFICIAL_LINKS.items():
        print(f"- {name}: {url}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
