# Catalyst — Canonical Aesthetic Direction

This file is the authoritative visual/aesthetic target for Catalyst. It defines what the rendered world should look and feel like, not how any subsystem must be implemented. It must be read together with the repository's architecture, compatibility, licensing, provenance, testing, and decision-hierarchy documents. This document does **not** authorize changes to unrelated gameplay, APIs, architecture, or non-visual behavior.

The core principle is:

> **Enhance what Minecraft already is; don't replace what Minecraft is.**
>
> Catalyst should feel like **Minecraft viewed through a modern cinematic environmental renderer**: unmistakably Minecraft in geometry, proportions, world identity, readability, and fundamental character, but with substantially richer lighting, atmosphere, weather, water, foliage, shadows, sky, environmental interaction, and camera presentation.

Physical plausibility is the foundation, not a requirement for literal simulation. Effects may receive tasteful cinematic enhancement when that enhancement remains believable, internally coherent, Minecraft-readable, and environmentally justified.

## Scope rule

The aesthetic direction is an additive/refinement target, not a reason to rewrite unrelated systems.

When applying this document to an existing implementation or specification:

- **KEEP** behavior that already satisfies this direction.
- **REFINE** existing visual behavior that is compatible but underspecified or inconsistent with this direction.
- **ADD** genuinely missing visual/aesthetic behavior.
- **REPLACE** only visual behavior that directly conflicts with this direction.
- **DO NOT TOUCH** unrelated gameplay, non-visual functionality, APIs/contracts, compatibility behavior, or architecture unless a visual requirement genuinely requires a narrowly scoped change.

Do not interpret the presence of a requirement here as proof that the implementation already exists. The implementation and requirements matrix remain the source of truth for implementation status.

## Reference and provenance policy

Never copy source code, shaders, assets, configuration, or proprietary implementation from reference packs in pursuit of a look. Study public screenshots, videos, documentation, and observable behavior and reverse-derive techniques from first principles. Follow `CLAUDE.md`, `docs/FIRST_SESSION_PROMPT.md`, and the repository provenance/licensing requirements.

### Reference priority tiers

**Primary tier — highest priority, applies across subsystems:**
Eclipse, Solas, Bliss, BSL, Complementary Unbound, Photon, AstraLex, IterationT, Derivative, Shrimple, Kappa, Nostalgia, Rethinking Voxels.

**Primary aesthetic reference, public information only — no source and none should be sought:**
KappaPT, NostalgiaVX. Treat these paid editions according to the repository's existing policy. Do not confuse them with the free Kappa/Nostalgia packs above.

**Secondary tier — background awareness only:**
Complementary Reimagined, Noble, Mellow, UlE-LITE, Fantasy Shaders Reimagined, Fantasy Shaders Unbound.

References are studied for principles, technical tradeoffs, and visual character; Catalyst must remain its own design.

## Final visual identity

Catalyst targets a balanced combination of:

- Realistic Minecraft
- Cinematic Minecraft
- Realistic environmental simulation
- A modern cinematic environmental renderer

The user controls how far the presentation moves along those axes.

The world should remain recognizably Minecraft while allowing almost every meaningful visual aspect to be transformed through lighting, atmosphere, weather, sky, clouds, water, foliage, shadows, materials, environmental depth, and camera presentation.

### Balance

The target is approximately **60% natural/realistic environmental presentation and 40% cinematic enhancement**, with the balance remaining dynamic rather than fixed. Cinematic intensity should emerge from conditions instead of turning every scene into a movie frame.

No scene should be intentionally ugly merely because conditions are ordinary. Clear noon, ordinary afternoon, calm weather, caves, rain, storms, snow, sunrise, sunset, moonlit night, Nether, and End should all be capable of looking beautiful in their own appropriate way.

## Presentation modes and customization architecture

Catalyst exposes three visual presets (canonical list: `docs/architecture/preset_model.md`).
Presets are **starting points, never locks**, and must be coherent — not arbitrary collections
of maximum values:

1. **Vanilla Enhanced** — close to Minecraft, with restrained environmental improvements.
   Strong Minecraft identity; subtle environmental realism; conservative post-processing;
   moderate atmosphere; gameplay-first readability; enhanced but restrained water/weather/foliage.
