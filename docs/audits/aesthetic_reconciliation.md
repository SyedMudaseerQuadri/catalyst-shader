# Catalyst — Aesthetic Update Reconciliation

> Status: audit/history only. `docs/visual/aesthetic_direction.md` and current project/architecture/state documents are authoritative.


## Change-set
The latest `docs/visual/aesthetic_direction.md` is treated as the newest visual/product-direction input. It is canonical for aesthetic intent.

## Affected areas

### Directly affected
- visual authority and documentation hierarchy;
- visual preset model;
- performance preset naming;
- environmental-state architecture;
- weather/cloud/atmosphere sequencing;
- wetness and snow placement;
- water/underwater architecture;
- foliage response;
- temporal requirements and invalidation;
- settings UX and override precedence;
- gameplay/readability safeguards;
- visual test scenes and regression criteria;
- research priorities and reference-decision work;
- roadmap and milestone gates;
- performance scaling and release checks.

### Indirectly affected
- feature dependency graph;
- material contracts where wetness/snow response is required;
- exposure/post-processing decisions;
- debug views;
- compatibility/capability verification for environmental inputs;
- release documentation and presets.

### Not automatically affected
- reference shader source archives;
- historical source prompts;
- implementation details that do not participate in the revised visual dependencies.

## Authority resolution
`docs/visual/aesthetic_direction.md` is the single visual authority. the retired visual-target summary, Codex prompts, migration notes, and historical specs are archived and non-authoritative.

## Reconciliation outcome
The roadmap now brings environmental state, temporal services, settings semantics, and readability safeguards earlier. Wetness/snow are no longer postponed to a generic late-stage optimization milestone. High-end GI/RT/PT remains conditional on measured evidence rather than being allowed to drive the foundational architecture prematurely.
