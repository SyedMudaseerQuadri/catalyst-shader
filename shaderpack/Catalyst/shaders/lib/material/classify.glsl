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
	vec3 albedo;        // linear
	vec3 normal;        // player space, unit
	vec2 light;         // x = block light, y = sky light, both 0..1
	float ao;           // vanilla ambient occlusion, 0..1 (applied to indirect light only)
	float emission;     // 0..1 fraction of albedo emitted
	float transmission; // 0..1 thin-surface light transmission
	int materialClass;
};

// Emission from the texel itself: only the bright parts of an emissive texture glow (torch flame, not its stick).
float emissionFromAlbedo(vec3 albedoLinear, int materialClass) {
	if (materialClass == MAT_LAVA) return 1.0;
	if (materialClass != MAT_EMISSIVE) return 0.0;
	float peak = max(albedoLinear.r, max(albedoLinear.g, albedoLinear.b));
	return smoothstep(0.25, 0.75, peak);
}

#endif