2. **Natural / Realistic** — stronger environmental realism while preserving Minecraft identity.
   Strong environmental response; physically believable lighting; rich atmosphere; natural water
   and foliage; dynamic weather; moderate cinematic enhancement.
3. **Cinematic** — maximum atmospheric and cinematic enhancement while remaining recognizably
   Minecraft. Stronger atmosphere; more pronounced volumetrics; stronger but believable
   reflections; more dramatic weather; more visible environmental depth; enhanced god rays and
   special moments; stronger camera options. Even Cinematic mode must remain recognizably
   Minecraft and gameplay-readable.

### Master aesthetic intensity

Provide a global convenience control with a range equivalent to:

**Vanilla-like → Natural → Enhanced → Cinematic → Immersive**

This changes the overall strength of visual enhancement without replacing or hiding individual controls.

### Separate visual axes

Users should be able to independently control:

- Minecraft identity: vanilla-like → enhanced presentation
- Environmental realism: Minecraft-like → realistic environmental behavior
- Cinematic intensity: natural → cinematic

This permits combinations such as realistic environmental behavior with restrained cinematic treatment, or Minecraft-like behavior with stronger cinematic atmosphere.

### Performance presets

Canonical list: `docs/architecture/preset_model.md` (Performance / Balanced / Quality / Ultra /
Cinematic). Do not restate the list here — see that file. Performance presets are convenience
starting points and must remain individually overridable.

### User experience tiers

Settings should support three levels:

- **Beginner:** simple controls and one-click system toggles; no overwhelming parameter wall.
- **Intermediate:** grouped subsystem controls and useful sub-settings.
- **Advanced:** full per-parameter customization wherever a parameter has meaningful visual impact.

A beginner should be able to disable a major visual system with one click, while still being able to enter its sub-settings if desired.

### Full customization principle

“Fully customizable” means that if a visual system has a meaningful parameter, Catalyst should expose a control for it rather than reducing everything to a few broad sliders.

Advanced controls should cover, where technically meaningful:

- Intensity
- Density
- Color
- Temperature
- Range
- Falloff
- Softness
- Speed
- Response strength
- Environmental reactivity
- Distance behavior
- Temporal response
- Quality
- Performance cost
- Enable/disable state

### Parent/child dependencies

If a parent system is disabled, dependent effects may automatically become inactive when required for visual correctness or performance. This behavior should be clearly indicated with a warning/status marker.

Users should have an explicit override where technically safe, allowing advanced users to retain a child effect when they intentionally want it.

### User override priority

Explicit user settings take priority over automatic environmental behavior. Automatic simulation remains the default, but a user override must win over the automatically selected intensity.

## Natural-vs-cinematic rule

Natural presentation is the default philosophy. Cinematic treatment should become stronger when environmental conditions justify it:

- Sunset + mountain + cloud gap → dramatic warm breakthrough.
- Storm + dark clouds + rain + lightning → dramatic atmospheric scene.
- Dense forest + low sun → cinematic dappled shafts.
- Calm clear noon → bright, clean, readable, slightly soft sunlight rather than an over-processed movie frame.

Do **not** apply a permanent heavy cinematic color grade or blur to every scene. The cinematic character should primarily come from lighting, atmosphere, weather, environment, material response, and composition.

## Global visual safeguards

Catalyst should prevent accidental broken visuals while allowing advanced users to intentionally push settings into extreme cinematic territory.

Default safeguards should discourage:

- Completely black shadows
- Blinding bloom
- Excessive DOF
- Excessive motion blur
- Overwhelming particles
- Neon color bleeding
- Plastic-looking water
- Completely opaque atmosphere
- Flat fog walls
- Excessive gloss
- Washed-out scenes
- Oversaturation
- Cartoon-like rendering
- Noisy/flickering visuals

These are safeguards, not hard creative limits for advanced users.

## Gameplay readability

Gameplay readability is always protected by default, including in Cinematic mode:

- Mobs remain identifiable.
- Blocks remain readable.
- Terrain remains navigable.
- Important objects remain visible.
- Weather does not become visual noise.
- Particles do not overwhelm gameplay.
- DOF does not make ordinary gameplay frustrating.
- Environmental effects should enrich the scene rather than obstruct it.

