#!/usr/bin/env python3
"""Draws the app icon and writes its appearance variants.

Generated rather than drawn in an editor because there is no editor here. It is
reproducible, and a change to the mark is a change to a number.

**What the mark is, and what it deliberately is not.** Two versions have been tried and
rejected. A small table with one cell marked was the product and its colour rule, and it had
too many parts. A flame said *fire*, and the app is about the response to a fire rather than
fire itself. So: a beacon and a light bar. Those are the shapes that mean *responder* — the
thing arriving, not the thing burning — which is what the feed actually reports.

Both are on a dark ground so the red carries, and both are two or three shapes rather than
fifteen, because at 29pt the whole mark is twenty points tall.

Apple's guidance for what we supply: flat, opaque, square. No transparency, no rounded
corners, no shadow, no attempt at glass. The platform applies the mask, the shadow and the
Liquid Glass treatment. Drawing any of those ourselves fights the system and looks wrong the
moment the system changes its approach.

Usage:
    python3 scripts/make_app_icon.py                    # write the installed icon
    python3 scripts/make_app_icon.py --compare          # every candidate, plus both previews
"""

import argparse
import math
import pathlib
import struct
import zlib

SIZE = 1024
SUPERSAMPLE = 2

# The lens. Brighter than the ground it sits on, because on a red icon a red light has to be
# the brighter red or it is not a light — and Apple's systemRed, which is built for text on a
# light background, reads as an error state at this size.
RED = (255, 74, 58, 255)
# The lens that alternates with it on real fire apparatus.
WHITE = (255, 246, 240, 255)
# The housing, and it has to be *visible*: the first value was almost exactly the ground, so
# the bar the lights sit in was there in the geometry and invisible in the picture.
HOUSING = (16, 5, 7, 255)
RAY = (255, 132, 104, 255)

OUT = pathlib.Path("TorontoLiveEMS/Assets.xcassets/AppIcon.appiconset")


