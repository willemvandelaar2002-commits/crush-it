# Imported stud material comparison

## Adopted after approval, 2026-10-21

Willem reviewed the visible comparison and asked to use the imported studs.
The former comparison-only restriction is superseded for this environment
rollout: a small server module and one world-startup call now make it visible
in the real game on every Play. The comparison below remains available as a
diagnostic, but is no longer the only place using the material.

`Style.Studs.UseWorldMaterials = true` is the production switch in
`src/shared/Kit/Style.luau`. Set it to **false and restart Play** to restore
the legacy world treatment. Variant absence also falls back automatically.

`server/Kit/WorldStuds.luau` visits explicit environment roots after
`World.create` finishes: World scenery; Hub; and each plot's Floor, Island,
Decor and PileZone. It converts only Plastic/SmoothPlastic parts already
carrying the kit's stud textures. It prunes Press, MegaCrusher and HelperYard
subtrees. Concrete, metal, sand, glass, neon and untextured surfaces stay as
they are. This is an existing-part material pass, not a duplicate map or a
change to every Style.studs call. The imported finish deliberately wraps all
surfaces of the chosen parts; the archived textures retain their old face lists.

Plastic's default friction differs from SmoothPlastic. Material conversion
now pins the original effective PhysicalProperties when no custom properties
were set, and records that state for exact rollback. Existing custom physics
are left alone. Returning to the original base material restores default
physics when appropriate. Missing-variant fallback leaves existing legacy
face lists intact, including the hub cylinder's Right-face texture.

Studio Play verification: all eight Floor.Top parts use Studs with their
original #7791A9 colour. 3,695 environment parts converted; no checked press,
Mega Crusher or helper part converted. Disable/re-enable checks preserved
size, CFrame, colour, collision/touch/query flags, anchoring and effective
physics for all 3,695; materials on 814 press/helper parts were unchanged.
No active kit texture overlays remain on converted surfaces. Legacy rollback
and reapplication worked, as did missing-variant single-face fallback.
Holding F still crushed an object, and client Output remained error-free.
Only the existing disabled Studio DataStore API errors remain on the server.

The comparison rig was removed and the normal camera/HUD restored. Studio
is left in Play showing the actual converted map. Save the imported materials
with the place and Publish to deploy this appearance; no Publish was performed.
Physical-phone rendering/performance remains a device check.

The following sections record the initial comparison and its reusable setup.

## Opt-in only, 2026-10-21

All existing world builders still call `Style.studs(part, faces?, perTile?)`.
They keep the image treatment, selected faces and default 2-stud tile. UI
studs, world colours, lighting, presses, collisions and gameplay are unchanged.
The helper now reuses its own textures per face rather than accumulating copies.

New API:

```lua
local Style = require(game.ReplicatedStorage.Shared.Kit.Style)
Style.materialStuds(part, true)  -- opt in to imported Studs; returns true if found
Style.materialStuds(part, false) -- restore original material and face textures
```

`Style.Studs.MaterialVariant` defaults to `"Studs"`. This is a lookup name,
not a global enable switch. No legacy call automatically opts in. The new
helper optionally accepts `fallbackFaces` and `fallbackPerTile` after the
boolean; these apply only to fallback image textures, never to the variant.

MaterialVariant wraps every face. This differs intentionally from the old
face-specific overlays. Choose whole world parts where that is acceptable;
do not replace every call or enable it on a parent containing presses.
The part's Material is set to the variant's BaseMaterial (Plastic for this
pack), with MaterialVariant set to its name. No base-material override is used.

Only Texture children with both the kit's `Studs` name and its exact texture
asset are managed. Converted overlays are moved into a nonrendering backup
Folder on that part; switching off restores the original instances, including
faces, tiling, offsets and tint, and the original Material/MaterialVariant.
Other textures and decals are untouched. Repeated enable/disable calls reuse
one backup and do not create variants or stack active textures. A missing or
wrong-class variant restores the backup, or uses the legacy texture fallback.
Calling the existing `Style.studs` also returns a converted part to textures.