## Environmental simulation model

Catalyst should behave as one interconnected environmental system. The important environmental inputs are:

- Time of day
- Weather
- Wind
- Biome
- Season, when supported by the environment/modpack
- Terrain
- Water state
- Surface/material properties
- Sun/moon angle
- Cloud coverage
- Atmospheric density
- Light sources
- Dimension

These inputs continuously influence one another.

A representative sequence is:

> Clear → clouds develop → wind changes → atmosphere changes → light changes → drizzle → rain → heavy rain → storm → rain weakens → clouds break → sunlight returns → wet world remains → gradual drying.

Each stage should be independently customizable, and different effects should change at different rates rather than snapping together.

Transitions should generally be smooth and progressive. Even sudden events should preserve temporal continuity where possible; lightning may be visually abrupt in intensity, but dependent environmental states should not become unstable or visibly snap.

## Time of day and sunlight

The day should progress continuously:

**Sunrise → morning → noon → afternoon → sunset → twilight → night → dawn**

Sunlight should respond dynamically to:

- Time
- Solar angle
- Weather
- Cloud cover
- Atmosphere
- Biome
- Season
- Dimension

Sunlight is strongest around noon and softer/warmer near sunrise/sunset, but noon light should retain a slightly soft, believable presentation rather than becoming razor-hard.

### Color temperature

- Sunrise: warm orange/gold
- Morning: gradually neutralizing
- Noon: neutral white
- Afternoon: slightly warm
- Sunset: warm and somewhat cinematically enhanced
- Twilight: progressively cooler
- Night: moon/sky driven

All transitions should be smooth and user-adjustable.

## Cloud and sky system

Clouds are a dynamic environmental system, not a decorative layer.

They should:

- Exist at multiple scales simultaneously.
- Gradually change and develop shape.
- Change speed with wind/weather.
- Move naturally across terrain.
- Cast dynamic shadows where appropriate.
- Affect direct sunlight while retaining appropriate ambient sky illumination.
- Become substantially darker/denser during severe storms.
- Produce cinematic breakthroughs when gaps permit strong light.
- Integrate with distant atmosphere and terrain.

Cloud behavior should support sequences such as:

> Clear/bright → distant clouds develop → cloud layers thicken → distant sky darkens → ambient light falls → wind increases → rain begins → lightning becomes possible.

The sky should use multiple atmospheric/depth scales rather than one flat cloud layer.

## Atmospheric depth, fog and haze

Atmosphere should be natural, cinematic, dynamic, and environmentally reactive.

Supported atmospheric character includes:

- Morning mist
- Forest mist
- Valley fog
- Mountain fog
- Rain haze
- Storm haze
- Snow/cold haze
- Swamp mist
- Underwater fog
- Cave atmosphere
- Distant terrain haze

Atmospheric density responds to:

- Time
- Weather
- Wind
- Biome
- Terrain
- Humidity-like environmental conditions
- Light
- Water
- Dimension

Distant mountains and terrain should integrate increasingly into atmospheric depth rather than disappearing into a flat fog wall.

Atmosphere should preserve enough distant information to remain visually interesting and readable.

## Lighting architecture

Lighting is one interconnected environmental system:

> **Sun/Moon → atmosphere → clouds → direct light → shadows → bounce/GI → material response → foliage → water → fog → particles → structures → player/entities**

Changing an environmental condition should be able to propagate naturally through the relevant visual systems.

### Direct light

Direct sunlight, moonlight, artificial light, firelight, emissive light, and lightning should respond to their source, surroundings, weather, and atmosphere.

### Shadows

Shadows should:

- Respond to light direction and source size.
- Become relatively harder around midday but remain slightly soft.
- Become softer around sunrise/sunset and under suitable atmospheric conditions.
- Depend on available ambient/bounced light.
- Never become completely black when environmental light exists.
- Receive subtle environmental color where physically justified.
- Remain naturally dark when conditions genuinely warrant it.

### Global illumination and bounce

Light should bounce between surfaces where the implementation supports it. Bounce depends on:

