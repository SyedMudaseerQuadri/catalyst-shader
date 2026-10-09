# Catalyst — Compatibility Target

"Current Minecraft" and "current Iris" are not valid targets. Populate this file during M0, before any version-sensitive implementation decision is made. Every version-sensitive decision elsewhere in the repository must reference the values recorded here, not an assumed "current" version.

| Item | Value | Evidence |
|---|---|---|
| Target Minecraft version | 1.21.11 | User-provided, pinned by uploaded jars |
| Target Iris version | 1.10.7 (Fabric build) | iris-fabric-1_10_7_mc1_21_11.jar, user-provided |
| Supported version range | Single pinned version only (1.21.11). Do not add multi-version support until this target ships. | Decision, not evidence — revisit later if scope changes |
| Loader / mod platform requirements | Fabric Loader + Fabric API 0.141.6 + Sodium 0.8.7 (required by Iris on Fabric — do not remove). Observed in testing: Fabric Loader 0.19.4 + Sodium 0.8.12 | fabric-api-0_141_6_1_21_11.jar, sodium-fabric-0_8_7_mc1_21_11.jar, user-provided; 0.8.12 from latest.log (EV-005) |
| Required Iris capabilities | GLSL 330 compatibility programs; gbuffers/shadow/deferred/composite/final programs; `dimension.properties`; profiles/screens/sliders; `colortexN` Format/Clear/ClearColor; hardware shadow filtering; `separateAo`; `MC_RENDER_STAGE_*` macros. M1 needs no feature flag | Checked in source against Iris branch `1.21.11` @ `0a1fcaa` (state/evidence/iris_1.10.7_capabilities.md, EV-001). Runtime: UNVERIFIED |
| Optional Iris capabilities | `COMPUTE_SHADERS`, `SSBO`, `CUSTOM_IMAGES`, `PER_BUFFER_BLENDING` exist (hardware-gated). Not used before M5/M6. Gate them with `iris.features.optional` when adopted | Checked in source (EV-001) |
| OpenGL / GLSL baseline | GLSL 330 compatibility (Iris patches to core). The RTX 3050 and RTX 4060 both expose GL 4.6 | Offline compile: EV-002. Driver compile: UNVERIFIED |
| Minimum hardware target | NVIDIA GeForce RTX 3050 (Ampere, desktop, 8GB VRAM). Must run the **Performance** preset at 1080p with default settings. Lower-VRAM 3050 variants (6GB desktop, 4GB laptop) are not guaranteed and must be verified separately before they are claimed | User decision (D-006). UNVERIFIED — no RTX 3050 available for testing |
| Recommended / primary development machine | GPU: RTX 4060 **Laptop** (8GB VRAM), NVIDIA driver 617.14 · CPU: i7-13700HX · RAM: 16GB · Storage: 1TB | User-provided; GPU/driver from latest.log (EV-005) |
| VRAM budget | Performance preset must fit the minimum target: aim for no more than ~6GB of total game VRAM use at 1080p, leaving headroom on an 8GB RTX 3050. Higher presets may use more but must stay under 8GB on the dev RTX 4060. Exact per-subsystem numbers get set by measurement | Target derived from D-006, not a measured result |
| Known driver/vendor constraints (NVIDIA/AMD/integrated) | Only NVIDIA (Ada Lovelace, RTX 4060) is currently available for verification. AMD/Intel/integrated GPUs are completely untested | Single test machine — real gap, see note below |
| Available test environments | One (1): the user's own machine above. No cross-vendor testing exists yet. As of 2026-09-30 no Fabric/Iris client is installed on it (docs/environment/capabilities.md) | User-provided; install check 2026-09-30 |

## Rules

- If a feature behaves differently across supported versions, isolate the difference in a compatibility layer and document it here or in an ADR. Do not silently mix assumptions from different versions.
- Catalyst must not be hardware-exclusive. Verify fallback behavior and quality across the vendor/tier range recorded above, not only the primary development GPU.
- Re-check this file when the environment or target changes — do not treat it as write-once.
