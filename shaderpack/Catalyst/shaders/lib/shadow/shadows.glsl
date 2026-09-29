// Catalyst — sun/moon shadow mapping.
//
// Shadow space: shadowProjection * shadowModelView * playerPos gives orthographic clip space (w = 1).
// A radial distortion concentrates shadow-map texels near the player. The shadow pass (program/shadow.glsl)
// and every receiver MUST use the same distortShadowClip() — it is the single owner of that mapping.
//
// Bias strategy: receiver position is pushed along its normal by an amount proportional to the local
// shadow texel size (which varies with distortion), plus a small slope-scaled depth bias.
// Requires: settings.glsl, core/common.glsl, core/uniforms.glsl.

#if !defined CATALYST_SHADOWS
#define CATALYST_SHADOWS

// 0 = no distortion, 1 = maximal. 0.85 keeps near-field detail without starving the far field.
const float SHADOW_DISTORTION = 0.85;
// shadow depth is compressed so casters behind the player still fit in the depth range.
const float SHADOW_DEPTH_SCALE = 0.2;

float shadowDistortionFactor(vec2 clipXY) {
	return length(clipXY) * SHADOW_DISTORTION + (1.0 - SHADOW_DISTORTION);
}

vec3 distortShadowClip(vec3 clipPos) {
	clipPos.xy /= shadowDistortionFactor(clipPos.xy);
	clipPos.z *= SHADOW_DEPTH_SCALE;
	return clipPos;
}

#if defined SHADOW_RECEIVER

uniform sampler2DShadow shadowtex0;

// Returns direct-light visibility in [0,1] for a surface at `playerPos`.
// `geoNormal` is the geometric normal (player space); `NdotL` its cosine with the light direction.
float sampleShadow(vec3 playerPos, vec3 geoNormal, float NdotL, vec2 pixel) {
	// World-space size of one shadow texel before distortion.
	float texelWorld = 2.0 * shadowDistance / float(shadowMapResolution);

	vec3 shadowView = (shadowModelView * vec4(playerPos, 1.0)).xyz;
	vec2 undistortedXY = (shadowProjection * vec4(shadowView, 1.0)).xy;
	float localScale = shadowDistortionFactor(undistortedXY); // < 1 near the player (denser texels)

	float normalOffset = texelWorld * localScale * (1.2 + 1.8 * (1.0 - saturate(NdotL)));
	vec3 biasedPos = playerPos + geoNormal * normalOffset;

	vec3 clip = (shadowProjection * (shadowModelView * vec4(biasedPos, 1.0))).xyz;
	vec3 shadowCoord = distortShadowClip(clip) * 0.5 + 0.5;

	// Outside the shadow map: treat as lit.
	if (any(lessThan(shadowCoord, vec3(0.0))) || any(greaterThan(shadowCoord, vec3(1.0)))) return 1.0;

	// Fade out toward shadowDistance so the shadow edge is not a visible line.
	float dist = length(playerPos.xz);
	float fade = smoothstep(shadowDistance * 0.85, shadowDistance, dist);

	float slopeBias = 0.00002 + 0.00010 * (1.0 - saturate(NdotL));
	shadowCoord.z -= slopeBias;

	float visibility;
#if SHADOW_FILTER == 0
	visibility = texture(shadowtex0, shadowCoord);
#else
	#if SHADOW_FILTER == 1
		const int TAPS = 4;
	#elif SHADOW_FILTER == 2
		const int TAPS = 8;
	#else
		const int TAPS = 16;
	#endif
	// Penumbra radius in shadow-map texels (converted to UV). More taps can afford a wider kernel without noise.
	float radius = (1.0 + 0.5 * float(SHADOW_FILTER)) * SHADOW_SOFTNESS / float(shadowMapResolution);
	float rotation = interleavedGradientNoise(pixel) * TAU;
	visibility = 0.0;
	for (int i = 0; i < TAPS; i++) {
		vec2 offset = vogelDisk(i, TAPS, rotation) * radius;
		visibility += texture(shadowtex0, vec3(shadowCoord.xy + offset, shadowCoord.z));
	}
	visibility /= float(TAPS);
#endif

	return mix(visibility, 1.0, fade);
}

#endif // SHADOW_RECEIVER
#endif