- Surface brightness
- Surface color
- Material
- Light intensity
- Distance
- Environment
- Weather
- Time

Bounce and color bleeding must remain physically believable and never become exaggerated.

### Color bleeding

Nearby materials can subtly influence surrounding illumination:

- Red glass → subtle red influence
- Green foliage → subtle green bounce
- Blue water → subtle blue influence
- Orange lava → stronger local orange influence
- Snow → bright neutral/cool bounce

The strength is fully adjustable and should become more noticeable in darkness only when conditions justify it.

### Emissive lighting

Emissive materials and light-emitting blocks should illuminate nearby surroundings where appropriate.

Different sources may have different:

- Intensity
- Color
- Falloff
- Radius
- Flicker
- Environmental response
- Visual personality

Falloff should remain soft and believable rather than producing hard artificial rings.

### Artificial light

Minecraft light sources should retain their identity while gaining richer environmental behavior:

- Torch: warm, subtle flicker
- Lantern: warm and comparatively stable
- Candle: smaller, softer source
- Glowstone: stronger, more distinctive emissive character
- Lava: strong warm environmental influence
- Other sources: source-specific behavior

### Firelight

Firelight should vary subtly with flame movement, fire intensity, wind, darkness, nearby surfaces, smoke, and weather rather than remaining a constant static light.

## Foliage and vegetation

Foliage has two separate user-selectable systems:

### Foliage appearance

**Minecraft foliage** ↔ **Realistic foliage**

The realistic option may approach a modern survival-game presentation such as the visual character of *The Last of Us*, while still preserving Minecraft geometry/world identity.

### Foliage motion

Users can choose between:

- Static
- Environmentally reactive
- User-defined motion intensity

Environmental motion responds to wind and weather. Wind behavior is random but constrained and believable:

> Mostly calm → sudden gust → settles → another gust → stronger burst → settles again.

It should not be forced into a monotonically increasing Calm → Breeze → Strong Wind sequence.

### Foliage response

Grass, leaves, trees, crops, bushes, and other vegetation should have differentiated behavior.

- Larger trees should feel different from small trees.
- Mature crops should move differently from young crops.
- Individual foliage density should affect shadows and light underneath.
- Dense canopy produces stronger dappled light and deeper shaded areas.
- Sparse foliage allows more sunlight through.
- Foliage can subtly influence surrounding environmental color.
- Fallen vegetation/debris may be enhanced but must remain small and gameplay-friendly.

Foliage should remain natural by default and become cinematic when conditions justify it.

## Water

Water should be cinematic-realistic while remaining recognizably Minecraft water.

Water behavior depends on:

- Depth
- Biome
- Water type/environment
- Weather
- Time of day
- Wind
- Surface condition
- Underwater sediment/clarity
- Lighting

### Water color and depth

Examples:

- Clear ocean → blue
- Deep ocean → progressively darker blue
- River → distinct river tone
- Swamp → murky green/brown
- Cold water → cooler
- Sunset → warm sky reflection

Shallow water should be relatively clear while deep water becomes progressively darker.

### Surface behavior

Water transitions naturally:

**Calm → gentle ripples → windy → stormy**

Surface movement, reflection breakup, wave intensity, and appearance respond continuously to wind/weather/surface conditions and are user-adjustable.

### Shoreline

Support:

- Wet shoreline
- Darkened sand
- Subtle foam
- Small wave movement
- Waterline variation
- Wet-sand reflections
- Shallow-water color transitions
- Terrain/material-dependent wetness

### Material wetness

Materials should respond appropriately:

- Stone: darker + smoother + reflective
- Dirt: darker + slightly damp
- Wood: darker + subtle sheen
- Sand: darker + subtle reflection
- Leaves: wet highlights
- Metal: stronger reflections

Wetness should transition naturally:

**Dry → slightly damp → wet → soaked → drying**

### Waterfalls

Waterfalls should respond to:

- Size
- Height
- Flow strength
- Wind
- Weather
- Terrain
- Water volume

They may produce:

- Mist
- Foam
- Spray
- Wet surrounding rocks
- Turbulence
- Sunlight interaction
- Reflections/refraction
- Subtle rainbow/light dispersion when naturally plausible
- Droplets

