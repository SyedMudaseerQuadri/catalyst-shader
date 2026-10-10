// Catalyst — volumetric clouds, cirrus and cloud shadows (M3, D-014).
//
// Two scales (aesthetic direction: "multiple scales simultaneously"):
//   cumulus: a ray-marched slab from the vanilla cloud altitude (Iris `cloudHeight`) up CUMULUS_THICKNESS blocks.
//            Shape = weather-driven 2D coverage field x height profile, eroded by 3D detail noise.
//   cirrus : a thin 2D layer high above, streaked along the wind.
// Coverage comes from EnvState.cloudCover (visual preset + user slider + rain/thunder), so clouds thicken before
// rain, darken in storms and break up as weather clears, in step with sky, fog and light.
// Lighting: single scattering of sun/moon light with a short light march, a two-lobe Henyey-Greenstein phase,
// a multiple-scattering approximation (attenuated optical-depth octave), and sky ambient that grows with height.
// Cloud shadows sample the SAME coverage field along the light direction, so shadows match the visible clouds.
// Drift is a constant velocity (integrating a varying wind speed over frameTimeCounter would make clouds jump).
// Requires: settings.glsl, core/common.glsl, core/uniforms.glsl, core/noise.glsl, environment/state.glsl,
//           atmosphere/sky.glsl.

#if !defined CATALYST_CLOUDS
#define CATALYST_CLOUDS

const float CUMULUS_THICKNESS = 120.0;     // blocks
const float CUMULUS_EXTINCTION = 0.075;    // per block at full density
const float CUMULUS_FEATURE_SIZE = 520.0;  // blocks per coverage-noise unit
const float CLOUD_MAX_DISTANCE = 9000.0;   // blocks; beyond this clouds have faded into the horizon haze
const float CLOUD_HAZE_DISTANCE = 5000.0;  // e-folding distance of the aerial-perspective fade
const float CIRRUS_ALTITUDE_ABOVE = 1400.0;
const vec2 CLOUD_DRIFT = vec2(2.6, 0.9);   // blocks per second, roughly along the mean wind direction

#if INTERNAL_TIER == TIER_LOW
	const int CLOUD_STEPS = 10;
	const int CLOUD_LIGHT_STEPS = 3;
#elif INTERNAL_TIER == TIER_MEDIUM
	const int CLOUD_STEPS = 14;
	const int CLOUD_LIGHT_STEPS = 4;
#elif INTERNAL_TIER == TIER_HIGH
	const int CLOUD_STEPS = 20;
	const int CLOUD_LIGHT_STEPS = 4;
#elif INTERNAL_TIER == TIER_ULTRA
	const int CLOUD_STEPS = 28;
	const int CLOUD_LIGHT_STEPS = 5;
#else
	const int CLOUD_STEPS = 40;
	const int CLOUD_LIGHT_STEPS = 6;
#endif

float cumulusBottom() { return cloudHeight; }
float cumulusTop()    { return cloudHeight + CUMULUS_THICKNESS; }

vec2 cloudDriftOffset() { return CLOUD_DRIFT * frameTimeCounter; }

// Henyey-Greenstein relative to isotropic (1 = isotropic).
float phaseRelative(float cosTheta, float g) {
	float g2 = g * g;
	return (1.0 - g2) / pow(max(1.0 + g2 - 2.0 * g * cosTheta, 1e-4), 1.5);
}

// Weather coverage field 0..1 at world XZ: where clouds exist and how developed they are.
float cumulusCoverage(vec2 worldXZ, float cover) {
	vec2 p = (worldXZ + cloudDriftOffset()) / CUMULUS_FEATURE_SIZE;
	float n = fbm2(p, 4);
	// cover 0 -> no clouds, 1 -> fully overcast. The threshold window keeps edges soft.
	float threshold = 1.0 - cover;
	return smoothstep(threshold - 0.08, threshold + 0.22, n);
}

// Density 0..1 at a world position. `detail` toggles the 3D erosion (skipped in light marches).
float cumulusDensity(vec3 worldPos, float cover, bool detail) {
	float h = (worldPos.y - cumulusBottom()) / CUMULUS_THICKNESS;
	if (h <= 0.0 || h >= 1.0) return 0.0;
	float base = cumulusCoverage(worldPos.xz, cover);
	if (base <= 0.0) return 0.0;
	// Developed areas grow taller; flat bases, rounded tops.
	float topHeight = 0.30 + 0.70 * base;
	float profile = smoothstep(0.0, 0.10, h) * (1.0 - smoothstep(topHeight * 0.55, topHeight, h));
	float d = base * profile;
	if (detail && d > 0.0) {
		vec3 q = (worldPos + vec3(cloudDriftOffset().x, 0.0, cloudDriftOffset().y) * 1.3) * 0.022;
		float erosion = fbm3(q, 2);
		d = saturate((d - (1.0 - erosion) * 0.45 * (1.0 - d * 0.5)) * 1.6);
	}
	return d;
}

