// Catalyst — deferred pass (after opaque geometry, before translucents).
// M1 role: fill any sky pixel that no sky geometry covered (colortex0 alpha still 0 from the clear),
// so the background is never undefined black. Future home of SSAO / screen-space GI (M5).

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

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

in vec2 uv;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

void main() {
	vec4 scene = texture(colortex0, uv);
	float depth = texture(depthtex0, uv).r;

	if (depth >= 1.0 && scene.a <= 0.0) {
		EnvState env = getEnvState();
		vec3 dir = normalize(playerDirFromView(viewFromScreen(vec3(uv, 1.0))));
		scene = vec4(skyRadiance(dir, env), 1.0);
	}

	outColor = scene;
}

#endif
