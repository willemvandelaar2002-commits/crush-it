# Gem Mine (10 Nov 2026)

Willem: "teleporter to a new world with the gem crusher, crushes gems, you have to pick them up". All Gems
come from here (no rebirth payout, no bay trickle). Numbers: `GemConfig.Mine` and the mine upgrades in
`GemConfig.Upgrades`; server `src/server/GemMine.luau`; client `src/client/GemMine.client.luau`; tests in
`Tests/Gems.spec`.

- **Unlock:** rebirth 1 opens it; rebirth 5 **awakens** your Gem Crusher (x1.5 gem value, gold look, announced).
- **Where:** one shared mine in the same place at `CFrame(1800, 0, 0)` (vault: a same-place area beats a
  multi-place teleport for a small game). A teleporter on every plot (front left, `Mine.Teleporter`), locked
  sign "REBIRTH 1 TO UNLOCK" before that. You arrive on the same portal on your pad; press E on it to go home.
- **One Gem Crusher that everyone uses** (10 Nov, Willem: "just 1 crusher that everyone uses"; later "gem crusher a
  bit further back and then the platform in the front"): the crusher stands at the back (`Mine.CrusherZ` -26), facing
  a raised round **gem platform** in front of it (`Mine.Zone`: radius 16, 1 stud high, gold trim, neon ring, glass
  top with a gold facet star, small crystals round its edge, sparkles). Every gem lands on the platform. One portal
  further in front (`Mine.PortalZ` 42: you arrive on it and press E on it to go home) and a GEM UPGRADES sign
  (navy board, gold frame, a gem on top) beside it.
- **Looks (10 Nov, Willem: "more gem like ... it looks kinda plain"):** dark slate floor with a neon edge, 14
  glowing pink/cyan veins running from the platform to the rim, cave rocks with crystal clusters on the rim, big
  glowing crystal spires (none on the portal side), and floating gems on the left and right that spin and bob on
  your screen. The view from the portal to the crusher is kept clear.
- **Your own pace on a shared machine:** each player's crushes run on their own timer (their upgrades). The
  ram's strike plays on your screen for your crushes only, and once yours is awakened the crusher turns opal
  and reads "YOUR AWAKENED GEM CRUSHER" on your screen only. Everyone's gems are private.
- **Crushing (10 Nov, was 1 gem per 6 s):** every 2 s the crusher drops 1 gem worth 1 (base 30 Gems a minute; Willem:
  "just drop 1 at a time at the start"). Gems are bigger (about 2 studs).
  It keeps crushing while you are away, up to 60 gems waiting, so there is a reason to come back.
- **Private gems:** only you see your gems (client-rendered in `workspace.MyGems`). Pick up by walking over them;
  the magnet pulls them in from 5 studs. The server checks every pickup (distance <= magnet + 6 slack, max 30
  per second) and refuses the rest (vault: server-validated batched collection).
- **Upgrades** (Gem Shop, listed first; kept through rebirths):
  - Crush Speed: -0.25 s per level, max 4 (1 s), 60 Gems x1.6 per level.
  - More Gems: +1 gem per crush, max 2 (3 per crush), 180 / 720.
  - Gem Value: +50% per level, max 2, 240 / 960.
  - Gem Magnet: +3 studs, max 5 (20 studs), 45 Gems x1.6 per level.
  - Everything maxed and awakened: 540 Gems a minute (the spec keeps it under 750).
  - A purchase takes effect at once (`GemMine.refresh`).
- 10 Nov: Gem prices are x3 the pre-mine prices (base 30 a minute, was 10): Gem Crate 750, Cash/Luck 45, Head Start
  120, Nest Egg 75, Quick Rolls 60, Gem Pedestal 180 (the next level still x growth). (x6 for one evening at 60/min.) Dev panel Gems +100/+1000/+10000.
- Lights over the crusher and the portal, so the mine is readable at night.
- **Mine sky (10 Nov, Willem: "you can still see the normal plots from a distance"):** while you are in the mine your
  sky is a starry purple night with a dense haze (local Sky + Atmosphere, `GemMine.client`), so the factories fade
  out; your normal sky comes back when you leave. A factory event's night, if already on, is left alone. Lag: the
  plots already stream out there (26,000 -> ~4,000 parts on the client after 20 s; the persistent `World` model,
  ~2,200 parts, stays), so the sky is mostly about the look.
- **Willem's models (10 Nov):** ChatGPT + Blender pack (GemCoreColossus crusher 12k triangles: Frame 9k, Ram 3k,
  two 60-triangle pistons; teleporter pad 1.3k; pickup gem 46; crystal clusters and cave rocks 20-130). Checked in
  Blender: clean, within the vault's budget for one shared hero machine (Triangle Budget: 20k per mesh hard cap).
  They go in `ReplicatedStorage.GemMineMeshes` (place file, not Git): GemCrusher (Model: Frame, Ram, Piston_L,
  Piston_R; attributes Strike, Height), TeleporterPad, GemPickup, CrystalClusterSmall/Large, CaveRockSmall/Wide/Tall.
  Missing ones fall back to the part-built stand-ins.
  Imported 10 Nov by Willem (3D Importer), prepared by Claude: the importer brings them in at 100x (cm) with a
  pivot turned 90 degrees, so they were scaled (crusher 22 studs tall, 24 x 13 footprint, strike 1.39 studs; pad
  9 studs; pickup 1 stud; rocks 4-8, crystals 3.7-4.6 before the random 1.6-3.5x), turned upright and given a
  plain pivot (crusher: bottom centre, front -Z). Pistons coloured gold. Frame and rocks collide as boxes; the
  ram, pistons, crystals and pickups don't. The crusher streams in whole (Atomic). Zone widened to 15-27 studs.
  **Willem must Save to Roblox: the models are only in the place file.** Awakened look: a recoloured texture
  (GemCrusher_Color_Awakened.png, made by Claude: pink crystals -> light blue/white; `docs/art/`), swapped on your
  screen only via `GemMineMeshes.AwakenedLook` (a SurfaceAppearance). Until that exists: an opal glow (Highlight).
- **Stand-ins until Willem's models:** the crusher, teleporter and gem pickups are built from parts.
  To do: the image-to-3D Gem Crusher (Blender pass like the Astral Leviathan), teleporter, gem pickup, scenery.
- **Later:** a capped cash upgrade "Gem Yield" in the normal world; an Auto Walk Robux pass.
- Tested in Studio 10 Nov: teleporter lock/unlock, teleport, crushing every 6 s, pickup (10 walked over = +10),
  sign opens the shop, Magnet 5 -> 8 at once, awakened label at rebirth 5, specs pass.
- Tested 10 Nov (second pass): arrive on your portal, 20 gems all inside the zone, walking the zone gave +34 in 4 s,
  E on the portal sends you home, specs pass.
- Tested 10 Nov (third pass, one shared crusher): all gems land in the zone, the ram strikes at your pace, a lap
  round the zone picked up 24, rebirth 5 turns it opal with the awakened label, E on the portal sends you home, specs pass.