// Optical depth toward the light from `worldPos` (coarse march with growing steps).
float cumulusLightDepth(vec3 worldPos, vec3 lightDir, float cover) {
	float depth = 0.0;
	float stepLength = 6.0;
	vec3 p = worldPos;
	for (int i = 0; i < CLOUD_LIGHT_STEPS; i++) {
		p += lightDir * stepLength;
		depth += cumulusDensity(p, cover, false) * stepLength;
		stepLength *= 1.9;
	}
	return depth * CUMULUS_EXTINCTION;
}

// Direct light reaching the ground through the cumulus layer at player-space position `playerPos` (0..1).
float cloudShadow(vec3 playerPos, EnvState env) {
#if CLOUD_STYLE == 2 && defined DIM_OVERWORLD
	vec3 worldPos = playerPos + cameraPosition;
	if (env.lightDir.y <= 0.02) return 1.0;
	float midAltitude = cumulusBottom() + CUMULUS_THICKNESS * 0.3;
	float t = (midAltitude - worldPos.y) / env.lightDir.y;
	if (t <= 0.0) return 1.0;
	vec3 hit = worldPos + env.lightDir * t;
	float coverage = cumulusCoverage(hit.xz, env.cloudCover);
	// Path length through a cloud of that coverage, along the slanted light ray.
	float path = CUMULUS_THICKNESS * (0.3 + 0.7 * coverage) * 0.5 / env.lightDir.y;
	float transmittance = exp(-coverage * CUMULUS_EXTINCTION * path);
	// Light scattered forward through thin clouds keeps shadows from going fully black.
	return mix(1.0, max(transmittance, 0.18), CLOUD_SHADOW_STRENGTH);
#else
	return 1.0;
#endif
}

// Light sources for cloud lighting: direct (sun or moon, without the overcast attenuation that represents
// these very clouds) and ambient from the sky dome above and the ground below.
struct CloudLighting {
	vec3 direct;
	vec3 lightDir;
	vec3 ambientTop;
	vec3 ambientBottom;
};

CloudLighting getCloudLighting(EnvState env) {
	CloudLighting cl;
	bool sunIsCaster = dot(env.lightDir, env.sunDir) > 0.0;
	cl.direct = (sunIsCaster ? env.sunRadiance : env.moonRadiance) * (1.0 - 0.6 * env.storm);
	cl.lightDir = env.lightDir;
	vec3 skyTop = skyRadiance(vec3(0.0, 1.0, 0.0), env);
	cl.ambientTop = skyTop * 1.1 + env.skyAmbient * 0.35 + env.lightningFlash * vec3(0.8, 0.85, 1.0) * 2.5;
	cl.ambientBottom = env.skyAmbient * 0.25 + env.lightRadiance * 0.04 + env.lightningFlash * vec3(0.8, 0.85, 1.0) * 1.2;
	return cl;
}

// Ray-marches the cumulus layer along `dir` (player space, unit) up to `maxDistance` blocks.
// Returns rgb = in-scattered radiance, a = transmittance of whatever lies behind.
vec4 renderCumulus(vec3 dir, float maxDistance, EnvState env, float dither) {
	vec3 origin = cameraPosition;
	float bottom = cumulusBottom();
	float top = cumulusTop();

	float tStart, tEnd;
	if (abs(dir.y) < 1e-4) {
		if (origin.y <= bottom || origin.y >= top) return vec4(0.0, 0.0, 0.0, 1.0);
		tStart = 0.0;
		tEnd = CLOUD_MAX_DISTANCE;
	} else {
		float tBottom = (bottom - origin.y) / dir.y;
		float tTop = (top - origin.y) / dir.y;
		tStart = max(min(tBottom, tTop), 0.0);
		tEnd = max(tBottom, tTop);
	}
	tEnd = min(min(tEnd, tStart + 3000.0), min(maxDistance, CLOUD_MAX_DISTANCE));
	if (tEnd <= tStart) return vec4(0.0, 0.0, 0.0, 1.0);

	CloudLighting cl = getCloudLighting(env);
	float cosTheta = dot(dir, cl.lightDir);
	// Forward lobe (silver lining) + back lobe; mostly forward like real cloud droplets.
	float phase = mix(phaseRelative(cosTheta, 0.60), phaseRelative(cosTheta, -0.25), 0.30);
	float extinction = CUMULUS_EXTINCTION * (1.0 + 0.8 * env.storm);

	float stepLength = (tEnd - tStart) / float(CLOUD_STEPS);
	float t = tStart + stepLength * dither;
	vec3 scattered = vec3(0.0);
	float transmittance = 1.0;
	float firstHit = -1.0;

	for (int i = 0; i < CLOUD_STEPS; i++) {
		vec3 p = origin + dir * t;
		float density = cumulusDensity(p, env.cloudCover, true);
		if (density > 0.002) {
			if (firstHit < 0.0) firstHit = t;
			float sigma = density * extinction;
			float lightDepth = cumulusLightDepth(p, cl.lightDir, env.cloudCover) * (1.0 + 0.8 * env.storm);
			// Multiple scattering: a second, weaker octave with reduced optical depth (light diffusing through).
			float lightT = max(exp(-lightDepth), 0.70 * exp(-lightDepth * 0.20));
			float h = saturate((p.y - bottom) / CUMULUS_THICKNESS);
			vec3 ambient = mix(cl.ambientBottom, cl.ambientTop, h);
			vec3 sourceRadiance = cl.direct * lightT * phase + ambient;
			float stepT = exp(-sigma * stepLength);
			scattered += transmittance * sourceRadiance * (1.0 - stepT);
			transmittance *= stepT;
			if (transmittance < 0.02) break;
		}
		t += stepLength;
	}

	if (firstHit < 0.0) return vec4(0.0, 0.0, 0.0, 1.0);
	// Aerial perspective: distant clouds fade into the horizon.
	float fade = exp(-firstHit / CLOUD_HAZE_DISTANCE);
	return vec4(scattered * fade, mix(1.0, transmittance, fade));
}

