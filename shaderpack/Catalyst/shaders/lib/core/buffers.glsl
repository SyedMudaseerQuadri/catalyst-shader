// Catalyst — render target formats and clear policy. Contract: docs/architecture/data_contracts.md.
// Iris reads these directives from the program source; they are in a comment because the format
// names are not GLSL identifiers.
/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGBA16;
const int colortex2Format = RGBA8;
const int colortex3Format = RGBA8;
const int colortex4Format = RGBA16F;
const int colortex5Format = R11F_G11F_B10F;
const int colortex6Format = RGBA16F;
const int colortex7Format = R11F_G11F_B10F;
*/
//
// Data buffers (1-3) always receive alpha = 1 from their producers. Under vanilla SRC_ALPHA blending
// (entities, particles, hand) that makes every write an exact overwrite, so no data is blended.

#if !defined CATALYST_BUFFERS
#define CATALYST_BUFFERS

// colortex0: scene HDR radiance. Cleared to transparent black so passes can detect "nothing drawn" (alpha 0).
const bool colortex0Clear = true;
const vec4 colortex0ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
// colortex1: rg = octahedral normal, b = packed lightmap, a = 1 (written) / 0 (nothing drawn).
const bool colortex1Clear = true;
const vec4 colortex1ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
// colortex2: rgb = albedo (sRGB-encoded, as sampled), a = 1 / 0.
const bool colortex2Clear = true;
const vec4 colortex2ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
// colortex3: r = material class / 255, g = direct-light shadow visibility, b = unused, a = 1 / 0.
const bool colortex3Clear = true;
const vec4 colortex3ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
// colortex4: TAA history (resolved HDR scene of the previous frame), a = 1 once written. Never cleared:
// it must survive into the next frame. Written only by composite1 (program/taa.glsl).
const bool colortex4Clear = false;
// colortex5: copy of the opaque HDR scene (sky + clouds + opaque geometry) made in deferred, read by gbuffers_water for
// refraction and screen-space reflections (a buffer cannot be read while it is being drawn to). Fully rewritten
// every frame, so it is not cleared.
const bool colortex5Clear = false;
// colortex6: rgb = indirect diffuse radiance already contained in colortex0 (albedo x ambient/block/bounce light),
// a = scalar weight of the environment reflection; written by the opaque lit programs, refined by deferred_gi
// (screen-space AO removes occluded indirect light, GI adds gathered bounce, SSR swaps sky for hit radiance).
const bool colortex6Clear = true;
const vec4 colortex6ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
// colortex7: bloom (composite2, from colortex0 mipmaps), read by final. Fully rewritten each frame.
const bool colortex7Clear = false;

#endif
