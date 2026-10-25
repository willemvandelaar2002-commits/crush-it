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
