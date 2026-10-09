// Catalyst — shared environmental state (docs/architecture/environment_state.md, decision D-003).
//
// Every subsystem that reacts to time, weather or dimension reads it from EnvState instead of
// deriving its own copy. Inputs are Iris uniforms; transitions stay progressive because the inputs
// themselves are smoothed (rainStrength, wetness, thunderStrength, eyeBrightnessSmooth).
//
// Input classification for the pinned target (Minecraft 1.21.11 / Iris 1.10.7):
//   time of day, sun/moon angle, rain, thunder, wetness, dimension (compile-time), eye light: VERIFIED uniforms
//   cloud coverage: DERIVABLE (from rain/thunder)      wind: APPROXIMATED later (M3)
//   biome: UNAVAILABLE as a direct input here (vanilla skyColor/fogColor carry biome tint)
//   season: UNAVAILABLE in vanilla
//
// Units: scene-linear relative radiance (see lib/core/common.glsl). Directions are player space, unit length.
// Requires: settings.glsl, core/common.glsl, core/uniforms.glsl.

#if !defined CATALYST_ENV_STATE
#define CATALYST_ENV_STATE

struct EnvState {
	vec3 sunDir;          // toward the sun
	vec3 moonDir;
	vec3 lightDir;        // toward the current shadow caster (sun by day, moon by night)
	float sunElevation;   // sin(altitude) of the sun, -1..1
	float day;            // 0..1, full day weight
	float night;          // 0..1, full night weight
	float twilight;       // 0..1, peaks with the sun near the horizon
	float rain;           // 0..1
	float storm;          // 0..1 thunder
	float wetness;        // 0..1, lags rain (drying)
	float overcast;       // 0..1 derived cloud cover
	float eyeSky;         // 0..1 smoothed sky light at the eye
	float eyeBlock;       // 0..1 smoothed block light at the eye
	vec3 sunRadiance;     // direct sunlight after atmospheric transmittance
	vec3 moonRadiance;
	vec3 lightRadiance;   // direct radiance for lightDir, weather-attenuated
	vec3 skyAmbient;      // hemispheric sky irradiance (upward-facing, unoccluded)
	vec3 blockLightColor; // full-strength torch-like block light
};

// Relative optical airmass for a solar elevation (Kasten & Young 1989 approximation), capped at the horizon.
float opticalAirmass(float sinElevation) {
	float altDeg = degrees(asin(clamp(sinElevation, -1.0, 1.0)));
	float h = max(altDeg, 0.0);
	float m = 1.0 / (sin(radians(h)) + 0.50572 * pow(h + 6.07995, -1.6364));
	return min(m, 38.0);
}

// Approximate atmospheric transmittance for direct light along a path of `airmass`.
// Zenith optical depths: Rayleigh at ~680/550/440 nm plus a grey aerosol term (preset / weather driven).
vec3 atmosphericTransmittance(float airmass, float aerosol) {
	const vec3 RAYLEIGH_ZENITH_DEPTH = vec3(0.045, 0.097, 0.235);
	return exp(-(RAYLEIGH_ZENITH_DEPTH + aerosol) * airmass);
}

// Noon sky-ambient luminance (noon sun luminance is ~2.5 in scene units: ~3.7:1 open ground sun-to-sky).
const float SKY_AMBIENT_NOON = 0.70;
// Fraction of the biome sky color's saturation that tints ambient light (raw vanilla sky is very saturated).
const float SKY_TINT_SATURATION = 0.25;

// The clear sky (both the visible dome and its irradiance) is dimmer when the sun is low; used by sky.glsl too.
float daylightSkyScale(float sunElevation) {
	return 0.40 + 0.60 * smoothstep(0.0, 0.85, sunElevation);
}

// Block light color for a 0..1 block-light level: warmer as it dims, closer to warm white at full strength
// (matches the observed vanilla behavior that dim torch light reads orange). Luminance stays that of
// env.blockLightColor, so only the hue depends on the level.
vec3 blockLightTint(vec3 fullColor, float level) {
	vec3 hue = mix(vec3(1.00, 0.52, 0.24), vec3(1.00, 0.80, 0.58), saturate(level));
	return hue / luminance(hue) * luminance(fullColor);
}

// Iris supplies the biome/weather vanilla colors in sRGB; bring them into the working space.
vec3 vanillaSkyLinear() { return srgbToLinear(clamp(skyColor, 0.0, 1.0)); }
vec3 vanillaFogLinear() { return srgbToLinear(clamp(fogColor, 0.0, 1.0)); }

