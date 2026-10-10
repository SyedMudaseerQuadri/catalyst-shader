// Catalyst — screen-space reflections (M4: water; reusable for wet/glossy surfaces in M5).
//
// Ray-marches the reflected ray in view space with geometrically growing steps, projects each step to the screen
// and compares against the opaque depth (depthtex1: translucents excluded, so water never reflects itself).
// A hit is refined by bisection. Confidence fades near screen edges and for rays facing the camera, where
// screen space has no data; callers blend toward their sky/environment reflection by (1 - confidence).
// Requires: settings.glsl, core/common.glsl, core/uniforms.glsl, core/space.glsl.

#if !defined CATALYST_SSR
#define CATALYST_SSR

#if INTERNAL_TIER == TIER_LOW
	const int SSR_STEPS = 12;
#elif INTERNAL_TIER == TIER_MEDIUM
	const int SSR_STEPS = 16;
#elif INTERNAL_TIER == TIER_HIGH
	const int SSR_STEPS = 24;
#elif INTERNAL_TIER == TIER_ULTRA
	const int SSR_STEPS = 32;
#else
	const int SSR_STEPS = 40;
#endif
const int SSR_REFINE_STEPS = 4;

vec3 projectToScreen(vec3 viewPos) {
	vec4 clip = gbufferProjection * vec4(viewPos, 1.0);
	return clip.xyz / clip.w * 0.5 + 0.5;
}

// Returns rgb = reflected color, a = confidence 0..1.
vec4 screenSpaceReflection(vec3 viewPos, vec3 viewDir, sampler2D depthTex, sampler2D colorTex, float dither) {
	// Rays toward the camera leave the screen data almost at once.
	if (viewDir.z > 0.0 && viewPos.z + viewDir.z * 4.0 > -near) return vec4(0.0);

	float stepLength = 0.15 + 0.03 * length(viewPos);
	vec3 previous = viewPos;
	vec3 p = viewPos + viewDir * stepLength * (0.5 + dither);
	for (int i = 0; i < SSR_STEPS; i++) {
		vec3 screen = projectToScreen(p);
		if (p.z > -near || any(lessThan(screen.xy, vec2(0.0))) || any(greaterThan(screen.xy, vec2(1.0)))) break;
		float sceneDepth = texture(depthTex, screen.xy).r;
		float sceneDistance = linearizeDepth(sceneDepth);
		float rayDistance = -p.z;
		float thickness = max(stepLength * 1.5, 0.4);
		if (sceneDepth < 1.0 && rayDistance > sceneDistance && rayDistance - sceneDistance < thickness) {
			// Bisection between the last miss and this hit.
			vec3 lo = previous;
			vec3 hi = p;
			for (int j = 0; j < SSR_REFINE_STEPS; j++) {
				vec3 mid = 0.5 * (lo + hi);
				vec3 s = projectToScreen(mid);
				if (-mid.z > linearizeDepth(texture(depthTex, s.xy).r)) hi = mid; else lo = mid;
			}
			vec3 hit = projectToScreen(hi);
			vec2 edge = min(hit.xy, 1.0 - hit.xy);
			float confidence = smoothstep(0.0, 0.08, min(edge.x, edge.y))
			                 * (1.0 - smoothstep(0.25, 0.75, viewDir.z)); // toward the camera: unreliable
			return vec4(texture(colorTex, hit.xy).rgb, confidence);
		}
		previous = p;
		stepLength *= 1.30;
		p += viewDir * stepLength;
	}
	return vec4(0.0);
}

#endif
