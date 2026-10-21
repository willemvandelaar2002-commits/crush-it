# Bright scrapyard island environment

## Restored island gaps and background diagnosis, 2026-10-21

The commons shoulder was filling the original bridge gap. CommonsFloor now
has radius Loop.Outer - 2 = 196 (diameter 392); its rim has radius 197 and
foundation radius 198. The central land stops beneath the train road, leaving
the original 12-stud sandy channel to the plot entrance radius 210. Only the
existing bridges cross it. The filled centre, work bays and planting remain;
plot positions, rail route, bridges, presses, interactions and Config are unchanged.
This supersedes the 208-radius shoulder described in the earlier pass below.

Background diagnosis and remaining limitation:

- The place has streaming enabled, and World is already Persistent. All 76
  GrassyCliff models were present on the client even when the backdrop vanished.
- At the same camera position, explicitly selecting Studio render Level01
  reproduced the missing cliffs, cranes and opposite plots. Level21 restored
  them. This is graphics-distance culling, not missing source or place assets.
- Enlarged backing geometry and disabled model LOD did not solve Level01
  culling. Those temporary tests were discarded; no proxy map or extra walls
  remain. Streaming radius and players' graphics preferences were not changed.
- Studio EditQualityLevel and the current Play rendering preview were raised
  to Level21. The current Play view is corrected, but starting Play again can
  reset rendering to Automatic. Setting SavedQualityLevel through the plugin
  is blocked by Roblox's capability permissions. In the Roblox Play settings,
  use manual Graphics Quality and raise it if distant scenery disappears.
  This is still a limitation for players who choose very low graphics; the
  repository change does not claim to override Roblox's rendering distance.
