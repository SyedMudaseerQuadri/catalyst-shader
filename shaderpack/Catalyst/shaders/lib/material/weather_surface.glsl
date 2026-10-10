// Catalyst — weather response of surfaces: rain wetness, puddles and snow cover (M3, D-014).
//
// Exposure to precipitation = vanilla sky light (only blocks open to the sky get rained/snowed on; shelters stay dry).
// Wetness (aesthetic direction, "Material wetness"): porous materials darken and saturate (water fills pores and
// lowers the albedo), smooth materials gain a reflective water film. Porosity comes from LabPBR (_s blue 0..64)
// when the resource pack provides it, otherwise from a per-class default. Puddles form on flat, exposed ground as
// wetness rises (the noise threshold falls with wetness: damp -> wet -> puddles), so the stages are progressive.
// Snow settles on upward faces with irregular coverage (lighter on plants), keeps a moderate albedo (never a
// glowing field), and melts slowly because weatherSnowCover fades slowly (shaders.properties).
// Requires: core/common.glsl, core/noise.glsl, material/classify.glsl, environment/state.glsl, environment/water.glsl.

#if !defined CATALYST_WEATHER_SURFACE
#define CATALYST_WEATHER_SURFACE

const vec3 SNOW_ALBEDO = vec3(0.72, 0.75, 0.80); // linear; fresh snow ~0.8-0.9 in reality, kept lower for readability
const float WATER_FILM_F0 = 0.02;

// How much precipitation reaches this surface: needs open sky above.
float precipitationExposure(float skyLight) {
	return smoothstep(0.80, 0.95, skyLight);
}

float defaultPorosity(int materialClass) {
	if (materialClass == MAT_FOLIAGE || materialClass == MAT_LEAVES) return 0.15; // waxy: wet highlights, little darkening
	return 0.45; // generic block: between stone (low) and dirt/sand (high)
}

// Puddle mask 0..1 for an exposed, flat surface at world XZ.
float puddleMask(vec2 worldXZ, float wetness) {
	float n = fbm2(worldXZ * 0.11, 3);
	float threshold = 1.02 - 0.42 * wetness; // no puddles until wetness ~0.4, spreading as it rises
	return smoothstep(threshold, threshold + 0.07, n);
}

// Returns the puddle amount (0..1) so callers can add rain ripples to it (M4).
float applyWeatherToSurface(inout Surface s, vec3 worldPos, EnvState env) {
	if (s.materialClass == MAT_LAVA || s.materialClass == MAT_EMISSIVE || s.materialClass == MAT_WATER) return 0.0;
	float exposure = precipitationExposure(s.light.y);
	if (exposure <= 0.0) return 0.0;
	float up = s.geoNormal.y;
	bool thin = s.materialClass == MAT_FOLIAGE || s.materialClass == MAT_LEAVES;

	// ---- Snow cover
	if (env.snowCover > 0.0) {
		float variation = valueNoise2(worldPos.xz * 0.7) * 0.6 + valueNoise2(worldPos.xz * 3.1) * 0.4;
		float amount = env.snowCover * exposure * smoothstep(0.30, 0.85, up) * (thin ? 0.55 : 1.0);
		float coverage = smoothstep(0.20, 0.65, amount + (variation - 0.5) * 0.6 * (1.0 - amount));
		if (coverage > 0.0) {
			s.albedo = mix(s.albedo, SNOW_ALBEDO, coverage);
			s.roughness = mix(s.roughness, 0.55, coverage);
			s.f0 = mix(s.f0, vec3(0.02), coverage);
			s.metalness *= 1.0 - coverage;
			s.normal = normalize(mix(s.normal, s.geoNormal, coverage));
			s.emission *= 1.0 - coverage;
		}
	}

	// ---- Rain wetness and puddles
	if (env.surfaceWet <= 0.0) return 0.0;
	float porosity = s.porosity >= 0.0 ? s.porosity : defaultPorosity(s.materialClass);
	if (s.metalness > 0.5) porosity = 0.0;
	// Walls catch less rain than floors and roofs.
	float wet = env.surfaceWet * exposure * mix(0.55, 1.0, saturate(up));

	float puddle = 0.0;
	if (up > 0.95 && !thin && s.materialClass < MAT_ENTITY) {
		puddle = puddleMask(worldPos.xz, env.surfaceWet) * exposure;
	}

	// Porous darkening: water raises saturation and lowers albedo (the exponent keeps hue, deepens color).
	float darken = wet * porosity;
	s.albedo = pow(max(s.albedo, 0.0), vec3(1.0 + 1.2 * darken)) * (1.0 - 0.25 * darken);
	// Water film: smooths less-porous surfaces; puddles are standing water (mirror-smooth, flat).
	float film = wet * (1.0 - 0.6 * porosity);
	s.roughness = mix(s.roughness, 0.08, film);
	s.f0 = max(s.f0, vec3(WATER_FILM_F0 * saturate(film * 1.5)));
	if (puddle > 0.0) {
		s.albedo *= 1.0 - 0.35 * puddle;
		s.roughness = mix(s.roughness, 0.015, puddle);
		s.f0 = max(s.f0, vec3(WATER_FILM_F0 * puddle));
		// Standing water: flat, with rain ripples while it rains.
		vec2 ripple = rainRippleGradient(worldPos.xz, frameTimeCounter, rainStrength * exposure);
		s.normal = normalize(mix(s.normal, normalize(vec3(-ripple.x, 1.0, -ripple.y)), puddle));
	}
	return puddle;
}

#endif
