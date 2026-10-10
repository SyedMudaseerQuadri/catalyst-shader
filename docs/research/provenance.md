# Catalyst Research Provenance

For every subsystem materially influenced by external research record:
- source
- source/version
- concept studied
- evidence reviewed
- Catalyst interpretation
- implementation differences
- license/usage constraints
- influence type: conceptual / algorithmic / implementation-independent

Do not record proprietary source code as implementation material.

## Recorded influences (M1)

No reference-shader source code was used. `reference_shaders/` was not opened for the M1 implementation.

| Subsystem | Source | Concept | Catalyst interpretation | Influence type |
|---|---|---|---|---|
| Shadow filtering noise | Jimenez, "Next Generation Post Processing in Call of Duty: Advanced Warfare" (SIGGRAPH 2014), public | interleaved gradient noise | per-pixel rotation of the shadow kernel; final-pass dither | algorithmic (published formula) |
| Shadow kernel | Vogel (1979) sunflower spiral, public mathematics | golden-angle disk sampling | 4/8/16-tap PCF kernel | algorithmic |
| Shadow distortion | common public shadow-mapping technique (radial texel redistribution) | concentrate texels near the viewer | own factor/bias derivation in `lib/shadow/shadows.glsl` | conceptual |
| Sun color | Kasten & Young (1989) relative optical airmass; Rayleigh optical depths from standard atmospheric physics | transmittance-driven sunlight color | `atmosphericTransmittance()` in `lib/environment/state.glsl` | algorithmic (published formula) |
| Sky halo | Henyey & Greenstein (1941) phase function | forward aerosol scattering around the sun | halo term in `lib/atmosphere/sky.glsl` | algorithmic |
| Normal encoding | Cigolle et al., "A Survey of Efficient Representations for Independent Unit Vectors" (JCGT 2014) | octahedral encoding | `lib/core/encode.glsl` | algorithmic |
| Tonemap | Reinhard et al. (2002), extended operator with white point | HDR to display compression | `lib/post/tonemap.glsl` | algorithmic |
| Color transfer | IEC 61966-2-1 (sRGB) | exact sRGB EOTF/OETF | `lib/core/common.glsl` | standard |

## Recorded influences (M2 materials)

| Subsystem | Source | Concept | Catalyst interpretation | Influence type |
|---|---|---|---|---|
| Material format | LabPBR Material Standard 1.3 (shaderLABS wiki, public specification) | resource-pack normal/specular channel layout | decoded from the spec text in `lib/material/labpbr.glsl` | standard |
| Tangent frame | Iris `NormalHelper.computeTangent` (LGPL-3.0, read for the interface contract only) | sign convention of `at_tangent.w` | bitangent = cross(T, N) * w; no code copied | interface contract |
| Specular distribution | Walter et al., "Microfacet Models for Refraction through Rough Surfaces" (EGSR 2007) | GGX NDF | `ggxDistribution()` | algorithmic |
| Visibility | Heitz, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs" (JCGT 2014) | height-correlated Smith G2 | `smithGgxCorrelatedVisibility()` | algorithmic |
| Fresnel | Schlick (1994) | Fresnel approximation | `fresnelSchlick()` | algorithmic |
| Environment BRDF | Karis, "Physically Based Shading on Mobile" (Unreal Engine blog, 2014) | analytic split-sum fit, F0 < 2% treated as no specular | `environmentBrdf()` | algorithmic (published fit constants) |

## Recorded influences (M2 temporal)

| Subsystem | Source | Concept | Catalyst interpretation | Influence type |
|---|---|---|---|---|
| TAA overall | Karis, "High Quality Temporal Supersampling" (SIGGRAPH 2014 course), public | jittered projection, reprojected history, neighborhood clamp, luminance-weighted blending | `lib/post/taa.glsl`, `program/taa.glsl` | algorithmic |
| Jitter sequence | Halton (1964) low-discrepancy sequence, public mathematics | base 2 / base 3 radical inverse | 8-position cycle in `taaHalton()` | algorithmic |
| History filter | Jimenez et al., "Filmic SMAA" (SIGGRAPH 2016 course), public | 5-tap bilinear Catmull-Rom approximation | `taaSampleHistory()` | algorithmic |
| History rejection | Salvi, "An Excursion in Temporal Supersampling" (GDC 2016), public | variance (mean +- sigma) neighborhood box | intersected with min/max box, YCoCg | algorithmic |
| History clipping | Pedersen, "Temporal Reprojection Anti-Aliasing in INSIDE" (GDC 2016), public talk | clip toward box center instead of per-channel clamp | `taaClipToBox()`; no code used | conceptual |
| Previous-frame data | Iris `MatrixUniforms` / `CameraUniforms` (LGPL-3.0, read for the interface contract only) | `gbufferPrevious*`, `previousCameraPosition`, origin shift keeps the camera delta exact | uniform declarations only | interface contract |

## Recorded influences (M3 environment)

| Subsystem | Source | Concept | Catalyst interpretation | Influence type |
|---|---|---|---|---|
| Hashing | Jarzynski & Olano, "Hash Functions for GPU Rendering" (JCGT 2020) | PCG integer hashes | `lib/core/noise.glsl` | algorithmic (published) |
| Value noise | Perlin (2002), "Improving Noise" | quintic fade curve | value-noise interpolation | algorithmic |
| Cloud rendering | Schneider & Vos, "The Real-Time Volumetric Cloudscapes of Horizon Zero Dawn" (SIGGRAPH 2015), public | coverage map x height profile, eroded by detail noise; short light march | own density/profile functions, no code | conceptual |
| Cloud multiple scattering | Wrenninge, Kulla & Lundqvist, "Oz: The Great and Volumetric" (SIGGRAPH 2013 talk), public | attenuated optical-depth octaves approximate multiple scattering | one extra octave, max() combined | algorithmic |
| Cloud phase | Henyey & Greenstein (1941) | two-lobe phase | forward + back lobe mix | algorithmic |
| Volume integration | Hillaire, "Physically Based and Unified Volumetric Rendering in Frostbite" (SIGGRAPH 2015), public | energy-conserving per-step scattering integration | S * (1 - exp(-sigma dt)) | algorithmic |
| Foliage anchoring | common public shader-pack practice, Iris `mc_midTexCoord` | top vs rooted vertex from the sprite center | own wind model | conceptual |

## Recorded influences (M4 water)

| Subsystem | Source | Concept | Catalyst interpretation | Influence type |
|---|---|---|---|---|
| Water optics | Pope & Fry (1997), "Absorption spectrum of pure water", public data | red absorbs strongly, blue weakly | rounded per-block coefficients | data (rounded) |
| Light attenuation | Beer-Lambert law | exponential extinction along the path | view path (surface) and light path (shadow-map depth difference) | physics |
| Refraction/Fresnel | Snell's law, Schlick (1994) | Snell's window, total internal reflection | `shadeWater()` from below | physics |
| Screen-space reflections | McGuire & Mara, "Efficient GPU Screen-Space Ray Tracing" (JCGT 2014), public | view-space ray march against the depth buffer, edge fade | own growing-step march + bisection | conceptual |
| Water depth from shadow maps | common public shader technique (shadowtex0 vs shadowtex1, Iris/OptiFine documentation) | depth difference between translucent and opaque casters | blocks via the projection's depth scale | conceptual |
| Rain ripples | public common technique (ring waves per random cell) | expanding ring normal perturbation | own cell/phase scheme | conceptual |
