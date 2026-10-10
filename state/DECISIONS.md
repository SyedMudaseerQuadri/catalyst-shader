# Catalyst Decisions

## D-001 — Single visual authority
`docs/visual/aesthetic_direction.md` is the sole canonical visual/aesthetic specification. the retired visual-target summary is retired to the archive.

## D-002 — Preset model
Catalyst uses three visual presets and five independent performance presets. RT/PT are techniques, not global preset families.

## D-003 — Environmental-state-first architecture
The updated aesthetic direction is treated as an architectural dependency: shared environmental state is foundational to weather, atmosphere, lighting, clouds, wetness, snow, foliage, water interaction, and temporal response.

## D-004 — Context-efficient agent memory
Use a small always-relevant `CLAUDE.md` plus state/checkpoint files and task-specific documents. Do not require full documentation rereads on normal sessions.

## D-005 — Tier-scoped GI strategy
Screen-space GI is the permanent GI method at internal rendering tiers Low/Medium/High (see
`docs/architecture/preset_model.md` for the user-facing preset vs. internal tier distinction —
this is never a preset name), not a discarded step toward voxel GI. Voxel-based GI is reserved for
internal tiers Ultra/Extreme, additive to (not a replacement for) screen-space GI at lower tiers.
Rationale: without this, the internal Low/Medium/High tiers would have no indirect lighting at all, which is a real, visible quality gap for the majority of
users' hardware — and screen-space GI is exactly the kind of technique that lets performance-
conscious reference packs (BSL, Solas, Shrimple) achieve a strong look cheaply. Screen-space GI's
known limitation (screen-space-only information — misses off-screen/occluded bounce light, can
leak/halo at edges) is an accepted, documented tradeoff for these tiers, not something to hide.

## D-006 — Minimum hardware target: RTX 3050
The minimum supported GPU is the NVIDIA GeForce RTX 3050 (Ampere, desktop, 8GB VRAM). At that floor, the
**Performance** preset must be playable at 1080p with default settings. Balanced and above may need
stronger hardware. The dev RTX 4060 (8GB) stays the recommended/primary machine.
Consequences:
- Every subsystem needs a Performance-preset path that fits the RTX 3050's compute and memory
  bandwidth. Voxel GI (M6) and RT/PT (M7) can never be required at the Performance preset.
- Catalyst runs on Iris/OpenGL, so the 3050's hardware RT cores offer no guaranteed benefit. Do not
  plan for them.
- The 6GB desktop and 4GB laptop RTX 3050 variants are not covered until verified.
Status: decision recorded; runtime evidence is UNVERIFIED because no RTX 3050 is available for testing
(see ISSUES.md).

## D-007 — Forward shading in gbuffers for M1/M2
Every lit gbuffers program shades itself into colortex0 and also writes G-buffer data (colortex1-3)
for later screen-space passes and debug views.
Rationale: Iris runs some programs (hand, particles, translucents) after `deferred`, so a deferred-only
lighting path would leave them unlit or need duplicate code. Forward shading through one shared lighting
library (`lib/lighting/forward.glsl`) keeps a single implementation that lights every program the same way.
The deferred slot stays free for SSAO / screen-space GI (M5).
Cost: overdraw means shading work for hidden fragments. Measure on the RTX 3050 floor; revisit if it dominates.

## D-008 — How the two preset axes map to Iris
Performance presets = the 5 Iris profiles (`profile.PERFORMANCE` ... `profile.CINEMATIC`). Balanced equals the source defaults.
Visual preset = the `VISUAL_PRESET` option (3 values). It resolves `PRESET_*` constants in `lib/settings.glsl`.
User sliders multiply the preset value (1.00 = preset default), which implements the precedence
"user override > preset". Iris shows the profile as custom once a performance option is changed.
Internal tiers: `INTERNAL_TIER` = `PERF_PROFILE` (hidden option, set only by profiles). It never appears in the UI.

## D-009 — Internal compile-time flags use `#if defined`, never `#ifdef`
Iris turns any `#define X` that some line tests with `#ifdef X` / `#ifndef X` into a boolean menu option
(checked in the source, EV-001). Include guards, stage, dimension and program flags therefore use `#if defined X`.
Only real user options (currently `SHADOWS`) are tested with `#ifdef`. `tools/validate_shaderpack.py` enforces this.

## D-010 — LabPBR 1.3 is the material input format; vanilla textures get no specular
Catalyst reads resource-pack materials only in the LabPBR 1.3 layout (`lib/material/labpbr.glsl`), the format
the architecture doc names as the preferred baseline. Without material data (f0 = 0, Iris default) surfaces are
purely diffuse, so vanilla textures keep their look (Minecraft identity). Specular is GGX + correlated Smith +
Schlick with a split-sum sky reflection. Single-scattering energy loss at high roughness is accepted for now (EV-003).
Option `MATERIAL_MAPS` (default on) skips the two texture reads when disabled. It is not tied to a performance profile.

## D-011 — Indirect light keeps surface color; exposure adapts only partially
From the first in-game test (EV-004): (1) sky ambient is a near-neutral, desaturated tint of the biome sky at
~4.5:1 sun-to-sky luminance; (2) occlusion uses an albedo-tinted multi-bounce fit (Jimenez 2016,
`BOUNCE_STRENGTH` 0.55) as the stand-in for GI until M5; (3) exposure adapts partially (`EXPOSURE_ADAPTATION`,
default 0.5) between a fixed daylight reference and the scene estimate, so interiors, caves and night stay
naturally darker. Constants are tuned with `tools/tone_sim.py`, which must be kept in sync with the shader formulas.

