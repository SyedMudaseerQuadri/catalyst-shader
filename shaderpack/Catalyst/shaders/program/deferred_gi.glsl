// Catalyst — deferred (first pass): screen-space ambient occlusion, global illumination and glossy reflections on
// the opaque, already-lit scene (M5, D-016). The second deferred pass (deferred_sky.glsl) then adds sky and clouds.
//
// The forward lighting assumed every surface sees open surroundings for its indirect light. Here each pixel casts a
// few cosine-distributed rays through the depth buffer:
//   - a ray that hits nearby geometry means that direction was occluded: the stored indirect diffuse light
//     (colortex6.rgb) is reduced by that share (AO), and
//   - the radiance of the surface it hit (colortex0, already lit by sun, sky and blocks) is gathered as bounce light
//     (GI) - this is where color bleeding and the warm glow around lava or a sunlit floor come from.
// Glossy surfaces (puddles, wet stone, polished LabPBR materials) swap their sky reflection for the reflected
// terrain where screen space has it.
// Known limitation (catalyst_architecture.md, GI strategy): only on-screen, visible geometry contributes; light from
// off-screen or hidden surfaces is missed, and thin objects can leak slightly at edges. Accepted for this method.

#include "/lib/settings.glsl"
#include "/lib/core/common.glsl"
#include "/lib/core/uniforms.glsl"
#include "/lib/core/space.glsl"
#include "/lib/core/buffers.glsl"
#include "/lib/core/encode.glsl"
#include "/lib/material/classify.glsl"

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

#include "/lib/environment/state.glsl"
#include "/lib/atmosphere/sky.glsl"
#include "/lib/lighting/specular.glsl"
#include "/lib/lighting/forward.glsl"
#include "/lib/lighting/ssr.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex6;
uniform sampler2D depthtex0;

in vec2 uv;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

#if INTERNAL_TIER == TIER_LOW
	const int GI_RAYS = 2;  const int GI_STEPS = 6;  const float GI_RADIUS = 2.5;
#elif INTERNAL_TIER == TIER_MEDIUM
	const int GI_RAYS = 3;  const int GI_STEPS = 8;  const float GI_RADIUS = 3.5;
#elif INTERNAL_TIER == TIER_HIGH
	const int GI_RAYS = 4;  const int GI_STEPS = 10; const float GI_RADIUS = 4.5;
#elif INTERNAL_TIER == TIER_ULTRA
	// Ultra/Extreme are reserved for voxel GI (M6, deferred until measured evidence); until then they run
	// screen-space GI with more rays.
	const int GI_RAYS = 6;  const int GI_STEPS = 12; const float GI_RADIUS = 6.0;
#else
	const int GI_RAYS = 8;  const int GI_STEPS = 14; const float GI_RADIUS = 8.0;
#endif
const float AO_RADIUS = 1.2; // blocks: hits farther than this occlude progressively less

