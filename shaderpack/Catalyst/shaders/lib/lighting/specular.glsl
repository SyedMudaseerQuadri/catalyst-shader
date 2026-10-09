// Catalyst — specular BRDF terms (microfacet, GGX).
//
// f_spec = D * V * F with V = G / (4 NdotL NdotV) (height-correlated Smith visibility).
// Catalyst's lighting units fold the 1/pi of Lambert diffuse into the light radiance (forward.glsl),
// so specular is multiplied by pi to stay energy-consistent with diffuse.
// Sources: Walter et al. 2007 (GGX), Heitz 2014 (correlated Smith), Schlick 1994 (Fresnel),
// Karis 2014 "Physically Based Shading on Mobile" (analytic environment BRDF approximation).
// Requires: core/common.glsl.

#if !defined CATALYST_SPECULAR
#define CATALYST_SPECULAR

// Floor for GGX alpha: the sun is a small but finite disk, and without TAA very sharp highlights alias.
const float MIN_ROUGHNESS = 0.04;

float ggxDistribution(float NdotH, float alpha) {
	float a2 = alpha * alpha;
	float d = NdotH * NdotH * (a2 - 1.0) + 1.0;
	return a2 / (PI * d * d);
}

float smithGgxCorrelatedVisibility(float NdotV, float NdotL, float alpha) {
	float a2 = alpha * alpha;
	float lambdaV = NdotL * sqrt(NdotV * NdotV * (1.0 - a2) + a2);
	float lambdaL = NdotV * sqrt(NdotL * NdotL * (1.0 - a2) + a2);
	return 0.5 / max(lambdaV + lambdaL, 1e-5);
}

vec3 fresnelSchlick(float cosTheta, vec3 f0) {
	float f = pow(1.0 - saturate(cosTheta), 5.0);
	return f0 + (1.0 - f0) * f;
}

// Direct specular for one light, already multiplied by NdotL and pi (see header).
vec3 directSpecular(vec3 n, vec3 v, vec3 l, float alpha, vec3 f0) {
	vec3 h = normalize(l + v);
	float NdotL = saturate(dot(n, l));
	float NdotV = max(dot(n, v), 1e-4);
	float NdotH = saturate(dot(n, h));
	float VdotH = saturate(dot(v, h));
	return PI * ggxDistribution(NdotH, alpha) * smithGgxCorrelatedVisibility(NdotV, NdotL, alpha)
	       * fresnelSchlick(VdotH, f0) * NdotL;
}

// Split-sum environment BRDF, analytic fit (Karis 2014). Returns the scale for prefiltered radiance.
vec3 environmentBrdf(vec3 f0, float NdotV, float alpha) {
	float perceptualRoughness = sqrt(alpha);
	const vec4 c0 = vec4(-1.0, -0.0275, -0.572, 0.022);
	const vec4 c1 = vec4(1.0, 0.0425, 1.04, -0.04);
	vec4 r = perceptualRoughness * c0 + c1;
	float a004 = min(r.x * r.x, exp2(-9.28 * NdotV)) * r.x + r.y;
	vec2 ab = vec2(-1.04, 1.04) * a004 + r.zw;
	// F0 below ~2% is not a real material: treat it as "no specular" so vanilla blocks (f0 = 0) get none.
	return f0 * ab.x + ab.y * saturate(50.0 * max(f0.r, max(f0.g, f0.b)));
}

#endif
