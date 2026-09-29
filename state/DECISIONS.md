# Catalyst Decisions

## D-001 — Single visual authority
`docs/visual/aesthetic_direction.md` is the sole canonical visual/aesthetic specification. the retired visual-target summary is retired to the archive.

## D-002 — Preset model
Catalyst uses three visual presets and five independent performance presets. RT/PT are techniques, not global preset families.

## D-003 — Environmental-state-first architecture
The updated aesthetic direction is treated as an architectural dependency: shared environmental state is foundational to weather, atmosphere, lighting, clouds, wetness, snow, foliage, water interaction, and temporal response.

## D-004 — Context-efficient agent memory
Use a small always-relevant `CLAUDE.md` plus state/checkpoint files and task-specific documents. Do not require full documentation rereads on normal sessions.

## D-005 — Tier-scoped GI strategy
Screen-space GI is the permanent GI method at internal rendering tiers Low/Medium/High (see
`docs/architecture/preset_model.md` for the user-facing preset vs. internal tier distinction —
this is never a preset name), not a discarded step toward voxel GI. Voxel-based GI is reserved for
internal tiers Ultra/Extreme, additive to (not a replacement for) screen-space GI at lower tiers.
Rationale: without this, the internal Low/Medium/High tiers would have no indirect lighting at all, which is a real, visible quality gap for the majority of
users' hardware — and screen-space GI is exactly the kind of technique that lets performance-
conscious reference packs (BSL, Solas, Shrimple) achieve a strong look cheaply. Screen-space GI's
known limitation (screen-space-only information — misses off-screen/occluded bounce light, can
leak/halo at edges) is an accepted, documented tradeoff for these tiers, not something to hide.

## D-006 — Minimum hardware target: RTX 3050
The minimum supported GPU is the NVIDIA GeForce RTX 3050 (Ampere, desktop, 8GB VRAM). At that floor, the
**Performance** preset must be playable at 1080p with default settings. Balanced and above may need
stronger hardware. The dev RTX 4060 (8GB) stays the recommended/primary machine.
Consequences:
- Every subsystem needs a Performance-preset path that fits the RTX 3050's compute and memory
  bandwidth. Voxel GI (M6) and RT/PT (M7) can never be required at the Performance preset.
- Catalyst runs on Iris/OpenGL, so the 3050's hardware RT cores offer no guaranteed benefit. Do not
  plan for them.
- The 6GB desktop and 4GB laptop RTX 3050 variants are not covered until verified.
Status: decision recorded; runtime evidence is UNVERIFIED because no RTX 3050 is available for testing
(see ISSUES.md).

## D-007 — Forward shading in gbuffers for M1/M2
Every lit gbuffers program shades itself into colortex0 and also writes G-buffer data (colortex1-3)
for later screen-space passes and debug views.
Rationale: Iris runs some programs (hand, particles, translucents) after `deferred`, so a deferred-only
lighting path would leave them unlit or need duplicate code. Forward shading through one shared lighting
library (`lib/lighting/forward.glsl`) keeps a single implementation that lights every program the same way.
The deferred slot stays free for SSAO / screen-space GI (M5).
Cost: overdraw means shading work for hidden fragments. Measure on the RTX 3050 floor; revisit if it dominates.

## D-008 — How the two preset axes map to Iris
Performance presets = the 5 Iris profiles (`profile.PERFORMANCE` ... `profile.CINEMATIC`). Balanced equals the source defaults.
Visual preset = the `VISUAL_PRESET` option (3 values). It resolves `PRESET_*` constants in `lib/settings.glsl`.
User sliders multiply the preset value (1.00 = preset default), which implements the precedence
"user override > preset". Iris shows the profile as custom once a performance option is changed.
Internal tiers: `INTERNAL_TIER` = `PERF_PROFILE` (hidden option, set only by profiles). It never appears in the UI.

## D-009 — Internal compile-time flags use `#if defined`, never `#ifdef`
Iris turns any `#define X` that some line tests with `#ifdef X` / `#ifndef X` into a boolean menu option
(checked in the source, EV-001). Include guards, stage, dimension and program flags therefore use `#if defined X`.
Only real user options (currently `SHADOWS`) are tested with `#ifdef`. `tools/validate_shaderpack.py` enforces this.
