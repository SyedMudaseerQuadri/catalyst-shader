# Catalyst Milestones

| Milestone | Purpose | Status |
|---|---|---|
| M0 | Reconciliation, environment, contracts, architecture baseline | PASS WITH KNOWN LIMITATIONS: runtime capability unavailable (I-002) |
| M1 | Minimal renderer and core render contracts | IMPLEMENTED; loads in-game, debug views PASS (EV-004). Gate pending: normal-view re-test after I-005 fix |
| M2 | Lighting, materials, shadows, temporal foundations | IN PROGRESS: shadows, sun/moon/block/sky lighting, material classes and LabPBR materials with GGX specular done (EV-003). Temporal: jittered TAA + history invalidation implemented (D-013), compile PASS, in-game UNVERIFIED. Per-object motion vectors: not possible on Iris 1.10.7 (no velocity attribute); entity-trail rejection instead. Remaining: in-game TAA check |
| M3 | Coupled environment: sky, atmosphere, clouds, weather, wetness, snow | IMPLEMENTED (D-014), compile PASS, in-game UNVERIFIED: volumetric cumulus + cirrus + cloud shadows, weather-coupled coverage, wetness/puddles, snow cover, wind + foliage sway, lightning flash, valley mist. DEFER: snow trails, seasons |
| M4 | Water and underwater system | IMPLEMENTED (D-015), compile PASS, in-game UNVERIFIED: waves + rain ripples, refraction, depth absorption/scattering, SSR + sky/cloud reflection, foam, Snell window, underwater caustics/absorbed light, colored glass shadows, underwater shafts, view droplets |
| M5 | Image quality, exposure, screen-space GI (internal Low/Medium/High tiers), reflections/post | IMPLEMENTED (D-016), compile PASS, in-game UNVERIFIED: SSGI + AO, glossy SSR, volumetric sunlight, bloom, preset-distinct grading. DEFER: DOF, motion blur |
| M6 | Voxel GI infrastructure (internal Ultra/Extreme tiers, additive to M5) | DEFERRED UNTIL EVIDENCE (gate needs measured frame times; Ultra/Extreme run SSGI with more rays meanwhile) |
| M7 | Advanced ray/path transport experiments | DEFERRED UNTIL EVIDENCE |
| M8 | Integration, presets, scalability, optimization | PARTIAL: profiles scale every new pass by internal tier; static cost model + option dependencies documented (gpu_budget.md). Gate needs benchmarks (UNMEASURED) |
| M9 | Full QA, compatibility validation, release packaging | FOUNDATION: `tools/validate_shaderpack.py`, `tools/package_shaderpack.py`, `tools/fetch_glslang.py` (pinned compiler) |
