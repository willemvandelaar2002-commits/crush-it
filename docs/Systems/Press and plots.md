# Press and plots

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
stretches the frame to `W * 1.65` wide and tall enough for the stroke, adds a
hanging cylinder the rod slides into, an accent-coloured glow round the
plinth (each tier its own colour) and a sign in front with the press name and
13 level lights. Bed, ram, stripes and rod are still code. Remove a Stage
model to fall back to the code-built look for that stage. Optional `Yaw`
attribute (degrees) per frame. Plots are now 120 wide (spacing 140, rows at
±95) to fit the biggest frame.
