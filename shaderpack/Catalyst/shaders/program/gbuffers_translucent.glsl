// Catalyst — translucent terrain: water, stained glass, ice, slime, honey (gbuffers_water).
//
// Glass, ice, slime and honey are forward-shaded and alpha-blended over the lit scene in colortex0 only.
// Water (M4, D-015) is composited by this shader itself and written opaque: it refracts the opaque scene copy
// (colortex5), absorbs and scatters along the real water thickness (depthtex1 = depth without translucents),
// reflects terrain (screen space), sky and clouds with Fresnel, shows wind/rain-driven waves, sun glint and
// shoreline foam. Seen from below, it shows Snell's window and total internal reflection.

#include "/lib/settings.glsl"
#include "/lib/core/common.glsl"
#include "/lib/core/uniforms.glsl"
#include "/lib/core/space.glsl"
#include "/lib/core/encode.glsl"
#include "/lib/material/classify.glsl"
#include "/lib/post/taa.glsl"

// =============================================================================================
#if defined STAGE_VERTEX

in vec4 mc_Entity;
in vec4 at_tangent; // xyz = dP/du (model space), w = bitangent sign

out vec2 texcoord;
out vec2 lightLevels;
out vec4 vertexColor;
out vec3 playerPos;
out vec3 geoNormal;
out vec4 tangentPlayer;
flat out int materialClass;

void main() {
	texcoord    = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lightLevels = remapLightmap((gl_TextureMatrix[1] * gl_MultiTexCoord1).xy);
	vertexColor = gl_Color;

	vec3 viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
	playerPos = playerFromView(viewPos);
	geoNormal = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal);
	tangentPlayer = vec4(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * at_tangent.xyz), at_tangent.w);
	materialClass = materialFromBlockId(int(mc_Entity.x + 0.5));

	gl_Position = taaJitterClip(ftransform());
}

#endif
// =============================================================================================
#if defined STAGE_FRAGMENT

// SHADOWS is a user option; Iris only recognizes boolean options referenced by #ifdef.
#ifdef SHADOWS
	#if defined DIM_OVERWORLD
		#define SHADOW_RECEIVER
	#endif
#endif

#include "/lib/environment/state.glsl"
#include "/lib/shadow/shadows.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/lighting/specular.glsl"
#include "/lib/material/labpbr.glsl"
#include "/lib/lighting/forward.glsl"
#include "/lib/atmosphere/clouds.glsl"
#include "/lib/environment/water.glsl"
#include "/lib/material/weather_surface.glsl"
#include "/lib/lighting/transmitted_light.glsl"
#include "/lib/lighting/ssr.glsl"

uniform sampler2D gtexture;
uniform sampler2D colortex5; // opaque scene copy (deferred)
uniform sampler2D depthtex1; // depth without translucents
#ifdef MATERIAL_MAPS
uniform sampler2D normals;
uniform sampler2D specular;
#endif

in vec2 texcoord;
in vec2 lightLevels;
in vec4 vertexColor;
in vec3 playerPos;
in vec3 geoNormal;
in vec4 tangentPlayer;
flat in int materialClass;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

const float REFRACTION_STRENGTH = 0.035; // screen-space offset per unit of normal tilt, before thickness scaling

// Distance from the eye to the opaque surface seen through screen position `uv`.
float opaqueDistance(vec2 uv) {
	float depth = texture(depthtex1, uv).r;
	if (depth >= 1.0) return far * 4.0;
	return length(viewFromScreen(vec3(uv, depth)));
}

// Reflection of the environment (no screen-space data): sky + clouds, occluded where the sky is hidden.
vec3 environmentReflection(vec3 dir, EnvState env, float skyAccess) {
	vec3 sky = approximateCloudReflection(skyRadiance(dir, env), dir, env);
	return sky * skyAccess;
}

