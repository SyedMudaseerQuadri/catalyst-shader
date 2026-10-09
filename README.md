# Catalyst — Claude Code Native Workspace

Catalyst is a Minecraft Java shader project organized for long-running Claude Code development.

## Start here
1. Read `CLAUDE.md`.
2. On first run, follow `docs/FIRST_SESSION_PROMPT.md` or use the `/bootstrap` project command.
3. Check `state/CURRENT.md` and `state/CHECKPOINT.md` before resuming work; `/resume` follows the same protocol.
4. Use `project/` for product truth and `docs/visual/aesthetic_direction.md` as the single canonical visual authority.
5. Use `docs/architecture/` for technical contracts, `docs/ROADMAP.md` for milestone order, and `state/` for continuity.

## Canonical presets
Visual: Vanilla Enhanced / Natural / Realistic / Cinematic.
Performance: Performance / Balanced / Quality / Ultra / Cinematic.

## Context policy
The package intentionally avoids speculative `tests/` and `tools/` directories before durable implementation assets exist. When real tooling or test assets are created, add them deliberately and document their maintained purpose. Testing methodology lives under `docs/testing/`; persistent evidence lives under `state/evidence/`.

## Install a build
Download `Catalyst-<version>.zip` from the repository's **Releases** page (not "Code > Download ZIP", which contains
the whole development repository) and put it in `.minecraft/shaderpacks/`.

## Shaderpack and tools
- `shaderpack/Catalyst/` — the Iris shader pack source (`shaders/`: `lib/` shared code, `program/` stage code, `world0|world-1|world1/` per-dimension entry points).
- `tools/fetch_glslang.py` — installs the pinned Khronos glslang build into `tools/.cache/` (run once).
- `tools/validate_shaderpack.py` — offline compile of every program x preset configuration with that glslang, plus pack consistency checks. Run before every checkpoint.
- `tools/tone_sim.py` — CPU simulator of indirect light, exposure and tonemapping; tune colors against in-game evidence before shipping.
- `tools/package_shaderpack.py` — builds `dist/Catalyst-<version>.zip` from runtime files only.

## Research material
`reference_shaders/` is a study library. It is not an implementation source and should not be loaded wholesale for routine tasks. Historical prompts and superseded project documents are under `archive/`.
