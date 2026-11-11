# 11 Nov: Exotic and Eternal art made from the coloured Legendary / Epic art (the grey source
# art isn't in the repo): the coloured pixels get the new rarity's hue and saturation; on cards
# only the rim changes (the inner purple panel stays, as in tint.py).
import sys, colorsys
from PIL import Image, ImageFilter
def recolor(src, dst, target, rim_only):
    im = Image.open(src).convert("RGBA"); px = im.load()
    th, ts, tv = colorsys.rgb_to_hsv(*[c / 255 for c in target])
    inner = None
    if rim_only:
        a = im.split()[3].point(lambda v: 255 if v > 128 else 0)
        inner = a.filter(ImageFilter.MinFilter(55)).load()
    # the source rarity's own saturation, to scale against
    for y in range(im.size[1]):
        for x in range(im.size[0]):
            r, g, b, al = px[x, y]
            if al == 0 or (inner and inner[x, y] > 0): continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if s < 0.25 or v < 0.25: continue  # navy outlines and white highlights stay
            nr, ng, nb = colorsys.hsv_to_rgb(th, min(1, s * ts / max(SRC_S, 1e-3)), min(1, v * tv / max(SRC_V, 1e-3)))
            px[x, y] = (int(nr * 255), int(ng * 255), int(nb * 255), al)
    im.save(dst)
JOBS = [("Exotic", "Legendary", (255, 112, 55)), ("Eternal", "Divine", (205, 185, 255))]
SRC = {"Legendary": (255, 190, 20), "Divine": (80, 215, 255)}
for name, base, target in JOBS:
    SRC_H, SRC_S, SRC_V = colorsys.rgb_to_hsv(*[c / 255 for c in SRC[base]])
    recolor(f"Tab-{base}.png", f"Tab-{name}.png", target, False)
    recolor(f"Card-{base}.png", f"Card-{name}.png", target, True)
    print("made", name)
