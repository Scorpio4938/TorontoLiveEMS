#!/usr/bin/env python3
"""Draws the app icon and writes its appearance variants.

Generated rather than drawn in an editor because there is no editor here and the mark
is geometric. It is reproducible, and a change to the geometry is a change to a number
rather than a re-export from a tool nobody else has.

The mark is a small table with one cell marked, which is the product and its one colour
rule: five columns of incidents, and colour for the exception. It is not a flame, because
most of what the feed carries is not a fire, and not a map pin, because every incident app
has one.

Apple's own guidance for what we supply: a flat, opaque, square image. No transparency, no
rounded corners, no drop shadow — the platform applies the mask, the shadow, and the Liquid
Glass treatment over the top. Drawing any of those ourselves fights the system and looks
wrong the moment the system changes its mind.

Usage:
    python3 scripts/make_app_icon.py            # write the three variants
    python3 scripts/make_app_icon.py --preview  # ...and a contact sheet to look at
"""

import argparse
import pathlib
import struct
import zlib

SIZE = 1024
SUPERSAMPLE = 2

# Apple's own values, so the icon and the app agree about what orange means.
SYSTEM_ORANGE = (255, 149, 0, 255)
INK = (236, 240, 248, 255)
# Dimmer than it looks like it needs to be. Against systemOrange the first value measured
# 1.4:1 — the exception was carried by hue alone, which is nothing to a reader who cannot
# separate those two hues. This is about 2.6:1, so it is brighter *and* more orange, and
# still 3.4:1 against the background.
MUTED = (96, 104, 120, 255)

OUT = pathlib.Path("TorontoLiveEMS/Assets.xcassets/AppIcon.appiconset")


class Canvas:
    """An RGBA pixel buffer with just enough drawing for a geometric mark."""

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
            colour = tuple(
                round(top[c] + (bottom[c] - top[c]) * t) for c in range(4)
            )
            row = bytes(colour) * self.w
            i = y * self.w * 4
            self.px[i:i + self.w * 4] = row

    def rounded_rect(self, x, y, w, h, radius, colour):
        """Hard-edged. The supersample pass below is what smooths it."""
        if w <= 0 or h <= 0:
            return
        x0, y0 = int(x), int(y)
        x1, y1 = int(x + w), int(y + h)
        r = min(radius, w / 2, h / 2)
        for py in range(max(0, y0), min(self.h, y1 + 1)):
            for px in range(max(0, x0), min(self.w, x1 + 1)):
                # Distance to the rect the corner circles are centred on.
                cx = min(max(px, x0 + r), x1 - r)
                cy = min(max(py, y0 + r), y1 - r)
                if (px - cx) ** 2 + (py - cy) ** 2 <= r * r:
                    self.set(px, py, colour)

    def downsample(self, factor):
        out = Canvas(self.w // factor, self.h // factor)
        n = factor * factor
        for y in range(out.h):
            for x in range(out.w):
                r = g = b = a = 0
                for dy in range(factor):
                    for dx in range(factor):
                        i = ((y * factor + dy) * self.w + (x * factor + dx)) * 4
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


def draw(columns, rows, cell_colour, accent, background):
    """The mark: `columns` x `rows` cells, all but one in `cell_colour`."""
    c = Canvas(SIZE * SUPERSAMPLE, SIZE * SUPERSAMPLE)
    c.vertical_gradient(background[0], background[1])

    s = SUPERSAMPLE
    # The mark occupies most of the square but not all of it. App icons are masked by the
    # system, so artwork runs edge to edge; the *content* keeps a margin the way Apple's own
    # icons do, or it reads as cramped once the corners come off.
    # Wider than tall, so the cells come out square or wider. A square grid makes tall thin
    # cells, which read as a bar chart rather than as a table.
    margin_x = int(SIZE * s * 0.080)
    margin_y = int(SIZE * s * 0.240)
    grid_w = SIZE * s - margin_x * 2
    grid_h = SIZE * s - margin_y * 2

    gap = int(SIZE * s * 0.030)
    cell_w = (grid_w - gap * (columns - 1)) / columns
    cell_h = (grid_h - gap * (rows - 1)) / rows
    radius = min(cell_w, cell_h) * 0.30

    # The exception: the second row, second from the right. Not the corner, because a mark
    # in the corner reads as a badge rather than as one row among many.
    marked = (rows - 2, columns - 2)

    for row in range(rows):
        for col in range(columns):
            colour = accent if (row, col) == marked else cell_colour
            c.rounded_rect(
                margin_x + col * (cell_w + gap),
                margin_y + row * (cell_h + gap),
                cell_w,
                cell_h,
                radius,
                colour,
            )

    return c.downsample(s)


LIGHT = (((14, 17, 26, 255), (30, 36, 52, 255)), MUTED)
DARK = (((6, 7, 11, 255), (16, 19, 28, 255)), (120, 130, 148, 255))
# Tinted is greyscale: the system maps luminance onto whatever tint the reader chose, so
# the exception has to be the brightest thing in the frame rather than the most orange.
TINTED = (((18, 18, 20, 255), (30, 30, 34, 255)), (200, 200, 205, 255))

# Both have three rows. Four was drawn and dropped: at 29pt — Settings, Spotlight — its
# cells come out under 3pt tall, which is not a cell, it is a smudge.
VARIANTS = {
    # Five columns, because the table has five.
    "five": (5, 3),
    # Three, because an icon is not a place to be accurate at the expense of being legible.
    "three": (3, 3),
}


def render(columns, rows, appearance):
    (background, cell_colour) = appearance
    accent = SYSTEM_ORANGE if appearance is not TINTED else (255, 255, 255, 255)
    return draw(columns, rows, cell_colour, accent, background)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--variant", choices=sorted(VARIANTS), default="five")
    parser.add_argument("--preview", action="store_true")
    parser.add_argument("--out", type=pathlib.Path, default=OUT)
    args = parser.parse_args()

    columns, rows = VARIANTS[args.variant]

    if args.preview:
        destination = pathlib.Path("/tmp/icon-preview")
        for name, (c, r) in VARIANTS.items():
            render(c, r, LIGHT).write(destination / f"{name}.png")
        for name, appearance in (("light", LIGHT), ("dark", DARK), ("tinted", TINTED)):
            render(columns, rows, appearance).write(destination / f"{args.variant}-{name}.png")
        print(f"  wrote a contact sheet to {destination}")
        return 0

    for name, appearance in (("light", LIGHT), ("dark", DARK), ("tinted", TINTED)):
        path = args.out / f"icon-{name}.png"
        render(columns, rows, appearance).write(path)
        print(f"  {path}  {path.stat().st_size // 1024} KB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
