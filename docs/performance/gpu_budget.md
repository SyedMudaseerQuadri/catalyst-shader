# Catalyst GPU Budget Specification

Budgets are measured, not invented. Record hardware, driver, Minecraft/Iris target, resolution, render distance, scene, camera, weather, preset, warm-up, measurement interval, average/percentile frame time, and VRAM/GPU data where measurable.

## Canonical performance presets

| Preset | Budget philosophy |
|---|---|
| Performance | minimum validated practical cost; must be playable at 1080p on the minimum target (RTX 3050 8GB — see `docs/release/compatibility.md`) |
| Balanced | recommended general use |
| Quality | higher image quality |
| Ultra | high-end quality |
| Cinematic | maximum practical validated quality |

This table budgets the 5 user-facing performance presets (Layer 1 — see
`docs/architecture/preset_model.md`). Internal rendering tiers (Layer 2: Low/Medium/High/Ultra/
Extreme/RT-PT) are a separate, non-user-facing concept each preset maps onto per subsystem — do
not maintain a second, competing global tier table here or restate Layer 2's definition; budget
against the 5 presets above and reference `preset_model.md` for how they relate to internal tiers.

## Per-subsystem accounting
Track shadow, materials/G-buffer, lighting, GI, reflections, water, atmosphere, clouds, volumetrics, voxel updates, ray traversal, path tracing, denoising, reconstruction, post-processing, and memory/bandwidth where measurable.
