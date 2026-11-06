"""LimitedCrusherAssets.luau from the Studio measurement + the pack manifest.
studio = (-bx, bz, by); units cm/100. Keys: frames 1..80 mapped so the model's contact
frame lands on the rig's CONTACT (33/71)."""
import json, math, sys
meas = json.load(open(sys.argv[1])); man = {e["id"]: e for e in json.load(open(sys.argv[2]))}; out = sys.argv[3]
CONTACT = 33/71
CONTACT_FRAME = {"CloverOverdrive": 29, "HorseshoeComet": 22, "JackpotFoundry": 39}
INPUT = {"CloverOverdrive": .42, "HorseshoeComet": .45, "JackpotFoundry": .5}
def conv(v): return (-v[0], v[2], v[1])
def num(x): return "0" if abs(x) < 1e-9 else ("%.4f" % x).rstrip("0").rstrip(".")
def v3(t): return "Vector3.new(%s)" % ", ".join(num(x) for x in t)
def tmap(f, fc): return (f-1)/(fc-1)*CONTACT if f <= fc else CONTACT+(f-fc)/(80-fc)*(1-CONTACT)
L = ["--!strict", "-- 6 Nov 2026: Willem's Lucky Weekend crushers (CrusherIncremental-Lucky-Weekend-Crushers).",
     "-- Generated (scratch limited_gen/gen.py) from the Studio import (part centres, sizes, pivots in",
     "-- Blender units, the import's axes: studio = (-blenderX, blenderZ, blenderY)) and the pack's",
     "-- Model-manifest.json: strike moves/turns, and per-part keys (frames 1..80 mapped so each",
     "-- model's impact frame lands on the rig's contact time). Merged into SpecialCrusherAssets.",
     "return {"]
for mid in ["CloverOverdrive", "HorseshoeComet", "JackpotFoundry"]:
    parts = meas[mid]["parts"]; m = man[mid]; fc = CONTACT_FRAME[mid]
    lo=[1e9]*3; hi=[-1e9]*3
    for p in parts.values():
        for i in range(3): lo[i]=min(lo[i],(p["c"][i]-p["s"][i]/2)/100); hi[i]=max(hi[i],(p["c"][i]+p["s"][i]/2)/100)
    size=[hi[i]-lo[i] for i in range(3)]
    ic = conv(m["inputCenter"]); isz = INPUT[mid]
    L.append('\t["%s"] = {kit = "motion", grow = true, size = %s, bedTop = %s,' % (mid, v3(size), num(ic[1]-isz/2)))
    L.append('\t\tinputCenter = %s, inputSize = %s,' % (v3(ic), num(isz)))
    L.append('\t\tparts = {')
    for name, p in sorted(parts.items(), key=lambda kv: (kv[0] != "Frame", kv[0])):
        L.append('\t\t\t["%s"] = {center = %s, size = %s, origin = %s},' % (name, v3([x/100 for x in p["c"]]), v3([x/100 for x in p["s"]]), v3([x/100 for x in p["p"]])))
    L.append('\t\t},'); L.append('\t\tmotion = {')
    moving=[]
    for a in m["assemblies"]:
        if a["name"] == "Frame": continue
        keys = [[tmap(f, fc), v] for f, v in a["previewKeys"]]
        T = a["strikeTranslation"]; R = a["strikeRotationXYZDegrees"]
        if a["name"] == "Reel_2":  # 810 deg: come back a quarter turn after the hit so the rest pose matches (720 = a whole number of turns)
            keys = [k for k in keys if k[0] <= tmap(28, fc)] + [[tmap(50, fc), 1], [tmap(72, fc), 720/810], [1, 720/810]]
        # big turns: extra keys so no tween step turns more than 40 degrees (a CFrame
        # tween takes the short way round, so 360 degrees in one step would not turn at all)
        R0 = max(abs(x) for x in a["strikeRotationXYZDegrees"])
        if R0 > 40:
            fine = [keys[0]]
            for (t0, v0), (t1, v1) in zip(keys, keys[1:]):
                n = max(1, math.ceil(abs(v1 - v0) * R0 / 40))
                for i in range(1, n + 1): fine.append([t0 + (t1 - t0) * i / n, v0 + (v1 - v0) * i / n])
            keys = fine
        ks = "{" + ", ".join("{%s, %s}" % (num(t), num(v)) for t, v in keys) + "}"
        if any(abs(x) > 1e-9 for x in T):
            L.append('\t\t\t{name = "%s", kind = "move", vector = %s, keys = %s},' % (a["name"], v3(conv(T)), ks)); moving.append(a["name"])
        for i, deg in enumerate(R):
            if abs(deg) < 1e-9: continue
            axis=[0,0,0]; axis[i]=1
            L.append('\t\t\t{name = "%s", kind = "rotate", axis = %s, angle = %s, keys = %s},' % (a["name"], v3(conv(axis)), num(math.radians(deg)), ks)); moving.append(a["name"])
    L.append('\t\t},')
    contact = {"CloverOverdrive": ["Jaw_Top","Jaw_Right","Jaw_Bottom","Jaw_Left"], "HorseshoeComet": ["SwingArm"], "JackpotFoundry": ["StarRam"]}[mid]
    L.append('\t\tcontact = {%s},' % ", ".join('"%s"' % c for c in contact))
    L.append('\t},')
L.append("}")
open(out, "w").write("\n".join(L) + "\n"); print("wrote", out)