- Roblox documents this relationship in its [QualityLevel reference](https://create.roblox.com/docs/reference/engine/enums/QualityLevel).

Verification: fresh Play confirmed diameters 392/394/396, floor top Y=1.44,
and all 76 cliff models loaded. Compared desktop views at the same camera
before/after and checked the exposed gap in phone landscape simulation.
Walked Plot 1's bridge in both directions with health 100, then reached the
press and held F: Crushed increased to 1. WalkSpeed remains 28. No game-script
errors were observed; Output includes existing DataStore API warnings, Roblox
CorePackages UI warnings, the existing asset-type warning for 203785492, and
the diagnostic SavedQualityLevel permission warning. Normal desktop camera
and device simulation were restored after testing. UI source is untouched.

## Cloudy daytime sky, 2026-10-21

YardDay now assigns all six engine-bundled sky512 cube faces, replacing the
place's repeated flat side image. The cloudy blue sky gives the new commons
a more cheerful horizon without changing the existing clock, warm lighting,
exposure, atmosphere, bloom, colours or game settings. No external sky upload
or dynamic Clouds instance is required. Other Build presets are unchanged.
The skybox is applied by Build.lighting during normal world creation, so it
persists across Play sessions. Save/Publish the existing place to deploy it.
Fresh Studio Play verified all six sky faces and rendered the clouds above
the yard. Clock 14, brightness 2, exposure -0.12 and haze 0.25 are unchanged.
Build/LF checks passed; Output only shows the existing DataStore API warnings.

## Connected land from the new references, 2026-10-21

Inspected both first contact sheets, the industrial daytime floor close-up,
and the capybara green route/cliff close-up in Reference/simulator-style.
Applied their broad connected ground, framed work areas, grouped stations
and contained planting to the existing scrapyard and toy train loop.

- Hub now has WorkshopCommons: a 416-stud circular ground slab, navy rim and
  chunky foundation. Its radius is Loop.Outer + World.HubGap - 2 (208).
  This fills the former central sandy annulus and adds a 10-stud shoulder
  outside the road. About 90,000 square studs of sand become connected land,
  accounting approximately for the hub/loop/spokes that already occupied it.
- Commons top is 0.16 studs below the existing floors, preventing coplanar
  surfaces. Its collider supports players above the existing rescue threshold.
  The 210-stud plot entry radius and plot footprints remain unchanged.
- The four former 12-stud spoke bridges become 18-stud charcoal service
  lanes across solid ground, at the same endpoints. Train rails, stops,
  timetable, ring road and each plot's bridge remain as before.
- Four low dark work bays at diagonal angles and radius 118 frame the
  open centre. They suggest incoming scrap, a maintenance workshop, sorted
  cubes and container storage. White corner markings keep their entrances
  legible. All new props reuse YardProps and disable collision/touch/query.
- Moved the existing striped-awning workshop from the outer sand into one
  bay, rather than duplicating it. Four contained planters at radius 154
  add two chunky trees and low bushes, clear of the lanes and rail corridor.
- Six framed storage aprons beneath the outer container/crane groups make
  those scenes read as yards rather than scattered props. They sit 0.08
  studs above the sand to avoid z-fighting, and remain noncolliding scenery
  below the playable level. Main circulation stays on the raised island.
- Imported studs still apply through the existing WorldStuds pass. No new
  lights, emitters, animation loops, UI, gameplay rules or material assets.
  Source changes are limited to Hub and World; all other source hashes
  are checked against the start of this pass.

Verification:

- Desktop Play: inspected a full centre overview and player-height court
  view against the reference principles. Roads, plot platforms and commons
  remain distinct; neighbouring presses and their signs remain visible.
- Walked from Plot 1 over its existing bridge onto the loop, down the south
  lane and across several commons positions. Reached the east spoke with
  full health, retained Plot 1 and WalkSpeed 28, and stayed on the new ground
  without rescue teleportation. Held F and crushed an object successfully.
- All new CommonsProps/planters and storage aprons are anchored and have
  collision/touch/query disabled. CommonsFloor is collidable and queryable,
  uses Studs, and retains SmoothPlastic's effective friction of 0.2.
- All 64 radial raycast samples hit solid commons ground at Y=1.44, above
  the rescue threshold. Six aprons sit at Y=-2.92, clear of the sand plane;
  exactly one striped workshop remains in the scene.
- Fresh iPhone 17 Pro landscape simulation inspected for readable ground,
  clear controls and the unchanged lower-left thumbstick area. This does
  not establish physical-phone frame rate or touch quality.
- Fresh Output checked: client clear; server only existing disabled Studio
  DataStore API messages. Place-only material variants and both mesh folders
  retained. Build and scoped whitespace checks pass; changed files use LF.
- Studio is left in Play at the default desktop viewport, with normal
  camera/HUD and the player standing on the new commons for review.

Review on a physical phone, then save and Publish the existing place. Saving
and online rankings remain outside this visual pass's checks.

Earlier environment passes are recorded below.

## Second art pass, 2026-10-21

The existing environment-only server exception applies to this follow-up.
Edits are confined to World, Hub, Kit/Build and Kit/YardProps plus docs.

- Clear colour blocks: sand #C49342, lane #4D5358, light kerbs #B8BCB6,
  existing blue-grey plot platforms, green #5AB633 cliff caps. Containers
  use saturated cobalt, teal and red; cranes are yellow with orange accents
  on the new workshop. Existing plot and press colours are unchanged.
- Built and inspected the south-west crane/container scene first, at player
  height and from above, then reused its scale around the perimeter. Six
  grouped yards replace eight smaller scattered stations. Two large static
  yellow cranes carry toy scrap cars; stacked containers, large banded scrap
  blocks and cable reels make readable silhouettes. All remain on the apron.
- Added one compact teal workshop with yellow/cream striped awning and
  grouped tool crates. The existing hub entrance is reused with small yellow
  collars, rather than adding another gate. Hub stations are fewer and their
  workshop groups are 1.5 times the previous scale, clear of bridge mouths.
- Cliff base modules still overlap to enclose the map. Upper tiers vary in
  height and retreat 15-22 studs, exposing broad terraces. Grass caps are
  3.5 studs thick, with tree groves on low and high ledges, bushes and rock
  outcrops. Distant hill caps are thicker too. Greenery remains at the edges.
- New YardDay preset: warmer ambient daylight, softer shadows, exposure
  -0.12, reduced bloom/haze and no sun rays. World maps the existing Day
  choice to YardDay; other lighting presets retain their previous settings.
  Config and shared UI helpers are unchanged.
- YardProps adds cableReel, yardScene and workshop helpers; container,
  vehicle, cluster and crane accept optional scale arguments. Existing calls
  remain valid. New scenery is anchored with collision/touch/query disabled,
  has no scripts or emitters, and adds no decorative lights.

Verification for this pass:

- Studio Play: inspected the initial corner, complete overview, normal plot
  camera and workshop approach. Sand/lanes/plots read distinctly, neighbouring
  plots remain visible, and the perimeter groups fit outside functional areas.
- Bounding-box checks found no perimeter yard/workshop overlap with any plot,
  scrap-shop tab or hub footprint. All EnvironmentProp parts passed anchored,
  noncolliding, nontouching and nonquerying checks. Solid floor and boundary
  collisions and all bridge/path geometry remain in place.
- Spawned on Plot 1, held F and crushed an object, walked to both scrap-shop
  pads, then crossed the bridge to the hub. No press or gameplay source edits.
- iPhone 17 Pro landscape simulation (750 x 381 viewport): normal HUD and
  crane-corner views inspected. Controls/thumbstick remain clear; UI is
  unchanged. This is visual emulation, not a physical-device FPS benchmark.
- Approximately 7,094 parts versus the previous idle scene's 6,685 (+6.1%),
  44 lights versus 46, and 16 emitters unchanged. Counts fluctuate during Play.
- No new game-script errors: client Output clear; server only existing
  StudioAccessToApisNotAllowed messages for saving/global rankings. Place-only
  ObjectMeshes (13) and PressMeshes (5) retained. Rojo build and diff checks
  passed; changed files use LF. Studio returned to Edit/default viewport.

Remaining: review on a physical phone for frame rate and touch usability, then
Publish from the existing place. This pass does not verify persistence or the
full progression/smelting cycle. The earlier rescue-message limitation below
is unchanged.

The following notes record the first completed environment pass.

## Completed 2026-10-21

Willem approved the scoped server exception ("yes you can do everything").
The latest environment-only request supersedes the earlier press-restyling
proposal. Press appearance, animation, gameplay, UI, economy, ownership and
interaction positions remain unchanged.

- World: muted sandy apron replaces the orange lava, glow, falls and embers.
  Warm-grey stepped cliffs have separate green caps, grouped perimeter
  trees and terraced distant hills. Eight sparse container/vehicle/scrap
  stations and two static cranes frame the yard.
- Build.path and Build.bridge: concrete finishes, existing kerbs and walking
  geometry, painted arrows, crossings and restrained yellow edge marks.
  Shared block/stud/lighting helpers are unchanged.
- New server/Kit/YardProps: reusable containers, toy scrap cars, cable reels,
  tool cabinets, crates, drums, scrap bins, banded cubes, short work lights,
  cranes and a CRUSH IT gate. All new prop parts are anchored and disable
  collision, touch and queries. No new animation loops or particle emitters.
- Moat and PlotDecor: low workshop clusters replace most garden dressing.
  Plot props remain under Decor so existing press-clearance parking works.
- Hub: sparse workshop stations and short shadowless lights; the old fountain
  becomes a scrap display with the same solid collision footprint. The cobalt
  entrance frames the existing road; its posts and hanging cube are decoration.
  The sign reads from either approach.
- Existing blue-grey workshop surfaces, bright sky, presses and UI are retained.
  The existing music 113892640002952 was confirmed loaded and playing.

## Studio verification

- Rojo sync confirmed; project build and whitespace checks pass, LF endings.
- Desktop Play: inspected normal-height and overview composition; spawned on
  Plot 1, held F and crushed an object. Walked the service lane to both
  scrap-shop pads, then across the existing bridge to the hub.
- Unowned Plot 8: invoked the existing buildPress on its model at tier 13,
  then restored tier 1. Six decorations parked; all 11 returned and the
  parking folder was empty. No player progression was changed.
- Every EnvironmentProp descendant checked: anchored, noncolliding,
  nontouching and excluded from queries.
- Fresh idle scene: 6,685 parts, 46 lights, 16 emitters versus the previous
  scene's 7,078 / 105 / 77. Counts vary slightly during crushing. This is
  an instance comparison, not a physical-phone frame-rate benchmark.
- iPhone 17 Pro simulation: fresh landscape and portrait sessions inspected
  (game orientation Sensor). Normal layout keeps the thumbstick area clear.
  Book, Shop and Rewards open/close and fit landscape bounds through the
  existing Style.setOpen helper; ShopHud.OpenShop opens the shop.
  Mouse targeting in the notched simulator is offset, so this does not
  establish successful physical touch/button activation.
- Changing an already-running desktop session to phone size can retain the
  open leaderboard over the crush area. A fresh phone session starts with
  the leaderboard collapsed. UI is excluded from this environment pass.
- Fresh Play: no client errors. Server Output only reports existing disabled
  Studio API access for DataStore saving and global rankings. Temporary QA
  command errors during an earlier session were not game-script errors.
- Studio-only ObjectMeshes (13) and PressMeshes (5) remain intact.
  Studio returned to Edit mode and default viewport; no publishing.

## Remaining checks and retained behaviour

Physical phone touch/performance, upgrade/rebirth transitions during real
progression, and the complete pickup/deposit/smelt/collect loop remain manual
checks. Paths and pad access were checked, but not a completed smelt sale.
Saving/rankings require a suitable API-enabled test environment.

The sandy lower apron still participates in the existing off-plot rescue:
it is scenery below the playable routes. Its threshold/collision are retained.
The existing "Ouch, hot lava!" rescue message is unchanged because player-facing
UI text is excluded from this pass; it can be revised separately.

Review and Publish from the existing Studio place, which contains the meshes
that a standalone Rojo build does not include.
