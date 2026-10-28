# Factory events — Bear Breakdown

28 Oct revision (Studio Play checked):
- **Everyone takes part automatically**: no Join/Leave. Everyone with a loaded plot
  is listed at Announce, frozen at Assemble; players arriving later are added at
  once (in Active the shield keeps its percentage when its maximum grows).
  No placed crusher -> event-only stand-in machine (power FallbackPower, no
  inventory change). Death/respawn keeps you in. Reward still needs both 30 s
  on your plot and 10 strikes; idempotent per round ID.
- **Event cores** (FactoryEventConfig.Cores): up to 3 purple cores at measured spots
  on your plot, prompt only for the owner; carry one (shown above your head),
  load it at your super crusher's port (purple ring in front of it) -> next strike
  x4. Every 18-28 s the port glows gold for 8 s: a core loaded then is CRITICAL x10.
  Leaving the plot or dying drops the core. Cores respawn after 5 s.
- **Bear paw slam** (Config.Slam): every 13-19 s, a red circle (radius 9) under one
  present player (rotated fairly, max 2 at once) with a filling countdown; 2.2 s
  later the bear's paw falls, shockwave. The server checks your real position at
  impact: hit = core dropped + walk speed 5 for 1.2 s; else DODGED.
- **Factory Bear**: Willem's rigged model (ReplicatedStorage.FactoryEventMeshes.
  FactoryBear, place-only; installer assets/factory-bear/Install-Bear.luau, fixed
  for Studio's 180° import turn and untinted textures) replaces the teddy at the
  same spot/height (World -> FactoryProps.bear). Event poses: roar at the intro,
  corrupted (red eyes, chest doors open on the purple reactor), wind-up/slam with
  each paw slam, defeated at the finale, recover after. Old eye/halo overlays are
  only used without the template. Cores everywhere use the bear's own reactor.
- HUD: compact boss bar top centre (title, timer, shield bar cyan->orange, one
  instruction); MY FACTORY button only while away. Studio chat: /event, /event
  win, /event cancel; ServerStorage.DevFactoryEvent also takes "Slam", "Critical".
- Tested: auto entry, pickup/carry/load, critical, slam hit and dodge, death and
  respawn, win with payout, cancel cleanup. Not yet: 2+ players, late join live.


