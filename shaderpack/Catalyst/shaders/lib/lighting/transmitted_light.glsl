// Catalyst — direct light filtered by translucent casters (M4): tinted glass/ice color the light passing through,
// and water above a receiver absorbs it with depth and focuses it into caustics. Sky light under water is absorbed
// too (only where the shadow map knows the water depth, i.e. within shadowDistance).
// Edits a local EnvState copy so shadeSurface() needs no extra parameters.
// Requires: shadow/shadows.glsl (with SHADOW_RECEIVER), environment/water.glsl, environment/state.glsl.

#if !defined CATALYST_TRANSMITTED_LIGHT
#define CATALYST_TRANSMITTED_LIGHT

#if defined SHADOW_RECEIVER
// Returns the scalar light transmittance (for the Sun Shadow debug view).
float applyTranslucentShadow(inout EnvState env, vec3 playerPos, vec3 biasNormal, float NdotL) {
	float waterDepth;
	vec3 tint = sampleTranslucentShadow(playerPos, biasNormal, NdotL, waterDepth);
	if (waterDepth > 0.0) {
		WaterOptics o = waterOptics(VANILLA_WATER_COLOR);
		tint *= exp(-o.extinction * waterDepth) * causticPattern(playerPos + cameraPosition, waterDepth);
		env.skyAmbient *= exp(-o.extinction * waterDepth * 0.6);
	}
	env.lightRadiance *= tint;
	return saturate(luminance(tint));
}
#endif

#endif
