# Catalyst — First Run and Resume Protocol

This file is supporting procedure; `CLAUDE.md` is the operating authority.

## First run
1. Inspect repository structure, active docs, existing shader source if present, available tools/tests if present, reference archives, and environment.
2. Read the project vision/requirements, canonical aesthetic direction, architecture overview, compatibility target, and current roadmap.
3. Inspect existing state files. If absent or stale, create/reconcile them.
4. Verify capabilities that are actually needed for the current milestone. Do not exhaustively retest unchanged capabilities on every session.
5. Inventory references and licenses as needed; do not exhaustively process the reference library unless a milestone requires it.
6. Establish a known-good checkpoint before risky implementation.
7. Start at the milestone recorded in `state/MILESTONES.md` and `state/CURRENT.md`.

## Resume
1. Read `state/CURRENT.md`.
2. Read `state/CHECKPOINT.md`.
3. Inspect the actual repository files named by the checkpoint.
4. Read relevant open issues/decisions and only task-relevant architecture/feature docs.
5. Reconcile any disagreement between state and code/tests before implementing new work.
6. Continue the current milestone rather than restarting completed work.

## Context efficiency
Use the state layer as project continuity memory. Do not use long session transcripts or repeated master prompts as the primary memory mechanism.
