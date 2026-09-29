# Catalyst — Reference Research

## Reference-shader deep analysis

You must perform a serious comparative source-code study before finalizing Catalyst architecture.

Do not merely list filenames or search for the word “water.” Trace the actual call graph and data flow.

For every reference pack, investigate at least the following categories.

## 6.1 Repository/file architecture

Determine:

- naming conventions;
- program layout;
- directory structure;
- library structure;
- dimension separation;
- configuration organization;
- compile-time configuration;
- shared include strategy;
- generated or special resources;
- use of shader properties;
- language/localization strategy.

## 6.2 Pass graph

Reconstruct:

- shadow pass sequence;
- gbuffers sequence;
- deferred sequence;
- composite sequence;
- final/post-processing sequence;
- compute passes;
- any special program ordering;
- temporal dependencies;
- data dependencies between passes.

Create diagrams where useful.

## 6.3 G-buffer/data architecture

Determine exactly what each reference stores and where.

For important buffers record:

- channel allocation;
- precision;
- encoding;
- packing;
- producer;
- consumer;
- lifetime;
- resolution;
- whether it is temporal/history data;
- whether it is filtered;
- expected precision/range;
- bandwidth implications.

Do not assume the same G-buffer meaning across packs merely because they use the same colortex number.

## 6.4 Lighting

Investigate:

- directional sun/moon light;
- block light;
- skylight;
- ambient term;
- bounce/indirect lighting;
- emissive contribution;
- colored lighting;
- attenuation;
- light temperature;
- light mixing;
- energy conservation decisions;
- artistic corrections;
- day/night response;
- underground/cave behavior;
- dimension-specific behavior.

Identify whether a technique is physically motivated, empirically tuned, stylized, or mixed.

## 6.5 Shadows

Investigate deeply:

- shadow map resolution;
- cascade count;
- split strategy;
- orthographic stabilization;
- shadow distortion;
- bias;
- normal offset;
- slope bias;
- filtering;
- PCF tap pattern;
- Poisson/Vogel/etc.;
- contact shadows;
- translucent shadows;
- colored shadows;
- subsurface effects;
- shadow culling;
- reverse culling;
- shadow map reuse;
- temporal filtering.

Explain why each approach was likely chosen and where it fails.

## 6.6 Materials/PBR

Investigate:

- LabPBR or other material conventions;
- albedo handling;
- normals;
- roughness;
- metallic/specular;
- emissive;
- subsurface/transmission;
- parallax/POM;
- material IDs;
- special block mappings;
- entity materials;
- foliage materials;
- translucency;
- wetness;
- snow response;
- emissive block special cases.

## 6.7 Water

Investigate the complete water system, not only its surface color:

- geometry displacement;
- wave function(s);
- wave spectrum or analytic model;
- normal generation;
- multi-scale normals;
- wind coupling;
- directional behavior;
- reflection;
- Fresnel;
- refraction;
- depth-based absorption;
- scattering;
- underwater fog;
- foam;
- shoreline treatment;
- caustics;
- SSR;
- planar methods;
- ray-traced/voxel methods;
- temporal stabilization;
- interaction with weather;
- interaction with shadows and GI.

Determine which effects are actually geometric and which are shading approximations.

## 6.8 Sky and atmosphere

Investigate:

- sky gradient;
- sun disc;
- moon disc;
- stars;
- atmospheric scattering;
- Rayleigh-like behavior;
- Mie-like behavior;
- aerial perspective;
- horizon response;
- sunrise/sunset;
- transmittance approximations;
- planetary/dimension assumptions;
- night sky treatment;
- end/nether sky systems.

## 6.9 Fog and volumetrics

Investigate:

- distance fog;
- height fog;
- cave fog;
- volumetric fog;
- light shafts;
- anisotropy;
- shadowed fog;
- colored light in fog;
- underwater fog;
- weather-dependent fog;
- density fields;
- temporal sampling;
- noise;
- reprojection;
- performance reductions.

## 6.10 Clouds

Investigate:

- 2D/planar clouds;
- volumetric clouds;
- noise types;
- FBM structure;
- coverage/shape functions;
- cloud lighting;
- self-shadowing;
- sun/moon response;
- cloud shadows on terrain;
- weather coupling;
- animation;
- temporal accumulation;
- reconstruction;
- horizon blending;
- quality tiers.

## 6.11 Weather and climate

Investigate:

- rain;
- snow;
- storm lighting;
- wet surfaces;
- puddles;
- atmospheric density changes;
- cloud coverage changes;
- wetness transitions;
- weather particle interaction;
- water/sky/fog coupling;
- thunder/lightning effects;
- biome or dimension differences.

Catalyst should ultimately treat weather as a coherent environmental state, not unrelated effects.

## 6.12 Temporal systems

Investigate:

- projection jitter;
- history buffers;
- reprojection;
- motion vectors;
- depth rejection;
- neighborhood clamping;
- variance clipping;
- disocclusion detection;
- anti-ghosting;
- reactive masks;
- temporal SSR;
- temporal GI;
- temporal volumetrics;
- temporal cloud accumulation;
- adaptive accumulation.

## 6.13 Anti-aliasing and reconstruction

Compare:

- FXAA;
- TAA;
- temporal upscaling;
- internal resolution scaling;
- sharpening;
- sample count;
- camera motion handling;
- fine-detail preservation;
- foliage stability.

## 6.14 Reflections and refractions

Compare:

