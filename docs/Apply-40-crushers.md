# Apply the 40-crusher update

The patch edits the Luau files in the GitHub checkout. It is applied on your
computer in the project folder that contains `CLAUDE.md`, `src/` and
`default.project.json`. The patch file itself can stay in Downloads.

Use **crush-it-40-crushers.patch**. It includes the previous Index UI changes,
all 40 live types and the 29 new procedural models. The new models are built
automatically in Studio by the code. Existing imported special templates stay
in their place-file folder.

## With Codex

Attach the patch to the Codex session working in the current crush-it checkout.
Give it these instructions:

> Read CLAUDE.md and docs/Home.md. Apply the attached crush-it-40-crushers.patch
> to this project. It is a combined patch based on commit 2584a5b and includes
> the earlier Index-only update. Preserve all local and newer work. If the old
> UI patch is already applied, apply the remaining catalogue/model changes
> without duplicating it. Resolve conflicts against the current code. Run the
> CrusherRules, SpecialCrushers and CatalogCrushers Studio test modules, then
> check all 40 Index entries, Owned equipment/recycling, roll reveals and bay
> animation in Play. Keep upgrades on world boards and leave phone work for
> later. Report the Studio checks actually completed.

## Manually, if the earlier UI patch has not been applied

1. Stop Play in Studio.
2. Open a PowerShell terminal in the project folder.
3. Run the check first, then apply:

```powershell
git apply --check "$env:USERPROFILE\Downloads\crush-it-40-crushers.patch"
git apply "$env:USERPROFILE\Downloads\crush-it-40-crushers.patch"
```

If the check reports a conflict, have Codex integrate it into the current
checkout. Do not reset, force or discard existing work to make it apply.

4. Start or keep the existing Rojo server running:

```powershell
rojo serve --port 34873
```

5. Connect Studio to that Rojo session in Edit mode and sync the new scripts.
6. Press Play, open INDEX and check that the total is **40**. The 29 new
   models require no separate asset import. Existing imported special assets
   still need to be present in `ServerStorage.SpecialCrusherMeshes`.

The supplied offline checks passed, but this update still needs Studio Play
and appearance verification on your machine before publishing the game.
