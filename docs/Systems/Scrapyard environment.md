# Bright scrapyard island environment

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
