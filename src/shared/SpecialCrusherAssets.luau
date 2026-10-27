--!strict
-- Runtime measurements copied from assets/special-crushers/asset-manifest.json.
-- Vector3 order is Roblox width, height, depth (manifest lists width, depth, height).
return {
 TwinTitan={size=Vector3.new(11.6,12.8,8.2),bedTop=1.62,rams={
  {name="Ram_L",stroke=3.525},
  {name="Ram_R",stroke=3.525},
 }},
 RocketPress={size=Vector3.new(11.1593,12.6,8.3),bedTop=1.62,rams={
  {name="Ram",stroke=3.525},
 }},
 Magnetron={size=Vector3.new(10.8,11.7,8.2),bedTop=1.62,rams={
  {name="Ram",stroke=3.525},
 }},
 GoldenKing={size=Vector3.new(10.8,13.4538,8.3),bedTop=1.62,rams={
  {name="Ram",stroke=3.525},
 }},
 Toyzilla={size=Vector3.new(11.8,13.2,8.4),bedTop=2.5,rams={
  {name="Ram",stroke=2.63},
 }},
 -- Mythics: Willem's Blender models, built in studs, fronts face -Z like the others
 -- grow: scale up to fill the bay.
 -- lift: the ram rests this much higher (opened) and strokes back down.
 -- side: moves with the ram but is not above the bed (ignored for toy space).
 JackpotPress={size=Vector3.new(7.53,7.52,4.73),bedTop=1.24,grow=true,rams={
  {name="Ram",stroke=1.35},{name="PistonShaft",stroke=1.35},
 }},
 SeraphPress={size=Vector3.new(8.35,8.65,5.44),bedTop=1.41,grow=true,rams={
  {name="Ram",stroke=1.35},{name="PistonShaft",stroke=1.35},
 }},
 PrismMech={size=Vector3.new(7.36,7.92,6.06),bedTop=1.45,grow=true,rams={
  {name="Ram",stroke=1.1},{name="PistonShaft",stroke=1.1},
 }},
 PhantomPirate={size=Vector3.new(7.9,7.75,5.76),bedTop=2.26,grow=true,rams={
  {name="Jaw",stroke=1.6,lift=1.6},{name="HydraulicRod_L",stroke=1.6,lift=1.6,side=true},{name="HydraulicRod_R",stroke=1.6,lift=1.6,side=true},
 }},
 CandyColossus={size=Vector3.new(7.7,8.49,5.96),bedTop=1.45,grow=true,rams={
  {name="Ram",stroke=1.5},{name="PistonShaft",stroke=1.5},
 }},
-- Crate crushers (27 Oct pack, assets/crate-crushers): kit="motion" rigs.
-- All numbers in FBX export space (x, y up, z; = Blender (x, z, -y)), studs at
-- fit 1; Studio's importer turns the meshes 180 degrees, SpecialCrushers works
-- the turn out from the parts themselves. parts = each component's mesh box
-- centre/size and its authored pivot (origin). motion kinds: move (vector),
-- rotate (axis, angle about origin), extend (stretch along a part axis, origin
-- stays put). curve press/wind = the 72-frame Blender demo curves.
-- Generated from the pack's JSON + FBX files (scratch tool fbxtool/gen.py).
 DuckyDynamo={size=Vector3.new(7.6,7.4291,5.825),bedTop=1.42,grow=true,kit="motion",
  parts={
   Frame={center=Vector3.new(0,3.68,0.0125),size=Vector3.new(7.6,7.36,5.825),origin=Vector3.new(0,0,0)},
   PistonShaft={center=Vector3.new(0,6.285,-0.5),size=Vector3.new(0.56,0.53,0.56),origin=Vector3.new(0,6.55,-0.5)},
   Ram={center=Vector3.new(0,5.7345,0.5075),size=Vector3.new(3.92,3.3891,3.295),origin=Vector3.new(0,5.48,0.22)},
   Wing_L={center=Vector3.new(-2.9893,3.803,-0.5525),size=Vector3.new(1.3786,2.8928,0.875),origin=Vector3.new(-2.55,4.9,-0.65)},
   Wing_R={center=Vector3.new(2.9893,3.803,-0.5525),size=Vector3.new(1.3786,2.8928,0.875),origin=Vector3.new(2.55,4.9,-0.65)},
  },
  motion={
   {name="Ram",kind="move",vector=Vector3.new(0,-2.54,0),curve="press"},
   {name="PistonShaft",kind="extend",axis="Y",ratio=5.79245,curve="press"},
   {name="Wing_L",kind="rotate",axis=Vector3.new(0,0,-1),angle=-0.1,curve="wind"},
   {name="Wing_R",kind="rotate",axis=Vector3.new(0,0,-1),angle=0.1,curve="wind"},
  },
  contact={"Ram"},
 },
 WindUpWrecker={size=Vector3.new(7.5,8.72,5.87),bedTop=1.42,grow=true,kit="motion",
  parts={
   Ear_L={center=Vector3.new(-0.83,7.14,0.125),size=Vector3.new(0.98,3.16,0.91),origin=Vector3.new(-0.83,5.93,0.1),parent="Ram"},
   Ear_R={center=Vector3.new(0.83,7.14,0.125),size=Vector3.new(0.98,3.16,0.91),origin=Vector3.new(0.83,5.93,0.1),parent="Ram"},
   Frame={center=Vector3.new(0,3.3225,0.035),size=Vector3.new(7.5,6.645,5.77),origin=Vector3.new(0,0,0)},
   PistonShaft={center=Vector3.new(0,5.875,-0.65),size=Vector3.new(0.56,0.53,0.56),origin=Vector3.new(0,6.14,-0.65)},
   Ram={center=Vector3.new(0,4.855,0.485),size=Vector3.new(3.64,2.55,3.01),origin=Vector3.new(0,4.87,0.25)},
   WindKey={center=Vector3.new(0,4.95,-2.1225),size=Vector3.new(2.96,1.56,1.655),origin=Vector3.new(0,4.95,-2.8)},
  },
  motion={
   {name="Ram",kind="move",vector=Vector3.new(0,-2.08,0),curve="press"},
   {name="PistonShaft",kind="extend",axis="Y",ratio=4.92453,curve="press"},
   {name="Ear_L",kind="rotate",axis=Vector3.new(0,0,-1),angle=-0.12,curve="wind"},
   {name="Ear_R",kind="rotate",axis=Vector3.new(0,0,-1),angle=0.12,curve="wind"},
   {name="WindKey",kind="rotate",axis=Vector3.new(0,0,-1),angle=1.5708,curve="wind"},
  },
  contact={"Ram"},
 },
 GumballGobbler={size=Vector3.new(7.4,8.7,5.84),bedTop=1.42,grow=true,kit="motion",
  parts={
   Frame={center=Vector3.new(0,4.35,0.07),size=Vector3.new(7.4,8.7,5.84),origin=Vector3.new(0,0,0)},
   Globe={center=Vector3.new(0,6.55,-0.5),size=Vector3.new(3.3,3.3,3.3),origin=Vector3.new(0,6.55,-0.5)},
   Gumballs={center=Vector3.new(0.0053,6.295,-0.4893),size=Vector3.new(2.0693,2.03,2.0533),origin=Vector3.new(0,6.4,-0.5)},
   PistonShaft={center=Vector3.new(0,4.09,0),size=Vector3.new(0.56,0.86,0.56),origin=Vector3.new(0,4.52,0)},
   Ram={center=Vector3.new(0,3.3475,0),size=Vector3.new(3.56,0.825,3.56),origin=Vector3.new(0,3.27,0)},
  },
  motion={
   {name="Ram",kind="move",vector=Vector3.new(0,-1.43,0),curve="press"},
   {name="PistonShaft",kind="extend",axis="Y",ratio=2.66279,curve="press"},
   {name="Gumballs",kind="rotate",axis=Vector3.new(0,1,0),angle=2.19911,curve="wind"},
  },
  contact={"Ram"},
  transparent={Globe=0.83},
 },
 ArcadeClaw={size=Vector3.new(7.6,7.325,5.8),bedTop=1.42,grow=true,kit="motion",
  parts={
   Carriage={center=Vector3.new(0,5.5875,0),size=Vector3.new(1.84,0.645,1.84),origin=Vector3.new(0,5.65,0)},
   Claw_L={center=Vector3.new(-1.2614,4.105,0),size=Vector3.new(1.8228,3.03,0.9),origin=Vector3.new(-0.62,5.35,0),parent="Carriage"},
   Claw_R={center=Vector3.new(1.2614,4.105,0),size=Vector3.new(1.8228,3.03,0.9),origin=Vector3.new(0.62,5.35,0),parent="Carriage"},
   Frame={center=Vector3.new(0,3.6625,0),size=Vector3.new(7.6,7.325,5.8),origin=Vector3.new(0,0,0)},
   PistonShaft={center=Vector3.new(0,6.27,0),size=Vector3.new(0.56,0.66,0.56),origin=Vector3.new(0,6.6,0)},
  },
  motion={
   {name="Carriage",kind="move",vector=Vector3.new(0,-1.02,0),curve="press"},
   {name="PistonShaft",kind="extend",axis="Y",ratio=2.54545,curve="press"},
   {name="Claw_L",kind="rotate",axis=Vector3.new(0,0,-1),angle=-0.08,curve="press"},
   {name="Claw_R",kind="rotate",axis=Vector3.new(0,0,-1),angle=0.08,curve="press"},
  },
  contact={"Claw_L","Claw_R"},
 },
 DiscoDestroyer={size=Vector3.new(7.8,6.375,6),bedTop=1.42,grow=true,kit="motion",
  parts={
   Deck_L={center=Vector3.new(-2.78,1.25,2.15),size=Vector3.new(1.1,0.2,1.1),origin=Vector3.new(-2.78,1.21,2.15)},
   Deck_R={center=Vector3.new(2.78,1.25,2.15),size=Vector3.new(1.1,0.2,1.1),origin=Vector3.new(2.78,1.21,2.15)},
   Frame={center=Vector3.new(0,3.1875,0),size=Vector3.new(7.8,6.375,6),origin=Vector3.new(0,0,0)},
   PistonShaft={center=Vector3.new(0,5.48,0),size=Vector3.new(0.56,0.2,0.56),origin=Vector3.new(0,5.58,0)},
   Ram={center=Vector3.new(0,3.85,0),size=Vector3.new(3.55,3.2,3.55),origin=Vector3.new(0,3.88,0)},
  },
  motion={
   {name="Ram",kind="move",vector=Vector3.new(0,-0.75,0),curve="press"},
   {name="PistonShaft",kind="extend",axis="Y",ratio=4.75,curve="press"},
   {name="Ram",kind="rotate",axis=Vector3.new(0,1,0),angle=3.14159,curve="wind"},
   {name="Deck_L",kind="rotate",axis=Vector3.new(0,1,0),angle=3.14159,curve="wind"},
   {name="Deck_R",kind="rotate",axis=Vector3.new(0,1,0),angle=-3.14159,curve="wind"},
  },
  contact={"Ram"},
 },
 KrakenClamp={size=Vector3.new(7.8,6.99,5.8),bedTop=1.42,grow=true,kit="motion",
  parts={
   Frame={center=Vector3.new(0,3.495,0),size=Vector3.new(7.8,6.99,5.8),origin=Vector3.new(0,0,0)},
   Jaw_L={center=Vector3.new(-2.0835,3.1732,0.2719),size=Vector3.new(3.1362,2.9493,2.1784),origin=Vector3.new(-2.93,4.38,-0.42)},
   Jaw_R={center=Vector3.new(2.0835,3.1732,0.2719),size=Vector3.new(3.1362,2.9493,2.1784),origin=Vector3.new(2.93,4.38,-0.42)},
   SidePiston_L={center=Vector3.new(-2.25,3,-0.75),size=Vector3.new(0.9,0.26,0.26),origin=Vector3.new(-2.7,3,-0.75)},
   SidePiston_R={center=Vector3.new(2.25,3,-0.75),size=Vector3.new(0.9,0.26,0.26),origin=Vector3.new(2.7,3,-0.75)},
  },
  motion={
   {name="Jaw_L",kind="move",vector=Vector3.new(0.65,0,0),curve="press"},
   {name="Jaw_R",kind="move",vector=Vector3.new(-0.65,0,0),curve="press"},
   {name="SidePiston_L",kind="extend",axis="X",ratio=1.72222,curve="press"},
   {name="SidePiston_R",kind="extend",axis="X",ratio=1.72222,curve="press"},
  },
  contact={"Jaw_L","Jaw_R"},
 },
}
