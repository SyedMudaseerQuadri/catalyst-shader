// Catalyst — translucent terrain: water, stained glass, ice, slime, honey (gbuffers_water).
//
// Forward-shaded and alpha-blended over the lit scene in colortex0 only; it does not overwrite the
// opaque G-buffer data behind it. Water gets a Fresnel sky reflection and a sun glint. This is the
// M1/M2 foundation; the full water/underwater system is M4.

#include "/lib/settings.glsl"
#include "/lib/core/common.glsl"
#include "/lib/core/uniforms.glsl"
#include "/lib/core/space.glsl"
#include "/lib/core/encode.glsl"
#include "/lib/material/classify.glsl"

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

// Water's reflectance at normal incidence (IOR ~1.33).
const float WATER_F0 = 0.02;

void main() {
	vec4 texel = texture(gtexture, texcoord);
	// separateAo=true: vertex rgb = biome tint, vertex a = ambient occlusion.
	vec4 base = vec4(texel.rgb * vertexColor.rgb, texel.a);
	if (base.a < 0.01) discard;

	vec3 n = dot(geoNormal, geoNormal) > 1e-6 ? normalize(geoNormal) : vec3(0.0, 1.0, 0.0);

	Surface s = makeSurface(srgbToLinear(base.rgb), n, lightLevels, vertexColor.a, materialClass);

#ifdef MATERIAL_MAPS
	// Stained glass, ice, slime, honey: resource-pack materials apply. Water has its own model below.
	if (materialClass != MAT_WATER) {
		mat3 tbn;
		if (buildTangentFrame(n, tangentPlayer, tbn)) applyLabPbrNormal(s, texture(normals, texcoord), tbn);
		applyLabPbrSpecular(s, texture(specular, texcoord));
	}
#endif

	EnvState env = getEnvState();

	float shadow = 1.0;
	float NdotL = dot(n, env.lightDir);
#if defined SHADOW_RECEIVER
	if (NdotL > 0.0) shadow = sampleShadow(playerPos, n, NdotL, gl_FragCoord.xy);
#endif

	vec3 color = shadeSurface(s, env, shadow, normalize(playerPos));
	float alpha = base.a;

	if (materialClass == MAT_WATER) {
		vec3 viewDir = normalize(playerPos);
		// Always reflect off the side facing the camera (also correct when looking up from underwater).
		vec3 facingN = dot(n, viewDir) > 0.0 ? -n : n;
		float cosTheta = saturate(dot(-viewDir, facingN));
		float fresnel = WATER_F0 + (1.0 - WATER_F0) * pow(1.0 - cosTheta, 5.0);

		vec3 reflDir = reflect(viewDir, facingN);
		// Sky reflection is only plausible where the sky is visible from the surface.
		vec3 reflection = skyRadiance(reflDir, env) * skyLightFalloff(lightLevels.y);

		// Sun glint: a tight specular lobe, shadowed and gated by sky access.
		float glint = pow(saturate(dot(reflDir, env.lightDir)), 600.0) * 60.0;
		reflection += env.lightRadiance * glint * shadow * directSkyAccess(lightLevels.y);

		// Water body: darker and more transparent than the vanilla texture suggests.
		color *= 0.55;
		color = mix(color, reflection, fresnel);
		alpha = mix(base.a * 0.75, 1.0, fresnel);
	}

	outColor = vec4(color, alpha);
}

#endif
