# Toy factory environment

22 Oct colour follow-up: restored the brighter golden apron (218,157,48) at
Willem's request. The softer lighting, reduced overhead shadows, larger studs
and themed displays remain. This supersedes the honey colour described below.

## Ceiling, softer light and display identities, 2026-10-22

This pass preserves the current thick structure, larger lettering and 4-stud
floor treatment. Playable geometry, trains, press progression, UI and all
Config/Store/Net values are unchanged. Source edits remain in World,
FactoryProps and the FactoryDay lighting preset in Build.

- The former 16 openings actually covered ~63% of the 880 x 880 roof, despite
  the earlier approximate half-solid description. Four diagonal openings now
  have broad opaque cream infills, including two above the centre. Twelve
  skylights cover 47.4%; the remaining roof is solid cream and structure.
  Existing thick borders, red/yellow girders and warm chunky pendants remain.
- Inspection found 40 casting roof parts: five red beams, five yellow beams,
  ten joints, ten cables and ten lamp brackets. Those high casters produced
  the long stripes seen in the previous screenshots. The roof subtree now
  has zero shadow-casting parts. Shelves, toys, crates, platforms and columns
  keep their grounding shadows; global shadows have not been disabled.
- FactoryDay brightness is 2.4, with ambient (121,129,145), warm neutral outdoor
  fill (174,171,163), saturation 0.02, contrast 0.05 and bloom 0.04. Existing
  Kit effects are reused; the previously handled older Bloom/SunRays stay
  disabled only for this preset. ShadowSoftness was not used as the sole fix.
- Apron colour is softer honey (203,166,104); red (217,85,70) and yellow
  (241,192,72) accents are less intense. Central blue-grey colour is unchanged,
  as are imported maps, the dedicated coarser floor variant and all UI textures.
- The same eight perimeter rack anchors now have two examples of each theme:
  Motor Works (coloured cars, varied yaw/scale and fewer cars on upper shelves),
  Duck Parade (3/2/1 ducks per level, with a larger top duck), Block Storage
  (colour-grouped stepped stacks), and Pack & Ship (shipping crates and a
  top stack near the existing striped packing booth). Headers identify each
  group; small repeated mixed-toy arrangements are removed. Existing giant
  teddy/duck landmarks and their substantial display plinths remain.
- Top-tier stacks and duck headers are raised/limited to avoid intersecting
  the shelf above or obscuring the largest duck. All scenery remains anchored
  and noncolliding, with clear plot entrances and the central Mega Crusher view.

### Blender preparation

[[Blender prop briefs]] documents the three replacement entry points, measured
unit bounds, ground anchors, forward axes, display scales and modelling briefs.
The bear/duck/car models now explicitly use the passed ground `cf` as WorldPivot
and expose PropKind/PropScale for inspection. Bear/duck face -Z; the car's
existing +X front is documented rather than silently rotated. Procedural
builders remain active. No Blender assets, mesh IDs or speculative loader exist.

### Verification

- Fresh Play: 2,426 backdrop parts (down from 2,716), six lights, zero roof
  casters, four opaque infills and 47.4% skylight coverage. No invalid
  decorative anchor/collision/touch/query flags were found.
- Compared rendered elevated views against the earlier pass: the long roof
  shadow bars are absent and shadows remain under racks/props/platforms.
  Inspected the ceiling and displays from the hub and Plot 1, Plot 3 and Plot 5
  at player height; solid ceiling sections now read clearly between skylights.
  Reviewed headers and shelf silhouettes without hiding the Mega Crusher.
- Projection checks against all eight plot rectangles found no scenery overlap
  at gameplay height. Walked Plot 1's bridge out and back, reached its press
  and held F: Crushed increased to 1, health remained 100 and WalkSpeed 28.
  Boarded ToyTrain1 with its actual RidePrompt, rode, then jumped off.
- Fresh server Output errors are only the existing disabled Studio DataStore
  APIs. Rojo build and LF/whitespace checks pass. No gameplay or UI source edits.
  Normal desktop HUD/camera are restored after review.

