import sys
from PIL import Image, ImageFilter
src, out = sys.argv[1], sys.argv[2]
NAVY=(12,14,52)
TABS={"Common":(185,200,222),"Uncommon":(60,215,50),"Rare":(30,135,255),"Epic":(185,55,255),"Legendary":(255,190,20),
      "Limited":(20,215,120),"Secret":(70,70,92),"Divine":(80,215,255)}
RIMS=dict(TABS); RIMS["Secret"]=(160,160,185); RIMS["Common"]=(205,215,232)
FILL=(135,45,235)
def lerp(a,b,t): return tuple(int(a[i]+(b[i]-a[i])*t) for i in range(3))
def shade(g,c):
    if g<60: return lerp(NAVY, lerp(NAVY,c,0.4), g/60)
    base=tuple(min(255,int(v*min(1.0,(g-30)/170))) for v in c)
    if g>228: base=lerp(base,(255,255,255),min(1,(g-228)/27)*0.75)
    return base
def tint(im,c,mask=None,c2=None):
    im=im.copy(); px=im.load(); m=mask.load() if mask else None
    for y in range(im.size[1]):
        for x in range(im.size[0]):
            r,g,b,a=px[x,y]
            if a==0: continue
            col=c2 if (m and m[x,y]>0) else c
            px[x,y]=shade(r,col)+(a,)
    return im
tab=Image.open(f"{src}/Rarity-Tab.png").convert("RGBA").crop((0,47,2172,681)).resize((640,187),Image.LANCZOS)
card=Image.open(f"{src}/Crusher-Card.png").convert("RGBA").crop((12,20,1109,1390)).resize((400,500),Image.LANCZOS)
# card rim = within ~27 px (on this 400 px card) of the transparent edge; the inner panel gets the fill colour
a=card.split()[3].point(lambda v:255 if v>128 else 0)
inner=a.filter(ImageFilter.MinFilter(55))  # erode 27 px
for name,c in TABS.items():
    tint(tab,c).save(f"{out}/Tab-{name}.png")
    tint(card,RIMS[name],inner,FILL).save(f"{out}/Card-{name}.png")
# the Auto Buy button
tint(tab,(70,225,60)).save(f"{out}/Tab-Buy.png"); tint(tab,(120,128,150)).save(f"{out}/Tab-Off.png")
