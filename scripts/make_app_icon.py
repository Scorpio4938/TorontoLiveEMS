#!/usr/bin/env python3
"""Draws the app icon and writes its appearance variants.

Generated rather than drawn in an editor because there is no editor here and the mark is one
shape. It is reproducible, and a change to the geometry is a change to a number rather than a
re-export from a tool nobody else has.

The mark is a flame. An earlier version was a small table with one cell marked — the product
and its colour rule in one figure — and it was rejected for having too many parts and for not
saying *fire* at a glance. That was the right call: this is Toronto Fire Services' feed, the
flame is what the service itself uses, and an icon that is statistically representative of the
incident mix is optimising the wrong thing. Nobody reads an icon for a census.

Two tones rather than one, because a flame is two tones: a bright core inside a warmer body.
That is also what Liquid Glass wants — separate layers it can refract between, which is what
Icon Composer builds from if this ever moves to it.

Apple's guidance for what we supply: flat, opaque, square. No transparency, no rounded
corners, no shadow, no attempt at glass. The platform applies the mask, the shadow and the
Liquid Glass treatment. Drawing any of those ourselves fights the system and looks wrong the
moment the system changes its approach.

Usage:
    python3 scripts/make_app_icon.py             # write the three appearance files
    python3 scripts/make_app_icon.py --preview   # ...and a copy to look at
"""

import argparse
import math
import pathlib
import struct
import zlib

SIZE = 1024
SUPERSAMPLE = 2

# The flame. Warm rather than Apple's systemRed, which is built for text and controls on a
# light background and reads as an error state at this size.
OUTER = (255, 106, 32, 255)
INNER = (255, 205, 92, 255)

OUT = pathlib.Path("TorontoLiveEMS/Assets.xcassets/AppIcon.appiconset")


class Canvas:
    """An RGBA pixel buffer with just enough drawing for one geometric mark."""

    def __init__(self, width, height):
        self.w = width
        self.h = height
        self.px = bytearray(width * height * 4)

    def set(self, x, y, colour):
        if 0 <= x < self.w and 0 <= y < self.h:
            i = (y * self.w + x) * 4
            self.px[i:i + 4] = bytes(colour)

    def vertical_gradient(self, top, bottom):
        for y in range(self.h):
            t = y / max(1, self.h - 1)
            colour = bytes(round(top[c] + (bottom[c] - top[c]) * t) for c in range(4))
            i = y * self.w * 4
            self.px[i:i + self.w * 4] = colour * self.w

    def fill_polygon(self, points, colour):
        """Even-odd scanline fill.

        Scanline rather than testing every pixel in the bounding box: the mark is drawn at
        twice the output size, so a bounding-box test is a few hundred million point-in-polygon
        checks and this is a few hundred thousand.
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
                start = max(0, int(crossings[i]))
                end = min(self.w, int(crossings[i + 1]) + 1)
                for x in range(start, end):
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


def bezier(p0, p1, p2, p3, steps):
    points = []
    for i in range(steps + 1):
        t = i / steps
        m = 1 - t
        points.append((
            m ** 3 * p0[0] + 3 * m * m * t * p1[0] + 3 * m * t * t * p2[0] + t ** 3 * p3[0],
            m ** 3 * p0[1] + 3 * m * m * t * p1[1] + 3 * m * t * t * p2[1] + t ** 3 * p3[1],
        ))
    return points


# The flame, in its own coordinates: y = 0 at the base, y = 1 at the tip, x symmetric about 0.
BASE_CENTRE_Y = 0.20
BASE_RADIUS = 0.20
# The side bulges out below the middle and draws back in to the tip. That waist is what makes
# it a flame rather than a teardrop.
BULGE_X, WAIST_X = 0.345, 0.205


def flame_outline(steps=180):
    """The closed outline of the flame, as a polygon.

    Symmetric. A leaning tip is more lifelike and unreadable at 29pt, where the whole mark is
    20 points tall and any asymmetry just looks like a rendering fault.
    """
    up = bezier(
        (BASE_RADIUS, BASE_CENTRE_Y),
        (BULGE_X, 0.46),
        (WAIST_X, 0.72),
        (0.0, 1.0),
        steps,
    )
    down = [(-x, y) for (x, y) in reversed(up)]
    # The base, from the left side round the bottom to the right, so the outline closes.
    arc = [
        (
            BASE_RADIUS * math.cos(a),
            BASE_CENTRE_Y + BASE_RADIUS * math.sin(a),
        )
        for a in (math.pi + math.pi * i / 90 for i in range(91))
    ]
    return up + down + arc


def draw(background, outer, inner):
    """One appearance: the flame on its background, at twice size, then halved."""
    c = Canvas(SIZE * SUPERSAMPLE, SIZE * SUPERSAMPLE)
    c.vertical_gradient(*background)

    height = SIZE * SUPERSAMPLE * 0.70
    base_y = SIZE * SUPERSAMPLE * 0.855
    centre_x = SIZE * SUPERSAMPLE / 2

    def place(points, scale, lift):
        return [
            (centre_x + x * height * scale, base_y - (y * scale + lift) * height)
            for (x, y) in points
        ]

    outline = flame_outline()
    c.fill_polygon(place(outline, 1.0, 0.0), outer)
    # The core: the same flame, smaller, sitting low inside the body the way a real one does.
    c.fill_polygon(place(outline, 0.52, 0.055), inner)

    return c.downsample(SUPERSAMPLE)


# Light is the icon people see: the whole frame red, the flame warm inside it.
LIGHT = (((150, 26, 22, 255), (74, 11, 14, 255)), OUTER, INNER)
# Dark goes further down rather than up, so it sits with a dark Home Screen instead of glowing
# off it.
DARK = (((92, 16, 16, 255), (34, 6, 8, 255)), OUTER, INNER)
# Tinted is greyscale and inverted in emphasis: the system maps luminance onto whatever tint
# the reader chose, so the flame has to be the brightest thing in the frame. Supply it orange
# and the tint eats it.
TINTED = (((26, 26, 28, 255), (12, 12, 14, 255)), (255, 255, 255, 255), (168, 168, 172, 255))

APPEARANCES = (("light", LIGHT), ("dark", DARK), ("tinted", TINTED))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--preview", action="store_true")
    parser.add_argument("--out", type=pathlib.Path, default=OUT)
    args = parser.parse_args()

    if args.preview:
        destination = pathlib.Path("/tmp/icon-preview")
        for name, appearance in APPEARANCES:
            draw(*appearance).write(destination / f"flame-{name}.png")
        print(f"  wrote a copy to {destination}")
        return 0

    for name, appearance in APPEARANCES:
        path = args.out / f"icon-{name}.png"
        draw(*appearance).write(path)
        print(f"  {path}  {path.stat().st_size // 1024} KB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
