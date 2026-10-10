// Catalyst — final pass: exposure, tonemap, grading, display encoding, debug views; water droplets on the view
// for a few seconds after surfacing (VIEW_DROPLETS).

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
#include "/lib/core/noise.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
#ifdef BLOOM
uniform sampler2D colortex7; // bloom (composite2)
#endif
uniform sampler2D depthtex0;

in vec2 uv;

layout(location = 0) out vec4 outColor;

#ifdef VIEW_DROPLETS
uniform float viewWetness; // shaders.properties: 1 in water, fades with a ~3 s half-life after surfacing

// Screen-space refraction offset of drops running down the view. Each cell of a coarse grid may hold one drop
// that slides down and fades; fewer drops remain as the view dries.
vec2 dropletOffset(vec2 screenUv) {
	if (viewWetness < 0.02 || isEyeInWater != 0) return vec2(0.0);
	float aspect = viewWidth / viewHeight;
	vec2 p = vec2(screenUv.x * aspect, screenUv.y) * 7.0;
	vec2 cell = floor(p);
	vec2 offset = vec2(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			ivec2 c = ivec2(cell) + ivec2(x, y);
			float seed = hash21(c);
			if (seed > viewWetness * 0.9) continue;
			float life = fract(frameTimeCounter * (0.10 + 0.15 * hash21(c + ivec2(7, 3))) + seed);
			vec2 center = vec2(c) + vec2(0.2 + 0.6 * hash21(c + ivec2(11, 5)), 1.0 - life * 1.2);
			float radius = 0.10 + 0.14 * hash21(c + ivec2(2, 9));
			vec2 d = (p - center) * vec2(1.0, 0.75); // slightly elongated along the run
			float r = length(d) / radius;
			if (r < 1.0) offset -= d / radius * (1.0 - r * r) * sin(life * PI);
		}
	}
	return offset * 0.010 * viewWetness;
}
#endif

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
	#elif DEBUG_VIEW == 6
		return hasData ? vec3(material.g) : vec3(1.0);
	#else
		return hasData ? vec3(material.b) : vec3(0.0); // smoothness; black = no specular data
	#endif
#endif
}

void main() {
	vec2 sampleUv = uv;
#ifdef VIEW_DROPLETS
	sampleUv = clamp(uv + dropletOffset(uv), vec2(0.0), vec2(1.0));
#endif
	vec3 hdr = texture(colortex0, sampleUv).rgb;
#ifdef BLOOM
	// Energy-conserving mix: a small, constant share of light spreads to its surroundings. It never lifts dark
	// scenes by itself (readability) and only becomes visible around genuinely bright sources.
	hdr = mix(hdr, texture(colortex7, sampleUv).rgb, saturate(PRESET_BLOOM * BLOOM_STRENGTH));
#endif

	EnvState env = getEnvState();
	vec3 display = toneAndGrade(hdr, computeExposure(env));
	vec3 encoded = linearToSrgb(display);

	// Sub-LSB dither removes banding in dark gradients (sky, fog) on 8-bit outputs.
	encoded += (interleavedGradientNoise(gl_FragCoord.xy) - 0.5) / 255.0;

	outColor = vec4(debugView(encoded), 1.0);
}

#endif
