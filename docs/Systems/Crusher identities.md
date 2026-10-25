# Crusher identities — 25 October 2026

The 25 October expansion finishes the code-built model pass: thirty-five
authored rigs and the existing five imported templates cover all forty types.
The twenty-two additional replacements cover every Common, Uncommon and Rare
type that is not an imported special. All five imported models, the thirteen
Epic/Legendary shapes, gameplay stats and saved type IDs remain in place.

| Type | Silhouette and mechanical identity |
| --- | --- |
| Starforge | Large filled five-point crown with a ruby centre, gold forge bell and open angled supports. The crown turns slowly. |
| DragonJaw | Long red snout, amber eyes, swept horns, wings and gold lower fangs. The upper skull/fangs hinge down around a rear pivot. |
| BlackHole | Dark spherical hammer inside a broad horizontal purple/gold accretion disc, with three tall field claws. Disc shards rotate. |
| Clockwork | Oversized clock dial, independently turning hands, counter-rotating exposed gears and a crown-shaped gold stamp. |
| FactoryHeart | Four open pump towers, four telescoping rods and a large pink mechanical heart that gently beats. |
| Quantum | Floating cyan nucleus inside crossed gold/cyan gyroscope rings above a finned die; rings turn about the core. |
| Titan | Massive rectangular weight, armoured navy cheeks and twin exposed shock columns. |
| Laser | Open triangular pylons, paired cyan focusing lenses, pink crystal and luminous die edge. |
| Plasma | Twin segmented glowing reactor towers, rounded domes and a rotating induction ring. |
| Gravity | Vertical circular field cage, orbiting pale weights and a purple spherical hammer. |
| Quake | Low wide outriggers, shock columns and an enormous orange barrel hammer. |
| Cyclone | Large six-blade rear turbine, dark circular housing and twin telescoping guide rods. |
| Mecha | Broad armoured shoulders, robot visor and a giant articulated-looking four-knuckle fist with a gold thumb. |
| Mega | Oversized purple hydraulic cylinder with gold flanges, pressure dial and a broad die. |
| Thunder | Twin Tesla columns, yellow insulators, conducting caps and blue lightning braces. |
| Frost | Tall navy-edged ice spikes, pale crystal facets and a frozen angular die. |
| Furnace | Orange insulated furnace, grilled hot window, twin chimneys and a heated stamp. |
| ScrapShark | Long blue nose, side eyes/gills, triangular dorsal fin and hinged toothed jaw. |
| SteamHammer | Tall copper steam risers, large pressure gauge, rotating valve and a cylindrical pile driver. |
| JunkyardJaw | Asymmetric excavator boom with large pivot bolts and a hydraulic two-finger grabber. |
| Cobalt | Green twin pressure tanks, capped double pump and twin telescoping rods. |
| Gearbox | Broad exposed drive casing with two counter-rotating toothed gears. |
| Flywheel | One enormous offset flywheel, visible bearing and narrow driver linkage. |
| Pneumatic | Rounded cyan air tanks and an oversized front pressure gauge. |
| DoubleStamp | Two separate green stamps and cylinders; alternate ordinary strokes, finish together. |
| Boiler | Round copper-jacket boiler, dome, short exhausts, gauge and bell hammer. |
| Conveyor | Long guarded roller bed with seven separate rotating axles and a gate press. |
| Bumper | Simple low red starter press, rounded pump cap and compact bumper die. |
| Steel | Taller blue uprights, steel pump housing and a front pressure dial. |
| Clamp | Open-sided orange C-clamp, offset arm and broad pressure shoe. |
| Spring | Twin exposed helical yellow return springs and a compact yellow stamp. |
| Screw | Threaded pressure screw and a slowly turning top handwheel. |
| Rivet | Slim offset red arm, round raised anvil and narrow punching pin. |
| Bottle | Three bottle-shaped guide moulds, feeding chute and ribbed flattening sole. |
| Bench | Low blue workbench vise, exposed rails, threaded handle and a horizontal sliding jaw. |

These are anchored Roblox Part/WedgePart rigs built by code. No asset IDs,
Blender imports or changes to stored meshes are required. Navy structures,
large coloured armour and a few bright accents match the toy-factory style.
Open centres and the existing bay envelope preserve background visibility.
Common rigs use simpler shapes and fewer visual effects. Rare rigs have larger
distinctive mechanisms, while Epic/Legendary retain their hero ornaments. All
forty now have an authored or imported model; Studio art review of the new
twenty-two remains required. Code-built models are not custom mesh artwork.

## Routing and animation

`shared/CrusherIdentityRig` builds the thirty-five shapes and returns the existing
CatalogCrushers rig contract. The catalogue delegates only these IDs. Bay and
pedestal routing now asks the catalogue before trying an imported template;
the static Index builder follows the same path. Held Tools inherit the same
sanitised previews. No type, rarity, price, stat, modifier, inventory schema or
production rule is changed. Existing special-template fallback remains.

Actual crushing uses existing CatalogCrushers server tweens and contact
timing. Piston rods telescope with fixed upper endpoints; DragonJaw rotates
around its rear hinge. Whole rigs fit uniformly, including conservative full
rotation extents of every animated ornament. Work surfaces and available
input space come from the real fitted ram geometry. Bench has a horizontal
working chamber instead of overhead ram clearance. Conveyor's moving axle
sweeps include the X axis; raised anvils, jaw beds and rollers have explicit
bed heights.

`CrusherIdentities.client` only animates tagged, equipped Workspace models
that have an InventoryId. Index, held Tools and rolling previews remain static
under this controller. Only the nearest four equipped rigs within 105 studs
animate, selected five times per second and updated at most thirty times per
second. Animation uses absolute server time and captured rest transforms;
it does not accumulate rotation. Culled or untagged rigs restore rest poses.
Late-streamed ornament descendants are collected without recapturing the
already animated transforms. Disappearing nodes are discarded safely.
Only rigs with actual ornaments or pulsing parts receive the animation tag;
twenty plain starters therefore do not displace a nearby clockwork or turbine.

