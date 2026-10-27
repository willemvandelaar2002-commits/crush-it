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
 -- Mythics: Willem's Blender models, built in studs, fronts face +Z
 -- (template attribute BayFrontYaw=0). grow: scale up to fill the bay.
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
}
