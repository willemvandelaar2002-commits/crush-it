# Mystery crate — art and Studio handoff

Willem: give Claude this ZIP. You do not need to open Blender.
MysteryCrate.fbx is the Studio import. MysteryCrate.blend is the editable
source, with a preview opening animation. The 512x512 transparent PNG is
the matching shop/HUD icon. Design-Reference.png is the concept, while
Model-Preview.png and Opening-Preview.png show the actual model.

## Claude: replace the placeholder, keep its behaviour

Find the current purple/yellow question-mark crate from Willem's screenshot.
Import MysteryCrate.fbx with Studio's 3D Importer. Keep its embedded colour
texture and three separate named meshes: Body, Lid and Seal. Check the
texture in Studio; do not flatten all three into a single mesh.

Fit the complete model uniformly to the current crate's footprint, ground
it on its existing platform and match its front facing. Preserve its prompt,
click target, interaction distance, reward logic, purchase flow and timers.
Store it using the existing crate template convention; do not introduce a
new storage path without checking current code. Anchor the visual parts
and preserve the station's existing collision behaviour.

Body is hollow; Lid rotates around the REAR hinge, not the mesh centre.
Model-manifest.json records each Blender-space pivot, bounds and triangle
count. Blender coordinates: X right, Y depth, Z up, front -Y.
The lid pivot is (0, 1.17, 2.16) and its opening is -105 degrees around
Blender X. Account for the actual imported basis and uniform scale. If the
importer recentres the Lid mesh, reconstruct the hinge from the manifest.

Preview sequence in Blender: frames 1–12 closed, small Seal wiggle
(frames 1–16), lid opens by frame 34, holds until 60, closes at 72.
Use the game's existing opening/reveal trigger and timing; do not create
a new crate reward just because the model contains an animated lid.
If the crate is currently only an interaction prop, keep that flow.
A subtle whole-model idle bob is optional; do not continuously open the lid.

The cyan texture seam is coloured artwork. To add true Roblox glow, use
small separate Neon seam strips or a brief local reveal effect, not Neon
on the whole Body. Keep VFX restrained in a crowded factory.

Upload MysteryCrate-Icon.png and reuse its actual image ID wherever this
crate needs a UI icon. Do not invent an ID or replace other crate icons.

Save the place after importing. Rojo does not store place-only mesh assets.

## Verification

The FBX was reopened in Blender: Body/Lid/Seal, pivots, bounds, triangle
counts, UVs and embedded PNG texture were checked. The lid's open/closed
animation angles were checked. The icon is RGBA, 512x512.
Roblox Studio was not run here. Verify actual front facing, import scale,
hinge motion, no clipping when open, unchanged interaction and Output
before publishing. Record the art replacement in docs/Decisions log.md.

The question mark is converted mesh geometry, not a font dependency.

