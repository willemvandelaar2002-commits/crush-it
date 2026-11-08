# Gems

Second currency for players who have rebirthed (added 8 Nov 2026). Numbers live in
`src/shared/GemConfig.luau`, rules in `CrusherRules` (`Rebirth`, `GemUpgrade`, `GemCrate`, `gemRate`),
UI in `src/client/GemShop.client.luau`, tests in `Server/Tests/Gems.spec.luau`.

- **Job:** progress after the first rebirth. Never sold for Robux, so the crate is not a paid random item (odds still shown).
- **Faucet:** each rebirth pays `10 + 5 * (n - 1)` (10, 15, 20 … 55 at rebirth 10). Trickle per crusher in a bay: Exotic 0.1, Mythic 0.15, Secret 0.25, Divine 0.5 per minute.
- **Sink, the Gem Shop** (GEMS button in the HUD row after REBIRTH, shown from rebirth 1):
  - Gem Crate, 25 Gems: Legendary 60% / Exotic 30% / Secret 8% / Divine 2%, Standard finish, refused when the inventory is full. Exotic+ results are announced server-wide.
  - Gem Cash and Gem Luck: +10% per level, max 10, cost `15 * 1.5^level`.
  - Quick Rolls: roll cooldown -0.25 s per level (never below 1 s), max 4, cost `20 * 2^level`.
- Gems and upgrades survive every rebirth.
- Analytics: `GemsEarned`, `GemUpgrade`, `GemCrate`.
- Art still to swap in (`GemConfig.Icon` = 0 shows the built-in diamond): Gem icon, crate art, upgrade icons.
