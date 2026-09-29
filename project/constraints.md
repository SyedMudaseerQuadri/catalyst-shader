# Catalyst Project Constraints

- Target environment is pinned in `docs/release/compatibility.md`; never use “current Minecraft” as an implementation target.
- The latest canonical visual direction is `docs/visual/aesthetic_direction.md`.
- No visual-reference pack is an implementation source of truth.
- No global preset names may be introduced without an ADR that reconciles them with the official 3 visual + 5 performance model.
- Release-critical claims require evidence.
- Experimental high-end techniques must not destabilize the foundational renderer.
- Environmental state must be designed as reusable shared state, not duplicated in each effect.
