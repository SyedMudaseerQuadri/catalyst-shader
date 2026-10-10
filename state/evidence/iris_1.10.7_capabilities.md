# EV-001 — Iris capabilities for the pinned target (source inspection)

- **id:** EV-001
- **date:** 2026-09-30
- **claim:** The Iris features Catalyst M1 depends on exist in Iris for Minecraft 1.21.11.
- **environment:** GitHub `IrisShaders/Iris`, branch `1.21.11`, head commit `0a1fcaae55099356bf53410b4f5302753edb0ffc` (2026-09-19). Network access, no Minecraft runtime.
- **procedure:** Read the loader/uniform source files named below and matched every directive, program name, uniform and macro Catalyst uses.
- **confidence:** MEDIUM. This is the branch head, not a confirmed `1.10.7` release tag (no such tag was found through the GitHub API). All features used are long-standing Iris features, but runtime behavior is **UNVERIFIED** until the pack is loaded in-game.

## Verified in source

| Feature | Source file | Result |
|---|---|---|
| Program names and fallback chains (`terrain`→`textured_lit`→`textured`→`basic`, `water`→`terrain`, `entities`/`hand`/`particles`→`textured_lit`, `skytextured`/`clouds`→`textured`) | `shaderpack/loading/ProgramId.java` | VERIFIED (source) |
| `dimension.properties` with `world0` / `world-1` / `world1` and `*` fallback | `shaderpack/ShaderPack.java`, `DimensionId.java` | VERIFIED (source) |
| `program.<path>.enabled = <option>`; program key is the path without extension (`world0/shadow`) | `ShaderProperties.java` l.384/699, `ShaderPack.java` l.261–296 | VERIFIED (source) |
| `profile.*`, `screen`, `screen.<name>`, `screen.columns`, `sliders` | `ShaderProperties.java` l.605–622 | VERIFIED (source) |
| `oldLighting`, `separateAo`, `underwaterOverlay`, `vignette`, `sun`, `moon`, `clouds`, `shadowTerrain/Entities/BlockEntities` | `ShaderProperties.java` l.161–223 | VERIFIED (source) |
| `colortexNFormat` (RGBA16F, RGBA16, RGBA8, R11F_G11F_B10F, RG16F), `colortexNClear`, `colortexNClearColor` | `PackRenderTargetDirectives.java`, `InternalTextureFormat.java` | VERIFIED (source) |
| `shadowMapResolution`, `shadowDistanceRenderMul`, `shadowHardwareFiltering`, `sunPathRotation` const directives | `PackShadowDirectives.java`, `PackDirectives.java` | VERIFIED (source) |
| Uniforms used by `lib/core/uniforms.glsl` (+ `renderStage`, `entityColor`, `moonPhase`) | `uniforms/*.java` | VERIFIED (source), all names present |
| `MC_RENDER_STAGE_<PHASE>` macros = `WorldRenderingPhase` ordinal | `gl/shader/StandardMacros.java` l.113, 352 | VERIFIED (source) |
| Boolean option rule: a `#define X` is a menu option only if some line is exactly `#ifdef X`/`#ifndef X` | `shaderpack/option/OptionAnnotatedSource.java` | VERIFIED (source); Catalyst uses `#if defined` for internal flags |
| Optional feature flags: `COMPUTE_SHADERS`, `SSBO`, `CUSTOM_IMAGES`, `PER_BUFFER_BLENDING`, `TESSELLATION_SHADERS`, `SEPARATE_HARDWARE_SAMPLERS` (hardware-gated) | `features/FeatureFlags.java` | VERIFIED (source); none are required by M1 |

## Addendum 2026-10-11 — features used by TAA (same commit `0a1fcaae`)

