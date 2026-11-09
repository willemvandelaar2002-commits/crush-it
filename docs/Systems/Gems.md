# Gems

Second currency for players who have rebirthed (added 8 Nov 2026). Numbers live in
`src/shared/GemConfig.luau`, rules in `CrusherRules` (`Rebirth`, `GemUpgrade`, `GemCrate`, `gemRate`),
UI in `src/client/GemShop.client.luau`, tests in `Server/Tests/Gems.spec.luau`.

- **Job:** progress after the first rebirth. Never sold for Robux, so the crate is not a paid random item (odds still shown).
- **Faucet:** each rebirth pays `10 + 5 * (n - 1)` (10, 15, 20 … 55 at rebirth 10), plus `FirstBonus` 15 at rebirth 1 (so 25: the first visit can buy the crate or an upgrade; 9 Nov). Trickle per crusher in a bay: Exotic 0.1, Mythic 0.15, Secret 0.25, Divine 0.5 per minute.
- **Sink, the Gem Shop** (GEMS button in the HUD row after REBIRTH, shown from rebirth 1):
  - Gem Crate, 25 Gems: Legendary 60% / Exotic 30% / Secret 8% / Divine 2%, Standard finish, refused when the inventory is full. Exotic+ results are announced server-wide.
  - Gem Cash and Gem Luck: +10% per level, max 10, cost `15 * 1.5^level`.
  - Quick Rolls: roll cooldown -0.25 s per level (never below 1 s), max 4, cost `20 * 2^level`.
- Gems and upgrades survive every rebirth.
- Analytics: custom `GemsEarned`, `GemUpgrade`, `GemCrate`; since 9 Nov also economy events in currency
  **"Gems"** (`Analytics.gems`): sources Rebirth / Bays (trickle), sinks GemCrate / GemUpgrade:<id>.
- Whole numbers (9 Nov): the trickle collects in `s.gemDust` and pays whole Gems.
- Shop: a strip under it says how to earn Gems (yellow when you can't afford anything); "+N" pops off
  the GEMS button whenever Gems come in.
  - Gem Pedestal (8 Nov): +1 roll pedestal (a 6th, purple, in front of the roll machine; `C.PedestalSpots[6]`), max 1, 60 Gems.
    `CrusherRules.pedestalCount`. The 6th pedestal only shows after a rebirth.
- Art (8 Nov): Willem's images in `GemConfig.Art` (the image ids behind his decals; decal ids in the comments):
  gem icon (HUD, prices), banner (shop frame, 9-sliced), pink card (crate), crate, upgrade icons, gem pile
  (rebirth), locked sign (Annex gate), Gem Crusher / Awakened.
- Gem Crusher: see `Gem Crusher.md`.
