# Catalyst — Engineering Standards

## Coding standards

- Prefer descriptive names.
- Keep functions focused.
- Avoid hidden global coupling.
- Document non-obvious coordinate systems.
- Document color spaces.
- Document unit conventions.
- Document depth conventions.
- Document normal encoding.
- Document temporal conventions.
- Document buffer packing.
- Avoid unexplained magic numbers in core rendering algorithms.
- Centralize tunable parameters.
- Use compile-time defines for architecture-level variants where appropriate.
- Keep shader stages small enough to reason about.
- Remove dead code after validation.
- Do not leave debug experiments active in release paths.
- Do not duplicate a large block of math just to save a small include.
- Conversely, do not create absurdly fragmented one-line include files that make the call graph impossible to follow.

---

## Coordinate systems and precision

Explicitly document:

- world space;
- view space;
- camera-relative space;
- shadow space;
- clip/NDC space;
- screen/UV space;
- voxel space.

Define and enforce conventions for:

- depth range;
- reverse-Z if ever used;
- handedness;
- normal orientation;
- sun direction sign;
- time units;
- exposure units/scales.

Be cautious with far-world precision and camera-relative coordinates.

---

## Color management

Design a coherent color pipeline.

Explicitly decide:

- texture input color space;
- lighting working space;
- HDR accumulation space;
- exposure location;
- bloom input space;
- tonemap input/output;
- display assumptions;
- color grading location.

Do not perform arbitrary RGB operations in inconsistent color spaces.

Where exact physical colorimetry is approximated, document the approximation.

---

## Numerical robustness

Pay special attention to:

- near-zero vectors;
- degenerate normals;
- grazing angles;
- extreme roughness;
- near/far depth precision;
- huge world coordinates;
- NaN/Inf propagation;
- shadow bias edge cases;
- ray traversal exiting the voxel volume;
- zero-length history confidence;
- exposure under/overflow.

Use defensive normalization and bounds checks where justified.

Never hide NaNs by clamping every output blindly; find the cause.

---

