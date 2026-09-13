#!/usr/bin/env python3
"""Remove Godot's fallback launcher resources from Android library AARs."""

from __future__ import annotations

import os
import re
import sys
import tempfile
import zipfile
from pathlib import Path


LAUNCHER_RESOURCE = re.compile(
    r"res/mipmap(?:-[^/]+)?/icon(?:_(?:background|foreground|monochrome))?\.(?:png|webp|xml)"
)


def is_launcher_resource(name: str) -> bool:
    return (
        name in {"res/drawable/icon_background.xml", "res/mipmap-anydpi-v26/themed_icon.xml"}
        or LAUNCHER_RESOURCE.fullmatch(name) is not None
    )


def sanitize(aar: Path) -> list[str]:
    fd, temporary_name = tempfile.mkstemp(prefix=f".{aar.name}.", suffix=".tmp", dir=aar.parent)
    os.close(fd)
    temporary = Path(temporary_name)
    removed: list[str] = []
    try:
        with zipfile.ZipFile(aar, "r") as source, zipfile.ZipFile(temporary, "w") as target:
            for info in source.infolist():
                if is_launcher_resource(info.filename):
                    removed.append(info.filename)
                    continue
                target.writestr(info, source.read(info.filename))
        os.replace(temporary, aar)
    finally:
        temporary.unlink(missing_ok=True)
    return removed


def main(arguments: list[str]) -> int:
    if not arguments:
        print("usage: sanitize_godot_launcher_aar.py AAR [AAR ...]", file=sys.stderr)
        return 2
    for value in arguments:
        aar = Path(value)
        removed = sanitize(aar)
        print(f"{aar}: removed {len(removed)} Godot launcher resource(s)")
        for name in removed:
            print(f"  {name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
