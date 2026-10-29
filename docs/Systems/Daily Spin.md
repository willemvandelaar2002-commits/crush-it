# Daily Spin

Implemented 24 October 2026 from the existing Coming Soon station. The panel
uses the current factory Style helpers; the referenced screenshot was not
available in the conversation. Desktop only.

## Art and interaction

The existing plaza station has an E / Open prompt and retains its placement.
Its old single-piece mesh is replaced by the imported standing wheel when
ServerStorage.HubMeshes.DailySpinWheel is available. The panel contains a square transparent rotor container with
`rbxassetid://105558594053157`, and a separate fixed frame/pointer ImageLabel
using `rbxassetid://71953431310313`. Both have identical size, position and
centre anchor. Only the rotor container rotates. There is no drawn wedge/icon
artwork or text over the icons/hub: dynamic reward amounts and odds appear in
the adjacent list. Close/reopen does not cancel a granted reward or reroll it.

Reward IDs map explicitly to artwork sectors in DailySpinConfig. Sector i lands
at (-45*i) modulo 360; target rotation adds the forward delta from the current
angle and six complete clockwise revolutions. Finished angles are normalized
before later spins. Equal artwork wedges do not imply equal odds.

The imported Frame/Stand/Rotor model is stored outside Git in
ServerStorage.HubMeshes.DailySpinWheel, with its authored ground pivot at origin.
The plaza clones it onto the station base, fits it to the existing station width
and tags the clone DailySpinWheel. Atomic streaming keeps its three parts together.
All meshes are anchored, decorative and retain their imported appearance.
The client rotates only Rotor; Frame and Stand stay fixed. The original loose
Workspace import was moved into this template library rather than left floating.
Missing templates retain the old station/procedural fallbacks. The UI works
independently; legacy top-level Workspace.DailySpinWheel is still supported.
Save the Studio place to retain the template; Rojo source alone cannot restore it.

## Provisional balance

All amounts, weights, sectors and image IDs live in shared/DailySpinConfig.luau.
Luck upgrades and Lucky passes do not change spin probabilities. Displayed odds
are calculated from the configured weights, not hard-coded percentages.

| Sector | Reward ID | Prize | Weight / initial chance |
| --- | --- | --- | --- |
| 0 green | cash_short | 60 seconds of current production | 40 / 40% |
| 1 orange | golden_small | 10 Golden Rush production bonuses | 20 / 20% |
| 2 blue | cash_medium | 300 seconds of current production | 18 / 18% |
| 3 teal | crusher_uncommon | Random Uncommon crusher | 10 / 10% |
| 4 yellow | cash_long | 1,200 seconds of current production | 7 / 7% |
| 5 red | golden_large | 30 Golden Rush production bonuses | 3 / 3% |
| 6 royal blue | crusher_rare | Random Rare crusher | 1.5 / 1.5% |
| 7 purple | crusher_epic | Random Epic crusher | 0.5 / 0.5% |

Cash uses the existing equipped-factory production estimate including its
current perks, with a minimum rate of $1/second, frozen when the server selects
the prize. Golden uses the existing goldenRush balance (next completed inputs
award the existing GoldenYield). Crushers use the current rarity pools, uniform
within that pool, Standard modifier, level 1, and a server-generated unique ID.
These are initial balancing choices, not approved final economy targets.

PaidProductId is 0. The paid control is explicitly disabled and there is no paid
spin remote action or receipt handler. Configuring a product alone will not
enable purchases: a separate receipt integration is required first.

## Server authority and persistence

DailySpin is the only added remote; State and Spin are its only accepted actions.
Clients never send reward IDs, amounts, timestamps or eligibility. Existing
remotes and save schema version are retained. Migration adds a dailySpin record
with nextAt, claims, pending and last; old profiles start eligible immediately.