Large waterfalls should feel substantially different from tiny waterfalls.

## Underwater

Underwater presentation should feel immersive and cinematic without becoming gameplay-obstructive or excessively realistic.

It should respond to:

- Depth
- Water clarity
- Biome
- Water type
- Weather
- Time
- Sun angle
- Lighting
- Sediment
- Player movement

Support:

- Color shift
- Reduced visibility
- Underwater fog
- Caustics
- Light shafts
- Surface distortion
- Natural particles/sediment
- Depth-dependent darkness
- Bubbles
- Subtle underwater movement

Underwater particles should remain closer to a natural Minecraft presentation rather than becoming a dense realistic simulation.

When the player exits water, the visual transition should communicate the sensation of emerging from water: water droplets/falling water on the view/player where appropriate, changing atmosphere, surface distortion clearing, and natural exposure/lighting transition.

## Rain, wetness and storm progression

Rain should be dynamic, environmentally reactive, and cinematic when justified.

Close rain should be more visible; distant rain should blend into atmospheric haze.

Storm intensity should scale continuously:

**Weak storm → moderate storm → strong storm → severe cinematic storm**

with corresponding changes to:

- Clouds
- Wind
- Rain density
- Visibility
- Fog/haze
- Light
- Shadows
- Water
- Foliage
- Spray
- Wetness
- Lightning probability/character

Normal weather remains moderate. Cinematic intensity is available but should not be the constant default.

### Lightning

Lightning should be dynamic and customizable, with natural irregular timing such as:

> Long silence → distant flash → several seconds → bright nearby flash → long silence → distant flashes → sudden strong strike.

Lightning should temporarily influence:

- Terrain
- Clouds
- Fog
- Water
- Wet surfaces
- Foliage
- Structures
- Shadows
- Player/entities
- Distant landscape

Intensity depends on distance. Distant lightning should appear softer than nearby strikes.

## Snow and ice

Snow should be fully environmental and highly customizable while preserving Minecraft identity.

Snow accumulation depends on:

- Snowfall intensity
- Wind
- Temperature-like conditions
- Surface type
- Surface angle
- Time
- Weather
- Underlying material

Accumulation should vary naturally:

**Bare → dusting → thin layer → moderate layer → deep snow**

Examples:

- Grass tips/edges receive lighter, irregular coverage.
- Large roofs and broad surfaces can accumulate much more.
- Branches can hold uneven snow.
- Wind redistributes loose snow.
- Upper snow receives sunlight while undersides remain darker.
- Snow should not become an unrealistically glowing white field.

### Snow trails

Walking through snow should create visible, natural path/footstep trails through displacement/compression. Trails should persist and behave appropriately without becoming gameplay clutter.

### Ice

Thin and thick ice should look meaningfully different. Thickness affects transparency, color, light transmission, and surface character.

### Melt/drying cycle

Where appropriate:

**Snow → wet surface → water/puddles → drying**

Different stages should occur at different rates rather than simultaneously snapping.

## Environmental particles and effects

Catalyst supports environmental particles for:

- Rain
- Snow
- Mist
- Fog particles
- Dust
- Sand
- Leaves
- Petals/vegetation debris
- Smoke
- Ash
- Embers
- Fire particles
- Water spray
- Water droplets
- Cave particles
- Underwater particles
- Floating environmental particles

Particles respond to:

- Wind
- Gravity
- Weather
- Time
- Biome
- Lighting
- Water
- Fire
- Terrain
- Player movement

Movement should be physically believable but cinematic.

### Particle density

Provide:

**None → subtle → natural → enhanced → cinematic**

Density is fully customizable and automatically responds to environmental conditions unless the user overrides it.

### Gameplay constraint

Particles must not become visual clutter. Leaves/debris should be somewhat smaller and natural. Normal weather should remain moderate; cinematic density is optional.

### Dust

Dust appears where environmentally justified, such as deserts, badlands, dry terrain, caves, and strong wind. Density responds to wind and environmental conditions.

Do **not** add a dedicated exaggerated “dust gust” spectacle.

### Smoke and embers

Smoke responds to source, wind, density, height, dissipation, lighting, color, and atmosphere.

Embers can:

