#!/usr/bin/env python3
"""Catalyst lighting/exposure simulator: a CPU mirror of the shader's light, sky, exposure and tonemap math.

Purpose (maintained tool): tune tone/color constants against in-game evidence without a GPU, and catch
regressions before an in-game test. Two models are kept side by side:
  "0.2.1"   the build the user tested (state/evidence/ingame2_2026-10-10.md); used to CALIBRATE the simulator
            against the in-game screenshots before trusting it,
  "current" the formulas in the shader source right now.
Outputs are passed through CAPTURE_GAMMA, the measured snipping-tool shift (debug grey 0.5 -> 0.447), so they
compare directly with the measured screenshot values printed next to them.

Keep the "current" formulas in sync with:
  lib/environment/state.glsl (sun, sky ambient, block light), lib/atmosphere/sky.glsl (sky dome),
  lib/lighting/forward.glsl (indirect + multi-bounce), program/gbuffers_forward_misc.glsl (clouds),
  lib/post/tonemap.glsl (exposure, contrast, saturation, tonemap).

Usage:  python tools/tone_sim.py
"""

from __future__ import annotations

import math

import numpy as np

# ------------------------------------------------------------------------------------------- helpers

def srgb_to_linear(c):
    c = np.asarray(c, float)
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def linear_to_srgb(c):
    c = np.maximum(np.asarray(c, float), 0)
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)


def lum(c):
    return float(np.dot(c, [0.2126, 0.7152, 0.0722]))


def smoothstep(e0, e1, x):
    t = min(max((x - e0) / (e1 - e0), 0.0), 1.0)
    return t * t * (3 - 2 * t)


CAPTURE_GAMMA = 1.168  # snipping-tool capture: display value v is saved as v ** 1.168 (EV-005)

# ---- Natural / Realistic preset + defaults (lib/settings.glsl)
PRESET_VANILLA_SKY_BLEND = 0.35
PRESET_SKY_DOME_VANILLA = 0.60
PRESET_AEROSOL = 0.08
PRESET_MIN_AMBIENT = 0.032
PRESET_CONTRAST = 1.03
PRESET_SATURATION = 1.02
VANILLA_SKY = srgb_to_linear([0.47, 0.65, 1.00])  # plains skyColor (sRGB)
SUN_PATH_TILT = math.radians(20.0)


def sun_elevation(world_time):
    """sin(altitude) for a Minecraft time of day (0 = sunrise, 6000 = noon) with the default path tilt."""
    theta = (world_time / 6000.0) * (math.pi / 2)
    return math.sin(theta) * math.cos(SUN_PATH_TILT)


def sun_radiance(sin_e):
    alt = max(math.degrees(math.asin(max(min(sin_e, 1), -1))), 0.0)
    m = min(1.0 / (math.sin(math.radians(alt)) + 0.50572 * (alt + 6.07995) ** -1.6364), 38.0)
    t = np.exp(-(np.array([0.045, 0.097, 0.235]) + PRESET_AEROSOL) * m)
    return t * 3.0 * smoothstep(-0.05, 0.04, sin_e)


def daylight_sky_scale(sin_e):
    """Sky brightness follows the sun: the clear sky (dome and hemispheric irradiance) is dimmer at low sun."""
    return 0.40 + 0.60 * smoothstep(0.0, 0.85, sin_e)


def sky_ambient_day(sin_e=None, scaled=False):
    base = np.array([0.80, 0.90, 1.10])
    v = VANILLA_SKY / lum(VANILLA_SKY)
    v = 1.0 + (v - 1.0) * 0.25
    hue = base * (1 - PRESET_VANILLA_SKY_BLEND) + v * PRESET_VANILLA_SKY_BLEND
    level = SKY_AMBIENT_NOON * daylight_sky_scale(sin_e) if scaled else 0.55
    return hue / lum(hue) * level


SKY_AMBIENT_NOON = 0.70


def multibounce(x, albedo, strength):
    a = 2.0404 * albedo - 0.3324
    b = -4.7951 * albedo + 0.6417
    c = 2.7552 * albedo + 0.6903
    fit = np.maximum(x, ((x * a + b) * x + c) * x)
    return x + (fit - x) * strength


def hg(cos_t, g):
    return (1 - g * g) / (4 * math.pi * max(1 + g * g - 2 * g * cos_t, 1e-4) ** 1.5)


# ------------------------------------------------------------------------------------------- models

