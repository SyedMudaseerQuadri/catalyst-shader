# Catalyst — Settings Architecture

## Layers
1. Visual preset selector
2. Performance preset selector
3. Master aesthetic intensity
4. Visual axes
5. Subsystem groups
6. Advanced per-parameter controls

## Groups
Lighting, Shadows, Materials, Atmosphere, Clouds, Weather, Water, Volumetrics, GI, Reflections, Camera, Color, Temporal, Debug.

## Precedence
User explicit override > subsystem override > preset value > automatic environmental default.

## Parent/child rules
A disabled parent may disable dependent children when necessary for correctness/performance. The UI must communicate dependency state. Advanced users may override only when the implementation can remain valid.

## Performance separation
Performance presets select computational budgets. Visual presets select artistic defaults. The combined configuration is resolved before compilation/runtime feature selection.
