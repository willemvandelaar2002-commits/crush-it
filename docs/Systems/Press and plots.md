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
