#!/usr/bin/env python3
"""Download the pinned Khronos glslang release used by tools/validate_shaderpack.py.

Installs into tools/.cache/glslang/ (git-ignored). The archive's SHA-256 is pinned so every
validation run uses the same compiler build (state/evidence/validation_*.md records the version).

Usage:  python tools/fetch_glslang.py
"""

from __future__ import annotations

import hashlib
import io
import platform
import sys
import urllib.request
import zipfile
from pathlib import Path

VERSION = "16.6.0"
BASE = f"https://github.com/KhronosGroup/glslang/releases/download/{VERSION}/"
# Pinned on first verified download (2026-10-09). Only the Windows build is pinned so far;
# other platforms download unpinned and print their hash so it can be added here.
ASSETS = {
    "Windows": (f"glslang-{VERSION}-windows-x86_64-release.zip", "82bf434e69b9bb4829de7e2b4bc2c5e7a7861e53d66cf75e5cc70f5f694a8d9b"),
    "Linux": (f"glslang-{VERSION}-linux-x86_64-release.zip", None),
    "Darwin": (f"glslang-{VERSION}-macos-universal-release.zip", None),
}

CACHE = Path(__file__).resolve().parent / ".cache" / "glslang"


def main() -> int:
    system = platform.system()
    if system not in ASSETS:
        print(f"unsupported platform {system}")
        return 1
    name, expected = ASSETS[system]
    exe = CACHE / "bin" / ("glslang.exe" if system == "Windows" else "glslang")
    if exe.exists():
        print(exe)
        return 0

    print(f"downloading {name} ...", file=sys.stderr)
    data = urllib.request.urlopen(BASE + name, timeout=180).read()
    digest = hashlib.sha256(data).hexdigest()
    if expected and digest != expected:
        print(f"SHA-256 mismatch: got {digest}, expected {expected}", file=sys.stderr)
        return 1
    if not expected:
        print(f"note: unpinned download, sha256={digest}", file=sys.stderr)

    CACHE.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        z.extractall(CACHE)
    if system != "Windows":
        exe.chmod(0o755)
    print(exe)
    return 0


if __name__ == "__main__":
    sys.exit(main())
