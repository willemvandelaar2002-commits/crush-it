# Press and plots

22 Oct gameplay redesign: plot origins/footprints and train access remain, while
three rear working bays, roll/bin/seller stations and two upgrade boards replace
the old per-plot manual press and smelter. Equipped inventory instances use the
existing press builder at bay scale. See [[Collectible crushers]] for current
gameplay and migration; the manual-tier details below are historical.

21 Oct connected-land update: the hub now sits on a broad raised commons
that reaches beneath the train loop. Its foundation now stops at the road,
restoring the 12-stud sandy gap to the plot islands. Four wider
spoke lanes keep the old connections. Plot footprints, owned areas, presses,
spawn/interaction positions and the train route are unchanged. See
[[Scrapyard environment]] for reference images and Play checks.

21 Oct movement update: Config.PlayerWalkSpeed is 28 studs/second for every
player. The server applies it in placeCharacter on initial spawn and respawn.
The spawn/respawn application was verified in Studio at 24; the subsequent
increase to 28 uses the same server setting.

21 Oct: environment builders now provide the bright scrapyard described in [[Scrapyard environment]]. Press logic and meshes remain unchanged. The 20 Oct limitation below is historical.

20 Oct visual update: shared Island colours now use blue-grey platforms,
navy borders and steel bridge finishes. All server geometry and gameplay
are unchanged. See [[Toy workshop]] for the remaining garden/lava replacement
and press styling steps blocked by the protected server-file constraint.

- 8 plots, two rows of 4 facing a walkway (`Config.Plots`). Each player gets
  one on join; the sign shows their name. Server full → kick with a message.
- The press is rebuilt when the tier changes; its width is
  `max(6, object width · 1.35)`, so it visibly grows.
- Crush: server checks the Speed cooldown, the ram strokes down
  (min(cooldown · 0.8, 0.5) s), Power damage comes off, and the object is
  squashed to 0.35 + 0.65 · hp/maxHp of its height. At 0 HP it pancakes to
  0.07, pays out, and the next object rolls in.
- Client sends Crush every 0.1 s while CRUSH / F / R2 is held; the server
  ignores anything early.
- Saving: `Kit/DataService` (session-locked, autosave 60 s), store
  `CrushItPlayer_v1`: cash, tier, levels, rebirths, crushed.
- Bigger press: the new press rises out of the floor (1.1 s, `RISE_SECONDS`),
  the owner gets a "BIGGER PRESS! Now crushing: X" banner, confetti and a
  shockwave; the next object rolls in once the press is up.
- Final hit: pieces of the object fly off (client-only physics), a shockwave
  ring on the bed, a heavy low thud, "+$X" and a full camera shake.
