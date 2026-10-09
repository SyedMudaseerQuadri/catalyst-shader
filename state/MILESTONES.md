# Catalyst Milestones

| Milestone | Purpose | Status |
|---|---|---|
| M0 | Reconciliation, environment, contracts, architecture baseline | PASS WITH KNOWN LIMITATIONS: runtime capability unavailable (I-002) |
| M1 | Minimal renderer and core render contracts | IMPLEMENTED; loads in-game, debug views PASS (EV-004). Gate pending: normal-view re-test after I-005 fix |
| M2 | Lighting, materials, shadows, temporal foundations | IN PROGRESS: shadows, sun/moon/block/sky lighting, material classes and LabPBR materials with GGX specular done (EV-003). Remaining: temporal (motion vectors, TAA, history invalidation) |
| M3 | Coupled environment: sky, atmosphere, clouds, weather, wetness, snow | FOUNDATION: shared EnvState service and analytic sky/fog exist; wetness, snow and custom clouds not started |
| M4 | Water and underwater system | FOUNDATION: Fresnel sky reflection, sun glint, underwater absorption fog; no waves/refraction |
| M5 | Image quality, exposure, screen-space GI (internal Low/Medium/High tiers), reflections/post | FOUNDATION: model-based exposure, tonemap, grading; no GI, bloom or histogram exposure |
| M6 | Voxel GI infrastructure (internal Ultra/Extreme tiers, additive to M5) | DEFERRED UNTIL EVIDENCE |
| M7 | Advanced ray/path transport experiments | DEFERRED UNTIL EVIDENCE |
| M8 | Integration, presets, scalability, optimization | FOUNDATION: 5 performance profiles + 3 visual presets wired; nothing measured |
| M9 | Full QA, compatibility validation, release packaging | FOUNDATION: `tools/validate_shaderpack.py`, `tools/package_shaderpack.py`, `tools/fetch_glslang.py` (pinned compiler) |
