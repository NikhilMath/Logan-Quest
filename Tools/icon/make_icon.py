"""Draws the Logan Quests app icon: a gold trail badge with LOGAN QUESTS around the top,
three stars along the bottom, and Old Main's tower at dusk over the Cache Valley mountains.

    python3 Tools/icon/make_icon.py LoganQuest/Assets.xcassets/AppIcon.appiconset/AppIcon.png
    sips -z 512 512 LoganQuest/Assets.xcassets/AppIcon.appiconset/AppIcon.png \
        --out LoganQuest/Assets.xcassets/Logo.imageset/Logo.png

Needs Pillow (pip3 install pillow) and macOS for the SF Rounded font. Everything is drawn at
4x and scaled down for smooth edges. Coordinates are on the final 1024 x 1024 canvas.
"""
import math, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

SS = 4
N = 1024
W = N * SS
def S(v): return int(round(v * SS))
def P(pts): return [(S(x), S(y)) for x, y in pts]

def lerp(c0, c1, k): return tuple(round(a + (b - a) * k) for a, b in zip(c0, c1))

def vgrad(w, h, stops):
    img = Image.new("RGB", (w, h)); d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / (h - 1)
        for (t0, c0), (t1, c1) in zip(stops, stops[1:]):
            if t <= t1:
                k = 0 if t1 == t0 else max(0, (t - t0) / (t1 - t0)); break
        else:
            (t0, c0), (t1, c1) = stops[-2], stops[-1]; k = 1
        d.line([(0, y), (w, y)], fill=lerp(c0, c1, k))
    return img

def glow(img, box, color, strength=150, blur=80):
    m = Image.new("L", img.size, 0)
    ImageDraw.Draw(m).ellipse([S(v) for v in box], fill=strength)
    m = m.filter(ImageFilter.GaussianBlur(S(blur)))
    img.paste(color, mask=m)

def shadow(img, draw_fn, offset=(0, 18), blur=22, alpha=110, color=(0, 0, 0)):
    m = Image.new("L", img.size, 0)
    draw_fn(ImageDraw.Draw(m), offset, alpha)
    m = m.filter(ImageFilter.GaussianBlur(S(blur)))
    img.paste(color, mask=m)

def star(d, cx, cy, r, fill, points=5, inner=0.45, rot=-90):
    pts = []
    for i in range(points * 2):
        rr = r if i % 2 == 0 else r * inner
        a = math.radians(rot + i * 180 / points)
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    d.polygon(P(pts), fill=fill)

def tower(d, cx, yS, u, base, body, shade, hole, finial=None):
    """Stylized Old Main tower. yS = top of the shaft; u = half the shaft width."""
    # shaft (right side shaded for depth)
    d.rectangle(P([(cx - u, yS), (cx + u, base)]), fill=body)
    d.rectangle(P([(cx + 0.35 * u, yS), (cx + u, base)]), fill=shade)
    # roof with shaded right face
    ry = yS - 0.2 * u
    apex = (cx, ry - 2.35 * u)
    d.polygon(P([(cx - 1.18 * u, ry), (cx + 1.18 * u, ry), apex]), fill=body)
    d.polygon(P([apex, (cx + 1.18 * u, ry), (cx, ry)]), fill=shade)
    # corner pinnacles
    for x, col in ((cx - 1.08 * u, body), (cx + 1.08 * u, shade)):
        d.polygon(P([(x - 0.17 * u, ry + 0.02 * u), (x + 0.17 * u, ry + 0.02 * u), (x, ry - 0.95 * u)]), fill=col)
    # cornice
    d.rectangle(P([(cx - 1.2 * u, ry), (cx + 1.2 * u, yS + 0.08 * u)]), fill=body)
    d.rectangle(P([(cx + 0.35 * u, ry), (cx + 1.2 * u, yS + 0.08 * u)]), fill=shade)
    # belfry arches
    for x in (cx - 0.42 * u, cx + 0.42 * u):
        aw = 0.17 * u
        d.rounded_rectangle(P([(x - aw, yS + 0.35 * u), (x + aw, yS + 1.6 * u)]), radius=S(aw), fill=hole)
    # band
    d.rectangle(P([(cx - 1.1 * u, yS + 1.9 * u), (cx + 1.1 * u, yS + 2.08 * u)]), fill=body)
    d.rectangle(P([(cx + 0.35 * u, yS + 1.9 * u), (cx + 1.1 * u, yS + 2.08 * u)]), fill=shade)
    # lower window
    d.rounded_rectangle(P([(cx - 0.2 * u, yS + 2.45 * u), (cx + 0.2 * u, yS + 3.5 * u)]), radius=S(0.2 * u), fill=hole)
    # finial
    d.line(P([apex, (cx, apex[1] - 0.45 * u)]), fill=body, width=S(0.09 * u))
    return (cx, apex[1] - 0.45 * u)