- Objects are drawn in `Config.Objects` with their front at -Z and turned
  around in `Objects.build` so the player (on the plot's walkway side) sees
  the front. Cylinders in Config stand along Y.
- Crush styles: every object has a `kind` (soft, fluff, glass, metal, wood,
  stone, planet). `Config.Kinds` picks its hit/crush sounds and effects:
  juice splat for the apple, fluff for the teddy, electric zaps and glass
  shards for phone/TV, sparks and smoke for metal, dust for the house and
  statue, fire and an explosion for the planet.
- Background music: `Music.client.luau` loops audio 113892640002952 in SoundService at 25% volume, continuing through respawns. Tune it in `Config.Music`.
- Sounds: all ids in `Config.Sounds` (free Creator Store audio, preloaded on
  join). Every stroke: thud + the kind's hit sound + a short hydraulic hiss
  on your own press; crush: heavy thud + crush sound + coin; bigger press:
  level-up jingle.
- Buying a bigger press moves you off the bed if the new press would grow
  under you.

## Press looks (PressBuilder.luau, 19 Oct)
Every tier has a name and paint colour (`Config.Presses`) and is at least 12%
wider than the one before (`Config.pressWidth`). Five stages add parts:
1. **Workshop** (Rusty, Workshop): rusty iron, wooden bed, bolts, red hand wheel.
2. **Steel** (Steel, Hazard, Pro): painted frame with hazard bands, twin side
   cylinders, pressure gauge, control panel with a red button, striped ram.
3. **Industrial** (Industrial, Factory, Heavy): I-beam pillars with rivets,
   orange beacons, steam vents, oil tank with a pipe up to the cylinder.
4. **Mega** (Mega, Turbo, Hyper): dark steel with neon edges, energy cells,
   neon bands, glowing ram, spinning ring round the cylinder.
5. **Titan** (Titan, Cosmic): black and gold, spikes, a glowing energy core
   with two orbiting rings.
The beam carries a name plate and 13 level lights (one per tier, lit up to
yours). Spinning parts are Models tagged `PressSpin`; the client turns them.

## Object meshes (19 Oct)
All 13 objects are AI-generated meshes (Roblox's mesh generator), stored in
the **place file** under `ReplicatedStorage.ObjectMeshes` (not in Git, not
managed by Rojo). `Objects.build` uses the Model with the object's name if it
exists and otherwise falls back to the parts in `Config.Objects`.
- Each mesh is scaled to fit the object's width/height; the real height is
  saved as the model attribute `Height` (the ram stops on it).
- A template's `Yaw` attribute (degrees) turns it so its front faces the
  player (TV -90, Teddy Bear 135, Fridge 50, Phone -30).
- Golden/Diamond: texture removed, painted gold / glass. Book silhouettes:
  painted black.
- To replace one: put a new Model with the same name in ObjectMeshes and
  save/publish the place.
- AI test presses (Rusty, Steel, Titan frames) are parked in
  `ServerStorage.GeneratedPresses` for later.

## Mesh press frames (19 Oct)
`ServerStorage.PressMeshes.Stage1..Stage5` (AI meshes, in the place file)
replace the code-built pillars/beam/extras for that stage. PressBuilder
scales the frame uniformly (never stretched) to whichever is bigger: wide
enough for the bed (`W * 1.55`) or tall enough for the stroke, adds a
hanging cylinder the rod slides into, an accent-coloured glow round the
plinth (each tier its own colour) and a sign in front with the press name and
13 level lights. Bed, ram, stripes and rod are still code. Remove a Stage
model to fall back to the code-built look for that stage. Optional `Yaw`
attribute (degrees) per frame. Plots are now 120 wide (spacing 140, rows at
±95) to fit the biggest frame.

## Upgrade board and row style (19 Oct, after Destroy a Vault)
- Upgrades are coloured rows (icon, name, "1.0 > 1.3", big green price
  button): Power red, Speed blue, Value yellow, Bigger Press purple, Rebirth
  orange. Same rows in the HUD panel and on a board next to the press.
- The board (12 x 18 studs) (`Plot.Board`) moves with the press size so it's always just
  right of it, turned toward the spawn. Its clickable rows are a SurfaceGui
  in the player's own PlayerGui (adorned), so only the owner uses it.
- Tutorial: dark banner across the top ("Hold CRUSH", "Buy An Upgrade",
  "Buy A Bigger Press") plus a pointing hand and ring on the button.

## Stud look (19 Oct)
Floors (bright grass), the dark pad under the press (grows with the press),
plot rims (each plot its own colour), walkway, press plinth and the board
frame carry the classic stud pattern: a Texture with
the imported Studs material (see Style kit; the old free image 7447638591 is gone), 2 studs
per tile. UI rows and the board background get the same pattern as a tiled
ImageLabel. The board frame is grey with white glowing edges.

## Steel frame replaced (20 Oct)
`PressMeshes.Stage2` is a new AI mesh: yellow painted steel pillars with chrome
cylinders, a thick riveted top beam and black/yellow hazard feet, open between
the legs (asset 136890182957615). The old beige arch and three other attempts
are parked in `ServerStorage.GeneratedPresses` (Old_Stage2_Beige, Gen_Steel_2..4).
Prompt tip for frames: say "connected ONLY at the top", "nothing between the
legs", "no table, no lower crossbar", or the bed/object ends up inside a slab.

## Islands in a lava sea (20 Oct, after the reference videos)
The flat field is gone. The whole map is a bright lava sea (`World.luau`:
flat orange surface with a slowly sliding stud pattern, glowing layer under it,
drifting blobs and crust plates, embers; cliffs and lavafalls rise out of it).
- Every plot is a thick **island** (`Moat.luau` + kit `Build.island`): grass top,
  dirt band, studded stone sides going down into the lava, rocks sticking out,
  boulders at the lava line, a chunky stone curb along the edge with gaps at
  the bridges, trees/bushes/lamps along the free edges.
- A **hub island** in the middle (`Hub.luau`, the tank game's "Market"): brick
  road, branch paths to every bridge with dark landing patches, lamps, trees,
  bushes, rocks, a lava fountain and two "CRUSH IT" signs; players spawn here.
- **Wooden plank bridges** (kit `Build.bridge`, the Yuzu game's) from the hub to
  every plot (`Config.World.HubGap` = 18). Long bridges get legs into the lava.
  (Until 20 Oct evening there was a second bridge to a separate scrap shop island;
  the shop is now a tab of the plot island, see below.)
- Plot floors: bright green studded grass with dark **asphalt zones with stepped
  edges** (kit `Build.patch`) under the buy pads and round the scrap pile, plus
  the dark pad under the press and the orange brick paths.
- Falling into the lava (below `Config.World.SeaY + 2`) puts you back on your plot
  with "Ouch, hot lava!". Sky back to bright **Day**. Rows moved apart
  (`RowOffset` 115) to make room for the hub. Theme "Island" in Style.

## Plot layout (20 Oct, evening): shop on the plot, everything close
Willem: the separate shop island made a long walk; in both reference games the
place you hand stuff in is on your own plot. Plot-local, +Z toward the hub:

- **Back** (the loop you repeat): scrap pile right behind the press (z -36) ->
  upgrade pad row (`Pads.ROW_Z` = -55: Power, Speed, Value, Bigger Press, Rebirth
  on the left, Auto Collect / Auto Crush on the right) -> "SCRAP SHOP" gate ->
  the shop on a 48 x 34 tab of the same island (`Config.ScrapShop`): Deposit,
  Collect Cash, Smelt Speed, Finish Now, smelter, Smelting board. No lava gap,
  no second bridge. Stats board ("Now Crushing") right of the pile.
- **Front**: hub bridge + gate, conveyor, spawn, and the two Mini Press yards
  (4 slots each, either side of the conveyor) with the Buy / Merge pads.
- **Sides of the press** (`PlotDecor`): scrap heap with a magnet crane that
  slowly swings over it (client turns `PressSpin` models round their `Axis`
  attribute), crates, bales of crushed scrap with a forklift, the boiler and an
  overhead steam pipe to the shop.
- The biggest press (AI mesh, tier 13) is ~104 x 64 studs: props it overlaps are
  parked in `ServerStorage.ParkedDecor<i>` and come back when the press is smaller
  (`Plots.buildPress` -> clearProps). Helper yards (z >= 33.5) and the pad row stay clear.
- Known: at the top tiers the Upgrades board and Robux signs still sit partly
  inside the big press frame (as before).

## Plot layout v3 (21 Oct): toy factory island
Willem: shop and buttons by the bridge, Mini Presses at the far end, more space
between plots, a little toy factory island. Plot-local, origin = press centre,
+Z toward the hub; the island runs z -80 .. +92 (`Config.Plots.Back/Front`), 120 wide.
- **Entrance** (bridge lands at x = 0): gate, spawn, scrap shop on the left
  (opens toward the centre path, `Config.Plots.ShopX/ShopZ`, built in its own
  frame by `ScrapShop.build`), upgrade pads on the right (two rows, `Pads.ROW_Z` = 58),
  stats board, scrap pile in front of the press (`Scrap.pileSpot`, z 14..40).
- **Back**: conveyor out of the **toy factory hall** door (`PlotDecor.factory`:
  windows, striped door, colourful sawtooth roof, chimneys, "TOY FACTORY" sign),
  Mini Press yards either side of the belt with Buy / Merge pads.
- Sides of the press: heap + swinging crane (left), boiler + bales/forklift (right).
- Spacing 190 (70 studs between islands), RowOffset 146; hub only reaches just
  past the outer bridges. Pad under the press capped at 76.
- Built on Willem's world art pass (sand yard, YardProps, blue-grey plots).

## Map v4 (21 Oct): the Toy Train Loop
Willem picked option C from the layout canvas. Numbers in `Config.Loop` / `Config.Plots.Ring`:
- Round **station hub** in the middle (radius 56): scrap display, CRUSH IT entrance,
  workshop props, spawn. Roads across it to **4 walkways** (0/90/180/270 degrees).
- **Ring road** from radius 172 to 198 (48 straight pieces, kerbs, painted edge lines)
  with **rails** at radius 182/188 and the **toy train** (engine + 4 wagons with toys,
  smoke) going round once a minute. Built in `Hub.luau`, driven by `client/Train.client.luau`
  from the server clock (cars moved part by part from their Chassis; pivots don't stream).
  Scenery only for now: no collisions, not rideable yet.
- **8 plots** at 22.5 + 45 k degrees (`Plots.originFor`), entrance edge at radius 210,
  facing the centre; their bridges (12 long) land on the loop.
- World (Willem's sand yard): cliff walls moved out to ±440, yard scenes and the
  workshop in the sand wedges between plots at radius 330.

## Mega Crusher + rideable trains (21 Oct)
- **Mega Crusher** (`server/MegaCrusher.luau`, `client/Mega.client.luau`): a tier-9
  press frame in the middle of the hub over a stack of 3 giant toy blocks. Every 6 s
  the ram slams: toys squash, sparks, "CRUSH!" pop-up, screen shake within 100 studs;
  then the toys bounce back. Scenery, pays nothing. The scrap display moved to the
  west side of the hub, the CRUSH IT entrance over the south road, spawn at z 30.
- **Train timetable** (`shared/TrainRoute.luau`): a lap = 8 legs, one per plot: stand
  `Config.Loop.TrainStop` (5) s at the plot's stop, drive 45 degrees in `TrainMove` (8) s
  with a smooth start/stop. `Trains` = 2, half a lap apart. A **train stop** shelter
  (posts, bench, toy-colour roof, "TRAIN STOP" sign) at every plot.
- **Riding** (`client/Train.client.luau`): E on a wagon ("Ride") seats you in it; you
  move with the wagon; the hint shows the stop ("Stop: <owner> / Your plot!"). Jump
  to hop off: at a stop you land on that plot's bridge, between stops beside the track.

## Plot layout changes, 28 Oct (Willem)
- Goals board in the front-right corner beside the roller, its back to the plaza-side wall: plot (52,102), yaw pi (was the left side at -44,24).
- Sell station moved toward the plaza-side (front) wall: (-26,96) (was -26,80).
- Coating Lab booth: plot (34,27) (was 42,19), nearer the walkway/front, and 1.35x bigger (CrusherConfig.CoatingBoothScale; PlotAssets.place has a `scale` option, the prompt moves with it).
- Fuser 1.4x bigger (CrusherConfig.Fusion.MachineScale; collision box and prompt scale with it), same spot (-97,57) in the fusion wing, turned so its input rings face the plot (+X, the doorway).

## What each crusher crushes (29 Oct)
`C.RarityObjects`: the toy on a bay's bed follows the crusher's rarity (the 13
meshes in ReplicatedStorage.ObjectMeshes / Config.Objects). Common Apple;
Uncommon Teddy Bear or Phone; Rare TV or Fridge; Epic Car or Truck; Legendary
Tank; Secret House or Statue; Divine Plane or Ship; Mythic Planet. Two options:
random per input. Visual only. Toys fill up to 90% of the clearance and ~90% of
the bed width.

## Less busy plot (30 Oct, trial — revert the commit if it looks worse)
- (Reverted the same day: locked bays keep their padlock/plaque; upper floors only appear after a plot upgrade anyway.)
- LOCKED pedestal hints and the EMPTY / price words on bay walls only show within `CrusherConfig.QuietLabelDistance` (30 studs).
- Trims: gold caps/feet and corner braces only on the outer columns of each bank (PlotStages `outerColumns`); trim road posts every `TrimPostSpacing` (24, was 12).
- Scrap counter over the bin (client/ScrapCounter) is sized in studs (`CrusherConfig.ScrapCounter`, 11 x 2.6 studs, 12 above the bin) so it shrinks with distance, and hides beyond 80 studs (was a fixed 320x70 px up to 260 studs).

- Floor colour per plot level: CrusherConfig.FloorColors (31 Oct: Factory V = bright red, PlotStages.sync).
- Floor studs: CrusherConfig.FloorStudTile (Factory V = 2: studs twice as big, a runtime copy of the Studs MaterialVariant named StudsX2) so the stud pattern reads from a distance. (The random lighter patches tried first were dropped.)
- Floor checkerboard: a Texture of lighter 4-stud squares on each floor top (Style.checker, look in Config.World.Checker: image, StudsPerTile 8, transparency 0.8). Plot floors get it on the levels in CrusherConfig.FloorChecker (31 Oct: Factory V); the yellow yard floor around the map always has it (World.luau). One texture per part, no extra parts; the road is its own part so stays plain.
