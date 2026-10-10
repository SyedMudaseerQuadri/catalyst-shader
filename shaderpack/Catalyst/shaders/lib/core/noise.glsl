// Catalyst — procedural noise shared by clouds, wind, wetness and water.
//
// Hashing: PCG-style integer hashes (Jarzynski & Olano, "Hash Functions for GPU Rendering", JCGT 2020).
// Integer hashing avoids the precision artifacts of fract(sin(x)) hashes on some GPUs.
// Value noise uses quintic interpolation (C2-continuous, so derived normals have no grid creases).
// Inputs to the 2D/3D noise should stay below ~2^20 in magnitude (float -> int conversion).
// Requires: nothing.

#if !defined CATALYST_NOISE
#define CATALYST_NOISE

uint pcgHash(uint v) {
	uint state = v * 747796405u + 2891336453u;
	uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
	return (word >> 22u) ^ word;
}

uvec3 pcgHash3(uvec3 v) {
	v = v * 1664525u + 1013904223u;
	v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
	v ^= v >> 16u;
	v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
	return v;
}

// Uniform random in [0,1) from integer lattice coordinates.
float hash11(int x)     { return float(pcgHash(uint(x))) * (1.0 / 4294967296.0); }
float hash21(ivec2 p)   { return float(pcgHash3(uvec3(p, 0x9E37u)).x) * (1.0 / 4294967296.0); }
float hash31(ivec3 p)   { return float(pcgHash3(uvec3(p)).x) * (1.0 / 4294967296.0); }

vec2 quintic(vec2 f) { return f * f * f * (f * (f * 6.0 - 15.0) + 10.0); }
vec3 quintic(vec3 f) { return f * f * f * (f * (f * 6.0 - 15.0) + 10.0); }

float valueNoise1(float x) {
	float i = floor(x);
	float f = x - i;
	float u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
	return mix(hash11(int(i)), hash11(int(i) + 1), u);
}

float valueNoise2(vec2 p) {
	vec2 i = floor(p);
	vec2 u = quintic(p - i);
	ivec2 c = ivec2(i);
	float a = hash21(c);
	float b = hash21(c + ivec2(1, 0));
	float d = hash21(c + ivec2(0, 1));
	float e = hash21(c + ivec2(1, 1));
	return mix(mix(a, b, u.x), mix(d, e, u.x), u.y);
}

float valueNoise3(vec3 p) {
	vec3 i = floor(p);
	vec3 u = quintic(p - i);
	ivec3 c = ivec3(i);
	float n000 = hash31(c);
	float n100 = hash31(c + ivec3(1, 0, 0));
	float n010 = hash31(c + ivec3(0, 1, 0));
	float n110 = hash31(c + ivec3(1, 1, 0));
	float n001 = hash31(c + ivec3(0, 0, 1));
	float n101 = hash31(c + ivec3(1, 0, 1));
	float n011 = hash31(c + ivec3(0, 1, 1));
	float n111 = hash31(c + ivec3(1, 1, 1));
	return mix(mix(mix(n000, n100, u.x), mix(n010, n110, u.x), u.y),
	           mix(mix(n001, n101, u.x), mix(n011, n111, u.x), u.y), u.z);
}

// Fractal sum normalized to [0,1]. Each octave is rotated to hide the lattice axes.
float fbm2(vec2 p, int octaves) {
	const mat2 ROTATE = mat2(0.80, 0.60, -0.60, 0.80);
	float sum = 0.0;
	float amplitude = 0.5;
	float norm = 0.0;
	for (int i = 0; i < octaves; i++) {
		sum += valueNoise2(p) * amplitude;
		norm += amplitude;
		p = ROTATE * p * 2.03 + 17.1;
		amplitude *= 0.5;
	}
	return sum / norm;
}

float fbm3(vec3 p, int octaves) {
	float sum = 0.0;
	float amplitude = 0.5;
	float norm = 0.0;
	for (int i = 0; i < octaves; i++) {
		sum += valueNoise3(p) * amplitude;
		norm += amplitude;
		p = p * 2.07 + vec3(13.7, 5.3, 29.1);
		amplitude *= 0.5;
	}
	return sum / norm;
}

#endif
