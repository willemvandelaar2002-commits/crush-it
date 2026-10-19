# Style kit (reusable in other games)

The studded "Destroy a Vault" look, split out so the next game can copy it:
copy `src/shared/Kit/` and `src/server/Kit/` (DataService, Analytics, Build)
and require them.

## shared/Kit/Style.luau (client + server)
- `Style.studs(part, faces?, perTile?)` stud texture (free image 7447638591, 2 studs/tile)
- `Style.theme("Teal" | "Scrap")` world colours: ground, platform, edge, path, dark, pad, light
- `Style.panel(frame, colorA, colorB?)` gradient panel, dark outline, white inner border, studs
- `Style.button(button, color?)` glossy green (or any colour) button; `Style.setButtonColor`
- `Style.text(label, stroke?)` white Fredoka text with dark outline
- `Style.studsImage(gui, tile, transparency)` stud pattern in UI
- `Style.iconButton(parent, {name, icon, label, a, b?, size?})` -> (button, badge): big tilted gradient tile with an emoji, outlined label and a red "!" badge; grows on hover, squishes on click
- `Style.rainbow(gui, speed?)` moving rainbow gradient (client only)
- `Style.wobble(gui, degrees?, speed?)` gentle tilt back and forth (client only)

## server/Kit/Leaderboard.luau
- `Leaderboard.start({ store, score = fn(player) -> number, top? = 50, every? = 120 })`
  writes each player's score to an OrderedDataStore (as log10(score+1)*1e6 so huge
  numbers fit), reads the top N and publishes it as JSON in
  `ReplicatedStorage.KitLeaderboard` (Status attribute "ok" / "unavailable").
  The panel UI is game code (Crush It: `client/Leaderboard.client.luau`).

## server/Kit/Build.luau
- `Build.block(parent, name, size, cf, color, studFaces?)`
- `Build.platform(parent, name, topCf, w, d, h, color, edgeColor, edge?)` raised slab with a lip
- `Build.inset(...)` framed patch on a surface
- `Build.signFrame(parent, baseCf, w, h, frameColor)` chunky sign on posts -> (model, face)
- `Build.label(part, text, color, offsetY, sizeStuds?)` big floating outlined label
- `Build.lighting()` bright cartoon lighting (colour correction, bloom, atmosphere)

Props (blocky + studded, colours from the theme's `leaf`, `trunk`, `rock`, `fence`, `lamp`;
pass a seeded `Random` so every server looks the same):
- `Build.tree(parent, baseCf, scale, palette, rng?)` square trunk + 2-3 twisted leaf cubes (~5x12 at scale 1; leaves don't collide)
- `Build.bush(parent, baseCf, scale, palette, rng?)` 2-3 low leaf cubes
- `Build.rock(parent, baseCf, scale, palette, rng?)` 2-3 tilted, half-sunk stones
- `Build.fence(parent, fromPos, toPos, color, {height?, spacing?})` posts with caps every 10 studs + two long rails
- `Build.lamp(parent, baseCf, palette, height?)` dark post with a glowing Neon head and a PointLight

## In Crush It
`Config.Look.Theme = "Teal"`: yellow studded ground, raised teal plot
platforms with dark edges and a coloured trim per plot, framed pad under the
press, conveyor with yellow rails, chunky studded sign + board, floating
labels over the press ("Rusty Press") and board ("Upgrades"). Plot floors are
now at y = 1.6 (raised platforms).

Props in Crush It (`src/server/Decor.luau`, toggle `Config.Look.Props`, layout seed
`Config.Look.PropSeed`): white fence behind both rows and down both ends (walkway
open), lamp + bush + tree + rock in every gap between plots, lamps at the walkway
ends, and a band of trees/bushes/rocks outside the fence (~230 props, ~1,200 parts).
