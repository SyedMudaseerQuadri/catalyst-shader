// Catalyst — wind (APPROXIMATED input: Minecraft has no wind; docs/architecture/environment_state.md).
//
// Wind = weather-driven base strength x a gust envelope. The envelope is built from slow 1D value noise so it
// follows the aesthetic direction's pattern (mostly calm -> sudden gust -> settles -> stronger burst -> settles)
// instead of a monotonic ramp. Every consumer (foliage, clouds, water) reads the same functions, so a gust moves
// leaves, clouds and waves together.
// frameTimeCounter wraps every hour; the envelope then jumps once (accepted, documented in D-014).
// Requires: settings.glsl, core/common.glsl, core/uniforms.glsl, core/noise.glsl.

#if !defined CATALYST_WIND
#define CATALYST_WIND

#include "/lib/material/classify.glsl"

// Base wind 0..1 from weather: calm in clear weather, stronger in rain, strongest in thunderstorms.
float windBase() {
	return 0.25 + 0.40 * rainStrength + 0.35 * thunderStrength;
}

// Gust envelope 0..~1.6 over time (seconds). Two slow layers: frequent mild gusts, rarer strong bursts.
float windGust(float t) {
	float mild = smoothstep(0.45, 0.95, valueNoise1(t * 0.23));
	float burst = smoothstep(0.70, 1.00, valueNoise1(t * 0.071 + 31.0));
	return 0.55 + 0.45 * mild + 0.60 * burst;
}

// Current wind strength 0..~1.6.
float windStrength() {
	return windBase() * windGust(frameTimeCounter);
}

// Horizontal wind direction (unit, world XZ). Slowly veers so clouds and foliage never move on a fixed axis.
vec2 windDirection() {
	float angle = 0.6 + 0.8 * (valueNoise1(frameTimeCounter * 0.004) - 0.5);
	return vec2(cos(angle), sin(angle));
}

// Vertex offset (world units) for swaying vegetation.
// `anchor` 0..1: 0 at the rooted base of a plant (does not move), 1 at its free top; leaves use 1.
// `stiffness` scales the amplitude (large trees' leaves sway less than grass).
vec3 foliageWindOffset(vec3 worldPos, float anchor, float stiffness) {
	float strength = windStrength() * FOLIAGE_MOTION;
	if (strength <= 0.0 || anchor <= 0.0) return vec3(0.0);
	vec2 dir = windDirection();
	float t = frameTimeCounter;
	// Phase varies across space so neighboring plants do not move in lockstep; the wave travels downwind.
	float phase = dot(worldPos.xz, dir) * 0.35 + valueNoise2(worldPos.xz * 0.15) * 6.0;
	float sway = sin(t * 1.7 - phase) * 0.6 + sin(t * 3.1 - phase * 1.3) * 0.25;
	float flutter = sin(t * 7.3 + worldPos.x * 2.1 + worldPos.z * 1.7) * 0.15;
	// Leaning with the wind (steady push) plus oscillation around the leaned pose.
	float push = 0.35 + 0.65 * sway;
	vec3 offset = vec3(dir.x, 0.0, dir.y) * push * 0.09 + vec3(0.0, flutter * 0.03, 0.0);
	offset.xz += vec2(dir.y, -dir.x) * flutter * 0.04;
	return offset * strength * stiffness * anchor;
}

// Per material class (classify.glsl): plants sway from a rooted base; leaf blocks move as a whole, less.
// `isTopVertex`: the vertex lies on the upper edge of its sprite (texture v below the sprite center).
vec3 foliageWindOffsetFor(vec3 worldPos, int materialClass, bool isTopVertex) {
	if (materialClass == MAT_LEAVES) return foliageWindOffset(worldPos, 1.0, 0.45);
	return foliageWindOffset(worldPos, isTopVertex ? 1.0 : 0.0, 1.0);
}

#endif
