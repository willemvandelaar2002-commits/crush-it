# Apply plot expansion and coatings

The patch targets main `ded180a`, preserving rarity rows, quests, six plots,
road/rail cleanup, leaderboards, colour polish and all existing crusher work.

```bash
git apply --check /path/to/crush-it-factory-progression.patch
git apply /path/to/crush-it-factory-progression.patch
rojo serve --port 34873
```

Merge newer local work if needed. Restart Studio Play after sync so plot
construction includes the extension/lab. No model/image import, place asset
replacement, save wipe or new remote IDs are required.

Use disposable Play profiles and run the server fixtures:

```lua
local t=game.ServerScriptService.Server.Tests
print(require(t["FactoryProgression.spec"])())
print(require(t["CrusherRows.spec"])())
print(require(t["CrusherRules.spec"])())
print(require(t["CrusherUpgradeView.spec"])())
print(require(t["DailySpin.spec"])())
print(require(t["QuestRules.spec"])())
```

Manual desktop checks:

1. With 23 occupied original bays, the upgrade board must stay hidden. With
   all 24 filled (mixed rarities allowed), it appears. Insufficient cash must
   not charge; purchasing once grants Factory II and six open rear bays.
   Repeated clicks must not charge again. Ordinary Unlock cannot skip the gate.
2. Walk down the centre aisle through the opened rear border. Check the low
   extension/floor edges, all six bay plaques, the fifth-row set bonus, lamps,
   trim and Factory II sign. Original roads, train, bridges and scenery should
   remain in place. Check floor collision and no hidden colliders before buying.
3. At the Coating Lab, hold an unequipped crusher. Preview each finish; verify
   current/next production and price, then confirm. It should keep the same ID,
   level/type/rarity, return refreshed to the backpack and show the finish in
   Owned/held/equipped models. Inspect imported and procedural types.
4. Try double confirmation, expired previews, switching held items, insufficient
   cash, a weaker/same finish and an equipped target. Nothing should charge
   without a valid current quote. Re-equip six matching rarities with different
   finishes and verify their row bonus still works.
5. Reload/rejoin a saved disposable profile. Expansion and all four finishes
   must persist; unconfirmed quotes must not. Release/reuse the plot and confirm
   hidden controls, gate, extension floor and colliders reset correctly.
6. Test mouse input on both physical boards and normal upgrades; observe
   streaming out/in. Check collect/sell, quests, Daily Spin, Equip Best, the
   tutorial, inventory, held welds and no new Output errors. Test a busy plot.

Supplied checks are offline and do not establish Studio rendering, interaction,
physics, replication or performance. Do not use live saves for test setup.
Phone work remains deferred. One plot expansion and four yield-only finishes
are included; future expansions/elemental abilities remain separate work.
