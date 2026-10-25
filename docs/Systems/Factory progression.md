# Plot expansion and Coating Lab — 25 October 2026

The first plot upgrade becomes available when all 24 original bays are
unlocked and occupied by valid, individually equipped owned crushers. Mixed
rarities qualify; four active rarity sets are not required. The green world
UPGRADE PLOT board appears near the centre aisle. It charges the configured
cash cost once and grants six already-unlocked rear bays, for 30 total.

This is one expansion level in this first pass. Price is
`floor(BayCosts[25] * 10)` in `CrusherConfig.PlotUpgrade`; the first 24 prices,
all existing roll weights, pass/store IDs and level formulas are unchanged.
Ordinary Unlock cannot bypass the base 24-bay cap. Saved `crushers.plotLevel`
defaults to zero; level one preserves/repairs the paid entitlement to 30 bays.
Schema/store names stay unchanged and no inventory is reset or consumed.

## Higher caps (25 Oct)

Factory II also raises the upgrade caps (`PlotUpgrade.Caps` in CrusherConfig):

| Cap | Before Factory II | With Factory II |
| --- | --- | --- |
| Factory/roll upgrades (Damage, Speed, Yield, Luck) | 20 | 30 |
| Each crusher's level | 40 | 60 |
| Pedestals | 4 | 4 (own max) |

At a base cap the MAX hint says UPGRADE PLOT raises it. Saves keep raised
levels (load clamps to the highest caps). Prices follow the existing growth
formulas. Tests: `Tests/PlotCaps.spec` (13 checks). Add a row to `Caps` per
future plot level.

## Five plot stages — layout v2 (25 Oct)

Plan from Willem's ChatGPT concept pictures (look and feel only, not
construction plans). Measured in Studio first: at least 135 studs of empty
floor behind every plot before the factory wall, ~130 studs to neighbours.
A first blockout had a 6-bay row in the middle behind the wings; Willem
dropped it (too hard to see) in favour of the rear yard.

| Stage (plot level) | Bays | Adds | Caps (upgrades / crusher LV) |
| --- | --- | --- | --- |
| 1 Starter Workshop (0) | 24 | two floors per wing | 20 / 40 |
| 2 Factory II (1) | 36 | third floor on both wings (25-36) + Coating Lab | 30 / 60 |
| 3 Factory III (2) | 48 | rear yard: island, floor, road, both ground banks (37-48); fusion (todo) | 40 / 80 |
| 4 Factory IV (3) | 54 | rear yard upper floor, left (49-54) | 50 / 100 |
| 5 Factory V (4) | 60 | rear yard upper floor, right (55-60) | 60 / 120 |

- Every upgrade needs every current bay filled; costs 10x the price of its first new bay.
- Rear yard = the same bank builder as the wings (`CrusherPlots.bankWing`),
  shifted back by `RearShift` (-78) and not tilted; max two floors, normal
  stairs. Rows 7-10 (REAR LEFT/RIGHT, REAR UPPER LEFT/RIGHT).
- `C.bayFrame(layout)` gives the frame bay coordinates are in (wings tilted,
  rear yard not); use it instead of `wingFrame`.
- **Save conversion** (`CrusherRules.migrate`, `crushers.layout` 1 -> 2): v1
  bays 31-66 move down by 6; v1 rear-row crushers (25-30) go to the first
  free bay of the plot level, otherwise back to the inventory. Plot levels
  keep their number. Never removes a crusher; runs once.
- Tested in Studio: all specs pass (FactoryProgression 213 incl. conversion
  cases, Rows 1756, Rules 371, PlotCaps 16), clean Output; Willem's
  Factory III save converted (48 bays shown, 30 crushers still on bays).
  Stage screenshots were visual-only previews.
- Still to do: visual progression per stage; fusion extension + mechanic.

## Fusion and stage props (25-26 Oct)

**Fusion** (`C.Fusion`, unlocks at plot level 2 = Factory III): a main crusher
plus three unequipped, unfused copies of the same type become one fused
crusher. The main keeps its id, level, coating and bay; the three copies are
used up. Fused = 2x scrap value (`R.stats`), saved as `fused=true`, can't fuse
again (one tier). Type and rarity stay, so rarity rows still count it.
Server: `Fuse` action (`R.fusionProblem` checks everything, near the fuser
only); `R.fusionCopies` suggests the weakest unequipped copies.
Screen: `client/Fusion.client.luau`, opened by the FusionPrompt on your own
fuser; type list, main (arrows), three USED UP copies, result, FUSE then
CONFIRM. Fused crushers get a gold neon frame on their bay pedestal and show
FUSED on the plaque, in the Index and on the backpack tool.
Tests: `Tests/Fusion.spec` (16 checks).

