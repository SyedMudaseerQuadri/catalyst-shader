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

## I-005 — Interiors washed out and grey (FIXED in 0.2.1, awaiting re-test)
Found in EV-004. Cause and fix recorded there. Close after an in-game re-test of the same room matches the goals.
