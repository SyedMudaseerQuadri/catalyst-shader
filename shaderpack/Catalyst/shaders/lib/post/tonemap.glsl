// Catalyst — exposure, tonemapping and grading (final pass only).
//
// Exposure (M1/M2): model-based rather than measured. Two parts: the overall daylight level (open-ground
// irradiance from the shared environment) is mostly normalized, while the local difference between open sky
// and the eye's surroundings (Iris's smoothed eye brightness) is adapted only slightly (EXPOSURE_ADAPTATION). It is stable and costs nothing. A measured histogram exposure replaces it in M5.
//
// Tonemap: per channel, linear up to a knee then an exponential shoulder, applied after a log-space contrast
// adjustment around mid grey. Per-channel mapping gives a natural highlight desaturation.
// Requires: settings.glsl, core/common.glsl, environment/state.glsl.

#if !defined CATALYST_TONEMAP
#define CATALYST_TONEMAP

const float CONTRAST_PIVOT = 0.18;   // mid grey for the contrast curve
// Display values below the knee pass through linearly; above it an exponential shoulder rolls off to 1.
// A plain Reinhard curve darkened every mid-tone (EV-005: a white block in sun showed 0.37 vs vanilla 0.72).
const float TONEMAP_KNEE = 0.55;
// Exposure numerator and the noon open-ground irradiance it is anchored to (tools/tone_sim.py, EV-005).
const float EXPOSURE_TARGET = 0.95;
const float DAY_REFERENCE_IRRADIANCE = 3.10;
// How strongly exposure follows the overall daylight level (morning vs noon vs night). Day is almost fully
// normalized, like the eye; night keeps part of its darkness.
const float DAYLIGHT_ADAPTATION_DAY = 0.85;
const float DAYLIGHT_ADAPTATION_NIGHT = 0.55;

// Irradiance on open, up-facing ground right now: the scene brightness outdoors.
float openGroundIrradiance(EnvState env) {
	float floorPart = max(PRESET_MIN_AMBIENT, READABILITY_MIN_AMBIENT) * 0.8;
	return luminance(env.lightRadiance) * max(env.lightDir.y, 0.0) + luminance(env.skyAmbient) + floorPart;
}

// Irradiance where the eye is, from Iris's smoothed eye sky/block light.
float eyeIrradiance(EnvState env, float openGround) {
	float floorPart = max(PRESET_MIN_AMBIENT, READABILITY_MIN_AMBIENT) * 0.8;
	float skyPart = (openGround - floorPart) * sqr(env.eyeSky);
	float blockPart = luminance(env.blockLightColor) * 0.30 * sqr(env.eyeBlock);
	return max(skyPart + blockPart + floorPart, 1e-4);
}

float computeExposure(EnvState env) {
	// 1) Daylight normalization: morning and noon read similarly bright, night stays darker.
	float openGround = openGroundIrradiance(env);
	float a = mix(DAYLIGHT_ADAPTATION_NIGHT, DAYLIGHT_ADAPTATION_DAY, env.day);
	float adaptedDaylight = pow(DAY_REFERENCE_IRRADIANCE, 1.0 - a) * pow(openGround, a);
	// 2) Local adaptation (aesthetic_direction.md: "very subtle by default"): interiors and caves are lifted
	// only slightly, so they keep their natural darkness.
	float local = pow(openGround / eyeIrradiance(env, openGround), EXPOSURE_ADAPTATION);
	float exposure = clamp(EXPOSURE_TARGET / adaptedDaylight * local, 0.05, 6.0);
	return exposure * exp2(EXPOSURE_BIAS + PRESET_EXPOSURE_BIAS);
}

vec3 applyContrast(vec3 c, float contrast) {
	// Power around mid grey = linear contrast in log2 space.
	return CONTRAST_PIVOT * pow(max(c, 0.0) / CONTRAST_PIVOT, vec3(contrast));
}

vec3 applySaturation(vec3 c, float saturation) {
	return max(mix(vec3(luminance(c)), c, saturation), 0.0);
}

// Per channel: linear below the knee, exponential shoulder above (C1-continuous, approaches 1).
vec3 tonemapShoulder(vec3 c) {
	const float k = TONEMAP_KNEE;
	vec3 shoulder = k + (1.0 - k) * (1.0 - exp(-(c - k) / (1.0 - k)));
	return mix(c, shoulder, step(vec3(k), c));
}

// Scene-linear HDR in, display-linear [0,1] out.
vec3 toneAndGrade(vec3 hdr, float exposure) {
	vec3 c = hdr * exposure;
	c = applyContrast(c, PRESET_CONTRAST * CONTRAST);
	c = applySaturation(c, PRESET_SATURATION * SATURATION);
	return saturate(tonemapShoulder(c));
}

#endif
