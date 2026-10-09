# Catalyst Data Contracts

For every shared resource record:
- name
- format/channels
- encoding
- producer
- consumers
- resolution
- precision
- clear policy
- lifetime
- flip/current/previous behavior
- debug view
- fallback

No undocumented shared resource should become foundational.

## Current contracts (M1; source of truth: `shaderpack/Catalyst/shaders/lib/core/buffers.glsl`)

| Resource | Format | Channels / encoding | Producers | Consumers | Clear | Lifetime / history | Debug view |
|---|---|---|---|---|---|---|---|
| colortex0 | RGBA16F, full res | rgb = scene-linear HDR radiance (Rec.709 primaries, see `lib/core/common.glsl`); a = coverage (0 = nothing drawn) | all gbuffers (forward shading), deferred (sky fill), composite (fog) | deferred, composite, final | (0,0,0,0) every frame | current frame only; Iris ping-pong within composite passes | final output |
| colortex1 | RGBA16, full res | rg = octahedral **shading** normal (normal-mapped when material maps are on), player axes, mapped to [0,1]; b = packed lightmap (8-bit block x 256 + 8-bit sky, /65535); a = 1 written / 0 empty | gbuffers_terrain / entities / hand / block / textured_lit | final (debug); future SSAO/GI (M5) | 0 every frame | current frame | 2 Normals, 3 Light Levels |
| colortex2 | RGBA8, full res | rgb = albedo as sampled (sRGB-encoded); a = 1 / 0 | same as colortex1 | final (debug); future GI (M5) | 0 every frame | current frame | 1 Albedo |
| colortex3 | RGBA8, full res | r = material class / 255 (`lib/material/classify.glsl`); g = direct-light shadow visibility; b = perceptual smoothness (0 when the surface has no specular data); a = 1 / 0 | same as colortex1 | final (debug); future SSR (M5) | 0 every frame | current frame | 4 Materials, 6 Sun Shadow, 7 Smoothness |
| shadowtex0 | depth, `shadowMapResolution` squared | distorted orthographic sun/moon depth (`distortShadowClip`, z x 0.2) | shadow (world0 only) | lit gbuffers via `sampleShadow` (hardware compare) | per frame | current frame | 6 Sun Shadow (receiver side) |

Rule: data buffers (1-3) are always written with alpha = 1, so vanilla SRC_ALPHA blending (entities, particles, hand) overwrites them exactly. Translucent programs (water, glass, clouds, weather, unlit) write colortex0 only.

## External material inputs (M2)
| Resource | Source | Encoding | Consumers | Fallback |
|---|---|---|---|---|
| `normals` sampler | resource-pack `_n` textures (Iris) | LabPBR 1.3 normal (DirectX XY), b = AO, a = height | gbuffers lit/translucent via `lib/material/labpbr.glsl` | Iris flat default; option `MATERIAL_MAPS` off skips sampling |
| `specular` sampler | resource-pack `_s` textures (Iris) | LabPBR 1.3 smoothness / F0-metal / SSS-porosity / emission | same | Iris zero default = no specular |
| `at_tangent` attribute | Iris vertex format | xyz = dP/du, w = handedness (dP/dv = cross(T,N)·w) | same | zero for formats without tangents: normal mapping skipped |
