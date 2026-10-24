# Apply the upgrade clarity patch

Prepared against main commit `3c17cf2` (24 October 2026).

Give `crush-it-upgrade-clarity.patch` to the coding agent with this instruction:

> Apply this patch to our existing Crush It project after reading CLAUDE.md and
> docs/Home.md. Preserve newer changes. It clarifies individual crusher levels,
> factory-wide upgrades and rolling upgrades through the existing physical plot
> controls. Keep all prices, formulas, save schemas, remote IDs, current assets,
> backpack placement and the forty-crusher catalogue. Resolve overlapping changes
> deliberately; don't reset the branch or force the patch. Read
> docs/Systems/Upgrade controls.md for the completed checks and remaining desktop
> Studio Play review. Sync the complete src/ tree through Rojo on port 34873 in
> Edit mode, then Play and check Output. Defer phone work.

For a matching checkout, use `git apply --check` before `git apply`. The patch
includes the new shared view module and pure fixture: copying only the modified
scripts would leave a missing require.

No place assets need importing for this change. Repository changes are prepared
locally; they have not been pushed to GitHub or verified in Studio here.
