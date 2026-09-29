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
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 cameraPosition;
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

// Player status effects (readability / vanilla behavior)
uniform float blindness;
uniform float darknessFactor;
uniform float nightVision;

#endif
