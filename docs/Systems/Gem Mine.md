# Gem Mine (10 Nov 2026)

Willem: "teleporter to a new world with the gem crusher, crushes gems, you have to pick them up". All Gems
come from here (no rebirth payout, no bay trickle). Numbers: `GemConfig.Mine` and the mine upgrades in
`GemConfig.Upgrades`; server `src/server/GemMine.luau`; client `src/client/GemMine.client.luau`; tests in
`Tests/Gems.spec`.

- **Unlock:** rebirth 1 **and FACTORY IV** (the rear yard) in the current run (11 Nov, Willem: "minimum plot 3 and
  rebirth 1 ... the one where you get that plot upgrade and the back is visible"; `GemConfig.UnlockPlot` 3 /
  `G.mineOpen`); the Gem Shop still opens at rebirth 1. Rebirth 5 **awakens** your Gem Crusher (x1.5 gem value,
  opal look, announced). Reaching Factory IV with a rebirth says "The GEM MINE is open! Its portal is in your rear
  yard."; a rebirth before that says it opens at Factory IV.
- **The portal (11 Nov, Willem: "probably a portal is better for it instead of a pad on the ground"):** a standing
  ring on the teleporter pad: 24 gold blocks with a pink neon band, three cyan gems, a ForceField swirl with
  sparkles and a pink glow; E on the swirl. On your plot it stands on the rear yard road (plot-local 0, -108) facing
  down the road, and only shows once you have Factory IV (before a rebirth it says "REBIRTH 1 + FACTORY IV TO
  UNLOCK"). The mine's way home is the same portal. Tested in Play: hidden at Factory III, shown at IV, opens with
  rebirth 1; dev /plot now refreshes it.
- **Where:** one shared mine in the same place at `CFrame(1800, 0, 0)` (vault: a same-place area beats a
  multi-place teleport for a small game). A portal on every plot (11 Nov: in the rear yard, `Mine.Teleporter`). You arrive on the same portal on your pad; press E on it to go home.
- **One Gem Crusher that everyone uses** (10 Nov, Willem: "just 1 crusher that everyone uses"; later "gem crusher a
  bit further back and then the platform in the front"): the crusher stands at the back (`Mine.CrusherZ` -26), facing
  a raised round **gem platform** in front of it (`Mine.Zone`: radius 22 since 10 Nov (was 16), centre 5 studs forward, 1 stud high, gold trim, neon ring, glass
  top with a gold facet star, small crystals round its edge, sparkles). Every gem lands on the platform. One portal
  further in front (`Mine.PortalZ` 42: you arrive on it and press E on it to go home) and a GEM UPGRADES sign
  (navy board, gold frame, a gem on top; the words printed on the board) beside it.
- **Looks (10 Nov, Willem: "more gem like ... it looks kinda plain"):** a polished amethyst tile floor (10 Nov, third try: slate was plain, studs looked unfinished):
  ~200 diamond-set tiles in two tones (Glass, a little reflectance) over a dark violet neon base that glows through
  the 0.7-stud joints; none under the gem platform; a neon edge, cave rocks with crystal clusters on the rim, big
  glowing crystal spires (none on the portal side), and floating gems on the left and right that spin and bob on
  your screen. The view from the portal to the crusher is kept clear.
- **Your own pace on a shared machine:** each player's crushes run on their own timer (their upgrades). The
  ram's strike plays on your screen for your crushes only, and once yours is awakened the crusher turns opal
  and reads "YOUR AWAKENED GEM CRUSHER" on your screen only. Everyone's gems are private.
- **Crushing (10 Nov, was 1 gem per 6 s):** every 2 s the crusher drops 1 gem worth 1 (base 30 Gems a minute; Willem:
  "just drop 1 at a time at the start"). Gems are bigger (about 2 studs).
- **Pickup sound (10 Nov):** a crystal ding per gem (`Config.Sounds.GemPickup`, Creator Store "gem_pickup"
  4612375233), in the Sounds volume group. Quick pickups in a row climb in pitch (+4% each, up to 12); a gem worth
  more rings a bit lower and louder; at most one ding per 0.05 s. Tested: 7 gems gave 5 dings climbing 1.00 -> 1.16.
  10 Nov evening (Willem: "a little too loud and have a delay"): volume .45 -> .22; six copies made and preloaded
  up front and used in turn (a new Sound per ding had to load first, ~0.3 s); each ding starts 0.07 s into the
  file (measured with an AudioAnalyzer: it swells in and peaks ~0.13 s in).
  It keeps crushing while you are away, up to 60 gems waiting, so there is a reason to come back.
- **Private gems:** only you see your gems (client-rendered in `workspace.MyGems`). Pick up by walking over them;
  the magnet pulls them in from 5 studs. The server checks every pickup (distance <= magnet + 6 slack, max 30
  per second) and refuses the rest (vault: server-validated batched collection).
- **Upgrades** (Gem Shop, listed first; kept through rebirths). 11 Nov (Willem: "the numbers should go higher and then
  the value lower. a max of 2 seems very low for more gems"): more, smaller levels, the same totals at the max and about
  the same Gems to get there; old levels convert once (x5, the magnet x3; `gemUpsV` 2, tested on an old save):
  - Crush Speed: -0.05 s per level, max 20 (1 s), 6 Gems x1.15 per level (613 to max).
  - More Gems: +0.2 gems per crush, max 10 (+2), 16 Gems x1.35 (874 to max). The fraction is the chance of one more
    gem in a crush (level 3 = 1.6 gems on average).
  - Gem Value: +10% per level, max 10 (x2), 22 Gems x1.35 (1,202 to max).
  - Gem Magnet: +1 stud per level, max 15 (20 studs), 10 Gems x1.2 (720 to max).
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
  **Willem must Save to Roblox: the models are only in the place file.** Awakened look (10 Nov): Willem's ChatGPT pack "Awakened Gem
  Crusher" (same geometry, white opal / pastel rainbow crystals, navy and gold kept). Only its SurfaceAppearance is
  used: `GemMineMeshes.AwakenedLook` (colour rbxassetid://72609987677019), swapped onto Frame and Ram on your screen
  only from rebirth 5 (the normal one comes back below 5; tested both ways). Without it: an opal glow (Highlight).
  Claude's earlier recolour (`docs/art/GemCrusher_Color_Awakened_1024.png`) is not used.
- **Stand-ins:** without Willem's models (GemMineMeshes) the crusher, teleporter and gem pickups are built from parts.
- **Bigger (11 Nov, Willem: "make the gem area bigger ... now i can just stand in the middle and i will get all of
  the gems ... the total area bigger as well then and the crusher too"):** platform radius 22 -> 38 (centre 8 studs
  forward; 3x the area: a maxed 20-stud magnet covers about a quarter of it from the middle, the base 5 studs ~2%),
  floor radius 70 -> 100 (bigger tiles, 252 of them; 30 rim rocks), Willem's crusher x1.5 (`Mine.ModelScale`: 36 x 33
  x 20 studs, its strike grows with it) at z -46, the portal at z 60. Gems fly out in a higher, slightly longer arc.
  Tested in Play: standing in the middle with magnet 5 got nothing in 30 s; walking to 39 gems picked up 38 (the
  last one had just landed); specs pass.
- **Vault check (11 Nov, Collectible Pickup FX, Economies and Currencies, AFK reward rules):** already right: the server
  owns the records, gems are client-only and private, pickups are batched (40 max, every 0.12 s) and checked by
  distance and rate, waiting gems are capped (60) so being away pays a little, not a lot. Fixed: the client now asks
  the server when a gem starts flying to you, not when it arrives (the vault's "laggy players fail validation"
  mistake); the ding still plays on arrival. The server no longer sends an empty message every crush while your mine
  is full. Left as is: gems are destroyed instead of pooled (at most 60, fine).
- **Upgrade caps grow with rebirths (11 Nov, Willem: "if the vault says that yes"; vault Progression and Pacing: each
  rebirth should bring something new to aim for, every category capped on its own):** every 5 rebirths raises the max
  of More Gems and Gem Value by 5 levels (+1 gem, +50%) and Gem Magnet by 3 (+3 studs), at most twice (rebirth 10):
  More Gems 10 -> 20 (5 a crush), Gem Value 10 -> 20 (x3), Magnet 15 -> 21 (26 studs). Crush Speed stays at 20 (1 s).
  `GemConfig.RebirthCap`, `G.maxLevel(u, rebirths)`; the server checks the level against your rebirths; old saves
  keep levels up to the highest possible max. The Gem Shop shows "Level 10 / 15" and, once maxed, "(+1 at rebirth 10)".
  Worst case at rebirth 10, all maxed and awake: 1,350 Gems a minute (was 540); the extra levels cost about 17.5k
  (More Gems) and 24k (Gem Value) Gems in all, 1.5k for the magnet. Spec: 8 new checks.
- **AUTO WALK (11 Nov, Willem; game pass 2079272256, R$ 49, `Store` perk AutoWalk, hidden from the shop list):** in the
  mine you walk to your nearest waiting gem by yourself, gem after gem (`Humanoid:MoveTo`, client/GemMine). Steering
  yourself pauses it for a second (seen as walking another way than Auto Walk sent you; this game has no standard
  PlayerModule). Same magnet and server checks as walking yourself. Sold by a board left of the portal (the same look
  as the GEM UPGRADES sign, a pink gem on top): not owned, E or a click opens the pass purchase and the board shows
  the price; owned, it switches Auto Walk on and off (attribute AutoWalkOn, on by default) and shows ON / OFF.
  Tested in Play: switched on it walked from the portal and picked up 9 gems in 12 s; off, or without the pass, it
  stays still; the board shows the price / ON; specs pass.
- **Later:** a capped cash upgrade "Gem Yield" in the normal world.
- Tested in Studio 10 Nov: teleporter lock/unlock, teleport, crushing every 6 s, pickup (10 walked over = +10),
  sign opens the shop, Magnet 5 -> 8 at once, awakened label at rebirth 5, specs pass.
- Tested 10 Nov (second pass): arrive on your portal, 20 gems all inside the zone, walking the zone gave +34 in 4 s,
  E on the portal sends you home, specs pass.
- Tested 10 Nov (third pass, one shared crusher): all gems land in the zone, the ram strikes at your pace, a lap
  round the zone picked up 24, rebirth 5 turns it opal with the awakened label, E on the portal sends you home, specs pass.
- **Music (10 Nov):** the mine has its own song slot, `GemConfig.Mine.Music` (0 = the normal music keeps playing).
  In the mine it fades in and the normal/event music pauses; it resumes when you leave. It is in the Music volume
  group in Settings. The song: Willem's Suno track, rbxassetid://129703295050685 (2:44, loops; tested 10 Nov:
  plays in the mine at 0.3, the normal music pauses and resumes at home).

- **Willem's gem cave props (11 Nov):** GemPortalRing, GemSignBoard, GemPlatformEdgeSegment and GemPlatformEdgePlain
  in ReplicatedStorage.GemMineMeshes (imported at 100x: scaled to 0.01, pivots set to the authored ground centre, front
  -Z; the rim's pivot is the platform centre). The portal (mine and rear yards) is the ring with its own base, an
  invisible flat Pad collider, the existing Swirl/SwirlCore (7.9 across, centred 5.85 up), prompt and labels; on the
  plots the ring is turned so its gold front faces the road. Both boards are GemSignBoard clones (Panel renamed
  UpgradeSign / AutoWalkSign, front text on the panel, back text on an invisible board behind the frame). The platform
  edge is twelve 30-degree arcs (two plain ones toward the portal) instead of the gold cylinder; the crystal clusters
  moved out to radius 41.4. All props are non-colliding. Without the templates the old code-built look is used.
- **AUTO WALK button (11 Nov, Willem):** while you are in the mine an AUTO WALK button sits above the hotbar
  (client/GemMine): owned = ON / OFF (tap to switch), not owned = BUY AUTO WALK (the server prompts the pass). It
  does the same as the board (remote GemMine "autoWalk"); the board stays.
- 11 Nov (later): the AUTO WALK button uses the AUTO ROLL button art (green = ON), 164 x 70, words AUTO WALK / ON, OFF or BUY.
- **GEM CHEST (11 Nov, Willem: "put the chest physically in the cave. then you buy 1 key, and open it with the key"):**
  the Gem Crate is now a chest in the mine beside the GEM UPGRADES board (code-built: navy box, gold bands, pink lock,
  a lid that opens with a burst of sparkles). GEM UPGRADES sells a **key** (rule `GemKey`, 750 Gems, up to 99 kept in
  `crushers.gemKeys`, attribute GemKeys); E at the chest (rule `GemCrate`, server reach 16 studs) uses one key for one
  crusher at the same odds as before. Without a key the prompt says "Needs a key". Tested in Play: key bought, chest
  opened, a Secret came out, the key was used.
- **Gem Chest reveal (11 Nov, Willem: "make the chest reveal more special"):** client/GemChest. The opener: camera to
  the chest, it shakes and glows in the prize's rarity colour (longer for rarer), a white flash and fanfare, the lid
  flies open with a beam of light and sparkles, and the crusher rises on screen on a sunburst with "LEGENDARY!" and
  its name (bigger show from Exotic, Secret, Divine). Everyone near sees the lid and beam. The server sends only the
  result (GemMine remote kinds chestOpen / chestReveal); the "Gem Chest: ..." notice is skipped and the server-wide
  announcement (Exotic+) waits 3.4 s. The lid turns about the chest's Hinge attribute: Willem's chest model needs a
  separate lid part (named Lid or ChestLid) and its hinge edge. Checked in Play: a Legendary reveal, all restored after.

## 11 Nov: Willem's Gem Chest model (assets/gem-chest)
- Template `ReplicatedStorage.GemMineMeshes.GemChest` (place file, not in Git): MeshParts ChestBody, ChestGlow (still),
  ChestLid + LidGlow (move), scaled to studs (9.28 x 7.47 x 6.46), front -Z, ground-centre pivot, attribute
  `Hinge` = CFrame(0, 4.26, 2.70) relative to the pivot (the rear hinge). Mesh colours white (SurfaceAppearance).
- server/GemMine clones it at the old spot (portalAt * (21,0,-9), 35 degrees). Meshes don't collide; an invisible
  `ChestHitbox` (8.4 x 4.6 x 5.4) collides and carries GemChestPrompt, the GEM CHEST label (6.6 up, clears the crown)
  and the reach check (M.chestPart). Without the template the old block chest is built.
- client/GemChest: lid + crown turn together about the hinge, OPEN_ANGLE +100 degrees (the old -115 swung the lid
  down into the box). Verified in Studio: lid centre goes 1.4 up / 3.9 back, crown stays on the lid, returns to the
  exact closed pose; key used, reward given (GemCrate unchanged).
