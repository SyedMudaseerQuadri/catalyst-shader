# Catalyst Current State

**Milestone:** M1 — Minimal Correct Renderer
**Status:** IMPLEMENTED — awaiting in-game verification (I-002)
**Current objective:** Verify the M1 shaderpack in Minecraft 1.21.11 + Iris 1.10.7, then continue M2 (temporal foundation, materials).

**What exists:** `shaderpack/Catalyst/` (Iris pack, 3 dimensions), `tools/validate_shaderpack.py` (offline compile + consistency),
`tools/package_shaderpack.py` (release zip), `dist/Catalyst-0.1.0-m1.zip`.

**Next intended work:**
1. Human: install the client and run the M1 check list (`CHECKPOINT.md`); record the results as EV-003.
2. Fix whatever the in-game test finds (Iris log errors first).
3. M2: motion vectors / TAA and temporal invalidation, LabPBR material input, shadow tuning at the RTX 3050 floor.

**Last checkpoint:** See `CHECKPOINT.md`.