28 Oct (installed in the place, Studio Play): **intro cutscene** when a round is
announced (client/FactoryEvent): letterbox bars, BEAR BREAKDOWN title, three
shots of ~3.5 s with captions: the corrupted bear (red eyes, dark purple glow,
halo) -> the shielded core under the Mega Crusher -> your own factory ("join and
your crushers combine into one SUPER CRUSHER"). Other HUDs hide during it and
come back after; SKIP ends it at once. Plays once per round, only for players
there at the start (first 4 s), and never takes over another cutscene's camera.
The bear/core overlays already show during Announce for this. Event panel moved
to the bottom centre (the top had the travel buttons and tutorial card).
Checked in Play: full round with Dev Start/Join/Win (one payout, ledger saved),
Skip mid-intro, all tests pass, no Output errors. Two-player, rejoin with the
real DataStore and the five super-crusher grades are not tested yet.


27 October 2026. First implementation; offline checks passed. **Studio Play,
real multiplayer replication, placement, camera and DataStore checks remain.**

Players stay on their own plots. Placed crushers temporarily become one super
crusher; inventory, equipment and ordinary production keep running unchanged.
The bear corrupts the factory. Local super crushers break core fragments and
send energy to the central Mega Crusher, which unfolds additional armour and
hydraulics, breaks the exposed central core and restores the friendly bear.

## Round

Idle (15 minutes) → Announce (20 seconds, optional Join/Leave) → Assemble
(6 seconds) → Active (up to 180 seconds) → Finale (7 seconds) → Victory
(6 seconds) → Recover (3 seconds) → Idle. A shield timeout or empty roster
skips the finale/reward and restores the factory. No participants means no
transformation. Schedule/timings are provisional in `FactoryEventConfig`.

At assembly, the server freezes the current placed fleet. Unplaced backpack
items and repeated IDs cannot inflate it. Joining closes at this boundary;
late arrivals spectate and can join the next event. Leaving/disconnecting
forfeits that round, restores the plot, and proportionally resizes the shared
shield without resetting its completion ratio. Death/being away pauses that
player's event strikes; returning to the plot resumes them.

## Scoring and strength

Common 1, Uncommon 2, Rare 3, Epic 4, Legendary 5, Mythic 6 points per placed
crusher. Silhouette grades start at 0/15/45/100/200 points: Super Press, Twin
Hydraulic, Reactor Press, Titan Engine, Factory Colossus. Grades add twin
shafts, shoulder reactors, auxiliary cylinders, crown and extra crushing teeth.
Colour follows the strongest rarity present. The footprint stays about 19×14
studs, under 30 studs tall, in the gap between the two original wing banks.
This coordinate choice is based on source layout; verify it in the actual place.

Damage strength uses **real fleet output**, including levels, coatings, fusion,
row bonuses and production perks. `power = min(25, 1 + log10(1 + total CPS))`.
This diminishing return lets advanced factories contribute more without
instantly ending the round. Initial shield = total power × 90; each present
factory strikes every 2 seconds for power × 2. HP scaling makes the event
playable solo; stronger fleets matter most in mixed-strength servers.

Optional OVERDRIVE is a timed button: near the shared strike beat, once per
6 seconds, boost the next server strike ×3. It never accepts client damage,
rarity, inventory, target or reward values. Only the owner's living character
inside their plot can activate it or accrue event presence/strikes.

## Rewards and persistence

Victory grants cash to still-joined participants with BOTH at least 30 seconds
on their plot and 10 authoritative strikes. Presence is not a movement/AFK test;
normal automatic crushing is intended. First-version reward = 120 seconds of
the snapshotted fleet CPS, minimum 250, maximum 1e12. These are provisional
balance values, not new production/shop prices. No crusher/crate/Robux reward
or new currency is enabled by this patch.

`factoryEvents = {wins, claimed}` lives in the existing profile. The bounded
last-20-round ID ledger and cash mutate together without yielding, then use
the existing DataService save. Repeated victory callbacks/rejoin cannot
reclaim that round. Save failures retain the changed profile for autosave;
there is no promised server-crash recovery/outbox for unfinished events.
Disconnected players do not receive an offline event payout.

## Presentation and integration

- New remotes: FactoryEventAction (Sync/Join/Leave/Pulse), FactoryEventState
  (server snapshot). Existing remote names and UI contracts are retained.
- `FactoryEvents` consumes narrow eventPlot/eventFleet APIs from CrusherGame.
- ReplicatedStorage.FactoryEventState attributes drive the central animation.
  **Mega.client remains the sole ram animator**, including imported RamParts
  and RamStretch. It switches to the event timeline and then its original loop.
- Client cosmetics use noncolliding/nonquerying parts, at most six nearby plot
  rigs, eight assembly motes per rig and one pooled event sound. Factory routes,
  train, stations, plot geometry and assets are not rebuilt.
- Actual placed models use LocalTransparencyModifier while transformed;
  authored alpha/emitter flags are restored. A local plot marker temporarily
  suppresses the existing small-machine audio/feedback mixer.
- The bear receives temporary glowing red eyes and a corruption halo. Named
  eyes are followed exactly; combined imports use a measured head mask that
  needs visual verification. The real place template is never edited.
- A dedicated mild ColourCorrectionEffect leaves the Lighting base settings
  alone. Recovery deletes the effect and temporary parts.
- Finale camera is participant-only and skippable; no control locking. Skip,
  death, respawn and normal completion restore the saved camera. Spectators
  keep their normal view. Verify overlap with the plot-upgrade cutscene.
- Desktop HUD uses shared Style helpers and Sibling ZIndexBehavior. Mobile
  adaptation is intentionally deferred.

No Blender or image upload is required for this first implementation. The
super crushers and event effects are built by Luau. The six crate crushers
and earlier five Mythics remain separate assets and are not granted here.

## Verification

`tools/factory-events/run_offline.py --luau /path/to/luau` executes the actual
rules, controller, cosmetic builders and LocalScript against explicit service
and geometry mocks. It also runs existing crusher, rarity-row, fusion, factory
progression and Daily Spin specs. Mock UI Style and profile serialization are
test substitutes, not Studio-rendering/real JSON/DataStore tests.

Studio: run `require(game.ServerScriptService.Server.Tests["FactoryEvents.spec"])()`.
Then use `game.ServerStorage.DevFactoryEvent:Invoke("Start")` in the **server**
Command Bar. Join through the HUD and stand on the own plot. `State` inspects,
`Win` triggers the finale during Active (does not bypass reward qualification),
`Cancel` aborts. The BindableFunction exists only in Studio.

Before publishing: test 1 and 2+ players; grades 1–5; all imported central rig
variants; live HP/energy/overdrive; no reward before both conditions; skip,
death, respawn and competing cutscenes; leave/disconnect/empty/timeout;
streaming in/out; unchanged production/saves; full restoration and a second
round. Inspect Output and screenshots at 1080p. Confirm the bear eye placement,
central-core contact and nearby stations remain clear. Save/rejoin with a
real enabled Studio DataStore and verify one reward/win and no lost inventory.
