# Catalyst Known Good State

## Current milestone
M2 in progress — M1 renderer + LabPBR materials (implemented, awaiting in-game verification)

## Verified
- Package initialized.
- Iris 1.21.11 feature set used by M1 checked in source (state/evidence/iris_1.10.7_capabilities.md).
- All program stages compile under Khronos glslang across 23 configurations (state/evidence/materials_2026-10-09.md).
- Specular BRDF conserves energy (same record).

## Unverified
- Runtime loading
- Iris source patching and driver compilation
- GPU rendering
- Visual output
- Performance (including the RTX 3050 minimum target)

## Known failures
None recorded yet.

## Next task
In-game check list in `state/CHECKPOINT.md`.
