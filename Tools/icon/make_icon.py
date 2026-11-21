"""Draws the Logan Quests app icon: LOGAN QUESTS in navy on gold, one word per line, each
line stretched to the same width.

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

GOLD_TOP, GOLD_BOTTOM = (255, 210, 96), (232, 146, 28)
NAVY = (17, 44, 70)
LINES = ["LOGAN", "QUESTS"]
WIDTH = 820     # each line is sized to fill this width
TRACK = 6       # extra space between letters
GAP = 66        # space between the two lines' capitals


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


def fitted_font(text):
    size = 400
    while line_width(font(size), text) > S(WIDTH):
        size -= 1
    return font(size)


def draw_icon():
    img = gradient(GOLD_TOP, GOLD_BOTTOM)
    d = ImageDraw.Draw(img)
    fonts = [fitted_font(text) for text in LINES]
    caps = [f.getbbox("H")[3] - f.getbbox("H")[1] for f in fonts]
    top = S(N / 2) - (sum(caps) + S(GAP) * (len(LINES) - 1)) / 2
    for text, f, cap in zip(LINES, fonts, caps):
        x = S(N / 2) - line_width(f, text) / 2
        for c in text:
            d.text((x, top - f.getbbox("H")[1]), c, font=f, fill=NAVY)
            x += f.getlength(c) + S(TRACK)
        top += cap + S(GAP)
    return img.resize((N, N), Image.LANCZOS)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: make_icon.py OUTPUT.png")
    draw_icon().save(sys.argv[1])
