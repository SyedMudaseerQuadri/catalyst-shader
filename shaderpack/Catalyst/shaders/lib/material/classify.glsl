// Catalyst — material classes. IDs are assigned in shaders/block.properties; keep both in sync.
// Class is stored in colortex1.b as (class / 255).

#if !defined CATALYST_MATERIAL_CLASSIFY
#define CATALYST_MATERIAL_CLASSIFY

#define MAT_DEFAULT      0
#define MAT_FOLIAGE      1   // plants and crops: thin, double-sided, lit as if facing up
#define MAT_LEAVES       2   // leaves: thin volume with light transmission
#define MAT_WATER        3
#define MAT_EMISSIVE     4   // light-emitting blocks; bright texels emit
#define MAT_LAVA         5   // fully emissive
#define MAT_ENTITY       10
#define MAT_HAND         11

// block.properties IDs -> material class.
int materialFromBlockId(int blockId) {
	if (blockId == 10001) return MAT_FOLIAGE;
	if (blockId == 10002) return MAT_LEAVES;
	if (blockId == 10003) return MAT_WATER;
	if (blockId == 10004) return MAT_EMISSIVE;
	if (blockId == 10005) return MAT_LAVA;
	return MAT_DEFAULT;
}

struct Surface {
	vec3 albedo;        // linear; for metals it tints the reflection instead of diffusing
	vec3 normal;        // shading normal, player space, unit (normal-mapped when material maps are on)
	vec3 geoNormal;     // geometric normal, player space, unit (shadow bias, self-shadowing)
	vec2 light;         // x = block light, y = sky light, both 0..1
	float ao;           // vanilla AO x material AO, 0..1 (applied to indirect light only)
	float emission;     // 0..1 fraction of albedo emitted
	float transmission; // 0..1 thin-surface light transmission
	float roughness;    // GGX alpha ("linear roughness" in LabPBR terms), 0..1
	vec3 f0;            // specular reflectance at normal incidence, linear; 0 = no specular
	float metalness;    // 0 dielectric, 1 metal (no diffuse term)
	int materialClass;
};

// Emission from the texel itself: only the bright parts of an emissive texture glow (torch flame, not its stick).
float emissionFromAlbedo(vec3 albedoLinear, int materialClass) {
	if (materialClass == MAT_LAVA) return 1.0;
	if (materialClass != MAT_EMISSIVE) return 0.0;
	float peak = max(albedoLinear.r, max(albedoLinear.g, albedoLinear.b));
	return smoothstep(0.25, 0.75, peak);
}

// Default surface for a material class. Without resource-pack material data there is no specular
// (f0 = 0), matching Iris's default specular texture, so vanilla textures keep their vanilla look.
Surface makeSurface(vec3 albedoLinear, vec3 geoNormal, vec2 light, float ao, int materialClass) {
	Surface s;
	s.albedo = albedoLinear;
	s.normal = geoNormal;
	s.geoNormal = geoNormal;
	s.light = light;
	s.ao = ao;
	s.emission = emissionFromAlbedo(albedoLinear, materialClass);
	s.transmission = 0.0;
	s.roughness = 1.0;
	s.f0 = vec3(0.0);
	s.metalness = 0.0;
	s.materialClass = materialClass;
	if (materialClass == MAT_FOLIAGE) {
		// Cross-shaped plants: shade like the ground they grow from, with light passing through.
		s.normal = vec3(0.0, 1.0, 0.0);
		s.geoNormal = vec3(0.0, 1.0, 0.0);
		s.transmission = 0.4;
	} else if (materialClass == MAT_LEAVES) {
		s.transmission = 0.5;
	}
	return s;
}

#endif
