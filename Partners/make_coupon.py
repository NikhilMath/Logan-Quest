"""Draws the generic coupon mockup for pitching Logan businesses, in Logan Quest navy, gold
and cream.

    python3 Partners/make_coupon.py Partners/coupon.png

It matches the prize-box coupon in the app (the `prize` in LoganQuest/Quest.swift), so change
both together. "Your Business" and "Your offer here" stay until a business signs on with an
agreed offer. Needs Pillow (pip3 install pillow)
and macOS for the SF Rounded font. Drawn at 3x and scaled down for smooth edges; coordinates
are on the final 2000 x 1000 canvas.
"""
import sys
from PIL import Image, ImageDraw, ImageFont

SS = 3
W, H = 2000, 1000
def S(v): return int(round(v * SS))

ROUNDED = "/System/Library/Fonts/SFNSRounded.ttf"
NAVY_TOP, NAVY_BOTTOM = (22, 56, 88), (8, 26, 44)
GOLD, GOLD_LIGHT, GOLD_DARK = (247, 189, 52), (255, 216, 110), (214, 148, 22)
CREAM = (251, 243, 226)
STUB = 560          # width of the left stub
NOTCH = 46          # radius of the perforation notches
BUSINESS_BASELINE = 383

def font(size, weight="Black"):
    f = ImageFont.truetype(ROUNDED, S(size))
    f.set_variation_by_name(weight)
    return f

def tracked(d, xy, text, f, fill, track=0):
    x, y = xy
    for c in text:
        d.text((x, y), c, font=f, fill=fill)
        x += f.getlength(c) + S(track)
    return x

