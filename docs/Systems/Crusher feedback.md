# Crusher feedback

24 October 2026. Desktop presentation pass for a full factory. Production rules,
economy, owned instances, save data and remote names are unchanged.

## What the player experiences

- Rams descend into contact, pause briefly, then retract. The regular rigs now
  use the same timing pattern as catalog/imported rigs. Objects no longer flatten
  at the beginning of the stroke: the server updates their squash at contact.
- Up to four nearby inputs get smooth local squash around contact. Farther inputs
  keep the simple replicated server step and existing ram animations.
- Small rings mark nearby hits; completed inputs throw four small coloured toy
  scraps. These are anchored, non-colliding local cosmetics, not collectible value.
- The camera is unchanged and there are no per-hit cash popups. Existing collect/
  sell money effects remain, with a new soft collection cue.

## One mix for the listener

`client/CrusherFeel.client.luau` selects the nearest **two** active machines to
the camera listener every 0.2 seconds. Spatial audio fades with distance, so
zooming out also quietens the production floor. Focus is stable at equal distances.

At most two impact channels play concurrently. Each uses one preloaded sample:
ordinary thud, a lower metal voice for heavy machines, or a lighter energy voice.
Special voices replace the ordinary sample instead of adding another layer.
Impacts arriving within 55 ms are merged, using one sample with a small gain
increase. A 0.25-second minimum start interval imposes a hard four-starts/second
limit. Suppressed events are dropped, never queued for an audible catch-up burst.

There is one occasional release hiss (minimum 1.25 seconds apart) and one very
quiet pressure bed for the nearby area, rather than motor loops on every machine.
The pressure bed reuses the existing Hiss sample at lower pitch. All sounds reuse
the game's current asset IDs. Studio audition is still required to choose final
levels and check the loop seam; no new audio upload is required for this pass.

All machinery is in the local `CrusherMachines` SoundGroup. Changes to the local
player's carried Scrap lower this mix for 0.8 seconds, then it recovers smoothly.
Collection and sale sounds remain outside that group, as does background music.

Samples preload in a background task. Unloaded impacts are skipped; there are
no waits in the render/event handlers and no delayed replay after loading. Each
impact is faded/stopped within 0.38 seconds, even if its source asset is long.

## Fixed budgets

| Resource | Per-client limit |
| --- | --- |
| Focused impact machines | 2 |
| Simultaneous impact voices | 2 |
| Impact starts | 4 per second |
| Other machinery voices | 1 release hiss + 1 quiet ambient loop |
| Nearby visual jobs | 4 |
| Parts per squash snapshot | 24; more complex inputs use the server fallback |
| Scrap burst slots | 4 |
| Visible toy scrap pieces | 16 |
| Pooled world parts | 24: 16 scrap, 4 rings, 4 invisible audio sources |
| Created Sound objects | 8: 3 sample choices per impact channel + hiss + ambience |
| Pending impact events | 16; stale events are discarded |

There are no Part or Sound allocations per hit. Local animations use one render
connection and clean up when their source streams out or the script is destroyed.
Listener focus scans existing active models; inventory, preview and pedestal
models are not tagged as working crushers.

## Replication and gameplay separation

`server/CrusherFeedbackServer.luau` tags equipped models with `ActiveCrusher`
and sends cosmetics using the existing `Hit` event with
`{crusherFeedback=true, events={...}}`. No RemoteEvent names or Net API changed.
Packets are batched at an 0.08-second minimum interval and sent only to players
within 170 studs, with at most 24 nearest events per recipient. The server queue
is capped at 256; removed rigs and stale events are discarded before transmission.

Each pulse includes its server impact time, type, input, base pose and squash
fractions. The client uses synchronised server time and drops old/missing sources
rather than blocking for streamed assets. It never requests damage, production
or money from this effect protocol.

`shared/CrusherFeedback.luau` holds presentation tuning, source selection, timing,
sample families and budget helpers. `CrusherRules`, main Config/Store numbers,
Special/Catalog geometry and all collection/equipment logic are unchanged.

## Supplied patch verification and original check list

- 198 pure policy assertions cover nearest-source selection, stable focus,
  a rolling four-starts/second cap, release spacing, stale pulses, contact/hold/
  return timing, object scale factors and restrained existing sample choices.
- 3,706 assertions run the actual client and server feedback modules against
  mocked engine services with 20 sources. They cover synchronous strikes,
  sustained overload, real pool/queue limits, smooth squash endpoints, collection/
  sale ducking, movement away, stale packets, unloaded sounds, stream-out/re-add,
  server interest filtering, a 1,000-event flood and cleanup. Eight Sound objects
  and 24 pooled cosmetic parts remain constant throughout.
- Luau compilation and LF/whitespace checks pass. These offline checks do not
  render Studio geometry, play Roblox audio or verify asset permissions.

Studio was unavailable. Desktop Play review still required:

