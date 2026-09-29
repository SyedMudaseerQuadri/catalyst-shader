# Catalyst Visual Quality & Regression Matrix

Every release-critical visual claim should be tested in representative scenes and, where practical, under each official visual preset and at least the relevant performance presets.

| ID | Scene | Primary checks |
|---|---|---|
| A | Clear daytime terrain | lighting, materials, shadows, readability |
| B | Sunrise/sunset | solar transition, atmosphere, exposure, color temperature |
| C | Night settlement | moon/block light, contrast, artificial-light response |
| D | Dense forest | foliage, dappled light, temporal stability, environmental coupling |
| E | Cave | darkness, local light, fog, readability |
| F | Large water body | waves, reflection, refraction, depth, shoreline |
| G | Underwater | absorption, scattering, fog, temporal stability |
| H | Rain transition | clouds, rain, wetness onset, lighting response |
| I | Heavy storm | cloud density, lightning, volumetrics, readability |
| J | Snow transition | snowfall, accumulation, surface response, melt/drying |
| K | High-motion camera | reprojection, ghosting, disocclusion |
| L | Material stress test | roughness, normal, emission, wetness/snow response |

## Artifact checklist
Ghosting, shimmer, flicker, unstable shadows/reflections, water artifacts, cloud artifacts, volumetric artifacts, banding, exposure errors, color errors, light leaks, NaN/Inf, precision issues, readability failures.

## Evidence
Record environment, preset, scene, expected behavior, observed behavior, artifact/evidence path, status. Status values: PASS / PASS WITH KNOWN LIMITATIONS / REWORK / DEFER / UNVERIFIED.
