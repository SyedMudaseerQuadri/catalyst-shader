#!/usr/bin/env python3
"""Catalyst shaderpack validator (offline, no Minecraft required).

Purpose (maintained tool, see README.md "Context policy"):
  1. Resolve every program the way Iris does (#include of "/abs" paths from the shaders root,
     relative paths from the including file), inject Iris's standard macros, and apply option
     overrides for each preset/option configuration.
  2. Compile every vertex/fragment program with Khronos glslang (reference GLSL front end).
  3. Check pack consistency: preset names, option/screen/slider/lang coverage, block IDs vs
     material classes, vertex/fragment pairs per dimension.

What a PASS here does NOT prove (record as a limitation, never as runtime evidence):
  - Iris's own source patching (compatibility -> core transform) succeeding;
  - driver-specific compilation (NVIDIA/AMD/Intel);
  - runtime behavior, visuals or performance.

Usage:
  python tools/fetch_glslang.py            # once: pinned compiler into tools/.cache/
  python tools/validate_shaderpack.py [--glslang PATH] [--pack shaderpack/Catalyst] [--quick]
Exit code 0 = all checks passed.
"""

from __future__ import annotations

import argparse
import concurrent.futures as futures
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

# Iris 1.21.11 WorldRenderingPhase order (net.irisshaders.iris.pipeline.WorldRenderingPhase);
# Iris defines MC_RENDER_STAGE_<NAME> = ordinal.
RENDER_PHASES = [
    "NONE", "SKY", "SUNSET", "CUSTOM_SKY", "SUN", "MOON", "STARS", "VOID", "TERRAIN_SOLID",
    "TERRAIN_CUTOUT_MIPPED", "TERRAIN_CUTOUT", "ENTITIES", "BLOCK_ENTITIES", "DESTROY", "OUTLINE",
    "DEBUG", "HAND_SOLID", "TERRAIN_TRANSLUCENT", "TRIPWIRE", "PARTICLES", "CLOUDS", "RAIN_SNOW",
    "WORLD_BORDER",
]

STANDARD_MACROS = {
    "MC_VERSION": "12111",
    "IRIS_VERSION": "11007",
    "MC_GL_VERSION": "460",
    "MC_GLSL_VERSION": "460",
    "IS_IRIS": "",
    "MC_OS_WINDOWS": "",
    "MC_GL_VENDOR_NVIDIA": "",
    "MC_MIPMAP_LEVEL": "4",
    "MC_RENDER_QUALITY": "1.0",
    "MC_SHADOW_QUALITY": "1.0",
    **{f"MC_RENDER_STAGE_{name}": str(i) for i, name in enumerate(RENDER_PHASES)},
}

OFFICIAL_PERFORMANCE_PROFILES = ["PERFORMANCE", "BALANCED", "QUALITY", "ULTRA", "CINEMATIC"]
OFFICIAL_VISUAL_PRESETS = ["Vanilla Enhanced", "Natural / Realistic", "Cinematic"]

INCLUDE_RE = re.compile(r'^\s*#\s*include\s+"([^"]+)"')
DEFINE_OPTION_RE = re.compile(r'^\s*(//)?\s*#define\s+(\w+)(?:\s+([^\s/]+))?\s*(?://\s*\[(.*?)\])?')
CONST_OPTION_RE = re.compile(r'^\s*const\s+(int|float|bool)\s+(\w+)\s*=\s*([^;]+);\s*//\s*\[(.*?)\]')


class Failure(Exception):
    pass


def resolve(path: Path, root: Path, stack: tuple[Path, ...] = ()) -> list[str]:
    """Return the file's lines with includes expanded (Iris semantics)."""
    if path in stack:
        raise Failure(f"circular include: {' -> '.join(str(p.relative_to(root)) for p in stack + (path,))}")
    if not path.is_file():
        raise Failure(f"missing include: {path.relative_to(root) if path.is_relative_to(root) else path}")
    out: list[str] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        m = INCLUDE_RE.match(line)
        if m:
            target = m.group(1)
            inc = root / target.lstrip("/") if target.startswith("/") else path.parent / target
            out.extend(resolve(inc.resolve(), root, stack + (path,)))
        else:
            out.append(line)
    return out


IFDEF_REF_RE = re.compile(r'^\s*#\s*if(n)?def\s+(\w+)\s*$')


