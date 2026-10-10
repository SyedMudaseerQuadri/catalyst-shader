# Catalyst Current State

**Milestone:** M8 — Integration, presets, scalability, optimization (M1-M5 implemented; M6/M7 deferred until measured evidence)
**Status:** IN PROGRESS. Everything after EV-005 (0.3.0 tone pipeline, M2 TAA, M3 environment, M4 water, M5 image
quality) is compile-verified only; the user tests in-game at the end of the project (decided 2026-10-11).
**Current objective:** Wait for the end-of-project in-game test of 0.4.0; until then only work that needs no runtime
evidence (documentation, tooling, static review). M6/M7/M8/M9 gates all require measured evidence.

**What exists:** `shaderpack/Catalyst/` (Iris pack, 3 dimensions, LabPBR materials, TAA, volumetric clouds, weather,
water, SSGI/AO/SSR, volumetric light, bloom), `tools/validate_shaderpack.py` (29 configurations), `tools/fetch_glslang.py`
(pinned compiler), `tools/tone_sim.py`, `tools/package_shaderpack.py`. Build: `dist/Catalyst-0.4.0.zip`, attached to
the GitHub prerelease `v0.4.0`.

**Next intended work:**
1. Human (end of project): test 0.4.0 with F2 screenshots per `CHECKPOINT.md` items 1-21 (record as EV-006); send
   `logs/latest.log`, FPS per profile, and the F3 light readout for the room (I-006).
2. Fix whatever the test finds (Iris log errors first), then tune with the evidence (watch items: room brightness
   with Bounce Light, cloud brightness, volumetric strength).
3. With frame times: M8 tuning, then decide M6 (voxel GI) per its evidence gate.
4. Human decision pending: project license (I-004).

**Last checkpoint:** See `CHECKPOINT.md`.
