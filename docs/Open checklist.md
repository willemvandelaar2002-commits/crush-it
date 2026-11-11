# Open checklist (updated 11 Nov 2026)

Everything from the 11 Nov full audit (`Vault audit 2026-11-11 full game.md`, findings 1-11 and "not
checked"), plus open items from earlier audits and sessions. Tick off here and add a Decisions log line.

## 11 Nov audit
- [x] 1 Luck multipliers barely worked after Luck ~10 -> now multiply every rarity-or-better (11 Nov)
- [x] 2 Paid luck for restricted players -> left as is (Willem: luck also works on free rolls)
- [x] 3 Odds only as "1 in N" -> ROLL ODDS window with percentages (11 Nov)
- [x] 4 Top rarities stopped being rare -> luckRank 3.5 + much rarer base odds (11 Nov)
- [x] 5 Big roll cinematics too frequent -> no cinematic for owned types (11 Nov); and rarer with 4
- [ ] 6 **Gems run out of purpose**: mine upgrades max in ~26 min, everything in 2-3 h. The Gem Crate is
      now a real Secret/Divine source (4 made the roll rarer); check whether that is enough or add a
      lasting sink (crate-only crushers or coatings, a cosmetic, a repeatable upgrade). Hold Gem Yield.
- [ ] 7 **Every client loads all six plots in full** (114k instances, 2,782 invisible parts per empty
      plot): build later stages when reached, unowned plots as a shell, then a smaller streaming radius.
- [ ] 8 **Crusher motion from the server** (~90 kbps per full factory): one strike event per bay, motion
      on each client.
- [ ] 9 `CastShadow` off on crusher meshes with `Style.lite()` (442k triangles in a full Factory VI).
- [ ] 10 **Real pacing**: dashboard `ReachedFactory` / `RebirthMinutes`; if first rebirths are under an
      hour, raise `Rebirth.Growth` a little.
- [ ] 11 **Nothing new after rebirth 10**: milestones at 15/20/25 (a look, a bay skin, a title).
- [ ] Not checked: 15-minute phone soak (Developer Console memory: Gui, GraphicsTexture, LuaHeap), touch
      target sizes, D1/D7 retention, shop funnel.

## Willem
- [ ] Upload the 4 Auto Roller images in `assets/autoroller` (Tab-Exotic, Card-Exotic, Tab-Eternal,
      Card-Eternal) and send the ids: Exotic and Eternal tabs/cards are grey art + tint until then
      (the Index already shows the Eternal icons).
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
- [ ] `/credits` works for the owner in live servers (test cash in the economy analytics).
- [ ] Referral: inviter misses the reward if their mailbox write fails (rare, not retried).
