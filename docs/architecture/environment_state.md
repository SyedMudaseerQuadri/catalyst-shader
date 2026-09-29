# Catalyst — Shared Environmental State Architecture

The latest aesthetic direction requires environmental systems to behave as one interconnected renderer. This document defines the shared state boundary.

## Inputs
- time of day;
- weather state and transition phase;
- wind;
- biome;
- season when genuinely supported by the target environment/modpack;
- terrain and surface/material class;
- water state;
- sun/moon angle;
- cloud coverage;
- atmospheric density;
- light sources;
- dimension.

## Derived state
The renderer may derive stable quantities such as:
- solar/lunar contribution;
- storm intensity;
- cloud attenuation;
- precipitation intensity;
- wetness level and drying state;
- snow accumulation/melt state;
- visibility/aerial perspective;
- ambient/environmental light modifiers.

## Consumers
Lighting, shadows, sky, clouds, atmosphere, weather, wetness, snow, foliage, water, particles, exposure, camera effects, and temporal history may consume shared state.

## Transition rule
State changes should be progressive and independently time-scaled. Do not make every visual system snap at the same instant when a weather or time state changes.

## Capability rule
A claimed environmental input must be classified as VERIFIED, DERIVABLE, APPROXIMATED, or UNAVAILABLE for the pinned target. If an input cannot be obtained directly, document the approximation and its visual consequence.
