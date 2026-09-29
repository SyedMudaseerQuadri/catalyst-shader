# Catalyst Session Log

Append only meaningful state-changing work. Do not record routine chat.

- 2026-09-30 — M0: minimum hardware target set to RTX 3050 (8GB desktop), Performance preset @1080p (D-006). Updated `docs/release/compatibility.md`, `docs/performance/gpu_budget.md`; opened I-001 (no 3050 test hardware).
- 2026-09-30 — M0 closed as PASS WITH KNOWN LIMITATIONS. Capabilities recorded; Iris 1.21.11 features checked in source (EV-001).
- 2026-09-30 — M1 built: `shaderpack/Catalyst` (shadow, forward-lit gbuffers, analytic sky, fog, exposure/tonemap, debug views, 3 dimensions, 5 profiles + 3 visual presets). Added `tools/validate_shaderpack.py` and `tools/package_shaderpack.py`. Validation PASS: 2058 compilations (EV-002). Decisions D-007..D-009; issues I-002..I-004. In-game verification pending.
- 2026-09-30 — Created the project Git repository (`main`); ignored `reference_shaders/` and `dist/`. I-003 resolved.
- 2026-09-30 — Published to https://github.com/SyedMudaseerQuadri/catalyst-shader (public) with tag m1-compile-verified. No LICENSE yet (I-004).
