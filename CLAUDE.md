# Crush It — for Claude

Read `docs/Home.md` first: the plan, the numbers per system, the decisions
log and the backlog. When a session decides or changes something, add a
dated line to `docs/Decisions log.md` and update the matching note in
`docs/Systems/`.

- Roblox Luau, Rojo syncs `src/` to Studio (`rojo serve --port 34873`, so it
  doesn't clash with WarChest on the default port). Files use LF endings.
- Rojo only manages ReplicatedStorage.Shared, ServerScriptService.Server and
  StarterPlayerScripts.Client; the world is built by code (`Plots.luau`).
- Every number is in `src/shared/Config.luau`.
- `src/server/Kit/` is reusable between games (session-locked saving).
- After a change: a short plain-language list of what changed, then the git block.
