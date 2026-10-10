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
flat out int skipCaster;

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	// Water does not cast sun shadows (it transmits light; caustics/underwater light are M4).
	int materialClass = materialFromBlockId(int(mc_Entity.x + 0.5));
	skipCaster = materialClass == MAT_WATER ? 1 : 0;

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
flat in int skipCaster;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outShadowColor;

void main() {
	if (skipCaster == 1) discard;
	float alpha = texture(gtexture, texcoord).a;
	if (alpha < 0.1) discard;
	outShadowColor = vec4(1.0);
}

#endif
