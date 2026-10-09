// Catalyst — lit opaque/cutout geometry: terrain, block entities, entities, hand, particles.
//
// Forward shading into colortex0 plus G-buffer data for later passes and debug views.
// Forward shading is deliberate: Iris renders some of these programs (particles, hand) after the
// deferred pass, so lighting must not depend on running before deferred.
//
// Wrapper defines: STAGE_VERTEX or STAGE_FRAGMENT; DIM_OVERWORLD / DIM_NETHER / DIM_END;
// PROGRAM_TERRAIN for chunk geometry (separate AO in vertex alpha, block IDs available).

#include "/lib/settings.glsl"
#include "/lib/core/common.glsl"
#include "/lib/core/uniforms.glsl"
#include "/lib/core/space.glsl"
#include "/lib/core/encode.glsl"
#include "/lib/material/classify.glsl"

// =============================================================================================
#if defined STAGE_VERTEX

in vec4 mc_Entity;
in vec4 at_tangent; // xyz = dP/du (model space), w = bitangent sign; zero for formats without tangents

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

#if defined PROGRAM_TERRAIN
	materialClass = materialFromBlockId(int(mc_Entity.x + 0.5));
#else
	materialClass = MAT_ENTITY;
#endif

	gl_Position = ftransform();
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

uniform sampler2D gtexture;
// MATERIAL_MAPS is a user option; Iris only recognizes boolean options referenced by #ifdef.
#ifdef MATERIAL_MAPS
uniform sampler2D normals;  // LabPBR _n (Iris default when absent: flat normal, AO 1)
uniform sampler2D specular; // LabPBR _s (Iris default when absent: all zero = no specular)
#endif
#if !defined PROGRAM_TERRAIN
uniform vec4 entityColor; // hurt/creeper flash tint, alpha = strength
#endif

in vec2 texcoord;
in vec2 lightLevels;
in vec4 vertexColor;
in vec3 playerPos;
in vec3 geoNormal;
in vec4 tangentPlayer;
flat in int materialClass;

/* RENDERTARGETS: 0,1,2,3 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outNormalLight;
layout(location = 2) out vec4 outAlbedo;
layout(location = 3) out vec4 outMaterial;

void main() {
	vec4 texel = texture(gtexture, texcoord);

#if defined PROGRAM_TERRAIN
	// separateAo=true: rgb = biome tint, a = vanilla ambient occlusion.
	vec4 base = vec4(texel.rgb * vertexColor.rgb, texel.a);
	float ao = vertexColor.a;
#else
	vec4 base = texel * vertexColor;
	base.rgb = mix(base.rgb, entityColor.rgb, entityColor.a);
	float ao = 1.0;
#endif
	if (base.a < 0.1) discard;

	// Particles and some entity quads can carry a zero normal; never normalize a zero vector.
	vec3 n = dot(geoNormal, geoNormal) > 1e-6 ? normalize(geoNormal) : vec3(0.0, 1.0, 0.0);

	Surface s = makeSurface(srgbToLinear(base.rgb), n, lightLevels, ao, materialClass);

#ifdef MATERIAL_MAPS
	// Foliage keeps its deliberate up-facing shading normal (see makeSurface).
	mat3 tbn = mat3(1.0); // initialized: buildTangentFrame may be skipped (NVIDIA C7050)
	if (materialClass != MAT_FOLIAGE && buildTangentFrame(n, tangentPlayer, tbn)) {
		applyLabPbrNormal(s, texture(normals, texcoord), tbn);
	}
	applyLabPbrSpecular(s, texture(specular, texcoord));
#endif

	EnvState env = getEnvState();

	float shadow = 1.0;
#if defined SHADOW_RECEIVER
	// Shadow lookups use the geometric normal: normal maps must not move the receiver.
	float NdotL = dot(s.geoNormal, env.lightDir);
	if (NdotL > 0.0 || s.transmission > 0.0) {
		vec3 biasNormal = NdotL >= 0.0 ? s.geoNormal : -s.geoNormal; // offset toward the light
		shadow = sampleShadow(playerPos, biasNormal, abs(NdotL), gl_FragCoord.xy);
	} else {
		shadow = 0.0; // faces turned away from the light receive no direct light (Sun Shadow debug view)
	}
#endif

	float smoothness = max(s.f0.r, max(s.f0.g, s.f0.b)) > 0.0 ? 1.0 - sqrt(s.roughness) : 0.0;
	outColor = vec4(shadeSurface(s, env, shadow, normalize(playerPos)), base.a);
	outNormalLight = vec4(encodeNormal(s.normal), packLightmap(s.light), 1.0);
	outAlbedo = vec4(base.rgb, 1.0);
	outMaterial = vec4(float(materialClass) / 255.0, shadow, smoothness, 1.0);
}

#endif
