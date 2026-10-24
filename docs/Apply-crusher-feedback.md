# Apply the crusher feedback patch

Prepared against main `3c17cf2`, independently of the earlier upgrade-clarity patch.
Apply only `crush-it-crusher-feedback.patch`; it includes all new runtime modules.

Suggested handoff to the coding agent:

> Read CLAUDE.md and docs/Home.md, then apply this patch while preserving newer
> changes and the upgrade-clarity work if present. This adds budgeted local
> crushing audio/visuals and impact-aligned squash through the existing Hit event.
> Preserve gameplay rules, numbers, saves, imported assets and remote names.
> Resolve overlapping edits deliberately; do not reset or force-apply. Sync all
> src/ through Rojo on port 34873 in Edit mode. Run the desktop Studio checks in
> docs/Systems/Crusher feedback.md with 20 equipped crushers, including regular,
> catalog and imported types. Check Output and verify earnings. Tune presentation
> only if the mix needs adjusting. Defer phone work.

Use `git apply --check` before applying to a matching checkout. New assets do not
need importing; the audio uses existing Config.Sounds IDs. Changes are prepared
locally and have not been pushed or tested in Studio here.
