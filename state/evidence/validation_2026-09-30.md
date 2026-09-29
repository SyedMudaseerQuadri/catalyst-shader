# EV-002 — Offline compilation and consistency validation, M1 shaderpack

- **id:** EV-002
- **date:** 2026-09-30
- **claim:** Every Catalyst program stage compiles as GLSL 330 compatibility under every shipped preset/option configuration, and the pack's properties, lang, and block IDs are consistent.
- **environment:** Windows 11, Python 3.14, Khronos glslang 16.6.0 (`glslang-16.6.0-windows-x86_64-release.zip`, official GitHub release). No GPU driver compilation, no Minecraft/Iris runtime.
- **procedure:** `python tools/validate_shaderpack.py --glslang <path-to-glslang.exe>`
  - resolves includes with Iris semantics, injects Iris 1.21.11 standard macros (`MC_RENDER_STAGE_*` from the phase enum);
  - 21 configurations: default, the 5 performance profiles, 3 visual presets, 7 debug views, 4 shadow filter levels, shadows off;
  - consistency: official preset names, profile values allowed, Balanced profile = source defaults, every option has a lang name and is on a screen, no leaked internal boolean options, block IDs mapped to material classes, vsh/fsh pairs present.
- **result:** **PASS**. 98 program stages × 21 configurations = 2058 compilations; 18 options; 5 profiles; 3 dimensions.
- **negative control:** a copy with an injected type error (`vec2 broken = c;`) failed with a glslang error. A copy with an include guard written as `#ifndef` failed with "option CATALYST_FOG has no lang name / not on any screen". So the validator detects both failure classes.
- **not covered (still UNVERIFIED):** Iris's compatibility→core source patching, NVIDIA/AMD/Intel driver compilers, in-game loading, visuals, performance.
- **confidence:** HIGH for syntax/type correctness of the source; NONE for runtime behavior.
