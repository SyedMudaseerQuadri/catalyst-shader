// Catalyst — analytic sky radiance (M1/M2 foundation; replaced by a scattering model in M3).
//
// Model: zenith-to-horizon gradient + a horizon brightening band + a forward-scattering halo around
// the sun. Colors come from the shared EnvState: the sun's transmittance tints the horizon at low sun,
// so sunsets emerge from the same physics that color the sunlight. The biome's vanilla sky color is
// blended in by PRESET_SKY_DOME_VANILLA to keep Minecraft's per-biome identity (blue skies stay blue).
// Units: scene-linear radiance, same scale as lighting.
// Requires: settings.glsl, core/common.glsl, environment/state.glsl.

#if !defined CATALYST_SKY
#define CATALYST_SKY

// Henyey-Greenstein phase function (normalized over the sphere).
float henyeyGreenstein(float cosTheta, float g) {
	float g2 = g * g;
	return (1.0 - g2) / (4.0 * PI * pow(max(1.0 + g2 - 2.0 * g * cosTheta, 1e-4), 1.5));
}

vec3 skyRadiance(vec3 dir, EnvState env) {
#if defined DIM_NETHER
	return vanillaFogLinear() * 0.6;
#elif defined DIM_END
	return vec3(0.030, 0.020, 0.045);
#else
	float up = dir.y;
	float aboveHorizon = max(up, 0.0);

	// Normalized sun tint (hue only): orange/red at low sun, near-white at high sun.
	vec3 sunTint = env.sunRadiance / max(max(env.sunRadiance.r, max(env.sunRadiance.g, env.sunRadiance.b)), 1e-4);

	// Daytime gradient, blended with the biome's vanilla sky color for identity.
	vec3 zenithDay  = mix(vec3(0.16, 0.32, 0.80), vanillaSkyLinear(), PRESET_SKY_DOME_VANILLA);
	vec3 horizonDay = mix(vec3(0.60, 0.72, 0.92), vanillaSkyLinear() * 1.4 + 0.15, PRESET_SKY_DOME_VANILLA);

	float horizonBand = exp(-aboveHorizon * 5.0);
	// The clear sky brightens as the sun climbs (same scale as the sky ambient light in state.glsl).
	vec3 daySky = mix(zenithDay, horizonDay, horizonBand) * 1.9 * daylightSkyScale(env.sunElevation);

	// Low sun: warm the horizon on the sun's side, cool the anti-solar side.
	float towardSun = saturate(dot(normalize(vec3(dir.x, 0.0, dir.z) + 1e-5), normalize(vec3(env.sunDir.x, 0.0, env.sunDir.z) + 1e-5)) * 0.5 + 0.5);
	vec3 twilightHorizon = mix(vec3(0.25, 0.22, 0.35), sunTint * vec3(1.0, 0.75, 0.55), towardSun) * 0.9;
	vec3 twilightSky = mix(zenithDay * 0.35, twilightHorizon, horizonBand);

	vec3 nightSky = mix(vec3(0.004, 0.007, 0.016), vec3(0.010, 0.014, 0.024), horizonBand) * NIGHT_VISIBILITY;

	vec3 sky = mix(nightSky, daySky, env.day);
	sky = mix(sky, twilightSky, env.twilight * (1.0 - env.night) * 0.85);

	// Forward scattering around the sun (aerosols) — halo brightness follows the actual sunlight.
	float cosSun = dot(dir, env.sunDir);
	sky += env.sunRadiance * henyeyGreenstein(cosSun, 0.76) * 0.20;

	// Faint moon halo at night.
	sky += env.moonRadiance * henyeyGreenstein(dot(dir, env.moonDir), 0.80) * 0.5;

	// Overcast: sky flattens toward grey; storms darken it.
	float greyLevel = luminance(sky) * 0.9 + 0.02 * env.day;
	sky = mix(sky, vec3(greyLevel), env.overcast * 0.85) * (1.0 - 0.45 * env.storm);

	// Below the horizon fade to a dim ground-bounce color so the lower hemisphere is never pure black.
	float belowHorizon = saturate(-up * 4.0);
	sky = mix(sky, horizonDay * 0.25 * env.day + nightSky, belowHorizon);

	return sky;
#endif
}

#endif