CREAM, CREAM_SHADE = (251, 243, 226), (226, 212, 186)
GOLD = (247, 189, 52)


def draw_icon():
    img = vgrad(W, W, [(0, (17, 48, 74)), (1, (8, 26, 44))])
    cx = cy = 512; R, r = 452, 350
    shadow(img, lambda dd, off, a: dd.ellipse(P([(cx - R + off[0], cy - R + off[1]), (cx + R + off[0], cy + R + off[1])]), fill=a), offset=(0, 18), blur=24, alpha=150, color=(0, 10, 20))
    m = Image.new("L", img.size, 0); ImageDraw.Draw(m).ellipse(P([(cx - R, cy - R), (cx + R, cy + R)]), fill=255)
    img.paste(vgrad(W, W, [(0, (255, 208, 92)), (1, (228, 146, 30))]), mask=m)
    d = ImageDraw.Draw(img)
    navy = (17, 44, 70)
    d.ellipse(P([(cx - R + 18, cy - R + 18), (cx + R - 18, cy + R - 18)]), outline=navy, width=S(7))
    # inner scene
    scene = vgrad(W, W, [(0, (14, 36, 66)), (0.55, (32, 104, 118)), (1, (32, 104, 118))])
    glow(scene, (cx - 170, cy - 380, cx + 170, cy - 60), (255, 205, 120), strength=130, blur=60)
    sd = ImageDraw.Draw(scene)
    sd.polygon(P([(cx - r, cy + 130), (cx - 200, cy + 30), (cx - 90, cy + 100), (cx + 60, cy - 10), (cx + 200, cy + 80), (cx + r, cy + 20), (cx + r, cy + r), (cx - r, cy + r)]), fill=(20, 64, 76))
    sd.polygon(P([(cx - r, cy + 230), (cx - 160, cy + 150), (cx + 10, cy + 210), (cx + 170, cy + 140), (cx + r, cy + 200), (cx + r, cy + r), (cx - r, cy + r)]), fill=(11, 40, 52))
    tip = tower(sd, cx, cy - 8, 76, cy + 500, CREAM, CREAM_SHADE, (16, 40, 66))
    star(sd, tip[0], tip[1] - 30, 38, GOLD)
    im = Image.new("L", img.size, 0); ImageDraw.Draw(im).ellipse(P([(cx - r, cy - r), (cx + r, cy + r)]), fill=255)
    img.paste(scene, mask=im)
    d = ImageDraw.Draw(img)
    d.ellipse(P([(cx - r, cy - r), (cx + r, cy + r)]), outline=navy, width=S(9))
    # LOGAN QUESTS around the top of the ring
    font = ImageFont.truetype("/System/Library/Fonts/SFNSRounded.ttf", S(70))
    try: font.set_variation_by_name("Heavy")
    except Exception: pass
    text, radius, track = "LOGAN QUESTS", 401, S(6)
    widths = [font.getlength(ch) + track for ch in text]
    total = sum(widths) - track
    theta = -math.pi / 2 - (total / S(radius)) / 2
    for ch, w in zip(text, widths):
        a = theta + (w / 2) / S(radius)
        if ch != " ":
            tile = Image.new("L", (S(120), S(120)), 0)
            td = ImageDraw.Draw(tile)
            bb = td.textbbox((0, 0), ch, font=font)
            td.text((tile.width / 2 - (bb[0] + bb[2]) / 2, tile.height / 2 - (bb[1] + bb[3]) / 2), ch, font=font, fill=255)
            tile = tile.rotate(-math.degrees(a + math.pi / 2), resample=Image.BICUBIC)
            x = S(cx) + S(radius) * math.cos(a) - tile.width / 2
            y = S(cy) + S(radius) * math.sin(a) - tile.height / 2
            img.paste(navy, (int(x), int(y)), tile)
        theta += w / S(radius)
    # three stars along the bottom of the ring
    for deg in (70, 90, 110):
        a = math.radians(deg)
        star(d, cx + 401 * math.cos(a), cy + 401 * math.sin(a), 22 if deg == 90 else 16, navy)
    return img.resize((N, N), Image.LANCZOS)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: make_icon.py OUTPUT.png")
    draw_icon().convert("RGB").save(sys.argv[1])