Remaining: custom sculpted toys and true extruded lettering still require
future imported assets. Full train laps, high-tier progression and real-phone
performance were not rerun for this environment-only pass. Low graphics still
uses Roblox's rendering-distance limits. Keep the previously prepared floor
material saved with the place; this pass adds no further place-only assets.

## Second visual polish, 2026-10-22

The attached concept remains the art target. This pass addresses the thin roof,
sparse shelves and flat lighting in the supplied current-state screenshots.
Only World, FactoryProps and the lighting helper in Build change. Config,
Store, Net, UI, Hub, Plots, press builders, progression and train code are intact.

- Cream ceiling sections surround 16 individually framed skylights, occupying
  approximately half the roof area. Red roof girders, yellow crossbeams,
  columns, joints, brackets and column bases are substantially thicker. Roof
  height remains 150 above the apron; opaque ceiling panels do not cast broad
  shadows, while the beams and stocked displays add visible shadow depth.
- Ten larger pendants have warm emissive undersides. Four pendants and the two
  loading-door lights use modest, unshadowed PointLights: six actual lights total.
- Eight shelves grow from 84 to 116 studs across, with 94-stud navy supports,
  chunky shelf edges, four toy groups per level and three levels. Larger ducks,
  cars carrying bricks, stacked bricks and base crates form grouped displays.
  The giant teddy/duck grow onto larger capped toy plinths. All remain beyond
  the playable plot envelope and use anchored, noncolliding built-in geometry.
- A thick blue/navy rear marquee tightly frames white CRUSH and yellow IT
  lettering with dark outlines and a simple cog silhouette. Its SurfaceGui
  density is deliberately low enough for TextScaled to fill the physical sign.
  Doors gain heavy surrounds, hazard accents and warm lamps; the gantry gains
  thicker towers/beams, trolley, cables and a larger suspended toy crate.
- Apron colour changes from (229,186,91) to richer gold (218,157,48). Only the
  apron and WorkshopCommons.CommonsFloor use the coarser 4-stud floor finish.
  The central blue-grey colour, geometry, physics and island gaps are retained;
  press, rail, plot and UI materials keep their previous treatment.
- FactoryDay uses cooler ambient shadows, warm outdoor fill, slightly stronger
  contrast and restrained KitBloom. Inspection found an existing enabled Bloom
  at intensity 1 as well as older SunRays. FactoryDay now disables those older
  two effects while preserving/restoring their Enabled state for other presets.
  Kit effects, Sky and Atmosphere are reused rather than stacked.

### Place material that must be saved

MaterialService.CrushItFactoryFloorStuds is a derived copy prepared in Studio:
its NormalMap is copied from the imported Studs, ColorMap is empty, BaseMaterial
is retained, StudsPerTile is 4, and boolean attribute FactoryFloorMaterial is
true. This preserves normal-lit studs with the part's own colour, removing
the baked colour contrast on broad floors. The five original variants and
their map/tiling settings are untouched. Rojo does not manage MaterialService.
**Save/Publish the existing place to retain this sixth material.**

Game scripts cannot edit MaterialVariant texture maps (plugin capability is
required), so the source only selects this prepared asset. If it is missing,
the helper clones imported Studs at a separate 4-stud scale with its original
maps; this remains functional, with stronger colour contrast. If Studs itself
is absent or world materials are disabled, it uses subtle 4-stud legacy top
textures (Right end face for the upright commons cylinder). Original shared
variants are never retiled, duplicate variants are not created, and unrelated
textures/decals remain intact. To recreate the exact finish manually, duplicate
Studs in Studio, apply the name/settings/attribute above and save the place.

### Verification and remaining visual gaps

- Fresh Studio Play starts correctly with Plot=1, WalkSpeed=28 and functioning
  player attributes. Final server Output errors are only the existing disabled
  Studio DataStore APIs. A development-only ColorMap permission failure was
  caught on restart and corrected before final verification.
- Reviewed the final hall at player height and a high interior overview, then
  inspected the environment in iPhone 17 Pro landscape simulation. Normal
  desktop camera, HUD and device mode were restored after review.
