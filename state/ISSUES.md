# Catalyst Open Issues

## I-001 — No minimum-target test hardware
The minimum hardware target is the RTX 3050 (D-006), but the only test machine is an RTX 4060. Until
someone runs benchmarks on an RTX 3050, or an agreed proxy method is documented (for example capping the
RTX 4060 clocks/VRAM, with its limits stated), every claim that Catalyst meets its minimum target stays
UNVERIFIED, and release gates that depend on it can only reach PASS WITH KNOWN LIMITATIONS.

## I-002 — No Minecraft + Iris runtime available to the agent (PARTIAL: user can test, see EV-004)
The development machine has no Fabric/Sodium/Iris 1.21.11 client installed (docs/environment/capabilities.md).
2026-10-09: the user ran 0.2.0-m2a in-game and sent screenshots (EV-004). The pack loads; debug views pass.
The agent still cannot run the game itself, so every visual change needs a user screenshot round-trip.
**Unblock:** install Fabric Loader + Fabric API 0.141.6 + Sodium 0.8.7 + Iris 1.10.7 for 1.21.11, copy
`dist/Catalyst-0.1.0-m1.zip` into `.minecraft/shaderpacks/`, then run the M1 check list in `state/CHECKPOINT.md`.

## I-003 — RESOLVED 2026-09-30: project has its own Git repository
`catalyst_final_v3/` is now its own repository (branch `main`). `reference_shaders/` (third-party) and `dist/`
(build output) are ignored. Remote: https://github.com/SyedMudaseerQuadri/catalyst-shader (public, `origin`).

## I-004 — Project license not chosen
The release zip ships without a LICENSE. The license is a product decision for the human. Also confirm that no
reference pack license affects Catalyst (no reference source was used; see docs/research/provenance.md).

## I-005 — Interiors washed out and flat (0.2.1 fix insufficient; reworked in 0.3.0, awaiting re-test)
EV-004's "grey wood" diagnosis was wrong (the blocks are neutral white, EV-005). Real cause: light-level falloff in
linear light (~5x brighter than vanilla at mid levels) + full adaptation. 0.3.0: vanilla-like falloff powers,
level-dependent block-light hue, subtle local adaptation. Close after an F2 re-test.

## I-006 — Room lighting source unconfirmed
The Light Levels debug suggests the test room is lit by block light, not sky light. Needs the F3 "Light" readout
(sky/block) on the room floor and what is in the doorways. 0.3.0 interior tuning assumes block ~0.55, sky ~0.15.

## I-007 — Screenshot capture alters colors
Snipping-tool captures (Windows HDR/color management) shift mid-tones and primaries (EV-005). Use F2 screenshots
for evidence. Comparisons made with the same capture stay valid.

## I-008 — Daytime outdoor too dark/dull, night clouds black (FIXED in 0.3.0, awaiting re-test)
EV-005. Shoulder tonemap, daylight-normalized exposure, sun-scaled sky dome/ambient, brighter clouds with sky in-scatter.
