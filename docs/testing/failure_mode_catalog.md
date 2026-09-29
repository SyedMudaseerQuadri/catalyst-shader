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
