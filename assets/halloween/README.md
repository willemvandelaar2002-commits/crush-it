# Crush It — Halloween models

28 October 2026. **Models only: this pack does not change gameplay or install
an event.** There are three FBXs to import from the Models folder:

1. **PumpkinForeman.fbx** — Halloween replacement for the bear mascot/boss.
   A giant jack-o'-lantern factory foreman with purple top hat/work apron,
   vine arms, pumpkin fists, bright eyes and an opening reactor chest.
2. **PumpkinCore.fbx** — the Halloween object to crush on the central Mega
   Crusher and on players' combined crushers. Four separate pumpkin-rind
   sections can break away to reveal the glowing candy-energy centre.
3. **CandySoul.fbx** — a small wrapped ghost candy for a carried/fed resource,
   if the event uses the core-feeding mechanic.

All three use **HalloweenPalette.png**, also embedded in their FBX files.
Keep the UV texture; vertex colours are not required. Import the three FBXs
individually, retaining their mesh names and separate pieces.

## What the other folders contain

- Blender/HalloweenEventModels.blend: editable source containing all three
  assets in named collections. Boss is visible by default. Enable the
  PumpkinCore or CandySoul collection to edit those models.
- Previews/: actual mesh renders. These are not generated concept pictures.
- Metadata/: mesh names, parent channels, authored pivots, dimensions and
  validation results. Each FBX is exported in its neutral/rest pose.
- Source/: reproducible Blender build/validation scripts.

The Blender file includes an eight-second rigid animation demonstration:
chest opening, wind-up, slam, roar and recovery, plus the core's rind opening.
FBX animation is deliberately not baked. These are anchored rigid mesh pieces,
with no skinning/Humanoid/AnimationId requirements.

## For Claude / whoever imports the models

- Source axes are Blender Z-up/-Y-front; export is -Z-forward/Y-up. Verify the
  real Studio import is upright and facing the desired direction. Scale the
  WHOLE boss to the existing bear's measured pedestal envelope and ground
  anchor, preserving the factory background. Do not resize individual limbs.
- Authored boss size is roughly 10.15 wide × 15.58 high × 5.50 deep in source
  units. The core is about 4.40 wide/high-body, 4.60 total height including stem;
  the candy is about 2.78 wide. Studio may interpret FBX unit scale differently;
  fit by measured dimensions rather than using an assumed conversion factor.
- Boss keeps the previous bear's 20 rigid channel names where useful. Ear_L/R
  are collar leaves on this character. Use THIS model's pivot/parent metadata,
  never the bear's numeric pivot positions or old recenter correction.
- MeshPart centres can differ from authored hinge origins after import. Use
  Metadata/rigs.json to rebuild the hinge points. Pivots are global in the
  neutral authored frame, with parent-channel names for head/paw children.
- Boss glow pieces: Eye_L, Eye_R and Core. Crush target glow: Glow. Candy glow:
  CandyGlow. Their texture swatches are white so you can tint them lime green
  (#B8FF44) and set Neon in Studio. Keep other parts white-tinted to preserve
  palette colours. The preview Blender materials already show these tints.
- Anchor parts and disable collision/touch/query for event cosmetics. Keep
  server hitboxes/event logic separate from the visible meshes.
- Model template names can be PumpkinForeman, PumpkinCore and CandySoul in a
  Halloween asset folder. Keep the normal bear and its assets available for
  the regular event; these are a seasonal alternative, not a destructive swap.
- No schedules, rewards, rarity values, HP/damage, shop items, event enrollment
  or other game code are supplied/changed by this pack.
- Verify texture upload, names, orientation, proportions, hinge movement and
  crusher/core clearance in Studio. Save/Publish place-only imported assets.

Blender/FBX checks are provided in Metadata/validation.json. Studio import and
Play have not been tested by Codex.
