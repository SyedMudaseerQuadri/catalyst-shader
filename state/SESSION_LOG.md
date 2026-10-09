# Catalyst Session Log

Append only meaningful state-changing work. Do not record routine chat.

- 2026-09-30 — M0: minimum hardware target set to RTX 3050 (8GB desktop), Performance preset @1080p (D-006). Updated `docs/release/compatibility.md`, `docs/performance/gpu_budget.md`; opened I-001 (no 3050 test hardware).
- 2026-09-30 — M0 closed as PASS WITH KNOWN LIMITATIONS. Capabilities recorded; Iris 1.21.11 features checked in source (EV-001).
- 2026-09-30 — M1 built: `shaderpack/Catalyst` (shadow, forward-lit gbuffers, analytic sky, fog, exposure/tonemap, debug views, 3 dimensions, 5 profiles + 3 visual presets). Added `tools/validate_shaderpack.py` and `tools/package_shaderpack.py`. Validation PASS: 2058 compilations (EV-002). Decisions D-007..D-009; issues I-002..I-004. In-game verification pending.
- 2026-09-30 — Created the project Git repository (`main`); ignored `reference_shaders/` and `dist/`. I-003 resolved.
- 2026-09-30 — Published to https://github.com/SyedMudaseerQuadri/catalyst-shader (public) with tag m1-compile-verified. No LICENSE yet (I-004).
- 2026-10-09 — Resume: repo clean and in sync; I-002 still open (no client). Added pinned `tools/fetch_glslang.py` (SHA-256 verified).
- 2026-10-09 — M2 materials: LabPBR 1.3 decode, tangent frame from Iris `at_tangent` (convention checked in source), GGX + correlated Smith + Schlick specular, split-sum sky reflection, `MATERIAL_MAPS` / `SPECULAR_INTENSITY` options, debug view 7. Validation PASS 2254 compilations; BRDF energy check PASS (EV-003). D-010.
- 2026-10-09 — First in-game evidence from the user (EV-004): pack loads; Albedo/Depth debug views PASS; interior washed out and grey (I-005). Root cause reproduced with new `tools/tone_sim.py`; fixed sky ambient hue/level, multi-bounce occlusion, partial eye adaptation (`EXPOSURE_ADAPTATION`). D-011. Build 0.2.1, compile PASS. Re-test pending.
- 2026-10-10 — EV-005: second in-game test (0.2.1). Debug views + shadows PASS; outdoor too dark, room too bright/flat, night clouds black; EV-004 diagnosis corrected. Rebuilt tools/tone_sim.py (calibrated against screenshots), implemented D-012 tone pipeline v2, vanilla-like light falloff, sun-scaled sky, cloud in-scatter, tbn init, Sun Shadow debug fix. Build 0.3.0; compile PASS. Published GitHub Release v0.3.0.