class Model:
    def __init__(self, name, **kw):
        self.name = name
        self.__dict__.update(kw)

    # block light color for a 0..1 block level
    def block_color(self, level):
        if self.block_hue_by_level:
            dim = np.array([1.0, 0.52, 0.24])
            bright = np.array([1.0, 0.80, 0.58])
            hue = dim + (bright - dim) * level
            return hue / lum(hue) * lum(np.array([1.0, 0.62, 0.32])) * 1.3
        return np.array([1.0, 0.62, 0.32]) * 1.3

    def sky_falloff(self, s):
        return s ** self.sky_falloff_power

    def shade(self, albedo, normal_up, sky, block, ao, sun, light_dir_y, sky_amb, night=False):
        n_dot_l = max(light_dir_y, 0.0) if normal_up else 0.0
        direct = sun * n_dot_l * smoothstep(0.05, 0.35, sky)
        sky_vis = 0.45 + 0.55 * ((1.0 if normal_up else 0.0) * 0.5 + 0.5)
        occl = self.sky_falloff(sky) * ao
        sky_term = sky_amb * sky_vis * multibounce(occl, albedo, self.bounce)
        aob = multibounce(ao, albedo, self.bounce)
        blk = self.block_color(block) * (block ** self.block_falloff_power + 0.02 * block)
        floor_c = PRESET_MIN_AMBIENT * np.array([1.0, 0.97, 0.92])
        return albedo * (direct + sky_term + (blk + floor_c) * aob)

    def sky_dome(self, up, sun, sun_dir_cos, env_day, sin_e=1.0):
        blend = self.dome_vanilla
        zen = np.array([0.16, 0.32, 0.80]) * (1 - blend) + VANILLA_SKY * blend
        hor = np.array([0.60, 0.72, 0.92]) * (1 - blend) + (VANILLA_SKY * 1.4 + 0.15) * blend
        band = math.exp(-max(up, 0) * 5.0)
        day = (zen * (1 - band) + hor * band) * self.dome_gain
        if self.sky_scaled:
            day = day * daylight_sky_scale(sin_e)
        return day * env_day + sun * hg(sun_dir_cos, 0.76) * 0.20

    def exposure(self, sun, light_y, sky_amb, eye_sky, eye_block, day):
        floor_part = PRESET_MIN_AMBIENT * 0.8
        blk = lum(self.block_color(eye_block)) * 0.30 * eye_block ** 2
        if self.exposure_mode == "0.2.1":
            sunlit = lum(sun) * 0.20 + lum(sky_amb)
            est = sunlit * eye_sky ** 2 + blk + floor_part
            adapted = 1.08 ** 0.5 * est ** 0.5
            return min(max(0.38 / adapted, 0.10), 4.0)
        # current: daylight normalization (open-ground irradiance) x subtle local adaptation
        e_open = lum(sun) * max(light_y, 0.0) + lum(sky_amb) + floor_part
        e_eye = (e_open - floor_part) * eye_sky ** 2 + blk + floor_part
        a_global = self.a_night + (self.a_day - self.a_night) * day
        global_adapted = self.day_reference ** (1 - a_global) * e_open ** a_global
        local = (e_open / max(e_eye, 1e-4)) ** self.a_local
        return min(max(self.target / global_adapted * local, 0.05), 6.0)

    def display(self, hdr, e):
        c = np.maximum(hdr * e, 0)
        c = 0.18 * (c / 0.18) ** PRESET_CONTRAST
        l = lum(c)
        c = np.maximum(l + (c - l) * PRESET_SATURATION, 0)
        if self.tonemap == "reinhard":
            c = c * (1 + c / 36.0) / (1 + c)
        else:  # linear toe/mid with an exponential shoulder above the knee
            k = self.knee
            c = np.where(c < k, c, k + (1 - k) * (1 - np.exp(-(c - k) / (1 - k))))
        return linear_to_srgb(np.clip(c, 0, 1))


M021 = Model("0.2.1", block_falloff_power=2.6, sky_scaled=False, block_hue_by_level=False, sky_falloff_power=2.0, bounce=0.55, dome_vanilla=0.35,
             dome_gain=2.0, cloud="0.2.1", exposure_mode="0.2.1", tonemap="reinhard")
CURRENT = Model("current", block_falloff_power=4.0, sky_scaled=True, block_hue_by_level=True, sky_falloff_power=3.5, bounce=0.35,
                dome_vanilla=PRESET_SKY_DOME_VANILLA, dome_gain=1.9, cloud="current", exposure_mode="current",
                tonemap="shoulder", knee=0.55, a_day=0.85, a_night=0.55, a_local=0.15, target=0.95, day_reference=3.10)


def cloud_radiance(model, sun, light_y, sky_amb, sky_up):
    wrapped = 0.75  # cloud faces seen from below/side, average
    if model.cloud == "0.2.1":
        return sun * wrapped * 0.6 + sky_amb * 1.6 + 0.004
    return sun * wrapped * 0.7 + sky_amb * 1.0 + sky_up * 0.6 + 0.004


def capture(srgb):
    return np.asarray(srgb) ** CAPTURE_GAMMA


