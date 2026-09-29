// Catalyst — surface lighting model (docs/architecture/catalyst_architecture.md, "Light transport model").
//
// Radiance leaving a diffuse surface = albedo * (direct + indirect) + emission, where
//   direct   = sun/moon radiance * cosine * shadow visibility              (Lambert; energy-conserving)
//   indirect = sky ambient (hemispheric) + block light + readability floor (scaled by vanilla AO)
// Approximations (documented per the architecture rules):
//   * Sky ambient uses vanilla sky light as an occlusion term. It over-lights narrow overhangs
//     compared to real GI; screen-space GI (M5) will refine it.
//   * Block light is Minecraft's per-block light level turned into a falloff curve, not a physical light.
//     No direction and no shadows; accepted for M1/M2.
//   * Thin surfaces (foliage/leaves) use wrapped diffuse for transmission. Cheap and stable, not subsurface transport.
// Requires: settings.glsl, core/common.glsl, environment/state.glsl, material/classify.glsl.

#if !defined CATALYST_LIGHTING_FORWARD
#define CATALYST_LIGHTING_FORWARD

// Perceptual falloff for Minecraft's linear 0..15 block light levels. Steeper than linear so light
// pools read as pools, with a small lift so level 1-3 stays distinguishable from darkness.
float blockLightFalloff(float level01) {
	return pow(level01, 2.6) + 0.02 * level01;
}

// Sky light arriving through the local opening; vanilla sky level already encodes how "open" the spot is.
float skyLightFalloff(float level01) {
	return level01 * level01;
}

// Direct light mask: shadow maps only cover the area near the player and do not know about caves
// beyond their range, so direct light is also gated by vanilla sky light (no sunlight deep underground).
float directSkyAccess(float skyLevel) {
	return smoothstep(0.05, 0.35, skyLevel);
}

vec3 shadeSurface(Surface s, EnvState env, float shadowVisibility) {
	float NdotL = dot(s.normal, env.lightDir);

	float diffuse = max(NdotL, 0.0);
	if (s.transmission > 0.0) {
		// Wrapped diffuse: thin surfaces also receive light from behind.
		float wrapped = saturate((abs(NdotL) + 0.35) / 1.35);
		diffuse = mix(diffuse, wrapped, s.transmission);
	}
	vec3 direct = env.lightRadiance * diffuse * shadowVisibility * directSkyAccess(s.light.y);

	// Hemispheric sky: surfaces facing up see more sky than walls; walls see some ground bounce.
	float upFacing = s.normal.y * 0.5 + 0.5;
	float skyVisibility = mix(0.45, 1.0, upFacing);
	vec3 sky = env.skyAmbient * skyVisibility * skyLightFalloff(s.light.y);

#if defined DIM_NETHER || defined DIM_END
	// No sky light in these dimensions: their ambient is a dimension-wide constant.
	sky = env.skyAmbient * skyVisibility;
#endif

	vec3 block = env.blockLightColor * blockLightFalloff(s.light.x);

	float floorLevel = max(PRESET_MIN_AMBIENT * NIGHT_VISIBILITY, READABILITY_MIN_AMBIENT);
	vec3 readabilityFloor = vec3(floorLevel) * vec3(0.85, 0.92, 1.0);

	vec3 indirect = (sky * PRESET_SHADOW_AMBIENT + block + readabilityFloor) * s.ao;

	// Night vision (vanilla effect) lifts all indirect light.
	indirect += nightVision * 0.25 * s.ao;

	vec3 emitted = s.albedo * s.emission * 4.0 * EMISSIVE_INTENSITY;

	return s.albedo * (direct + indirect) + emitted;
}

#endif
