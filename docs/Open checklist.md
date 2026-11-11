# Open checklist (updated 11 Nov 2026)

Everything from the 11 Nov full audit (`Vault audit 2026-11-11 full game.md`, findings 1-11 and "not
checked"), plus open items from earlier audits and sessions. Tick off here and add a Decisions log line.

## 11 Nov audit
- [x] 1 Luck multipliers barely worked after Luck ~10 -> now multiply every rarity-or-better (11 Nov)
- [x] 2 Paid luck for restricted players -> left as is (Willem: luck also works on free rolls)
- [x] 3 Odds only as "1 in N" -> ROLL ODDS window with percentages (11 Nov)
- [x] 4 Top rarities stopped being rare -> luckRank 3.5, much rarer base odds, Eternal halved again and
      then (Willem: less rare) Eternal/Divine/Secret base up, cap back to x10 (11 Nov; maxed Eternal 1 in ~5,160)
- [x] 5 Big roll cinematics too frequent -> no cinematic for owned types (11 Nov); and rarer with 4
- [ ] 6 **Gems run out of purpose**: mine upgrades max in ~26 min, everything in 2-3 h. The Gem Crate is
      now a real Secret/Divine source (4 made the roll rarer); check whether that is enough or add a
      lasting sink (crate-only crushers or coatings, a cosmetic, a repeatable upgrade). Hold Gem Yield.
- [x] 7 Every client loaded all six plots in full -> hidden floors, bays, stages, rear yard and trim
      wait in ServerStorage (server/PlotStash) until shown: empty plot 7,321 -> 2,710 instances, Workspace
      on a fresh server 49,200 -> 21,600 (11 Nov). Streaming radius kept at 1024 (vault: keep; it can't
      be set by script). Unowned plots as a bare shell: not done (they show the base factory).
- [x] 8 Crusher motion from the server -> one small strike event per strike to players within 320
      studs, motion played on each client (Shared.CrusherMotion); Prism showroom loops locally (11 Nov).
      Full factory of 60 specials: server send 20-65 kbps (was ~90, peaks 200).
- [ ] 8b What is left of that traffic is mostly the toys: every crush makes a new toy model (~35
      instances/s) and its squash changes sizes on the server (~190 changes/s). Next: toys and squash
      on the client too.
- [x] 9 Crusher models cast no shadows in lite mode (phones, low graphics, EFFECTS Low) (11 Nov).
- [ ] 10 **Real pacing**: dashboard `ReachedFactory` / `RebirthMinutes`; if first rebirths are under an
      hour, raise `Rebirth.Growth` a little.
- [ ] 11 **Nothing new after rebirth 10**: milestones at 15/20/25 (a look, a bay skin, a title).
- [ ] Not checked: 15-minute phone soak (Developer Console memory: Gui, GraphicsTexture, LuaHeap), touch
      target sizes, D1/D7 retention, shop funnel.

## Willem
- [x] Exotic / Eternal Auto Roller art uploaded and in the game (11 Nov)
- [ ] Gem cave models: standing portal ring, a sign board (GEM UPGRADES / AUTO WALK), optional platform
      edge segment.
- [ ] Save to Roblox after model changes (Mythic templates, Gem Mine meshes, Eternals).
- [ ] Delete `ServerStorage.OldMythicMeshes` once happy with the new Mythics.
- [ ] Test the Gem Mine with two players (private gems, one shared crusher).

## Earlier audits, still open
- [ ] Crusher lock (5 Nov QoL #2): keep-forever toggle that Trash all / Recycle / Fuse skip (server).
- [ ] Haptics (5 Nov QoL #3): `HapticService` pulse on SMASH, golden toy grab, big roll impact.
- [ ] "Tomorrow: ..." on the daily reward panel (4 Nov R3, D1 hook).
- [ ] Chat [VIP]/[PLUS] prefixes stop working Feb 2027 (platform chat): overhead tag only.
- [x] `/credits` is Studio only now (11 Nov; the dev panel replaces it)
- [ ] Referral: inviter misses the reward if their mailbox write fails (rare, not retried).
