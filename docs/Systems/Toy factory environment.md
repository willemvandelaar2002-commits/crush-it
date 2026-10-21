# Toy factory environment

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