## Run the temporary Studio comparison

1. Open the existing place with its imported MaterialService assets and Rojo
   connected. Start Play and wait for the plot floors to finish loading.
2. In Studio's **server** Command Bar, paste and run
   `docs/Studio/StudMaterialComparison.luau`. The script is outside `src/`,
   is not synced by Rojo, and does not run in published gameplay.
3. `Workspace.StudMaterialComparison` contains LEFT `A_LegacyTexture` and
   RIGHT `B_ImportedStuds`. Both are copies of an actual Floor.Top, resized
   identically to 24 x original-height x 20. Colour is copied unchanged. The
   noncolliding samples sit above the world, at top Y=140, away from machines.
   No real floor or press is modified.
4. Change the model's **UseImportedStuds** attribute in Properties, or run:

   ```lua
   workspace.StudMaterialComparison:SetAttribute("UseImportedStuds", false)
   -- true = imported material on RIGHT; false = restored legacy on both
   ```

5. In the **client** Command Bar, use this player-height camera:

   ```lua
   local c = workspace.CurrentCamera
   c.CameraType = Enum.CameraType.Scriptable
   c.CFrame = CFrame.lookAt(Vector3.new(0, 147, 35), Vector3.new(0, 139, 0))
   c.Focus = CFrame.new(0, 139, 0)
   ```

   For a shallow angle, use position `(0, 143, 40)` looking at `(0, 140, 0)`.
   For pattern detail, use `(0, 174, 22)` looking at `(0, 140, 0)`.
   Restore normal controls with `workspace.CurrentCamera.CameraType = Enum.CameraType.Custom`.

6. Stop Play to remove the samples and temporary connections. The setup also
   safely replaces its previous comparison if run again. Do not publish a
   manually saved diagnostic rig as part of the game.

Studs has a native 1-stud tile; StudsSmall has 0.5. The comparison matches
the legacy sample's image repeat to the imported Studs tile (1), leaving
the real world's default (2) and all imported settings unchanged. Matching
was also checked in a detail render. To evaluate a different material scale,
make a deliberately named separate variant in Studio; never retile a shared
variant to satisfy one part. The helper never edits variant maps or tiling.

## Place assets and Rojo

MaterialService contains Studs, StudsSmall, Inlet, Weld and Universal, each
with its imported colour and normal maps. They are place-only assets, like
ObjectMeshes and PressMeshes. **Save them with the existing place and include
them when publishing.** A standalone Rojo build does not contain the pack.

`default.project.json` manages only Shared, Server and StarterPlayerScripts;
MaterialService is outside its managed trees. The comparison adds no mapping,
deletion or override for that service. Verified all five originals retained
their imported map IDs, BaseMaterial, MaterialPattern and StudsPerTile after
sync and testing. No protected server, Net, Config or Store files were edited.

A persistent production opt-in on an actual plot would require capturing
the Floor model returned by `Build.platform` in `src/server/Plots.luau`, then
applying `Style.materialStuds` to that model's `Top` part only. That is a
protected world-builder edit and was not made; the temporary setup exercises
the shared helper without changing it.

## Verification

Studio Play: viewed matching floor samples at player height, shallow angle
and a higher detail angle under existing world lighting. Both use colour
#7791A9 and size 24 x 1.55 x 20 in the current place. The imported pattern
has visible relief shading and wraps onto the sides; the old image shows a
flatter ring pattern and stays on Top. No global replacement decision made.

Runtime checks passed: repeated enable/disable, exact texture/material
restoration, missing-variant fallback, per-face texture idempotence, unrelated
Texture/Decal preservation, and unchanged shared variant tiling. The rig's
attribute toggle worked in both directions. Client Output had no errors;
server Output had only the existing disabled Studio DataStore API messages.

Rojo build and scoped whitespace/LF checks passed. Protected-file hashes and
the UI helper section were checked unchanged. Temporary samples/camera/HUD
changes were cleaned up and Studio returned to Edit. Physical-device material
quality/performance and a decision on production surfaces remain future checks.
