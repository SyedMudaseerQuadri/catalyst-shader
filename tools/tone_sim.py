#!/usr/bin/env python3
"""Catalyst lighting/exposure simulator: a CPU mirror of the indirect-light, exposure and tonemap math.

Purpose (maintained tool): tune tone/color constants against reference scenes without a GPU, and catch
regressions like "interiors turn grey" before an in-game test. Each scene prints display sRGB and
saturation for a surface, so a change can be compared with the vanilla screenshot measurements recorded
in state/evidence/.

Keep the formulas in sync with:
  lib/environment/state.glsl (sky ambient), lib/lighting/forward.glsl (indirect + multi-bounce),
  lib/post/tonemap.glsl (exposure, contrast, saturation, tonemap).

Usage:  python tools/tone_sim.py [--legacy]
"""

from __future__ import annotations

import argparse
import math

import numpy as np


def srgb_to_linear(c):
    c = np.asarray(c, float)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def linear_to_srgb(c):
    c = np.maximum(np.asarray(c, float), 0)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)


def lum(c):
    return float(np.dot(c, [0.2126, 0.7152, 0.0722]))


def sat(c):
    c = np.asarray(c)
    return float((c.max() - c.min()) / max(c.max(), 1e-6))


# ---- Natural / Realistic preset constants (lib/settings.glsl)
PRESET_VANILLA_SKY_BLEND = 0.35
PRESET_MIN_AMBIENT = 0.032
PRESET_SHADOW_AMBIENT = 1.00
PRESET_CONTRAST = 1.03
PRESET_SATURATION = 1.02
READABILITY_MIN_AMBIENT = 0.015
EXPOSURE_KEY = 0.18
W = 6.0

VANILLA_SKY = srgb_to_linear([0.47, 0.65, 1.00])  # typical plains skyColor (sRGB)


def sky_ambient_day(legacy):
    if legacy:
        return (0.55 * (np.array([0.30, 0.45, 0.75]) * (1 - PRESET_VANILLA_SKY_BLEND)
                        + VANILLA_SKY * 1.2 * PRESET_VANILLA_SKY_BLEND))
    # new: hemispheric sky irradiance is only mildly blue (sky + ground bounce); biome hue kept but desaturated
    base = np.array([0.80, 0.90, 1.10])
    vanilla = VANILLA_SKY / max(lum(VANILLA_SKY), 1e-6)
    vanilla = 1.0 + (vanilla - 1.0) * SKY_TINT_SATURATION
    hue = base * (1 - PRESET_VANILLA_SKY_BLEND) + vanilla * PRESET_VANILLA_SKY_BLEND
    return hue / lum(hue) * SKY_AMBIENT_LUM


SKY_AMBIENT_LUM = 0.55        # daytime hemispheric sky irradiance (sun noon ~2.5): ~4.5:1 sun/sky, a clear-day ratio
SKY_TINT_SATURATION = 0.25    # how much of the biome sky's saturation survives in the ambient light
BOUNCE_STRENGTH = 0.55        # share of the multi-bounce term (0 = pure occlusion, 1 = full Jimenez fit)
ADAPTATION = 0.5              # EXPOSURE_ADAPTATION default: 0 = fixed exposure, 1 = full adaptation
EXPOSURE_TARGET = 0.38        # exposure numerator: open noon lands at ~0.35, the level matched to vanilla brightness
DAY_REFERENCE = 2.53 * 0.20 + SKY_AMBIENT_LUM + PRESET_MIN_AMBIENT * 0.8  # open-sky noon scene estimate


def multibounce(x, albedo):
    """Jimenez et al. 2016 multi-bounce occlusion fit: occluded light is partly re-bounced, tinted by albedo."""
    a = 2.0404 * albedo - 0.3324
    b = -4.7951 * albedo + 0.6417
    c = 2.7552 * albedo + 0.6903
    return np.maximum(x, ((x * a + b) * x + c) * x)