**Fusion wing**: 34x34 floor sticking out left of the Collect Scrap hopper
(x -78..-112, z 44..78), its own island and blue/orange rim; the left plot rim
opens there from Factory III. Fuser (code-built, Blender model later) faces
the entrance; maintenance robot and crates beside it.

**Blender fuser (26 Oct)**: Willem's model lives in the place file at
`ServerStorage.FusionMeshes.FusionMachine` (20 MeshParts, scaled to 14.4 x 8 x
10, glass/neon set, no collisions; Willem must Publish to keep it). Code uses
it only when the template has the attribute `Ready=true`; otherwise the
code-built fuser shows. Placement turns it by its input rings and centres it
by its bounding box, so the imported pivot doesn't matter. First import came
in at 100x scale and renders black (vertex colours read as black; part Color
has no effect), so Ready is not set yet.

**Stage props** (`server/PlotStages.luau`, cumulative, built once, shown by
plot level): rim bolts and lamp collars recoloured per stage (yellow, orange,
silver, gold); Factory II cobalt road edging, compressor beside the right
stairs, tool trolley by the hopper; Factory III fusion wing, cyan pipes with
orange brackets; Factory IV cyan neon floor channels, pipe gauges;
Factory V gold-capped light towers at the front corners.

Checked in Studio: all specs pass, prompt opens the screen at the fuser,
screen layout checked with a made-up inventory (Studio-only preview hook),
props previewed for stage 5. Not yet done live: a real fuse (Willem's save has
no type with 4 copies; it would change the real save).

## Factory III — third floor (25 Oct)

Second plot upgrade (plot level 2). Becomes buyable once all 30 bays (the 24
originals plus the Factory II rear row) hold crushers. Price
`floor(BayCosts[31] * 10)` (`PlotUpgrade.Costs[2]`). It grants 12 bays at
once: a third floor on both wings (bays 31-36 left, 37-42 right), stepped back
on top of the upper floor the same way the upper floor sits on the ground
bays. Rows 6 and 7 (TOP LEFT / TOP RIGHT) join the rarity-row system.

- Built by `CrusherPlots.topFloor`: step under the top bays, a deck that
  roofs the upper bays, back wall, columns, rails and rear support columns
  (skipped where they would land in the Factory II rear row). The upper
  floor's parapet hides once the top floor is built.
- Access: a green **lift pad** at the top of each wing's stairs on the upper
  walkway (press E, "Go up") and one straight above on the top walkway
  ("Go down"). Prompts only work once the floor is built.
- No ghost or BUILD sign: the floor stays hidden until bought, then rises
  into place like the upper floors do.
- Board: shows FACTORY III, +12 BAYS · 3RD FLOOR · HIGHER LV CAPS, grey with
  "Fill all 30 bays" until full; level plate reads FACTORY III after.
- Caps with Factory III: upgrades 40, crusher levels 80.