- Rise naturally
- Respond to wind
- Vary in brightness
- Fade with distance
- Become more visible at night
- Receive environmental illumination
- Subtly reflect in water

### Fire

Fire remains recognizably Minecraft while gaining:

- Better motion
- Better lighting
- Better transparency/depth
- Wind response
- Natural flame progression
- Better smoke/ember interaction

Flame motion should progress naturally:

**Calm → flickering → leaning → strongly moving**

### Player interaction

Player movement may subtly disturb:

- Dust
- Snow
- Underwater sediment/bubbles
- Tall vegetation
- Water
- Loose leaves/debris

This must remain subtle rather than exaggerated.

### Particle depth

Particles should have proper depth behavior:

- Foreground particles are clearer.
- Midground particles interact with atmosphere.
- Distant particles fade into haze.
- Lighting changes with distance.
- Avoid flat 2D-overlay appearance.

A fully volumetric particle system is **not** a requirement; particles should remain performant and Minecraft-readable.

### Particle modes

Provide:

**Vanilla → Enhanced → Cinematic**

while preserving original Minecraft particle character.

## Materials and surface response

Keep vanilla Minecraft materials almost completely recognizable. Environmental lighting is the primary realism mechanism.

Different materials may receive different degrees of environmental realism where visually meaningful, but the result must remain Minecraft.

Material response can include:

- Roughness
- Reflectivity
- Wetness
- Bump/detail
- Emission
- Light response
- Environmental color influence

Do not make everything glossy or mirror-like by default.

### Resource-pack compatibility

Catalyst should work well across vanilla and third-party resource packs and remain visually coherent with different art styles such as medieval, sci-fi, fantasy, and realistic packs.

Material response should adapt to the available material data rather than assuming one art direction.

## Foliage/environmental color influence

Colored environmental materials can subtly influence nearby light and atmosphere. For example, colored glass should be able to affect nearby ground/light where physically justified.

This influence may become somewhat more noticeable in darker environments, but should remain subtle by default and fully adjustable.

## Night and moon

Night should be:

- Naturally dark
- Atmospheric
- Readable
- User-adjustable

Users should be able to control the full range:

**Brighter → natural → very dark**

The world should never become an unreadable black screen when ambient information exists.

### Moon

Moonlight has higher priority than arbitrary night tinting and responds to:

- Moon phase
- Weather
- Cloud cover
- Time
- Atmospheric conditions

Moonlight can have a subtle cool/bluish character, especially in shadows and ambient surroundings.

Moon phases should visibly matter.

### Stars

Stars should support:

- Subtle twinkling
- Different brightness
- Sparse distribution
- Milky Way
- Stars near the moon
- Moon-brightness influence
- Cloud/weather occlusion
- Shooting stars
- User customization

## Biomes and seasons

Biomes should have distinct visual character through:

- Lighting tone
- Atmosphere
- Fog/mist
- Vegetation
- Water behavior
- Weather response
- Sunlight behavior
- Environmental color

Biome transitions should be smooth and cinematic rather than hard visual switches.

Seasonal variation, when supported, is fully user controlled and may affect:

- Foliage
- Weather
- Snow
- Atmosphere
- Sunlight
- Color
- Falling leaves
- Ground/wetness
- Other appropriate environmental states

Seasonal exceptions should occur only where the environment genuinely justifies them.

## Caves and underground

Caves should feel like a distinct environment, not merely an artificially darker surface.

They may include:

- Distinct atmospheric character
- Natural darkness
- Ambient/bounced information
- Local light influence
- Mist/haze where appropriate
- Light shafts through openings
- Moisture/wetness
- Particles
- Depth variation
- Different underground moods

Cave light shafts are **enabled by default**, appear when geometry/light/atmosphere justify them, and are fully customizable.

Users must be able to disable all cave-specific settings.

Cave entrances should transition smoothly between outdoor and underground environments.

## Nether

The Nether must be clearly different from the Overworld and remain unmistakably Minecraft Nether.

It should have its own:

- Sky/ceiling presentation
- Atmosphere
- Fog
- Lighting behavior
- Lava interaction
- Ember/ash behavior
- Environmental color
- Shadows
- Volumetric effects
- Cinematic identity

