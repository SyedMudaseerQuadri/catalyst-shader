# Catalyst — Claude Code Operating Contract

Catalyst is a Minecraft Java shader project. You are the primary engineering agent operating inside this repository.

## Authority
1. Actual repository contents and verified test results are the implementation truth.
2. `project/` defines the intended product.
3. `docs/visual/aesthetic_direction.md` is the single canonical visual/aesthetic authority.
4. `docs/architecture/` defines current technical architecture and contracts.
5. `state/` records current position, decisions, issues, and resumable checkpoints.
6. `docs/research/` and `reference_shaders/` are research material, not implementation authority.
7. `archive/` is historical and non-authoritative unless specifically requested.

Never treat two documents as equal authorities when one is explicitly canonical. Do not silently revive superseded material.

## Context discipline
- On the first run, perform a broad orientation of the active project and establish the initial state.
- On later runs, read `state/CURRENT.md` and `state/CHECKPOINT.md`, verify them against the repository, then load only the documents relevant to the current task.
- Do not reread the entire documentation tree or reference library for routine work.
- Use structured state for facts/status and short prose for rationale/history.

## Default workflow
Orient → verify state → identify milestone/task → inspect affected code/docs → plan → implement the smallest coherent change → validate → record evidence → update state → checkpoint → continue.

Default to action when the next step is unambiguous. Ask the human only for genuine product/creative decisions, missing required information, unsafe/irreversible external actions, or a blocker that cannot be resolved from the repository/evidence.

## Visual direction
Use `docs/visual/aesthetic_direction.md` as the sole visual target. Do not create or revive another competing visual-target document. The three official visual presets are **Vanilla Enhanced**, **Natural / Realistic**, and **Cinematic**.

## Performance direction
The five official user-facing performance presets are **Performance**, **Balanced**, **Quality**, **Ultra**, and **Cinematic**. Performance is independent of visual style. Internally, each preset maps onto rendering tiers (Low/Medium/High/Ultra/Extreme/RT-PT — see `docs/architecture/preset_model.md`) that decide implementation technique per subsystem; those internal tiers are legitimate and used throughout the architecture docs, but must never be exposed as additional selectable presets. Do not introduce Potato/Low/Medium/High/Extreme/RT/PT as additional global *preset* families. RT/PT remain internal rendering techniques/modes, not preset names, unless a future ADR explicitly changes this rule.

## Environmental direction
Catalyst is designed as a coupled environmental renderer. Time, weather, wind, biome, season when supported, terrain/material state, water state, sun/moon angle, cloud coverage, atmosphere, light sources, and dimension may influence multiple subsystems. Build shared environmental state services early enough for downstream systems to depend on them rather than implementing disconnected weather/sky/wetness effects.

## Evidence rules
Never fabricate compilation, runtime, visual, compatibility, benchmark, or capability evidence. Use `PASS`, `PASS WITH KNOWN LIMITATIONS`, `REWORK`, `DEFER`, or `UNVERIFIED` as appropriate. A requirement is not VERIFIED merely because code exists.

## Claude Code commands
Use `/bootstrap` for first-run orientation, `/resume` for normal continuation, and `/status` for a concise verified state check. These commands are routing helpers, not additional instruction contracts.

## State and recovery
Maintain `state/CURRENT.md`, `state/CHECKPOINT.md`, `state/DECISIONS.md`, `state/ISSUES.md`, `state/MILESTONES.md`, `state/SESSION_LOG.md`, and structured evidence under `state/evidence/`. Before risky work, preserve a known-good checkpoint. On resume, reconcile state against the actual repository before continuing.

## Git
Use Git checkpoints when a repository is available. Do not force-push, delete unrelated work, or destroy the last known-good state.

## Research and provenance
Study references for principles and observable behavior. Never copy source-code structure, identifiers, comments, magic constants, or proprietary implementation. Record meaningful external influence in `docs/research/provenance.md`.
