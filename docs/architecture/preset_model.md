# Catalyst — Canonical Preset Model

This file distinguishes two layers that must never be conflated. Every other doc that discusses
presets or tiers defers to this file and does not restate these lists.

## Layer 1 — User-facing presets (what the player sees and selects)

These are the only options that appear in the settings menu.

### Visual presets
- **Vanilla Enhanced** — restrained improvements; closest to Minecraft identity.
- **Natural / Realistic** — default target; environmental realism is emphasized while preserving Minecraft character.
- **Cinematic** — strongest atmospheric/cinematic treatment while maintaining readability.

### Performance presets
- **Performance**
- **Balanced**
- **Quality**
- **Ultra**
- **Cinematic**

Performance presets are independent from visual style. They control computational quality and may reduce resolution, samples, update frequency, history length, shadow quality, volumetric quality, cloud quality, GI quality, reflection quality, or equivalent costs.

That's 8 named options total, across two independent axes. **Nothing else is ever surfaced as a preset name in the settings menu.**

## Layer 2 — Internal rendering tiers (how Claude/the engine decides which technology to use)

Internal to the engine, not shown to the player, never selectable directly:

- Low
- Medium
- High
- Ultra
- Extreme
- RT/PT capabilities (ray-traced / path-traced techniques, gated separately by hardware and evidence)

Each user-facing Performance preset maps internally to a combination of these tiers across
subsystems — e.g. a hypothetical mapping might run most subsystems at internal Medium under the
"Balanced" preset while running a specific cheap subsystem at internal High, or run the top
Performance preset ("Cinematic") at internal Ultra/Extreme with RT/PT enabled only where the
detected hardware and evidence-gated rollout allow it. The exact mapping is an implementation
detail decided during development (record it in an ADR once settled) — what's fixed here is that
the mapping exists and flows in this direction only: user preset → internal tier selection, never
the reverse.

This is also the language used for tier-scoped subsystem decisions elsewhere (for example, the GI
strategy in `docs/architecture/catalyst_architecture.md`, which says screen-space GI runs at
internal Low/Medium/High and voxel GI at internal Ultra/Extreme) — those are internal-tier
statements, not statements about which preset name shows in the menu.

## Hard rule

**Internal rendering tiers must never become additional presets in the settings menu.** Do not
expose "Low," "Medium," "Extreme," "RT," or "PT" as selectable options anywhere in user-facing UI.
A player choosing "Cinematic" (visual) and "Ultra" (performance) should never need to know, and
should never be shown, that this resolved internally to (for example) tier Extreme with RT enabled
on subsystem X and tier High on subsystem Y. If a future need arises to expose more granular
control, extend the existing 8 named presets or add explicit per-subsystem overrides under the
Advanced UX layer — do not add a 9th preset family built from internal tier names.

## Other controls
- Master aesthetic intensity: Vanilla-like → Natural → Enhanced → Cinematic → Immersive.
- Three independent visual axes: Minecraft identity, environmental realism, cinematic intensity.
- User overrides take precedence over automatic environmental behavior when safe.
- Beginner / Intermediate / Advanced UX layers expose different control depth without changing the underlying model.

## Naming rule
Do not introduce global user-facing presets named Low, Medium, High, Extreme, Potato, RT, PT, etc.
without an ADR changing this contract. RT/PT are internal technical rendering approaches (Layer 2),
not canonical user-facing preset names (Layer 1).