def collect_options(shaders: Path) -> dict[str, dict]:
    """Options Iris would expose, using Iris's own rules (OptionAnnotatedSource, Iris 1.21.11):
      - `#define NAME value // [a b c]`         -> value option
      - `const type NAME = value; // [a b c]`   -> const option
      - `#define NAME` / `//#define NAME`       -> boolean option ONLY if some line anywhere in the pack
                                                  is exactly `#ifdef NAME` or `#ifndef NAME`
    Internal flags must therefore be tested with `#if defined NAME`, or they leak into the menu.
    """
    sources = [p for p in shaders.rglob("*") if p.suffix in (".glsl", ".vsh", ".fsh", ".gsh", ".csh")]
    ifdef_refs = set()
    for f in sources:
        for line in f.read_text(encoding="utf-8").splitlines():
            m = IFDEF_REF_RE.match(line)
            if m:
                ifdef_refs.add(m.group(2))

    options: dict[str, dict] = {}
    for f in sources:
        for line in f.read_text(encoding="utf-8").splitlines():
            c = CONST_OPTION_RE.match(line)
            if c:
                options[c.group(2)] = {"kind": "const", "default": c.group(3).strip(), "values": c.group(4).split()}
                continue
            d = DEFINE_OPTION_RE.match(line)
            if not d:
                continue
            name = d.group(2)
            if d.group(4) is not None:
                options[name] = {"kind": "define", "default": d.group(3), "values": d.group(4).split()}
            elif d.group(3) is None and name in ifdef_refs:
                options[name] = {"kind": "bool", "default": "false" if d.group(1) else "true",
                                 "values": ["true", "false"], "file": str(f.relative_to(shaders))}
    return options


def parse_properties(path: Path) -> dict[str, str]:
    props: dict[str, str] = {}
    text = path.read_text(encoding="utf-8").replace("\\\n", " ")
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        props[k.strip()] = " ".join(v.split())
    return props


def apply_overrides(lines: list[str], overrides: dict[str, str], options: dict[str, dict]) -> list[str]:
    out = []
    for line in lines:
        replaced = line
        for name, value in overrides.items():
            kind = options.get(name, {}).get("kind")
            if kind == "bool" and re.match(rf'^\s*(//)?\s*#define\s+{name}\b', line):
                replaced = f"#define {name}" if value == "true" else f"// #define {name}"
            elif kind == "define":
                replaced = re.sub(rf'^(\s*#define\s+{name}\s+)\S+', rf'\g<1>{value}', replaced)
            elif kind == "const":
                replaced = re.sub(rf'^(\s*const\s+\w+\s+{name}\s*=\s*)[^;]+;', rf'\g<1>{value};', replaced)
        out.append(replaced)
    return out


def inject_macros(lines: list[str]) -> list[str]:
    if not lines or not lines[0].startswith("#version"):
        raise Failure("first line is not #version")
    macros = [f"#define {k} {v}".rstrip() for k, v in STANDARD_MACROS.items()]
    return [lines[0]] + macros + lines[1:]


