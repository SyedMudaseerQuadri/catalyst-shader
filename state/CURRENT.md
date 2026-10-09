# Catalyst Current State

**Milestone:** M2 — Lighting, Materials, Shadows & Temporal Foundation (M1 implemented, awaiting in-game check)
**Status:** IN PROGRESS. Materials done (EV-003); temporal foundation next. In-game verification still blocked (I-002).
**Current objective:** Temporal foundation (motion vectors, jittered TAA, history validation and centralized invalidation).

**What exists:** `shaderpack/Catalyst/` (Iris pack, 3 dimensions, LabPBR materials), `tools/validate_shaderpack.py`,
`tools/fetch_glslang.py` (pinned compiler), `tools/package_shaderpack.py`. Build: `dist/Catalyst-0.2.0-m2a.zip`.

**Next intended work:**
1. Human: install the client and run the check list in `CHECKPOINT.md`; record the results as EV-004.
2. M2 temporal: TAA with jitter + reprojection + neighborhood clamp; invalidation on camera cuts, dimension change and teleports.
3. Fix whatever the in-game test finds (Iris log errors first).

**Last checkpoint:** See `CHECKPOINT.md`.
