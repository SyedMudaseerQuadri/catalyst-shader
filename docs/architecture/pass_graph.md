# Catalyst — Pass Graph

This document is authoritative only after the architecture gate freezes a pass graph.
Define the exact intended pass graph after considering actual Iris capabilities — do not
include a stage merely because it sounds advanced or technologically fashionable; each stage
must have a clear purpose and data contract.

Candidate stages, to be confirmed/pruned by evidence:
setup/begin; shadow rendering; geometry/G-buffer; depth preparation; material preparation;
direct lighting; screen-space effects; atmospheric/volumetric stages; water/translucency;
voxelization; voxel/light propagation; ray tracing; path tracing; temporal accumulation;
denoising; reconstruction/upscaling; exposure; tonemapping; color grading; final output.

Record for each confirmed pass:
- purpose
- inputs / outputs
- resolution
- synchronization assumptions
- temporal state
- fallback behavior
- debug view
- estimated/observed cost

## Implemented pass graph — M1 (compile-verified EV-002; runtime UNVERIFIED)

Shading model: **forward shading in gbuffers** (decision D-007). Fullscreen passes add sky fill, fog and the display transform.

| # | Pass (Iris program) | Purpose | Inputs | Outputs | Res | Temporal | Fallback | Debug | Cost |
|---|---|---|---|---|---|---|---|---|---|
| 1 | shadow (world0) | sun/moon depth map | geometry, mc_Entity (water skipped) | shadowtex0 | shadowMapResolution | none | `SHADOWS` off disables the program; receivers return lit | 6 | UNMEASURED |
| 2 | gbuffers_skybasic / skytextured | analytic sky, stars, sun/moon disks | EnvState | colortex0 | full | none | deferred fills uncovered pixels | — | UNMEASURED |
| 3 | gbuffers_clouds | vanilla clouds lit by EnvState | cloud geometry | colortex0 (blend) | full | none | — | — | UNMEASURED |
| 4 | gbuffers_terrain / block / entities / hand / textured_lit | forward-lit opaque and cutout geometry (diffuse + GGX specular + sky reflection) + G-buffer data | textures, LabPBR normals/specular, lightmap, AO, shadowtex0, EnvState | colortex0-3 | full | none | — | 1-4, 6 | UNMEASURED |
| 5 | deferred | fill sky where no sky geometry drew (alpha 0) | colortex0, depthtex0 | colortex0 | full | none | — | — | UNMEASURED |
| 6 | gbuffers_water / hand_water | forward-lit translucents (LabPBR for glass/ice/slime/honey); water Fresnel sky reflection + sun glint | textures, LabPBR maps, shadowtex0, EnvState | colortex0 (blend) | full | none | — | — | UNMEASURED |
| 7 | gbuffers_weather / textured / basic | rain/snow, unlit glows, outlines | textures, EnvState | colortex0 (blend) | full | none | — | — | UNMEASURED |
| 8 | composite | aerial perspective, border fog, medium fog (water/lava/powder snow), blindness/darkness | colortex0, depthtex0, EnvState | colortex0 | full | none | — | — | UNMEASURED |
| 9 | final | model-based exposure, contrast/saturation, extended-Reinhard tonemap, sRGB encode, dither, debug views | colortex0-3, depthtex0 | screen | full | none | — | 0-6 | UNMEASURED |

The Nether (world-1) and End (world1) use the same graph without pass 1.
