# Toy workshop theme

## Implemented, 2026-10-20

The existing `Island` palette in `shared/Kit/Style.luau` now gives the
server-built plot and hub platforms blue-grey studded tops, navy borders,
lighter bridge decks and steel-coloured island sides. Its legacy `grass`,
`wood` and other keys remain compatible with the existing builders. This is
a finish change: bridge planks, paths, elevations and collision shapes are
unchanged. The pad is lighter blue so the press reads against its base.
The existing bright Day sky is retained.

UI uses #13172A outlines, quieter studs, blue-grey bolted modal casings,
coloured header accents and a cobalt zone plate. Money and purchase actions
retain green. `Style.workshopPanel(frame, accent?)` and
`Style.pressureGauge(parent)` are additive helpers; the latter returns a
dial and needle. The HUD needle responds to holding CRUSH/F/R2, without
changing press timing or damage. Existing Style signatures are unchanged.

Phone layouts keep the leaderboard shortcut away from CRUSH, separate the
zone plate from goal text, and move the portrait scrap display above the
thumbstick/jump area. The existing hidden `Upgrades` panel remains hidden.
The tutorial now resolves `Upgrades` before using it; the pre-existing nil
reference was producing an Output error every frame.

## World changes blocked by the server-file constraint

No files in `src/server`, Config, Store or Net were changed. No replacement
client map, runtime recolouring sweep, or Studio mesh edits were introduced.
The complete toy scrapyard is **not finished**: the lava exterior, brick
service paths, trees, bushes and lamp shapes still come from protected
server builders. Recolouring their shared palette cannot replace geometry
or hardcoded colours/materials.

When server visual edits are permitted, these are the concrete next steps:

| File | Required visual change | Preserve |
| --- | --- | --- |
| `server/Kit/Build.luau` | Give `Build.path` a concrete finish, flush painted arrows and occasional crossings. Add reusable anchored tool-cart, scrap-bin, tyre-stack, pipe-rack, container and work-light builders. New decorative parts should have `CanCollide`, `CanTouch`, and `CanQuery` false. | Existing path widths, heights, bridge endpoints, walking surfaces and builder signatures. |
| `server/Moat.luau` | Replace `edgeProps` tree/bush calls with those workshop props. Restyle existing bridge geometry as service decking. | Front bridge offset 16, width 9, shop opening and off-plot rescue behaviour. |
| `server/Hub.luau` | Replace garden clusters and fountain with low workshop props and an industrial sign feature; connect painted crossings to the existing landings. | Spawn, bridge gaps, road layout and clear routes between plots. |
| `server/PlotDecor.luau` | Reuse the existing crates, heap, crane, bales and pipe builders. Put incoming stock on the conveyor side, carts outside the bed clearance, and collected scrap beside the existing pile/smelter route. Replace the garden lamp with a low work light. | `Decor` grouping used by `Plots.clearProps`, animated crane tags/axis and clearance for the largest press. |
| `server/World.luau` | Replace the 2048-stud orange sea, drifting blobs, lavafalls and tall cliff ring with a blue-grey industrial backdrop, low yard walls, colourful containers and a few distant crane silhouettes. | Playable layout and sightlines. The current sea participates in the rescue system: keep the exterior clearly outside playable routes rather than creating apparently walkable ground that teleports players. |
| `server/PressBuilder.luau` | Apply cobalt to selected frame surfaces, chrome to pistons, a clear bed outline and restrained work lights; keep orange for selected higher-tier machinery. | Bed/ram dimensions, returned offsets, pivots, welds, animation alignment and collision flags. Inspect mesh textures before changing tint. |

`ReplicatedStorage.ObjectMeshes` (13 children) and `ServerStorage.PressMeshes`
(5 children) exist in the connected Studio place and were left intact.
Future mesh changes need inspection in that place; rebuilding from the Rojo
project alone would omit these assets.

## Validation

- Rojo build and `git diff --check` passed; protected file diffs are empty.
- Desktop Studio Play at 1636 x 753: held F crushed an object, pressure
  needle reset on release, Book/Shop/Rewards opened and closed using their
  buttons, and `ShopHud.OpenShop` opened the shop. Walked from the plot via
  the existing bridge onto the hub.
- iPhone 17 Pro simulation: inspected landscape (750 x 381) and portrait
  (401 x 778). Game orientation is `Sensor`; game ScreenGuis use Sibling
  ZIndexBehaviour and CoreUISafeInsets. Inspected modal screenshots and
  checked open/close state and bounds through the shared modal helper.
  Physical-device touch testing is still recommended; simulator mouse
  targeting has an offset on the notched viewport.
- Reapplying workshop panel styling does not duplicate decorations.
- The baseline tutorial error was fixed. Studio API access is disabled,
  producing DataStore/global-leaderboard access errors; saving and online
  rankings were not verified. Do not enable production data access merely
  to run a visual check.

After the remaining server work, test the smallest and largest presses,
upgrade/rebirth transitions and parked-prop restoration, then walk the
incoming-stock -> press -> scrap -> smelter route on desktop and phone.
Publish from the existing Studio place after reviewing the result.
