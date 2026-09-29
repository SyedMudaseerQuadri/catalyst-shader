# Catalyst — Architecture Overview

See also: pass_graph.md, data_contracts.md, uniform_contracts.md, feature_dependency_graph.md for the subsystem contract docs split out of this section.

## Catalyst architecture — design it from scratch

After the research, design Catalyst independently.

Do not simply copy the NG architecture or a reference pack's directory tree.

Create:

`docs/architecture/catalyst_architecture.md`

It must define the renderer from top to bottom.

Include:

## Visual philosophy

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


## Cross-cutting environmental state

The architecture uses a shared environmental-state service defined in `environment_state.md`. Time, weather, wind, biome/season (when supported), cloud coverage, sun/moon angle, atmospheric density, surface/water state, light sources, and dimension feed multiple rendering subsystems. This is a deliberate dependency required by the canonical aesthetic direction; do not duplicate independent weather/wetness/cloud state in each effect.

## Settings and preset architecture

The canonical preset model is defined in `preset_model.md` and `settings_architecture.md`: three visual presets and five independent performance presets, plus master aesthetic intensity, visual axes, UX layers, and explicit override precedence.

## Light transport model

Design a coherent lighting model instead of separate unrelated hacks.

The architecture should have explicit concepts for:

- direct solar illumination;
- direct lunar illumination;
- block-emitted radiance;
- sky illumination;
- indirect diffuse illumination;
- specular response;
- emissive surfaces;
- occlusion;
- transmission/subsurface where appropriate;
- atmospheric attenuation;
- participating media.

Energy conservation should be used as a guiding principle, but artistic response controls are allowed.

Where approximations are used, document:

- the physical quantity being approximated;
- the approximation;
- why it is needed;
- what artifact it introduces;
- what control mitigates it.

---

## Material system

Design a unified surface-material model.

At minimum consider:

- base color;
- normal;
- roughness;
- metallic/specular response;
- emissive;
- opacity/translucency;
- material classification;
- subsurface/transmission capability;
- wetness response;
- snow response;
- optional parallax/POM support where feasible.

Prefer interoperability with widely supported Minecraft material conventions where practical, especially LabPBR if the research confirms it remains the best baseline for the target environment.

Do not create a custom format merely to be different.

---

## Shadow architecture

Design shadows as a subsystem with clear interfaces.

Requirements:

- stable cascaded shadows where cascades are used;
- sensible split strategy;
- adequate resolution allocation;
- robust bias;
- slope-aware handling;
- contact shadows where cost-effective;
- transparent/translucent support where practical;
- soft shadow filtering;
- temporal stability;
- quality scaling;
- dimension-aware behavior.

Research the strongest shadow approaches from the references and combine them only where the resulting architecture remains coherent.

---

## Temporal architecture

Design temporal infrastructure early enough that later effects can depend on it cleanly.

The temporal system should support, where required:

- jitter;
- previous/current transforms;
- reprojection;
- motion vectors;
- depth rejection;
- disocclusion;
- neighborhood statistics;
- clipping/clamping;
- reactive masks;
- confidence metrics;
- effect-specific history.

Do not make TAA a late patch that every expensive effect hacks around.

Temporal stability is a core architectural service.

---

## Atmosphere, sky, clouds, weather

Treat the environment as a coupled system.

The environment state should influence:

- sun intensity;
- sky radiance;
- fog density;
- aerial perspective;
- cloud coverage;
- volumetric density;
- precipitation;
- surface wetness;
- lighting color;
- visibility;
- cloud shadows.

Weather should feel like an atmospheric state with transitions, not independent toggles.

Clouds, fog, sky, rain, snow, sun shafts, and wet surfaces should respond to common environmental inputs where appropriate.

---

## Water architecture

Catalyst water must be treated as a dedicated rendering subsystem.

Design interfaces for:

- surface geometry/displacement;
- multi-scale wave normals;
- view-dependent response;
- Fresnel;
- reflection;
- refraction;
- absorption;
- scattering;
- depth;
- foam;
- shoreline response;
- underwater fog;
- volumetric interaction;
- caustic approximation;
- rain interaction;
- temporal stabilization.

The goal is visual plausibility and continuity from:

above water → surface → shallow water → deep water → underwater.

Avoid treating water as a translucent flat plane with a color tint.

---

## GI strategy

`docs/architecture/preset_model.md` defines two layers: user-facing presets (what the player
selects) and internal rendering tiers (Low/Medium/High/Ultra/Extreme/RT-PT — how the engine
decides which technology to use). GI is tier-scoped using the **internal** rendering tiers, not a
user-facing preset — a player never sees "Low" or "Extreme" in a menu; they see the Performance
preset, which maps internally to one of these tiers per subsystem.

Decided: Catalyst's GI approach is **tier-scoped, not a single linear ladder**. Screen-space GI
is not a discarded intermediate step on the way to voxel GI — it is the permanent GI method at
internal tiers Low/Medium/High, which cannot realistically afford voxel GI. Voxel-based GI (and
its RT/PT extensions) is reserved for internal tiers Ultra/Extreme. Do not build screen-space GI
as throwaway scaffolding, and do not attempt to unify both into one shared codepath merely for
architectural elegance if that compromises either tier's quality or cost.

