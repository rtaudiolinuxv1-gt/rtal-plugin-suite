#!/usr/bin/env python3
"""Render the "RTAL Forge" bitmap theme for Faust-style plugin dialogs.

Every image that replaces a standard Faust UI widget is drawn procedurally:
knobs (filmstrips and separate base/pointer layers), sliders, buttons,
checkboxes and switches, radio buttons, LEDs, numeric entries, menus,
bargraph meters, group frames, tabs and the panel background.

    python3 generate.py                  # default amber accent, 1x and 2x
    python3 generate.py --accent 3ec8ff  # recolour the accent
    python3 generate.py --out mytheme    # write somewhere else

Drawing happens at 4x supersampling on premultiplied float RGBA, then each
image is box-filtered down, which gives clean anti-aliased edges.
Requires Pillow and NumPy.

(c) 2026 rtaudiolinux <rtaudiolinux.v1@gmail.com> - DOC-1.0
"""

import argparse
import json
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont

SS = 4  # supersampling factor
KNOB_FRAMES = 101  # 0..100 %, so the centre frame (50) is exact for bipolar knobs
KNOB_SWEEP = 270.0  # degrees, from -135 (min) to +135 (max), 0 = 12 o'clock

# ---------------------------------------------------------------- palette
PAL = {
    "panel": (0.110, 0.118, 0.130),
    "panel_hi": (0.165, 0.175, 0.190),
    "panel_lo": (0.060, 0.064, 0.072),
    "groove": (0.035, 0.038, 0.044),
    "metal_lo": (0.42, 0.43, 0.45),
    "metal_hi": (0.88, 0.89, 0.90),
    "rubber": (0.085, 0.088, 0.095),
    "tick": (0.62, 0.64, 0.67),
    "lcd": (0.045, 0.050, 0.048),
    "text": (0.86, 0.87, 0.88),
    "green": (0.35, 0.95, 0.45),
    "yellow": (1.00, 0.85, 0.25),
    "red": (1.00, 0.28, 0.22),
}
ACCENT = (1.00, 0.60, 0.18)


def hex_rgb(h):
    h = h.strip().lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))


# ---------------------------------------------------------------- canvas helpers
class Canvas:
    """Premultiplied float RGBA canvas drawn at SS x the target size."""

    def __init__(self, w, h):
        self.w, self.h = w, h
        self.W, self.H = w * SS, h * SS
        self.px = np.zeros((self.H, self.W, 4), np.float32)
        ys, xs = np.mgrid[0:self.H, 0:self.W].astype(np.float32)
        # coordinates in target pixels, sampled at sub-pixel centres
        self.x = (xs + 0.5) / SS
        self.y = (ys + 0.5) / SS

    def over(self, rgb, alpha):
        """Composite colour rgb (tuple or HxWx3 array) with coverage alpha."""
        a = np.clip(alpha, 0.0, 1.0)[..., None].astype(np.float32)
        col = np.broadcast_to(np.asarray(rgb, np.float32), self.px[..., :3].shape)
        src = np.concatenate([col * a, a], axis=-1)
        self.px = src + self.px * (1.0 - a)

    def add(self, rgb, amount):
        """Additive light (glows); keeps alpha at least as opaque as the glow."""
        a = np.clip(amount, 0.0, None)[..., None].astype(np.float32)
        col = np.asarray(rgb, np.float32)
        self.px[..., :3] += col * a
        self.px[..., 3:] = np.maximum(self.px[..., 3:], np.clip(a, 0, 1))

    def image(self):
        p = self.px.reshape(self.h, SS, self.w, SS, 4).mean(axis=(1, 3))
        a = p[..., 3:]
        rgb = np.where(a > 1e-6, p[..., :3] / np.maximum(a, 1e-6), 0.0)
        out = np.concatenate([np.clip(rgb, 0, 1), np.clip(a, 0, 1)], axis=-1)
        return Image.fromarray((out * 255.0 + 0.5).astype(np.uint8), "RGBA")


def cov(sdf):
    """Anti-aliased coverage from a signed distance (target pixels, <0 inside)."""
    return np.clip(0.5 - sdf * SS, 0.0, 1.0)


def sd_circle(c, cx, cy, r):
    return np.hypot(c.x - cx, c.y - cy) - r


def sd_rrect(c, x0, y0, x1, y1, r):
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    hx, hy = (x1 - x0) / 2 - r, (y1 - y0) / 2 - r
    qx = np.abs(c.x - cx) - hx
    qy = np.abs(c.y - cy) - hy
    return np.hypot(np.maximum(qx, 0), np.maximum(qy, 0)) + np.minimum(np.maximum(qx, qy), 0) - r


def sd_segment(c, ax, ay, bx, by, w):
    px, py = c.x - ax, c.y - ay
    dx, dy = bx - ax, by - ay
    h = np.clip((px * dx + py * dy) / (dx * dx + dy * dy + 1e-9), 0, 1)
    return np.hypot(px - dx * h, py - dy * h) - w / 2


def blur(a, radius_px):
    """Approximate Gaussian blur (three box passes) of a 2-D array at SS scale."""
    r = max(1, int(radius_px * SS / 2))
    out = a.astype(np.float32)
    for _ in range(3):
        for axis in (0, 1):
            pad = [(0, 0), (0, 0)]
            pad[axis] = (r + 1, r)
            p = np.pad(out, pad, mode="edge")
            cs = np.cumsum(p, axis=axis)
            if axis == 0:
                out = (cs[2 * r + 1:] - cs[:-2 * r - 1]) / (2 * r + 1)
            else:
                out = (cs[:, 2 * r + 1:] - cs[:, :-2 * r - 1]) / (2 * r + 1)
    return out


def mix(a, b, t):
    t = np.asarray(t, np.float32)[..., None] if np.ndim(t) else t
    return np.asarray(a, np.float32) * (1 - t) + np.asarray(b, np.float32) * t


def vgrad(c, y0, y1, top, bottom):
    t = np.clip((c.y - y0) / max(1e-6, (y1 - y0)), 0, 1)
    return mix(top, bottom, t)


def noise(shape, seed, streak=0):
    rng = np.random.default_rng(seed)
    n = rng.standard_normal(shape).astype(np.float32)
    if streak:
        k = int(streak)
        p = np.concatenate([n[:, -k:], n, n[:, :k]], axis=1)  # wrap: tileable
        cs = np.cumsum(p, axis=1)
        n = (cs[:, 2 * k:] - cs[:, :-2 * k]) / (2 * k)
        n = n[:, :shape[1]]
        n /= n.std() + 1e-9
    return n