def run(model):
    print(f"\n=== model {model.name} (values as the snipping tool would save them) ===")
    white = srgb_to_linear([0.85, 0.85, 0.85])
    grass = srgb_to_linear([0.425, 0.443, 0.255])          # measured albedo debug (EV-005)
    for label, t in (("morning /time 1000", 1000), ("noon /time 6000", 6000)):
        s = sun_elevation(t)
        sun = sun_radiance(s)
        sky_amb_day = sky_ambient_day(s, model.sky_scaled)
        e = model.exposure(sun, s, sky_amb_day, 1.0, 0.0, 1.0)
        g = model.display(model.shade(grass, True, 1.0, 0.0, 1.0, sun, s, sky_amb_day), e)
        q = model.display(model.shade(white, True, 1.0, 0.0, 1.0, sun, s, sky_amb_day), e)
        zen = model.display(model.sky_dome(0.8, sun, 0.3, 1.0, s), e)
        hor = model.display(model.sky_dome(0.05, sun, 0.2, 1.0, s), e)
        sky_up = model.sky_dome(1.0, sun, s, 1.0, s)
        cl = model.display(cloud_radiance(model, sun, s, sky_amb_day, sky_up), e)
        print(f"  {label:20s} exposure={e:.2f}")
        ref = label.startswith("morning")
        for name, val, game, van in (("grass", g, (0.178, 0.195, 0.136), (0.422, 0.456, 0.274)),
                                     ("white block top", q, (0.369, 0.366, 0.381), (0.716, 0.716, 0.717)),
                                     ("sky zenith", zen, (0.418, 0.457, 0.597), (0.554, 0.673, 0.933)),
                                     ("sky horizon", hor, (0.406, 0.426, 0.493), (0.605, 0.66, 0.738)),
                                     ("clouds", cl, (0.433, 0.463, 0.577), (0.631, 0.712, 0.888))):
            extra = f"   in-game 0.2.1 {game}  vanilla {van}" if ref else ""
            print(f"     {name:16s} {np.round(capture(val), 3)}{extra}")

    # Night (/time 18000): moonlight only.
    moon = np.array([0.50, 0.62, 0.95]) * 0.055
    night_amb = np.array([0.10, 0.14, 0.26]) * 0.10
    e = model.exposure(moon, 0.6, night_amb, 1.0, 0.0, 0.0)
    g = model.display(model.shade(grass, True, 1.0, 0.0, 1.0, moon, 0.6, night_amb), e)
    nsky = model.display(np.array([0.007, 0.010, 0.020]), e)
    print(f"  night /time 18000     exposure={e:.2f}")
    print(f"     grass            {np.round(capture(g), 3)}   in-game 0.2.1 (0.07, 0.08, 0.044)")
    print(f"     sky              {np.round(capture(nsky), 3)}   in-game 0.2.1 (0.041, 0.049, 0.102)")

    # Block-lit white room (Light Levels debug: block ~0.55, sky ~0.15), daytime outside.
    s = sun_elevation(1000)
    sun = sun_radiance(s)
    sky_amb_day = sky_ambient_day(s, model.sky_scaled)
    e = model.exposure(sun, s, sky_amb_day, 0.15, 0.55, 1.0)
    floor = model.display(model.shade(white, True, 0.15, 0.55, 0.9, sun * 0, s, sky_amb_day), e)
    wall = model.display(model.shade(white, False, 0.12, 0.45, 0.8, sun * 0, s, sky_amb_day), e)
    darkwall = model.display(model.shade(white, False, 0.05, 0.25, 0.7, sun * 0, s, sky_amb_day), e)
    print(f"  white room, block-lit exposure={e:.2f}")
    print(f"     floor            {np.round(capture(floor), 3)}   in-game 0.2.1 (0.278, 0.258, 0.228)  vanilla (0.254, 0.197, 0.149)")
    print(f"     back wall        {np.round(capture(wall), 3)}   in-game 0.2.1 (0.382, 0.354, 0.315)  vanilla (0.226, 0.18, 0.133)")
    print(f"     dark left wall   {np.round(capture(darkwall), 3)}   in-game 0.2.1 (0.22, 0.211, 0.197)   vanilla (0.114, 0.093, 0.076)")

    stone = srgb_to_linear([0.50, 0.50, 0.50])
    for label, blk_level in (("cave, next to torch (14/15)", 14 / 15), ("cave, 4 blocks from torch", 10 / 15), ("cave, unlit", 0.0)):
        # Daytime outside: the shader's open-sky estimate is still daylight; darkness comes from eye brightness.
        e = model.exposure(sun, s, sky_amb_day, 0.0, max(blk_level - 0.1, 0), 1.0)
        c = model.display(model.shade(stone, False, 0.0, blk_level, 0.9, sun * 0, s, sky_amb_day * 0), e)
        print(f"  {label:28s} stone {np.round(capture(c), 3)}  (exposure {e:.2f})")


if __name__ == "__main__":
    run(M021)
    run(CURRENT)
