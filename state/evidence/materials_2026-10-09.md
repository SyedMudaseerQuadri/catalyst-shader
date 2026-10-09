# EV-003 — M2 material system: LabPBR decoding, specular BRDF, compilation

- **id:** EV-003
- **date:** 2026-10-09
- **claim:** The LabPBR 1.3 material path and GGX specular model compile in every configuration, decode the
  standard as written, use the tangent convention Iris actually produces, and conserve energy.
- **environment:** Windows 11, Python 3.14, Khronos glslang 16.6.0 (pinned via `tools/fetch_glslang.py`,
  SHA-256 `82bf434e…8d9b`). No Minecraft/Iris runtime.
- **confidence:** HIGH for compilation and the math; NONE for in-game appearance (I-002).

## 1. Compilation — PASS
`python tools/validate_shaderpack.py`: 98 program stages x 23 configurations = **2254 compilations, all PASS**.
New configuration: `MATERIAL_MAPS=off`. Options: 20 (`MATERIAL_MAPS` correctly detected as a boolean menu option).

## 2. Iris interfaces — checked in source (branch `1.21.11`)
| Item | Source | Result |
|---|---|---|
| Samplers `normals`, `specular` | `samplers/IrisSamplers.java` l.217–218 | present |
| Defaults when a pack has no maps: normal `0x7F7FFFFF` (flat, AO 1), specular `0x00000000` | `pbr/texture/PBRType.java` | present; Catalyst treats f0 = 0 as "no specular" |
| Attribute `at_tangent` in terrain/entity formats | `vertices/IrisVertexFormats.java` l.44/59/71 | present |
| Tangent convention: xyz = dP/du; w = sign(dot(dP/dv, cross(T, N))) | `vertices/NormalHelper.java` `computeTangent` | so dP/dv = cross(T, N) * w |

Derived: Minecraft texture v grows downward, and LabPBR stores normals DirectX-style (green = down = +v),
so tangent-space Y maps onto `cross(T, N) * w` with **no flip** (`lib/material/labpbr.glsl`).

## 3. LabPBR decoding — matches the spec text (shaderlabs.org wiki, fetched 2026-10-09)
roughness = (1 - smoothness)^2; F0 linear for g <= 229; g >= 230 treated as metal with albedo as F0 (allowed by the
spec); b >= 65 is subsurface (65..255 maps to 0..1); a < 255 is emission (a / 254); `_n` blue = AO (linear).
Not yet decoded: porosity (needs wetness, M3), height/POM, predefined metal IORs.

## 4. BRDF energy check — PASS
Monte Carlo directional albedo of the direct specular term (F = 1, importance-sampled GGX, 400k samples each):

| alpha | 0 deg | 46 deg | 75 deg |
|---|---|---|---|
| 0.04 | 0.998 | 0.998 | 0.986 |
| 0.1 | 0.989 | 0.981 | 0.927 |
| 0.3 | 0.878 | 0.844 | 0.824 |

Never above 1, so the model creates no energy. The loss at higher roughness is the known single-scattering GGX
deficit (no multiple-scattering compensation yet). Accepted for M2 and recorded as an approximation.
Environment BRDF fit: outputs in [0, 0.89] over the tested grid; exactly 0 when f0 = 0 (vanilla blocks get no sheen).

## Not covered (still UNVERIFIED)
In-game look with a LabPBR resource pack, the normal-map orientation on screen, driver compilation, performance cost.
