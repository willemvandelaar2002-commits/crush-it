# Gems

Second currency for players who have rebirthed (added 8 Nov 2026). Numbers live in
`src/shared/GemConfig.luau`, rules in `CrusherRules` (`Rebirth`, `GemUpgrade`, `GemCrate`, `gemRate`),
UI in `src/client/GemShop.client.luau`, tests in `Server/Tests/Gems.spec.luau`.

- **Job:** progress after the first rebirth. Never sold for Robux, so the crate is not a paid random item (odds still shown).
- **Faucet (10 Nov):** only the **Gem Mine** (see `Gem Mine.md`): base 30 Gems a minute from rebirth 1 (10 Nov; prices x3 with it, see `Gem Mine.md`). Rebirths pay no Gems and bays make none any more.
- **HUD (10 Nov, Willem):** your Gems show bottom left just above the cash, in the same style (gem icon, big pink
  number); tap it to open the Gem Shop. Shown from rebirth 1. (Was a GEMS button in the top-left row.)
- **Sink, the Gem Shop** (open it from the Gems counter or the GEM UPGRADES sign in the mine):
  - Gem Crate, 750 Gems (25 before the mine; all Gem prices x3 on 10 Nov): Legendary 60% / Exotic 30% / Secret 8% / Divine 2%, Standard finish, refused when the inventory is full. Exotic+ results are announced server-wide.
  - Mine upgrades first: Crush Speed, More Gems, Gem Value, Gem Magnet (see `Gem Mine.md`).
  - Gem Cash and Gem Luck: +10% per level, max 10, cost `15 * 1.5^level`.
  - Quick Rolls: roll cooldown -0.25 s per level (never below 1 s), max 4, cost `20 * 2^level`.
  - Head Start (9 Nov): a rebirth starts 1 Factory further per level with the earlier bays open
    (lv 1: FACTORY II + 12 bays, lv 2: FACTORY III + 24), max 2 (never at Rebirth.MinPlot), 40 / 120 Gems.
  - Nest Egg (9 Nov): start a rebirth with 1% of its price per level, max 5 (25, 40, 64, 102, 164 Gems).
  - Why: rebirth 1 -> 2 is where players stop (170 -> 66); vault (Progression and Pacing): a rebirth
    keeps "fast travel to the start of the furthest region". Willem tests whether it feels good.
  - The upgrade list scrolls (6 rows, 4 visible).
- Gems and upgrades survive every rebirth.
- DEV panel (Studio): Gems +25/+100/+1000, set Rebirths 0/1/3/5/10 (1+: Gem Mine, 5+: awakened),
  Rebirth "Make ready" / "Rebirth now", Gem upgrades all max / all 0, plot level 6 (Annex).
- Analytics: custom `GemsEarned`, `GemUpgrade`, `GemCrate`; since 9 Nov also economy events in currency
  **"Gems"** (`Analytics.gems`): sources Mine (were Rebirth / Bays before 10 Nov), sinks GemCrate / GemUpgrade:<id>.
- Whole numbers (9 Nov): fractions (Gem Value) collect in `s.gemDust` and pay whole Gems.
- Shop: a strip under it says how to earn Gems (yellow when you can't afford anything); "+N" pops off
  the GEMS button whenever Gems come in.
  - Gem Pedestal (8 Nov): +1 roll pedestal (a 6th, purple, in front of the roll machine; `C.PedestalSpots[6]`), max 1, 60 Gems.
    `CrusherRules.pedestalCount`. The 6th pedestal only shows after a rebirth.
- Art (8 Nov): Willem's images in `GemConfig.Art` (the image ids behind his decals; decal ids in the comments):
  gem icon (HUD, prices), banner (shop frame, 9-sliced), pink card (crate), crate, upgrade icons, gem pile
  (rebirth), locked sign (Annex gate), Gem Crusher / Awakened.
- Gem Crusher and pickup: see `Gem Mine.md`.
