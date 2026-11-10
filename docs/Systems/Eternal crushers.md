# Eternal crushers (proposed tier, not in the game yet)

Six models planned (ChatGPT pack 8 Nov: ChronoColossus, Worldbreaker, InfinityEngine, AstralLeviathan,
RiftMonarch, RealitySplitter): a rollable tier above Divine, below Mythic. **Not added:** no rarity,
odds, types, Index entries or economy yet; that waits for Willem's call on the tier.

## Astral Leviathan (9 Nov), the first upgraded model
- Source: Hunyuan3D image-to-3D prototype of Willem's concept (100k faces, 4K PBR).
- Claude's Blender pass (Blender 5.2 via the Blender MCP on Willem's PC):
  welded the generator's split mesh, cut the upper head free at the gold cheek hinge (straight planes,
  both gold discs stay on the Frame), filled the cuts with the armour navy, removed a floating sliver,
  decimated to Frame 6,000 + UpperJaw 3,000 triangles, colour texture 4K -> 1024.
- Motion: the head rests tipped 12 degrees up (baked into the FBX) and bites 32 degrees down about the
  hinge, where upper and lower teeth meet. Input sits in the mouth (`inputCenter`, size 0.32).
- Files: Willem's PC, Downloads\CrushIt-Coating-and-Plot-Props\AstralLeviathan (FBX, PNG, game-ready
  .blend with the prototype hidden inside, manifest.json, previews).
- Studio: template `ServerStorage.SpecialCrusherMeshes.AstralLeviathan` (Willem's import, cm scale,
  place file: **Willem must publish**). Metadata `shared/EternalCrusherAssets.luau` (motion format).
- Test: DEV panel "Eternal preview (bay 1)": Astral Leviathan / Clear. Checked in Play: textured, faces
  the walkway, fit 1.57 (9.4 studs tall), the head swings 0 -> 32 degrees down every 2 s, no errors.

## The other five (10 Nov)
- Source: Willem's ChatGPT pack "Eternal Five" (Hunyuan3D image-to-3D, already reduced to 3,000 triangles
  each, 1024 colour textures). Each came as one fused piece.
- Claude's pass (Blender 5.2 in the cloud workspace, `bpy`): straight cuts only around the moving parts,
  every cut capped with a navy texel of the model's own texture, stray chips dropped, back to ~3,200
  triangles each (Frame + moving parts). Rest/hit renders checked before export.
  - ChronoColossus: `UpperPress` (crystal + gold collar under the cyan band) slides 0.32 down onto the lower crystal.
  - Worldbreaker: `Boulder` (boulder, collar, upper arm) swings 17 degrees down about the elbow bolt onto the
    lava anvil (24 clipped into the arm).
  - InfinityEngine: `Crossbar` (bar + its crystal) presses 0.32 down onto the white anvil.
  - RiftMonarch: `UpperClaw` closes 10 degrees down, `LowerClaw` 10 degrees up, around the palm.
  - RealitySplitter: `LeftJaw`/`RightJaw` tip 9 degrees inward about the gold axle; the scrap floats between
    their inner spikes.
- Files: Willem's PC, Downloads\CrushIt-Coating-and-Plot-Props\Eternal\<Id> (FBX, game-ready .blend with the
  high source hidden inside, manifest.json, Rest-and-Hit.png).
- Studio: Willem imported the five FBX files; Claude moved them to `ServerStorage.SpecialCrusherMeshes.<Id>`
  with the Leviathan's settings (anchored, no collision, Box fidelity, attribute Eternal) and the pivot at
  the bottom centre (no PrimaryPart, like the Leviathan). **Place file: Willem must save.**
- Metadata in `shared/EternalCrusherAssets.luau` (motion format; `bedTop` is required by the build).
- Test (Play, DEV "Eternal preview" rows, bay 1): all five face the walkway at fit 1.57, no errors.
  Chrono and Infinity press 0.50 studs; Worldbreaker turns 17 degrees, boulder 0.84 down; Rift upper claw
  0.28 down / lower 0.24 up; Reality jaws' tops close from ~2.2 to ~1.2 studs off the middle.

## The Eternal tier (10 Nov)
Willem: "more rare than divine, we just needed new crushers. so cooler animation than divine".
- `C.Rarities`: **Eternal**, between Divine and Mythic (Mythic stays last and strongest). Weight .0002 (taken from
  Common): 1 in 500,000 rolls for any Eternal, 1 in 3,000,000 for each of the six, before luck (Divine: 1 in
  125,000 / 500,000). rank 6.5 (luck and pity), price 30M, mult 2.5, colour lavender-white (205,185,255).
- `C.EternalTypes`: the six (AstralLeviathan, ChronoColossus, Worldbreaker, InfinityEngine, RiftMonarch,
  RealitySplitter), appended after the Exotics so older catalogue indexes stay put; Quantum band, value 580 per
  input (Divine 500, Mythic 660). Row bonus .57, factory event points 7.5, objects Ship/Planet.
- Looks: bay glow (`C.SpecialBay.Eternal`: cosmic violet + starlight, shafts) and plaque colours, a card look
  (`client/CardFx`: deep space violet, starlight rim, halo), Index tint, row colour, Auto Roller (in the list and
  ticked by default; its tab/card art uses the grey art with a tint until Willem makes coloured ones).
- Index icons: Willem bulk-imports `Downloads\CrushIt-Coating-and-Plot-Props\Eternal\Icons` (Crusher_<Id>.png,
  the Leviathan's rendered by Claude in the same style as ChatGPT's five); `CrusherIcons.Ready` loads them by name.
- **Big roll cinematic** (`client/BigRoll`, `C.BigRoll.Eternal` Hold 9 s, longer than Divine's 6.4): darker and
  violet; a white-hot crack tears open over the pedestal, three portal rings (violet, cyan, white) spin up on
  different axes, twelve crystal shards orbit faster and faster while stars stream in, the camera slowly circles;
  then everything collapses into the rift, the screen goes black, and the crusher bursts out: white flash, two
  shockwaves, ten light rays, a rainbow supernova and drifting starlight. The ETERNAL title shimmers.
- Server-wide aftershock: x2 luck for 45 s (Divine: x1.5 for 30 s); the banner names the rarity.
- Test: DEV "Big roll" -> Eternal (or `/bigroll eternal`). Checked in Play: the roll gives an Eternal with the
  cinematic, 87 effect parts during the build-up, no errors, everything cleaned up after (HUD, camera, dimming).
  Studio's screen capture does not draw the 3D world during big rolls (Divine too), so Willem judges the look.
