// Catalyst — G-buffer packing. Layout is recorded in docs/architecture/data_contracts.md.
//
// Normal encoding: octahedral, player/world axes, mapped to [0,1] for UNORM storage.
// Lightmap packing: block and sky light quantized to 8 bits each, packed in one 16-bit channel.

#if !defined CATALYST_ENCODE
#define CATALYST_ENCODE

vec2 encodeNormal(vec3 n) {
	n /= (abs(n.x) + abs(n.y) + abs(n.z));
	vec2 e = n.z >= 0.0 ? n.xy : (1.0 - abs(n.yx)) * vec2(n.x >= 0.0 ? 1.0 : -1.0, n.y >= 0.0 ? 1.0 : -1.0);
	return e * 0.5 + 0.5;
}

vec3 decodeNormal(vec2 e) {
	e = e * 2.0 - 1.0;
	vec3 n = vec3(e, 1.0 - abs(e.x) - abs(e.y));
	float t = max(-n.z, 0.0);
	n.xy += vec2(n.x >= 0.0 ? -t : t, n.y >= 0.0 ? -t : t);
	return normalize(n);
}

float packLightmap(vec2 lm) {
	vec2 q = floor(clamp(lm, 0.0, 1.0) * 255.0 + 0.5);
	return (q.x * 256.0 + q.y) / 65535.0;
}

vec2 unpackLightmap(float p) {
	float v = floor(p * 65535.0 + 0.5);
	return vec2(floor(v / 256.0), mod(v, 256.0)) / 255.0;
}

// Vanilla lightmap texture coordinates sit on texel centers of a 16x16 map; remap to [0,1].
vec2 remapLightmap(vec2 lmcoord) {
	return clamp((lmcoord * 16.0 - 0.5) / 15.0, 0.0, 1.0);
}

#endif