Checked in Studio: all specs pass (FactoryProgression 134, Rows 1138,
PlotCaps 15). Third floor shown on a plot as a preview (no save change):
stepped look, rear supports, lift up works. Not yet seen live: the real
purchase and its rise animation (needs a profile with 30 full bays and the
cash; not done on Willem's save). Later, with more plot upgrades, the
Factory II rear row may be moved up as well (Willem, 25 Oct).

## World upgrade

The new six-bay row is a low rear extension, not another tall wall of machines.
The original 24 bay coordinates stay unchanged. The new centres are x=-25..25
at z=-43, with a 70x24 deck spanning z=-54..-30. It overlaps the old floor;
two central rear border blocks open a walkway. The narrow extension remains
inside the factory scenery's existing conservative radial envelope. No hall,
train, bridge or surrounding display geometry is moved.

Factory II adds gold entrance trim, a level plate, corner caps, rear lamps and
the new Coating Lab. Hidden structures are non-colliding/non-queryable until
earned; plot release hides them and restores the rear border. The fifth row
uses the existing row-bonus system. Original ground/upper-floor purchasing is
retained. Coating/plot controls are physical SurfaceGuis, with shared chunky
Style and Sibling behaviour. Their Content.Visible state is mirrored to the
owner's interactive copies, avoiding a disabled-SurfaceGui visibility trap.

## Coatings

The lab unlocks with Factory II. Hold an **unequipped** crusher, click one of
four finish cartridges, review its name/current-to-next finish and output,
then press the separate confirmation button on the machine. Prices use cash
earned from selling scrap. No duplicate crushers or other materials are consumed.

| Finish | Scrap-value multiplier | Price factor |
| --- | --- | --- |
| Polished | 1.50x | 4 |
| Frost | 1.65x | 7 |
| Fire | 1.80x | 10 |
| Charged | 2.00x | 16 |

Cost is `floor(rarity.price * factor * (1 + .15*(level-1)))`. These are initial
balance values in Config. One finish replaces the previous modifier; they do
not stack. Identical/weaker finishes are rejected without charge. Existing
Polished/Charged/Rusty roll multipliers remain unchanged. Frost and Fire are
craft-only entries; the weighted roll modifier pool remains the original four.
Damage, HP and strike speed are unaffected by coatings. Existing row bonuses
still multiply separately after re-equipping. The preview explicitly excludes
row bonuses while the crusher is unequipped.

The server chooses the held inventory ID and creates a 20-second quote token.
Confirm checks ownership, proximity to the owner's lab, plot level, unchanged
finish/level/price, matching held ID, expiry and cash. It then charges and updates
the same instance in one non-yielding transaction. Replays, stale/switched/foreign
targets and unaffordable requests cannot charge or stack finishes. Quotes live
only in the session, not saves. Existing CrusherState carries the optional quote;
no remote names are added. Quest tokens and shop products retain their rules.

The type, rarity, level and inventory ID survive coating, so row eligibility
and collection protection remain intact. A changed modifier refreshes the Tool
even when its level stays the same. Owned previews, held mini models, working
bays and offer displays use the shared `CrusherFinish` helper. It adds three
small anchored finish details near the base; Polished also makes selected
procedural armour metallic. Original paint, ram transforms and imported texture
maps remain identifiable. No per-hit particles, lights or sounds are added.
After confirming, the refreshed crusher returns to the backpack; hold/equip it
again normally. Imported templates in ServerStorage are never edited.

## Verification

Offline fixtures execute the actual modules using disposable API adapters:
FactoryProgression 102, rarity rows 776, CrusherRules 341, UpgradeView 441,
DailySpin 285 and QuestRules 12 checks. World geometry/control checks pass 72;
actual server-action/proximity integration passes 9; Tool finish refresh passes
3. Coverage includes double purchase/confirm, cash failures, partial/corrupt
rows, five-row bonuses, migration/entitlement repair, all four finishes, no
weaker finishes, quote expiry/ownership/held-item changes, effect reuse, gate
reset and the existing hall envelope. Existing rule tests retain base unlock
coverage through BaseMaxBays; the new suite covers the paid 25–30 entitlement.

No Studio is connected here. Real visual quality, shadows, walk access, owner
GUI input, sound/texture permissions, held welds, streaming/replication and
performance still require fresh Play verification. See
[[../Apply-factory-progression]]. Desktop only. More expansion levels and any
future elemental combat/status effects are not included in this first pass.

## Connected integration — 25 October 2026

Applied cleanly while preserving rarity rows, quests, colours, the standing
wheel and newer world edits. Rojo build passed. Fresh Studio suites passed:
FactoryProgression 102, CrusherRows 776, CrusherRules 341, UpgradeView 441,
DailySpin 285, QuestRules 12 and RollPresentation 3,656 (5,613 total).

Studio API access was enabled. The existing mock-only injection guard rejected
fixture setup before changing the real profile. Subsequent purchase fixtures
ran with temporary in-memory profile storage and leaderboard writes disabled;
both original modules were restored exactly afterward. API settings were not
changed. No test balances or inventories were written to live saves/boards.

Play verified the board hidden at 23 occupied bays and visible at 24, an
unaffordable purchase leaving cash unchanged, one successful 31,940,260 cash
charge opening all 30 bays, repeat-purchase rejection and the lab appearing.
Before purchase the deck and six hidden bays had no collision. After purchase
a collidable-deck raycast hit the extension at floor height and both centre
rear rim blocks were open. The extension/Factory II/lab were viewed in Play.

Fresh-module Studio fixtures passed 140 finish checks covering all four
finishes on Titan and all five imported types: idempotent decoration, safe
parts and unchanged imported mesh textures/materials/colours. A tool-refresh
fixture replaced the stale tool, preserved ID/level and avoided duplicates.
The pure suite covers quote expiry, double confirmation, switched/equipped
targets, cash rejection and migration of expansion/all finishes.

Studio mode changes interrupted physical coating clicks and end-to-end live
quote confirmation; those checks did not pass and remain manual, together with
actual rejoin, full held/Owned/bay appearance, walk-through/button review,
streaming and device performance. Initial game Output showed the existing
asset 203785492 warning; rejected fixture probes also logged test-command
errors. No new production-script failure was observed. Temporary fixtures
were discarded, storage sources restored, and nothing was published.