- Backdrop has 2,716 anchored parts and six unshadowed lights. All decorative
  collision/touch/query flags remain off; only apron and enclosing wall/window
  colliders are retained. The extra geometry is concentrated in large shelf
  toys and architecture, without geometry per floor stud or new moving loops.
- Checked 18,264 scenery/plot projection pairs at Y=1.6..110: no overlaps with
  any of the eight plot rectangles. Walked the representative plot bridge
  both ways and returned to the press; holding F increased Crushed to 1 with
  health 100 and WalkSpeed 28. Boarded ToyTrain2 through its RidePrompt, rode
  and jumped off; rail route and timetable source are unchanged.
- Rebuilding World retains one root and the same 3,381 descendants/2,716 parts,
  with six material variants total. Tested missing-derived-material fallback:
  it creates one coarser clone safely, retaining the original source maps.
  Original Studs remains tile 1 with its original colour/normal maps.
- Rojo build and LF/whitespace checks pass. No gameplay or UI sources changed.

The reference still has sculpted mascot detail, true extruded logo lettering
and richer background dressing. This implementation uses built-in primitives
for toys/cog and outlined SurfaceGui lettering on a thick sign instead of
requiring unavailable meshes. Full train laps, high-tier progression and
physical-phone FPS remain review items; phone simulation is not a device
performance benchmark. Low graphics retains Roblox's distant-rendering limits.

## 2026-10-21 — factory hall around the Toy Train Loop

The environment follows the approved bright toy-factory concept. The current
circular map remains the game: eight player plots, two rideable trains, their
stops and timetable, four hub walkways and the central Mega Crusher.

`World.luau` replaces the outdoor cliff/scrapyard backdrop with a high factory
hall. Its half-width is at least 440 studs and expands with the configured plot
envelope. The wall sits beyond the current plot corners (radius approximately
387). Its 150-stud height leaves the centre and upgraded presses open.

- Cream walls, cobalt lower panels, red columns and yellow structural bands.
- Tall blue-tinted windows, broad skylights and red roof beams. Roof glass and
  roof beams do not cast shadows; they keep the large interior bright.
- Eight oversized toy shelves with bricks, cars and ducks. A teddy and a duck
  form corner landmarks on toy crates. All toys use simple built-in geometry.
- Rear gantry with a suspended toy crate, two shuttered storage facades,
  a striped packing booth and static supply conveyors along the outer walls.
- Four small toy displays occupy the gaps between the inner hub walkways,
  with clear space around both the hub and train track.
- Warm golden studded apron, navy perimeter lanes and yellow paint. The apron
  keeps the previous `YardFloor` name, 2048 x 2048 extent and SeaY top surface.
  It remains below the playable platforms and uses the existing rescue logic.

`Kit/FactoryProps.luau` contains reusable scenery builders. These add anchored,
noncolliding parts with touch and queries disabled. Only the enclosing wall
panels/windows and the existing rescue apron have collision. The World model
retains persistent streaming, and rebuilding it replaces only that model.

`Build.lighting("FactoryDay")` adds bright, gently warm ambient fill and low
haze/bloom. Existing lighting presets and all shared Style arguments remain
compatible. Integration retains the engine-bundled cloudy sky and the existing
WorldStuds pass: imported Studs applies to eligible environment surfaces,
with the original texture fallback if the place material is missing. The
MaterialService assets must still be saved with the place; Rojo does not own them.

No changes to Config, Store, Net, train code/timetable, Hub, Plots, MegaCrusher,
press construction, player attributes, UI or place-only meshes. No new model,
image or audio uploads are required. No additional moving scenery, particle
emitters or dynamic lights are introduced.

## Patch author's verification (before integration)

- All repository Luau files compile with the Luau CLI; `git diff --check` passes.
- A headless harness executes the actual Config, Style, Build, FactoryProps
  and World modules with basic Roblox geometry/instance mocks. It verifies
  construction and rebuilding, interaction flags, the unchanged rescue floor,
  and preservation of an unrelated gameplay root.
- Generated backdrop: 1,724 parts, 112 texture instances and zero dynamic
  lights. These are backdrop-only counts, not a live whole-game benchmark.
