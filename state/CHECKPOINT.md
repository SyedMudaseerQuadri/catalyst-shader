# Catalyst Recoverable Checkpoint

## Type
Implementation checkpoint: M1 shaderpack, compile-verified, not yet run in-game. Date 2026-09-30.
Git checkpoint: the first commit on `main` (tag `m1-compile-verified`). Rebuild the zip with `tools/package_shaderpack.py`.

## Known truth
- Canonical aesthetic direction: `docs/visual/aesthetic_direction.md`
- Official visual presets: Vanilla Enhanced / Natural / Realistic / Cinematic (`VISUAL_PRESET` option)
- Official performance presets: Performance / Balanced / Quality / Ultra / Cinematic (Iris profiles)
- Minimum hardware: RTX 3050 8GB, Performance preset at 1080p (D-006, target only)
- Pass graph and buffer contracts: `docs/architecture/pass_graph.md`, `docs/architecture/data_contracts.md`
- Historical Codex/dual-agent instructions are non-authoritative under `archive/superseded_active/`.

## Verification state
- Iris feature set: checked in source (EV-001); runtime UNVERIFIED.
- Shader compilation: PASS under Khronos glslang, 2058 compilations across 21 configurations (EV-002).
- Shader runtime / visuals / performance: UNVERIFIED (I-002).
- Cross-vendor GPU validation: not available.

## M1 in-game check list (record as EV-003)
1. Pack loads with no errors in `logs/latest.log` (search "Iris" / "shader").
2. Overworld noon, sunset, night, rain: sky, sun/moon, shadows and fog look plausible; no black or NaN pixels.
3. Nether and End load (no shadow pass there) with readable lighting.
4. Underwater, lava and powder-snow views apply medium fog.
5. Each debug view (Options > Debug) shows sensible data: albedo, normals, light levels, materials, depth, sun shadow.
6. Switch all 5 profiles and 3 visual styles; each reloads without errors.
7. Note FPS at 1080p on the RTX 4060 for Performance and Balanced (proxy data only until I-001 is resolved).

## Safe resume
Run `python tools/validate_shaderpack.py --glslang <glslang.exe>` (must PASS), then continue from `CURRENT.md`.
