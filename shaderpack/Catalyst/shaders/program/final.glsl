// Catalyst — final pass: exposure, tonemap, grading, display encoding, debug views.

#include "/lib/settings.glsl"
#include "/lib/core/common.glsl"
#include "/lib/core/uniforms.glsl"
#include "/lib/core/space.glsl"
#include "/lib/core/encode.glsl"
#include "/lib/core/buffers.glsl"
#include "/lib/material/classify.glsl"

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
#include "/lib/post/tonemap.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D depthtex0;

in vec2 uv;

layout(location = 0) out vec4 outColor;

// Distinct, readable colors for material classes in the debug view.
vec3 materialDebugColor(int materialClass) {
	if (materialClass == MAT_FOLIAGE) return vec3(0.35, 0.85, 0.25); // foliage
	if (materialClass == MAT_LEAVES) return vec3(0.10, 0.55, 0.15); // leaves
	if (materialClass == MAT_WATER) return vec3(0.15, 0.40, 0.95); // water
	if (materialClass == MAT_EMISSIVE) return vec3(1.00, 0.80, 0.20); // emissive
	if (materialClass == MAT_LAVA) return vec3(1.00, 0.30, 0.05); // lava
	if (materialClass >= MAT_ENTITY) return vec3(0.85, 0.30, 0.85); // entity / hand
	return vec3(0.50);                                     // default
}

vec3 debugView(vec3 displayColor) {
#if DEBUG_VIEW == 0
	return displayColor;
#else
	vec4 normalLight = texture(colortex1, uv);
	vec4 albedo = texture(colortex2, uv);
	vec4 material = texture(colortex3, uv);
	bool hasData = normalLight.a > 0.5;
	#if DEBUG_VIEW == 1
		return hasData ? albedo.rgb : vec3(0.0);
	#elif DEBUG_VIEW == 2
		return hasData ? decodeNormal(normalLight.rg) * 0.5 + 0.5 : vec3(0.0);
	#elif DEBUG_VIEW == 3
		vec2 lm = unpackLightmap(normalLight.b);
		return hasData ? vec3(lm.x, lm.y, 0.0) : vec3(0.0); // red = block light, green = sky light
	#elif DEBUG_VIEW == 4
		return hasData ? materialDebugColor(int(material.r * 255.0 + 0.5)) : vec3(0.0);
	#elif DEBUG_VIEW == 5
		return vec3(saturate(linearizeDepth(texture(depthtex0, uv).r) / far));
	#else
		return hasData ? vec3(material.g) : vec3(1.0);
	#endif
#endif
}

void main() {
	vec3 hdr = texture(colortex0, uv).rgb;

	EnvState env = getEnvState();
	vec3 display = toneAndGrade(hdr, computeExposure(env));
	vec3 encoded = linearToSrgb(display);

	// Sub-LSB dither removes banding in dark gradients (sky, fog) on 8-bit outputs.
	encoded += (interleavedGradientNoise(gl_FragCoord.xy) - 0.5) / 255.0;

	outColor = vec4(debugView(encoded), 1.0);
}

#endif
