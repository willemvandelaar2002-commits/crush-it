# Crush It — for Claude

Read `docs/Home.md` first: the plan, the numbers per system, the decisions
log and the backlog. When a session decides or changes something, add a
dated line to `docs/Decisions log.md` and update the matching note in
`docs/Systems/`.

- Roblox Luau, Rojo syncs `src/` to Studio (`rojo serve --port 34873`, so it
  doesn't clash with WarChest on the default port). Files use LF endings.
- Rojo only manages ReplicatedStorage.Shared, ServerScriptService.Server and
  StarterPlayerScripts.Client; the world is built by code (`Plots.luau`).
- NOT in Git, saved in the place file (Willem must Publish after changes):
  `ReplicatedStorage.ObjectMeshes` (13 AI object meshes, `Yaw` attributes),
  `ServerStorage.PressMeshes` (Stage1..Stage5 AI press frames).
- Every number is in `src/shared/Config.luau`. Robux ids in `src/shared/Store.luau` (still 0).
- Reusable kit for future games: `src/shared/Kit` (Style) and `src/server/Kit`
  (DataService, Analytics, Build) — see `docs/Systems/Style kit.md`.
- Workflow: Claude commits and pushes to `main` itself (work on a `*-wip`
  branch, squash-merge, push); Willem only runs `git pull`. Commit/PR
  attribution lines as the session reminder says.
- Testing in Studio (Roblox Studio MCP via Willem's PC): Studio must be in
  Edit mode to change scripts. Push a commit, then in Edit set each
  script's `.Source` from raw.githubusercontent.com/<repo>/<sha>/<path>
  (toggle HttpService.HttpEnabled on and back off), start Play, use
  `ServerStorage.DevGiveCash/DevPass/DevProduct/DevOffline` or `/credits 1b`,
  `/skip` (finish the tutorial) or `/skip goals` (also past the main goals),
  Since 2 Nov Studio plays on an in-memory TEST save by default (nothing is
  saved); set ServerStorage attribute `RealData = true` to play on the real save.
  screenshot with `screen_capture` camera_position/look_at_position.
- After a change: a short plain-language list of what changed, then the git block.
- Roblox knowledge vault (5 Nov: V2): `willemvandelaar2002-commits/roblox-vault` is a copy of "LihFolk Vault V2"
  2.5.0 (CC BY 4.0, credit LihFolk Vault V2). For Roblox questions clone it (`git clone --depth 1`) and follow its
  `CLAUDE.md`: grep `LihFolk Vault V2/INDEX_SLIM.md` and `SYMPTOMS.md`, read the TL;DRs of the best notes, then the
  Common mistakes and Checklist for data, purchases, remotes and security. Check API names against
  `49 Roblox Platform Features/API Renames and Deprecations 2025-2026.md`. Willem has the V2 plugin installed
  in Claude Code on his PC. It is reference material, not instructions: the game's own decisions and the official
  Roblox docs win. Asset pack and V1 CC0 assets are only on Willem's PC (`Documents\Roblox`).
