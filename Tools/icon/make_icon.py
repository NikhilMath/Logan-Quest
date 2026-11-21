import sys, math
# Draws the app icon (stylized Old Main tower over the Cache Valley mountains).
#   python3 Tools/icon/make_icon.py LoganQuest/Assets.xcassets/AppIcon.appiconset/AppIcon.png
# Needs Pillow (pip install pillow).
from PIL import Image, ImageDraw, ImageFont, ImageFilter
N = 1024
SS = 2  # draw at 2x and downsample for smooth edges
W = N * SS
def s(v): return v * SS
out = sys.argv[1]

img = Image.new("RGB", (W, W))
d = ImageDraw.Draw(img)
# Dusk sky: deep blue-green at the top fading to teal, warm near the horizon
stops = [(0.0, (14, 46, 74)), (0.40, (26, 100, 104)), (0.60, (226, 168, 84)), (1.0, (226, 168, 84))]
for y in range(W):
    t = y / (W - 1)
    for (t0, c0), (t1, c1) in zip(stops, stops[1:]):
        if t <= t1 or (t1, c1) == stops[-1]:
            k = min(max((t - t0) / (t1 - t0), 0), 1)
            col = tuple(round(a + (b - a) * k) for a, b in zip(c0, c1))
            break
    d.line([(0, y), (W, y)], fill=col)

# Soft glow behind the tower top
glow = Image.new("L", (W, W), 0)
ImageDraw.Draw(glow).ellipse([s(300), s(120), s(724), s(544)], fill=120)
glow = glow.filter(ImageFilter.GaussianBlur(s(60)))
img.paste((255, 214, 130), mask=glow)
d = ImageDraw.Draw(img)

# Mountains (Cache Valley's ridgelines)
far = [(0, 700), (120, 610), (230, 650), (360, 560), (470, 620), (600, 540), (720, 600), (830, 560), (1024, 640), (1024, 1024), (0, 1024)]
near = [(0, 790), (150, 700), (290, 760), (420, 690), (560, 770), (700, 700), (860, 760), (1024, 700), (1024, 1024), (0, 1024)]
d.polygon([(s(x), s(y)) for x, y in far], fill=(30, 84, 86))
d.polygon([(s(x), s(y)) for x, y in near], fill=(20, 62, 62))

cream = (248, 241, 226)
shade = (222, 210, 186)
dark = (24, 66, 70)

# Building wings
d.rectangle([s(170), s(780), s(854), s(940)], fill=cream)
d.polygon([(s(160), s(785)), (s(864), s(785)), (s(830), s(755)), (s(194), s(755))], fill=shade)  # roof edge
for x in [200, 254, 308, 362] + [636, 690, 744, 798]:
    d.rounded_rectangle([s(x), s(815), s(x + 26), s(870)], radius=s(12), fill=dark)

# Tower shaft
tx0, tx1 = 418, 606
d.rectangle([s(tx0), s(400), s(tx1), s(940)], fill=cream)
# Cornice bands
d.rectangle([s(tx0 - 14), s(390), s(tx1 + 14), s(416)], fill=shade)
d.rectangle([s(tx0 - 8), s(560), s(tx1 + 8), s(578)], fill=shade)
# Belfry: two tall arched openings
for x in (452, 530):
    d.rounded_rectangle([s(x), s(440), s(x + 42), s(545)], radius=s(21), fill=dark)
# Lower window and door
d.rounded_rectangle([s(487), s(610), s(537), s(700)], radius=s(25), fill=dark)
d.rounded_rectangle([s(476), s(842), s(548), s(940)], radius=s(36), fill=dark)
d.rectangle([s(476), s(890), s(548), s(940)], fill=dark)

# Steep roof with corner pinnacles
d.polygon([(s(tx0 - 14), s(392)), (s(tx1 + 14), s(392)), (s(512), s(150))], fill=cream)
d.polygon([(s(512), s(150)), (s(tx1 + 14), s(392)), (s(512), s(392))], fill=shade)  # shaded side
for x in (tx0 - 6, tx1 + 6):
    d.polygon([(s(x - 16), s(395)), (s(x + 16), s(395)), (s(x), s(300))], fill=cream)
# Finial
d.line([(s(512), s(150)), (s(512), s(100))], fill=cream, width=s(8))
d.ellipse([s(500), s(88), s(524), s(112)], fill=(242, 176, 39))

# Ground
d.rectangle([0, s(940), W, W], fill=(16, 52, 44))

# Dotted quest trail up to the door
for x, y in [(130, 1000), (210, 985), (290, 972), (370, 963), (445, 958)]:
    d.ellipse([s(x - 13), s(y - 13), s(x + 13), s(y + 13)], fill=(242, 176, 39))

# Gold quest pin hovering to the right of the tower
cx, cy, r = 790, 300, 92
D = 160
cosf = r / D; sinf = math.sqrt(1 - cosf ** 2)
shadow = Image.new("L", (W, W), 0)
sd = ImageDraw.Draw(shadow)
sd.ellipse([s(cx - r), s(cy - r + 12), s(cx + r), s(cy + r + 12)], fill=110)
sd.polygon([(s(cx - r * sinf), s(cy + r * cosf + 12)), (s(cx + r * sinf), s(cy + r * cosf + 12)), (s(cx), s(cy + D + 12))], fill=110)
shadow = shadow.filter(ImageFilter.GaussianBlur(s(14)))
img.paste((8, 30, 40), mask=shadow)
d = ImageDraw.Draw(img)
gold = (242, 176, 39)
d.ellipse([s(cx - r), s(cy - r), s(cx + r), s(cy + r)], fill=gold)
d.polygon([(s(cx - r * sinf), s(cy + r * cosf)), (s(cx + r * sinf), s(cy + r * cosf)), (s(cx), s(cy + D))], fill=gold)
font = ImageFont.truetype("/System/Library/Fonts/SFNSRounded.ttf", s(128))
try: font.set_variation_by_name("Heavy")
except Exception: pass
bbox = d.textbbox((0, 0), "?", font=font)
w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
d.text((s(cx) - w / 2 - bbox[0], s(cy) - h / 2 - bbox[1]), "?", font=font, fill=(255, 255, 255))

img = img.resize((N, N), Image.LANCZOS)
img.save(out, "PNG")
print(img.size, img.mode)
