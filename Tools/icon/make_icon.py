"""Draws the Logan Quests app icon: LOGAN in cream over QUESTS in gold, on navy.

    python3 Tools/icon/make_icon.py LoganQuest/Assets.xcassets/AppIcon.appiconset/AppIcon.png
    sips -z 512 512 LoganQuest/Assets.xcassets/AppIcon.appiconset/AppIcon.png \\
        --out LoganQuest/Assets.xcassets/Logo.imageset/Logo.png

Needs Pillow (pip3 install pillow) and macOS for the SF Rounded font. Everything is drawn at
4x and scaled down for smooth edges. Coordinates are on the final 1024 x 1024 canvas.
"""
import sys

from PIL import Image, ImageDraw, ImageFont

SS = 4
N = 1024
W = N * SS
FONT = "/System/Library/Fonts/SFNSRounded.ttf"
WEIGHT = "Black"

NAVY_TOP, NAVY_BOTTOM = (22, 56, 88), (8, 26, 44)
LINES = [("LOGAN", (251, 243, 226)), ("QUESTS", (247, 189, 52))]
WIDTH = 830     # the wider line fills this width; both lines use the same size
TRACK = 6       # extra space between letters
GAP = 70        # space between the two lines' capitals


def S(v):
    return int(round(v * SS))


def gradient(top, bottom):
    img = Image.new("RGB", (W, W))
    d = ImageDraw.Draw(img)
    for y in range(W):
        t = y / (W - 1)
        d.line([(0, y), (W, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)))
    return img


def font(size):
    f = ImageFont.truetype(FONT, S(size))
    f.set_variation_by_name(WEIGHT)
    return f


def line_width(f, text):
    return sum(f.getlength(c) for c in text) + S(TRACK) * (len(text) - 1)


def fitted_size(text):
    size = 400
    while line_width(font(size), text) > S(WIDTH):
        size -= 1
    return size


def draw_icon():
    img = gradient(NAVY_TOP, NAVY_BOTTOM)
    f = font(min(fitted_size(text) for text, _ in LINES))
    bb = f.getbbox("H")
    cap = (bb[3] - bb[1]) / SS
    top = N / 2 - (cap * len(LINES) + GAP * (len(LINES) - 1)) / 2
    d = ImageDraw.Draw(img)
    for text, color in LINES:
        x = S(N / 2) - line_width(f, text) / 2
        for c in text:
            d.text((x, S(top) - bb[1]), c, font=f, fill=color)
            x += f.getlength(c) + S(TRACK)
        top += cap + GAP
    return img.resize((N, N), Image.LANCZOS)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: make_icon.py OUTPUT.png")
    draw_icon().save(sys.argv[1])
