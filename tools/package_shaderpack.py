#!/usr/bin/env python3
"""Build the release shaderpack zip (docs/architecture/governance.md 51.16, repository vs release boundary).

Only runtime files go in the zip: shaderpack/Catalyst/shaders/** plus the user-facing README.txt.
Research, docs, tools, state and reference packs are never packaged.

Usage:
  python tools/package_shaderpack.py [--version 0.1.0-m1] [--out dist]
Install: copy the zip into <minecraft>/shaderpacks/ and select it in Iris.
"""

from __future__ import annotations

import argparse
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PACK = ROOT / "shaderpack" / "Catalyst"
ALLOWED_SUFFIXES = {".vsh", ".fsh", ".gsh", ".csh", ".glsl", ".properties", ".lang", ".png", ".txt"}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--version", default="0.2.1")
    ap.add_argument("--out", default=str(ROOT / "dist"))
    args = ap.parse_args()

    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    zip_path = out_dir / f"Catalyst-{args.version}.zip"

    files = sorted(p for p in (PACK / "shaders").rglob("*") if p.is_file())
    rejected = [p for p in files if p.suffix not in ALLOWED_SUFFIXES]
    if rejected:
        print("Refusing to package unexpected files:", *[str(p.relative_to(PACK)) for p in rejected], sep="\n  ")
        return 1

    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        for p in files:
            z.write(p, p.relative_to(PACK).as_posix())
        readme = PACK / "README.txt"
        if readme.exists():
            z.write(readme, "README.txt")

    print(f"{zip_path}  ({len(files)} shader files, {zip_path.stat().st_size / 1024:.1f} KiB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