Core effects are subtle local transparency pulses on a few Neon parts. There
are no added sounds, PointLights, ParticleEmitters, per-hit allocations, hit
listeners, screen flashes or camera shake. No extra audio competes with the
separate crusher-feedback mixer. This pass can be applied independently of
the feedback and upgrade-clarity patches.

## Supplied offline verification and limits

Offline execution runs the actual builder and catalogue modules with matrix
transforms and disposable Roblox API substitutes. It samples every ram at
21 stroke positions, each ornament through a full revolution, and a translated,
rotated bay placement. It checks anchoring, collision flags, bay extents, bed
clearance, piston endpoints and return-to-rest endpoints. The existing catalogue
suite also runs all twenty-nine roster designs. Client runtime checks exercise
twenty rigs, motion/culling, restored poses, late streamed descendants, source
removal/re-addition, static previews and constant instance counts.

The contact sheets render geometry exported from the real Luau builders, with
Blender review lighting. They are not Studio screenshots; Roblox lighting and
materials will differ. Offline tween checks validate endpoints, not Roblox
interpolation or replication. Studio Play, clean Output, real roll/equip/held
previews, input squash, replication and appearance remain unverified here.
Phone layout work remains deferred. See [[../Apply-crusher-identities]].

## Expansion verification — 25 October 2026

Offline assertions: 189,343 identity geometry/endpoint checks over all thirty-five
rigs; 12,010 existing catalogue checks; and 117 local animation/coverage checks.
The runtime fixture places twenty plain starters in front of five decorated
rigs and confirms that four decorated machines animate, the fifth stays still,
culling restores transforms and steady animation creates no Instances. All
forty types are covered by an authored rig or an unchanged imported template.

The roll-presentation fixtures and all 335 CrusherRules assertions also pass.
All source files compile with LF endings. Config, roster, production rules,
Store and Net remain unchanged by either 25 October patch. The Studio results
below describe the earlier thirteen-rig pass only. Fresh Play verification of
the new twenty-two, real held models, actual tween interpolation, streaming and
engine performance still needs the connected Studio agent.

## Integration and Studio verification — 24 October 2026

Applied cleanly over the uncommitted crusher-feedback work, including its
independent cleanup watcher, and retained Daily Spin, upgrade clarity, Equip
Best, the guided tutorial and Blender scenery. No price, production, save or
remote configuration was changed by this patch.

Completed in fresh Studio Play:

- CrusherIdentities.spec: 101,714 checks passed for all thirteen rigs, including
  stroke samples, translated/rotated placements, moving ornament sweeps, safe
  parts, piston endpoints, stationary frames and actual tween return to rest.
- CatalogCrushers.spec: 12,227 checks passed across all 29 roster designs.
  Existing regressions also passed: CrusherFeedback 198, CrusherRules 335,
  DailySpin 285, CrusherUpgradeView 441 and SpecialCrushers 52. Total: 115,252.
- All 40 static collection previews regenerated. The Legendary Index filter
  showed eight cards, and the new models were inspected in a desktop screenshot.
  The working bank was also inspected with twenty equipped crushers, including
  all thirteen replacements, the three imported specials and lower rarities.
- The live selector chose four nearby rigs; seven ornament/glow entries changed
  over a 0.6-second sample. Instance counts stayed constant across the thirteen
  identity rigs (648 descendants). Moving away restored all 32 recorded ornament
  transforms/transparencies to their server rest poses, including orientation.
- A five-pedestal roll produced five offers and cached the new identity shapes
  as silhouettes. A normal purchase added a crusher. Quantum unequipped into
  the backpack, displayed its new held mini model with all 52 parts welded,
  then equipped again successfully.
- TwinTitan, GoldenKing and Toyzilla retained SpecialTemplate markers and the
  imported-model suite passed. No imported assets or place-file pivots changed.
- Output contained only existing disabled-DataStore and asset 203785492 type
  warnings. No new identity, rig, feedback or other game-script errors appeared.
  Rojo build, scoped whitespace and LF checks passed.

These tests used disposable Studio mock profiles, not live saves. Full manual
front/back art review of every rig, real stream-out/re-entry, multiplayer/device
performance and phone work remain outstanding. Studio was returned to Edit
mode and the temporary Play fixtures were discarded. Nothing was published.

## Combined-patch Studio verification — 25 October 2026

The expansion now passes actual Studio suites: 189,343 identity checks across
35 authored rigs, 12,010 catalogue checks, 3,656 roll-presentation checks and
1,311 existing gameplay/feedback/spin/upgrade/import checks (206,320 total).
All forty preview models regenerated; the five imported-template tests passed.
No place assets were edited by this integration.

A disposable mock profile equipped all twenty-two new rigs within a working
24-machine factory. All 24 had production inputs at the sampled moment, and
a desktop screenshot was reviewed. ScrapShark was unequipped, held with 32
unanchored/noncolliding parts and 31 welds, and equipped again. Collect, Sell
and Equip Best actions passed. A separate client fixture with twenty plain
starters and five decorated rigs selected four decorated machines, animated
their ornaments without increasing its 737 descendants, and restored positions
and orientations when the camera moved away. This is a culling fixture, not
an actual network streaming test or frame-time benchmark.

Rojo build and whitespace checks passed. Output contained only existing
disabled-DataStore and asset 203785492 warnings. Full front/back/held art review
of every type, real stream-out/re-entry, human audio and device performance
remain outstanding; no phone work or publishing was performed.
