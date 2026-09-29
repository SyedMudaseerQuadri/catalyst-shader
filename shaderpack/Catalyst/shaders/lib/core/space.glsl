// Catalyst — coordinate-space conversions.
//
// Spaces (docs/standards/coding_standards.md):
//   screen : (uv in [0,1]^2, depth in [0,1]); depth 1.0 = far plane / sky. No reverse-Z.
//   NDC    : screen * 2 - 1 (OpenGL convention).
//   view   : camera space, right-handed, camera looks down -Z.
//   player : world axes (+Y up), origin at the eye; float-precision safe at any world coordinate.
//   world  : player + cameraPosition (only for small, wrapped uses; beware precision far from origin).
// Requires lib/core/uniforms.glsl.

#if !defined CATALYST_SPACE
#define CATALYST_SPACE

vec3 viewFromScreen(vec3 screenPos) {
	vec4 v = gbufferProjectionInverse * vec4(screenPos * 2.0 - 1.0, 1.0);
	return v.xyz / v.w;
}

vec3 playerFromView(vec3 viewPos) {
	return mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz;
}

vec3 playerDirFromView(vec3 viewDir) {
	return mat3(gbufferModelViewInverse) * viewDir;
}

// Positive distance along -Z in view space.
float linearizeDepth(float depth) {
	float z = depth * 2.0 - 1.0;
	return (2.0 * near * far) / (far + near - z * (far - near));
}

#endif
