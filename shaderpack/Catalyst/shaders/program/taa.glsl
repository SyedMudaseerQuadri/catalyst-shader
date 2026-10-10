// Catalyst — composite1: temporal anti-aliasing resolve (lib/post/taa.glsl). Runs on the fogged HDR scene,
// before exposure and tonemapping in final. Writes the resolved scene to colortex0 and the new history to colortex4.

#include "/lib/settings.glsl"
#include "/lib/core/common.glsl"
#include "/lib/core/uniforms.glsl"
#include "/lib/core/space.glsl"
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

#include "/lib/post/taa.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex4;
uniform sampler2D depthtex0;

in vec2 uv;

/* RENDERTARGETS: 0,4 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outHistory;

// Blend weight of the current frame: low when still (more accumulation), higher in fast motion
// where reprojected history is less reliable.
const float TAA_CURRENT_WEIGHT_STILL  = 0.10;
const float TAA_CURRENT_WEIGHT_MOTION = 0.25;
const float TAA_CURRENT_WEIGHT_HAND   = 0.25;
// Hand pixels: Iris scales the hand's projected depth by MC_HAND_DEPTH around the screen-depth center.
const float TAA_HAND_DEPTH_LIMIT = 0.5 + 0.5 * MC_HAND_DEPTH;

// Screen position of the same surface point in the previous frame.
vec2 reprojectToPreviousFrame(vec2 screenUv, float depth) {
	vec3 viewPos = viewFromScreen(vec3(screenUv, depth));
	vec4 previousView;
	if (depth >= 1.0) {
		// Sky: direction only, camera translation does not move it.
		previousView = vec4(mat3(gbufferPreviousModelView) * playerDirFromView(viewPos), 0.0);
	} else {
		vec3 playerPos = playerFromView(viewPos) + (cameraPosition - previousCameraPosition);
		previousView = gbufferPreviousModelView * vec4(playerPos, 1.0);
	}
	vec4 previousClip = gbufferPreviousProjection * previousView;
	return previousClip.xy / previousClip.w * 0.5 + 0.5;
}

void main() {
	vec2 texSize = vec2(viewWidth, viewHeight);
	vec2 texel = 1.0 / texSize;
	vec3 current = texture(colortex0, uv).rgb;
	float depth = texture(depthtex0, uv).r;
	bool isHand = depth < TAA_HAND_DEPTH_LIMIT;

	// This pixel's sample came from (uv - jitter) in unjittered screen space.
	vec2 unjitteredUv = uv - taaJitterPixels() * texel;
	vec2 previousUv = isHand ? uv : reprojectToPreviousFrame(unjitteredUv, depth);

	vec4 historySample = texture(colortex4, previousUv);
	bool valid = historySample.a > 0.5
	          && all(greaterThanEqual(previousUv, vec2(0.0))) && all(lessThanEqual(previousUv, vec2(1.0)))
	          && distance(cameraPosition, previousCameraPosition) < TAA_RESET_DISTANCE;

	vec3 resolved = current;
	if (valid) {
		// Current 3x3 neighborhood: mean +- 1 standard deviation, intersected with its min/max box.
		vec3 m1 = vec3(0.0);
		vec3 m2 = vec3(0.0);
		vec3 boxMin = vec3(1e9);
		vec3 boxMax = vec3(-1e9);
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				vec3 c = taaEncode(texture(colortex0, uv + vec2(x, y) * texel).rgb);
				m1 += c;
				m2 += c * c;
				boxMin = min(boxMin, c);
				boxMax = max(boxMax, c);
			}
		}
		m1 /= 9.0;
		vec3 sigma = sqrt(max(m2 / 9.0 - m1 * m1, 0.0));
		boxMin = max(boxMin, m1 - sigma);
		boxMax = min(boxMax, m1 + sigma);

		vec3 history = taaClipToBox(taaEncode(taaSampleHistory(colortex4, previousUv, texSize)), boxMin, boxMax);

		float motionPixels = length((previousUv - uv) * texSize);
		float currentWeight = isHand ? TAA_CURRENT_WEIGHT_HAND
		                             : mix(TAA_CURRENT_WEIGHT_STILL, TAA_CURRENT_WEIGHT_MOTION, saturate(motionPixels / 8.0));
		resolved = taaDecode(mix(history, taaEncode(current), currentWeight));
	}

	// Never let a bad value enter the history (it would persist for many frames).
	if (any(isnan(resolved)) || any(isinf(resolved))) resolved = current;

	outColor = vec4(resolved, 1.0);
	outHistory = vec4(resolved, 1.0);
}

#endif