EnvState getEnvState() {
	EnvState env;

	env.sunDir   = normalize(mat3(gbufferModelViewInverse) * sunPosition);
	env.moonDir  = normalize(mat3(gbufferModelViewInverse) * moonPosition);
	env.lightDir = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
	env.sunElevation = env.sunDir.y;

	env.rain    = rainStrength;
	env.storm   = thunderStrength;
	env.wetness = wetness;
	env.overcast = saturate(rainStrength * 0.85 + thunderStrength * 0.15);

	env.eyeSky   = float(eyeBrightnessSmooth.y) / 240.0;
	env.eyeBlock = float(eyeBrightnessSmooth.x) / 240.0;

	// Day/night weights: the transition spans roughly -6 deg (civil twilight) to +10 deg of solar altitude.
	env.day      = smoothstep(-0.10, 0.17, env.sunElevation);
	env.night    = 1.0 - smoothstep(-0.20, 0.00, env.sunElevation);
	env.twilight = saturate(1.0 - abs(env.sunElevation) * 4.0);

	// Warm, slightly soft block light (~2700 K incandescent-like tint).
	env.blockLightColor = vec3(1.00, 0.62, 0.32) * 1.30 * BLOCKLIGHT_INTENSITY;

#if defined DIM_NETHER
	env.sunRadiance = vec3(0.0);
	env.moonRadiance = vec3(0.0);
	env.lightRadiance = vec3(0.0);
	// The Nether has no sky light; its ambient comes from the dimension's fog tint.
	env.skyAmbient = mix(vec3(0.20, 0.09, 0.05), vanillaFogLinear() * 1.5, 0.5) * 0.35 * AMBIENT_INTENSITY;
	env.day = 0.0; env.night = 0.0; env.twilight = 0.0;
	env.rain = 0.0; env.storm = 0.0; env.wetness = 0.0; env.overcast = 0.0;
#elif defined DIM_END
	env.sunRadiance = vec3(0.0);
	env.moonRadiance = vec3(0.0);
	env.lightRadiance = vec3(0.0);
	env.skyAmbient = vec3(0.16, 0.12, 0.22) * 0.45 * AMBIENT_INTENSITY;
	env.day = 0.0; env.night = 0.0; env.twilight = 0.0;
	env.rain = 0.0; env.storm = 0.0; env.wetness = 0.0; env.overcast = 0.0;
#else
	float aerosol = PRESET_AEROSOL * (1.0 + 2.0 * env.rain);

	// Sun: transmittance-driven color gives warm low-sun light without a hand-painted sunset tint.
	float sunAbove = smoothstep(-0.05, 0.04, env.sunElevation);
	env.sunRadiance = atmosphericTransmittance(opticalAirmass(env.sunElevation), aerosol)
	                  * 3.0 * SUN_INTENSITY * sunAbove;

	// Moon: sunlight reflected by the moon, cool-shifted for the Purkinje-like night look; phase-scaled.
	// moonPhase 0 = full, 4 = new.
	float phaseLight = 1.0 - 0.75 * (1.0 - abs(float(moonPhase) - 4.0) / 4.0);
	float moonAbove = smoothstep(-0.05, 0.06, env.moonDir.y);
	env.moonRadiance = vec3(0.50, 0.62, 0.95) * 0.055 * phaseLight * moonAbove * NIGHT_VISIBILITY;

	// Weather attenuation of direct light (cloud cover blocks most of the direct beam).
	float directVisibility = 1.0 - 0.92 * env.overcast;
	bool sunIsCaster = dot(env.lightDir, env.sunDir) > 0.0;
	env.lightRadiance = (sunIsCaster ? env.sunRadiance : env.moonRadiance) * directVisibility;

	// Sky ambient: the irradiance from the whole sky hemisphere plus ground bounce is only mildly blue, so the
	// hue stays close to neutral; the biome's vanilla sky color adds a desaturated tint (Minecraft identity).
	// Level: ~3.7:1 open-ground sun-to-sky ratio at noon (a clear-day value), so shade is never artificially black.
	// Tuned with tools/tone_sim.py against the in-game screenshots (state/evidence/ingame_2026-10-09.md).
	vec3 biomeSky = vanillaSkyLinear() / max(luminance(vanillaSkyLinear()), 1e-4);
	biomeSky = 1.0 + (biomeSky - 1.0) * SKY_TINT_SATURATION;
	vec3 dayHue = mix(vec3(0.80, 0.90, 1.10), biomeSky, PRESET_VANILLA_SKY_BLEND);
	vec3 dayAmbient = dayHue / max(luminance(dayHue), 1e-4) * SKY_AMBIENT_NOON * daylightSkyScale(env.sunElevation);
	vec3 twilightAmbient = vec3(0.35, 0.28, 0.30) * 0.25;
	vec3 nightAmbient = vec3(0.10, 0.14, 0.26) * 0.10 * NIGHT_VISIBILITY;
	vec3 ambient = mix(nightAmbient, dayAmbient, env.day);
	ambient = mix(ambient, twilightAmbient, env.twilight * 0.5 * (1.0 - env.night));

	// Overcast: the sky becomes a brighter, grey, diffuse source while the sun beam fades.
	vec3 overcastAmbient = vec3(luminance(ambient)) * mix(1.0, 1.25, env.day);
	env.skyAmbient = mix(ambient, overcastAmbient, env.overcast * 0.8) * (1.0 - 0.35 * env.storm) * AMBIENT_INTENSITY;
#endif

	return env;
}

#endif
