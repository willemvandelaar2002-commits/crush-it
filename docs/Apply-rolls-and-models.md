# Roll reveals and remaining models — 25 October 2026

This combined patch targets GitHub main `4331b25`, which already has Daily
Spin, the first thirteen identity rigs, Equip Best, tutorial and upgrade clarity.
Preserve newer local work when merging. No imported place assets are replaced.

From the repository root, apply the combined package's APPLY-THIS.patch:

```bash
git apply --check /path/to/APPLY-THIS.patch
git apply /path/to/APPLY-THIS.patch
rojo serve --port 34873
```

Restart Studio Play to rebuild all static crusher previews. No model import,
mesh upload, asset-ID edits or balance changes are needed. Separate patches
are supplied as an alternative: stage 1 roll reveals, then stage 2 models.

In the server command bar, run disposable fixtures:

```lua
local tests=game.ServerScriptService.Server.Tests
print(require(tests["CrusherRollPresentation.spec"])())
print(require(tests["CrusherIdentities.spec"])())
print(require(tests["CatalogCrushers.spec"])())
print(require(tests["CrusherRules.spec"])())
```

Then verify on desktop with a disposable Studio profile:

1. Roll with five pedestals and force each rarity through the existing test
   harness. Inspect type odds at Luck 0/max, with/without the Lucky pass, and
   the first Common-only draw. Confirm one local Rare+ chime per batch.
2. An unowned offer must say UNOWNED. Purchase it: NEW DISCOVERY appears once.
   Buy a duplicate, try insufficient cash/full inventory, then Sync/rejoin;
   none should claim a new discovery. Another offer of that now-owned type
   should lose its UNOWNED label. Purchasing never adds an extra reward.
3. Start another roll at the real cooldown boundary, leave mid-reveal, and
   buy during the stagger. Old callbacks must not recreate bought offers.
4. Inspect all forty Index previews and all twenty-two new rigs in a working
   bay, on a roll pedestal and held from the backpack. Compare front/back and
   upper/angled bays. Check ScrapShark's hinge, Bench's horizontal jaw,
   DoubleStamp's alternating/simultaneous strokes, raised beds and telescoping
   rods. Inputs must fit without clipping through the bed.
5. Test twenty or more working crushers. Only four nearby decorated rigs get
   additional idle animation; plain starters should not occupy those slots.
   Walk/zoom away and back and test actual stream-out/re-entry. Confirm smooth
   frame time, no loose carried pieces and all five imported models intact.
6. Check collect, sell, upgrades, Equip Best, tutorial, Daily Spin, Index and
   Shop. Verify no new Output errors. Do not modify live player saves.

All supplied checks here were offline with actual source modules and Roblox
API substitutes. No connected Studio session is available in this environment;
visuals, audio permissions, real tween/replication and performance remain to
be verified in-engine. Previews use actual exported geometry with Blender
review lighting, not Studio lighting. Phone work remains deferred.
