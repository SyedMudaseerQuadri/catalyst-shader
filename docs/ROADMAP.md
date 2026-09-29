# Catalyst — Reconciled Development Roadmap

This roadmap supersedes older ordering proposals. It is derived from the current product requirements and canonical aesthetic direction. The key architectural change is that environmental state, temporal foundations, settings/override semantics, and gameplay-readability safeguards are built early enough to support the coupled visual systems described by the aesthetic direction.

## M0 — Reconciliation, Environment & Contracts
- Pin and verify target compatibility.
- Establish Claude-native state/checkpoint system.
- Establish targeted research/provenance index for the current architecture; defer exhaustive reference analysis until a milestone needs it.
- Freeze buffer/uniform/pass/resource contracts only after capability verification.
- Define the environmental-state model, preset model, settings precedence, temporal invalidation rules, and fallback policy.
- Establish known-good checkpoint and first test scenes.
**Gate:** project truth, architecture baseline, compatibility target, preset model, and state/recovery system are internally consistent.

## M1 — Minimal Correct Renderer
- Valid Iris shader structure for the pinned target.
- Stable camera/depth/material path and debug output.
- Basic direct lighting and exposure foundation sufficient to validate the pipeline.
- Minimal configuration layer wired to the official preset model.
**Gate:** world loads/render path is valid and debug views demonstrate correct data flow.

## M2 — Lighting, Materials, Shadows & Temporal Foundation
- Unified material semantics.
- Sun/moon/block lighting and readable night lighting.
- Stable shadow architecture, bias, filtering, dimension handling.
- Motion vectors, jitter, reprojection, history validation, and centralized invalidation.
- Early color/exposure pipeline.
**Gate:** core scenes are stable under camera motion and time/dimension changes.

## M3 — Coupled Environment System
Build shared environmental state and connect: 
- sky and solar state;
- atmosphere/fog/haze;
- clouds and cloud shadows;
- weather progression;
- rain and lightning;
- wetness and drying;
- snow/ice and melt;
- foliage/environmental response;
- particles with readability safeguards.
Transitions should be progressive and temporally coherent rather than independent effects.
**Gate:** clear/noon, sunset, rain, storm, snow, and transition scenes show coherent state-driven behavior.

## M4 — Water & Underwater
- Surface response and waves.
- Depth-aware color/absorption/scattering.
- Fresnel/reflection/refraction.
- Shoreline/foam interaction where justified.
- Underwater continuity and temporal stability.
- Rain and environment interaction where supported.
**Gate:** above-water → surface → shallow → deep → underwater continuity passes visual and temporal tests.

## M5 — Image Quality & Cinematic Presentation
- Exposure/eye adaptation.
- Tonemapping and controlled color grading.
- Screen-space GI for internal rendering tiers Low/Medium/High (permanent method for these tiers,
  not a stepping stone — see `docs/architecture/catalyst_architecture.md`'s GI strategy).
- Reflections beyond the water system where justified.
- Volumetric depth/light shafts where they serve the aesthetic target.
- Bloom and camera effects with readability safeguards.
- Visual preset profiles and explicit overrides.
**Gate:** the three visual presets are distinct but coherent, do not violate readability
safeguards, and internal tiers Low/Medium/High have working indirect lighting via screen-space GI.

## M6 — Scalable Advanced GI Infrastructure (internal Ultra/Extreme tiers)
Voxel-based GI at internal tiers Ultra/Extreme, additive to (not a replacement for) the screen-space GI
already shipped for lower tiers at M5. Proceed only after measured evidence supports it:
- voxel representation/light transport;
- optional voxel reflections/shadows/GI;
- scalable resource/update strategies.
**Gate:** advanced GI provides measurable visual benefit within defined performance budgets and does not destabilize lower tiers.

## M7 — Advanced Ray/Path Transport Research
Treat ray marching, voxel ray tracing, and path tracing as techniques to evaluate, not promises.
- sampling;
- traversal;
- accumulation;
- denoising;
- adaptive quality;
- hybrid approaches.
**Gate:** each adopted technique has evidence, a fallback, and a measurable cost/benefit case.

## M8 — Integration, Scaling & Optimization
- Make Performance/Balanced/Quality/Ultra/Cinematic performance profiles coherent.
- Measure GPU/VRAM cost.
- Tune subsystem scaling and fallbacks.
- Verify settings UX and parent/child dependencies.
- Remove avoidable passes, reads, loops, and synchronizations only after measurement.
**Gate:** quality/performance matrix is internally consistent and benchmark evidence exists for supported environments.

## M9 — Release QA
- Compatibility verification.
- Visual regression matrix.
- Performance benchmarks.
- Debug-off release defaults.
- Packaging, credits, licenses, documentation, known limitations.
- Reproducible bug-report workflow.
**Gate:** release checklist fully evidenced.

## Milestone completion rule
A milestone is complete only when implementation, validation, evidence, documentation, state update, and a recoverable Git checkpoint (where available) agree.