- Geometry projections check all generated scenery against all eight plot
  rectangles, the train corridor, central hub and four walkways. No overlap
  was found at gameplay height. High roof structure is deliberately overhead.

Studio was unavailable in the implementation environment. These checks do
not establish Roblox rendering quality, physics, Output state or phone FPS.

## Required Studio review

1. Sync into the existing place in Edit mode and start Play. Inspect the hall
   from a normal plot camera, the hub and a ride on each train.
2. Ride a full loop, board at several stops and jump off. Walk every hub spoke
   and representative plot bridges; verify scenery does not hide the route.
3. Crush, collect/deposit scrap and use upgrade pads. Inspect the largest press
   tier through the existing developer tools without modifying saved progress.
4. Check Output, window/skylight brightness and SurfaceGui sign readability.
   Review at 1080p and phone landscape; measure performance on a real phone.
5. Confirm the lower-apron rescue still returns players to their plots. Its
   existing message is outside this environment pass.

Publish only after reviewing the actual Studio result. The concept image is
an art-direction reference, not evidence of the implementation's appearance.

## Integration into the current game, 2026-10-21

The supplied patch targeted an older World/Home revision. Its complete hall,
FactoryProps builders and FactoryDay preset were integrated while retaining
the newer imported material rollout, cloudy sky and the raised hub commons.
The optional inner ToySupplyBays are skipped when WorkshopCommons exists:
their old apron-height placement would otherwise bury/overlap duplicate props
under the current work bays. Existing centre props and the restored 12-stud
island gap are preserved. Hub, presses, trains, Config, Store, Net and UI source
are unchanged by this integration. The outdoor cliffs/container yards are
replaced by the factory scenery as requested.

### Integration verification in Studio

- Rojo build and scoped whitespace/LF checks passed. Both changed modules and
  the new FactoryProps module execute in fresh Play; the patch author's
  standalone Luau/headless harness is not included and was not rerun here.
- Actual backdrop: 1,596 anchored parts, 64 active legacy textures, 22 parts
  using imported Studs, and zero dynamic lights. All scenery touch/query flags
  are off; collision is limited to the existing apron and enclosing wall/windows.
- Eight shelves, 25 ducks (including shelf toys), one giant teddy, the gantry,
  loading facades, packing booth and roof render. FactoryDay clock is 13.5.
  The apron still has top Y=-3, size 2048 x 1 x 2048 and its original name.
- Projected 11,248 scenery/plot pairs at gameplay height (Y=1.6..110): no
  overlap with any of the eight plot rectangles. Commons foundation radius
  remains 198, with plot entrances still at 210 and no duplicate inner bays.
- Desktop player view and a high interior overview were inspected against the
  supplied reference. A fresh iPhone 17 Pro landscape Play was inspected at
  750 x 381; thumbstick, jump, Crush and the top panel buttons remain visible.
  Also inspected the hall while riding in phone simulation. UI is unchanged.
- Walked Plot 1's bridge both ways and returned to the press. Holding F crushed
  an object (Crushed=1), with health 100 and WalkSpeed 28. Boarded ToyTrain2
  through its actual RidePrompt, rode across several stops and jumped off;
  TrainHud and Humanoid.Sit returned to their normal states. A complete lap
  on each train was not run.
- Dropped onto the lower apron: the existing rescue returned the avatar to
  Plot 1 with health 100. ObjectMeshes=13, PressMeshes=5 and MaterialService
  variants=5 remain intact. No place assets were replaced or edited.
- Fresh server Output errors are limited to the existing disabled Studio
  DataStore APIs (GetAsync/GetSortedAsync). Earlier client Output also contains
  existing Roblox CorePackages warnings and the unchanged asset-type warning
  for 203785492; no factory game-script errors were observed.

Remaining review: complete laps on both trains, full upgrade/progression and
largest-press playthrough, plus performance on a physical phone. Very low
Roblox graphics still culls distant scenery as documented in Scrapyard
environment; Persistent streaming does not override that rendering limit.
Preview captures used higher Studio render quality. Save/Publish the existing
place after reviewing this pass, retaining its material variants and meshes.
