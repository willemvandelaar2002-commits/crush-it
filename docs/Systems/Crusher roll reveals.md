# Crusher roll reveals — 25 October 2026

World pedestals keep the flickering silhouettes and sequential results. Offers
now lift and settle with a short rarity-scaled motion; Rare/Epic/Legendary get
an owner-only coloured outline and world badge, plus one quiet existing chime
for the highest rarity in that roll. The existing shared camera kick is reduced.
No extra pause or delay is added to the authoritative three-second cooldown.
There is no fullscreen reveal, forced camera, auto-purchase or bonus reward.

The final card shows approximate **type odds for that particular roll**, using
the Luck level and Lucky pass snapshotted when rolling. It labels the first
Common-only roll correctly. This is the marginal chance of that type; it does
not include the additional independent modifier probability. Flickering preview
silhouettes deliberately show no odds, since they are cosmetic weighted samples.

An unseen offer says UNOWNED / BUY TO COLLECT. NEW DISCOVERY appears only after
the server successfully purchases the first copy of a type. Failed purchases,
duplicates, rejoin/Sync and rolling alone cannot trigger it. Existing inventory
protection keeps the last copy, so this needs no new save ledger. Purchase
receipts travel as one optional field on the existing full CrusherState packet;
no partial packets or new remotes are introduced. Daily Spin remains separate.

Client accents have five fixed anchors/highlights/badges, no per-hit or per-roll
instance creation, one preloaded sound, stale-event rejection, owner and distance
filtering, batch deduplication and automatic cleanup. Late streaming does not
replay old results. A small discovery queue handles multiple first purchases;
the bottom banner dismisses automatically and does not block world controls.

Verification: the pure test covers all forty type probabilities with every
Luck level and both pass states, normalization, the starter draw, motion
endpoints and stale events. Offline runtime fixtures check server reveal and
purchase receipt integration and bounded client accents. Studio Play remains
required for the actual look, sounds, streaming and Output. Desktop only.

Studio server command:
`print(require(game.ServerScriptService.Server.Tests["CrusherRollPresentation.spec"])())`

Test five simultaneous offers and each rarity; buy a new type and a duplicate,
then try an unaffordable/full-inventory purchase and Sync/rejoin. Walk away
mid-roll and restart another roll immediately when the real cooldown permits.
Verify that the labels match the offer, no old purchase prompt or delayed
reveal survives a new roll, and there are no new Output errors.

## Integration verification — 25 October 2026

Applied the combined patch cleanly over the current checkout, retaining the
standing Daily Spin wheel and newer scenery, feedback and upgrade systems.
Fresh Studio Play passed CrusherRollPresentation.spec (3,656 checks) and the
seven rig/gameplay regression suites (206,320 checks altogether). Rojo build
and whitespace checks passed.

Using disposable Studio mock profiles, five first-roll offers showed 1-in-8
Common type odds. Later offers matched the Luck-20 snapshot. A successful first
purchase added exactly one item and sent one discovery receipt; another visible
offer of that type lost UNOWNED. Duplicate, unaffordable and full-inventory buys
and mock reload produced no false discovery. A real purchase opened the named
NEW DISCOVERY banner, which dismissed automatically. Buying slot five during
the stagger and starting the next roll at the real cooldown boundary left
exactly five current offers; an early repeated roll was rejected.

A disposable client fixture displayed all five rarities: the loaded chime
played once at Legendary pitch, then highlights cleared and the ten pooled
anchor/highlight instances remained constant. This verifies playback state,
not a human listening assessment. Output showed only the existing disabled
DataStore and asset 203785492 type warnings. No live saves were used.

Actual multiplayer streaming/re-entry, device performance, human audio and
complete visual review of every model/rarity remain manual checks. Phones are
deferred. The previous Daily Spin live-persistence limitations still apply.
