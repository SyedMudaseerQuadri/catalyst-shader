// Catalyst — distance fog / aerial perspective and medium fog (water, lava, powder snow).
//
// Aerial perspective: Beer-Lambert extinction exp(-density * distance), in-scattered color = sky radiance
// toward a flattened view direction. Density decays with altitude (thinner air above sea level) and
// rises with rain. A border term blends to sky at the render-distance edge so chunk loading is hidden.
// Requires: settings.glsl, core/common.glsl, core/uniforms.glsl, environment/state.glsl, atmosphere/sky.glsl.

#if !defined CATALYST_FOG
#define CATALYST_FOG

const float SEA_LEVEL = 63.0;

// Returns the fogged color. `playerPos` is the surface position, `isSky` skips distance fog for the sky itself.
vec3 applyAtmosphericFog(vec3 color, vec3 playerPos, bool isSky, EnvState env) {
	float dist = length(playerPos);
	vec3 viewDir = playerPos / max(dist, 1e-4);

	// Medium the eye is in (vanilla isEyeInWater: 1 water, 2 lava, 3 powder snow).
	if (isEyeInWater == 1) {
		// Absorption tinted like clear green-blue water; light level follows sky exposure at the eye.
		vec3 absorb = vec3(0.30, 0.08, 0.05);
		vec3 transmittance = exp(-absorb * dist * 0.5);
		vec3 waterScatter = vec3(0.02, 0.09, 0.12) * (luminance(env.skyAmbient + env.lightRadiance * 0.2) * 1.5 + 0.02) * (0.3 + 0.7 * env.eyeSky);
		return color * transmittance + waterScatter * (1.0 - transmittance);
	}
	if (isEyeInWater == 2) {
		float t = 1.0 - exp(-dist * 1.2);
		return mix(color, vec3(1.8, 0.45, 0.05), t);
	}
	if (isEyeInWater == 3) {
		float t = 1.0 - exp(-dist * 0.9);
		return mix(color, vec3(0.55, 0.62, 0.72) * (luminance(env.skyAmbient) + 0.1), t);
	}

	vec3 fogDir = normalize(vec3(viewDir.x, max(viewDir.y, 0.0) * 0.5 + 0.02, viewDir.z));
	vec3 fogColor = skyRadiance(fogDir, env);

	float fogAmount = 0.0;
	if (!isSky) {
#if defined DIM_NETHER
		float density = 0.012;
#elif defined DIM_END
		float density = 0.004;
#else
		float worldHeight = playerPos.y * 0.5 + cameraPosition.y; // midpoint of the ray, cheap estimate
		float heightFactor = exp(-max(worldHeight - SEA_LEVEL, 0.0) / 60.0);
		float density = 0.0011 * heightFactor * (1.0 + 4.0 * env.rain + 2.0 * env.storm);
#endif
		density *= PRESET_FOG_DENSITY * FOG_DENSITY;
		fogAmount = 1.0 - exp(-density * dist);

		// Border fog: hide the render-distance edge.
		float border = smoothstep(far * 0.75, far, length(playerPos.xz));
		fogAmount = max(fogAmount, border);
	}

	// Vanilla blindness / darkness effects: short dark fog (gameplay behavior preserved).
	float effect = max(blindness, darknessFactor);
	if (effect > 0.0) {
		float t = (1.0 - exp(-dist * 0.35)) * effect;
		return mix(mix(color, fogColor, fogAmount), vec3(0.0), t);
	}

	return mix(color, fogColor, fogAmount);
}

#endif