class Canvas:
    """An RGBA pixel buffer with just enough drawing for two or three shapes."""

    def __init__(self, width, height):
        self.w = width
        self.h = height
        self.px = bytearray(width * height * 4)

    def set(self, x, y, colour):
        if 0 <= x < self.w and 0 <= y < self.h:
            i = (y * self.w + x) * 4
            self.px[i:i + 4] = bytes(colour)

    def get(self, x, y):
        i = (y * self.w + x) * 4
        return tuple(self.px[i:i + 3])

    def vertical_gradient(self, top, bottom):
        for y in range(self.h):
            t = y / max(1, self.h - 1)
            colour = bytes(round(top[c] + (bottom[c] - top[c]) * t) for c in range(4))
            i = y * self.w * 4
            self.px[i:i + self.w * 4] = colour * self.w

    def fill_polygon(self, points, colour):
        """Even-odd scanline fill.

        Scanline rather than testing every pixel in a bounding box: the mark is drawn at twice
        the output size, so a box test is hundreds of millions of point-in-polygon checks where
        this is a few hundred thousand.
        """
        ys = [p[1] for p in points]
        top, bottom = int(min(ys)), int(max(ys))
        n = len(points)
        for y in range(max(0, top), min(self.h, bottom + 1)):
            yc = y + 0.5
            crossings = []
            for i in range(n):
                ax, ay = points[i]
                bx, by = points[(i + 1) % n]
                if (ay <= yc < by) or (by <= yc < ay):
                    crossings.append(ax + (yc - ay) * (bx - ax) / (by - ay))
            crossings.sort()
            for i in range(0, len(crossings) - 1, 2):
                for x in range(max(0, int(crossings[i])), min(self.w, int(crossings[i + 1]) + 1)):
                    self.set(x, y, colour)

    def downsample(self, factor):
        out = Canvas(self.w // factor, self.h // factor)
        n = factor * factor
        for y in range(out.h):
            for x in range(out.w):
                r = g = b = a = 0
                for dy in range(factor):
                    row = (y * factor + dy) * self.w
                    for dx in range(factor):
                        i = (row + x * factor + dx) * 4
                        r += self.px[i]
                        g += self.px[i + 1]
                        b += self.px[i + 2]
                        a += self.px[i + 3]
                out.set(x, y, (r // n, g // n, b // n, a // n))
        return out

    def png(self):
        raw = bytearray()
        stride = self.w * 4
        for y in range(self.h):
            raw.append(0)  # filter: none
            raw += self.px[y * stride:(y + 1) * stride]

        def chunk(tag, data):
            body = tag + data
            return (
                struct.pack(">I", len(data))
                + body
                + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)
            )

        return (
            b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", self.w, self.h, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
            + chunk(b"IEND", b"")
        )

    def write(self, path):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(self.png())


# --- shapes, all in canvas pixels, all as polygons so one fill routine serves everything ---

def rrect(cx, cy, w, h, radius, corner_steps=24):
    """A rounded rectangle centred on (cx, cy)."""
    x0, y0, x1, y1 = cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2
    r = min(radius, w / 2, h / 2)
    pts = []

    def arc(ax, ay, start, end):
        for i in range(corner_steps + 1):
            a = start + (end - start) * i / corner_steps
            pts.append((ax + r * math.cos(a), ay + r * math.sin(a)))

    arc(x1 - r, y0 + r, -math.pi / 2, 0)
    arc(x1 - r, y1 - r, 0, math.pi / 2)
    arc(x0 + r, y1 - r, math.pi / 2, math.pi)
    arc(x0 + r, y0 + r, math.pi, 3 * math.pi / 2)
    return pts


def dome(cx, base_y, radius, steps=90):
    """A half-circle sitting on a flat base — the shape of the light itself."""
    pts = [(cx - radius, base_y)]
    for i in range(steps + 1):
        a = math.pi + math.pi * i / steps
        pts.append((cx + radius * math.cos(a), base_y + radius * math.sin(a)))
    pts.append((cx + radius, base_y))
    return pts


def ray(cx, cy, inner, outer, half_width, angle):
    """A tapered bar from `inner` to `outer` along `angle` (radians from straight up)."""
    dx, dy = math.sin(angle), -math.cos(angle)
    px, py = math.cos(angle), math.sin(angle)
    return [
        (cx + dx * inner + px * half_width, cy + dy * inner + py * half_width),
        (cx + dx * outer + px * half_width * 0.55, cy + dy * outer + py * half_width * 0.55),
        (cx + dx * outer - px * half_width * 0.55, cy + dy * outer - py * half_width * 0.55),
        (cx + dx * inner - px * half_width, cy + dy * inner - py * half_width),
    ]


# --- the two candidates ---------------------------------------------------------------

def beacon(background, light, glow, housing=HOUSING):
    """A beacon on its housing, throwing light. The siren, as a shape."""
    c = Canvas(SIZE * SUPERSAMPLE, SIZE * SUPERSAMPLE)
    c.vertical_gradient(*background)
    s = SIZE * SUPERSAMPLE
    cx = s / 2

    base_y = s * 0.700
    c.fill_polygon(rrect(cx, s * 0.790, s * 0.560, s * 0.180, s * 0.070), housing)
    c.fill_polygon(dome(cx, base_y, s * 0.185), light)
    # Short, thick, few. Thin rays are the first thing to vanish at 29pt, so these are the
    # light's flourish rather than the thing that carries the meaning — the dome carries it.
    for angle in (-0.62, 0.0, 0.62):
        c.fill_polygon(
            ray(cx, base_y - s * 0.055, s * 0.245, s * 0.375, s * 0.052, angle),
            glow,
        )
    return c.downsample(SUPERSAMPLE)


def lightbar(background, left_light, right_light, middle, housing=HOUSING):
    """The bar itself, three lenses. Red, white, red — what a fire truck actually shows."""
    c = Canvas(SIZE * SUPERSAMPLE, SIZE * SUPERSAMPLE)
    c.vertical_gradient(*background)
    s = SIZE * SUPERSAMPLE
    cx, cy = s / 2, s * 0.500

    c.fill_polygon(rrect(cx, cy, s * 0.720, s * 0.300, s * 0.110), housing)
    for offset, colour in ((-0.222, left_light), (0.0, middle), (0.222, right_light)):
        c.fill_polygon(
            rrect(cx + s * offset, cy, s * 0.180, s * 0.208, s * 0.060),
            colour,
        )
    return c.downsample(SUPERSAMPLE)


# Light is the icon people see. Dark goes further down rather than up, so it sits on a dark
# Home Screen instead of glowing off it.
# Light enough that the housing reads as a bar rather than as nothing. At the first value the
# bar and the ground measured 1.6:1 — present in the geometry, invisible in the picture.
LIGHT_GROUND = ((146, 32, 28, 255), (52, 10, 12, 255))
DARK_GROUND = ((120, 26, 24, 255), (36, 8, 9, 255))
# Tinted is greyscale: the system maps luminance onto whatever tint the reader chose, so the
# lights have to be the brightest thing in the frame. Supply them red and the tint eats them.
TINTED_GROUND = ((8, 8, 10, 255), (0, 0, 0, 255))
# And its housing is *lighter* than its ground, the opposite of the other two. A dark bar on a
# dark ground is nothing: that appearance measured 1.2:1, so the bar was in the geometry and
# invisible in the picture. In tinted the lenses are the brightest things in the frame either
# way, so the bar can sit above the ground instead of below it.
TINTED_HOUSING = (76, 76, 80, 255)

CANDIDATES = {
    "beacon": lambda ground, tinted, housing: beacon(
        ground,
        (255, 255, 255, 255) if tinted else RED,
        (168, 168, 172, 255) if tinted else RAY,
        housing,
    ),
    "lightbar": lambda ground, tinted, housing: lightbar(
        ground,
        (255, 255, 255, 255) if tinted else RED,
        (255, 255, 255, 255) if tinted else RED,
        (150, 150, 154, 255) if tinted else WHITE,
        housing,
    ),
}

APPEARANCES = (
    ("light", LIGHT_GROUND, HOUSING),
    ("dark", DARK_GROUND, HOUSING),
    ("tinted", TINTED_GROUND, TINTED_HOUSING),
)


def render(candidate, appearance_name, ground, housing):
    return CANDIDATES[candidate](ground, appearance_name == "tinted", housing)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate", choices=sorted(CANDIDATES), default="beacon")
    parser.add_argument("--compare", action="store_true")
    parser.add_argument("--out", type=pathlib.Path, default=OUT)
    args = parser.parse_args()

    if args.compare:
        destination = pathlib.Path("/tmp/icon-preview")
        for candidate in CANDIDATES:
            for name, ground, housing in APPEARANCES:
                render(candidate, name, ground, housing).write(destination / f"{candidate}-{name}.png")
        print(f"  wrote both candidates to {destination}")
        return 0

    for name, ground, housing in APPEARANCES:
        path = args.out / f"icon-{name}.png"
        render(args.candidate, name, ground, housing).write(path)
        print(f"  {path}  {path.stat().st_size // 1024} KB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
