# Progression (rebirth, rare objects, collection)

All numbers in `src/shared/Config.luau`.

## Rebirth
- Unlocks once your press reaches `Config.Rebirth.RequiredTier(rebirths)`:
  the Car for the first rebirth, one tier further each time (capped at the Planet).
- Resets cash, press size and Power/Speed/Value levels.
- Gives a permanent cash multiplier: 1 + 0.5 × rebirths (x1.5, x2.0, x2.5…).
- Button: the gold "Rebirth" card under Bigger Press; tap twice ("SURE?") to confirm.

## Golden and Diamond objects
- Every object that rolls in can be **Golden** (5%, pays x10) or
  **Diamond** (0.5%, pays x50). Same HP as normal.
- Gold/diamond tint, sparkles, a special burst and "GOLDEN!" / "DIAMOND!" on the crush.
- A Diamond crush is announced to everyone in the server.

## Collection book
- "BOOK" button (top left) → every object with a 3D preview (black until
  crushed) and how many Normal / Golden / Diamond you've crushed.
- The first crush of each version adds a permanent cash bonus:
  Normal +1%, Golden +3%, Diamond +10% (all 39 = x2.82).
- A red dot on the BOOK button means something new was added.

## Cash per crush
`ObjectValue(tier) × Value upgrade × variant mult × rebirth mult × collection mult`
(rebirth × collection is shown next to your cash as "x1.75" etc.)
