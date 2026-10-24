# Apply the crusher identity pass

Based on GitHub main `3c17cf2`. Apply from the repository root:

```bash
git apply --check /path/to/crush-it-crusher-identities.patch
git apply /path/to/crush-it-crusher-identities.patch
rojo serve --port 34873
```

If the check fails against newer local work, have the connected coding agent
merge the patch into the current checkout while preserving its newer features.
Do not reset the repository or paste the entire patch into a Studio script.
The changes are code-built: no FBX import and no replacement of place assets.

Before playing, ensure Rojo has synced the two new shared modules and the new
client LocalScript along with the three changed presentation builders. Stop
and restart Play so the server regenerates static collection previews.

In Studio Play, run the disposable test from the Server command bar:

```lua
print(require(game.ServerScriptService.Server.Tests["CrusherIdentities.spec"])())
print(require(game.ServerScriptService.Server.Tests["CatalogCrushers.spec"])())
```

Then check on desktop:

1. Open Index, filter Epic/Legendary and inspect every model. There remain
   forty entries and eight types per rarity. Close/reopen Index.
2. Roll on the existing pedestals; silhouettes and revealed results use the
   same new shapes as Index. Purchase/equip/unequip a crusher normally.
3. Using the connected agent's disposable Play test profile, equip all thirteen
   updated types in turn. Check front/back views, upper/angled bays, input
   clearance and full down/return strokes. Inspect DragonJaw's hinge/fangs.
4. Inspect rotating Starforge crown, clock hands/gears, accretion disc, turbine,
   gyroscope, gravity weights and induction ring. Check FactoryHeart's pulse.
   Titan/Quake/Mecha rely mainly on their actual crushing motion.
5. Hold an unequipped crusher: its mini model should match Index without loose
   ornaments. Verify TwinTitan, GoldenKing and Toyzilla still use their imported
   models; restore missing templates if they were already absent.
6. Fill twenty or more working bays in the disposable test profile. Only four
   nearby equipped rigs get ornament motion. Walk/zoom away and back, and test
   streaming out/in. Ensure steady performance and no new sounds or spam.
7. Confirm normal scrap production, collection, sale and upgrades, and no new
   errors in Output. Do not edit live saves to set up the checks.

This environment has no connected Roblox Studio, so those Play checks have
not been completed here. No commit is pushed or game published by this patch.
