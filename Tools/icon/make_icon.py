"""Draws the Logan Quests app icon: L and Q drawn as one road, on red-rock orange. The L's road
comes down from the top, turns the corner and runs into the Q, a roundabout with a gold flag on
its island; the Q's tail is a road leaving through the ring.

    python3 Tools/icon/make_icon.py LoganQuest/Assets.xcassets/AppIcon.appiconset/AppIcon.png
    sips -z 512 512 LoganQuest/Assets.xcassets/AppIcon.appiconset/AppIcon.png \\
        --out LoganQuest/Assets.xcassets/Logo.imageset/Logo.png

Needs Pillow (pip3 install pillow). Everything is drawn at 4x and scaled down for smooth edges.
Coordinates are on the final 1024 x 1024 canvas.
"""
import math
import sys

from PIL import Image, ImageDraw, ImageFilter

SS = 4
N = 1024
W = N * SS

ROCK_TOP, ROCK_BOTTOM = (240, 120, 68), (190, 62, 44)  # red rock
ROAD = (38, 42, 58)
ROAD_WIDTH = 140
LINE = (255, 206, 72)        # the dashed center lines, and the flag
POLE = (251, 243, 226)       # cream
SHADOW = (60, 10, 10)

Q_X, Q_Y, Q_R = 626, 600, 205  # the roundabout's center and the radius of its center line
JOIN = 150                     # where the L's road meets the ring, in degrees (0 is right, 90 down)
L_X, L_TURN_R = 190, 130       # the L's upright, and the radius of its corner
TAIL_ANGLE, TAIL_IN, TAIL_OUT = 40, 0.5, 110  # tail starts at half the radius, ends 110 outside
DASH, GAP, LINE_WIDTH = 50, 36, 17
FLAG_SIZE = 0.9


def S(v):
    return v * SS


def P(points):
    return [(S(x), S(y)) for x, y in points]


def gradient(top, bottom):
    img = Image.new("RGB", (W, W))
    d = ImageDraw.Draw(img)
    for y in range(W):
        t = y / (W - 1)
        d.line([(0, y), (W, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)))
    return img


def arc(cx, cy, r, a0, a1, steps):
    return [(cx + r * math.cos(math.radians(a0 + (a1 - a0) * i / steps)),
             cy + r * math.sin(math.radians(a0 + (a1 - a0) * i / steps))) for i in range(steps + 1)]


def road_paths():
    ring = arc(Q_X, Q_Y, Q_R, -90, 270, 160)
    join_x = Q_X + Q_R * math.cos(math.radians(JOIN))
    join_y = Q_Y + Q_R * math.sin(math.radians(JOIN))
    turn_y = join_y - L_TURN_R
    letter_l = [(L_X, -120), (L_X, turn_y)] + arc(L_X + L_TURN_R, turn_y, L_TURN_R, 180, 90, 30)[1:] + [(join_x, join_y)]
    a = math.radians(TAIL_ANGLE)
    tail = [(Q_X + TAIL_IN * Q_R * math.cos(a), Q_Y + TAIL_IN * Q_R * math.sin(a)),
            (Q_X + (Q_R + TAIL_OUT) * math.cos(a), Q_Y + (Q_R + TAIL_OUT) * math.sin(a))]
    return [letter_l, ring, tail]


def stroke(d, path, width, color, step=3):
    """A smooth thick line with round ends: discs stamped closely along the path."""
    r = width / 2
    for a, b in zip(path, path[1:]):
        n = max(1, int(math.dist(a, b) / step))
        for i in range(n + 1):
            x, y = a[0] + (b[0] - a[0]) * i / n, a[1] + (b[1] - a[1]) * i / n
            d.ellipse([S(x - r), S(y - r), S(x + r), S(y + r)], fill=color)


def dashes(d, path, dash, gap, width, color):
    segs = list(zip(path, path[1:]))
    total = sum(math.dist(a, b) for a, b in segs)

    def at(dist):
        walked = 0
        for a, b in segs:
            seg = math.dist(a, b)
            if walked + seg >= dist:
                t = (dist - walked) / seg if seg else 0
                return a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
            walked += seg
        return path[-1]

    pos = gap / 2
    while pos < total:
        end = min(total, pos + dash)
        d.line(P([at(pos + (end - pos) * i / 8) for i in range(9)]), fill=color, width=S(width), joint="curve")
        pos = end + gap


def flag(d, x, bottom, top, size):
    d.line(P([(x, bottom), (x, top)]), fill=POLE, width=round(S(18 * size)))
    d.polygon(P([(x + 6, top), (x + 6 + 120 * size, top + 42 * size), (x + 6, top + 84 * size)]), fill=LINE)
    r = 19 * size
    d.ellipse([S(x - r), S(top - r), S(x + r), S(top + r)], fill=POLE)


def draw_icon():
    img = gradient(ROCK_TOP, ROCK_BOTTOM)
    paths = road_paths()

    shadow = Image.new("L", (W, W), 0)
    sd = ImageDraw.Draw(shadow)
    for p in paths:
        stroke(sd, [(x, y + 18) for x, y in p], ROAD_WIDTH, 110)
    img.paste(SHADOW, (0, 0), shadow.filter(ImageFilter.GaussianBlur(S(22))))

    d = ImageDraw.Draw(img)
    for p in paths:
        stroke(d, p, ROAD_WIDTH, ROAD)
    for p in paths:
        dashes(d, p, DASH, GAP, LINE_WIDTH, LINE)
    flag(d, Q_X - 30, Q_Y + 56, Q_Y - 90, FLAG_SIZE)
    return img.resize((N, N), Image.LANCZOS)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: make_icon.py OUTPUT.png")
    draw_icon().save(sys.argv[1])
