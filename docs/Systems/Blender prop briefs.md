# Toy-factory prop replacement briefs

Prepared 2026-10-22; integrated 2026-10-24. The five imported Blender models now
live in `ReplicatedStorage.FactoryToyModels` in the Studio place. The builders
in `src/server/Kit/FactoryProps.luau` clone these templates, with their original
procedural implementations retained as silent fallbacks.

## Shared handoff

Replace the internals of `FactoryProps.bear`, `.duck` and `.car` when models are
imported. Preserve their arguments, returned Model, ground anchor and scale.
Their Model.WorldPivot is now the supplied `cf`; PropKind/PropScale attributes
identify each instance. Anchor all imported pieces and disable CanCollide,
CanTouch and CanQuery, matching the procedural scenery. Keep built-in builders
as fallback. Do not replace the separate gameplay object/press mesh libraries.

Use the same chunky toy-factory style: generous rounded edges, simple glossy
materials, bold colour groups, readable silhouettes and a few large details.
Avoid tiny fasteners, fabric fuzz, realistic tyre treads or per-stud objects.
Prefer one mesh or a few material groups; reuse colours and geometry. Apply
Blender transforms and validate the imported axes and dimensions in Studio.
Dimensions below are **Roblox studs at scale 1**, measured from the current
builders. Export near these bounds, with +Y up and the pivot at the stated
ground anchor, then apply the existing uniform scale. Do not centre the pivot
on the bounding box: these props have deliberately asymmetric front/back bounds.

| Prop / builder | Local forward | Approximate unit bounds X × Y × Z | Ground pivot and occupied bounds |
| --- | --- | --- | --- |
| Teddy / `bear(parent, cf, scale)` | -Z | 16 × 22.15 × 10.35 | (0,0,0), below seated body; X ±8, Y 0..22.15, Z -6.85..3.5 |
| Rubber duck / `duck(parent, cf, scale)` | -Z | 7.4 × 8.4 × 8.6 | (0,0,0), directly below body centre; X ±3.7, Y 0..8.4, Z -6.1..2.5 |
| Toy car / `car(parent, cf, scale, color)` | +X | 9.125 × 5.675 × 5.9 | (0,0,0), wheel contact plane under chassis; X -4.5..4.625, Y 0..5.675, Z ±2.95 |

If the car is authored facing -Z for consistency with the other assets, use
an explicit -90° local Y adapter at placement to reproduce its current +X
forward. Verify in Studio before replacing every call. Leave gameplay and
the train wagon contents untouched.

## Teddy bear

The best first swap is the giant FactoryTeddy under World.ToyDisplays, called
from World.displays. Its ground anchor is on top of the existing capped crate:
`bearCf * CFrame.new(0,39.5,0)`, where bearCf faces the hall centre. Scale 4
gives an approximately 64 × 88.6 × 41.4 display. Keep the crate/plinth separate.

Model a seated teddy with a large round head, broad belly, short rounded arms,
two forward-facing feet, circular ears, inset muzzle and red bow. Use warm tan,
cream, dark navy eyes/nose and restrained white eye glints. Give the face a
clear friendly expression from across the hall. Keep feet grounded and avoid
deep gaps between arms/body that make the silhouette look disconnected.

## Rubber duck

The giant duck at the opposite corner is the primary swap: `duckCf *
CFrame.new(0,36.5,0)` in World.displays, scale 8 (about 59.2 × 67.2 × 68.8).
The same builder stocks the Duck Parade shelves at scales 2.2, 3 and 4.2.
Retain the asymmetric beak-forward bounds so shelf toys do not clip their racks.

Model a plump rounded body with a softly swept tail, oversized round head,
broad orange bill, shallow wing forms and two large dark eyes. Use golden
yellow with a slightly darker wing region, simple smooth surfaces and a few
readable highlights. Avoid realistic feathers or a long thin neck. The base
must sit flat without an added display pedestal inside the mesh.

## Toy car

Swap the Motor Works shelf cars first through FactoryProps.car. Current shelf
scales are 2.2, 2.6 and 3, with small yaw variations; preserve the `color`
argument for red/blue/green/teal paint variants. The car should read as a toy
at roughly 20–27 studs long on the racks. Keep wheels attached and static.