The Nether can be dark, intense, and cinematic, but should not simply be an Overworld palette swap.

## End

The End must feel like an entirely different dimension:

- Empty
- Vast
- Mysterious
- Dark
- Cold
- Unsettling
- Cinematic
- Ethereal
- Surreal
- Beautiful
- Dangerous
- Otherworldly

The End sky must be substantially different from both the Overworld and Nether.

Support:

- Subtle sky movement/variation
- Strange sky phenomena
- Extremely distant atmospheric structures/forms
- End atmospheric events
- Dramatic night fog
- Otherworldly environmental lighting
- Dimension-specific particles/atmosphere

The End should be scary and incredible at the same time.

## Celestial bodies

Sun, moon, and stars may be visually redesigned for a more detailed cinematic presentation while preserving Minecraft's identity and world readability.

Celestial behavior should remain consistent with time, weather, atmosphere, and dimension.

## Camera and post-processing

Camera effects are optional presentation tools, not permanent filters.

### Depth of field

DOF should have:

- Presets
- Full customization
- Off → natural → cinematic range
- Focus behavior centered on the crosshair/selected focus target where appropriate
- Adjustable strength, distance, transition speed, aperture-like behavior, and related parameters

No automatic excessive blur.

### Motion blur

Motion blur is fully customizable and may be disabled. It should depend on camera movement speed rather than being constantly applied.

### Other camera effects

Lens-like effects and cinematic camera treatments should be subtle by default and fully adjustable.

Camera presentation must prioritize temporal stability and gameplay readability over a flattering static screenshot.

## Exposure and eye adaptation

Exposure should behave like a natural eye/camera adaptation system:

- Very subtle by default
- Smooth
- Context-dependent
- User-adjustable
- More noticeable only when the brightness change warrants it

Moving from dark cave/interior to bright exterior, or bright exterior to dark interior, should not create an abrupt artificial exposure jump.

## Temporal stability

When sharpness and stability conflict, prioritize stability.

Avoid:

- Shimmer
- Flicker
- Temporal instability
- Noisy shadows
- Unstable reflections
- Crawling foliage
- Unstable volumetrics

The target is a stable image that remains detailed while moving.

## Distant landscape and environmental depth

Foreground, midground, background, and atmosphere should form a coherent depth hierarchy without becoming a flat fog wall.

Distant terrain should become increasingly integrated into atmospheric perspective, with haze depending on:

- Weather
- Time
- Biome
- Terrain
- Atmosphere
- Camera angle
- Sunlight
- Water conditions

## Special moments

Catalyst should support naturally occurring cinematic moments without scripting every scene.

Examples:

- Mountain + sunset + cloud breakthrough
- Storm over distant mountains
- Sunlight returning after heavy rain
- Moonlight through forest canopy
- Waterfall in mist at sunrise
- Fog lifting from a valley
- Snow-covered landscape under soft morning light
- Cave opening with shafts of sunlight
- Lightning briefly revealing distant terrain

The renderer should not force these compositions; it should make them beautiful when they naturally occur.

## Environmental continuity

Different systems must not behave as isolated effects.

Examples:

### Storm

Clouds darken → direct light falls → ambient changes → wind increases → foliage reacts → rain begins → surfaces wet → puddles develop → water reacts → mist increases → lightning becomes possible → lightning illuminates the environment → storm weakens → clouds break → sunlight returns → wet surfaces remain → drying occurs gradually.

### Snow

Temperature/weather changes → snowfall begins → accumulation develops according to surface → branches/roofs/terrain collect different amounts → wind redistributes loose snow → footsteps compress snow → sunlight changes snow brightness → snow melts where appropriate → wetness/puddles develop → drying follows.

### Sunrise

Night atmosphere fades → cool ambient light remains → sky warms → sunlight strengthens → long soft shadows appear → fog/mist catches light → mist gradually dissipates → environment warms toward neutral daylight.

### Sunset

Neutral afternoon light warms → shadows lengthen/soften → clouds catch warm light → atmosphere becomes warmer → landscape receives warm indirect light → twilight gradually cools after sunset.

## Performance philosophy

Visual quality should scale gracefully with performance presets. Expensive features should degrade in quality or resolution before the core aesthetic identity collapses.

