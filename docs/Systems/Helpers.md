# Helpers (Mini Presses)

The "units" from the reference games (capybaras in the onsen, tanks in Destroy a Vault):
small presses you buy and place in two yards on the front half of your plot, either side
of the conveyor, round the big press. They crush on their own and feed their value
straight into your smelter.

- Code: `src/server/Helpers.luau` (yard, buying, merging, production), `src/client/Helpers.client.luau` (ram animation, sparks, "+$X").
- Numbers: `Config.Helpers`.
  - 8 slots (2 yards of 4, plot-local x -30/-44 and 34/48, z 39/52), one ram hit every `Tick` = 3 s.
  - Value per hit: `ObjectValue(tier) * 2.6^(level-1)` × your cash multipliers (Cash Mult, 2x pass, friend boost). Level 1 = $3 per 3 s at tier 1.
  - Cost: `SizeCost(tier) * 0.15 * 1.45^owned` (tier 1: $19 for the first).
- Buy pad "Buy Mini Press": stand on it to buy (repeats while you stand, until the 8 slots are full).
- Merge pad: 3 of the same level → 1 of the next level (lowest level first). 8 levels: Mini, Bronze, Silver, Gold, Ruby, Emerald, Diamond, Rainbow.
- Their cash goes into the smelter queue (`Scrap.feed`), so you still walk to Collect Cash; it also counts in the shown cash/sec.
- Saved in `data.helpers` (list of levels). Rebirth clears them.
