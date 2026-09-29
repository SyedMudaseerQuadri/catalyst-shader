# Catalyst — Engineering Governance

Evidence discipline, ADRs, benchmarking, checkpoints, scope control, gate progression.

## Engineering governance, evidence, and execution control

This section governs how Catalyst is researched, implemented, validated, and maintained.
It exists to prevent scope drift, unsupported assumptions, endless research, unmeasurable claims, and unrecoverable autonomous changes.

## 51.1 Target compatibility matrix

Before architecture decisions become implementation commitments, create:

`docs/release/compatibility.md`

Record:

- exact target Minecraft version;
- exact target Iris version;
- supported Minecraft/Iris version range, if more than one is intentionally supported;
- Java/runtime requirements;
- OpenGL capability baseline;
- Sodium/Iris assumptions relevant to the target;
- required Iris capabilities;
- optional Iris capabilities;
- unsupported capabilities;
- minimum hardware target;
- recommended hardware target;
- VRAM expectations;
- known driver/vendor constraints;
- available test environments.

Never treat the phrase “current Minecraft” or “current Iris” as a sufficient compatibility target.
All version-sensitive implementation decisions must reference a concrete target version or an explicitly documented compatibility range.

If a feature differs between supported versions, isolate the compatibility layer and document the difference rather than silently mixing assumptions.

## 51.2 Requirement classification

Classify major requirements into:

### Release-critical
Must work correctly for the intended release target.

### High-end target
Important intended capability that may be deferred when evidence, compatibility, or performance does not justify immediate implementation.

### Future/research
Architecture should not unnecessarily block it, but implementation is not required until justified.

Do not treat every item in the long-term feature list as equally mandatory for the first release.

Maintain the authoritative classification in:

`docs/architecture/requirements_matrix.md`

## 51.3 Research triage

Do not spend equal effort on every reference pack or every subsystem.

Use three research levels:

### Level 1 — Inventory
For every reference:
- identity/version;
- files;
- source statistics;
- licenses;
- major program types;
- notable capabilities.

### Level 2 — Comparative analysis
For every major subsystem:
- identify the strongest relevant references;
- summarize competing approaches;
- identify tradeoffs;
- determine which approaches require deeper investigation.

### Level 3 — Deep tracing
Trace actual control flow and data flow only for the strongest or most architecture-relevant candidates.

The objective is sufficient evidence for correct engineering decisions, not exhaustive reading of every line of every archive.

Stop redundant research once the evidence is sufficient to make the next decision with justified confidence.

## 51.4 Evidence classification

For every architecture-critical external claim, classify the evidence:

- **A — Directly verified:** confirmed from supplied source, official documentation, or an actually executed test.
- **B — Strongly supported:** supported by multiple credible sources or independent observations.
- **C — Observed/inferred:** inferred from behavior, screenshots, source patterns, or other indirect evidence.
- **D — Hypothesis:** plausible engineering assumption not yet verified.

Architecture-critical decisions should not rely solely on C or D evidence when the claim can reasonably be verified.

Record evidence level in research and architecture documents.

## 51.5 External-source provenance

For every Catalyst subsystem materially influenced by external research, record in:

`docs/research/provenance.md`

- source;
- source version;
- concept studied;
- evidence reviewed;
- Catalyst-specific interpretation;
- implementation differences;
- license/usage constraints;
- whether the influence is conceptual, algorithmic, or implementation-independent.

Do not copy:
- source-code control flow;
- identifiers;
- comments;
- magic constants;
- file organization;
- naming schemes;
- implementation-specific structure

merely because it is convenient.

Catalyst must remain an independently designed implementation.

## 51.6 Architecture Decision Records

Create:

`docs/architecture/adr/`

For every major or difficult-to-reverse architecture decision, write an ADR containing:

1. problem;
2. context;
3. constraints;
4. alternatives considered;
5. evidence;
6. decision;
7. expected benefits;
8. known costs;
9. rejected alternatives;
10. migration/rollback implications.

Do not hide major architecture decisions inside implementation commits only.

## 51.7 Measurable acceptance criteria

Every milestone and every expensive subsystem must define measurable acceptance criteria before being declared complete.

Where applicable, record:

- compilation status;
- load/startup status;
- runtime error count;
- frame-time budget;
- VRAM budget;
- resource count;
- internal resolution;
- sample count;
- artifact severity;
- image-regression threshold;
- temporal stability criteria;
- supported feature set;
- explicitly deferred features.

Subjective visual judgment is allowed as a design input, but it is not sufficient by itself for critical technical acceptance.

## 51.8 Standard performance benchmark protocol

Create:

`docs/testing/performance_benchmark_protocol.md`

Whenever performance is measured, record:

