# Gem Crusher (8 Nov 2026)

Willem: "a special crusher you unlock, REBIRTH 5-10 TO UNLOCK". Config `CrusherConfig.GemCrushers`,
rule `CrusherRules.gemCrusher`, tests in `Tests/Gems.spec`.

- **Rebirth 5:** every player gets one Gem Crusher (Mythic tier). **Rebirth 10:** that same crusher
  (same id, level, finish, bay) becomes the **Awakened Gem Crusher**. Saves already past 5 / 10 get
  theirs on load. Announced to the server; analytics `GemCrusher`.
- Never rolled, never in a crate or shop; can't be trashed or recycled (TrashMany skips it).
- Value per input 1200 (awakened 2400), above every Mythic (660). In a bay it makes Gems:
  1 / min (awakened 2.5 / min) instead of the Mythic trickle.
- Index: shows "REBIRTH 5" / "REBIRTH 10". Icons: Willem's art (`CrusherIcons`, `GemConfig.Art`).
- **Model: not in yet.** It borrows the FactoryHeart rig in gem colours. When Willem's model is
  imported: put it in `ServerStorage.SpecialCrusherMeshes.GemCrusher` (and `...Awakened`), add a
  `SpecialCrusherAssets` entry, set `template` in `C.GemCrushers`. Still to do then: a showcase stand
  on the plot ("REBIRTH 5 TO UNLOCK").
- Rebirth panel: a strip under it shows the Gems the next rebirth pays (gem pile art) and the next
  unlock (`GemConfig.Milestones`: Gem Shop 1, Annex 3, Gem Crusher 5, Awakened 10). After a rebirth
  the pop-up shows the Gems and, at a milestone, its art.
