# Upgrade controls

24 October 2026. Presentation and control clarification for desktop. This is
not a new economy or progression system.

## Two scopes, with rolling kept separate

| Physical control | Label | What changes |
| --- | --- | --- |
| Equipped crusher's bay plaque | THIS CRUSHER | Only that inventory instance gains a level; its level stays when swapped |
| Blue production board | FACTORY UPGRADES / ALL YOUR CRUSHERS | Damage, strike cycle and scrap yield apply to owned crushers, including crushers equipped later |
| Purple rolling board | ROLL UPGRADES / FUTURE ROLLS | Luck changes future offer odds; pedestals add choices per free roll |

All purchases stay on the plot. There is no new full-screen upgrade menu.
`ProductionStation`, `RollingStation`, upgrade IDs, bay IDs, remote names and
arguments remain compatible. Board dimensions and station positions are unchanged.

Bay plaques preview current level -> next level and estimated current -> next
cash per minute, using `CrusherRules.stats` for both. At the cap they show the
current level/output and MAX. The estimate includes current global upgrades,
rarity, modifier and perks; it is not a guarantee of real-time earnings.

Board price buttons show the level step and cost. Their effect line describes
the upgrade separately. Speed shows remaining cycle duration as a percentage
(100% -> 94% at level 0), rather than mislabelling duration reduction as attack
rate. Luck shows the normalised chance of Uncommon-or-better, including Lucky
pass when owned; it does not claim a raw weight bonus is final probability.
Pedestals describe choices per roll; each chosen offer still costs cash.

## Purchase feedback and routing

Green means affordable; grey means short of cash or MAX. An unaffordable click
shows the missing cash and collect/sell hint without submitting a purchase.
MAX also submits no purchase. Server ownership, distance, cash and maximum
checks remain authoritative and unchanged.

`CrusherWorkshop.purchase` sets PurchaseState, PurchaseCost, PurchaseHint and
SuccessText attributes. Owner-only PlayerGui SurfaceGui copies mirror these
attributes and update their glossy colour; they continue to bind as controls
stream in and out. A successful purchase displays CRUSHER +1!, FACTORY +1!,
ROLLING +1! or BAY UNLOCKED! according to its scope.

LEVEL UP always targets the crusher currently named on an occupied plaque,
even while another backpack Tool is held. Empty bays retain placement of a
held crusher. SWAP still opens the collection's equipment view; existing bay
placement prompts are otherwise unchanged.

## Implementation

- `shared/CrusherUpgradeView.luau`: read-only descriptions, estimates, pricing
  states and shared state colours; it never mutates profiles.
- `server/Kit/CrusherWorkshop.luau`: existing chunky Style helpers, scope labels,
  price-state application; additive API helpers preserve existing callers.
- `server/CrusherGame.luau`: fills world controls from the shared view.
- `client/CrusherHud.luau`: owner-copy attributes/colours and explicit level action.
- `shared/CrusherConfig.luau`: tutorial wording only; no game numbers changed.

## Supplied patch verification

- All 70 Luau source files compile; LF and diff whitespace checks pass.
- 441 pure profile/view assertions: all forty types' previews match the real
  level purchase; only the selected instance levels; global scope, saved instance
  levels, exact affordability, maximum levels and pass-aware odds are checked.
- Mocked world controls at 1920x1080 and 1280x720: 57 assertions each cover named
  crusher leveling while holding another Tool, empty-bay placement, SWAP,
  upgrade/unlock actions, scope feedback, live attribute/colour updates, MAX,
  cash shortfall and stream-out/rebind. These are programmatic control/layout
  checks, not rendered Studio screenshots or proof of physical readability.

The supplied patch was prepared without Studio. Remaining desktop Play review:

1. Check both boards and an occupied plaque at ordinary walking/camera distance.
2. Level one of two duplicate crushers; the other instance must stay unchanged.
3. Buy factory damage/yield and confirm both equipped crushers improve.
4. Hold a different Tool and click LEVEL UP; verify the named crusher levels.
5. Check short-cash, MAX, slot/floor unlock, swap, streaming away/back and clean Output.
6. Rejoin to verify individual levels and factory upgrades remain saved.

Phone implementation and testing are deferred.

## Integration checks ? 24 October 2026

Applied against the current checkout, retaining Blender scenery, the forty-type
catalogue, backpack placement and the newer eight-step guided tutorial. The
Upgrade and Level tutorial descriptions now use the new scope labels; tutorial
IDs, ordering and rewards are unchanged. Other edits arriving during validation
were retained, including the goals board/time-skip work.

Rojo build passed. Synced all 71 mapped source files into Studio Edit mode
(12 sources changed), preserving the five FactoryToyModels templates. Fresh
Play passed CrusherUpgradeView.spec (441 assertions) and the current
CrusherRules.spec (332 assertions). Live owner controls showed Ready/Short
purchase attributes and the new price/level text. Play Output had only existing
disabled-DataStore and asset 203785492 type warnings; no upgrade script errors
appeared during that check.

The real mouse/readability check did not complete: Studio changed modes during
validation, and concurrent source edits appeared. Do not count the supplied
mocked controls as a completed Studio interaction test. The desktop review list
above, including held-tool LEVEL UP, success feedback, streaming, MAX states
and persistence/rejoin, remains manual. The test profile used Studio's mock
store; no live save was changed. No publishing was performed.
