# Catalyst Current State

**Milestone:** M2 — Lighting, Materials, Shadows & Temporal Foundation (M1 implemented, awaiting in-game check)
**Status:** IN PROGRESS. Second in-game test done (EV-005): debug views and shadows pass; tone/color reworked in 0.3.0 (I-005, I-008), untested.
**Current objective:** Temporal foundation (motion vectors, jittered TAA, history validation and centralized invalidation).

**What exists:** `shaderpack/Catalyst/` (Iris pack, 3 dimensions, LabPBR materials), `tools/validate_shaderpack.py`,
`tools/fetch_glslang.py` (pinned compiler), `tools/tone_sim.py` (tone/color simulator), `tools/package_shaderpack.py`. Build: `dist/Catalyst-0.3.0.zip`, also attached to the GitHub Release `v0.3.0`.

**Next intended work:**
1. Human: re-test 0.3.0 with F2 screenshots per the protocol in `CHECKPOINT.md` (record as EV-006); send the F3 light readout for the room (I-006).
2. M2 temporal: TAA with jitter + reprojection + neighborhood clamp; invalidation on camera cuts, dimension change and teleports.
3. Fix whatever the in-game test finds (Iris log errors first).

**Last checkpoint:** See `CHECKPOINT.md`.
