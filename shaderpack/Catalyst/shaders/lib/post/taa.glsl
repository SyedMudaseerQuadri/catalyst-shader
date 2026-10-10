// Catalyst — temporal anti-aliasing (M2 temporal foundation, D-013).
//
// Every geometry pass offsets its projection by a sub-pixel jitter (Halton 2,3, 8 positions). The TAA pass
// (program/taa.glsl, composite1) reprojects each pixel into the previous frame with the previous camera
// matrices, samples the history with a Catmull-Rom filter, clips it to the current 3x3 neighborhood and blends.
//
// History is invalid (fully replaced by the current frame) when:
//   - the history buffer holds no data (alpha 0: first frame, resolution change, new dimension pipeline),
//   - the camera moved more than TAA_RESET_DISTANCE blocks in one frame (teleport, respawn, portal),
//   - the reprojected position is off-screen (newly revealed screen edge).
// Moving entities have no motion vectors yet; neighborhood clipping limits their ghosting.
// Requires lib/settings.glsl, lib/core/common.glsl, lib/core/uniforms.glsl.

#if !defined CATALYST_TAA
#define CATALYST_TAA

const int TAA_JITTER_COUNT = 8;
const float TAA_RESET_DISTANCE = 4.0; // blocks per frame; sprinting at 60 fps is ~0.1, elytra ~1.

// Halton(2,3) point i, centered on the pixel: each component in (-0.5, 0.5) pixels.
vec2 taaHalton(int i) {
	vec2 result = vec2(0.0);
	vec2 f = vec2(1.0);
	int a = i + 1;
	int b = i + 1;
	for (int k = 0; k < 4; k++) { // 4 digits cover indices up to 15 in base 2 and up to 80 in base 3
		f.x *= 0.5;
		result.x += f.x * float(a % 2);
		a /= 2;
		f.y /= 3.0;
		result.y += f.y * float(b % 3);
		b /= 3;
	}
	return result - 0.5;
}

// This frame's jitter in pixels. Zero when TAA is off or a debug view is shown (debug data stays unjittered).
vec2 taaJitterPixels() {
	vec2 jitter = vec2(0.0);
#ifdef TAA
	#if DEBUG_VIEW == 0
		jitter = taaHalton(frameCounter % TAA_JITTER_COUNT);
	#endif
#endif
	return jitter;
}

// Applies the jitter to a clip-space position (vertex stage of every geometry pass).
vec4 taaJitterClip(vec4 clipPos) {
	clipPos.xy += taaJitterPixels() * (2.0 / vec2(viewWidth, viewHeight)) * clipPos.w;
	return clipPos;
}

#if defined STAGE_FRAGMENT

// Working space for neighborhood statistics and blending: luminance-compressed YCoCg. Compressing by
// 1 / (1 + luma) (Karis 2014) keeps bright specular pixels from dominating, which removes most flicker.
vec3 taaEncode(vec3 hdr) {
	hdr /= 1.0 + luminance(hdr);
	return vec3(
		 0.25 * hdr.r + 0.5 * hdr.g + 0.25 * hdr.b,
		 0.5  * hdr.r               - 0.5  * hdr.b,
		-0.25 * hdr.r + 0.5 * hdr.g - 0.25 * hdr.b);
}

vec3 taaDecode(vec3 ycocg) {
	vec3 rgb = vec3(
		ycocg.x + ycocg.y - ycocg.z,
		ycocg.x           + ycocg.z,
		ycocg.x - ycocg.y - ycocg.z);
	rgb = max(rgb, 0.0);
	return rgb / max(1.0 - luminance(rgb), 1e-3);
}

// Catmull-Rom history sample from 5 bilinear taps (corners dropped; their weight is negligible).
// Keeps the resolved image sharp where plain bilinear history would soften it each frame.
vec3 taaSampleHistory(sampler2D history, vec2 uv, vec2 texSize) {
	vec2 samplePos = uv * texSize;
	vec2 center = floor(samplePos - 0.5) + 0.5;
	vec2 f = samplePos - center;

	vec2 w0 = f * (-0.5 + f * (1.0 - 0.5 * f));
	vec2 w1 = 1.0 + f * f * (-2.5 + 1.5 * f);
	vec2 w2 = f * (0.5 + f * (2.0 - 1.5 * f));
	vec2 w3 = f * f * (-0.5 + 0.5 * f);
	vec2 w12 = w1 + w2;
	vec2 offset12 = w2 / w12;

	vec2 texel = 1.0 / texSize;
	vec2 uv0 = (center - 1.0) * texel;
	vec2 uv3 = (center + 2.0) * texel;
	vec2 uv12 = (center + offset12) * texel;

	vec3 result = texture(history, vec2(uv12.x, uv0.y)).rgb * (w12.x * w0.y)
	            + texture(history, vec2(uv0.x, uv12.y)).rgb * (w0.x * w12.y)
	            + texture(history, uv12).rgb                * (w12.x * w12.y)
	            + texture(history, vec2(uv3.x, uv12.y)).rgb * (w3.x * w12.y)
	            + texture(history, vec2(uv12.x, uv3.y)).rgb * (w12.x * w3.y);
	float weight = w12.x * w0.y + w0.x * w12.y + w12.x * w12.y + w3.x * w12.y + w12.x * w3.y;
	return max(result / weight, 0.0); // Catmull-Rom lobes can ring below zero
}

// Moves `history` toward the box center until it lies inside the box (clip, not clamp: preserves hue).
vec3 taaClipToBox(vec3 history, vec3 boxMin, vec3 boxMax) {
	vec3 center = 0.5 * (boxMax + boxMin);
	vec3 extent = 0.5 * (boxMax - boxMin) + 1e-5;
	vec3 offset = history - center;
	vec3 units = abs(offset / extent);
	float maxUnit = max(units.x, max(units.y, units.z));
	return maxUnit > 1.0 ? center + offset / maxUnit : history;
}

#endif
#endif
