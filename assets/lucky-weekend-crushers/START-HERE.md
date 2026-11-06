# Lucky Weekend — Blender models and Studio handoff

Willem: send Claude this whole ZIP. You do not need Blender. The three FBX
files are the Studio imports. Blender-Preview.jpg shows the actual models.
Lucky-Weekend-Crushers.blend is the editable source and includes a short
animation preview for all three on frames 1–80. No script needs to be run.

## Import and place the models

1. Read CLAUDE.md, docs/Home.md and the current crusher asset and event code.
   Import each FBX into a staging place in Roblox Studio. Retain individual
   named meshes, and verify the embedded colour textures are imported. The
   separate meshes are the moving assemblies; do not merge them.
2. Follow the current template convention in ServerStorage.SpecialCrusherMeshes.
   Use the exact names CloverOverdrive, HorseshoeComet and JackpotFoundry.
   Stage and test before touching any live assets. Anchor meshes and disable
   collisions/touch/query as with other crusher visuals. Uniformly fit the
   whole model to the current bay envelope and ground it at its base.
3. Model-manifest.json contains the measured open-pose bounds, assembly
   pivots and strike curves. Values are in authored Blender units and axes:
   X right, Y depth, Z up, front toward -Y. Convert them into the imported
   model's basis and scale. Verify yaw in an actual factory bay. If Studio
   recenters MeshParts, reconstruct pivots from the manifest. inputCenter is
   the centre of the open scrap prop, not its floor. Frame is stationary.
   The FBX files contain the open pose; Blender keyframes and preview scrap
   are reference only and are not included in the FBX files.

## Moving assemblies

- **CloverOverdrive:** Jaw_Top, Jaw_Right, Jaw_Bottom and Jaw_Left translate
  directly inward together, then retract. Hold the scrap in the central
  gap. For optional VFX, chase a short green light around the fixed ring
  before impact; the ring itself does not rotate.
- **HorseshoeComet:** SwingArm includes the horseshoe, hinge cap and impact
  star. Move it about the shoulder pivot, with a short backswing and a
  downward strike, then return to rest. A brief cyan impact streak fits
  the comet theme.
- **JackpotFoundry:** Pull Lever, spin Reel_1 through Reel_3 and stop them
  in sequence, then lower StarRam and RamShaft (the shaft travels half as
  far). The reels' symbols are purely visual and do not change earnings,
  odds, or rewards. The Blender preview lines up three stars on impact.

Use the existing strike feedback timing and distance limits. Animate around
the intended pivots and keep the existing output transaction. Do not route
the clover jaws or horseshoe arm through a vertical-only ram path.

## Event integration notes

These are art assets; they do not implement the Lucky Weekend roll pool.
Agreed design direction: show rarity **Limited** and a **Lucky Weekend**
badge in the Index. Make them available from regular rolls while the
existing Lucky Weekend event is active. Reuse its authoritative server
state rather than starting an independent timer. On weekends when the event
returns, the three can roll again. Once found, ownership, equipping and
normal production persist after the event ends. Choose odds/output with
the game's existing balance and show the actual odds in-game. Do not
announce the crushers as rollable until their integration is tested.

Before publishing, check all three in a bay and in roll/Index previews,
watch open/strike/return, verify nearby bay clearance, and verify that the
event pool appears only during the event. Confirm ownership survives
event expiry and rejoin. Keep existing crusher IDs and player saves intact.

All three FBX files were re-imported into Blender to check assembly names,
pivots, triangle counts and embedded textures. The source's motion keys
and the open/contact poses were also checked. Roblox Studio has not been
tested here.