void main() {
	vec4 scene = texture(colortex0, uv);
	float depth = texture(depthtex0, uv).r;
	vec4 normalLight = texture(colortex1, uv);
	// Sky, the hand (its own projection) and pixels without G-buffer data pass through.
	if (depth >= 1.0 || depth < 0.5 + 0.5 * MC_HAND_DEPTH || normalLight.a < 0.5) {
		outColor = scene;
		return;
	}

	vec3 viewPos = viewFromScreen(vec3(uv, depth));
	vec3 normalPlayer = decodeNormal(normalLight.rg);
	vec3 normalView = normalize(mat3(gbufferModelView) * normalPlayer);
	vec4 indirect = texture(colortex6, uv);
	vec3 color = scene.rgb;
	float noiseA = interleavedGradientNoise(gl_FragCoord.xy + 5.588238 * float(frameCounter % 64));
	float noiseB = interleavedGradientNoise(gl_FragCoord.yx * 1.37 + 11.3 + 7.31 * float(frameCounter % 64));

#ifdef SCREEN_SPACE_GI
	vec3 tangent = normalize(cross(abs(normalView.y) < 0.99 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0), normalView));
	vec3 bitangent = cross(normalView, tangent);
	vec3 origin = viewPos + normalView * 0.03 * max(1.0, -viewPos.z * 0.02);
	float stepLength = GI_RADIUS / float(GI_STEPS);

	vec3 gathered = vec3(0.0);
	float occlusion = 0.0;
	for (int i = 0; i < GI_RAYS; i++) {
		// Cosine-weighted hemisphere direction (pdf cancels the cosine: the mean radiance is the irradiance).
		float r1 = fract(noiseA + float(i) * 0.618034);
		float r2 = fract(noiseB + float(i) * 0.414214);
		float phi = TAU * r1;
		float sinTheta = sqrt(r2);
		vec3 dir = tangent * (cos(phi) * sinTheta) + bitangent * (sin(phi) * sinTheta) + normalView * sqrt(1.0 - r2);

		for (int j = 0; j < GI_STEPS; j++) {
			float t = (float(j) + 0.5 + 0.5 * r2) * stepLength;
			vec3 q = origin + dir * t;
			vec3 s = projectToScreen(q);
			if (q.z > -near || any(lessThan(s.xy, vec2(0.0))) || any(greaterThan(s.xy, vec2(1.0)))) break;
			float sceneDepth = texture(depthtex0, s.xy).r;
			if (sceneDepth >= 1.0) continue;
			float sceneDistance = linearizeDepth(sceneDepth);
			float rayDistance = -q.z;
			if (rayDistance > sceneDistance + 0.02 && rayDistance - sceneDistance < max(stepLength * 2.0, 0.5)) {
				occlusion += 1.0 - smoothstep(0.0, AO_RADIUS, t);
				// Only the side of the hit surface facing back along the ray emits toward us.
				vec3 hitNormal = mat3(gbufferModelView) * decodeNormal(texture(colortex1, s.xy).rg);
				if (dot(hitNormal, dir) < 0.0) gathered += texture(colortex0, s.xy).rgb;
				break;
			}
		}
	}
	gathered /= float(GI_RAYS);
	float ao = 1.0 - occlusion / float(GI_RAYS);

	// AO: the indirect light computed for open surroundings is removed for the occluded share.
	color -= indirect.rgb * (1.0 - ao) * AO_STRENGTH;
	// GI: the occluded directions return the light of the surfaces that occlude them.
	vec3 albedo = srgbToLinear(texture(colortex2, uv).rgb);
	color += albedo * gathered * GI_STRENGTH;
#endif

#ifdef GLOSSY_REFLECTIONS
	// Glossy surfaces: replace the sky reflection by the reflected scene where screen space knows it.
	float smoothness = texture(colortex3, uv).b;
	float reflectionWeight = indirect.a < 0.75 ? indirect.a * 2.0 : 0.0;
	if (smoothness > 0.55 && reflectionWeight > 0.001) {
		vec3 reflectView = reflect(normalize(viewPos), normalView);
		vec4 hit = screenSpaceReflection(viewPos, reflectView, depthtex0, colortex0, noiseA);
		if (hit.a > 0.0) {
			vec3 skyReflection = vec3(0.0);
		#if defined DIM_OVERWORLD
			EnvState env = getEnvState();
			float alpha = max(sqr(1.0 - smoothness), MIN_ROUGHNESS);
			vec3 reflectPlayer = mat3(gbufferModelViewInverse) * reflectView;
			reflectPlayer = normalize(mix(reflectPlayer, normalPlayer, alpha * alpha));
			skyReflection = mix(skyRadiance(reflectPlayer, env), env.skyAmbient, alpha)
			              * skyLightFalloff(unpackLightmap(normalLight.b).y);
		#endif
			float glossFade = smoothstep(0.55, 0.75, smoothness);
			color += reflectionWeight * (hit.rgb - skyReflection) * hit.a * glossFade;
		}
	}
#endif

	outColor = vec4(max(color, 0.0), scene.a);
}

#endif
