// Catalyst — volumetric sunlight in air (M5, D-016).
//
// Sunlight scattered toward the eye by the same air density the distance fog uses (haze, rain haze, valley mist),
// marched through the shadow map: where trees or terrain shade the air the scattering stops, producing shafts
// ("god rays") through foliage, gaps and doorways. The distance fog already adds the sky-colored in-scatter;
// this adds only the sun's directional part (forward-scattering phase), scaled by the visual preset.
// Range is limited to the shadow-mapped area (beyond it there is no shadow information).
// Requires: shadow/shadows.glsl (SHADOW_RECEIVER), atmosphere/fog.glsl, atmosphere/clouds.glsl, environment/state.glsl.

#if !defined CATALYST_VOLUMETRIC
#define CATALYST_VOLUMETRIC

#if defined SHADOW_RECEIVER

#if INTERNAL_TIER == TIER_LOW
	const int VOLUMETRIC_STEPS = 6;
#elif INTERNAL_TIER == TIER_MEDIUM
	const int VOLUMETRIC_STEPS = 8;
#elif INTERNAL_TIER == TIER_HIGH
	const int VOLUMETRIC_STEPS = 12;
#elif INTERNAL_TIER == TIER_ULTRA
	const int VOLUMETRIC_STEPS = 16;
#else
	const int VOLUMETRIC_STEPS = 24;
#endif

vec3 volumetricSunlight(vec3 playerPos, bool isSky, EnvState env, float dither) {
	if (env.lightRadiance.r + env.lightRadiance.g + env.lightRadiance.b <= 0.0) return vec3(0.0);
	float range = min(shadowDistance * 0.9, 128.0);
	float dist = isSky ? range : min(length(playerPos), range);
	vec3 dir = normalize(playerPos);
	float stepLength = dist / float(VOLUMETRIC_STEPS);

	float scattered = 0.0;
	float transmittance = 1.0;
	for (int i = 0; i < VOLUMETRIC_STEPS; i++) {
		float t = (float(i) + dither) * stepLength;
		vec3 p = dir * t;
		float density = overworldAirDensity(p.y + cameraPosition.y, env);
		float fade;
		vec3 coord = shadowCoordinate(p, vec3(0.0), 1.0, fade);
		float visible = 1.0;
		if (all(greaterThanEqual(coord, vec3(0.0))) && all(lessThanEqual(coord, vec3(1.0)))) {
			visible = mix(texture(shadowtex1, coord), 1.0, fade);
		}
		scattered += visible * density * transmittance * stepLength;
		transmittance *= exp(-density * stepLength);
	}

	// Forward-scattering phase (Henyey-Greenstein g = 0.5, relative to isotropic), partly isotropic for mist.
	float cosTheta = dot(dir, env.lightDir);
	float phase = mix(0.75 / pow(1.25 - cosTheta, 1.5), 1.0, 0.4);
	return env.lightRadiance * cloudShadow(vec3(0.0), env) * scattered * phase * PRESET_VOLUMETRIC * VOLUMETRIC_STRENGTH;
}

#endif
#endif
