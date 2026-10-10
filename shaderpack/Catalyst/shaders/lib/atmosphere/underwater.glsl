// Catalyst — underwater light shafts (M4, D-015).
//
// When the eye is in water, sunlight entering through the surface scatters toward the eye. A short march along the
// view ray reads, at each sample, whether the sun reaches it (shadowtex1: opaque casters) and how much water it
// crossed (shadowtex0 holds the water surface: depth difference in blocks), so shafts appear exactly where terrain
// lets light through and fade with depth. Added on top of the underwater fog in composite.
// Requires: shadow/shadows.glsl (SHADOW_RECEIVER), environment/water.glsl, environment/state.glsl, atmosphere/clouds.glsl.

#if !defined CATALYST_UNDERWATER
#define CATALYST_UNDERWATER

#if defined SHADOW_RECEIVER

#if INTERNAL_TIER == TIER_LOW
	const int SHAFT_STEPS = 8;
#elif INTERNAL_TIER == TIER_MEDIUM
	const int SHAFT_STEPS = 10;
#elif INTERNAL_TIER == TIER_HIGH
	const int SHAFT_STEPS = 14;
#else
	const int SHAFT_STEPS = 20;
#endif
const float SHAFT_MAX_DISTANCE = 40.0; // blocks
const float SHAFT_STRENGTH = 2.5;

vec3 underwaterShafts(vec3 playerPos, EnvState env, float dither) {
	float dist = min(length(playerPos), SHAFT_MAX_DISTANCE);
	if (dist <= 0.0 || env.lightDir.y <= 0.0) return vec3(0.0);
	vec3 dir = normalize(playerPos);
	WaterOptics o = waterOptics(VANILLA_WATER_COLOR);
	float stepLength = dist / float(SHAFT_STEPS);
	vec3 sum = vec3(0.0);
	for (int i = 0; i < SHAFT_STEPS; i++) {
		float t = (float(i) + dither) * stepLength;
		vec3 p = dir * t;
		float fade;
		vec3 coord = shadowCoordinate(p, vec3(0.0), 1.0, fade);
		if (any(lessThan(coord, vec3(0.0))) || any(greaterThan(coord, vec3(1.0)))) continue;
		float visible = texture(shadowtex1, coord);
		float surface = texture(shadowtex0, coord.xy).r;
		float waterAbove = surface < coord.z ? shadowDepthToBlocks(coord.z - surface) : 0.0;
		sum += visible * exp(-o.extinction * (waterAbove + t));
	}
	float phase = (1.0 - 0.36) / pow(1.0 + 0.36 - 1.2 * dot(dir, env.lightDir), 1.5); // HG g = 0.6, rel. isotropic
	return env.lightRadiance * cloudShadow(vec3(0.0), env) * sum * stepLength * o.scattering * phase * SHAFT_STRENGTH;
}

#endif
#endif
