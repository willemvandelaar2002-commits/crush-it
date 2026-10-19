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
