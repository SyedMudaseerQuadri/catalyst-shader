Catalyst — Minecraft Java shader pack (development build 0.4.0)

Requirements
  Minecraft 1.21.11, Fabric Loader, Fabric API 0.141.6, Sodium 0.8.x, Iris 1.10.7.
  Minimum GPU: NVIDIA RTX 3050 (8 GB) using the "Performance" profile at 1080p (target, not yet benchmarked).

Install
  Copy this zip into .minecraft/shaderpacks/ and select "Catalyst" in Options > Video Settings > Shader Packs.

Presets
  Performance preset: use the "Profile" button (Performance / Balanced / Quality / Ultra / Cinematic).
  Visual style: "Visual Style" option (Vanilla Enhanced / Natural / Realistic / Cinematic).
  The two are independent. Sliders adjust on top of the chosen visual style.

Features
  Lighting: sun/moon light with soft shadows, sky light, warm block light, bounce light and ambient occlusion
  (screen-space GI), LabPBR 1.3 resource-pack materials, temporal anti-aliasing.
  Environment: volumetric clouds with cloud shadows, weather-driven cloud cover, rain wetness and puddles,
  snow cover, gusty wind moving foliage, lightning, valley mist, volumetric sunlight, bloom.
  Water: waves and rain ripples, refraction, depth-based color (murky swamps, clear oceans), terrain/sky/cloud
  reflections, shoreline foam, caustics and light shafts under water, droplets on the view after surfacing.

Known limitations
  Reflections and bounce light only use what is on screen. Fast mobs may leave a faint trail with TAA.
  Underwater caustics, shafts and volumetric light need Shadows. Snow trails and seasons are not supported.
  Performance has not been measured yet. Debug views are under Options > Debug (keep Off for play).
