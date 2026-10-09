// Catalyst — central configuration.
// Single owner of every user-facing option (docs/architecture/settings_architecture.md).
// Iris reads the option annotations ("// [a b c]") directly from this file.
//
// Precedence (settings_architecture.md): user explicit value > visual/performance preset > automatic default.
// Visual-preset parameters are resolved below as PRESET_* constants; user sliders are multipliers
// on top of them (1.00 = "use the preset's value"), so a preset change never discards a user override.

#if !defined CATALYST_SETTINGS
#define CATALYST_SETTINGS

// ---------------------------------------------------------------------------------------------
// Layer 1 — Visual preset (docs/architecture/preset_model.md)
// 0 = Vanilla Enhanced, 1 = Natural / Realistic (default), 2 = Cinematic
#define VISUAL_PRESET 1 // [0 1 2]

// Layer 1 — Performance preset. Selected through the Iris profile button (shaders.properties);
// this option is not shown on any screen. 0 Performance, 1 Balanced, 2 Quality, 3 Ultra, 4 Cinematic.
#define PERF_PROFILE 1 // [0 1 2 3 4]

// ---------------------------------------------------------------------------------------------
// Shadows (performance-scaled; values are set by the performance profiles)
#define SHADOWS
const int shadowMapResolution = 2048; // [1024 1536 2048 3072 4096]
const float shadowDistance = 128.0; // [64.0 80.0 96.0 128.0 160.0 192.0 256.0]
// Only render shadow-casting chunks inside shadowDistance: a large saving on the RTX 3050 floor.
const float shadowDistanceRenderMul = 1.0;
const bool shadowHardwareFiltering = true;
#define SHADOW_FILTER 2 // [0 1 2 3]
#define SHADOW_SOFTNESS 1.00 // [0.50 0.75 1.00 1.25 1.50 2.00]
const float sunPathRotation = -20.0; // [-40.0 -30.0 -20.0 -10.0 0.0 10.0 20.0 30.0 40.0]

// ---------------------------------------------------------------------------------------------
// Materials: read LabPBR 1.3 normal/specular maps from the resource pack (Iris loads _n/_s textures).
#define MATERIAL_MAPS
#define SPECULAR_INTENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50]

// ---------------------------------------------------------------------------------------------
// Artistic controls — multipliers over the visual preset (1.00 = preset default)
#define SUN_INTENSITY 1.00 // [0.50 0.75 1.00 1.25 1.50 2.00]
#define AMBIENT_INTENSITY 1.00 // [0.50 0.75 1.00 1.25 1.50 2.00]
#define BLOCKLIGHT_INTENSITY 1.00 // [0.50 0.75 1.00 1.25 1.50 2.00]
#define EMISSIVE_INTENSITY 1.00 // [0.00 0.50 1.00 1.50 2.00 3.00]
#define FOG_DENSITY 1.00 // [0.00 0.25 0.50 0.75 1.00 1.25 1.50 2.00]
#define SATURATION 1.00 // [0.70 0.80 0.90 1.00 1.10 1.20 1.30]
#define CONTRAST 1.00 // [0.80 0.90 1.00 1.10 1.20]
#define EXPOSURE_BIAS 0.0 // [-2.0 -1.5 -1.0 -0.5 0.0 0.5 1.0 1.5 2.0]
// Eye adaptation: 0 = fixed exposure, 1 = full adaptation (every scene normalized to the same brightness).
#define EXPOSURE_ADAPTATION 0.50 // [0.00 0.25 0.50 0.75 1.00]
#define NIGHT_VISIBILITY 1.00 // [0.50 0.75 1.00 1.50 2.00]

// ---------------------------------------------------------------------------------------------
// Debug (docs/testing): 0 off, 1 albedo, 2 normals, 3 lightmap, 4 material id, 5 linear depth, 6 direct shadow,
// 7 smoothness (LabPBR)
#define DEBUG_VIEW 0 // [0 1 2 3 4 5 6 7]

// =============================================================================================
// Resolved visual-preset parameters (not user-facing; derived from VISUAL_PRESET only)
// =============================================================================================
#if VISUAL_PRESET == 0
	// Vanilla Enhanced — closest to Minecraft identity.
	const float PRESET_VANILLA_SKY_BLEND   = 0.60; // weight of the biome's vanilla sky color
	const float PRESET_AEROSOL            = 0.06; // haze optical depth; warms low sun
	const float PRESET_FOG_DENSITY        = 0.60;
	const float PRESET_SATURATION         = 1.00;
	const float PRESET_CONTRAST           = 1.00;
	const float PRESET_EXPOSURE_BIAS      = 0.10;
	const float PRESET_MIN_AMBIENT        = 0.045; // readability floor, scene-linear units
	const float PRESET_SHADOW_AMBIENT     = 1.10; // ambient share in shade; >1 = softer contrast
#elif VISUAL_PRESET == 2
	// Cinematic — stronger atmosphere and contrast, still readable.
	const float PRESET_VANILLA_SKY_BLEND   = 0.20;
	const float PRESET_AEROSOL            = 0.11;
	const float PRESET_FOG_DENSITY        = 1.40;
	const float PRESET_SATURATION         = 1.06;
	const float PRESET_CONTRAST           = 1.08;
	const float PRESET_EXPOSURE_BIAS      = -0.15;
	const float PRESET_MIN_AMBIENT        = 0.025;
	const float PRESET_SHADOW_AMBIENT     = 0.85;
#else
	// Natural / Realistic — default target (~60% natural / 40% cinematic).
	const float PRESET_VANILLA_SKY_BLEND   = 0.35;
	const float PRESET_AEROSOL            = 0.08;
	const float PRESET_FOG_DENSITY        = 1.00;
	const float PRESET_SATURATION         = 1.02;
	const float PRESET_CONTRAST           = 1.03;
	const float PRESET_EXPOSURE_BIAS      = 0.00;
	const float PRESET_MIN_AMBIENT        = 0.032;
	const float PRESET_SHADOW_AMBIENT     = 1.00;
#endif

// Hard readability safeguard: no preset or slider may take the light floor below this.
const float READABILITY_MIN_AMBIENT = 0.015;

// =============================================================================================
// Internal rendering tier (Layer 2 — never user-facing, see preset_model.md)
// Mapping: Performance -> Low, Balanced -> Medium, Quality -> High, Ultra -> Ultra, Cinematic -> Extreme.
// Subsystems branch on TIER_* only for choices that have no dedicated user option.
// =============================================================================================
#define TIER_LOW 0
#define TIER_MEDIUM 1
#define TIER_HIGH 2
#define TIER_ULTRA 3
#define TIER_EXTREME 4
#define INTERNAL_TIER PERF_PROFILE

#endif
