# Catalyst — Regression Matrix

Durable regression coverage for implemented features. Use real evidence records; `UNVERIFIED` is valid until the environment can test the case.

| Area | Scene / test | Expected behavior | Status | Evidence |
|---|---|---|---|---|
| Bootstrap/rendering | Minimal world | Shader loads and world renders without fatal shader errors | UNVERIFIED | |
| Lighting | Day/night | Stable expected direct-light response and readable night | UNVERIFIED | |
| Shadows | Shadow geometry | No unacceptable acne, peter-panning, or cascade instability | UNVERIFIED | |
| Atmosphere | Horizon/fog | Stable depth, haze, and transition behavior | UNVERIFIED | |
| Weather | Clear/rain/storm/snow | State transitions are coherent and do not break unrelated systems | UNVERIFIED | |
| Wetness/snow | Transition scenes | Surface/environment response follows supported state and remains readable | UNVERIFIED | |
| Water | Surface/shallow/deep/underwater | Continuous appearance and temporal stability | UNVERIFIED | |
| Temporal | Camera/animated scene | No unacceptable ghosting, shimmer, or history corruption | UNVERIFIED | |
| Materials | Representative material scene | Encodings remain stable across relevant passes | UNVERIFIED | |
| Dimensions | Overworld/Nether/End | Dimension-specific behavior remains valid | UNVERIFIED | |
| Performance | Benchmark scene | Declared budget is met or exception documented | UNVERIFIED | |
| Presets | Visual × performance combinations | Profiles remain coherent and obey dependency rules | UNVERIFIED | |
