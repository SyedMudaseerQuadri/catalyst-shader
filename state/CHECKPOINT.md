# Catalyst Recoverable Checkpoint

## Type
Implementation checkpoint: M1 shaderpack + M2 materials, compile-verified, not yet run in-game. Date 2026-10-09.
Git checkpoints: tag `m1-compile-verified`, then tag `m2-materials-compile-verified`. Rebuild the zip with `tools/package_shaderpack.py`.

## Known truth
- Canonical aesthetic direction: `docs/visual/aesthetic_direction.md`
- Official visual presets: Vanilla Enhanced / Natural / Realistic / Cinematic (`VISUAL_PRESET` option)
- Official performance presets: Performance / Balanced / Quality / Ultra / Cinematic (Iris profiles)
- Minimum hardware: RTX 3050 8GB, Performance preset at 1080p (D-006, target only)
- Pass graph and buffer contracts: `docs/architecture/pass_graph.md`, `docs/architecture/data_contracts.md`
- Historical Codex/dual-agent instructions are non-authoritative under `archive/superseded_active/`.

## Verification state
- Iris feature set: checked in source (EV-001); runtime UNVERIFIED.
- Shader compilation: PASS under Khronos glslang 16.6.0 (pinned), 2496 compilations across 24 configurations (incl. TAA off), 2026-10-11.
- Specular BRDF energy conservation: PASS (EV-003).
- Shader runtime: loads in-game (EV-004). Debug views PASS. Normal-view look: interior REWORK fixed in 0.2.1, re-test pending. Performance: UNVERIFIED.
- Cross-vendor GPU validation: not available.

## In-game test protocol (EV-004: 0.2.0-m2a, EV-005: 0.2.1; record the next run as EV-006)
Use **F2** screenshots (not a snipping tool), Debug View = Off, profile **Balanced**, `/weather clear`, the same
camera spots, times `/time set 1000`, `6000`, `12500`, `18000`; FPS overlay visible. Scenes: the white room,
the cherry-grove view, water, a cave with a torch, the Nether. Pair each with a vanilla F2 shot from the same spot.
1. Pack loads with no errors in `logs/latest.log` (search "Iris" / "shader").
2. Overworld noon, sunset, night, rain: sky, sun/moon, shadows and fog look plausible; no black or NaN pixels.
3. Nether and End load (no shadow pass there) with readable lighting.
4. Underwater, lava and powder-snow views apply medium fog.
5. Each debug view (Options > Debug) shows sensible data: albedo, normals, light levels, materials, depth, sun shadow.
6. Switch all 5 profiles and 3 visual styles; each reloads without errors.
7. Note FPS at 1080p on the RTX 4060 for Performance and Balanced (proxy data only until I-001 is resolved).
8. With a LabPBR resource pack: bumps are lit from the sun's side (not inverted); metals reflect the sky; Debug > Smoothness shows the pack's data.
9. Without a resource pack: vanilla blocks look the same as with `Resource Pack Materials` off (no added shine).
10. TAA (build after 0.3.0): block edges and leaves smooth and stable when still; turning the camera does not smear;
    the held item has no trail; teleport (`/tp ~100 ~ ~`) and Nether portal show no flash of old frames; note the FPS
    with Anti-Aliasing > Temporal Anti-Aliasing on and off.
11. Clouds (M3): clear sky shows scattered 3D clouds with bright tops and grey bases; their shadows move over the
    ground; `/weather rain` thickens them over ~1 min, `/weather thunder` darkens them; lightning flashes light sky,
    clouds and ground. Note FPS with Clouds = Catalyst vs Vanilla (cost scales with the profile).
12. Wetness (M3): in rain, open ground darkens and shines, puddles appear on flat ground after a while and dry
    slowly after `/weather clear`; covered areas stay dry; deserts never get wet.
13. Snow (M3): in a snowy biome during snowfall, block tops whiten unevenly over ~1 min and melt slowly afterwards.
14. Wind (M3): grass and leaves sway in gusts (stronger in rain); their shadows move with them; no gaps between
    leaf blocks. Morning (`/time set 0`) shows thin mist in valleys, none on mountain tops.
15. Water above (M4): shallow water is clear, deep water darkens to blue; swamp water is murky green-brown; the
    surface refracts the bottom, reflects terrain/sky/clouds more at grazing angles, waves grow with wind/rain/storm,
    raindrops make rings; thin water at shores shows faint foam. No flicker when moving (TAA).
16. Under water (M4): sun reaches the bottom as moving caustics, dimmer with depth; light shafts from the surface;
    looking up shows the sky through a circular window and mirror-like water beyond it.
17. Surfacing (M4): water runs down the view for a few seconds. Stained glass casts colored shadows.
18. Note FPS with Water > Terrain Reflections on/off and Underwater Light Shafts on/off.
19. Bounce light (M5): in the test room and next to a lava pool, compare Lighting > Bounce Light on/off: corners
    get soft contact shadows, sunlit floors/lava tint nearby walls; the room must NOT get brighter/flatter overall
    than with it off (watch item, D-016). Note FPS on/off.
20. Reflections (M5): puddles in rain reflect nearby trees/blocks, not only the sky; no reflections floating in
    mid-air when turning the camera.
21. Volumetric light and bloom (M5): morning sun through trees shows soft shafts; torches/lava/sun glow slightly;
    dark caves stay dark (bloom must not lift them). The three visual styles look distinct but all readable.

## Safe resume
Run `python tools/fetch_glslang.py` once, then `python tools/validate_shaderpack.py` (must PASS); continue from `CURRENT.md`.
