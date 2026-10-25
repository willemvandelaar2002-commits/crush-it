# Apply matching rarity rows

This patch targets main `7728d07` and retains the quests, colour, crusher model,
roll reveal, Daily Spin, Equip Best and tutorial work already there.

From the repository root:

```bash
git apply --check /path/to/crush-it-rarity-rows.patch
git apply /path/to/crush-it-rarity-rows.patch
rojo serve --port 34873
```

If the check fails against newer local work, have the connected coding agent
merge the patch while preserving that work. Restart Studio Play after sync:
row furniture is built with the plots. No model import, new image upload,
save reset or place-template replacement is required.

Run disposable fixtures from the Studio Server command bar:

```lua
local tests=game.ServerScriptService.Server.Tests
print(require(tests["CrusherRows.spec"])())
print(require(tests["CrusherRules.spec"])())
print(require(tests["CrusherUpgradeView.spec"])())
print(require(tests["DailySpin.spec"])())
print(require(tests["QuestRules.spec"])())
```

Then use a disposable Play profile, not live player saves:

1. Unlock a six-bay row. Equip five Epic crushers with different models/levels;
   the sign should show EPIC SET 5/6, with no output boost. Add the sixth: it
   should show EPIC ROW 6/6, +25% SCRAP ACTIVE and purple front/top strips.
2. Compare actual completed-object scrap with the same machines outside a
   set. Damage/speed/HP must stay unchanged. Test Golden Rush and Collect/Sell
   to verify one bonus at completion, no multiplier when transferring balances.
3. Swap one member to Rare or unequip it. Future output/Owned previews should
   lose the bonus, glow should stop, and already banked scrap should remain.
   Replace it with another Epic: the bonus should return automatically.
4. Test Common +5%, Uncommon +10%, Rare +15%, Legendary +40%, and four different
   complete rows at once. A bonus applies only to its own physical row. Locked
   or empty bays do not qualify; six matching machines spread across rows
   do not qualify.
5. Inspect low signs and trim from ordinary play views, upper rows and angled
   bays. Signs should be readable and should not block LEVEL UP/SWAP clicks or
   player movement. Check the row-aware Owned footer and output labels.
6. Test Equip Best on a valuable levelled matching row. It should keep the
   setup if its raw-output choice would reduce total row-aware production,
   with an explanatory message. Ordinary improving selections still work.
7. Fill a busy factory; only four nearby active rows should pulse. Walk away,
   stream out/in, break a set during a pulse, leave/rejoin and release/reuse a
   plot. Check no stale glow, loose effects or new Output errors. Rejoin should
   derive sets from normal saved equipment without a new saved unlock flag.
8. Verify quests, purchases, rolling, Daily Spin, collect/sell and upgrades.

The patch has 610 new row assertions, 1,073 existing regression checks and
116 mocked world-runtime checks passing offline. All source files compile
with LF endings. These do not verify real Roblox rendering, replication,
input/raycast behaviour, streaming, performance or engine Output. A connected
Studio Play check is still required. Desktop only.

Plot expansion, an Upgrade Plot board, a fifth row and merging/forging are
not part of this first mechanic. No new irreversible item consumption is added.
