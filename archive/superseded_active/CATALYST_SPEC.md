# Catalyst — Project Spec

## Project identity

Project name: **Catalyst**

Target platform: Minecraft Java Edition shader pipeline, primarily through Iris.

Core ambition:

> Build a new-generation Minecraft shader pack that combines the strongest rendering ideas discovered in the reference ecosystem into a single coherent, cinematic, realistic, physically motivated, highly configurable, and highly optimized renderer, while maintaining an architecture capable of advanced voxel ray tracing and path tracing.

Catalyst should aim for:

- cinematic presentation;
- realism without sterile or over-literal physical equations;
- strong material readability;
- beautiful day/night transitions;
- physically motivated but artistically controlled lighting;
- high-quality shadows;
- indirect lighting/global illumination;
- advanced reflections and refraction;
- water with convincing waves, reflection, refraction, absorption and underwater behavior;
- atmospheric depth;
- physically motivated sky and aerial perspective;
- convincing clouds and volumetrics;
- dynamic weather;
- believable wetness/snow accumulation where supported;
- strong temporal stability;
- modern reconstruction/denoising;
- scalable quality tiers;
- advanced voxel ray tracing;
- advanced voxel path tracing;
- future-proof interfaces for techniques beyond the initial roadmap.

Do not equate “more effects” with “better.” Catalyst should instead maximize perceived image quality, consistency, and immersion per unit of GPU cost.

---

## Available reference library

The workspace contains reference archives supplied by the human. Locate and inspect them. The current set includes:

- Complementary Unbound r5.8.1
- Complementary Reimagined r5.8.1
- Kappa v5.3
- Nostalgia v5.1
- Solas Shader v3.7
- Bliss v2.1.2
- Eclipse Shader Unstable
- BSL v10.1.3
- Photon v1.3b
- Rethinking Voxels r0.1-beta9
- AstraLex V93.0
- a second AstraLex archive with a decorative filename that appears to be a duplicate; verify by checksum/content and deduplicate it if identical.

Also present in the workspace is an earlier **NG Renderer** planning document supplied by the human.

Important:

The NG document is a **previous shader project's architecture**, not the required foundation of Catalyst. Use it only when a design idea remains objectively useful after research. Catalyst must receive a fresh architecture and fresh plan.

---

## Special reference rule for kappa/kappapt and nostalgia/nostalgiavx

The human has legitimately supplied the free/reference versions:

- Kappa
- Nostalgia

The human has not supplied the paid KappaPT or NostalgiaVX source archives.

Do not search for or use leaked copies of those paid packs.

You may use lawful public documentation, official project pages, public development posts, release notes, interviews, and other public technical material to understand the **high-level differences and techniques** associated with KappaPT and NostalgiaVX.

Known public high-level facts that must be treated as reference information, not source code to reproduce:

- KappaPT is described by its author as a Kappa-family pack using world-space path tracing in place of the normal vanilla-lightmap-centered approach, including path-traced block emission, skylight occlusion, and GI.
- Kappa itself includes a screenspace/path-tracing-style emission approach that can improve prominent colored lighting and GI behavior relative to basic lightmap-only rendering.
- NostalgiaVX is publicly described as using a combined lighting approach involving a light propagation volume and path tracing to achieve high-fidelity lighting at a lower cost than pure path tracing.
- Public development material describes the move away from expensive geometry-shader-based voxelization toward 3D image/custom-image and compute-shader techniques, and describes compute-based path tracing/denoising and advanced denoising concepts.

Do not treat these statements as permission to recreate proprietary source. Use them only to inform Catalyst's own architectural investigation.

---

## Current iris documentation is authoritative for iris syntax

Before implementation of any Iris-specific feature, verify current documentation.

At minimum investigate the current official Iris documentation for:

