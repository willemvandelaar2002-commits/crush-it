# Bright scrapyard island environment

## Scope and completed work — 2026-10-20

The latest environment-only request supersedes the earlier suggestion to
restyle hydraulic presses in [[Toy workshop]]. Press appearance, progression,
animation and functionality are intentional and must remain unchanged.
UI, gameplay, economy, layout, ownership and interaction positions are also
outside this pass.

Completed within the existing permissions: the shared Island environment
palette now has fresh green foliage, warm brown trunks and warm-grey rocks
and cliffs. Blue-grey workshop platforms remain as they were. No UI helper
or press code was changed.

## Narrow server exception needed

The pasted request explicitly says to request an exception before editing
protected world builders. The following edits are proposed, not yet applied:

| Protected file | Environment-only changes |
| --- | --- |
| `src/server/World.luau` | Replace `sea`/`lavaFall` visuals with a muted tan floor and sparse static surface variation; remove exterior glow, embers, flowing textures and lava-drift instances. Keep the existing exterior floor collision/elevation and enclosure. Vary stepped cliff heights/depths/ledges; use a separate green cliff-cap colour. Add grouped perimeter trees, sparse container/vehicle/scrap clusters and two low-detail static cranes below the cliff skyline. |
| `src/server/Kit/Build.luau` | Update only environment helpers: concrete `path` and `bridge` finishes, kerbs and occasional flush crossings/edge markings at existing widths and connections. Add reusable simple anchored container, cable-reel, cabinet, barrel, crate, scrap-bin, cube-stack, vehicle and work-light helpers. Decorative additions disable collision, touch and query; retain existing walking-surface collisions. Do not change `block`, `studs`, global lighting or other helpers in a way that changes press appearance. |
| `src/server/Moat.luau` | Replace most `edgeProps` trees/bushes with a few deliberate workshop clusters; retain greenery at selected edges. Keep island dimensions, bridge endpoints, opening widths and `Moat.start` rescue logic unchanged. |
| `src/server/Hub.luau` | Replace most roadside garden clusters with sparse workshop props and short soft work lights. Remove the decorative lava fountain glow/particles. Use the existing sign/landmark area for a CRUSH IT entrance feature with a suspended cube only if a clearance check confirms it fits, retaining existing ground-level collision footprints and spawn/road positions. |
| `src/server/PlotDecor.luau` | Reuse existing heap/bales/crates/pipe builders, add a few cable-reel/cabinet/bin clusters, and replace the decorative streetlamp with a short work light. Keep additions inside the `Decor` grouping so the existing largest-press clearance/parking logic continues to work. Preserve gate name labels, signs, stations and all interaction positions. |

No exception is requested for `PressBuilder.luau`, `Plots.luau`, game logic,
Config, Store or Net. Studio-only ObjectMeshes and PressMeshes are preserved.
New props will use seeded placement and no per-frame scripts; lighting will
be sparse and shadowless. A simple part/light count will accompany the full
Play test after approval.

Two dependencies explain why the palette alone cannot finish this task:

- `World` uses `theme.grass` for cliff caps, while `Hub` uses the same key
  for its workshop floor. A separate cliff-cap colour must be consumed in
  `World` to make cliffs green without making the workshop green again.
- The orange exterior is also the existing off-plot rescue surface.
  Preserve its collisions and rescue threshold; sandy areas below the
  playable platforms remain outside the routes. `Moat.start` currently
  displays "Ouch, hot lava!". Changing that message would alter player-facing
  text and is excluded from this environment-only exception; flag it for
  a separate decision if desired.

Full environment composition, new prop clearance and final normal-height/
overview verification remain pending approval of the five-file exception.

## Palette verification

- Rojo build and whitespace checks passed. This pass changes only the
  environment colours in `Style.luau` and documentation; protected-file
  and client-script diffs are empty. Changed files use LF endings.
- Studio Play: inspected the current palette at player height and from an
  elevated overview. Fresh foliage is visible, but lava and blue-grey cliff
  caps remain until the server exception is approved. Full composition is
  not represented by this palette-only result.
- Confirmed spawn on Plot 1, held F to crush an object, and walked across
  the existing bridge to the hub. No new client script errors; server
  Output still reports disabled Studio API access for saving and rankings.
- Verified the palette used by the server: foliage `#69C14F`, cliff rock
  `#ACA699`. ObjectMeshes still has 13 children and PressMeshes has 5.
- Studio was already in Play mode and was left in Play for review. No
  publishing was performed.
