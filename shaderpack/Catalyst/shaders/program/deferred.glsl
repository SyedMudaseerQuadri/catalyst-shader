// Catalyst — deferred pass (after opaque geometry, before translucents).
// Fills any sky pixel that no sky geometry covered (colortex0 alpha still 0 from the clear), so the background
// is never undefined black, then composites the volumetric clouds over the sky and over terrain beyond them.
// Translucents (water, glass) are drawn after this pass, on top of the clouds. Future home of SSAO / GI (M5).

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

#include "/lib/environment/state.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/atmosphere/clouds.glsl"

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

in vec2 uv;

/* RENDERTARGETS: 0,5 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outOpaqueCopy;

void main() {
	vec4 scene = texture(colortex0, uv);
	float depth = texture(depthtex0, uv).r;

	EnvState env = getEnvState();
	vec3 dir = normalize(playerDirFromView(viewFromScreen(vec3(uv, 1.0))));
	if (depth >= 1.0 && scene.a <= 0.0) {
		scene = vec4(skyRadiance(dir, env), 1.0);
	}

#if CLOUD_STYLE == 2 && defined DIM_OVERWORLD
	float maxDistance = depth >= 1.0 ? 1e6 : length(viewFromScreen(vec3(uv, depth)));
	// Per-pixel, per-frame start offset: banding becomes noise that TAA averages away.
	float dither = interleavedGradientNoise(gl_FragCoord.xy + 5.588238 * float(frameCounter % 64));
	scene.rgb = applyClouds(scene.rgb, dir, maxDistance, env, dither);
#endif

	outColor = scene;
	outOpaqueCopy = vec4(scene.rgb, 1.0);
}

#endif