| Feature | Source file | Result |
|---|---|---|
| `gbufferPreviousModelView`, `gbufferPreviousProjection` (previous frame's matrix, per frame) | `uniforms/MatrixUniforms.java` l.38, 66-83 | VERIFIED (source) |
| `previousCameraPosition`; origin shift is applied to current and previous alike, so their difference is exact | `uniforms/CameraUniforms.java` l.30, 62-120 | VERIFIED (source) |
| `colortexNClear = false` keeps a buffer out of the per-frame clear list | `shaderpack/properties/PackRenderTargetDirectives.java` l.55-64, 116 | VERIFIED (source) |
| `MC_HAND_DEPTH` macro = `HandRenderer.DEPTH` = 0.125 (hand projection z scaled by 0.125) | `gl/shader/StandardMacros.java` l.104, `pathways/HandRenderer.java` l.39, 56 | VERIFIED (source) |
| History persistence across frames for a never-cleared buffer read and written by one composite pass | `targets/BufferFlipper.java` (ping-pong) | source read; runtime UNVERIFIED |
| No per-vertex velocity attribute: Iris vertex formats add only `mc_Entity`, `mc_midTexCoord`, `at_tangent`, `at_midBlock` | `vertices/IrisVertexFormats.java` l.29-45 (and no velocity/motion file in the 1166-entry source tree) | VERIFIED ABSENT (source) |

## Addendum 2026-10-11 (M3) — environment inputs (same commit `0a1fcaae`)

| Feature | Source file | Result |
|---|---|---|
| `biome_precipitation` (0 none, 1 rain, 2 snow, at the player position), `temperature`, `rainfall`, `biome`, `biome_category` (per tick) | `uniforms/BiomeUniforms.java` l.30-53 | VERIFIED (source) |
| `wetness` = smoothed `rainStrength`; half-lives default 600 / 200 (0.1 s units) | `uniforms/CommonUniforms.java` l.181, `properties/PackDirectives.java` l.63-64 | VERIFIED (source) |
| **Defect:** the `drynessHalflife` directive writes the *wetness* half-life | `properties/PackDirectives.java` l.283-284 | VERIFIED (source); Catalyst avoids the directive and uses custom uniforms |
| Custom uniforms `uniform.<type>.<name> = <expr>` in shaders.properties; inputs = all non-dynamic uniforms (incl. biome) | `ShaderProperties.java` l.586-593, `IrisRenderingPipeline.java` l.297-299 | VERIFIED (source) |
| `smooth(target, fadeUp, fadeDown)`, `if(bool, a, b)`, `==` on ints; fade values are half-lives in 0.1 s units | `parsing/IrisFunctions.java` l.444-640, `parsing/SmoothFloat.java` l.60-120 | VERIFIED (source) |
| `thunderStrength` (per frame) | `uniforms/IrisExclusiveUniforms.java` l.62 | VERIFIED (source) |
| `lightningBoltPosition` (xyz camera-relative, w = 1 while a bolt entity exists, per tick) | `uniforms/IrisExclusiveUniforms.java` l.91-102 | VERIFIED (source) |
| `cloudHeight` (vanilla cloud altitude environment attribute, per frame) | `uniforms/IrisExclusiveUniforms.java` l.290-296 | VERIFIED (source) |
| `shadowModelViewInverse` | `uniforms/MatrixUniforms.java` l.49-51 | VERIFIED (source) |
| `mc_midTexCoord` vertex attribute (float x2) | `vertices/IrisVertexFormats.java` l.31, 43 | VERIFIED (source) |
| `depthtex1` = depth copied before translucents (`beginTranslucents` -> `copyPreTranslucentDepth`) | `pipeline/IrisRenderingPipeline.java` l.1058-1069 | VERIFIED (source); used by M4 |
| `shadowtex1` = shadow depth without translucents | `shadows/ShadowRenderTargets.java` l.66, 181; `shadows/ShadowRenderer.java` l.575-587 | VERIFIED (source); used by M4 |
| Wind, season, snow-trail history: no input | none | UNAVAILABLE (wind APPROXIMATED procedurally; season and trails DEFER) |
