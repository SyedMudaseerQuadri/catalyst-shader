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
