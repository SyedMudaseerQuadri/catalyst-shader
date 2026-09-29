// Catalyst — sky passes.
//   PROGRAM_SKY_BASIC    (gbuffers_skybasic): sky dome, sunrise fan, stars, void plane.
//   PROGRAM_SKY_TEXTURED (gbuffers_skytextured): sun, moon, End sky box.
//
// The sky dome is shaded per pixel from the view direction (the vanilla geometry only supplies coverage).
// Clouds are drawn after these programs and blend over the sky as expected.

#include "/lib/settings.glsl"
#include "/lib/core/common.glsl"
#include "/lib/core/uniforms.glsl"
#include "/lib/core/space.glsl"

// =============================================================================================
#if defined STAGE_VERTEX

out vec2 texcoord;
out vec4 vertexColor;

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	vertexColor = gl_Color;
	gl_Position = ftransform();
}

#endif
// =============================================================================================
#if defined STAGE_FRAGMENT

#include "/lib/environment/state.glsl"
#include "/lib/atmosphere/sky.glsl"

uniform int renderStage;
#if defined PROGRAM_SKY_TEXTURED
uniform sampler2D gtexture;
#endif

in vec2 texcoord;
in vec4 vertexColor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

// Scene-linear brightness of the celestial textures relative to their sRGB texel value.
const float SUN_DISK_RADIANCE  = 12.0;
const float MOON_DISK_RADIANCE = 0.9;
const float STAR_RADIANCE      = 0.6;
const float END_SKY_RADIANCE   = 0.25;

void main() {
	EnvState env = getEnvState();

#if defined PROGRAM_SKY_BASIC
	if (renderStage == MC_RENDER_STAGE_STARS) {
		float visibility = (1.0 - env.day) * (1.0 - env.overcast);
		outColor = vec4(srgbToLinear(vertexColor.rgb) * STAR_RADIANCE * visibility, vertexColor.a);
		return;
	}
	// Vanilla's sunrise fan is replaced by the analytic twilight in skyRadiance().
	if (renderStage == MC_RENDER_STAGE_SUNSET) discard;

	vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), 1.0);
	vec3 dir = normalize(playerDirFromView(viewFromScreen(screenPos)));
	outColor = vec4(skyRadiance(dir, env), 1.0);
#endif

#if defined PROGRAM_SKY_TEXTURED
	vec4 texel = texture(gtexture, texcoord) * vertexColor;
	vec3 linear = srgbToLinear(texel.rgb);
	float radiance = 1.0;
	if (renderStage == MC_RENDER_STAGE_SUN) {
		radiance = SUN_DISK_RADIANCE * (1.0 - env.overcast);
		// Sun disk color follows the atmosphere (reddens near the horizon like the sunlight itself).
		vec3 tint = env.sunRadiance / max(max(env.sunRadiance.r, max(env.sunRadiance.g, env.sunRadiance.b)), 1e-4);
		linear *= tint;
	} else if (renderStage == MC_RENDER_STAGE_MOON) {
		radiance = MOON_DISK_RADIANCE * NIGHT_VISIBILITY * (1.0 - env.overcast);
	} else {
		radiance = END_SKY_RADIANCE; // End sky box / custom skies
	}
	outColor = vec4(linear * radiance, texel.a);
#endif
}

#endif
