# Collectible hydraulic crushers

## Current loop — 2026-10-22

Roll a crusher with earned cash, equip its unique instance in a bay, let it
crush automatic inputs, collect ready scrap into carried scrap, then sell
carried scrap directly for cash. Automatic crushing is free. Objects are
production inputs, not purchases or the main collection.

The eight plot origins, 120 x 172 footprints, bridges, factory hall, central
Mega Crusher, circular railway and rideable trains remain. New plot furniture
has three rear bays at local X -34/0/34, Z -38, plus a roll station, blue scrap
bin, green seller and separate Production/Rolling boards. Consoles are low
and tilted to keep crushing beds visible. Interactive furniture and machine
decoration do not collide with players. Use E/tap prompts on your own stations;
the HUD also supports collecting/selling/rolling and managing the same actions.

## Configuration and economy

`shared/CrusherConfig.luau` is exposed as `Config.Crushers`. It holds all new
prices, weights, limits, production parameters and tutorial instructions.

| Progression | Behaviour |
| --- | --- |
| Starter | One equipped Bumper Press, one usable bay, $20 for a new profile |
| Rolls | $30 each; inventory limit 80; duplicates remain separate GUID instances |
| Extra bays | Bay 2 costs $180; bay 3 costs $900; sequential unlocks |
| Individual levels | 1..40, cost floor(16 × 1.38^(level-1) × rarity multiplier) |
| Global upgrades | Each has its own level 0..20; costs below |
| Damage | Cost floor(20 × 1.65^level); damage multiplier 1.35^level |
| Speed | Cost floor(30 × 1.7^level); strike/reset cycle multiplier 0.94^level |
| Scrap yield | Cost floor(25 × 1.65^level); completed-object value × (1 + 0.2 × level) |
| Luck | Cost floor(50 × 1.75^level); uncommon+ weights improve with rarity rank |
| Rolling speed | Cost floor(35 × 1.7^level); interval max(0.65, 3 × 0.93^level) seconds |

Every rolling-speed level currently improves the actual server interval. The
reveal cycles machine names until the server cooldown expires, then displays
the real result. Paying faster requests cannot create extra rolls. The roll
deadline is saved as an absolute timestamp and restored on profile reload.

Rarity weights are Common 70, Uncommon 22, Rare 6, Epic 1.8 and Legendary 0.2.
For rank 0..4, the weight is multiplied by (1 + 0.12 × LuckLevel × rank), then
normalised. Lucky pass doubles uncommon-and-rarer weights, rather than claiming
that normalised probabilities literally double. Types: Common Bumper/Steel,
Uncommon Cobalt, Rare Mega, Epic Titan and Legendary Quantum. The existing
press builder/meshes are fitted inside each bay. Missing meshes use its
procedural fallback; place templates are never replaced.

Modifier selection is separate: Standard 80%, Rusty 14%, Polished 5%, Charged
1%. Their scrap-value multipliers are 1/1.15/1.5/2. Rarity colour marks the
machine plinth and inventory card; modifiers change bed/plinth materials.
Effects are limited to one low-rate emitter per machine, with local machine
lights disabled. There is no loose physical scrap or decorative debris per hit.

Individual levels multiply damage by 1.12^(level-1) and scrap value by
1.10^(level-1). Global upgrades apply on top. Type inputs have 12..120 HP,
so damage and strike speed affect production independently. Global yield,
rarity, modifier, Double Cash and friend boost multiply the completed value.
The displayed estimate is value / (ceil(HP/damage) × cycle + input delay);
actual server scheduling can differ slightly. Low-rarity crushers remain
useful through their own levels and global upgrades.

## Ledgers and ownership

- `cash`: spendable cash; only server-validated purchases subtract it.
- `crushers.available`: completed scrap value waiting in the bin, persisted.
- `scrap`: carried scrap value, persisted. Collect moves ready value here;
  Sell moves it to cash and clears carried scrap. Repeating either action
  cannot reward the same value twice. Production only pays on object completion.

`shared/CrusherRules.luau` performs non-yielding transactions. The server supplies
its RNG, clock, GUIDs and actual player perks. Equipment/levels target the full
inventory ID, including duplicates. One instance cannot occupy two bays.
Replacing a bay occupant returns the old instance to stored inventory; there
is no destructive sell/delete action. Unequipping never removes an owned
machine, so spending all cash cannot remove the ability to earn. Full inventory,
locked/full bays, invalid IDs, max levels and unaffordable actions do not charge.
Explicitly choosing an occupied bay replaces its occupant for free.

`server/CrusherGame.luau` owns sessions, visible models, automatic production
and snapshots. `CrusherAction`, `CrusherState` and `CrusherOpen` extend Net;
legacy names remain for the shop/rewards and recovery. Requests are throttled
per player. Production runs on the server independently of client rendering.

## Save migration and retired systems

Uses the existing `CrushItPlayer_v1` store and `player_<UserId>` key, session
locking, autosaves and leave/shutdown saves. Schema is `crusherSchema = 2`.
Owned instances, levels, rarity/modifier, equipped bay IDs, unlocked bays,
global upgrades, tutorial, ready/carried scrap and roll deadline are persisted.

One-time migration:

- Cash and purchase receipt history stay on the profile. Existing pass ownership
  still uses the same Marketplace IDs and Pass_* attribute contracts.
- Old tier maps to one of the six crusher types. Its individual level is
  1 + floor((old Power + old Value)/2), capped at 40.
- Global Damage gets floor(old Power/2), Speed gets old Speed, Yield gets old
  Value + rebirths, and Luck gets rebirths, all capped at 20.