Performance presets must remain useful starting points, but advanced users can override individual systems.

Environmental systems should avoid unnecessary simulation or particle density when their contribution is not visually meaningful.

## Hard aesthetic constraints

The following are persistent rejection criteria unless explicitly overridden by a user:

- Oversaturated
- Plastic-looking
- Cartoonish
- Washed out
- Excessively dark
- Neon
- Blurry
- Noisy
- Overly glossy
- Fake-looking
- Flat
- Overly foggy
- Excessively bloomed
- Unreadable gameplay
- Artificially black shadows
- Arbitrary illumination without environmental cause
- Effects that exist solely because they look cool

## Effects must have environmental reasons

A core Catalyst rule is:

> **No visual effect should exist merely because it looks cool. It should have a believable environmental reason to exist.**

Examples:

- Dust requires an appropriate dry/windy environment.
- Mist requires appropriate atmospheric/moisture conditions.
- Water spray requires water movement/impact.
- Embers require a heat/fire source.
- Strong god rays require appropriate light + atmosphere + geometry.
- Strong reflections require suitable surface/material/light conditions.
- Snow accumulation requires suitable weather/environment.
- Dramatic fog should have a plausible environmental cause.

Cinematic enhancement is allowed when it strengthens an effect that the environment already justifies.

## Interaction with Minecraft identity

Minecraft geometry, world structure, block identity, proportions, gameplay readability, and fundamental visual language remain the foundation.

Environmental realism may be extensive, but it should feel like an enhancement of Minecraft rather than a replacement for it.

Vanilla materials should remain almost completely recognizable unless the user explicitly selects a more advanced visual material presentation.

## Reference-image interpretation rule

The aesthetic target is not a single screenshot. It is a dynamic system capable of producing coherent visual states across:

- Morning
- Noon
- Afternoon
- Sunset
- Twilight
- Night
- Clear weather
- Overcast
- Rain
- Storm
- Snow
- Fog
- Forest
- Mountains
- Valleys
- Desert
- Swamp
- Ocean
- Rivers
- Caves
- Underwater
- Nether
- End
- Interior/exterior transitions
- Player movement
- Camera movement

The visual system should remain beautiful and coherent across the entire range.

## Validation principles

Visual validation should verify:

1. Minecraft identity remains intact.
2. Natural presentation is the default.
3. Cinematic intensity emerges from conditions rather than a permanent filter.
4. Lighting behaves as one interconnected system.
5. Shadows retain ambient/bounced information.
6. Water reacts to environment and depth.
7. Foliage reacts naturally to wind/weather.
8. Weather transitions smoothly.
9. Snow/wetness accumulate and decay progressively.
10. Particles remain gameplay-friendly.
11. Nether and End have distinct identities.
12. Camera effects remain optional and controllable.
13. Gameplay readability is preserved.
14. Temporal stability is maintained.
15. User overrides work consistently.
16. Performance presets remain meaningful.
17. No unrelated functionality changes are introduced.

## Final standing goal

Catalyst should be **beautiful in ordinary moments and breathtaking in naturally exceptional moments**.

The target is not photorealism for its own sake. It is a believable, cinematic environmental presentation that makes Minecraft's existing world feel richer, deeper, wetter, more atmospheric, more alive, and more coherent without losing what makes it Minecraft.

The final standard is:

> **Minecraft, enhanced by a modern cinematic environmental renderer — natural by default, cinematic when conditions justify it, fully customizable when the user wants more, and always governed by environmental coherence, readability, stability, and Minecraft identity.**

## Constraints this does not relax

- Do not copy source code, shader logic, assets, or configuration from reference packs.
- Follow all existing provenance/licensing restrictions, including the repository's KappaPT/NostalgiaVX policy.
- A visual target never outranks correctness, compatibility, stable architecture, or temporal stability.
- Do not modify unrelated gameplay or functionality to satisfy an aesthetic requirement.
- Do not treat an aesthetic requirement as proof of implementation.
- Use the repository's visual test matrix and validation documents to verify the target across time, weather, dimensions, environments, and camera motion.
- Preserve existing behavior whenever it already satisfies this document.
