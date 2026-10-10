// Catalyst — the one authoritative declaration of shared Iris uniforms (docs/architecture/uniform_contracts.md).
// All names verified against the Iris 1.21.11 source (state/evidence/iris_1.10.7_capabilities.md).
//
// Conventions:
//   *Position (sunPosition, moonPosition, shadowLightPosition): view space, NOT normalized.
//   gbufferModelViewInverse: view space -> player space (world axes, origin at the camera/eye).
//   cameraPosition: world-space camera position; worldPos = playerPos + cameraPosition.
//   frameTimeCounter: seconds, wraps every hour.  worldTime: ticks 0..23999.

#if !defined CATALYST_UNIFORMS
#define CATALYST_UNIFORMS

// Camera / transforms
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView;  // previous frame (TAA reprojection)
uniform mat4 gbufferPreviousProjection;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;   // same shifted origin as cameraPosition (Iris keeps their difference exact)
uniform float near;
uniform float far;

// Screen / frame
uniform float viewWidth;
uniform float viewHeight;
uniform int frameCounter;
uniform float frameTimeCounter;

// Sun / moon / time
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 shadowLightPosition;
uniform int worldTime;
uniform int moonPhase;

// Weather / environment
uniform float rainStrength;
uniform float wetness;
uniform float thunderStrength;
uniform vec3 skyColor;
uniform vec3 fogColor;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform float eyeAltitude;
uniform float cloudHeight;               // vanilla cloud altitude (environment attribute), blocks
uniform vec4 lightningBoltPosition;      // xyz relative to the camera, w = 1 while a bolt exists

// Custom uniforms defined in shaders.properties (Iris smooth(): fade times are 0.1 s units of half-life).
uniform float weatherWetness;            // rain-biome rain, soaks in ~30 s half-life, dries ~120 s
uniform float weatherSnowCover;          // snow-biome snowfall, builds ~60 s half-life, melts ~180 s

// Player status effects (readability / vanilla behavior)
uniform float blindness;
uniform float darknessFactor;
uniform float nightVision;

#endif
