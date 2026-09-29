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

out vec2 texcoord;
out vec2 lightLevels;
out vec4 vertexColor;
out vec3 playerPos;
out vec3 geoNormal;
flat out int materialClass;

void main() {
	texcoord    = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lightLevels = remapLightmap((gl_TextureMatrix[1] * gl_MultiTexCoord1).xy);
	vertexColor = gl_Color;

	vec3 viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
	playerPos = playerFromView(viewPos);
	geoNormal = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal);

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
#include "/lib/lighting/forward.glsl"

uniform sampler2D gtexture;
#if !defined PROGRAM_TERRAIN
uniform vec4 entityColor; // hurt/creeper flash tint, alpha = strength
#endif

in vec2 texcoord;
in vec2 lightLevels;
in vec4 vertexColor;
in vec3 playerPos;
in vec3 geoNormal;
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

	Surface s;
	s.albedo = srgbToLinear(base.rgb);
	s.normal = n;
	s.light = lightLevels;
	s.ao = ao;
	s.materialClass = materialClass;
	s.emission = emissionFromAlbedo(s.albedo, materialClass);
	s.transmission = 0.0;
	if (materialClass == MAT_FOLIAGE) {
		// Cross-shaped plants: shade like the ground they grow from, with light passing through.
		s.normal = vec3(0.0, 1.0, 0.0);
		s.transmission = 0.4;
	} else if (materialClass == MAT_LEAVES) {
		s.transmission = 0.5;
	}

	EnvState env = getEnvState();

	float shadow = 1.0;
#if defined SHADOW_RECEIVER
	float NdotL = dot(s.normal, env.lightDir);
	if (NdotL > 0.0 || s.transmission > 0.0) {
		vec3 biasNormal = NdotL >= 0.0 ? s.normal : -s.normal; // offset toward the light
		shadow = sampleShadow(playerPos, biasNormal, abs(NdotL), gl_FragCoord.xy);
	}
#endif

	outColor = vec4(shadeSurface(s, env, shadow), base.a);
	outNormalLight = vec4(encodeNormal(s.normal), packLightmap(s.light), 1.0);
	outAlbedo = vec4(base.rgb, 1.0);
	outMaterial = vec4(float(materialClass) / 255.0, shadow, 0.0, 1.0);
}

#endif