Model a rounded chunky body, simple raised cabin, large dark wheels, blue-tinted
windows and broad headlights. Keep the wheelbase wide and proportions slightly
exaggerated. Use a body-paint material group that can be recoloured independently
of tyres, windows and lights. Avoid brand logos, realistic interiors, thin
mirrors or trim that disappears at player height.

## Import review

Compare a new model beside the procedural version on the same anchor before
switching builders. Check the giant and shelf scales, ground contact, facing,
recolouring, bounds and phone readability. Save imported assets with the place
and document their real IDs/locations only after import. Templates are reused
directly; no asset-ID loader is used.

## Integrated templates — 2026-10-24

All five models were found as loose Workspace imports. They were moved to
`ReplicatedStorage.FactoryToyModels`, retaining their mesh textures/materials.
The imports faced the reverse of the handoff axes. Their geometry was rotated
180 degrees around the authored ground anchor, then their Model pivots were
set to the ground origin with identity orientation. This is baked into the
place templates; builders do not apply a second facing rotation. Duck, bear
and robot now face -Z; car faces +X.

The imported MeshPart.PivotOffset contains Blender's axis conversion. Placement
uses the enclosing Model pivot, not the individual MeshPart pivots. Duck/bear
retain their asymmetric occupied bounds from the table above. Additional unit
bounds are FriendlyRobot 7 x 10.2 x 3.9 (bounds centre Z=-0.25 relative to its
ground pivot), and ToyBricks 6 x 5.6 x 3.6 (centred in X/Z, bottom at Y=0).

On each clone, the builder repairs a recentered Model pivot from these known
asymmetric bounds, applies the existing uniform scale once, then places it at
the supplied CFrame. It preserves builder names, return type, EnvironmentProp,
PropKind and PropScale. All BaseParts are anchored and have collision, touch
and query disabled. No extra detail geometry is added to imported toys.

Car colour is applied only to BodyPaint. Its clone has TextureID cleared and
any SurfaceAppearance/Texture/Decal removed from that paint part, so Color can
recolour it. The details mesh keeps its original texture, material and tint;
the library template is not recoloured. A car template without a MeshPart
named BodyPaint falls back to the procedural car.

Each of the two existing Block Storage shelves replaces its bottom-left stack
with FriendlyRobot at scale 2.2, and its middle-shelf second stack with ToyBricks
at scale 3. These fit inside the old stacks' footprint/headroom. Missing imports
leave the original stacks. Giant mascot anchors, crates/plinths, shelf car/duck
anchors and scales, hall, open centre, plots and train route are unchanged.

### Validation actually completed

- Rojo build, scoped whitespace and LF checks passed.
- 273 Studio assertions passed across unit, shelf and giant scales, translated
  and rotated anchors, all prop attributes, safe physics flags, preserved
  materials/textures, car paint, and Model-pivot recovery after recentring.
  Compared all three missing-library builders against their original procedural
  versions. Temporary test fixtures were removed.
- Side-by-side imported/procedural comparisons were inspected at unit and giant
  scales, plus block shelves; red/blue imported car paint variants were inspected.
  Fresh desktop Play screenshots confirmed giant bear/duck ground contact on
  their existing plinths, facing, textured faces, shelf toys, robot and bricks.
- Fresh Play built 36 imported instances: 18 cars, 13 ducks, one teddy, two robots
  and two brick displays. No imported parts had active collision/touch/query.
  Conservative world-space bounds stay at radius >=417.99, beyond both the
  358.59 plot envelope and train ring outer radius 198 (rail centre radius 185).
  No route or plot geometry was moved. A complete train ride was not run.
- The live crusher catalogue still reports 40 types. No gameplay, progression,
  economy, UI or upgrade-interaction source changed. ObjectMeshes still contains
  13 templates and PressMeshes five.
- Play Output contained only existing disabled-DataStore warnings and the
  existing asset 203785492 type mismatch. No scenery script errors appeared.
  Mobile work remains deferred.

### Place-file handoff

Save the Studio place to retain the normalized FactoryToyModels folder; these
meshes and pivot edits are outside Git. ReplicatedStorage explicitly ignores
unknown children in the Rojo project, preserving this folder and ObjectMeshes.
Keep templates at their current unit dimensions and handoff axes when replacing
them later. If the folder or individual templates are absent, the game continues
using procedural scenery without waiting or repeated warnings. Studio was left
in Edit mode. This pass did not publish the game.
