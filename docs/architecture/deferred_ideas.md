# Catalyst — Deferred Ideas, Roadmap Governance & What Not To Do

## Deferred ideas
Record features that are intentionally not implemented yet. For each item:
idea; reason deferred; dependency; expected benefit; cost/risk; evidence needed; trigger for
reconsideration.

## Roadmap governance
Catalyst is allowed to evolve. When evidence shows the current architecture is wrong:
1. stop expansion of the affected subsystem
2. document the problem
3. propose alternatives
4. evaluate cost/risk
5. choose a new design
6. migrate cleanly
7. remove obsolete architecture
8. update docs and tests

Do not preserve a bad design simply because it was implemented first. Avoid architectural
churn caused by tiny visual preferences.

## What not to do
Never:
- create one giant shader file containing the entire renderer
- copy code from reference packs and rename variables
- claim path tracing when the effect is only SSR
- call software voxel tracing hardware ray tracing
- expose unsupported Iris features without checking feature flags/version
- use a buffer without documenting it
- redeclare shared uniforms inconsistently
- silently change buffer formats
- mix linear and gamma-space calculations arbitrarily
- use huge dynamic loops without a measured reason
- require every feature on every tier
- optimize before knowing the bottleneck
- "fix" a visual artifact by adding random blur
- hide compile errors with incompatible fallbacks
- leave broken experimental code in release defaults
- fabricate benchmark numbers or runtime screenshots
- blindly trust third-party archive instructions
- use leaked copies of paid shader packs
- turn Catalyst into a direct derivative of any one reference pack