# ---------------------------------------------------------------- widgets
def screw(c, cx, cy, r, angle=0.6):
    c.over((0, 0, 0), cov(sd_circle(c, cx, cy + r * 0.15, r * 1.05)) * 0.5)
    t = np.clip((c.y - (cy - r)) / (2 * r), 0, 1)
    c.over(mix(PAL["metal_hi"], PAL["metal_lo"], t), cov(sd_circle(c, cx, cy, r)))
    for a in (angle, angle + math.pi / 2):
        dx, dy = math.cos(a) * r * 0.62, math.sin(a) * r * 0.62
        c.over((0.15, 0.15, 0.17), cov(sd_segment(c, cx - dx, cy - dy, cx + dx, cy + dy, r * 0.26)))


def background(w, h, accent, seed=7):
    c = Canvas(w, h)
    base = np.asarray(PAL["panel"], np.float32)
    streaks = noise((c.H, c.W), seed, streak=c.W // 6)
    fine = noise((c.H, c.W), seed + 1, streak=6 * SS)
    lum = 1.0 + 0.035 * streaks + 0.025 * fine
    # soft light from the top centre, vignette towards the edges
    nx, ny = (c.x / w - 0.5) * 2, (c.y / h - 0.25) * 2
    light = 1.0 + 0.28 * np.exp(-(nx * nx * 0.8 + ny * ny * 1.4))
    vx, vy = (c.x / w - 0.5) * 2, (c.y / h - 0.5) * 2
    vign = 1.0 - 0.32 * np.clip((vx * vx + vy * vy) / 2.0, 0, 1) ** 1.3
    c.over(base * (lum * light * vign)[..., None], np.ones((c.H, c.W)))
    # header band with an accent hairline
    hb = 44.0
    c.over((0.05, 0.053, 0.06), cov(c.y - hb) * 0.55)
    c.over(PAL["panel_hi"], cov(np.abs(c.y - hb - 0.5) - 0.5) * 0.9)
    c.over(accent, cov(np.abs(c.y - hb + 1.5) - 0.5) * 0.55)
    # bevel around the edge
    c.over((1, 1, 1), cov(np.abs(c.y - 0.5) - 0.5) * 0.10)
    c.over((0, 0, 0), cov(np.abs(c.y - (h - 0.5)) - 0.5) * 0.5)
    for (sx, sy) in ((14, 14), (w - 14, 14), (14, h - 14), (w - 14, h - 14)):
        screw(c, sx, sy, 5.0)
    return c.image()


def background_tile(size, seed=11):
    c = Canvas(size, size)
    base = np.asarray(PAL["panel"], np.float32)
    streaks = noise((c.H, c.W), seed, streak=c.W // 5)
    fine = noise((c.H, c.W), seed + 1, streak=6 * SS)
    lum = 1.0 + 0.035 * streaks + 0.025 * fine
    c.over(base * lum[..., None], np.ones((c.H, c.W)))
    return c.image()


def knob_layers(d, accent, ticks=True):
    """Static parts of a knob of diameter d: returns a function rendering one frame."""
    proto = Canvas(d, d)
    cx = cy = d / 2.0
    ang = np.arctan2(proto.x - cx, -(proto.y - cy))  # 0 at 12 o'clock, clockwise positive
    rad = np.hypot(proto.x - cx, proto.y - cy)
    r_arc = 0.405 * d
    w_arc = max(1.6, 0.045 * d)
    r_skirt = 0.345 * d
    r_cap = 0.285 * d
    sweep = math.radians(KNOB_SWEEP) / 2

    # Static base: shadow, tick marks, arc groove.
    base = Canvas(d, d)
    sh = blur(cov(sd_circle(base, cx, cy + 0.035 * d, r_skirt)), 0.06 * d)
    base.over((0, 0, 0), sh * 0.75)
    if ticks:
        for i in range(11):
            a = -sweep + 2 * sweep * i / 10
            r0, r1 = 0.462 * d, (0.497 if i in (0, 5, 10) else 0.485) * d
            base.over(PAL["tick"], cov(sd_segment(base, cx + math.sin(a) * r0, cy - math.cos(a) * r0,
                                                  cx + math.sin(a) * r1, cy - math.cos(a) * r1,
                                                  max(0.9, 0.018 * d))) * 0.85)
    in_sweep = (np.abs(ang) <= sweep)
    ring = np.abs(rad - r_arc) - w_arc / 2
    groove = cov(ring) * in_sweep
    base.over(PAL["groove"], groove)
    base.over((1, 1, 1), cov(np.abs(rad - (r_arc + w_arc / 2)) - 0.35) * in_sweep * 0.06)

    # Skirt (dark rubber, knurled; the knurl turns with the value).
    skirt_cov = cov(sd_circle(proto, cx, cy, r_skirt))
    skirt_shade = vgrad(proto, cy - r_skirt, cy + r_skirt, (0.20, 0.205, 0.215), (0.05, 0.052, 0.058))
    # Cap: brushed aluminium with conical highlights (lighting stays fixed).
    cap_cov = cov(sd_circle(proto, cx, cy, r_cap))
    theta = np.arctan2(proto.y - cy, proto.x - cx)
    cone = 0.62 + 0.20 * np.cos(2 * (theta + 0.8)) + 0.07 * np.cos(4 * (theta + 0.3))
    brushed = noise((proto.H, proto.W), 3, streak=0)
    # concentric brushing: blur noise along the angle approximated by radius jitter
    ring_noise = np.sin(rad * SS * 2.3 + brushed * 0.6) * 0.025
    fall = 1.0 - 0.18 * (rad / r_cap) ** 3
    cap_l = np.clip(cone * fall + ring_noise, 0, 1)
    cap_rgb = mix(PAL["metal_lo"], PAL["metal_hi"], cap_l)
    rim_hi = cov(np.abs(rad - (r_cap - 0.6)) - 0.45) * np.clip(-np.cos(theta + 0.9), 0, 1)
    rim_lo = cov(np.abs(rad - (r_cap + 0.4)) - 0.6)
    dimple = cov(sd_circle(proto, cx, cy, 0.07 * d))

    def frame(t, bipolar=False, pointer=True, arc=True, skirt_turn=True, cap=True):
        c = Canvas(d, d)
        c.px = base.px.copy()
        a_val = -sweep + 2 * sweep * t
        if arc:
            a_from = 0.0 if bipolar else -sweep
            lo, hi = min(a_from, a_val), max(a_from, a_val)
            sel = (ang >= lo) & (ang <= hi)
            # rounded ends: add caps at both arc ends
            ends = np.minimum(
                np.hypot(c.x - (cx + math.sin(lo) * r_arc), c.y - (cy - math.cos(lo) * r_arc)),
                np.hypot(c.x - (cx + math.sin(hi) * r_arc), c.y - (cy - math.cos(hi) * r_arc))) - w_arc / 2
            fill = np.maximum(cov(ring) * sel, cov(ends) * (hi - lo > 1e-3))
            glow = blur(fill, 0.05 * d)
            c.add(accent, glow * 0.45)
            c.over(accent, fill)
            c.over((1, 1, 1), fill * cov(np.abs(rad - r_arc) - w_arc * 0.12) * 0.35)
        rot = a_val if skirt_turn else 0.0
        knurl = 0.5 + 0.5 * np.cos(36 * (ang - rot))
        skirt_rgb = skirt_shade * (0.80 + 0.35 * knurl * (rad > r_cap + 0.012 * d))[..., None]
        c.over(skirt_rgb, skirt_cov)
        if cap:
            c.over((0, 0, 0), rim_lo * 0.6)
            c.over(cap_rgb, cap_cov)
            c.over((1, 1, 1), rim_hi * 0.55)
            c.over((0.30, 0.31, 0.33), dimple * 0.35)
        if pointer:
            sx, sy = math.sin(a_val), -math.cos(a_val)
            r0, r1 = 0.11 * d, r_skirt - 0.02 * d
            pw = max(1.4, 0.05 * d)
            c.over((0, 0, 0), cov(sd_segment(c, cx + sx * r0, cy + sy * r0, cx + sx * r1, cy + sy * r1, pw * 1.7)) * 0.55)
            c.over((0.97, 0.95, 0.90), cov(sd_segment(c, cx + sx * r0, cy + sy * r0, cx + sx * r1, cy + sy * r1, pw)))
            tip = cov(sd_segment(c, cx + sx * (r1 - 0.06 * d), cy + sy * (r1 - 0.06 * d), cx + sx * r1, cy + sy * r1, pw))
            c.over(accent, tip)
        return c

    def pointer_layer():
        c = Canvas(d, d)
        r0, r1 = 0.11 * d, r_skirt - 0.02 * d
        pw = max(1.4, 0.05 * d)
        c.over((0, 0, 0), cov(sd_segment(c, cx, cy - r0, cx, cy - r1, pw * 1.7)) * 0.55)
        c.over((0.97, 0.95, 0.90), cov(sd_segment(c, cx, cy - r0, cx, cy - r1, pw)))
        c.over(accent, cov(sd_segment(c, cx, cy - (r1 - 0.06 * d), cx, cy - r1, pw)))
        return c

    return frame, pointer_layer


def filmstrip(frames):
    w, h = frames[0].size
    strip = Image.new("RGBA", (w, h * len(frames)))
    for i, f in enumerate(frames):
        strip.paste(f, (0, i * h))
    return strip


def groove_track(w, h, vertical):
    c = Canvas(w, h)
    if vertical:
        tw = max(4.0, w * 0.22)
        x0, x1, y0, y1 = (w - tw) / 2, (w + tw) / 2, 2, h - 2
    else:
        tw = max(4.0, h * 0.22)
        x0, x1, y0, y1 = 2, w - 2, (h - tw) / 2, (h + tw) / 2
    s = sd_rrect(c, x0, y0, x1, y1, tw / 2)
    c.over((1, 1, 1), cov(sd_rrect(c, x0 - 0.8, y0 - 0.2, x1 + 0.8, y1 + 1.0, tw / 2 + 0.8)) * 0.07)
    c.over(PAL["groove"], cov(s))
    inner = blur(cov(-s - 1.2), 1.0)
    c.over((0, 0, 0), cov(s) * (1 - inner) * 0.6)
    # scale ticks beside the track
    n = 11
    for i in range(n):
        if vertical:
            yy = 8 + (h - 16) * i / (n - 1)
            for xx in ((x0 - 6, x0 - 3), (x1 + 3, x1 + 6)):
                c.over(PAL["tick"], cov(sd_segment(c, xx[0], yy, xx[1], yy, 0.9)) * (0.8 if i % 5 == 0 else 0.45))
        else:
            xx = 8 + (w - 16) * i / (n - 1)
            for yy in ((y0 - 6, y0 - 3), (y1 + 3, y1 + 6)):
                c.over(PAL["tick"], cov(sd_segment(c, xx, yy[0], xx, yy[1], 0.9)) * (0.8 if i % 5 == 0 else 0.45))
    return c.image()


def track_fill(w, h, vertical, accent):
    c = Canvas(w, h)
    if vertical:
        tw = max(4.0, w * 0.22)
        x0, x1, y0, y1 = (w - tw) / 2, (w + tw) / 2, 2, h - 2
    else:
        tw = max(4.0, h * 0.22)
        x0, x1, y0, y1 = 2, w - 2, (h - tw) / 2, (h + tw) / 2
    s = sd_rrect(c, x0 + 0.8, y0 + 0.8, x1 - 0.8, y1 - 0.8, tw / 2 - 0.8)
    glow = blur(cov(s), 2.0)
    c.add(accent, glow * 0.35)
    c.over(accent, cov(s))
    c.over((1, 1, 1), cov(s) * 0.18 * (np.abs((c.x - (x0 + x1) / 2) if vertical else (c.y - (y0 + y1) / 2)) < tw * 0.15))
    return c.image()


def fader_thumb(w, h, vertical, accent):
    c = Canvas(w, h)
    m = 1.5
    sh = blur(cov(sd_rrect(c, m, m + 1.5, w - m, h - m + 1.5, 3)), 1.5)
    c.over((0, 0, 0), sh * 0.7)
    s = sd_rrect(c, m, m, w - m, h - m, 3)
    c.over(vgrad(c, m, h - m, (0.32, 0.33, 0.35), (0.12, 0.125, 0.135)), cov(s))
    c.over((1, 1, 1), cov(np.abs(s + 0.6) - 0.4) * (c.y < h * 0.5) * 0.25)
    # ridges
    if vertical:
        for i in range(-2, 3):
            if i == 0:
                continue
            yy = h / 2 + i * h * 0.14
            c.over((0.05, 0.05, 0.06), cov(sd_segment(c, w * 0.18, yy, w * 0.82, yy, 1.0)) * 0.8)
            c.over((1, 1, 1), cov(sd_segment(c, w * 0.18, yy + 1, w * 0.82, yy + 1, 0.7)) * 0.12)
        c.over(accent, cov(sd_segment(c, w * 0.12, h / 2, w * 0.88, h / 2, 1.6)))
    else:
        for i in range(-2, 3):
            if i == 0:
                continue
            xx = w / 2 + i * w * 0.14
            c.over((0.05, 0.05, 0.06), cov(sd_segment(c, xx, h * 0.18, xx, h * 0.82, 1.0)) * 0.8)
            c.over((1, 1, 1), cov(sd_segment(c, xx + 1, h * 0.18, xx + 1, h * 0.82, 0.7)) * 0.12)
        c.over(accent, cov(sd_segment(c, w / 2, h * 0.12, w / 2, h * 0.88, 1.6)))
    return c.image()


def button(w, h, state, accent):
    c = Canvas(w, h)
    m = 1.0
    s = sd_rrect(c, m, m, w - m, h - m, 5)
    c.over((0, 0, 0), cov(sd_rrect(c, m, m + 1.0, w - m, h - m + 1.0, 5)) * 0.6)
    if state == "pressed":
        top, bot = (0.07, 0.074, 0.08), (0.14, 0.145, 0.155)
    elif state == "hover":
        top, bot = (0.34, 0.35, 0.37), (0.17, 0.175, 0.19)
    else:
        top, bot = (0.27, 0.28, 0.30), (0.13, 0.135, 0.145)
    # Gradient only inside the top/bottom 8 px insets; the stretchable middle is flat.
    shade = 0.5 * np.clip((c.y - m) / 8, 0, 1) + 0.5 * np.clip((c.y - (h - 8)) / (8 - m), 0, 1)
    c.over(mix(top, bot, shade), cov(s))
    edge = cov(np.abs(s + 0.5) - 0.5)
    if state == "pressed":
        c.over(accent, edge * 0.9)
        c.add(accent, blur(edge, 2.0) * cov(s) * 0.35)
        c.over((0, 0, 0), cov(s) * (1 - blur(cov(-s - 2.0), 1.5)) * 0.5)
    else:
        c.over((1, 1, 1), edge * (c.y < 7) * 0.22)
        c.over((0, 0, 0), edge * (c.y > h - 7) * 0.5)
    return c.image()


def inset_box(w, h, r=3.0, color=None):
    c = Canvas(w, h)
    s = sd_rrect(c, 1, 1, w - 1, h - 1, r)
    c.over((1, 1, 1), cov(sd_rrect(c, 0.5, 1.5, w - 0.5, h - 0.2, r + 0.5)) * 0.08)
    c.over(PAL["lcd"] if color is None else color, cov(s))
    c.over((0, 0, 0), cov(s) * (1 - blur(cov(-s - 1.5), 1.2)) * 0.75)
    return c


def checkbox(size, on, accent):
    c = inset_box(size, size, r=3.0, color=PAL["groove"])
    if on:
        p = [(0.27, 0.53), (0.43, 0.69), (0.74, 0.32)]
        pts = [(x * size, y * size) for x, y in p]
        w = max(1.8, size * 0.13)
        m = np.minimum(sd_segment(c, *pts[0], *pts[1], w), sd_segment(c, *pts[1], *pts[2], w))
        c.add(accent, blur(cov(m), size * 0.12) * 0.7)
        c.over(accent, cov(m))
        c.over((1, 1, 1), cov(m + w * 0.3) * 0.35)
    return c.image()


def toggle_switch(w, h, on, accent):
    c = Canvas(w, h)
    s = sd_rrect(c, 1, 1, w - 1, h - 1, (h - 2) / 2)
    c.over((1, 1, 1), cov(sd_rrect(c, 0.5, 1.5, w - 0.5, h - 0.2, (h - 1) / 2)) * 0.08)
    c.over(PAL["groove"], cov(s))
    if on:
        c.over(accent, cov(s + 1.5) * 0.85)
        c.add(accent, blur(cov(s + 1.5), 2) * 0.3)
    c.over((0, 0, 0), cov(s) * (1 - blur(cov(-s - 1.5), 1.2)) * 0.6)
    r = (h - 2) / 2 - 1.5
    kx = (w - 1 - 1.5 - r) if on else (1 + 1.5 + r)
    ky = h / 2
    c.over((0, 0, 0), blur(cov(sd_circle(c, kx, ky + 1.2, r)), 1.2) * 0.7)
    c.over(vgrad(c, ky - r, ky + r, PAL["metal_hi"], PAL["metal_lo"]), cov(sd_circle(c, kx, ky, r)))
    return c.image()


def radio(size, on, accent):
    c = Canvas(size, size)
    cx = cy = size / 2
    s = sd_circle(c, cx, cy, size / 2 - 1)
    c.over((1, 1, 1), cov(sd_circle(c, cx, cy + 0.6, size / 2 - 0.6)) * 0.08)
    c.over(PAL["groove"], cov(s))
    c.over((0, 0, 0), cov(s) * (1 - blur(cov(-s - 1.4), 1.0)) * 0.7)
    if on:
        dot = sd_circle(c, cx, cy, size * 0.22)
        c.add(accent, blur(cov(dot), size * 0.15) * 0.8)
        c.over(accent, cov(dot))
        c.over((1, 1, 1), cov(sd_circle(c, cx - size * 0.06, cy - size * 0.07, size * 0.07)) * 0.5)
    return c.image()


def led(size, color, on):
    c = Canvas(size, size)
    cx = cy = size / 2
    r = size * 0.32
    c.over((0, 0, 0), cov(sd_circle(c, cx, cy, r + 1.2)) * 0.8)
    col = np.asarray(color, np.float32)
    if on:
        c.add(col, blur(cov(sd_circle(c, cx, cy, r)), size * 0.18) * 0.9)
        c.over(mix(col, (1, 1, 1), 0.15), cov(sd_circle(c, cx, cy, r)))
        c.over((1, 1, 1), cov(sd_circle(c, cx, cy, r * 0.45)) * 0.55)
    else:
        c.over(col * 0.22, cov(sd_circle(c, cx, cy, r)))
    c.over((1, 1, 1), cov(sd_circle(c, cx - r * 0.35, cy - r * 0.4, r * 0.3)) * (0.6 if on else 0.25))
    return c.image()


def arrow(w, h, up, pressed, accent):
    c = Canvas(w, h)
    s = sd_rrect(c, 0.5, 0.5, w - 0.5, h - 0.5, 2.5)
    top, bot = ((0.10, 0.10, 0.11), (0.16, 0.16, 0.17)) if pressed else ((0.28, 0.29, 0.31), (0.15, 0.155, 0.165))
    c.over(vgrad(c, 0, h, top, bot), cov(s))
    cx, cy = w / 2, h / 2
    # explicit triangle via half-planes
    if up:
        a, b, d = (cx - w * 0.24, cy + h * 0.17), (cx + w * 0.24, cy + h * 0.17), (cx, cy - h * 0.2)
    else:
        a, b, d = (cx - w * 0.24, cy - h * 0.17), (cx + w * 0.24, cy - h * 0.17), (cx, cy + h * 0.2)

    def edge(p, q):
        nx, ny = q[1] - p[1], -(q[0] - p[0])
        ln = math.hypot(nx, ny)
        return ((c.x - p[0]) * nx + (c.y - p[1]) * ny) / ln

    e = np.maximum.reduce([edge(a, b), edge(b, d), edge(d, a)])
    if np.mean(e < 0) == 0:
        e = np.maximum.reduce([-edge(a, b), -edge(b, d), -edge(d, a)])
    c.over(accent if pressed else PAL["text"], cov(e))
    return c.image()


def menu_box(w, h, accent):
    c = Canvas(w, h)
    s = sd_rrect(c, 1, 1, w - 1, h - 1, 4)
    c.over((0, 0, 0), cov(sd_rrect(c, 1, 2, w - 1, h, 4)) * 0.5)
    c.over(vgrad(c, 1, h - 1, (0.20, 0.205, 0.22), (0.10, 0.104, 0.112)), cov(s))
    c.over((1, 1, 1), cov(np.abs(s + 0.5) - 0.5) * (c.y < 5) * 0.18)
    # arrow well on the right
    xw = w - h
    c.over((0, 0, 0), cov(np.abs(c.x - xw) - 0.5) * cov(s + 3) * 0.6)
    c.over((1, 1, 1), cov(np.abs(c.x - xw - 1) - 0.5) * cov(s + 3) * 0.06)
    return c.image()


def menu_arrow(w, h, accent):
    c = Canvas(w, h)
    a, b, d = (w * 0.1, h * 0.2), (w * 0.9, h * 0.2), (w * 0.5, h * 0.85)

    def edge(p, q):
        nx, ny = -(q[1] - p[1]), (q[0] - p[0])
        ln = math.hypot(nx, ny)
        return ((c.x - p[0]) * nx + (c.y - p[1]) * ny) / ln

    e = np.maximum.reduce([edge(a, b), edge(b, d), edge(d, a)])
    if np.mean(e < 0) == 0:
        e = np.maximum.reduce([-edge(a, b), -edge(b, d), -edge(d, a)])
    c.over(accent, cov(e))
    return c.image()


def popup(w, h):
    c = Canvas(w, h)
    s = sd_rrect(c, 0.5, 0.5, w - 0.5, h - 0.5, 4)
    c.over((0.075, 0.08, 0.088), cov(s))
    c.over((0.30, 0.31, 0.33), cov(np.abs(s + 0.5) - 0.5))
    return c.image()


def menu_highlight(w, h, accent):
    c = Canvas(w, h)
    s = sd_rrect(c, 1, 1, w - 1, h - 1, 3)
    c.over(np.asarray(accent) * 0.35, cov(s))
    c.over(accent, cov(np.abs(c.x - 2.5) - 1.0) * cov(s))
    return c.image()


def meter(w, h, vertical, on, segments=24):
    c = Canvas(w, h)
    bg = sd_rrect(c, 0, 0, w, h, 2)
    c.over((0.03, 0.033, 0.036), cov(bg))
    length = h if vertical else w
    gap = 1.2
    seg = (length - 4 - gap * (segments - 1)) / segments
    for i in range(segments):
        t = (i + 0.5) / segments
        col = PAL["green"] if t < 0.62 else (PAL["yellow"] if t < 0.85 else PAL["red"])
        p0 = 2 + i * (seg + gap)
        if vertical:
            y1 = h - p0
            s = sd_rrect(c, 2.5, y1 - seg, w - 2.5, y1, 1)
        else:
            s = sd_rrect(c, p0, 2.5, p0 + seg, h - 2.5, 1)
        if on:
            c.add(col, blur(cov(s), 1.2) * 0.45)
            c.over(col, cov(s))
            c.over((1, 1, 1), cov(s + 1.0) * 0.18)
        else:
            c.over(np.asarray(col) * 0.16, cov(s))
    return c.image()


def group_frame(w, h, accent):
    c = Canvas(w, h)
    s = sd_rrect(c, 1, 1, w - 1, h - 1, 7)
    c.over((0, 0, 0), blur(cov(sd_rrect(c, 2, 3, w - 2, h - 0.5, 7)), 1.5) * 0.55)
    # Flat fill, with edge lighting confined to the 12 px nine-slice insets so
    # stretching never shows a seam.
    c.over((0.136, 0.143, 0.156), cov(s))
    edge = cov(np.abs(s + 0.5) - 0.5)
    c.over((1, 1, 1), edge * (0.13 * (c.y < 10) + 0.04))
    c.over((0, 0, 0), edge * (c.y > h - 10) * 0.35)
    return c.image()


def label_plate(w, h):
    c = Canvas(w, h)
    s = sd_rrect(c, 0.5, 0.5, w - 0.5, h - 0.5, h / 2 - 0.5)
    c.over((0.065, 0.07, 0.078), cov(s))
    c.over((1, 1, 1), cov(np.abs(s + 0.5) - 0.5) * (c.y > h * 0.5) * 0.10)
    return c.image()


def tab(w, h, active, accent):
    c = Canvas(w, h)
    s = sd_rrect(c, 1, 1, w - 1, h + 8, 6)  # rounded top corners only
    if active:
        c.over(vgrad(c, 1, h, (0.19, 0.198, 0.214), (0.150, 0.158, 0.172)), cov(s))
        c.over(accent, cov(np.abs(c.y - 2.0) - 1.0) * cov(s + 2.0))
    else:
        c.over(vgrad(c, 1, h, (0.11, 0.115, 0.126), (0.085, 0.09, 0.1)), cov(s))
    c.over((1, 1, 1), cov(np.abs(s + 0.5) - 0.5) * (c.y < 6) * 0.10)
    return c.image()


def lcd_label(w, h, accent):
    c = inset_box(w, h, r=3.0, color=mix(PAL["lcd"], accent, 0.04))
    return c.image()


# ---------------------------------------------------------------- build
def build(out, accent, scale, manifest):
    sub = f"{scale}x"
    root = os.path.join(out, sub)
    S = scale

    def save(img, rel, kind, **meta):
        path = os.path.join(root, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        img.save(path, optimize=True)
        key = rel.rsplit(".", 1)[0]
        entry = manifest.setdefault(key, {"type": kind})
        entry.update({k: v for k, v in meta.items()})
        entry.setdefault("files", {})[sub] = f"{sub}/{rel}"
        entry.setdefault("size", {})[sub] = list(img.size)

    # Large, smooth images: the SDF edges are already anti-aliased, so render
    # without supersampling to keep memory reasonable.
    global SS
    keep, SS = SS, 1
    save(background(1200 * S, 800 * S, accent), "background/panel_default.png", "background",
         note="Full panel 1200x800 (1x) with header band (44 px), vignette and corner screws.")
    save(background_tile(256 * S), "background/panel_tile.png", "background-tile",
         note="Seamless brushed-metal tile for panels of any size.")
    SS = keep

    for name, d, ticks in (("knob_large", 80, True), ("knob_medium", 56, True), ("knob_small", 36, False)):
        frame, pointer = knob_layers(d * S, accent, ticks=ticks)
        frames = [frame(i / (KNOB_FRAMES - 1)).image() for i in range(KNOB_FRAMES)]
        save(filmstrip(frames), f"knobs/{name}_strip.png", "knob-filmstrip",
             frames=KNOB_FRAMES, orientation="vertical", frame_size=[d, d],
             sweep_degrees=KNOB_SWEEP, note="Frame 0 = minimum, last frame = maximum.")
        save(frame(0.0, pointer=False, arc=False, skirt_turn=False).image(), f"knobs/{name}_base.png", "knob-base",
             note="Static knob body without pointer or value arc, for toolkits that rotate a pointer.")
        save(pointer().image(), f"knobs/{name}_pointer.png", "knob-pointer",
             note="Pointer at 12 o'clock on a transparent square; rotate about the centre "
                  f"from -{KNOB_SWEEP / 2:g} to +{KNOB_SWEEP / 2:g} degrees.")
        if name == "knob_medium":
            bframes = [frame(i / (KNOB_FRAMES - 1), bipolar=True).image() for i in range(KNOB_FRAMES)]
            save(filmstrip(bframes), f"knobs/{name}_bipolar_strip.png", "knob-filmstrip",
                 frames=KNOB_FRAMES, orientation="vertical", frame_size=[d, d], sweep_degrees=KNOB_SWEEP,
                 note="Value arc grows from 12 o'clock: for pan, detune and other +/- ranges.")

    save(groove_track(28 * S, 160 * S, True), "sliders/vslider_track.png", "slider-track",
         nine_slice=[0, 12, 0, 12], note="Stretch vertically between the insets.")
    save(track_fill(28 * S, 160 * S, True, accent), "sliders/vslider_fill.png", "slider-fill",
         nine_slice=[0, 12, 0, 12], note="Accent fill: clip from the bottom to the value.")
    save(fader_thumb(34 * S, 18 * S, True, accent), "sliders/vslider_thumb.png", "slider-thumb",
         hotspot=[17, 9])
    save(groove_track(160 * S, 28 * S, False), "sliders/hslider_track.png", "slider-track",
         nine_slice=[12, 0, 12, 0], note="Stretch horizontally between the insets.")
    save(track_fill(160 * S, 28 * S, False, accent), "sliders/hslider_fill.png", "slider-fill",
         nine_slice=[12, 0, 12, 0], note="Accent fill: clip from the left to the value.")
    save(fader_thumb(18 * S, 34 * S, False, accent), "sliders/hslider_thumb.png", "slider-thumb",
         hotspot=[9, 17])

    for st in ("normal", "hover", "pressed"):
        save(button(96 * S, 30 * S, st, accent), f"buttons/button_{st}.png", "button",
             nine_slice=[8, 8, 8, 8])
    for on in (False, True):
        tag = "on" if on else "off"
        save(checkbox(20 * S, on, accent), f"toggles/checkbox_{tag}.png", "checkbox")
        save(toggle_switch(40 * S, 22 * S, on, accent), f"toggles/switch_{tag}.png", "switch",
             note="Alternative look for Faust checkboxes.")
        save(radio(18 * S, on, accent), f"toggles/radio_{tag}.png", "radio")
    for cname, col in (("amber", accent), ("green", PAL["green"]), ("red", PAL["red"])):
        for on in (False, True):
            save(led(16 * S, col, on), f"leds/led_{cname}_{'on' if on else 'off'}.png", "led")

    save(inset_box(80 * S, 24 * S).image(), "entries/nentry_box.png", "nentry-box", nine_slice=[6, 6, 6, 6])
    for up in (True, False):
        for pressed in (False, True):
            save(arrow(14 * S, 11 * S, up, pressed, accent),
                 f"entries/nentry_{'up' if up else 'down'}_{'pressed' if pressed else 'normal'}.png", "nentry-arrow")
    save(menu_box(130 * S, 24 * S, accent), "menus/menu_box.png", "menu-box",
         nine_slice=[8, 6, 30, 6], note="Right 24 px is the arrow well; keep it in the right inset.")
    save(menu_arrow(10 * S, 7 * S, accent), "menus/menu_arrow.png", "menu-arrow")
    save(popup(160 * S, 120 * S), "menus/menu_popup.png", "menu-popup", nine_slice=[6, 6, 6, 6])
    save(menu_highlight(160 * S, 22 * S, accent), "menus/menu_item_highlight.png", "menu-highlight",
         nine_slice=[6, 4, 6, 4])

    save(meter(14 * S, 160 * S, True, False), "meters/vbargraph_off.png", "bargraph",
         note="Unlit LED column; draw vbargraph_on clipped from the bottom to the value.")
    save(meter(14 * S, 160 * S, True, True), "meters/vbargraph_on.png", "bargraph")
    save(meter(160 * S, 14 * S, False, False), "meters/hbargraph_off.png", "bargraph",
         note="Unlit LED row; draw hbargraph_on clipped from the left to the value.")
    save(meter(160 * S, 14 * S, False, True), "meters/hbargraph_on.png", "bargraph")

    save(group_frame(220 * S, 160 * S, accent), "groups/group_frame.png", "group-frame",
         nine_slice=[12, 12, 12, 12], note="hgroup / vgroup panel.")
    save(label_plate(120 * S, 18 * S), "groups/label_plate.png", "label-plate", nine_slice=[9, 0, 9, 0])
    save(tab(110 * S, 26 * S, False, accent), "groups/tab_normal.png", "tab", nine_slice=[8, 6, 8, 0])
    save(tab(110 * S, 26 * S, True, accent), "groups/tab_active.png", "tab", nine_slice=[8, 6, 8, 0])
    save(lcd_label(64 * S, 18 * S, accent), "groups/value_display.png", "value-display",
         nine_slice=[5, 5, 5, 5], note="Numeric readout under knobs and sliders.")


def preview(out, accent):
    """Compose a mock plugin dialog from the 1x assets, plus a contact sheet."""
    a = lambda rel: Image.open(os.path.join(out, "1x", rel)).convert("RGBA")
    font = lambda s, bold=False: ImageFont.truetype(
        "/usr/share/fonts/truetype/dejavu/DejaVuSans%s.ttf" % ("-Bold" if bold else ""), s)
    W, H = 900, 520
    img = a("background/panel_default.png").resize((W, H), Image.LANCZOS)
    dr = ImageDraw.Draw(img)
    acc = tuple(int(v * 255) for v in accent)
    txt = (220, 222, 225)
    dim = (150, 154, 160)
    dr.text((26, 12), "RTAL FORGE", font=font(18, True), fill=acc)
    dr.text((160, 16), "theme preview", font=font(13), fill=dim)

    def nine(img_rel, w, h, ins):
        src = a(img_rel)
        l, t, r, b = ins
        sw, sh = src.size
        out_ = Image.new("RGBA", (w, h))
        cols = [(0, l, 0, l), (l, sw - r, l, w - r), (sw - r, sw, w - r, w)]
        rows = [(0, t, 0, t), (t, sh - b, t, h - b), (sh - b, sh, h - b, h)]
        for (sx0, sx1, dx0, dx1) in cols:
            for (sy0, sy1, dy0, dy1) in rows:
                if sx1 > sx0 and sy1 > sy0 and dx1 > dx0 and dy1 > dy0:
                    out_.paste(src.crop((sx0, sy0, sx1, sy1)).resize((dx1 - dx0, dy1 - dy0)), (dx0, dy0))
        return out_

    def put(im, x, y):
        img.alpha_composite(im, (int(x), int(y)))

    def frame_of(strip_rel, t):
        s = a(strip_rel)
        fw = s.size[0]
        i = round(t * (KNOB_FRAMES - 1))
        return s.crop((0, i * fw, fw, (i + 1) * fw))

    def label(x, y, text, w):
        f = font(11)
        tw = dr.textlength(text, font=f)
        dr.text((x + (w - tw) / 2, y), text, font=f, fill=txt)

    def value(x, y, text, w=64):
        put(nine("groups/value_display.png", w, 18, (5, 5, 5, 5)), x, y)
        f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf", 11)
        tw = dr.textlength(text, font=f)
        dr.text((x + (w - tw) / 2, y + 2), text, font=f, fill=acc)

    # tabs
    put(nine("groups/tab_active.png", 110, 26, (8, 6, 8, 0)), 24, 58)
    put(nine("groups/tab_normal.png", 110, 26, (8, 6, 8, 0)), 136, 58)
    put(nine("groups/tab_normal.png", 110, 26, (8, 6, 8, 0)), 248, 58)
    for i, t in enumerate(("Amp", "Effects", "Cab & Mics")):
        f = font(12, i == 0)
        tw = dr.textlength(t, font=f)
        dr.text((24 + i * 112 + (110 - tw) / 2, 63), t, font=f, fill=txt if i == 0 else dim)

    # amp group
    put(nine("groups/group_frame.png", 520, 200, (12, 12, 12, 12)), 24, 84)
    put(nine("groups/label_plate.png", 100, 18, (9, 0, 9, 0)), 40, 92)
    dr.text((58, 94), "PREAMP", font=font(10, True), fill=dim)
    names = [("Gain", 0.72), ("Bass", 0.55), ("Middle", 0.4), ("Treble", 0.63), ("Master", 0.3)]
    for i, (n, t) in enumerate(names):
        x = 44 + i * 98
        put(frame_of("knobs/knob_large_strip.png", t), x, 118)
        label(x, 202, n, 80)
        value(x + 8, 220, f"{t * 10:4.1f}")
    # menu + entry
    put(nine("menus/menu_box.png", 150, 24, (8, 6, 30, 6)), 380, 94)
    put(a("menus/menu_arrow.png"), 380 + 150 - 17, 94 + 9)
    dr.text((390, 99), "Plex Lead 59", font=font(11), fill=txt)

    # right column: mic group with sliders and meters
    put(nine("groups/group_frame.png", 320, 200, (12, 12, 12, 12)), 556, 84)
    put(nine("groups/label_plate.png", 110, 18, (9, 0, 9, 0)), 572, 92)
    dr.text((588, 94), "MIC & LEVEL", font=font(10, True), fill=dim)
    for i, t in enumerate((0.7, 0.45)):
        x = 590 + i * 60
        tr = nine("sliders/vslider_track.png", 28, 140, (0, 12, 0, 12))
        put(tr, x, 120)
        fill = nine("sliders/vslider_fill.png", 28, 140, (0, 12, 0, 12))
        top = int(120 + 2 + (1 - t) * 136)
        put(fill.crop((0, top - 120, 28, 140)), x, top)
        th = a("sliders/vslider_thumb.png")
        put(th, x - 3, top - 9)
        label(x - 16, 266, ("Level", "Room")[i], 60)
    for i, t in enumerate((0.78, 0.66)):
        x = 720 + i * 22
        put(a("meters/vbargraph_off.png").resize((14, 150)), x, 118)
        on = a("meters/vbargraph_on.png").resize((14, 150))
        cut = int(150 * (1 - t))
        put(on.crop((0, cut, 14, 150)), x, 118 + cut)
    label(706, 272, "Out L/R", 64)
    for j, (name, t, bip) in enumerate((("Pan", 0.35, True), ("Width", 0.8, False))):
        x, y = 784, 112 + j * 84
        put(frame_of("knobs/knob_medium_bipolar_strip.png" if bip else "knobs/knob_medium_strip.png", t), x, y)
        label(x - 6, y + 58, name, 68)

    # bottom row: effects
    put(nine("groups/group_frame.png", 852, 200, (12, 12, 12, 12)), 24, 296)
    put(nine("groups/label_plate.png", 120, 18, (9, 0, 9, 0)), 40, 304)
    dr.text((60, 306), "EFFECTS CHAIN", font=font(10, True), fill=dim)
    small = [("Rate", 0.3), ("Depth", 0.6), ("Mix", 0.45), ("Time", 0.7), ("Fdbk", 0.35), ("Tone", 0.55)]
    for i, (n, t) in enumerate(small):
        x = 44 + i * 64
        put(frame_of("knobs/knob_small_strip.png", t), x + 10, 336)
        label(x, 376, n, 56)
    for i, (n, on) in enumerate((("Chorus", True), ("Delay", True), ("Reverb", False))):
        put(a("toggles/checkbox_%s.png" % ("on" if on else "off")), 446, 334 + i * 28)
        dr.text((474, 336 + i * 28), n, font=font(12), fill=txt)
    for i, (n, on) in enumerate((("Ping Pong", True), ("Tape Wow", False))):
        put(a("toggles/switch_%s.png" % ("on" if on else "off")), 556, 334 + i * 30)
        dr.text((604, 337 + i * 30), n, font=font(12), fill=txt)
    for i, (n, on) in enumerate((("1/4", False), ("1/8", True), ("Dotted", False))):
        put(a("toggles/radio_%s.png" % ("on" if on else "off")), 700 + i * 58, 336)
        dr.text((722 + i * 58, 337), n, font=font(11), fill=txt)
    put(a("leds/led_green_on.png"), 700, 368)
    put(a("leds/led_amber_on.png"), 720, 368)
    put(a("leds/led_red_off.png"), 740, 368)
    dr.text((764, 368), "Lock", font=font(11), fill=dim)
    # hslider
    put(nine("sliders/hslider_track.png", 300, 28, (12, 0, 12, 0)), 44, 406)
    hf = nine("sliders/hslider_fill.png", 300, 28, (12, 0, 12, 0))
    put(hf.crop((0, 0, 190, 28)), 44, 406)
    put(a("sliders/hslider_thumb.png"), 44 + 190 - 9, 403)
    label(44, 438, "Pre-Delay", 300)
    put(a("meters/hbargraph_off.png").resize((220, 14)), 380, 413)
    put(a("meters/hbargraph_on.png").resize((220, 14)).crop((0, 0, 150, 14)), 380, 413)
    label(380, 438, "Input", 220)
    # nentry + buttons
    put(nine("entries/nentry_box.png", 80, 24, (6, 6, 6, 6)), 630, 408)
    dr.text((642, 412), "120.0", font=ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf", 12), fill=acc)
    put(a("entries/nentry_up_normal.png"), 712, 408)
    put(a("entries/nentry_down_normal.png"), 712, 421)
    label(630, 438, "BPM", 96)
    put(nine("buttons/button_normal.png", 90, 30, (8, 8, 8, 8)), 760, 404)
    dr.text((785, 411), "Tap", font=font(12), fill=txt)
    put(nine("buttons/button_pressed.png", 90, 30, (8, 8, 8, 8)), 760, 448)
    dr.text((779, 455), "Freeze", font=font(12), fill=acc)
    img.save(os.path.join(out, "preview_dialog.png"), optimize=True)

    # contact sheet of every 1x asset
    files = []
    for dp, _, fs in os.walk(os.path.join(out, "1x")):
        for f in sorted(fs):
            if f.endswith(".png") and "panel_default" not in f:
                files.append(os.path.join(dp, f))
    files.sort()
    thumbs = []
    for f in files:
        im = Image.open(f).convert("RGBA")
        if im.size[1] > 4 * im.size[0] and "strip" in f:  # show five frames of a strip
            fw = im.size[0]
            n = im.size[1] // fw
            sel = [round(k * (n - 1) / 4) for k in range(5)]
            row = Image.new("RGBA", (fw * 5 + 16, fw))
            for k, s in enumerate(sel):
                row.paste(im.crop((0, s * fw, fw, (s + 1) * fw)), (k * (fw + 4), 0))
            im = row
        im.thumbnail((240, 170))
        thumbs.append((os.path.relpath(f, os.path.join(out, "1x")), im))
    cols, cw, ch = 4, 260, 205
    rows = (len(thumbs) + cols - 1) // cols
    sheet = a("background/panel_tile.png").resize((256, 256))
    big = Image.new("RGBA", (cols * cw, rows * ch))
    for yy in range(0, big.size[1], 256):
        for xx in range(0, big.size[0], 256):
            big.paste(sheet, (xx, yy))
    dsh = ImageDraw.Draw(big)
    for i, (name, im) in enumerate(thumbs):
        x, y = (i % cols) * cw, (i // cols) * ch
        big.alpha_composite(im, (x + (cw - im.size[0]) // 2, y + 10 + (170 - im.size[1]) // 2))
        f = font(10)
        tw = dsh.textlength(name, font=f)
        dsh.text((x + (cw - tw) / 2, y + ch - 22), name, font=f, fill=(200, 202, 206))
    big.save(os.path.join(out, "contact_sheet.png"), optimize=True)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", default=os.path.dirname(os.path.abspath(__file__)))
    ap.add_argument("--accent", default="ff9a2e", help="accent colour as hex RGB (default ff9a2e, amber)")
    ap.add_argument("--scales", default="1,2", help="comma-separated scale factors (default 1,2)")
    args = ap.parse_args()
    accent = hex_rgb(args.accent)
    manifest = {}
    for s in [int(v) for v in args.scales.split(",")]:
        build(args.out, accent, s, manifest)
        print(f"rendered {s}x")
    theme = {
        "name": "RTAL Forge",
        "version": "1.0",
        "author": "rtaudiolinux <rtaudiolinux.v1@gmail.com>",
        "license": "DOC-1.0",
        "accent": "#" + args.accent.lstrip("#"),
        "conventions": {
            "units": "Sizes and insets are in 1x pixels; 2x images are exactly double.",
            "nine_slice": "[left, top, right, bottom] insets kept unscaled when stretching.",
            "filmstrips": f"Vertical, square frames, {KNOB_FRAMES} frames from minimum to maximum.",
            "knob_sweep": f"{KNOB_SWEEP:g} degrees, from -{KNOB_SWEEP / 2:g} (min) to +{KNOB_SWEEP / 2:g} (max), 0 = 12 o'clock.",
            "bargraphs": "Draw *_off, then *_on clipped to the value (from the bottom or left).",
        },
        "faust_widget_map": {
            "hslider": ["sliders/hslider_track", "sliders/hslider_fill", "sliders/hslider_thumb", "groups/value_display"],
            "vslider": ["sliders/vslider_track", "sliders/vslider_fill", "sliders/vslider_thumb", "groups/value_display"],
            "hslider/vslider [style:knob]": ["knobs/knob_medium_strip", "knobs/knob_large_strip", "knobs/knob_small_strip",
                                              "knobs/knob_medium_bipolar_strip (when min < 0 < max)"],
            "nentry": ["entries/nentry_box", "entries/nentry_up_normal", "entries/nentry_down_normal"],
            "nentry/hslider [style:menu{...}]": ["menus/menu_box", "menus/menu_arrow", "menus/menu_popup", "menus/menu_item_highlight"],
            "nentry/hslider [style:radio{...}]": ["toggles/radio_off", "toggles/radio_on"],
            "button": ["buttons/button_normal", "buttons/button_hover", "buttons/button_pressed"],
            "checkbox": ["toggles/checkbox_off", "toggles/checkbox_on", "toggles/switch_off (alternative)", "toggles/switch_on (alternative)"],
            "hbargraph": ["meters/hbargraph_off", "meters/hbargraph_on"],
            "vbargraph": ["meters/vbargraph_off", "meters/vbargraph_on"],
            "[style:led] bargraph": ["leds/led_*_off", "leds/led_*_on"],
            "hgroup / vgroup": ["groups/group_frame", "groups/label_plate"],
            "tgroup": ["groups/tab_normal", "groups/tab_active", "groups/group_frame"],
            "dialog background": ["background/panel_default", "background/panel_tile"],
        },
        "assets": manifest,
    }
    with open(os.path.join(args.out, "theme.json"), "w") as f:
        json.dump(theme, f, indent=2)
    preview(args.out, accent)
    print("wrote theme.json, preview_dialog.png, contact_sheet.png")


if __name__ == "__main__":
    main()
