// Catalyst — composite pass: atmospheric / medium fog over the finished HDR scene (opaque + translucent),
// plus volumetric sunlight (shafts through trees and mist) and underwater light shafts.

#include "/lib/settings.glsl"
#include "/lib/core/common.glsl"
#include "/lib/core/uniforms.glsl"
#include "/lib/core/space.glsl"
#include "/lib/core/buffers.glsl"

// =============================================================================================
#if defined STAGE_VERTEX

out vec2 uv;

void main() {
	uv = gl_MultiTexCoord0.xy;
	gl_Position = ftransform();
}

#endif
// =============================================================================================
#if defined STAGE_FRAGMENT

// Volumetric sunlight and underwater shafts read the shadow maps (user options; Iris needs #ifdef to list them).
#ifdef SHADOWS
	#if defined DIM_OVERWORLD
		#define SHADOW_RECEIVER
	#endif
#endif

#include "/lib/environment/state.glsl"
#include "/lib/shadow/shadows.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/atmosphere/fog.glsl"
#include "/lib/atmosphere/clouds.glsl"
#include "/lib/environment/water.glsl"
#include "/lib/atmosphere/underwater.glsl"
#include "/lib/atmosphere/volumetric.glsl"

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

in vec2 uv;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main() {
	vec3 color = texture(colortex0, uv).rgb;
	float depth = texture(depthtex0, uv).r;
	bool isSky = depth >= 1.0;

	vec3 viewPos = viewFromScreen(vec3(uv, depth));
	vec3 playerPos = playerFromView(viewPos);
	if (isSky) {
		// Give the sky a direction at a large distance so medium fog (underwater) still applies to it.
		playerPos = normalize(playerDirFromView(viewFromScreen(vec3(uv, 1.0)))) * far;
	}

	EnvState env = getEnvState();
	color = applyAtmosphericFog(color, playerPos, isSky, env);
#if defined SHADOW_RECEIVER
	float dither = interleavedGradientNoise(gl_FragCoord.xy + 5.588238 * float(frameCounter % 64));
	#ifdef UNDERWATER_SHAFTS
	if (isEyeInWater == 1) color += underwaterShafts(playerPos, env, dither);
	#endif
	#ifdef VOLUMETRIC_LIGHT
	if (isEyeInWater == 0) color += volumetricSunlight(playerPos, isSky, env, dither);
	#endif
#endif

	outColor = vec4(color, 1.0);
}

#endif
