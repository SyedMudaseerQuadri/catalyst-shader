// Catalyst — surface lighting model (docs/architecture/catalyst_architecture.md, "Light transport model").
//
// Radiance leaving a surface = diffuse + specular + emission, where
//   diffuse  = albedo * kd * (direct + indirect)        kd = (1 - Fresnel) * (1 - metalness)
//   direct   = sun/moon radiance * cosine * shadow       (Lambert; 1/pi folded into light units)
//   indirect = sky ambient (hemispheric) + block light + readability floor (scaled by AO)
//   specular = GGX sun/moon highlight + sky reflection (split-sum approximation), see specular.glsl
// Approximations (documented per the architecture rules):
//   * Sky ambient uses vanilla sky light as an occlusion term. It over-lights narrow overhangs
//     compared to real GI; screen-space GI (M5) will refine it. Interreflection inside occluded spaces
//     is approximated by an albedo-tinted multi-bounce fit (multiBounce), not traced.
//   * Block light is Minecraft's per-block light level turned into a falloff curve, not a physical light.
//     No direction, no shadows and no specular highlight; accepted for M1/M2.
//   * Thin surfaces (foliage/leaves) use wrapped diffuse for transmission. Cheap and stable, not subsurface transport.
//   * Sky reflection ignores occluders other than vanilla sky light (no SSR yet), and rough reflections
//     are approximated by bending the reflection toward the normal instead of prefiltering.
// Requires: settings.glsl, core/common.glsl, environment/state.glsl, material/classify.glsl,
//           lighting/specular.glsl, atmosphere/sky.glsl.

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

// Share of the multi-bounce term (0 = plain occlusion, 1 = full fit). Stands in for GI until M5.
const float BOUNCE_STRENGTH = 0.55;

// Multi-bounce occlusion fit (Jimenez et al. 2016, "Practical Real-Time Strategies for Accurate Indirect
// Occlusion"): occluded light is partly bounced back by nearby surfaces of similar albedo, so occlusion
// darkens less and keeps the surface's own color. Without it, enclosed spaces lit only by blue sky light
// turn grey (the 0.2.0-m2a in-game failure).
vec3 multiBounce(float visibility, vec3 albedo) {
	vec3 a =  2.0404 * albedo - 0.3324;
	vec3 b = -4.7951 * albedo + 0.6417;
	vec3 c =  2.7552 * albedo + 0.6903;
	vec3 fit = max(vec3(visibility), ((visibility * a + b) * visibility + c) * visibility);
	return mix(vec3(visibility), fit, BOUNCE_STRENGTH);
}

// `viewDir`: unit vector from the eye toward the surface, player space.
vec3 shadeSurface(Surface s, EnvState env, float shadowVisibility, vec3 viewDir) {
	vec3 v = -viewDir;
	float NdotL = dot(s.normal, env.lightDir);
	float NdotV = max(dot(s.normal, v), 1e-4);
	bool hasSpecular = max(s.f0.r, max(s.f0.g, s.f0.b)) > 0.0;

	// A normal map can tilt the shading normal toward the light on a face that points away from it;
	// the geometry itself still blocks the light (unless the surface transmits).
	float geometricFacing = smoothstep(-0.05, 0.05, dot(s.geoNormal, env.lightDir));
	float lightAccess = shadowVisibility * directSkyAccess(s.light.y);

	float diffuse = max(NdotL, 0.0) * geometricFacing;
	if (s.transmission > 0.0) {
		// Wrapped diffuse: thin surfaces also receive light from behind.
		float wrapped = saturate((abs(NdotL) + 0.35) / 1.35);
		diffuse = mix(diffuse, wrapped, s.transmission);
	}
	vec3 direct = env.lightRadiance * diffuse * lightAccess;

	// Hemispheric sky: surfaces facing up see more sky than walls; walls see some ground bounce.
	float upFacing = s.normal.y * 0.5 + 0.5;
	float skyVisibility = mix(0.45, 1.0, upFacing);
	vec3 aoBounce = multiBounce(s.ao, s.albedo);
#if defined DIM_NETHER || defined DIM_END
	// No sky light in these dimensions: their ambient is a dimension-wide constant.
	vec3 sky = env.skyAmbient * skyVisibility * aoBounce;
#else
	// Sky access (vanilla sky light) and vanilla AO together form the occlusion of the sky term.
	vec3 sky = env.skyAmbient * skyVisibility * multiBounce(skyLightFalloff(s.light.y) * s.ao, s.albedo);
#endif

	vec3 block = env.blockLightColor * blockLightFalloff(s.light.x);

	// Readability floor: near-neutral (slightly warm) so it never cools or greys out surfaces.
	float floorLevel = max(PRESET_MIN_AMBIENT * NIGHT_VISIBILITY, READABILITY_MIN_AMBIENT);
	vec3 readabilityFloor = vec3(floorLevel) * vec3(1.0, 0.97, 0.92);

	vec3 indirect = sky * PRESET_SHADOW_AMBIENT + (block + readabilityFloor) * aoBounce;

	// Night vision (vanilla effect) lifts all indirect light.
	indirect += nightVision * 0.25 * aoBounce;

	vec3 emitted = s.albedo * s.emission * 4.0 * EMISSIVE_INTENSITY;

	if (!hasSpecular) {
		return s.albedo * (direct + indirect) + emitted;
	}

	// ---- Specular (only for surfaces with material data) ----
	vec3 fresnelView = fresnelSchlick(NdotV, s.f0);
	vec3 kd = (1.0 - fresnelView) * (1.0 - s.metalness);
	vec3 color = s.albedo * kd * (direct + indirect) + emitted;

	float alpha = max(s.roughness, MIN_ROUGHNESS);
	color += env.lightRadiance * directSpecular(s.normal, v, env.lightDir, alpha, s.f0)
	         * lightAccess * geometricFacing * SPECULAR_INTENSITY;

#if defined DIM_OVERWORLD
	// Sky reflection: bend the mirror direction toward the normal as roughness grows (cheap prefilter stand-in),
	// keep it above the horizon of the surface, and occlude it with vanilla sky light.
	vec3 r = reflect(viewDir, s.normal);
	r = normalize(mix(r, s.normal, alpha * alpha));
	vec3 reflected = mix(skyRadiance(r, env), env.skyAmbient, alpha);
	float specularOcclusion = skyLightFalloff(s.light.y) * s.ao;
	color += reflected * environmentBrdf(s.f0, NdotV, alpha) * specularOcclusion * SPECULAR_INTENSITY;
#endif

	return color;
}

#endif