- shader program ordering and available program types;
- fragment, vertex, compute, tessellation support;
- `shaders.properties`;
- feature flags;
- custom textures;
- custom images;
- colortex buffers;
- depth buffers;
- shadow buffers;
- shadowcolor buffers;
- buffer flipping;
- buffer resolution/scaling;
- custom uniforms and variables;
- SSBO support;
- image load/store;
- 3D images;
- separate hardware samplers where relevant;
- reverse shadow culling where relevant;
- current Iris/OpenGL compatibility requirements;
- current Minecraft/Iris version behavior relevant to the target build.

Do not use an old remembered syntax when current documentation provides a different or expanded interface.

As of the current documentation used during preparation, Iris documents compute shader support, custom images, SSBOs, configurable colortex resources, and multiple color/depth/shadow resources. Treat exact limits and availability as version-dependent and verify them at implementation time.

---

## Catalyst visual philosophy

Catalyst should target a distinctive visual identity inspired by the best qualities found in the reference ecosystem but not visually identical to any one pack.

Desired characteristics:

- cinematic depth;
- strong but controlled light transport;
- realistic material response;
- rich indirect lighting;
- natural sky colors;
- believable atmospheric perspective;
- dramatic but physically coherent sunsets/sunrises;
- convincing night lighting;
- readable shadows;
- realistic water behavior;
- volumetric depth;
- detailed clouds;
- immersive weather;
- controlled highlights;
- no excessive crushed blacks;
- no unnecessary white clipping;
- restrained bloom;
- natural saturation;
- strong color separation without neon overload;
- visual consistency across biomes and dimensions.

Use a physically motivated base and artistic controls on top.

Do not force every subsystem to be mathematically perfect if the approximation is visually superior and stable.

---

## Requirements for the final catalyst renderer

At maturity, Catalyst should aim to provide coherent support for:

### Core
- stable rendering;
- robust materials;
- direct lighting;
- excellent shadows;
- day/night cycle;
- dimension handling;
- configurable quality.

### Cinematic environment
- atmospheric sky;
- physically motivated haze;
- volumetric fog;
- beautiful clouds;
- weather;
- light shafts;
- strong horizon depth.

### Materials
- PBR;
- emissive;
- metallic/specular;
- roughness;
- normal maps;
- optional parallax;
- wetness/snow response;
- subsurface/transmission where appropriate.

### Water
- waves;
- realistic shading;
- reflection;
- refraction;
- absorption;
- underwater scattering/fog;
- foam;
- optional caustics.

### Advanced transport
- screen-space GI;
- voxel GI;
- voxel reflections;
- voxel ray-traced shadows;
- voxel path-traced lighting;
- robust denoising and temporal reconstruction.

### Camera
- HDR;
- auto exposure;
- tonemapping;
- color grading;
- optional bloom;
- optional cinematic camera effects.

### Engineering
- debug suite;
- automated validation;
- repeatable QA;
- documented performance tiers;
- maintainable code.

---

## Visual quality bar

Catalyst must be evaluated scene-by-scene, not by feature count.

For every visual subsystem ask:

1. Does it look good in isolation?
2. Does it remain correct when combined with other systems?
3. Does it respond correctly to time of day?
4. Does it behave correctly in weather?
5. Does it remain stable while the camera moves?
6. Does it preserve material identity?
7. Does it avoid obvious cheating artifacts where the intended mode promises realism?
8. Is the performance cost proportional to the benefit?

The ultimate goal is a renderer that can produce images that feel:

- cinematic;
- deep;
- atmospheric;
- natural;
- coherent;
- high dynamic range;
- materially rich;
- visually intentional.

Do not reduce this to “make Minecraft look realistic.”

---

## High-end mode philosophy

The high-end path-traced mode should not simply turn every effect into a path-traced version.

Use the best transport method for each problem.

Examples:

- rasterization for primary geometry;
- shadow maps for inexpensive direct visibility;
- screen-space techniques where they are sufficient;
- voxel data for world-space traversal;
- path tracing for difficult indirect transport;
- temporal reconstruction to recover quality;
- compute for parallel random-access tasks.

A hybrid renderer can be superior to an indiscriminate fully path-traced renderer when judged on image quality, stability, and real-time performance.

---

