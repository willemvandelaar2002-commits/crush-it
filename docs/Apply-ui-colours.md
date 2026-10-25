# Brighter colours and clearer studs — 25 October 2026

Apply `crush-it-brighter-colours.patch` from the repository root. It targets
main `ded00dc` and preserves the newer Rewards, roll-reveal and crusher work.

```bash
git apply --check /path/to/crush-it-brighter-colours.patch
git apply /path/to/crush-it-brighter-colours.patch
rojo serve --port 34873
```

Merge with newer local work if the check fails. Restart Studio Play after
Rojo syncs the shared Style module, UpgradeView and Workshop builder. No new
image uploads, imported materials or place-file changes are required.

Inspect Factory/Roll Upgrades, bay purchase plaques, Shop/Index and Rewards.
Compare the red/yellow/green rows and stud visibility with the supplied
reference. Check Ready/Short/Max buttons, hover/click feedback, readable text,
panel open/close and no new Output errors. Explicit Rewards texture choices
remain controlled by Rewards. World floor/material/lighting settings stay as
they were; this patch addresses the coloured controls and shared UI finish.

All 88 Luau files compile with LF endings. A disposable helper smoke check
exercised panel/collection styling, recolouring and explicit stud overrides;
repeated styling retained the same decoration counts. Gameplay configuration,
rules and remotes are unchanged. No Studio is connected here, so appearance
and real Play checks remain for the connected coding agent. Desktop only.