vec3 shadeWater(vec4 texel, EnvState env, float shadow) {
	vec2 res = vec2(viewWidth, viewHeight);
	vec2 screenUv = gl_FragCoord.xy / res;
	vec3 worldPos = playerPos + cameraPosition;
	float surfaceDistance = length(playerPos);
	vec3 viewDir = playerPos / max(surfaceDistance, 1e-4);
	vec3 geoN = dot(geoNormal, geoNormal) > 1e-6 ? normalize(geoNormal) : vec3(0.0, 1.0, 0.0);
	float skyAccess = skyLightFalloff(lightLevels.y);

	// Waves on horizontal surfaces (both sides); flowing side faces keep their geometric normal.
	vec3 n = geoN;
	if (abs(geoN.y) > 0.5) {
		vec3 waveN = waterSurfaceNormal(worldPos.xz, precipitationExposure(lightLevels.y));
		n = geoN.y > 0.0 ? waveN : vec3(waveN.x, -waveN.y, waveN.z);
	}
	// The side facing the camera.
	bool fromBelow = dot(geoN, viewDir) > 0.0;
	vec3 facingN = fromBelow ? -n : n;
	float cosI = saturate(dot(-viewDir, facingN));

	WaterOptics optics = waterOptics(vertexColor.rgb);

	// ---- Refraction: offset by the wave tilt in view space, more through thicker water.
	vec3 viewTilt = mat3(gbufferModelView) * (facingN - (fromBelow ? -geoN : geoN));
	float thickness = max(opaqueDistance(screenUv) - surfaceDistance, 0.0);
	vec2 refractUv = screenUv + viewTilt.xy * REFRACTION_STRENGTH * saturate(thickness * 0.5) * (fromBelow ? 0.6 : 1.0);
	refractUv = clamp(refractUv, vec2(0.0), vec2(1.0));
	float refractedDistance = opaqueDistance(refractUv);
	if (refractedDistance < surfaceDistance) {
		// The offset landed on something in front of the water: use the straight-through sample.
		refractUv = screenUv;
		refractedDistance = opaqueDistance(screenUv);
	}
	vec3 behind = texture(colortex5, refractUv).rgb;

	vec3 reflectDir = reflect(viewDir, facingN);
	float fresnel;
	vec3 transmitted;
	vec3 reflected;

	if (!fromBelow) {
		// ---- Seen from above: absorption and in-scattering along the path through the water.
		float pathLength = min(max(refractedDistance - surfaceDistance, 0.0), 256.0);
		vec3 transmittance = exp(-optics.extinction * pathLength);
		vec3 lightInWater = env.skyAmbient * skyAccess + env.lightRadiance * shadow * max(env.lightDir.y, 0.0) * 0.6;
		vec3 inScatter = lightInWater * (optics.scattering / optics.extinction) * (1.0 - transmittance);
		// Keep a trace of the vanilla water texture's pattern (Minecraft identity).
		float pattern = mix(1.0, luminance(texel.rgb) * 1.8, 0.20);
		transmitted = (behind * transmittance + inScatter) * pattern;

		fresnel = WATER_F0_SURFACE + (1.0 - WATER_F0_SURFACE) * pow(1.0 - cosI, 5.0);
		reflectDir.y = max(reflectDir.y, 0.02); // waves cannot reflect the ground below the horizon
		reflectDir = normalize(reflectDir);
		reflected = environmentReflection(reflectDir, env, skyAccess);
#ifdef WATER_REFLECTIONS
		vec3 viewPos = (gbufferModelView * vec4(playerPos, 1.0)).xyz;
		vec3 viewReflect = mat3(gbufferModelView) * reflectDir;
		float dither = interleavedGradientNoise(gl_FragCoord.xy + 5.588238 * float(frameCounter % 64));
		vec4 ssr = screenSpaceReflection(viewPos, viewReflect, depthtex1, colortex5, dither);
		reflected = mix(reflected, ssr.rgb, ssr.a);
#endif
		// Sun glint: sharp GGX lobe on the wave normal (sparkles move with the waves).
		vec3 glint = env.lightRadiance * directSpecular(n, -viewDir, env.lightDir, 0.025, vec3(WATER_F0_SURFACE))
		             * shadow * directSkyAccess(lightLevels.y);
		reflected += glint / max(fresnel, 1e-3); // added after the Fresnel mix below at full strength

		// Shoreline foam: thin water against terrain, broken up by moving noise.
		float foamNoise = valueNoise2(worldPos.xz * 3.0 + frameTimeCounter * vec2(0.3, 0.2));
		float foam = smoothstep(0.55, 0.05, thickness) * smoothstep(0.35, 0.75, foamNoise) * 0.55;
		vec3 foamColor = (env.skyAmbient * skyAccess + env.lightRadiance * shadow * max(dot(geoN, env.lightDir), 0.0)) * 0.85;
		transmitted = mix(transmitted, foamColor, foam);
	} else {
		// ---- Seen from below: Snell's window. Beyond the critical angle the surface is a mirror of the water.
		float sinT2 = sqr(WATER_IOR) * (1.0 - cosI * cosI);
		if (sinT2 >= 1.0) {
			fresnel = 1.0;
		} else {
			float cosT = sqrt(1.0 - sinT2);
			fresnel = WATER_F0_SURFACE + (1.0 - WATER_F0_SURFACE) * pow(1.0 - cosT, 5.0);
		}
		transmitted = behind; // the underwater fog (composite) absorbs along the eye-to-surface distance
		vec3 waterHue = vanillaFogLinear() / max(luminance(vanillaFogLinear()), 1e-3);
		reflected = waterHue * (luminance(env.skyAmbient) * 0.25 + 0.01) * (0.3 + 0.7 * env.eyeSky);
	}

	return mix(transmitted, reflected, fresnel);
}

void main() {
	vec4 texel = texture(gtexture, texcoord);
	// separateAo=true: vertex rgb = biome tint, vertex a = ambient occlusion.
	vec4 base = vec4(texel.rgb * vertexColor.rgb, texel.a);
	if (base.a < 0.01) discard;

	vec3 n = dot(geoNormal, geoNormal) > 1e-6 ? normalize(geoNormal) : vec3(0.0, 1.0, 0.0);
	EnvState env = getEnvState();

	float shadow = 1.0;
	float NdotL = dot(n, env.lightDir);
#if defined SHADOW_RECEIVER
	if (NdotL > 0.0) shadow = sampleShadow(playerPos, n, NdotL, gl_FragCoord.xy);
#endif
	shadow *= cloudShadow(playerPos, env);

	if (materialClass == MAT_WATER) {
		outColor = vec4(shadeWater(texel, env, shadow), 1.0);
		return;
	}

	Surface s = makeSurface(srgbToLinear(base.rgb), n, lightLevels, vertexColor.a, materialClass);
#ifdef MATERIAL_MAPS
	// Stained glass, ice, slime, honey: resource-pack materials apply.
	mat3 tbn = mat3(1.0); // initialized: buildTangentFrame may be skipped (NVIDIA C7050)
	if (buildTangentFrame(n, tangentPlayer, tbn)) applyLabPbrNormal(s, texture(normals, texcoord), tbn);
	applyLabPbrSpecular(s, texture(specular, texcoord));
#endif
	applyWeatherToSurface(s, playerPos + cameraPosition, env);
#if defined SHADOW_RECEIVER
	if (NdotL > 0.0) applyTranslucentShadow(env, playerPos, n, NdotL);
#endif

	outColor = vec4(shadeSurface(s, env, shadow, normalize(playerPos)), base.a);
}

#endif