// Thin high cirrus. Returns rgb = radiance, a = transmittance (rarely below 0.6: cirrus is thin).
vec4 renderCirrus(vec3 dir, EnvState env) {
	if (dir.y <= 0.01) return vec4(0.0, 0.0, 0.0, 1.0);
	float altitude = cumulusBottom() + CIRRUS_ALTITUDE_ABOVE;
	float t = (altitude - cameraPosition.y) / dir.y;
	if (t <= 0.0 || t > 40000.0) return vec4(0.0, 0.0, 0.0, 1.0);
	vec2 p = cameraPosition.xz + dir.xz * t + cloudDriftOffset() * 3.0;
	// Streaks: stretch the noise along the drift direction.
	vec2 along = normalize(CLOUD_DRIFT);
	vec2 q = vec2(dot(p, along) * 0.00035, dot(p, vec2(-along.y, along.x)) * 0.0016);
	float n = fbm2(q, 4);
	float amount = smoothstep(0.52, 0.85, n) * (0.35 + 0.65 * env.cloudCover) * (1.0 - 0.8 * env.overcast);
	float opacity = amount * 0.55 * exp(-t / 30000.0);
	if (opacity <= 0.0) return vec4(0.0, 0.0, 0.0, 1.0);
	CloudLighting cl = getCloudLighting(env);
	vec3 radiance = cl.direct * (0.25 + 0.20 * phaseRelative(dot(dir, cl.lightDir), 0.70)) + cl.ambientTop * 0.8;
	return vec4(radiance * opacity, 1.0 - opacity);
}

// Cheap cloud look-up for reflections (water): one coverage sample where the ray meets the layer's middle,
// shaded flat. Positions match the real clouds, detail and self-shadowing do not.
vec3 approximateCloudReflection(vec3 background, vec3 dir, EnvState env) {
#if CLOUD_STYLE == 2 && defined DIM_OVERWORLD
	if (dir.y <= 0.02) return background;
	float t = (cumulusBottom() + CUMULUS_THICKNESS * 0.4 - cameraPosition.y) / dir.y;
	if (t <= 0.0) return background;
	float coverage = cumulusCoverage(cameraPosition.xz + dir.xz * t, env.cloudCover);
	CloudLighting cl = getCloudLighting(env);
	vec3 cloudColor = cl.direct * 0.45 * (0.6 + 0.4 * phaseRelative(dot(dir, cl.lightDir), 0.5)) + cl.ambientTop * 0.9;
	float opacity = smoothstep(0.05, 0.6, coverage) * 0.9 * exp(-t / CLOUD_HAZE_DISTANCE);
	return mix(background, cloudColor, opacity);
#else
	return background;
#endif
}

// Composites both layers over `background` (sky or distant terrain) for a view ray.
vec3 applyClouds(vec3 background, vec3 dir, float maxDistance, EnvState env, float dither) {
#if CLOUD_STYLE == 2 && defined DIM_OVERWORLD
	vec3 color = background;
	if (maxDistance > 1e5) {
		vec4 cirrus = renderCirrus(dir, env);
		color = color * cirrus.a + cirrus.rgb;
	}
	vec4 cumulus = renderCumulus(dir, maxDistance, env, dither);
	return color * cumulus.a + cumulus.rgb;
#else
	return background;
#endif
}

#endif