- GPU;
- CPU where relevant;
- driver/runtime;
- Minecraft version;
- Iris version;
- Catalyst version/commit;
- resolution;
- render distance;
- simulation distance if relevant;
- scene/test identifier;
- camera position/path;
- time of day;
- weather;
- preset/profile;
- relevant feature configuration;
- warm-up frames/time;
- measurement duration;
- average frame time;
- percentile frame times where available;
- VRAM usage where measurable;
- comparison baseline.

Do not compare benchmark results collected under materially different conditions without clearly labeling the difference.

Never invent or interpolate missing benchmark measurements.

## 51.9 Known-good checkpoints

Maintain:

`docs/testing/known_good_state.md`

At each major checkpoint record:

- current known-good commit/checkpoint;
- supported environment;
- implemented features;
- known failures;
- current benchmark status;
- current architecture state;
- next intended milestone.

Before risky architectural migrations, create a recoverable checkpoint.

Never destroy the last known-good state merely to continue experimentation.

## 51.10 Resource ownership and synchronization

For advanced GPU resources, explicitly document:

- producer;
- consumer;
- read/write ownership;
- access mode;
- initialization state;
- clear policy;
- synchronization requirements;
- lifetime;
- ping-pong/flip behavior;
- resize/recreation behavior;
- invalidation behavior;
- debug representation.

This applies especially to:
- custom images;
- 3D resources;
- SSBOs;
- voxel data;
- temporal histories;
- accumulation buffers.

Never rely on an undocumented synchronization assumption.

## 51.11 Temporal invalidation policy

Create and enforce a central history-reset policy.

Invalidate affected temporal history when appropriate after:

- shader reload;
- dimension change;
- render-resolution change;
- major preset/feature change;
- camera teleport or sufficiently large discontinuity;
- time discontinuity;
- exposure discontinuity;
- major weather-state transition;
- voxel-volume relocation/rebuild;
- resource recreation;
- any condition that makes reprojection invalid.

Do not let each subsystem invent incompatible history-reset rules.

## 51.12 Graceful degradation

Every optional feature must define behavior for:

1. full implementation available;
2. reduced-quality implementation available;
3. feature disabled by user;
4. capability unavailable;
5. capability incompatible;
6. temporary subsystem failure.

Optional features should degrade cleanly rather than unnecessarily invalidating the renderer.

Document fallback quality and expected visual differences.

## 51.13 Scope control

Do not expand the project merely because an interesting rendering technique is discovered.

Before adding a new subsystem, evaluate:

- user-visible benefit;
- image-quality benefit;
- architectural impact;
- compatibility impact;
- performance impact;
- validation burden;
- maintenance cost.

Record interesting but deferred techniques rather than automatically implementing them.

Maintain deferred work in:

`docs/architecture/deferred_ideas.md`

## 51.14 Stop / defer / replace conditions

Stop expanding a subsystem when one or more of the following is true:

- required platform capability is unavailable;
- repeated validation demonstrates architectural incompatibility;
- performance materially exceeds the defined budget;
- correctness cannot be established with available evidence;
- a critical dependency is unavailable;
- the implementation has become disproportionately complex relative to its benefit;
- the required research cannot be completed lawfully;
- validation infrastructure is insufficient for a release-critical claim.

When this occurs:

1. preserve the last known-good state;
2. document the blocker;
3. isolate the affected scope;
4. evaluate alternatives;
5. defer, simplify, or replace the subsystem;
6. continue unaffected work where practical.

Do not spend unlimited effort forcing an unsuitable approach to work.

## 51.15 Autonomous decision rule

Do not ask the human to decide routine engineering questions that can be resolved from evidence.

Make the best-supported decision and document it.

Ask/block only when:
- requirements genuinely conflict;
- the environment lacks information required to proceed safely;
- a decision has substantial irreversible product implications that cannot reasonably be inferred;
- user ownership, legal permission, or explicit scope is required.

When blocked, clearly state the exact missing input rather than asking a broad generic question.

## 51.16 Repository vs release-package boundary

Treat these as separate artifacts:

### Development repository
May contain:
- research;
- temporary analysis;
- tests;
- benchmarks;
- debug tools;
- architecture records;
- source references;
- development-only utilities.

### Release shaderpack
May contain only:
- required runtime files;
- required licenses/credits;
- user-facing documentation;
- supported configuration;
- release-safe resources.

Never accidentally package research archives, temporary files, internal benchmarks, or development-only artifacts into the release shaderpack.

## 51.17 Gate-based progression

A milestone may proceed only after its gate is evaluated.

Each gate must answer:

- Is the implementation structurally correct?
- Is it actually validated?
- Are known failures understood?
- Does it satisfy the defined performance budget?
- Does it preserve prior supported behavior?
- Is the documentation updated?
- Is the checkpoint recoverable?

Possible gate outcomes:
