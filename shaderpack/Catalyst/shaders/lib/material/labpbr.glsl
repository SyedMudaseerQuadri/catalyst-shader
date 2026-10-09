// Catalyst — LabPBR 1.3 material decoding (resource-pack `_n` / `_s` textures).
// Standard: https://shaderlabs.org/wiki/LabPBR_Material_Standard (decoded from the spec, not from any pack).
//
// _n (normals): rg = tangent-space normal XY, DirectX convention (green points DOWN the texture = +v);
//               z reconstructed; b = material AO (linear); a = height (unused: no POM yet).
// _s (specular): r = perceptual smoothness; g = F0 (0..229 linear) or metal (230..255);
//               b = porosity (0..64) or subsurface (65..255); a = emission (0..254), 255 = none.
//
// Tangent frame (verified in Iris 1.21.11 NormalHelper.computeTangent): at_tangent.xyz = dP/du,
// and at_tangent.w is chosen so that dP/dv = cross(T, N) * w. Minecraft's texture v grows downward,
// so the DirectX-style green channel maps onto that bitangent with no flip.
// Requires: core/common.glsl, material/classify.glsl, lighting/specular.glsl (MIN_ROUGHNESS).

#if !defined CATALYST_LABPBR
#define CATALYST_LABPBR

// Builds the tangent-to-player matrix. Returns false when the vertex format has no usable tangent
// (e.g. particles), in which case normal mapping must be skipped.
bool buildTangentFrame(vec3 geoNormal, vec4 tangent, out mat3 tbn) {
	vec3 t = tangent.xyz - geoNormal * dot(geoNormal, tangent.xyz); // Gram-Schmidt against the normal
	if (dot(t, t) < 1e-6) { tbn = mat3(1.0); return false; }
	t = normalize(t);
	float handedness = tangent.w < 0.0 ? -1.0 : 1.0;
	vec3 b = cross(t, geoNormal) * handedness;
	tbn = mat3(t, b, geoNormal);
	return true;
}

void applyLabPbrNormal(inout Surface s, vec4 normalTex, mat3 tbn) {
	vec2 xy = normalTex.rg * 2.0 - 1.0;
	vec3 tangentNormal = vec3(xy, sqrt(saturate(1.0 - dot(xy, xy))));
	vec3 n = tbn * tangentNormal;
	if (dot(n, n) > 1e-6) s.normal = normalize(n);
	s.ao *= normalTex.b;
}

void applyLabPbrSpecular(inout Surface s, vec4 specularTex) {
	float smoothness = specularTex.r;
	s.roughness = max(sqr(1.0 - smoothness), MIN_ROUGHNESS);

	float g = specularTex.g * 255.0;
	if (g >= 229.5) {
		// Metals: the spec allows treating every predefined metal (230..254) like 255, albedo-as-F0.
		s.metalness = 1.0;
		s.f0 = s.albedo;
	} else {
		s.f0 = vec3(specularTex.g);
	}

	float b = specularTex.b * 255.0;
	if (b >= 64.5) s.transmission = max(s.transmission, (b - 65.0) / 190.0);
	// Porosity (0..64) is decoded when wetness exists (M3).

	float a = specularTex.a * 255.0;
	if (a < 254.5) s.emission = max(s.emission, a / 254.0);
}

#endif
