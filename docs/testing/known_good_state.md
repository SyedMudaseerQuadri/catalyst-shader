# Catalyst Known Good State

## Current milestone
M1 — Minimal Correct Renderer (implemented, awaiting in-game verification)

## Verified
- Package initialized.
- Iris 1.21.11 feature set used by M1 checked in source (state/evidence/iris_1.10.7_capabilities.md).
- All program stages compile under Khronos glslang across 21 configurations (state/evidence/validation_2026-09-30.md).

## Unverified
- Runtime loading
- Iris source patching and driver compilation
- GPU rendering
- Visual output
- Performance (including the RTX 3050 minimum target)

## Known failures
None recorded yet.

## Next task
In-game M1 check list in `state/CHECKPOINT.md`.
