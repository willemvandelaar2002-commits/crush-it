# Matching rarity rows — 25 October 2026

A complete physical row of six equipped crushers of the same rarity gets a
matching colour glow and a scrap-output bonus. Different types, levels and
Standard/Rusty/Polished/Charged modifiers may form the set. This is a current
lineup bonus. An empty/locked bay, mixed rarity or unequipped member removes
it immediately for subsequent completions.

| Rarity | Extra scrap from that row |
| --- | --- |
| Common | 5% |
| Uncommon | 10% |
| Rare | 15% |
| Epic | 25% |
| Legendary | 40% |

First-pass values live in `CrusherConfig.RowBonuses`. The physical rows map
to ground left (bays 1–6), ground right (7–12), upper left (13–18), upper
right (19–24). Six matching crushers scattered across rows do not qualify.
All six must be unlocked and individually equipped owned instances. Saved
type/rarity mismatches, repeated equipment IDs and unknown IDs cannot form a
set. There is no ActivateRow action or client-supplied multiplier.

## Economy and saves

`CrusherRows` derives everything from owned/equipped/unlocked state. There is
no new save flag, schema reset, currency or activation payout. The multiplier
applies only to that row's completed-object scrap value, alongside existing
level/yield/modifier/pass/friend bonuses. Damage, HP, cycle times, prices and
rolling weights retain their rules. Multiple rows boost their own machines;
their percentages do not add into a plot-wide multiplier. Unequipped inventory
and pedestal previews have no active-row bonus.

`CrusherRules.stats` reports the row bonus; `step` uses one derived snapshot
per non-yielding production tick. Eligibility is checked at completion. Golden
Rush still multiplies/consumes charges on its normal completed inputs. Breaking
a set never recalculates banked/carried scrap; Collect and Sell transfer the
ledger without another boost. Income-based offline earnings/rewards/time-skip
estimates use the existing cash-per-second API and therefore reflect current
row-aware production. Level previews include the bonus on both current/next
levels. Owned cards show row-inclusive output and ROW +%.

Equip Best ranks raw output fairly and checks the resulting row-aware total
before committing. It refuses a change that would reduce earnings by breaking
a stronger hand-arranged set and explains why. It does not optimise every
possible rarity arrangement: players may arrange sets manually.

## World presentation

Each row has a low, noninteractive plaque forward of individual bay controls,
showing the most-matched rarity and progress, then its bonus at 6/6. Locked
rows and released plots hide their plaques. Six small Neon strips lie in
front of raised pedestal trim; existing overhead status strips take the rarity
colour when active. Breaking the set restores normal colours. Imported rigs
are untouched. Non-colliding/non-queryable signs cannot intercept bay input.

`RarityRows.client` pulses the nearest four active rows within 135 studs at
20 Hz; farther rows keep a static glow. It handles deactivation, release and
late-streamed rails without per-frame Instances. No sounds, PointLights,
particles, extra Highlights or large panels are added. SurfaceGuis use Sibling
and the shared Style. Phone work is deferred.

## Verification

Actual source modules run with disposable offline API adapters: 610 row
assertions cover five rarities/four rows, mixed levels/types/modifiers, missing
or locked members, malformed equipment, rejoin derivation, independent row
scopes, real completion/Golden Rush/collect/sell ledgers and Equip Best safety.
Existing CrusherRules 335, UpgradeView 441, DailySpin 285 and QuestRules 12
also pass. A world runtime passes 116 checks for safe geometry, exposed rail
placement, GUI layering, unchanged-sync instance counts, five active rows
sharing four pulse slots, culling, deactivation and release cleanup.

No connected Studio is available here. Fresh Play must verify actual glow,
readability, shadows, input, streaming, held models, performance and Output.
See [[../Apply-rarity-rows]]. Plot expansion, the Upgrade Plot board and
merging/forging remain future work; no fifth row or item consumption is added.

## Connected Studio integration — 25 October 2026

Applied cleanly over quests, brighter colours, roll/model changes and the
standing Daily Spin wheel. Rojo build and whitespace checks passed. Fresh
Studio suites passed: CrusherRows 610, CrusherRules 335, UpgradeView 441,
DailySpin 285, QuestRules 12 and RollPresentation 3,656 (5,339 total).

Disposable mock-profile Play checks confirmed EPIC SET 5/6 changes to EPIC
ROW 6/6 / +25% SCRAP ACTIVE on equipping the sixth member, with visible purple
front/top trim. Unequipping removes activation; re-equipping and mock reload
derive it again. Four simultaneous Common/Uncommon/Rare/Legendary rows report
their own 5/10/15/40% bonuses. Owned opened with row-aware output on all 24
cards and the selected row's progress footer. All 28 row parts were anchored,
noncolliding, nontouching and nonqueryable. Desktop screenshots were reviewed;
complete sign readability and direct bay-button click review remain manual.

A disposable five-row client fixture verified four pulsing rows and one static
row, deactivation cleanup, a late-added rail joining the pulse, and static
transparency restoration after camera culling. A separate server fixture kept
112 descendants across repeated syncs and hid/restored rows on release/reuse.
These are fixtures, not actual multiplayer stream-out/re-entry or player leave
tests. No live saves or place assets changed. Output contained existing disabled
DataStore and asset 203785492 warnings; no new game-script errors appeared.

Live rejoin, actual network streaming, device performance, full interaction/art
review and phone work remain untested. Studio was returned to Edit mode and
Play fixtures discarded; nothing was published.
