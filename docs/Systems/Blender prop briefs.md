# Toy-factory prop replacement briefs

Prepared 2026-10-22. No Blender models or mesh IDs have been created. The game
continues to use its procedural props in `src/server/Kit/FactoryProps.luau`.

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
and document their real IDs/locations only after import. No custom-model loader
or speculative asset reference has been added in this pass.
