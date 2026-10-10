# Catalyst — Failure Recovery Protocol & Failure Mode Catalog

## Failure recovery protocol
When an error occurs:
1. **Classify** — syntax, include path, unsupported Iris feature, invalid shader-stage usage,
   buffer mismatch, uniform mismatch, synchronization issue, precision problem, temporal
   artifact, visual bug, performance regression, resource/VRAM issue, dimension-specific bug.
2. **Isolate** — reduce to the smallest reproducible stage or effect.
3. **Inspect contracts** — check producer/consumer assumptions first.
4. **Reproduce** — confirm the failure is deterministic or identify its trigger conditions.
5. **Fix the root cause** — avoid random patches.
6. **Regression test** — re-run both the failed case and nearby systems.
7. **Document** — record the cause, fix, and lesson below.

## Failure mode catalog
Record every recurring failure with: symptom, reproduction scene/trigger, affected subsystem,
likely causes, root cause, fix/workaround, permanent-fix status, regression coverage.

Known categories to track against:
compile failure · runtime load failure · NaN/Inf · shadow acne · peter-panning · cascade seams
· shimmering · TAA/temporal ghosting · disocclusion trails · unstable/reflection-popping SSR ·
water edge artifacts · voxel leaks/stair-stepping · light bleeding · path-tracing noise/fireflies
· denoiser blur · cloud swimming · volumetric flicker · exposure pumping · tonemap clipping ·
banding · color shifts · underwater discontinuity · emissive over-brightness · translucent
shadow errors · performance regression.

## Known limitation: screen-space GI/AO/reflections (M5, D-016)
- **Symptom:** bounce light and reflections change when the source leaves the screen; slight light leaking or dark
  halos at object edges; reflections end at screen borders.
- **Trigger:** turning the camera away from a bright surface (e.g. a lava pool or a sunlit floor) that lights a wall.
- **Subsystem:** `program/deferred_gi.glsl`, `lib/lighting/ssr.glsl`.
- **Root cause:** screen space only knows visible geometry (catalyst_architecture.md, GI strategy).
- **Status:** accepted limitation for the internal Low/Medium/High tiers; edge fades soften it. Voxel GI (M6) would
  remove it for Ultra/Extreme once measured evidence exists.
- **Regression coverage:** CHECKPOINT test item 19 (Bounce Light on/off, room and lava scenes).
