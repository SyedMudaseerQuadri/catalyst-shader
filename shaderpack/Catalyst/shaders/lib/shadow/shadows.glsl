// Catalyst — sun/moon shadow mapping.
//
// Shadow space: shadowProjection * shadowModelView * playerPos gives orthographic clip space (w = 1).
// A radial distortion concentrates shadow-map texels near the player. The shadow pass (program/shadow.glsl)
// and every receiver MUST use the same distortShadowClip() — it is the single owner of that mapping.
//
// Casters: shadowtex1 holds opaque/cutout casters only (Iris copies it before translucent shadow terrain);
// shadowtex0 also holds translucent casters, and shadowcolor0 says what they are (program/shadow.glsl):
// a = 0.5 marks water (rgb unused), a = 1 with rgb < 1 is tinted glass/ice transmittance.
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

uniform sampler2DShadow shadowtex1; // opaque casters, hardware compare
uniform sampler2D shadowtex0;       // all casters, raw depth
uniform sampler2D shadowcolor0;     // translucent caster info

const float SHADOW_WATER_FLAG = 0.5;

// Biased, distorted shadow-map coordinate of a receiver; `fade` = 1 at the shadow distance edge.
vec3 shadowCoordinate(vec3 playerPos, vec3 geoNormal, float NdotL, out float fade) {
	float texelWorld = 2.0 * shadowDistance / float(shadowMapResolution);
	vec3 shadowView = (shadowModelView * vec4(playerPos, 1.0)).xyz;
	vec2 undistortedXY = (shadowProjection * vec4(shadowView, 1.0)).xy;
	float localScale = shadowDistortionFactor(undistortedXY);
	float normalOffset = texelWorld * localScale * (1.2 + 1.8 * (1.0 - saturate(NdotL)));
	vec3 biasedPos = playerPos + geoNormal * normalOffset;
	vec3 clip = (shadowProjection * (shadowModelView * vec4(biasedPos, 1.0))).xyz;
	fade = smoothstep(shadowDistance * 0.85, shadowDistance, length(playerPos.xz));
	vec3 coord = distortShadowClip(clip) * 0.5 + 0.5;
	coord.z -= 0.00002 + 0.00010 * (1.0 - saturate(NdotL));
	return coord;
}

// Blocks per unit of shadow-map depth (orthographic projection, after the depth compression).
float shadowDepthToBlocks(float depthDelta) {
	return depthDelta * 2.0 / (abs(shadowProjection[2][2]) * SHADOW_DEPTH_SCALE);
}

// Translucent casters between the light and a receiver: returns the color transmittance of tinted glass/ice
// (1 = none) and, through `waterDepth`, how many blocks of water the light crossed (0 = none).
vec3 sampleTranslucentShadow(vec3 playerPos, vec3 geoNormal, float NdotL, out float waterDepth) {
	waterDepth = 0.0;
	float fade;
	vec3 coord = shadowCoordinate(playerPos, geoNormal, NdotL, fade);
	if (any(lessThan(coord, vec3(0.0))) || any(greaterThan(coord, vec3(1.0))) || fade >= 1.0) return vec3(1.0);
	float casterDepth = texture(shadowtex0, coord.xy).r;
	if (casterDepth >= coord.z - 0.0001) return vec3(1.0);
	vec4 info = texture(shadowcolor0, coord.xy);
	if (abs(info.a - SHADOW_WATER_FLAG) < 0.25) {
		waterDepth = shadowDepthToBlocks(coord.z - casterDepth) * (1.0 - fade);
		return vec3(1.0);
	}
	return mix(info.rgb, vec3(1.0), fade);
}


// Returns direct-light visibility in [0,1] for a surface at `playerPos`.
// `geoNormal` is the geometric normal (player space); `NdotL` its cosine with the light direction.
float sampleShadow(vec3 playerPos, vec3 geoNormal, float NdotL, vec2 pixel) {
	float fade;
	vec3 shadowCoord = shadowCoordinate(playerPos, geoNormal, NdotL, fade);

	// Outside the shadow map: treat as lit.
	if (any(lessThan(shadowCoord, vec3(0.0))) || any(greaterThan(shadowCoord, vec3(1.0)))) return 1.0;

	float visibility;
#if SHADOW_FILTER == 0
	visibility = texture(shadowtex1, shadowCoord);
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
		visibility += texture(shadowtex1, vec3(shadowCoord.xy + offset, shadowCoord.z));
	}
	visibility /= float(TAPS);
#endif

	return mix(visibility, 1.0, fade);
}

#endif // SHADOW_RECEIVER
#endif
