# Catalyst Open Issues

## I-001 — No minimum-target test hardware
The minimum hardware target is the RTX 3050 (D-006), but the only test machine is an RTX 4060. Until
someone runs benchmarks on an RTX 3050, or an agreed proxy method is documented (for example capping the
RTX 4060 clocks/VRAM, with its limits stated), every claim that Catalyst meets its minimum target stays
UNVERIFIED, and release gates that depend on it can only reach PASS WITH KNOWN LIMITATIONS.

## I-002 — No Minecraft + Iris runtime available to the agent (blocks the M1 gate)
The development machine has no Fabric/Sodium/Iris 1.21.11 client installed (docs/environment/capabilities.md).
The M1 shaderpack compiles offline (EV-002), but loading, visuals and performance are UNVERIFIED.
**Unblock:** install Fabric Loader + Fabric API 0.141.6 + Sodium 0.8.7 + Iris 1.10.7 for 1.21.11, copy
`dist/Catalyst-0.1.0-m1.zip` into `.minecraft/shaderpacks/`, then run the M1 check list in `state/CHECKPOINT.md`.

## I-003 — RESOLVED 2026-09-30: project has its own Git repository
`catalyst_final_v3/` is now its own repository (branch `main`). `reference_shaders/` (third-party) and `dist/`
(build output) are ignored. Remote: https://github.com/SyedMudaseerQuadri/catalyst-shader (public, `origin`).

## I-004 — Project license not chosen
The release zip ships without a LICENSE. The license is a product decision for the human. Also confirm that no
reference pack license affects Catalyst (no reference source was used; see docs/research/provenance.md).
