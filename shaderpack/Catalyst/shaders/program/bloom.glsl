// Catalyst — composite2: bloom (M5, D-016). Builds a wide, smooth glow from the mipmap chain of the resolved HDR
// scene (Iris generates colortex0's mipmaps for this pass): a 3x3 tent filter at each of six mip levels, summed
// with weights falling off by size. Final mixes a small, constant share of it into the image.

#include "/lib/settings.glsl"
#include "/lib/core/common.glsl"
#include "/lib/core/uniforms.glsl"
#include "/lib/core/buffers.glsl"

// =============================================================================================
#if defined STAGE_VERTEX

out vec2 uv;

void main() {
	uv = gl_MultiTexCoord0.xy;
	gl_Position = ftransform();
}

#endif
// =============================================================================================
#if defined STAGE_FRAGMENT

const bool colortex0MipmapEnabled = true;

uniform sampler2D colortex0;

in vec2 uv;

/* RENDERTARGETS: 7 */
layout(location = 0) out vec4 outBloom;

vec3 tentSample(float lod) {
	vec2 texel = exp2(lod) / vec2(viewWidth, viewHeight);
	vec3 sum = textureLod(colortex0, uv, lod).rgb * 4.0;
	sum += (textureLod(colortex0, uv + vec2(texel.x, 0.0), lod).rgb + textureLod(colortex0, uv - vec2(texel.x, 0.0), lod).rgb
	      + textureLod(colortex0, uv + vec2(0.0, texel.y), lod).rgb + textureLod(colortex0, uv - vec2(0.0, texel.y), lod).rgb) * 2.0;
	sum += textureLod(colortex0, uv + texel, lod).rgb + textureLod(colortex0, uv - texel, lod).rgb
	     + textureLod(colortex0, uv + vec2(texel.x, -texel.y), lod).rgb + textureLod(colortex0, uv + vec2(-texel.x, texel.y), lod).rgb;
	return sum / 16.0;
}

void main() {
	const float WEIGHTS[6] = float[6](0.28, 0.24, 0.18, 0.13, 0.10, 0.07);
	vec3 bloom = vec3(0.0);
	for (int i = 0; i < 6; i++) {
		bloom += tentSample(float(i + 1)) * WEIGHTS[i];
	}
	outBloom = vec4(max(bloom, 0.0), 1.0);
}

#endif
