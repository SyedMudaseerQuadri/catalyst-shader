// Catalyst — simple forward programs that only write scene radiance (colortex0).
//   PROGRAM_BASIC    (gbuffers_basic, gbuffers_line): untextured lines/outlines — shown as-is for readability.
//   PROGRAM_UNLIT    (gbuffers_textured and its fallbacks: beacon beam, spider eyes, armor glint):
//                    self-lit or overlay content; vanilla blending is preserved.
//   PROGRAM_CLOUDS   (gbuffers_clouds): vanilla clouds, lit by the shared environment (replaced in M3).
//   PROGRAM_WEATHER  (gbuffers_weather): rain and snow, lit by ambient + direct light.

#include "/lib/settings.glsl"
#include "/lib/core/common.glsl"
#include "/lib/core/uniforms.glsl"
#include "/lib/core/space.glsl"
#include "/lib/core/encode.glsl"

// =============================================================================================
#if defined STAGE_VERTEX

out vec2 texcoord;
out vec2 lightLevels;
out vec4 vertexColor;
out vec3 playerPos;
out vec3 geoNormal;

void main() {
	texcoord    = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lightLevels = remapLightmap((gl_TextureMatrix[1] * gl_MultiTexCoord1).xy);
	vertexColor = gl_Color;
	vec3 viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
	playerPos = playerFromView(viewPos);
	geoNormal = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal);
	gl_Position = ftransform();
}

#endif
// =============================================================================================
#if defined STAGE_FRAGMENT

#include "/lib/environment/state.glsl"

#if !defined PROGRAM_BASIC
uniform sampler2D gtexture;
#endif

in vec2 texcoord;
in vec2 lightLevels;
in vec4 vertexColor;
in vec3 playerPos;
in vec3 geoNormal;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

// Display-referred content (outlines, glows) is lifted into scene-linear so it survives exposure.
const float UNLIT_RADIANCE = 1.0;

void main() {
#if defined PROGRAM_BASIC
	vec4 c = vertexColor;
	outColor = vec4(srgbToLinear(c.rgb) * UNLIT_RADIANCE, c.a);
#else
	vec4 c = texture(gtexture, texcoord) * vertexColor;
	if (c.a < 0.004) discard;
	vec3 albedo = srgbToLinear(c.rgb);
	EnvState env = getEnvState();

	#if defined PROGRAM_CLOUDS
		vec3 n = dot(geoNormal, geoNormal) > 1e-6 ? normalize(geoNormal) : vec3(0.0, 1.0, 0.0);
		// Clouds are thick scattering media: soft wrapped direct light plus a strong sky term.
		float wrapped = saturate(dot(n, env.lightDir) * 0.5 + 0.5);
		vec3 lit = env.lightRadiance * wrapped * 0.6 + env.skyAmbient * 1.6 + vec3(0.004);
		outColor = vec4(albedo * lit, c.a);
	#elif defined PROGRAM_WEATHER
		vec3 lit = env.skyAmbient * 1.2 + env.lightRadiance * 0.15 + env.blockLightColor * pow(lightLevels.x, 2.6);
		outColor = vec4(albedo * lit, c.a * 0.7);
	#else
		outColor = vec4(albedo * UNLIT_RADIANCE, c.a);
	#endif
#endif
}

#endif