def compile_one(glslang: str, lines: list[str], stage: str, label: str, tmpdir: Path) -> str | None:
    src = tmpdir / (re.sub(r"[^\w.-]", "_", label) + (".vert" if stage == "vert" else ".frag"))
    src.write_text("\n".join(lines) + "\n", encoding="utf-8")
    proc = subprocess.run([glslang, "-S", stage, str(src)], capture_output=True, text=True)
    if proc.returncode != 0:
        msg = (proc.stdout + proc.stderr).strip()
        return f"{label}\n{msg}"
    return None


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--pack", default=str(Path(__file__).resolve().parent.parent / "shaderpack" / "Catalyst"))
    cached = Path(__file__).resolve().parent / ".cache" / "glslang" / "bin" / ("glslang.exe" if os.name == "nt" else "glslang")
    ap.add_argument("--glslang", default=os.environ.get("GLSLANG") or (str(cached) if cached.exists() else None)
                    or shutil.which("glslang") or shutil.which("glslangValidator"),
                    help="defaults to the pinned build from tools/fetch_glslang.py")
    ap.add_argument("--quick", action="store_true", help="default configuration only")
    args = ap.parse_args()

    shaders = Path(args.pack).resolve() / "shaders"
    problems: list[str] = []

    # ---------------------------------------------------------------- consistency checks
    options = collect_options(shaders)
    props = parse_properties(shaders / "shaders.properties")
    lang = parse_properties(shaders / "lang" / "en_us.lang")

    profiles = {k[len("profile."):]: v for k, v in props.items() if k.startswith("profile.")}
    if sorted(profiles) != sorted(OFFICIAL_PERFORMANCE_PROFILES):
        problems.append(f"performance profiles {sorted(profiles)} != official {OFFICIAL_PERFORMANCE_PROFILES}")
    visual_names = [lang.get(f"value.VISUAL_PRESET.{i}") for i in range(3)]
    if visual_names != OFFICIAL_VISUAL_PRESETS:
        problems.append(f"visual preset names {visual_names} != official {OFFICIAL_VISUAL_PRESETS}")

    profile_values: dict[str, dict[str, str]] = {}
    for pname, spec in profiles.items():
        values = {}
        for token in spec.split():
            if "=" not in token:
                problems.append(f"profile {pname}: unsupported token '{token}'")
                continue
            k, v = token.split("=", 1)
            if k not in options:
                problems.append(f"profile {pname}: unknown option {k}")
            elif options[k]["kind"] != "bool" and v not in options[k]["values"]:
                problems.append(f"profile {pname}: {k}={v} not in allowed values {options[k]['values']}")
            values[k] = v
        profile_values[pname] = values
    # The source defaults must equal exactly one profile (Balanced), so Iris shows it as selected.
    defaults = {k: o["default"] for k, o in options.items()}
    if "BALANCED" in profile_values and any(defaults.get(k) != v for k, v in profile_values["BALANCED"].items()):
        problems.append("source defaults do not match profile.BALANCED")

    screen_refs: list[str] = []
    for k, v in props.items():
        if k == "screen" or (k.startswith("screen.") and not k.endswith(".columns")) or k == "sliders":
            screen_refs += v.split()
    for ref in screen_refs:
        if ref in ("<empty>", "<profile>", "*") or (ref.startswith("[") and ref.endswith("]")):
            if ref.startswith("["):
                name = ref[1:-1]
                if f"screen.{name}" not in props:
                    problems.append(f"screen link {ref} has no screen.{name} definition")
                if f"screen.{name}" not in lang:
                    problems.append(f"screen {name} has no lang name")
            continue
        if ref not in options:
            problems.append(f"screen/slider references unknown option {ref}")
    for name in options:
        if name not in ("PERF_PROFILE",) and f"option.{name}" not in lang:
            problems.append(f"option {name} has no lang name")
        if name not in ("PERF_PROFILE",) and name not in screen_refs:
            problems.append(f"option {name} is not on any screen")

    classify = (shaders / "lib" / "material" / "classify.glsl").read_text(encoding="utf-8")
    block_ids = {k.split(".", 1)[1] for k in parse_properties(shaders / "block.properties") if k.startswith("block.")}
    for bid in sorted(block_ids):
        if f"blockId == {bid}" not in classify:
            problems.append(f"block.properties ID {bid} has no material mapping in classify.glsl")

    worlds = [d for d in ("world0", "world-1", "world1") if (shaders / d).is_dir()]
    programs: list[tuple[str, Path, str]] = []
    for w in worlds:
        stems = {p.stem for p in (shaders / w).glob("*.[vf]sh")}
        for stem in sorted(stems):
            for ext, stage in (("vsh", "vert"), ("fsh", "frag")):
                f = shaders / w / f"{stem}.{ext}"
                if not f.exists():
                    problems.append(f"{w}/{stem}: missing .{ext}")
                else:
                    programs.append((f"{w}/{stem}.{ext}", f, stage))

    # ---------------------------------------------------------------- configurations
    configs: dict[str, dict[str, str]] = {"default": {}}
    if not args.quick:
        for pname, values in profile_values.items():
            configs[f"profile={pname}"] = values
        for v in options["VISUAL_PRESET"]["values"]:
            configs[f"VISUAL_PRESET={v}"] = {"VISUAL_PRESET": v}
        for v in options["DEBUG_VIEW"]["values"]:
            configs[f"DEBUG_VIEW={v}"] = {"DEBUG_VIEW": v}
        for v in options["SHADOW_FILTER"]["values"]:
            configs[f"SHADOW_FILTER={v}"] = {"SHADOW_FILTER": v}
        configs["SHADOWS=off"] = {"SHADOWS": "false"}
        configs["MATERIAL_MAPS=off"] = {"MATERIAL_MAPS": "false"}

    # ---------------------------------------------------------------- compilation
    compiled = 0
    if not args.glslang:
        problems.append("glslang not found: run tools/fetch_glslang.py, pass --glslang or set GLSLANG (compilation NOT checked)")
    else:
        with tempfile.TemporaryDirectory() as td:
            tmpdir = Path(td)
            jobs = []
            with futures.ThreadPoolExecutor(max_workers=os.cpu_count() or 4) as pool:
                for cname, overrides in configs.items():
                    for label, path, stage in programs:
                        try:
                            lines = inject_macros(apply_overrides(resolve(path, shaders), overrides, options))
                        except Failure as e:
                            problems.append(f"[{cname}] {label}: {e}")
                            continue
                        jobs.append(pool.submit(compile_one, args.glslang, lines, stage, f"[{cname}] {label}", tmpdir))
                for job in jobs:
                    compiled += 1
                    err = job.result()
                    if err:
                        problems.append(err)

    # ---------------------------------------------------------------- report
    print(f"Catalyst validator: {len(programs)} program stages x {len(configs)} configurations = {compiled} compilations")
    print(f"options: {len(options)}  profiles: {len(profiles)}  block IDs: {len(block_ids)}  dimensions: {', '.join(worlds)}")
    if problems:
        print(f"\nFAIL — {len(problems)} problem(s):")
        for p in problems[:60]:
            print(" -", p)
        if len(problems) > 60:
            print(f" ... and {len(problems) - 60} more")
        return 1
    print("\nPASS — all programs compiled under glslang and all consistency checks passed.")
    print("Not covered: Iris source patching, vendor drivers, runtime/visual/performance behavior.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
