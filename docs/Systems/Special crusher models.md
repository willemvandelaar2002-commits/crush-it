# Imported special crushers — 2026-10-22

## 27 Oct: six crate crushers (assets/crate-crushers)
Ducky Dynamo, Wind-Up Wrecker, Gumball Gobbler (Epic, Titan band) and Arcade
Claw (Legendary, Quantum band); Disco Destroyer and Kraken Clamp (Mythic since 29 Oct, Mythic production band). **Crate-only**:
`C.CrateTypes`, not in their rarity's roll list, so normal rolls, roll odds and
free random drops (spin, rewards, quests) are unchanged; `C.rarityOf` finds
their tier through `def.rarity`. Index shows CRATE ONLY. Tiers/bands are
provisional (Willem: fill the crates).

- Templates: `ServerStorage.SpecialCrusherMeshes.<Id>` (place-only: save/publish
  the place). Studio's importer keeps studs 1:1 and turns the meshes 180° about Y
  (part rotations stay identity); fronts end up like the Mythics (default yaw π).
  Gumball Globe set to Transparency 0.83 (template and at build).
- `SpecialCrusherAssets`: `kit="motion"` entries generated from the pack's JSON +
  FBX (per part: mesh box centre/size and authored pivot, FBX space; motion kinds
  move / rotate / extend; parents for ears and claws; contact parts).
- `SpecialCrushers.rig` works out the FBX->world mapping from the Frame (scale)
  and the part furthest from it (the turn), pre-computes every moving part's pose
  at the Blender curve keys, and a strike tweens key to key (no per-frame loop).
  Contact (key 33/71) lands at the shared feedback hit time; the return takes
  ~55% of the cycle. Pistons stretch from their fixed end, children follow the
  parent then hinge.
- Checked in Play (4 s sampling, 6 bays): shaft tops fixed and shafts meet the
  heads, frames still, ears/claws stay attached, Kraken jaws close 4.6 -> 3.5 and
  pistons stretch 1.0 -> 1.5.


Five imported templates now participate in the existing collection, equipment,
levels and automatic production. They use the existing rarity weights, prices,
individual upgrades and production formulas. No new abilities, bonus payouts
or mesh IDs were invented.

| Template | Roll rarity | Existing production band |
| --- | --- | --- |
| TwinTitan | Epic | Titan |
| RocketPress | Uncommon | Cobalt |
| Magnetron | Rare | Mega |
| GoldenKing | Legendary | Quantum |
| Toyzilla | Legendary | Quantum |

Existing types remain in their pools. Adding models divides selection within
a rarity; the probability of the rarity itself is unchanged. Stable instance
IDs, modifiers, levels, equipment and existing saves are retained. The legacy
tier migration uses an explicit six-type list, so adding types cannot change
what an old tier-13 profile receives.

## Place assets and measurements

Inspected the actual imports: each outer Model contains another Model, then
one Frame MeshPart and one Ram MeshPart; TwinTitan has Ram_L and Ram_R.
Their ground pivots were retained, but the initial imported dimensions were
100 times the manifest sizes. All 11 source MeshParts were anchored and the
five models moved from Workspace into ServerStorage.SpecialCrusherMeshes.

Save/publish the place to retain this folder, its imported materials and the
anchoring changes. Rojo manages only Shared, Server and Client; it does not
manage or remove this folder. Existing PressMeshes and ObjectMeshes remain.

The supplied original manifest is copied to
`assets/special-crushers/asset-manifest.json`; runtime measurements are in
`shared/SpecialCrusherAssets.luau`. Its Vector3 values convert the manifest's
width/depth/height order to Roblox width/height/depth. Single and twin hydraulic
strokes are 3.525 nominal studs; Toyzilla's jaw stroke is 2.63. Bed tops are
1.62, or 2.5 for Toyzilla.

`server/SpecialCrushers.luau` clones a template and locates components recursively,
including named Model wrappers containing multiple parts. It normalises the
import's uniform unit scale and uniformly fits the complete assembly into the
configured machine envelope. Source meshes, pivots, materials, tints and maps
are untouched. The whole clone faces the plaza: these actual FBX imports face
-Z, so placement includes a half-turn. Optional template attribute BayFrontYaw
(radians) overrides that facing for a differently oriented future reimport.

All spawned parts are anchored and non-colliding. Frame components remain
stationary. Named ram assemblies translate down their scaled manifest stroke,
then return to the exact captured rest transforms. TwinTitan alternates heads
on ordinary strikes and uses both on completion, without extra rewards. Inputs
fit the available clearance and squash through the existing object helper.
Missing or malformed templates fall back to the existing press builder.

## Desktop Studio verification

All five were rendered and operated in actual collection bays, facing the
plaza. Toyzilla's eyes/jaw, GoldenKing's crown, Magnetron's arch and both twin
heads were visually inspected. Current fitted width / height / depth:

| Template | Fitted studs |
| --- | --- |
| TwinTitan | 8.519 / 9.400 / 6.022 |
| RocketPress | 8.325 / 9.400 / 6.192 |
| Magnetron | 8.600 / 9.317 / 6.529 |
| GoldenKing | 7.546 / 9.400 / 5.799 |
| Toyzilla | 8.403 / 9.400 / 5.982 |

These fit the current 8.6 × 9.4 × 8 machine envelope and its raised stage
inside the two-tier bays. Stroke tests sample the down position and return:
static frame, correct moving component count, scaled manifest travel, anchored
parts, material/map preservation, TwinTitan alternation and nested wrappers.
Rules tests cover roll reachability, unchanged production bands, old migration
and saved special instances. A levelled TwinTitan moved to bay 13 and survived
mock-store reload with its ID, level, cash and ownership preserved.

Final suites: 129 gameplay assertions and 52 rig assertions passed. A runtime
missing-folder test built TwinTitan through the legacy fallback, then restored
the five templates and confirmed that re-equipping used its imported model.
Rojo build and LF/whitespace checks passed.

Studio Output showed no gameplay-script errors in the final integration test.
Studio DataStore API access remains disabled: persistence here is a mock-store
roundtrip, not a published rejoin test. Desktop only; phone and live multiplayer
performance are not verified by this pass. Save the place assets before publishing.
