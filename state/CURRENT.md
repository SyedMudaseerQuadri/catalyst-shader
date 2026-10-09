# Catalyst Current State

**Milestone:** M2 — Lighting, Materials, Shadows & Temporal Foundation (M1 implemented, awaiting in-game check)
**Status:** IN PROGRESS. First in-game test done (EV-004): pack runs, interior look failed and was fixed (I-005, untested).
**Current objective:** Temporal foundation (motion vectors, jittered TAA, history validation and centralized invalidation).

**What exists:** `shaderpack/Catalyst/` (Iris pack, 3 dimensions, LabPBR materials), `tools/validate_shaderpack.py`,
`tools/fetch_glslang.py` (pinned compiler), `tools/tone_sim.py` (tone/color simulator), `tools/package_shaderpack.py`. Build: `dist/Catalyst-0.2.1.zip`.

**Next intended work:**
1. Human: re-test 0.2.1: the same room, plus outdoor day, sunset, night, cave, water with Debug View = Off (record as EV-005).
2. M2 temporal: TAA with jitter + reprojection + neighborhood clamp; invalidation on camera cuts, dimension change and teleports.
3. Fix whatever the in-game test finds (Iris log errors first).

**Last checkpoint:** See `CHECKPOINT.md`.
