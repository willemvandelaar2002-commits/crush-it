# START HERE — Exotic crushers

Willem: give Claude this whole ZIP. No Blender installation or script-running
is required. This contains six models, their actual rendered icons and the
code integration patch. It is not yet published to your live game.

## Claude — apply and import

1. Read CLAUDE.md and docs/Home.md. The patch was built against main commit
   adc03e0 (8 Nov: Auto Buy pass id 2074912226). Run:
       git apply --check exotic-integration.patch
       git apply exotic-integration.patch
   If main has moved and it does not apply cleanly, port the changes into
   current code. Do not replace newer files with older snapshots.
2. Import the six FBXs with Studio's 3D Importer. They contain embedded
   colour textures. Preserve the separate meshes and their names: Frame
   is stationary; other assemblies are specified in Model-manifest.json.
   Use these exact outer Model names under ServerStorage.SpecialCrusherMeshes:
   MaglevMauler, OrigamiClamp, WreckingWinch, CamCruncher, ScrewStamper,
   DrawbridgeCrusher. Retain the current template importer and fallbacks.
3. The patch registers shared/ExoticCrusherAssets with the existing
   SpecialCrushers motion kit. Metadata uses the same (-BlenderX,
   BlenderZ, BlenderY) basis as the previous imported packs. Verify
   facing, uniform import scale, Frame dimensions and pivot reconstruction
   in Studio. Studio importer settings can change these.
4. Upload all six PNGs in Icons to this experience with their exact
   Crusher_<TypeId> names. The patch marks these as ready for the existing
   rbxgameasset resolver. If using uploaded numeric image IDs instead,
   add the six real IDs to CrusherIcons.Overrides. There are no invented
   asset IDs. Verify Index, hotbar and Auto Roller icons resolve.
5. Rojo serves the scripts, but it does not manage ServerStorage templates.
   Save/publish the place only after the Studio checks below pass.

## Included balance and behaviour

- Permanent regular roll pool: Legendary < Exotic < Limited/Secret < Divine
  < Mythic. Exotic rank 4.25; all previous ranks remain unchanged.
- Six equal Exotic choices. Base odds: 1 in 15,000 for each, 1 in 2,500
  for any Exotic. Total Exotic weight .04 is taken from Common, so other
  non-Common base odds stay unchanged. Existing luck/boost formula applies.
- Price 200,000; base value 280 and multiplier 2.1, yielding 588/input
  before other boosts. This is between Legendary 440 and Secret 726.
- Full Exotic row: 44% row-only bonus. Fleet event points: 5.5 each.
- Coral/mint row, bay and card visuals; regular reveal just above Legendary.
  Exotic does not trigger a Secret/Divine big-roll cinematic.
- Auto Roller includes Exotic. New-profile defaults include it; existing
  saved stop targets are not overwritten.
- Existing types remain in the same C.Types order. No saved IDs are changed.
  No remote names or purchase product IDs changed; no server production
  code was modified (only an existing test expectation was expanded).

## Motion

- MaglevMauler: Sled moves sideways into the shock wall.
- OrigamiClamp: Fold_1, Fold_2 and Fold_3 fold down as a nested fan.
- WreckingWinch: WinchDrum rotates, DropWeight drops, Cable extends.
- CamCruncher: Camshaft spins eccentric lobes; Stamp moves vertically.
- ScrewStamper: Screw turns AND translates; Handle turns; Shoe descends.
- DrawbridgeCrusher: Bridge swings down about its rear hinge.

Exotic-Crushers.blend contains all six editable models and a demo cycle,
frames 1–72, contact at frame 34. FBXs are open-pose meshes; runtime
animation comes from the registered Lua metadata. Icons contain no labels.

## Validation and remaining Studio checks

Verified all six FBX files by re-importing into Blender: exact mesh names,
pivots, bounds, triangles and packed PNG colour texture. Verified the source
animation keys and inspected open/contact renders. Verified 512x512 RGBA
icons. The game code compiles and the patch applies cleanly to adc03e0.

The real CrusherRules, CrusherRows and CrusherRollPresentation fixture suites
pass under the Luau CLI with lightweight datatype/service adapters. Extra
checks exercise all six through actual roll/buy/migration transactions,
odds, luck, row activation/breaking, output ordering and event points.
The JSON adapter only deep-copies tables, not Roblox's JSON codec.
To repeat from repo root:
    python tools/exotic/run-tests.py /path/to/luau

Still required: Studio Play at 1080p with no Output errors; test every
model at open/contact/return in a real occupied bay and in previews; check
textures and icon IDs; six-Exotic row bonus and glow; autoroller filter and
selected targets; normal luck/boost odds; event fleet points; rejoin with an
owned Exotic. Keep the place in test-save mode during checks. Check actual
JSON/persistence and live asset permissions before publishing.

The patch includes the dated Decisions log and Systems/Exotic crushers note.