def indirect(albedo, sky, block, ao, up, legacy, sky_amb):
    sky_vis = 0.45 + 0.55 * (up * 0.5 + 0.5)
    sky_fall = sky * sky
    floor_c = max(PRESET_MIN_AMBIENT, READABILITY_MIN_AMBIENT) * np.array([0.85, 0.92, 1.0])
    blk = np.array([1.0, 0.62, 0.32]) * 1.3 * (block ** 2.6 + 0.02 * block)
    if legacy:
        return (sky_amb * sky_vis * sky_fall * PRESET_SHADOW_AMBIENT + blk + floor_c) * ao
    # new: occlusion (sky access x vanilla AO) feeds the multi-bounce term, so enclosed spaces keep warmth
    occl = sky_fall * ao
    vis = occl + (multibounce(occl, albedo) - occl) * BOUNCE_STRENGTH
    ao_b = ao + (multibounce(ao, albedo) - ao) * BOUNCE_STRENGTH
    floor_c = max(PRESET_MIN_AMBIENT, READABILITY_MIN_AMBIENT) * np.array([1.0, 0.97, 0.92])
    return sky_amb * sky_vis * vis * PRESET_SHADOW_AMBIENT + (blk + floor_c) * ao_b


def exposure(eye_sky, eye_block, light_lum, sky_amb, legacy):
    sunlit = light_lum * 0.20 + lum(sky_amb)
    est = sunlit * eye_sky ** 2 + lum(np.array([1.0, 0.62, 0.32]) * 1.3) * 0.30 * eye_block ** 2 + PRESET_MIN_AMBIENT * 0.8
    if legacy:
        return min(max(EXPOSURE_KEY / est, 0.35), 5.0)
    adapted = DAY_REFERENCE ** (1 - ADAPTATION) * est ** ADAPTATION
    return min(max(EXPOSURE_TARGET / adapted, 0.10), 4.0)


def display(hdr, e):
    c = hdr * e
    c = EXPOSURE_KEY * (np.maximum(c, 0) / EXPOSURE_KEY) ** PRESET_CONTRAST
    l = lum(c)
    c = np.maximum(l + (c - l) * PRESET_SATURATION, 0)
    c = c * (1 + c / (W * W)) / (1 + c)
    return linear_to_srgb(np.clip(c, 0, 1))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--legacy", action="store_true", help="also show the pre-fix (0.2.0-m2a) model")
    args = ap.parse_args()

    planks = srgb_to_linear([0.78, 0.69, 0.50])  # birch-planks-like albedo
    grass = srgb_to_linear([0.45, 0.62, 0.28])
    stone = srgb_to_linear([0.50, 0.50, 0.50])
    sun_noon = np.array([2.64, 2.53, 2.19])      # EnvState sunRadiance at noon (approx)
    night_light = lum(np.array([0.50, 0.62, 0.95]) * 0.055)

    # name, albedo, sky level, block level, AO, up-facing, direct light, eye sky, eye block, light lum
    scenes = [
        ("room wall, day (screenshot)", planks, 0.60, 0.0, 0.85, 0.0, 0.0, 0.60, 0.0, lum(sun_noon)),
        ("room floor, day", planks, 0.70, 0.0, 0.90, 1.0, 0.0, 0.60, 0.0, lum(sun_noon)),
        ("outdoor grass, noon sun", grass, 1.00, 0.0, 1.00, 1.0, 1.0, 1.00, 0.0, lum(sun_noon)),
        ("outdoor wall in shade, noon", stone, 1.00, 0.0, 0.90, 0.0, 0.0, 1.00, 0.0, lum(sun_noon)),
        ("cave stone, torch nearby", stone, 0.00, 0.80, 0.90, 0.0, 0.0, 0.00, 0.7, lum(sun_noon)),
        ("cave stone, no light", stone, 0.00, 0.00, 0.90, 0.0, 0.0, 0.00, 0.0, lum(sun_noon)),
        ("night grass, moonlight", grass, 1.00, 0.0, 1.00, 1.0, 0.0, 1.00, 0.0, night_light),
    ]
    models = [("legacy", True), ("new", False)] if args.legacy else [("new", False)]
    for title, legacy in models:
        print(f"== {title} model ==")
        for name, alb, sky, blk, ao, up, direct, eye_s, eye_b, llum in scenes:
            night = llum < 0.1
            sky_amb = sky_ambient_day(legacy) * ((0.06 if legacy else 0.035) if night else 1.0)
            hdr = alb * indirect(alb, sky, blk, ao, up, legacy, sky_amb)
            if direct:
                hdr = hdr + alb * sun_noon
            if night:
                hdr = hdr + alb * np.array([0.50, 0.62, 0.95]) * 0.055
            e = exposure(eye_s, eye_b, llum, sky_amb, legacy)
            out = display(hdr, e)
            print(f"  {name:32s} sRGB={np.round(out, 3)}  sat={sat(out):.2f} (albedo {sat(linear_to_srgb(alb)):.2f})  exposure={e:.2f}")


if __name__ == "__main__":
    main()
