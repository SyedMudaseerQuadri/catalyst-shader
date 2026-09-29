# Catalyst — Environment & Capability Declaration

Re-run this check at the start of every session — do not trust a stale result; the
environment or the human's setup may have changed since the last session. Test and record
each item; never assume a capability exists or is absent without actually attempting it.

Last checked: 2026-09-30 (Claude Code session on the user's Windows 11 machine).

| Capability | Status | Evidence |
|---|---|---|
| File inspection/editing | AVAILABLE | Files created and edited in this repository |
| Script execution | AVAILABLE | Python 3.14 and Git Bash ran `tools/*.py` |
| Network/internet access | AVAILABLE | GitHub API and raw file downloads succeeded |
| Access to current official Iris documentation / live public sources | AVAILABLE | Iris source read from GitHub branch `1.21.11` (EV-001) |
| GLSL/Iris compiler or validator (e.g. `glslangValidator` or equivalent) | PARTIAL | Khronos glslang 16.6.0 downloaded to the session scratchpad (not installed system-wide); validates GLSL, not Iris patching (EV-002) |
| Shader compilation | PARTIAL | Reference-compiler only; no GPU driver compile |
| Launchable Minecraft + Iris client with GPU rendering | UNAVAILABLE | `%APPDATA%/.minecraft` holds only an SKLauncher folder; no Fabric/Iris/Sodium install found |
| Screenshot capture | UNAVAILABLE | Depends on the client |
| Frame-time measurement | UNAVAILABLE | Depends on the client |
| GPU/VRAM measurement | UNAVAILABLE | Depends on the client |
| Git | AVAILABLE | Git 2.45.1; project is its own repository on `main` since 2026-09-30; remote `origin` = github.com/SyedMudaseerQuadri/catalyst-shader (public). GitHub CLI (`gh`) not installed |

Mark each **AVAILABLE**, **UNAVAILABLE**, or **PARTIAL**, with how it was determined.

## How this file governs execution

This file governs *how* the rest of the repository's instructions are executed, not
*whether* they apply.

- **If network access is UNAVAILABLE or PARTIAL:** do not fabricate documentation citations
  or claims about current Iris syntax. Proceed using the most conservative documented
  assumption available from supplied materials, classify the related decision as a low
  evidence tier (see `docs/architecture/governance.md`), and record it in the relevant ADR
  as `PENDING HUMAN VERIFICATION — no network access at time of decision`. Do not block
  implementation on this alone.
- **If a Minecraft + Iris runtime is UNAVAILABLE or PARTIAL:** substitute static analysis,
  syntax linting, and code-review-level correctness checks wherever possible. Explicitly mark
  any Definition-of-Done or acceptance-criterion item that genuinely requires in-game or
  in-hardware verification as `UNVERIFIED — requires human playtest/benchmark` rather than
  PASS. Never let a milestone gate return PASS when a release-critical criterion depends on a
  capability recorded UNAVAILABLE — use PASS WITH KNOWN LIMITATIONS instead, and name the
  limitation.
- **If a capability is AVAILABLE:** use it with no reduced standard.
