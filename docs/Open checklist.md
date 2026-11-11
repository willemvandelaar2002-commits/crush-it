# Open checklist (11 Nov 2026)

What still needs doing, from the 11 Nov full audit (`Vault audit 2026-11-11 full game.md`) and earlier
sessions. Tick items off here when they are done (and add a Decisions log line).

## Decisions for Willem
- [ ] **How rare should the top stay?** (audit 4) Luck multipliers now work (11 Nov), so Secrets,
      Divines and Eternals come faster for players with passes, boosts and rebirths (Eternal 1 in ~240-1,250
      per pedestal mid/late game). Knobs: `C.LuckMultCap` (10), `C.LuckGrowth`, a cap per rarity, or a new
      chase above Eternal.
- [ ] **Gems need a lasting sink** (audit 6): mine upgrades max in ~26 min of mining, everything in ~2-3 h;
      then only the Gem Crate. Ideas: crate-only crushers or coatings, a cosmetic, a repeatable upgrade.
      Hold "Gem Yield" until then.
- [ ] **After rebirth 10** (audit 11): rebirth milestones at 15/20/25 (a look, a bay skin, a title).

## Build next
- [ ] **Short big-roll cinematic for types you already own** (audit 5); full one for a first-time type.
- [ ] **Plots: build later stages when reached, unowned plots as a shell** (audit 7; 114k instances on every
      client, 2,782 invisible parts per empty plot). Then try a smaller streaming radius.
- [ ] **Crusher motion on the client** (audit 8): one strike event per bay instead of server tweens
      (~90 kbps per full factory today).
- [ ] `CastShadow` off on crusher meshes with `Style.lite()` (audit 9).
- [ ] Index and Auto Roller: Eternal tab/card art (still grey + tint).
- [ ] Gem cave models from Willem: standing portal ring, a sign board (GEM UPGRADES / AUTO WALK), optional
      platform edge segment; then the Blender pass and wiring.

## Check / measure
- [ ] **Real pacing** (audit 10): Creator Dashboard events `ReachedFactory`, `RebirthMinutes`. If first
      rebirths are under an hour, raise `Rebirth.Growth` a little.
- [ ] D1 / D7 retention and the shop funnel since 3 Nov.
- [ ] 15-minute phone soak with the Developer Console memory page (Gui, GraphicsTexture, LuaHeap).
- [ ] Test the Gem Mine with two players (private gems, one shared crusher).

## Housekeeping
- [ ] Save to Roblox after model changes (Mythic templates, Gem Mine meshes, Eternals).
- [ ] Delete `ServerStorage.OldMythicMeshes` once happy with the new Mythics.
- [ ] Chat [VIP]/[PLUS] prefixes stop working Feb 2027 (platform chat): move to the overhead tag only.
- [ ] `/credits` works for the owner in live servers (test cash in the economy analytics).

## Decided, not doing
- Paid luck for players where paid random items are restricted: left as is (11 Nov, Willem: luck also
  applies to free rolling).
