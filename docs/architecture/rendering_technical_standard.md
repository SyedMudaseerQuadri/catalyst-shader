# Catalyst Rendering Technical Standard

## Purpose

This document defines technical conventions that must remain consistent across Catalyst unless an Architecture Decision Record (ADR) explicitly changes them.

## 1. Coordinate and Transform Conventions

Document and enforce:

- world-space convention;
- view/camera-space convention;
- clip-space convention;
- tangent-space convention;
- handedness;
- matrix multiplication order;
- vector/matrix storage assumptions;
- current and previous camera transforms.

Every subsystem must state which coordinate space it expects and produces.

## 2. Depth Convention

Define explicitly:

- near/far planes;
- depth range;
- reversed-Z status;
- linear-depth reconstruction;
- projection reconstruction;
- precision expectations.

Depth reconstruction must use one authoritative implementation where practical.

## 3. Color and HDR

Define:

- texture/storage color spaces;
- linear-light working space;
- display/output transform;
- HDR representation;
- exposure convention;
- luminance convention;
- tonemapping location in the pipeline.

Do not perform lighting calculations in an unintended gamma-encoded space.

## 4. Material Conventions

Define authoritative meanings for:

- base color;
- roughness;
- metallic/specular;
- normal;
- emission;
- opacity/transmission;
- material classification;
- wetness;
- snow.

Material packing must be documented before dependent passes are implemented.

## 5. Lighting Conventions

Document:

- direct-light representation;
- sky-light representation;
- emissive radiance;
- attenuation;
- shadow visibility;
- indirect-light representation;
- exposure relationship.

Use physically motivated conventions where practical, while allowing explicitly documented artistic controls.

## 6. Sampling and Randomness

Define:

- deterministic seed inputs;
- frame index usage;
- pixel/sample indexing;
- blue-noise or other sequence policy if adopted;
- scrambling policy;
- decorrelation policy;
- temporal sample behavior.

Randomness must not create avoidable temporal instability.

## 7. Precision and Numerical Policy

Document:

- minimum precision expected per subsystem;
- acceptable approximations;
- epsilon policy;
- normalization requirements;
- NaN/Inf handling;
- overflow/underflow concerns;
- half/float usage.

Never use arbitrary clamps to conceal an unknown numerical failure.

## 8. Temporal Contracts

Every temporal resource must define:

- current state;
- previous state;
- validity;
- reset conditions;
- reprojection method;
- disocclusion criteria;
- confidence;
- neighborhood/clamping policy.

## 9. Ray/Voxel Conventions

If voxel/ray systems are enabled, define:

- world-to-voxel mapping;
- voxel coordinate convention;
- origin handling;
- bounds;
- traversal convention;
- hit representation;
- normal convention;
- material payload;
- empty-space representation.

## 10. Change Policy

Any foundational convention change requires:

1. impact analysis;
2. ADR;
3. migration plan;
4. affected-contract review;
5. validation;
6. checkpoint.

Cosmetic tuning does not require an ADR unless it changes a technical contract.
