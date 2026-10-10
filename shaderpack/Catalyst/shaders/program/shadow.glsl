// Catalyst — shadow map pass (depth only). Overworld only; the Nether and End have no shadow caster.
// Uses distortShadowClip() from lib/shadow/shadows.glsl, the same mapping receivers use.

#include "/lib/settings.glsl"
#include "/lib/core/common.glsl"
#include "/lib/core/uniforms.glsl"
#include "/lib/material/classify.glsl"
#include "/lib/shadow/shadows.glsl"
#include "/lib/core/noise.glsl"
#include "/lib/environment/wind.glsl"

// =============================================================================================
#if defined STAGE_VERTEX

in vec4 mc_Entity;
in vec2 mc_midTexCoord;

out vec2 texcoord;
out vec4 vertexColor;
flat out int isWater;

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
		int materialClass = materialFromBlockId(int(mc_Entity.x + 0.5));
	isWater = materialClass == MAT_WATER ? 1 : 0;
	vertexColor = gl_Color;

	vec4 clip = ftransform(); // in the shadow pass this is shadowProjection * shadowModelView * vertex
	if (materialClass == MAT_FOLIAGE || materialClass == MAT_LEAVES) {
		// Same wind displacement as gbuffers_terrain, so shadows sway with the plants.
		vec3 playerPos = (shadowModelViewInverse * (gl_ModelViewMatrix * gl_Vertex)).xyz;
		playerPos += foliageWindOffsetFor(playerPos + cameraPosition, materialClass, texcoord.y < mc_midTexCoord.y);
		clip = shadowProjection * (shadowModelView * vec4(playerPos, 1.0));
	}
	clip.xyz = distortShadowClip(clip.xyz);
	gl_Position = clip;
}

#endif
// =============================================================================================
#if defined STAGE_FRAGMENT

uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 vertexColor;
flat in int isWater;

const float SHADOW_WATER_FLAG_OUT = 0.5; // must match SHADOW_WATER_FLAG in lib/shadow/shadows.glsl

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outShadowColor;

void main() {
	// Water is a caster in shadowtex0 only (receivers use shadowtex1 for opaque shadows); it marks itself so
	// receivers below can apply water absorption and caustics (lib/shadow/shadows.glsl).
	if (isWater == 1) {
		outShadowColor = vec4(1.0, 1.0, 1.0, SHADOW_WATER_FLAG_OUT);
		return;
	}
	vec4 texel = texture(gtexture, texcoord) * vertexColor;
	if (texel.a < 0.1) discard;
	// Opaque and cutout casters: no tint. Translucent (stained glass, ice): light keeps their color.
	vec3 transmittance = texel.a > 0.99 ? vec3(1.0) : mix(vec3(1.0), srgbToLinear(texel.rgb), saturate(texel.a * 1.2));
	outShadowColor = vec4(transmittance, 1.0);
}

#endif
