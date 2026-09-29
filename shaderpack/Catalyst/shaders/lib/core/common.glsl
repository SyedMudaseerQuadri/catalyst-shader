// Catalyst — shared math and color-space helpers.
//
// Color pipeline (docs/standards/coding_standards.md, "Color management"):
//   texture input  : sRGB-encoded (vanilla / resource-pack textures)
//   working space  : scene-linear, Rec.709/sRGB primaries, HDR (colortex0)
//   scene units    : relative radiance; direct noon sun ~ 3.0, full blocklight ~ 1.3
//   exposure       : applied once, in final
//   tonemap/grade  : final, then sRGB encode for display

#if !defined CATALYST_COMMON
#define CATALYST_COMMON

const float PI = 3.14159265358979;
const float TAU = 6.28318530717959;
const float GOLDEN_ANGLE = 2.39996322972865; // radians, pi * (3 - sqrt(5))

float saturate(float x) { return clamp(x, 0.0, 1.0); }
vec2  saturate(vec2 x)  { return clamp(x, 0.0, 1.0); }
vec3  saturate(vec3 x)  { return clamp(x, 0.0, 1.0); }

float sqr(float x) { return x * x; }

// Rec.709 relative luminance of a linear color.
float luminance(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

// Exact sRGB transfer functions (IEC 61966-2-1).
vec3 srgbToLinear(vec3 c) {
	vec3 lo = c / 12.92;
	vec3 hi = pow((c + 0.055) / 1.055, vec3(2.4));
	return mix(lo, hi, step(vec3(0.04045), c));
}

vec3 linearToSrgb(vec3 c) {
	c = max(c, 0.0);
	vec3 lo = c * 12.92;
	vec3 hi = 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055;
	return mix(lo, hi, step(vec3(0.0031308), c));
}

// Interleaved gradient noise (Jimenez 2014, public presentation) — per-pixel rotation/dither in [0,1).
float interleavedGradientNoise(vec2 pixel) {
	return fract(52.9829189 * fract(dot(pixel, vec2(0.06711056, 0.00583715))));
}

// Point i of an n-point Vogel (golden-angle) disk, unit radius, rotated by `rotation` radians.
vec2 vogelDisk(int i, int n, float rotation) {
	float r = sqrt((float(i) + 0.5) / float(n));
	float theta = float(i) * GOLDEN_ANGLE + rotation;
	return r * vec2(cos(theta), sin(theta));
}

#endif
