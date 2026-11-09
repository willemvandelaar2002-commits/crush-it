# Gem Mine (10 Nov 2026)

Willem: "teleporter to a new world with the gem crusher, crushes gems, you have to pick them up". All Gems
come from here (no rebirth payout, no bay trickle). Numbers: `GemConfig.Mine` and the mine upgrades in
`GemConfig.Upgrades`; server `src/server/GemMine.luau`; client `src/client/GemMine.client.luau`; tests in
`Tests/Gems.spec`.

- **Unlock:** rebirth 1 opens it; rebirth 5 **awakens** your Gem Crusher (x1.5 gem value, gold look, announced).
- **Where:** one shared mine in the same place at `CFrame(1800, 0, 0)` (vault: a same-place area beats a
  multi-place teleport for a small game). A teleporter on every plot (front left, `Mine.Teleporter`), locked
  sign "REBIRTH 1 TO UNLOCK" before that. A portal in the middle of the mine sends you home.
- **Six pads**, one per plot, each with your Gem Crusher, your name and a GEM UPGRADES sign (opens the Gem Shop).
- **Crushing:** every 6 s the ram drops 1 gem worth 1 (base 10 Gems a minute). It keeps crushing while you are
  away, up to 40 gems lying on your pad, so there is a reason to come back.
- **Private gems:** only you see your gems (client-rendered in `workspace.MyGems`). Pick up by walking over them;
  the magnet pulls them in from 5 studs. The server checks every pickup (distance <= magnet + 6 slack, max 30
  per second) and refuses the rest (vault: server-validated batched collection).
- **Upgrades** (Gem Shop, listed first; kept through rebirths):
  - Crush Speed: -0.5 s per level, max 6 (3 s), 20 Gems x1.6 per level.
  - More Gems: +1 gem per crush, max 2, 60 / 240.
  - Gem Value: +50% per level, max 2, 80 / 320.
  - Gem Magnet: +3 studs, max 5 (20 studs), 15 Gems x1.6 per level.
  - Everything maxed and awakened: ~180 Gems a minute (the spec keeps it under 220).
  - A purchase takes effect at once (`GemMine.refresh`).
- Gem Crate now costs 250 (was 25), since Gems come in faster.
- Lights at the middle and on every pad, so the mine is readable at night.
- **Stand-ins until Willem's models:** the crusher, teleporter and gem pickups are built from parts.
  To do: the image-to-3D Gem Crusher (Blender pass like the Astral Leviathan), teleporter, gem pickup, scenery.
- **Later:** a capped cash upgrade "Gem Yield" in the normal world; an Auto Walk Robux pass.
- Tested in Studio 10 Nov: teleporter lock/unlock, teleport, crushing every 6 s, pickup (10 walked over = +10),
  sign opens the shop, Magnet 5 -> 8 at once, awakened label at rebirth 5, specs pass.