1. Compare a regular, catalog and imported rig: confirm contact, squash, short
   hold and full return before the next stroke, including high strike speed.
2. Equip 20 crushers, walk along the banks, zoom out and visit another plot.
   Audition impact volume, sample balance, pressure-loop seam and hiss spacing.
3. Collect and sell; verify money cues remain clear and the machinery recovers.
4. In the client Workspace, inspect `LocalCrusherFeedback` attributes:
   ActiveImpactVoices <= 2, ImpactsLastSecond <= 4, ActiveScrapParts <= 16 and
   PendingEvents <= 20. Check that local parts have no collision/query/touch.
5. Stream away/back, replace a crusher mid-stroke and check Output for errors.
6. Verify scrap earnings still match the pre-change production loop.

Phone optimisation/testing is deferred as requested.

## Integrated comparison — 24 October 2026

The patch was merged over Daily Spin, upgrade clarity, the current tutorial,
Equip Best and Blender scenery. Only the decision-log context needed manual
resolution. Production rules, Config/Store numbers and custom rig builders
remain unchanged. The new Hit packet is cosmetic; it cannot grant scrap/cash.

Open [the animated timing comparison](../Comparisons/Crusher-feedback.html) in
a browser. It has side-by-side existing/patched strokes, rig selection, a cycle
slider, quarter-speed playback and pause. This is a code-based schematic, not
a Studio video or audio recording. Screenshots of the same 20-crusher bank
were also inspected before and after in Studio.

At an ordinary 1.4-second production cycle:

| Rig | Existing visual timing | Patched visual timing |
| --- | --- | --- |
| Ordinary press | Contact 180 ms, no hold, return complete 450 ms | Contact 240 ms, hold 48 ms, return complete 600 ms |
| Catalogue rig | Contact 240 ms, hold 48 ms, return complete 600 ms | Unchanged |
| Imported special | Contact 228 ms, hold 60 ms, return complete 600 ms | Unchanged |

The ordinary press now accelerates into contact and eases out on its return.
Its longer visible stroke does not slow the production cycle. Previously the
input flattened immediately at strike start. Now the server squashes it at
contact, with a small smooth local blend for the nearest inputs. Custom rig
motion, camera and all income rules stay the same. Nearby rings, finishing
scraps and the restrained machinery mix are additional presentation.

### Checks actually completed in this checkout

- Rojo build, scoped whitespace/LF checks and comparison JavaScript syntax passed.
- Fresh Studio suites passed: CrusherFeedback.spec 198, CrusherRules.spec 335,
  DailySpin.spec 285 and CrusherUpgradeView.spec 441 checks (1,259 total).
  The supplied external 3,706-check mock harness was not present or rerun.
- Used the same disposable 20-crusher profile before/after, containing all six
  ordinary types, all five imported specials and nine catalogue rigs. Both
  deterministic 60-second production simulations produced exactly 168 completed
  inputs and 17,450.80 scrap value. This is a fixed-timestep simulation, not a
  claim that two wall-clock Play sessions have identical frame scheduling.
- Actual Studio Play created 20 active crusher tags. All eight sound objects
  loaded, and impact playback was observed through Sound.IsPlaying. Pools
  stayed at 24 parts/eight Sounds, with every cosmetic part anchored and all
  collision/touch/query disabled.
- At normal speed, sampled maxima were one impact voice, one impact start in
  a second, eight scrap parts and four pending jobs. At maximum global speed:
  one voice, three starts/second, eight scrap parts and six pending jobs. These
  observed peaks stayed inside the policy limits; they are not worst-case
  performance benchmarks.
- Moving to the hub silenced machinery: zero voices/starts/scraps/pending jobs
  and the ambient loop stopped. Returned to the bank and replaced a working
  crusher during production without errors.
- Collect and Sell both succeeded. Continuous client sampling measured the
  machinery SoundGroup falling from 0.65 to approximately 0.2204, then recovering
  to 0.65. Existing carry/money effects were retained.
- Found and fixed a real engine lifecycle issue: under deferred signals, a
  destroyed LocalScript cannot reliably run its own Destroying callback.
  CrusherFeelCleanup is an independent, small lifecycle watcher; owner/run
  references let it remove orphaned pools and sound groups. Destroy/recreate
  and disable/re-enable tests now remove old pools and restart with exactly
  one sound group, 24 parts and eight Sounds.
- Output contained only existing disabled-DataStore and asset 203785492 type
  warnings; no feedback/game script errors appeared in the completed checks.

Sound loading/playback and volume behavior were verified programmatically; the
subjective mix, hiss/loop seam and loudness need a human listening review. True
stream-out/re-entry, physical-device performance and phone work remain untested.
All profile fixtures used Studio's guarded mock-store API, not live saves.
The comparison preview has no audio. Nothing was published.

Audio implementation references: [Roblox sound objects](https://create.roblox.com/docs/sound/objects)
and [Sound loading/playback API](https://create.roblox.com/docs/reference/engine/classes/Sound).