def draw():
    w, h = S(W), S(H)
    # Navy gradient card
    card = Image.new("RGBA", (w, h))
    g = ImageDraw.Draw(card)
    for y in range(h):
        t = y / (h - 1)
        g.line([(0, y), (w, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(NAVY_TOP, NAVY_BOTTOM)) + (255,))
    # Shape: rounded rectangle minus the two notches
    mask = Image.new("L", (w, h), 0)
    m = ImageDraw.Draw(mask)
    m.rounded_rectangle([0, 0, w - 1, h - 1], radius=S(56), fill=255)
    for cy in (0, H):
        m.ellipse([S(STUB - NOTCH), S(cy - NOTCH), S(STUB + NOTCH), S(cy + NOTCH)], fill=0)
    # Everything else is drawn on a clear layer, then laid over the card, so see-through
    # colors blend with the navy instead of punching holes in it.
    ink = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(ink)

    # Gold border inset
    d.rounded_rectangle([S(22), S(22), S(W - 22), S(H - 22)], radius=S(40), outline=GOLD + (110,), width=S(3))

    # Perforation
    y = NOTCH + 24
    while y < H - NOTCH - 24:
        d.rounded_rectangle([S(STUB - 3), S(y), S(STUB + 3), S(y + 22)], radius=S(3), fill=CREAM + (90,))
        y += 40

    # Stub: the prize box, then QUEST REWARD
    cx, base = STUB / 2, 520
    bw, bh = 250, 160
    d.rounded_rectangle([S(cx - bw / 2), S(base - bh), S(cx + bw / 2), S(base)], radius=S(14), fill=GOLD)
    d.rectangle([S(cx - bw / 2), S(base - bh), S(cx + bw / 2), S(base - bh + 12)], fill=GOLD_DARK)
    lw, lh = 284, 52
    d.rounded_rectangle([S(cx - lw / 2), S(base - bh - lh + 6), S(cx + lw / 2), S(base - bh + 6)], radius=S(12), fill=GOLD_LIGHT)
    d.rectangle([S(cx - 20), S(base - bh - lh + 6), S(cx + 20), S(base)], fill=CREAM)
    top = base - bh - lh + 6
    for side in (-1, 1):
        box = [S(cx + side * 34 - 40), S(top - 50), S(cx + side * 34 + 40), S(top - 4)]
        ell = Image.new("RGBA", (S(90), S(60)))
        ImageDraw.Draw(ell).ellipse([0, 0, S(90) - 1, S(60) - 1], fill=CREAM + (255,))
        ell = ell.rotate(side * -28, expand=True, resample=Image.BICUBIC)
        ink.alpha_composite(ell, (S(cx + side * 38) - ell.width // 2, S(top - 26) - ell.height // 2))
    d.rounded_rectangle([S(cx - 18), S(top - 22), S(cx + 18), S(top + 6)], radius=S(10), fill=CREAM)

    f = font(40, "Heavy")
    label = "QUEST REWARD"
    lwid = sum(f.getlength(c) for c in label) + S(6) * (len(label) - 1)
    tracked(d, (S(cx) - lwid / 2, S(600)), label, f, GOLD, 6)
    f = font(30, "Semibold")
    for i, line in enumerate(["Downtown Logan", "quest"]):
        tw = f.getlength(line)
        d.text((S(cx) - tw / 2, S(670 + i * 44)), line, font=f, fill=CREAM + (170,))

    # Main side
    x0 = STUB + 90
    tracked(d, (S(x0), S(110)), "LOGAN QUESTS", font(34, "Heavy"), GOLD, 5)
    # The business, as big as fits (up to 230) on a fixed baseline.
    business, size = "Your Business", 230
    while font(size).getlength(business) > S(W - 110 - (x0 - 8)):
        size -= 2
    d.text((S(x0 - 8), S(BUSINESS_BASELINE)), business, font=font(size), fill=CREAM, anchor="ls")

    # Offer (placeholder) in a dashed gold box
    ox0, oy0, ox1, oy1 = x0, 470, W - 110, 640
    d.rounded_rectangle([S(ox0), S(oy0), S(ox1), S(oy1)], radius=S(26), fill=GOLD + (34,))
    dash, gap, r = 26, 16, 26
    def dashes(a, b, fixed, horizontal):
        p = a
        while p < b:
            q = min(p + dash, b)
            if horizontal: d.line([(S(p), S(fixed)), (S(q), S(fixed))], fill=GOLD, width=S(4))
            else: d.line([(S(fixed), S(p)), (S(fixed), S(q))], fill=GOLD, width=S(4))
            p += dash + gap
    dashes(ox0 + r, ox1 - r, oy0, True); dashes(ox0 + r, ox1 - r, oy1, True)
    dashes(oy0 + r, oy1 - r, ox0, False); dashes(oy0 + r, oy1 - r, ox1, False)
    for (ax, ay, start) in [(ox0, oy0, 180), (ox1 - 2 * r, oy0, 270), (ox1 - 2 * r, oy1 - 2 * r, 0), (ox0, oy1 - 2 * r, 90)]:
        d.arc([S(ax), S(ay), S(ax + 2 * r), S(ay + 2 * r)], start, start + 90, fill=GOLD, width=S(4))
    f = font(84)
    offer = "Your offer here"
    bb = f.getbbox(offer)
    d.text((S(ox0 + 50), S((oy0 + oy1) / 2) - (bb[1] + bb[3]) / 2), offer, font=f, fill=GOLD_LIGHT)

    d.text((S(x0), S(690)), "Finish the Downtown Logan quest, then show the prize", font=font(40, "Medium"), fill=CREAM + (215,))
    d.text((S(x0), S(740)), "screen in the Logan Quest app at the counter.", font=font(40, "Medium"), fill=CREAM + (215,))

    # Expiry
    d.line([(S(x0), S(830)), (S(W - 110), S(830))], fill=CREAM + (60,), width=S(2))
    tracked(d, (S(x0), S(862)), "EXPIRES DEC 31, 2026", font(44, "Heavy"), GOLD, 4)
    f = font(36, "Semibold")
    note = "One per player"
    d.text((S(W - 110) - f.getlength(note), S(868)), note, font=f, fill=CREAM + (160,))

    card.alpha_composite(ink)
    card.putalpha(mask)
    return card.resize((W, H), Image.LANCZOS)

if __name__ == "__main__":
    draw().save(sys.argv[1])
