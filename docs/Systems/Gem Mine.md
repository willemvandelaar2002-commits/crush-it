# Gem Mine (10 Nov 2026)

Willem: "teleporter to a new world with the gem crusher, crushes gems, you have to pick them up". All Gems
come from here (no rebirth payout, no bay trickle). Numbers: `GemConfig.Mine` and the mine upgrades in
`GemConfig.Upgrades`; server `src/server/GemMine.luau`; client `src/client/GemMine.client.luau`; tests in
`Tests/Gems.spec`.

- **Unlock:** rebirth 1 opens it; rebirth 5 **awakens** your Gem Crusher (x1.5 gem value, gold look, announced).
- **Where:** one shared mine in the same place at `CFrame(1800, 0, 0)` (vault: a same-place area beats a
  multi-place teleport for a small game). A teleporter on every plot (front left, `Mine.Teleporter`), locked
  sign "REBIRTH 1 TO UNLOCK" before that. You arrive on the same portal on your pad; press E on it to go home.
- **One Gem Crusher that everyone uses** (10 Nov, Willem: "just 1 crusher that everyone uses"): a big
  stand-in crusher (1.8x the bay size) in the middle, a glowing pickup zone around it where the gems land
  (between 13 and 25 studs from it, `Mine.Zone`), a rim of rocks and crystals, one portal (`Mine.PortalZ`: you
  arrive on it and press E on it to go home) and a GEM UPGRADES sign beside it (opens the Gem Shop).
- **Your own pace on a shared machine:** each player's crushes run on their own timer (their upgrades). The
  ram's strike plays on your screen for your crushes only, and once yours is awakened the crusher turns opal
  and reads "YOUR AWAKENED GEM CRUSHER" on your screen only. Everyone's gems are private.
- **Crushing (10 Nov, was 1 gem per 6 s):** every 2 s the ram drops 2 gems worth 1 (base 60 Gems a minute).
  It keeps crushing while you are away, up to 60 gems waiting, so there is a reason to come back.
- **Private gems:** only you see your gems (client-rendered in `workspace.MyGems`). Pick up by walking over them;
  the magnet pulls them in from 5 studs. The server checks every pickup (distance <= magnet + 6 slack, max 30
  per second) and refuses the rest (vault: server-validated batched collection).
- **Upgrades** (Gem Shop, listed first; kept through rebirths):
  - Crush Speed: -0.25 s per level, max 4 (1 s), 120 Gems x1.6 per level.
  - More Gems: +1 gem per crush, max 2 (4 per crush), 360 / 1440.
  - Gem Value: +50% per level, max 2, 480 / 1920.
  - Gem Magnet: +3 studs, max 5 (20 studs), 90 Gems x1.6 per level.
  - Everything maxed and awakened: 720 Gems a minute (the spec keeps it under 750).
  - A purchase takes effect at once (`GemMine.refresh`).
- 10 Nov: with 6x the Gems, every Gem price went x6: Gem Crate 1500, Cash/Luck 90, Head Start 240, Nest Egg 150,
  Quick Rolls 120, Gem Pedestal 360 (the next level still x growth). Dev panel Gems +100/+1000/+10000.
- Lights over the crusher and the portal, so the mine is readable at night.
- **Stand-ins until Willem's models:** the crusher, teleporter and gem pickups are built from parts.
  To do: the image-to-3D Gem Crusher (Blender pass like the Astral Leviathan), teleporter, gem pickup, scenery.
- **Later:** a capped cash upgrade "Gem Yield" in the normal world; an Auto Walk Robux pass.
- Tested in Studio 10 Nov: teleporter lock/unlock, teleport, crushing every 6 s, pickup (10 walked over = +10),
  sign opens the shop, Magnet 5 -> 8 at once, awakened label at rebirth 5, specs pass.
- Tested 10 Nov (second pass): arrive on your portal, 20 gems all inside the zone, walking the zone gave +34 in 4 s,
  E on the portal sends you home, specs pass.
- Tested 10 Nov (third pass, one shared crusher): all gems land in the zone, the ram strikes at your pace, a lap
  round the zone picked up 24, rebirth 5 turns it opal with the awakened label, E on the portal sends you home, specs pass.
