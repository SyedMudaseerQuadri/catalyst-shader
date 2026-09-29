# Catalyst Feature Dependency Graph

The graph below is normative for sequencing and impact analysis. A subsystem may be implemented earlier for scaffolding, but downstream features must not assume unavailable inputs.

```text
Target capability / contracts
        │
        ├── Camera + depth + transforms
        │        │
        │        ├── Motion vectors ──┐
        │        └── Material data    │
        │                             ▼
        ├── Time / dimension ──┐   Temporal services
        │                       │      │
        ├── Weather ────────────┼──────┤
        ├── Wind ──────────────┤      │
        ├── Biome/season ──────┤      │
        ├── Cloud coverage ────┤      │
        ├── Sun/moon angle ────┤      │
        ├── Atmosphere density ┤      │
        ├── Surface/water state┤      │
        └── Dimension ─────────┘      │
                 │                    │
                 ▼                    ▼
        Shared Environmental State ── Temporal response
          │       │       │       │       │
          ▼       ▼       ▼       ▼       ▼
        Sky   Atmosphere Clouds  Weather Wetness/Snow
          │       │       │       │       │
          └───────┴───────┴───────┴───────┤
                                          ▼
                        Lighting / Shadows / Foliage / Water
                                          │
                                          ▼
                                   Image quality / post
                                          │
                                          ▼
                                   Presets & scaling
```

## Rules
- Environmental state is shared; subsystem-local copies must be justified.
- Temporal history depends on explicit invalidation policy.
- Presets choose quality/behavior envelopes; they do not create hidden dependencies.
- Screen-space GI (internal rendering tiers Low/Medium/High — see `docs/architecture/preset_model.md`
  for the preset-vs-tier distinction) is part of core image quality/post and depends on the same
  foundational systems as everything else in that stage — it is not high-end.
- Voxel GI/RT/PT (internal tiers Ultra/Extreme only) sits below and depends on the same stable
  foundational systems, additive to screen-space GI rather than replacing it.