- SSR;
- ray marching;
- hierarchical/depth-aware search;
- temporal reuse;
- roughness-aware reflection;
- probe/environment approximations;
- voxel/world-space reflection concepts;
- water-specific reflection.

## 6.15 GI and voxel systems

For every pack with GI, voxel, or related systems, reconstruct:

- what world representation exists;
- how voxelization happens;
- whether geometry shaders are used;
- whether compute is used;
- whether 3D images are used;
- whether SSBOs are used;
- voxel resolution;
- world-to-voxel mapping;
- clipmaps or cascades;
- occupancy representation;
- color/albedo representation;
- normal representation;
- emissive representation;
- light propagation;
- ray traversal;
- cone tracing;
- path tracing;
- secondary rays;
- skylight;
- ambient occlusion;
- denoising;
- temporal accumulation;
- ray guiding;
- performance characteristics.

## 6.16 Path tracing / ray tracing

When a source pack includes an advanced ray/path system, determine at high level:

- ray origin generation;
- ray direction generation;
- sampling distribution;
- BRDF sampling strategy;
- next-event or direct-light sampling if applicable;
- bounce count;
- termination;
- Russian roulette if applicable;
- emission sampling;
- voxel traversal;
- surface representation;
- handling of non-voxelizable geometry;
- screen-space fallback;
- shadow rays;
- reflection rays;
- GI rays;
- denoising;
- temporal accumulation;
- adaptive sampling;
- ray guiding;
- low-resolution strategies;
- reconstruction.

Do not copy implementation code. Extract concepts and engineering lessons.

## 6.17 Post processing / camera

Investigate:

- auto exposure;
- local exposure;
- bloom;
- glare;
- lens flare;
- chromatic aberration, if any;
- depth of field;
- motion blur;
- vignette;
- sharpening;
- film grain;
- tonemapping;
- color grading;
- white balance;
- contrast curve;
- saturation management;
- highlight rolloff;
- black floor;
- HDR range.

## 6.18 Visual identity

For each reference pack answer:

- What makes it visually recognizable?
- What does it do exceptionally well?
- Where does it become unrealistic or stylized?
- Where does it become oversaturated?
- What gives it depth?
- What gives it cinematic feel?
- What makes its nights believable or unbelievable?
- What makes its water convincing?
- What makes its clouds convincing?
- Where does detail disappear?
- What artifacts are typical?

Use this as visual design research, not code extraction.

## 6.19 Optimization

Investigate:

- pass count;
- full-resolution vs reduced-resolution effects;
- compute usage;
- image load/store usage;
- texture bandwidth;
- noise texture usage;
- branch divergence;
- loop bounds;
- dynamic loops;
- register pressure;
- repeated math;
- cache behavior where inferable;
- temporal reuse;
- spatial reuse;
- resolution scaling;
- feature gating;
- quality presets.

Do not guess a shader's performance from code aesthetics alone. Where possible, benchmark or derive cost from measured behavior.

---

## Research deliverables

Create a complete research dossier under:

`docs/research/`

Create one source-specific document per reference pack actually studied in depth (not
necessarily all 19 up front — follow the research triage/routing below to decide which packs
warrant a dedicated document for the current task).

For each source-specific document, include:

1. source/version;
2. license/credits notes;
3. architecture summary;
4. strongest subsystems;
5. weakest subsystems;
6. notable algorithms/techniques;
7. performance strategy;
8. visual characteristics;
9. important artifacts/failure modes;
10. what Catalyst should learn;
11. what Catalyst should explicitly avoid.

For factual claims based on public web research, cite the source in the research document.

---

## Cross-reference decision matrix

Create:

`docs/research/reference_decision_matrix.md`

For each major subsystem, compare the reference approaches and choose one of:

- adopt the concept;
- adapt the concept;
- combine concepts;
- defer;
- reject.

Subsystems must include at least:

- renderer/pass architecture;
- material encoding;
- shadows;
- direct lighting;
- block lighting;
- GI;
- voxelization;
- reflection;
- water;
- sky;
- atmosphere;
- fog;
- clouds;
- weather;
- temporal reconstruction;
- denoising;
- exposure;
- tonemapping;
- color grading;
- performance scaling;
- debug architecture.

For every decision state:

- evidence;
- expected quality;
- expected cost;
- compatibility implications;
- implementation complexity;
- maintenance complexity;
- fallback strategy.

Do not choose based purely on reputation or visual screenshots.

---

## Advanced research policy

During implementation you may discover better techniques not present in the original reference list.

You may research:

- rendering papers;
- open technical documentation;
- Khronos/OpenGL material;
- Iris documentation;
- academic papers;
- open-source rendering techniques;
- public technical articles;
- publicly documented Minecraft shader techniques.

Any external technique adopted into Catalyst must be recorded in:

`docs/research/external_techniques.md`

Record:

- technique;
- source;
- reason for adoption;
- adaptation to Minecraft/Iris;
- known limitations.

Do not introduce a sophisticated method just because it sounds advanced. Prove that it is relevant.

---



## Research routing

Use the actual repository as the research source map:

- Comparative decisions → `docs/research/reference_decision_matrix.md`
- Provenance → `docs/research/provenance.md`
- Reference source material → `reference_shaders/`
- Current architecture/implementation truth → `docs/architecture/` and the repository itself

Do not expect legacy per-pack study-note files to exist. Create a focused study record only when a milestone genuinely needs durable findings.
