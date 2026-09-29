# Merge Provenance

This package merges, in order of authority:
1. **Catalyst_Codex_Ultimate** — provided `MASTER_PROMPT_CODEX.md`, `AGENTS.md` core, and the
   overall docs/ skeleton, including the named-reference visual target matrix and KappaPT/
   NostalgiaVX leaked-source policy not present in earlier generations.
2. **Catalyst_Engineering_Additions** — provided the fully detailed versions of
   `rendering_technical_standard.md`, `decision_hierarchy.md`, `gpu_budget.md`,
   `visual_quality_matrix.md`, and the ADR policy (these were thin stubs in Ultimate).
3. **Catalyst_Master_Prompt_for_Codex_v2 / Improved** (earlier generation) — supplied the
   deepest per-topic research guidance, the full engineering-governance section, the complete
   milestone/roadmap detail, failure-mode catalog, and capability-declaration depth, merged in
   as `docs/research/deep_research_guide.md`, `docs/architecture/governance.md`,
   `docs/architecture/catalyst_architecture.md`, `docs/standards/*`, and "Extended reference"
   sections appended to several docs that Ultimate had only stubbed.

Where Ultimate and the older generation both covered a topic, Ultimate's version is kept as
the primary content (it is better-written and more current); the older generation's material
is appended underneath as "Extended reference" rather than discarded, so no technical detail
from any source is lost.

## Round 2 — Catalyst_Codex_Package_FINAL.zip
Folded in three improvements from this later upload:
- `docs/architecture/decision_hierarchy.md` replaced with its version — more granular tiers
  (separates "stable architecture" and "scalability") and an explicit single-source-of-truth
  instruction, now also applied to `AGENTS.md` (which points here instead of restating the list).
- `docs/architecture/aesthetic_direction.md` — new. Maps named references (Eclipse, Bliss,
  KappaPT, Complementary Unbound, AstraLex) to specific subsystems without relaxing the
  provenance/licensing rules.
- `docs/release/compatibility.md` — new. Forces an explicit, evidence-backed Minecraft/Iris/
  hardware target instead of an implicit "current version" assumption.

## Round 3 — Deduplication pass
Removed a real efficiency problem: several `docs/` files (capabilities, pass_graph,
deferred_ideas, requirements_matrix, ROADMAP, failure_mode_catalog) contained the same
information twice — once as a short primary version, once appended underneath as "Extended
reference" from the older generation. Every one of those files has been rewritten as a single
non-duplicated version that keeps every distinct fact from both sources, so a Codex session
reading these files no longer pays to read the same guidance twice. Also fixed a shell-escaping
artifact (`-e` literal text) left over from the round-1 build script, and normalized leftover
raw section numbering (`# 9. FOO`) from the original source prompts into clean subheadings.
No information was removed in this pass — only repeated text.

## Round 4 — Bug fix + last duplication removed
- Fixed a real bug: 24 section headers across 7 files were duplicated back-to-back
  (e.g. "## Material system" printed twice in a row with nothing between), left over from
  the original build script. All fixed — content is unchanged, just no longer mis-headed.
- Trimmed the 8 subsystem sections in `MASTER_PROMPT_CODEX.md` (light transport, materials,
  shadows, temporal, atmosphere, water, GI/voxel/RT/PT, denoising) that duplicated
  `docs/architecture/catalyst_architecture.md` almost word-for-word. Each is now a short
  summary plus a pointer to the doc, instead of the full text appearing twice in the
  repository. `MASTER_PROMPT_CODEX.md` dropped from ~3,240 to ~2,850 words with zero loss of
  information — the detail still exists, once, in `docs/`.

This is the version to hand to Codex. No known duplication or bugs remain.
