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
| 1 | shadow (world0) | sun/moon depth map; water + glass as flagged translucent casters, foliage wind sway | geometry, mc_Entity | shadowtex0/1, shadowcolor0 | shadowMapResolution | none | `SHADOWS` off disables the program; receivers return lit | 6 | UNMEASURED |
| 2 | gbuffers_skybasic / skytextured | analytic sky, stars, sun/moon disks | EnvState | colortex0 | full | none | deferred fills uncovered pixels | — | UNMEASURED |
| 3 | gbuffers_clouds | vanilla clouds lit by EnvState | cloud geometry | colortex0 (blend) | full | none | — | — | UNMEASURED |
| 4 | gbuffers_terrain / block / entities / hand / textured_lit | (all geometry except sky and lines: sub-pixel Halton jitter when `TAA` is on) forward-lit opaque and cutout geometry (diffuse + GGX specular + sky reflection) + G-buffer data | textures, LabPBR normals/specular, lightmap, AO, shadowtex0, EnvState | colortex0-3 | full | none | — | 1-4, 6 | UNMEASURED |
| 5a | deferred | screen-space AO + GI (cosine rays through depthtex0, gathers lit colortex0 radiance, AO removes occluded share of colortex6 indirect) and glossy SSR (swaps sky reflection for hit radiance), rays/steps by tier (`program/deferred_gi.glsl`) | colortex0-3, colortex6, depthtex0, EnvState | colortex0 | full | per-frame noise, resolved by TAA | `SCREEN_SPACE_GI` / `GLOSSY_REFLECTIONS` off | — | UNMEASURED |
| 5b | deferred1 | copy of the opaque scene to colortex5 for water; fill sky where no sky geometry drew (alpha 0); volumetric cumulus + cirrus over sky and terrain beyond the clouds (`lib/atmosphere/clouds.glsl`, steps by tier) | colortex0, depthtex0, EnvState | colortex0 | full | dithered start, resolved by TAA | `CLOUD_STYLE` 0/1 skip it | — | UNMEASURED |
| 6 | gbuffers_water / hand_water | forward-lit translucents (LabPBR for glass/ice/slime/honey, blended); water (D-015) written opaque: refraction of colortex5, depth absorption/scattering, SSR + sky/cloud reflection, waves, rain ripples, glint, foam, Snell window from below | textures, LabPBR maps, colortex5, depthtex1, shadowtex0/1, shadowcolor0, EnvState | colortex0 | full | dithered SSR start | `WATER_REFLECTIONS` off: sky/clouds only | — | UNMEASURED |
| 7 | gbuffers_weather / textured / basic | rain/snow, unlit glows, outlines | textures, EnvState | colortex0 (blend) | full | none | — | — | UNMEASURED |
| 8 | composite | aerial perspective, border fog, valley mist, medium fog (water/lava/powder snow), blindness/darkness; volumetric sunlight through the shadow map (`VOLUMETRIC_LIGHT`); underwater shafts | colortex0, depthtex0, shadowtex0/1, EnvState | colortex0 | full | dithered march, resolved by TAA | options off skip the marches | — | UNMEASURED |
| 9 | composite1 | temporal anti-aliasing: reproject with previous-frame matrices, Catmull-Rom history, 3x3 YCoCg variance clip, blend 10-25% current | colortex0, colortex3 (entity mask), colortex4, depthtex0 | colortex0, colortex4 | full | colortex4 history; reset on empty history, camera jump > 4 blocks, off-screen reprojection | `TAA` off disables the program and the jitter | — | UNMEASURED |
| 9b | composite2 | bloom: 3x3 tent at mip levels 1-6 of colortex0 (Iris-generated mipmaps) | colortex0 (mipmapped) | colortex7 | full | none | `BLOOM` off disables the program | — | UNMEASURED |
| 10 | final | droplets after surfacing, bloom mix (preset share), split-tone grade (preset), model-based exposure (daylight normalization x local adaptation), contrast/saturation, knee+shoulder tonemap, sRGB encode, dither, debug views | colortex0-3, depthtex0 | screen | full | none | — | 0-6 | UNMEASURED |

The Nether (world-1) and End (world1) use the same graph without pass 1.