Catalyst's GI approach by internal tier:

- Internal Low/Medium/High: direct lighting, plus screen-space GI for indirect/bounce light.
  Ambient occlusion (non-GI) applies at all tiers as a separate, cheaper effect.
- Internal Ultra/Extreme: voxel/light-propagation GI, with voxel ray-traced and voxel
  path-traced GI as further Extreme-tier options.

Known limitation of screen-space GI to design around, not ignore: it only has information about
what is visible on screen, so it misses light bouncing from off-screen or occluded geometry and
can produce minor light leaking/halos at object edges. This is an accepted tradeoff at the
Low/Medium/High internal tiers, not a defect to silently work around with hacks — document it
plainly in the relevant ADR and in `docs/testing/failure_mode_catalog.md` once implemented.

The exact technical approach within each tier must be selected after comparing the reference
packs and target hardware.

The architecture must allow high-end GI to exist without making lower tiers depend on it.

---

## Voxel infrastructure

If Catalyst adopts a voxel-based high-end path, design the voxel system independently and rigorously.

Investigate and choose among:

- geometry shader voxelization;
- raster-assisted voxelization;
- compute-assisted voxelization;
- 3D custom images;
- SSBO-based structures;
- multi-resolution voxel grids;
- cascaded/clipmapped volumes;
- compact occupancy formats;
- color/material storage;
- emissive storage;
- normal or directional storage.

Prefer modern, measurable, efficient approaches that fit current Iris capabilities.

Voxelization must not become an invisible frame-time sink.

Document:

- world-to-voxel mapping;
- voxel size;
- volume dimensions;
- memory footprint;
- update frequency;
- dirty-region strategy if any;
- storage format;
- clear/update strategy;
- read/write synchronization;
- traversal methods;
- fallbacks.

---

## Ray tracing / path tracing

Catalyst's high-end architecture should distinguish clearly between:

- screen-space ray marching;
- voxel ray tracing;
- voxel path tracing;
- future native renderer/hardware-accelerated possibilities.

Do not call screen-space or voxel software tracing “hardware RT.”

High-end modes may include:

- voxel reflections;
- voxel soft shadows;
- voxel GI;
- multiple-bounce indirect illumination;
- emissive lighting;
- skylight occlusion;
- secondary transport;
- path-traced water/reflections where practical;
- hybrid screen-space + voxel fallback systems.

Design interfaces so better traversal, sampling, denoising, or reconstruction techniques can be added later without rewriting the whole renderer.

---

## Denoising / reconstruction

For noisy high-end effects, design a first-class reconstruction system.

Investigate and implement as justified:

- temporal accumulation;
- spatial filtering;
- variance estimation;
- normal-aware filtering;
- depth-aware filtering;
- luminance-aware clipping;
- confidence masks;
- history weighting;
- reprojection;
- optional advanced denoising;
- lower internal render resolution;
- upscale/reconstruct.

Denoising should preserve:

- edges;
- surface normals;
- thin geometry;
- material boundaries;
- moving objects;
- lighting changes.

Do not make the image clean by turning it into a smeared blur.

---

## Camera / cinematic pipeline

Create a coherent HDR camera pipeline.

Investigate and design:

- scene exposure;
- eye adaptation;
- white balance;
- highlight rolloff;
- tonemapping;
- contrast;
- color grading;
- bloom;
- glare;
- optional lens effects;
- optional depth of field;
- optional motion blur;
- optional vignette/film response.

Effects must be optional and quality-tier aware.

Avoid cheap cinematic filters that merely reduce image clarity.

---

## Source code organization

Create a Catalyst-specific source tree after architecture is finalized.

A starting philosophy, not a mandatory final tree:

```text
shaders/
  lib/
    core/
    math/
    camera/
    material/
    lighting/
    shadow/
    atmosphere/
    cloud/
    weather/
    water/
    temporal/
    reflection/
    gi/
    voxel/
    raytrace/
    pathtrace/
    denoise/
    exposure/
    tonemap/
    debug/
```

Do not create empty speculative modules merely for appearance. Add modules when the milestone needs them.

Use clearly defined ownership:

- one concept has one authoritative implementation;
- shared code belongs in shared libraries;
- stage-specific glue belongs in the stage;
- constants/configuration should not be duplicated across unrelated files.

---

## Future extensibility

Do not architect Catalyst around the assumption that voxel path tracing is the final possible technique.

Keep interfaces flexible enough to potentially support later:

- better traversal structures;
- improved temporal reconstruction;
- more advanced sampling;
- better denoisers;
- more efficient sparse representations;
- additional volumetric techniques;
- improved atmospheric scattering;
- future Minecraft/Iris rendering capabilities;
- a possible separate native renderer project in the far future.

Do not implement a native Vulkan backend as part of the current Iris shader pack unless the project explicitly becomes a separate renderer/client project. Keep that boundary clean.

---

