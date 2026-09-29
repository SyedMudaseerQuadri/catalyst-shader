// Catalyst — exposure, tonemapping and grading (final pass only).
//
// Exposure (M1/M2): model-based rather than measured. It estimates scene luminance from the shared
// environment (sun/sky/block light at the eye, via Iris's smoothed eye brightness) and scales it to a
// mid-grey key. It is stable and costs nothing. A measured histogram exposure replaces it in M5.
//
// Tonemap: extended Reinhard per channel with a white point, applied after a log-space contrast
// adjustment around mid grey. Per-channel mapping gives a natural highlight desaturation.
// Requires: settings.glsl, core/common.glsl, environment/state.glsl.

#if !defined CATALYST_TONEMAP
#define CATALYST_TONEMAP

const float EXPOSURE_KEY = 0.18;    // target mid grey
const float TONEMAP_WHITE = 6.0;    // scene value that maps to display white

float estimateSceneLuminance(EnvState env) {
	float sunlit = luminance(env.lightRadiance) * 0.20 + luminance(env.skyAmbient);
	float skyPart = sunlit * sqr(env.eyeSky);
	float blockPart = luminance(env.blockLightColor) * 0.30 * sqr(env.eyeBlock);
	float floorPart = max(PRESET_MIN_AMBIENT, READABILITY_MIN_AMBIENT) * 0.8;
	return max(skyPart + blockPart + floorPart, 1e-4);
}

float computeExposure(EnvState env) {
	float exposure = EXPOSURE_KEY / estimateSceneLuminance(env);
	// Limits keep night dark-but-readable and noon from being crushed.
	exposure = clamp(exposure, 0.35, 5.0);
	return exposure * exp2(EXPOSURE_BIAS + PRESET_EXPOSURE_BIAS);
}

vec3 applyContrast(vec3 c, float contrast) {
	// Power around mid grey = linear contrast in log2 space.
	return EXPOSURE_KEY * pow(max(c, 0.0) / EXPOSURE_KEY, vec3(contrast));
}

vec3 applySaturation(vec3 c, float saturation) {
	return max(mix(vec3(luminance(c)), c, saturation), 0.0);
}

vec3 tonemapReinhardExtended(vec3 c) {
	const float W2 = TONEMAP_WHITE * TONEMAP_WHITE;
	return c * (1.0 + c / W2) / (1.0 + c);
}

// Scene-linear HDR in, display-linear [0,1] out.
vec3 toneAndGrade(vec3 hdr, float exposure) {
	vec3 c = hdr * exposure;
	c = applyContrast(c, PRESET_CONTRAST * CONTRAST);
	c = applySaturation(c, PRESET_SATURATION * SATURATION);
	return saturate(tonemapReinhardExtended(c));
}

#endif
