# Hub plaza (factory centre)

24 Oct: Daily Spin is now active through its existing station's E prompt; the
remaining station descriptions below retain their historical placeholder status.
See [[Daily Spin]] for images, rewards, cooldown and persistence checks.

22 Oct 2026, from Willem's "hub reference" (`Reference/Our goal/hub reference.png`).
Built by `server/HubPlaza.luau`, called from `Hub.luau` (station). Everything
sits inside the train loop (r < 172); +Z is the south spoke (spawn side).

- **Floor:** plaza blue (inner disc r 56, rest of the commons to the road), dark
  blue spokes from r 52 out to the road, yellow ring line at r 64. The old
  commons work bays (vehicles, containers, workshop), scrap display, CRUSH IT
  entrance arch, curbs and cross paths are gone; the planters at r 154 stay.
- **Stage:** three walkable tiers (r 50 / 43 / 36, 1.4 high each) with yellow
  edge lines, a yellow rail with beacons round the top, open at the 4 spokes.
- **Mega Crusher** (tag `MegaCrusher`, scale 1.45): navy towers, chrome guide
  pillars, orange hydraulics with blue hoses, red top beam with a yellow gear,
  navy ram with hazard band. Parts in `RamParts` move with the ram
  (client/Mega.client picks them up as they stream in). A toy dump truck and
  bricks on the bed squash every 7 s. "MEGA CRUSHER" sign at the south foot.
- **AI meshes (22 Oct):** when `ServerStorage.HubMeshes` has MegaFrame, MegaRam
  and MegaTruck (Roblox AI generate_mesh, place-only: Publish to keep them),
  the Mega Crusher uses them instead of parts: frame scaled 1.35 on the stage,
  the ram's mesh (head + rod) is the moving "Ram", the truck (x1.7) squashes.
  Frame attributes BedTop 5 / BarBottom 37.6 (studs above its bottom, unscaled).
  Without the folder the part-built crusher is used.
- **Willem's Mega Crusher model (23 Oct):** `HubMeshes.MegaCrusherModel`
  (moved from Workspace "MegaCrusher-Roblox"; Frame_*, Platform_* incl. its own
  MEGA CRUSHER sign, Ram, PistonRod). Takes priority over the AI frame: scaled
  1.8, turned 180° (its sign faced -Z), Ram slams, PistonRod sits in
  "RamStretch" and stretches between the beam and the ram (client), the AI toy
  truck squashes on Frame_Bed. Attribute BedTop 5.72 (unscaled). The code sign
  is skipped when the model has its own (OwnSign).
- **Station meshes (22 Oct):** HubMeshes also holds Station_DailySpin,
  Station_TopCrushers, Station_Quests, Station_Boosts (scaled to their base
  widths 14/27/17/14), Prop_Pedestal (Special Crushers display, glass dome and
  the imported GoldenKing on top), Prop_Tree (2 per station) and Prop_Lamp
  (both sides of every spoke). Signs and COMING SOON plates stay code-built for
  sharp text. Stations face the nearest spoke walkway. Missing meshes fall back
  to the part-built versions.
- **Props pass (23 Oct, `HubPlaza.dress`):** yellow stair nosing, rails and
  lamps at the 4 stage openings; a pad with a yellow outline under every
  station with bricks at its corners; 26 clusters of big studded toy bricks
  (scale 2.6-3.2, some stacked) kept 26 studs off the spokes and 10 off the
  pads; AI cactus/bush pots (Prop_Cactus, Prop_Bush) by the stairs and
  stations; crossing shelters (yellow studded roof, hazard barrier, lamps) on
  both sides of every spoke near the railway. Spoke lamps are now code lamps
  (navy post, yellow light) like the reference.
- **Stations** (placeholders, attribute `Placeholder`, sign + COMING SOON),
  facing out toward the road, scale 1.8 (Top Crushers 1.45):
  Boosts 35° r112 (purple vending machine, 3 cans) · Quests 325° r112 (booth,
  foreman, notice board) · Special Crushers 135° r114 (press under a glass dome)
  · Top Crushers 215° r116 (3 boards with crowns, trophy) · Daily Spin 250° r108
  (red gear wheel with 6 coloured segments).
- **Spawn:** HubSpawn moved to (0, 80) in front of the stage.

Next: gameplay for the stations (daily spin rewards, quests, boosts, special
crushers, leaderboards); a shared Mega Crusher server event.
Known gap: the Special Crushers press keeps its normal colours (meant to be gold).

## Travel buttons

`client/Travel.client.luau` adds two buttons at the top centre: **Mega Crusher** (hub, arrives at (0, `C.HubTravelZ`) facing the stage) and **My Factory** (your plot spawn). The server handles `Net "Travel"` in CrusherGame ("Hub" | "Plot"), with `C.TravelCooldown` between trips, using `G.safeTeleport` so you never fall through unstreamed floors.
