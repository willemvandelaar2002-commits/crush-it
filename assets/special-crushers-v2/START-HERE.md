# Crush It — Secret and Divine crusher replacements

Willem: send Claude this ZIP. You do not need Blender. The eight FBX files
are the Studio imports. The BLEND is the editable source for all eight;
its timeline demonstrates the mechanisms (1 open, 19 crush, 55 returned).
Blender-Preview.jpg is a render of the actual models. These replace the
existing eight crusher appearances, not their game data or Index icons.

## Claude: import and connect

1. Read CLAUDE.md, docs/Home.md and the current special crusher importer.
   Use Studio's 3D Importer to stage each FBX in a temporary location, with
   the game owner's asset permissions. Keep the individual named meshes;
   do not merge the whole model. Each FBX contains an embedded colour
   texture; keep its UVs and confirm the colours loaded. No texture download
   is required. There are 2–6 rigid mesh assemblies per crusher.
2. Use the exact filename without extension as the outer Model name.
   Put the vetted templates in ServerStorage.SpecialCrusherMeshes. Keep a
   backup of the existing models until a Studio Play check passes. Anchor
   the parts, disable collisions/touch/query where the current builder
   does so, and fit them to the current machine envelope at one uniform
   scale. Pivot the entire model at ground centre. Verify which way it faces
   in a real bay; Blender front is -Y before conversion. Do not assume
   the importer's scale factor or blindly copy an old template's yaw.
3. Match assemblies by the names in Model-manifest.json. Frame is static.
   Imported MeshParts may be recentered; if so, reconstruct the moving
   pivots from the manifest rather than rotating around a bounding-box
   centre. The manifest uses Blender X=right, Y=depth (front is -Y),
   Z=up; convert positions, axes and rotations through the imported
   model basis, and apply the same uniform scale to linear travel.
   inputCenter is the initial scrap centre, especially for the levitating
   input on Celestial Crusher and the gap on Eclipse Engine. bedTop is
   the nominal support height; check actual contact in the bay. Preview
   actions are in the Blender source; FBX geometry is the open pose.
4. Connect motion to the current strike feedback. The legacy downward-only
   ram path is not suitable for rollers, side jaws, hinges or the three
   converging rams. Preserve the existing output transaction and fallback
   path. Use stored rest transforms as the basis of every strike, return
   to them cleanly and reuse current animation distance/performance limits.
   If a visual effect is added, prefer short local pulses over permanent
   lights on every machine. The Blender renders use display lighting;
   embedded textures supply colour, not Roblox particle or Neon effects.

| Model | Named motion and effect cue |
| --- | --- |
| ShadowShredder | Roller_Lower and Roller_Upper counter-rotate. Small pink tooth flash as scrap goes through the gap. |
| VoidVise | Jaw_L and Jaw_R slide inward together. Gravity_Core spins; purple impact pulse. |
| EclipseEngine | Crescent_Top and Crescent_Bottom travel toward one another. Brief orange eclipse flare. |
| NightRipper | Claw_L and Claw_R pivot toward the anvil. Brief mint sparks. |
| HaloHammer | Hammer_Arm swings around the shoulder pivot. Cyan impact ring under the head. |
| CelestialCrusher | Orbit_Indigo rotates in-plane; Orbit_Gold tilts. Celestial_Ram_1 through 3 converge on the floating input. |
| ArchangelAnvil | Wing_L and Wing_R fold while Ram stamps vertically. Small gold star flash. |
| AuroraPress | Prism_Stage_1 through 3 extend downward at different distances. Quick teal and pink shimmer. |

Keep crusher IDs, odds, rarity, yields, purchases, saved ownership and Index
icons. In Studio, check an open pose, a strike and a return in a real bay;
repeat in roll/display previews and near another occupied row. Check that
the motion neither clips adjacent bays nor blocks the scrap. Only save the
place after confirming the imported colours and pivots.

## Verification

All eight FBX exports were re-imported into Blender 4.5 LTS. Mesh names,
pivot locations, bounding boxes, triangle counts and packed colour images
were checked. The Blender animations were checked at the open, strike and
return frames. Roblox Studio integration was not run in this workspace.

