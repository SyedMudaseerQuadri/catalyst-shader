# Catalyst — Validation, Test Scenes & Regression

## Debug mode

Catalyst must have a structured debug system.

At minimum provide debug views for:

- albedo;
- normals;
- roughness;
- metallic/specular;
- emissive;
- material ID;
- depth;
- linear depth;
- motion vectors;
- velocity magnitude;
- shadow map;
- shadow factors;
- direct lighting;
- indirect lighting;
- GI confidence;
- reflection mask;
- refraction mask;
- water depth;
- fog density;
- cloud density;
- cloud shadow;
- voxel occupancy;
- voxel radiance;
- ray count/sample count where possible;
- temporal confidence;
- history rejection;
- variance;
- exposure;
- HDR luminance.

Debug modes must be documented and easy to activate.

---

## Automated validation

Build whatever automated validation can be supported by the workspace.

At minimum create tooling that can:

- validate expected files exist;
- validate include paths;
- catch malformed configuration;
- catch duplicate or inconsistent uniform declarations;
- catch buffer-contract mismatches;
- search for unresolved symbols;
- detect obvious impossible feature combinations;
- report shader-stage dependency violations;
- validate documented buffer mappings against implementation where possible.

Where an actual GLSL/Iris compiler or Minecraft test environment is available, use it.

Where it is unavailable, build static checks and clearly mark the limitation.

Never report “compiled successfully” without actually compiling/loading.

---

## Test scenes

Create or document a repeatable QA matrix covering:

### Lighting
- clear noon;
- golden hour;
- sunrise;
- sunset;
- full night;
- moonlit scene;
- interior with mixed light;
- deep cave;
- emissive-heavy scene.

### Environment
- plains;
- forest;
- desert;
- snowy biome;
- jungle;
- swamp;
- mountains;
- ocean;
- river;
- village/structure-heavy scene.

### Weather
- clear;
- rain;
- heavy rain/storm;
- snow;
- wet transition;
- post-rain.

### Water
- shallow;
- deep;
- underwater;
- reflective shoreline;
- moving camera over water;
- underwater cave.

### Geometry/materials
- foliage;
- glass/translucency;
- emissive blocks;
- metallic materials;
- rough materials;
- POM/high-detail textures;
- entities;
- particles.

### Dimensions
- Overworld;
- Nether;
- End;
- special/custom dimensions if supported.

### Stress
- high render distance;
- dense foliage;
- large body of water;
- strong fog;
- many light sources;
- many emissive materials;
- heavy cloud coverage.

---

## Regression testing

Every milestone must maintain a regression checklist.

A fix for:

- shadows must not break water;
- water must not break translucency;
- GI must not corrupt exposure;
- temporal accumulation must not ghost entities;
- voxel updates must not corrupt lighting;
- cloud changes must not break sky/fog;
- new buffers must not silently change unrelated material encodings.

Maintain:

`docs/testing/regression_matrix.md`

---