- Each old Mini Press becomes a separate Common/Rusty Steel Stamp at its old
  helper level, capped at 40. The main crusher and up to two converted helpers
  start equipped. Remaining machines stay owned in inventory.
- Old carried scrap remains carried. Smelter queue and ready cash are moved
  into carried scrap exactly once, then those active smelter ledgers and helper
  list are cleared. Migration is idempotent after save/reload.
- `legacyCrusherRecovery` retains old cash/tier/levels/rebirths/helpers/object
  collection and smelter values. Legacy fields not retired remain on the root.
  Earning rates intentionally follow the new economy, not the old tier economy.

Game.server branches into the new controller before starting any retired
income loops. Plots builds the new layout instead of old buy pads, helper
yards and smelter. Legacy Main/Goal/Guide/Helpers/Onboarding/Scrap/Zone client
presentation is dormant. Old code is retained for inspection/recovery, but
does not generate parallel income. Turning Enabled off alone is not a complete
save rollback; recovery requires reviewing the snapshot and currency ledger.

Perks: AutoCrush becomes +25% strike damage because basic automation is free;
AutoCollect collects and sells automatically; DoubleCash remains doubled value;
Lucky improves crusher rolls; OfflineEarnings uses the new equipped fleet's
rate with its existing share/time cap. FinishSmelt's existing product identity
now sells all finished scrap, while GoldenRush/reward batches keep a 10x value
bonus on the next completed inputs. Cash products use configured new-loop
amounts. All existing IDs are retained (currently zero), so no unconfigured
Robux purchase is enabled.

## UI and tutorial

CrushHud's Book panel is now the crusher inventory, with type, rarity, modifier,
level, estimated production, upgrade cost and ID suffix on each card. Last roll
and equipped machines sort first, then stored production rate. Selecting a bay
and a particular card equips/replaces that exact instance. Production and
Rolling have separate panels and physical boards, each showing current level,
next benefit and cash cost. One tutorial instruction is shown at a time through
collect, sell, roll, equip, both boards and an individual level. Unaffordable
actions explain that collecting and selling will supply cash.

CrushHud, CrushButton, Book, BookButton, ShopButton, RewardsButton, ShopHud and
OpenShop behaviour remain. CrushButton now opens collection management;
Card_Power maps to global Damage and Card_Size to the next bay unlock.
Shop's caller follows the action bar's relocated CrushButton. New ScreenGuis
use Sibling. Phone actions sit in the centre above/between movement controls;
panels scroll. Periodic production snapshots do not recreate live buttons or
reset scroll position unless inventory/upgrades/equipment actually change.

## Verification, 2026-10-22

- `server/Tests/CrusherRules.spec.luau`: 67 assertions pass in Studio: transaction,
  costs, RNG weights, cooldown, ownership, duplicate instances, equipment,
  maxima, all 20 roll-speed benefits, distinct upgrade effects, completed-only
  scrap, repeated collection/selling, migration/idempotence, large legacy cash,
  paid multipliers and eight independent production profiles.
- Fresh player in Play: automatic starter production, collect/sell and a paid
  roll through actual HUD buttons. Server confirms cash deduction, separate
  ledgers, new owned instance and tutorial progression. Desktop inventory inspected.
- Migrated fixture: cash $777, tier 7, upgrades, three helpers, carried scrap
  $10 and smelter values $25/$15. Produced four owned machines, three working
  bays, unchanged cash and $50 carried; retired helpers are empty and recovery
  is retained. Upgraded an instance/global level and verified mock-store
  save/reload retains IDs, equipment, levels, money and purchase history.
  Collected, sold, rolled and replaced the correct equipped instance afterward.
- All six press types fit their selected inputs; tested the procedural press
  fallback with templates temporarily unavailable, restoring all five templates.
  ObjectMeshes (13), press templates (5) and factory materials are preserved.
- Phone landscape: inventory/upgrade layouts inspected, modal tabs opened,
  unaffordable purchase denied with guidance, then a real Luck button purchase
  charged $50 once. Action bar avoids thumbstick/jump. Studio MCP input required
  safe-area coordinate calibration; no input-coordinate workaround is in game code.
- Final Play smoke: walked the gate/central/back aisles and bay approach; used
  the actual collection/seller prompts (carried returned to zero, cash increased).
  Inventory, Production, Rolling, Shop and Rewards opened and closed; Shop's
  OpenShop attribute still opens its panel. Boarded a moving train, rode and
  jumped off with full health. A full railway lap was not timed.
- Output: no gameplay-script exceptions observed. Studio reports disabled
  DataStore APIs, engine UI warnings and an asset-type mismatch for existing
  place asset 203785492 (not referenced by the new source). Those warnings are
  not a claim of clean published Output. Rojo build and whitespace/LF checks pass.

Real DataStore API access is disabled in this Studio place, so real published
rejoins/session contention remain unverified; mock-store roundtrip is not a
claim of live persistence verification. Eight-profile rules tests are not
eight concurrent networked clients. Physical-phone FPS and actual multiplayer
load remain tests to perform before publishing. Inventory disposal/merging,
extra crusher types and a travelling dealer are future features, not part of
this core implementation.

Studio-only `ServerStorage.DevCrusher` supports Get, Cash, Action, Profile and
Reload for QA. Profile replacement/reload are explicitly limited to the mock
store; they reject real Studio API-backed profiles. The test suite does not
touch a real profile. The rollout flag should be flipped only with a reviewed
migration/recovery plan.
