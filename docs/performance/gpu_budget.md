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

## Static cost model (2026-10-11) — ESTIMATE, not a measurement

Derived from the shader source (loop counts and texture reads per pixel), to make the profiles coherent before any
benchmark exists. Frame times are UNMEASURED (I-001); the M8 gate needs real numbers from
`docs/testing/performance_benchmark_protocol.md`. "taps" = texture reads per affected pixel.

| Pass (internal tier by profile: Performance=Low, Balanced=Medium, Quality=High, Ultra=Ultra, Cinematic=Extreme) | Low | Medium | High | Ultra | Extreme | Pixels affected |
|---|---|---|---|---|---|---|
| shadow map resolution / PCF taps | 1024 / 4 | 2048 / 8 | 2048 / 16 | 3072 / 16 | 4096 / 16 | lit geometry |
| deferred: SSGI rays x steps (depth taps, + 1 color/normal tap per hit) | 2x6 = 12 | 3x8 = 24 | 4x10 = 40 | 6x12 = 72 | 8x14 = 112 | opaque terrain |
| deferred1: cloud primary x light steps (procedural noise, no taps) | 10x3 | 14x4 | 20x4 | 28x5 | 40x6 | sky + far terrain |
| water SSR steps (+4 refinement) | 12 | 16 | 24 | 32 | 40 | water only |
| composite: volumetric steps (shadow taps) | 6 | 8 | 12 | 16 | 24 | all (overworld) |
| composite: underwater shaft steps (2 shadow taps each) | 8 | 10 | 14 | 20 | 20 | all, eye in water |
| composite1 TAA (taps) | 14 | 14 | 14 | 14 | 14 | all |
| composite2 bloom (taps, small mips) | 54 | 54 | 54 | 54 | 54 | all |

Expected heaviest passes on the RTX 3050 floor (Performance): clouds (ALU-bound noise), shadow map, SSGI. If the
Performance profile misses its target in measurement, the first levers are: clouds -> Vanilla, SSGI rays 2 -> 1
(with AO only), volumetric steps 6 -> 4. Do not change them before measurement (M8 rule).

## Parent/child option dependencies (settings UX)
| Option | Needs |
|---|---|
| Cloud Shadows, Cloud Amount | Clouds = Catalyst |
| Caustics, Underwater Light Shafts, Volumetric Light, colored glass shadows | Shadows on (overworld) |
| Bounce Strength, Ambient Occlusion | Bounce Light on |
| Volumetric Strength / Bloom Strength | Volumetric Light / Bloom on |
Each dependent option's in-game description states its requirement (lang/en_us.lang).
