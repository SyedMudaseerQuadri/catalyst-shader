# Catalyst — Codex Repository Operating Policy

The authoritative high-level instructions are in `MASTER_PROMPT_CODEX.md`.

## Source of truth
The repository and its persistent `docs/` state are authoritative. Do not assume previous-session memory.

## Session start
Read:
1. `docs/testing/known_good_state.md`
2. `docs/environment/capabilities.md`
3. `docs/architecture/requirements_matrix.md`
4. relevant ADRs
5. relevant deferred/research notes

## Priority
See `docs/architecture/decision_hierarchy.md` for the authoritative priority order used to
resolve engineering tradeoffs. Do not restate that list anywhere else — one source of truth only.

## Compatibility target
Establish and consult `docs/release/compatibility.md` before any version-sensitive decision.
"Current Minecraft" / "current Iris" are not valid targets — the file starts as UNSET and must
be populated during M0.

## Evidence
Use VERIFIED/PARTIAL/UNVERIFIED/BLOCKED/DEFERRED status. Never fabricate runtime or benchmark evidence.

## Research
Use supplied references as research material. Do not copy substantial third-party source or proprietary/leaked implementations.

Full reference source is available at `reference_shaders/` (one subfolder per pack, all fully usable
as study material): Eclipse, Solas, Bliss, BSL, Complementary Reimagined, Complementary Unbound,
Photon, AstraLex, Rethinking Voxels, IterationT, Derivative, Shrimple, Mellow, Noble, UlE-LITE,
Fantasy Shaders Reimagined, Fantasy Shaders Unbound, Kappa, Nostalgia. Treat this as read-only study
material — study architecture, structure, and technique, but never copy files from it into Catalyst's
own source, and never use it as a starting point for the ground-up rebuild.

Note: `Kappa`/`Nostalgia` above are the free base packs (full source supplied, fully usable). Their
paid upgrade editions — **KappaPT** and **NostalgiaVX** — were NOT supplied and are NOT present in
`reference_shaders/`. Per the policy in `docs/CATALYST_SPEC.md` and `docs/FIRST_SESSION_PROMPT.md`,
KappaPT/NostalgiaVX must be studied from public screenshots, videos, and documentation only — never
from leaked or paywalled archives. See `docs/architecture/aesthetic_direction.md` for priority tiers.

## Engineering
Maintain authoritative contracts for resources, uniforms, coordinates, depth, color, materials, temporal state, voxel/ray conventions, and numerical behavior.

## Execution
Research enough → decide → implement → validate → measure → document → checkpoint.

## Visual direction
Catalyst should be cinematic and exceptional. Study the preferred reference qualities documented
in `docs/visual/visual_target.md` and `docs/architecture/aesthetic_direction.md` (which maps
specific references to specific subsystems), but do not clone any reference pack, and never let
the pursuit of a look outrank the decision hierarchy above.

## Full docs index (final merged package)
- `MASTER_PROMPT_CODEX.md` — the pastable, authoritative execution prompt (paste this into Codex first).
- `docs/CATALYST_SPEC.md`, `docs/FIRST_SESSION_PROMPT.md` — project identity and bootstrap steps.
- `docs/environment/capabilities.md` — capability declaration (update every session).
- `docs/research/` — `deep_research_guide.md` (per-topic deep-dive guidance), `provenance.md`, `reference_decision_matrix.md`.
- `docs/architecture/` — `catalyst_architecture.md` (overview + subsystems), `pass_graph.md`, `data_contracts.md`, `uniform_contracts.md`, `feature_dependency_graph.md`, `rendering_technical_standard.md`, `decision_hierarchy.md`, `governance.md`, `quality_and_performance.md`, `requirements_matrix.md` (live tracking table), `deferred_ideas.md`, `adr/README.md`.
- `docs/performance/gpu_budget.md` — budget model and optimization policy.
- `docs/testing/` — `known_good_state.md` (rewrite every session), `failure_mode_catalog.md`, `validation_and_regression.md`, `visual_quality_matrix.md`, `performance_benchmark_protocol.md`.
- `docs/visual/visual_target.md`, `docs/architecture/aesthetic_direction.md` — named-reference visual inspiration, mapped to subsystems (study, never clone).
- `docs/release/compatibility.md` — version/hardware compatibility target (UNSET until M0 fills it in; consult before version-sensitive decisions).
- `docs/ROADMAP.md` — M0–M10 milestones and Definition of Done.