The server uses wall-clock time for a 24-hour cooldown from acceptance. It
throttles requests and holds one in-flight operation per player. A profile that
cannot be saved cannot spin. Before granting, it persists the selected prize
and cooldown as a pending outbox record. It then grants without yielding and
clears pending/increments claims in the same profile mutation, saving that state.
On rejoin, a saved pending prize is delivered from its stored outcome without
rerolling. A saved completed delivery cannot be applied again. Ambiguous save
failures never roll back an outcome or choose a second reward.

DataService serializes saves and snapshots after acquiring its per-profile save
lock, so an older autosave cannot overwrite a newer reservation/delivery. This
also applies to leave/shutdown saves; existing save APIs keep their signatures.

A full inventory blocks a new spin without consuming it, regardless of which
prize might have been selected. If another purchase fills the last slot while
the reservation is saving, the selected crusher remains pending until the
player makes room and reopens the panel. No replacement reward is substituted.

## Verification actually completed

- Rojo build and scoped whitespace/LF checks passed. Fresh Studio Play loaded
  all added modules and UI. Final suites passed: DailySpin.spec 285 checks,
  CrusherRules.spec 335, CrusherUpgradeView.spec 441.
- Both images loaded successfully and their transparency was visually checked
  in the rendered panel. The fixed image overlays the rotor at the same axle.
- All eight prizes were delivered through server-side mock-profile fixtures and
  animated to 0, 315, 270, 225, 180, 135, 90 and 45 degrees respectively. The
  frame remained at 0 degrees; repeated/wrapped forward rotations passed.
- A real free-spin button click granted one server-selected reward. Twenty
  duplicate requests, including a client-supplied jackpot argument, left one
  claim. Save/reload through the existing mock store retained cooldown/token.
- Full inventory (80) rejected a spin with nextAt unchanged and no extra claim.
  Pending-prize capacity races are also covered in the pure fixtures.
- Injected a failed reservation save: no grant occurred; retry delivered the
  same selected token once. Injected a failed delivery save, reloaded the saved
  pending snapshot, then recovered: final balance and claim count contained
  exactly one reward. These injections used disposable Studio scripts/mock data.
- Station E prompt, close button, reopen, and close/reopen during a spin passed.
  The last test ended with one claim and an active cooldown after the animation.
- Rendered layout fixtures at 1920x1080, 1280x720, 1024x640 and 900x600 retained
  square wheels, aligned rotor/frame anchors and viewport margins. The actual
  Studio window was not physically resized; real window-resize review remains.
- Workspace.DailySpinWheel Frame/Stand positions remained unchanged. Output
  contained only existing disabled-DataStore and asset 203785492 type warnings;
  no Daily Spin script errors appeared. Test fixtures were discarded on Stop.

Live cross-server rejoin persistence and production DataStore failure behavior
still need testing with API access. Studio used the in-memory mock store, so
no real player saves were changed. Paid spins and phones were not tested or
enabled. Review provisional balance and the missing reference screenshot before
publishing. Studio was returned to Edit mode; this change was not published.

24 October standing-model follow-up: visually checked the imported wheel at the
plaza in fresh Play. The stand bottom matches the station top within 0.001 stud;
no loose duplicate remains. E opened the panel, both images loaded, and a real
free-spin click completed with a cash reward and cooldown. All eight landing
angles plus wrapped/repeated angles moved only Rotor, with Frame/Stand unchanged.
Fixed rest-pose caching so garbage collection cannot capture a mid-spin pose.
Rojo build passed; Output contained only the existing disabled-DataStore and
asset 203785492 warnings. Live persistence remains untested as described above.

## 29 Oct: boosts instead of Golden, brighter list
The two Golden prizes (the next 10 / 30 crushed toys pay 10x scrap; worked, but
nothing on screen showed it) became 2x Luck for 10 min (20%) and 2x Cash for
30 min (3%), granted through server/Boosts after the saved delivery. Older saved
Golden prizes still pay out. The prize list uses the prizes' own bright colours
and rounded chances (40.0%, 0.10%). Golden Rush still exists as a (hidden) shop
product.
