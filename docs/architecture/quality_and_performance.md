# Catalyst — Quality, Performance & Scaling

## Official performance presets

| Preset | Intent | Typical levers |
|---|---|---|
| Performance | maximize stability/FPS | reduced resolution/samples/update frequency, simplified expensive effects |
| Balanced | default tradeoff | moderate quality and stable temporal reuse |
| Quality | image quality first within practical limits | higher shadows, reflections, volumes, reconstruction |
| Ultra | high-end raster/advanced features | high resolution/samples and richer optional systems |
| Cinematic | maximum practical presentation | highest validated budgets; strongest visual effects that remain coherent |

These are the only canonical performance preset names.

## Performance engineering
Performance is a design requirement. Measure before deep optimization. For expensive effects track resolution, samples, texture reads, image loads/stores, loop bounds, memory, history, update frequency, and observed frame time when available. Prefer reuse, safe low-resolution passes, bounded loops, and explicit feature elimination.

## Graceful degradation
Every optional subsystem defines full, reduced, user-disabled, unavailable-capability, and failed-subsystem behavior.

## Budget rule
A preset name never excuses uncontrolled cost. When measured cost exceeds budget: reduce quality, reduce frequency/resolution, redesign, defer, replace, or move the feature to a higher preset.
