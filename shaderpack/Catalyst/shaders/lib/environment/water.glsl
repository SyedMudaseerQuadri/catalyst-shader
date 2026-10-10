// Catalyst — water model shared by the water surface, puddles, underwater lighting and the underwater view (M4, D-015).
//
// Optics (per block = 1 m): pure water absorbs red strongly and blue weakly; the biome's vanilla water color
// (vertex tint) adds dissolved matter/sediment: murky swamp water absorbs and scatters more and looks green-brown.
// Waves: a height field of wind-aligned swells plus moving noise, with amplitude from the shared wind and weather
// (calm -> ripples -> windy -> stormy). Normals come from finite differences, never vertex displacement (no gaps,
// stable under TAA). Rain adds expanding ring ripples on exposed water and puddles.
// Requires: settings.glsl, core/common.glsl, core/uniforms.glsl, core/noise.glsl, environment/wind.glsl.

#if !defined CATALYST_WATER
#define CATALYST_WATER

const vec3 WATER_ABSORPTION_CLEAR = vec3(0.34, 0.070, 0.030);  // per block
const vec3 WATER_SCATTERING_CLEAR = vec3(0.004, 0.012, 0.016); // per block, bluish
const float WATER_IOR = 1.333;
const float WATER_F0_SURFACE = 0.02;
// Vanilla's default water color (#3F76E4, sRGB): used where the biome tint is not available (light under water).
const vec3 VANILLA_WATER_COLOR = vec3(0.247, 0.463, 0.894);

struct WaterOptics {
	vec3 absorption;
	vec3 scattering;
	vec3 extinction;
};

// `biomeTint`: vanilla water color (sRGB, from the vertex color). Neutral (blue ~ (0.25,0.46,0.89)) for oceans,
// darker green-brown in swamps. Deviation from the clear-water hue raises absorption and scattering.
WaterOptics waterOptics(vec3 biomeTint) {
	vec3 tint = srgbToLinear(clamp(biomeTint, 0.0, 1.0));
	tint /= max(max(tint.r, max(tint.g, tint.b)), 1e-3);
	// Sediment: colors far from blue absorb blue and scatter their own hue.
	float murk = saturate(1.0 - tint.b);
	WaterOptics o;
	o.absorption = (WATER_ABSORPTION_CLEAR + murk * vec3(0.05, 0.08, 0.20)) * WATER_TURBIDITY;
	o.scattering = (WATER_SCATTERING_CLEAR + murk * 0.06 * tint) * WATER_TURBIDITY;
	o.extinction = o.absorption + o.scattering;
	return o;
}

// Wave amplitude 0..1 from wind and weather.
float waveIntensity() {
	return saturate(0.18 + 0.45 * windBase() + 0.25 * thunderStrength) * WATER_WAVE_STRENGTH;
}

float waterHeight(vec2 xz, float t) {
	vec2 dir = windDirection();
	vec2 perp = vec2(-dir.y, dir.x);
	float along = dot(xz, dir);
	float across = dot(xz, perp);
	// Swells: a few long wind-aligned waves, slightly off-axis so they do not look like corrugation.
	float h = sin(along * 0.55 - t * 1.30 + across * 0.12) * 0.40
	        + sin(along * 0.93 - t * 1.85 - across * 0.31) * 0.25
	        + sin(along * 1.71 - t * 2.60 + across * 0.47) * 0.12;
	// Chop: moving noise, finer.
	h += (valueNoise2(xz * 1.3 - dir * t * 0.9) - 0.5) * 0.35;
	h += (valueNoise2(xz * 3.1 + perp * t * 0.6) - 0.5) * 0.15;
	return h;
}

// Expanding ring ripples from raindrops. Returns a gradient (dHeight/dx, dHeight/dz).
vec2 rainRippleGradient(vec2 xz, float t, float intensity) {
	if (intensity <= 0.0) return vec2(0.0);
	vec2 gradient = vec2(0.0);
	for (int layer = 0; layer < 2; layer++) {
		vec2 p = xz * 2.6 + float(layer) * 17.3;
		vec2 cell = floor(p);
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				ivec2 c = ivec2(cell) + ivec2(x, y);
				vec2 center = vec2(c) + vec2(hash21(c), hash21(c + ivec2(57, 113)));
				float period = 0.9 + 0.5 * hash21(c + ivec2(19, 7));
				float age = fract(t / period + hash21(c + ivec2(3, 41)));
				// Only some cells get a drop in each period: more in heavier rain.
				if (hash21(c + ivec2(int(t / period), 5)) > intensity) continue;
				vec2 d = p - center;
				float dist = length(d);
				float radius = age * 0.9;
				float ring = sin((dist - radius) * 18.0) * smoothstep(0.18, 0.0, abs(dist - radius)) * (1.0 - age);
				gradient += (dist > 1e-4 ? d / dist : vec2(0.0)) * ring;
			}
		}
	}
	return gradient * 0.35;
}

// Shading normal for an upward-facing water (or puddle) surface at world XZ.
vec3 waterSurfaceNormal(vec2 xz, float rainExposure) {
	float t = frameTimeCounter;
	const float e = 0.08;
	float amp = waveIntensity() * 0.18;
	float h0 = waterHeight(xz, t);
	float hx = waterHeight(xz + vec2(e, 0.0), t);
	float hz = waterHeight(xz + vec2(0.0, e), t);
	vec2 gradient = vec2(hx - h0, hz - h0) / e * amp;
	gradient += rainRippleGradient(xz, t, rainStrength * rainExposure);
	return normalize(vec3(-gradient.x, 1.0, -gradient.y));
}

// Caustic brightness pattern (mean ~1) on surfaces lit through water. `depth`: blocks of water above.
float causticPattern(vec3 worldPos, float depth) {
	float t = frameTimeCounter;
	vec2 p = worldPos.xz + worldPos.y * 0.3;
	float n1 = valueNoise2(p * 1.4 + vec2(t * 0.35, t * 0.21));
	float n2 = valueNoise2(p * 1.9 - vec2(t * 0.27, -t * 0.31) + 7.1);
	// Bright thin lines where the two ridged fields cross; focus sharpens near the surface and blurs with depth.
	float ridges = (1.0 - abs(n1 * 2.0 - 1.0)) * (1.0 - abs(n2 * 2.0 - 1.0));
	float sharpness = mix(6.0, 2.0, saturate(depth / 8.0));
	// Normalized so the pattern averages 1 at any sharpness (fit to a Monte Carlo of this noise: caustics move
	// light around, they do not add or remove it).
	float c = pow(ridges, sharpness) * (0.36 * sharpness + 0.68);
	return mix(1.0, c, CAUSTICS_STRENGTH * waveIntensity() * smoothstep(0.0, 0.4, depth));
}

#endif
