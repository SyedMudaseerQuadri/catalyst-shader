# Catalyst Decision Hierarchy

This is the detailed engineering priority order for Catalyst. `CLAUDE.md` establishes the operating contract and defers detailed tradeoff ordering to this document.

When engineering tradeoffs conflict, use this default priority order:

1. Correctness
2. Platform (Iris/Minecraft) compatibility
3. Stable architecture
4. Temporal stability
5. Visual quality
6. Performance
7. Scalability
8. Maintainability
9. Feature breadth
10. Experimental techniques

A lower-priority goal must not silently compromise a higher-priority goal.

Exceptions require explicit evidence and documentation.

## Examples

- Do not add a visually impressive effect if it breaks temporal stability.
- Do not enable an unsupported platform capability merely because another shader pack appears to use it.
- Do not preserve an architecture only because substantial code has already been written.
- Do not sacrifice correctness for a benchmark number without documenting the tradeoff.
- Do not add experimental path-tracing infrastructure before the raster/voxel foundations are sufficiently stable.