## D-012 — Tone pipeline v2 (supersedes the exposure part of D-011)
From EV-005, tuned in `tools/tone_sim.py` after calibrating its 0.2.1 model against the screenshots:
(1) tonemap = per-channel linear-to-knee (0.55) + exponential shoulder, replacing Reinhard;
(2) exposure = daylight normalization on open-ground irradiance (strength 0.85 by day, 0.55 at night, anchored at
noon 3.10) x subtle local adaptation (`EXPOSURE_ADAPTATION` default 0.15);
(3) clear-sky dome and sky ambient scale with sun height (`daylightSkyScale`), dome uses `PRESET_SKY_DOME_VANILLA`;
(4) block/sky light falloff powers 4.0 / 3.5 (vanilla's curve lives in display space) and block-light hue that warms
as it dims; multi-bounce strength 0.35; (5) clouds include sky in-scatter so they are never darker than the sky.

## D-013 — Temporal anti-aliasing design (M2 temporal foundation)
Jittered TAA in a dedicated composite1 pass on the fogged HDR scene, before exposure/tonemap (so exposure changes
never smear through history). Camera-only reprojection from depth. Per-object motion vectors are not possible: Iris 1.10.7's vertex formats have no
velocity attribute (checked `vertices/IrisVertexFormats.java`: only mc_Entity, mc_midTexCoord, at_tangent, at_midBlock).
Mitigation: history alpha marks entity pixels; history that was an entity where no entity is in the current 3x3
neighborhood is mostly discarded (trail removal). Static block entities keep entity neighbors, so their edges stay AA'd. History in colortex4 (RGBA16F, never cleared).
Centralized invalidation in `lib/post/taa.glsl`: empty history, camera jump > 4 blocks/frame (teleport, portal,
respawn), off-screen reprojection. The hand is not reprojected (it moves with the camera). Lines/outlines and the sky
pass are not jittered. Debug views disable jitter. One user option, `TAA` (default on in every profile: the cost is
one fullscreen pass with 14 texture reads per pixel).

## D-014 — Coupled environment (M3)
One weather state drives every subsystem through EnvState: `cloudCover` (preset + slider + rain/thunder),
`surfaceWet` / `snowCover` (custom smoothed uniforms gated by biome precipitation: wet 30 s soak / 120 s dry,
snow 60 s build / 180 s melt, so stages progress at different rates), `wind` (procedural gust envelope, the only
APPROXIMATED input), `lightningFlash` (bolt presence, flickering, distance-attenuated).
Clouds: ray-marched cumulus slab at the vanilla cloud altitude + 2D cirrus, rendered in deferred over sky and
distant terrain, steps scaled by internal tier (10/14/20/28/40); cloud shadows sample the same coverage field;
vanilla clouds only with Clouds = Vanilla. Drift is a constant velocity (a time-varying speed integrated over
frameTimeCounter would make clouds jump); frameTimeCounter's hourly wrap causes one jump per hour (accepted).
Surfaces: sky-light-gated exposure; porosity-based darkening, water film, progressive puddles; snow on upward
faces with irregular coverage and moderate albedo. Foliage/leaves sway in the same wind in terrain and shadow passes.
Mist: low valley mist around sunrise and on wet ground. Snow trails and seasons: DEFER (no persistent world-space
history / no input).

## D-015 — Water and underwater (M4)
Water is composited by gbuffers_water itself and written opaque: deferred copies the opaque HDR scene (sky, clouds,
terrain) into colortex5 (R11F_G11F_B10F); the water shader refracts it by the wave tilt, absorbs/scatters along the
real path through the water (depthtex1, the pre-translucent depth Iris provides), and mixes a Fresnel reflection:
screen-space reflection of terrain (`WATER_REFLECTIONS`, steps by tier) over an environment reflection of sky +
approximate clouds. Optics: clear-water absorption (0.34, 0.07, 0.03)/block + bluish scattering; the biome water
tint (vertex color) raises absorption/scattering for murky water. Waves: fragment normals from a wind-aligned
height field (amplitude from wind/weather), never vertex displacement; rain ring ripples on water and puddles.
From below: Snell's window with total internal reflection. Shoreline foam where the water is thin.
Light under water: water is now a shadow caster in shadowtex0 only, flagged in shadowcolor0 (a = 0.5); receivers
take opaque shadows from shadowtex1 and get water depth = shadowtex0/shadowtex1 depth difference in blocks, giving
absorbed sunlight, attenuated sky light and caustics (normalized to mean 1, Monte Carlo fit). Stained glass/ice now
cast colored shadows (shadowcolor0 rgb) instead of black ones. Underwater view: sun shafts marched through the
shadow maps (`UNDERWATER_SHAFTS`). After surfacing: droplets running down the view (`VIEW_DROPLETS`, ~3 s).
Limitations: entities and particles behind water are covered by the opaque water write if drawn before it;
shoreline sand is not darkened (no water-proximity data in opaque passes); the underwater-light effects need Shadows.
