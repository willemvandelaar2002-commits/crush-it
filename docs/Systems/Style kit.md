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

## server/Kit/Build.luau
- `Build.block(parent, name, size, cf, color, studFaces?)`
- `Build.platform(parent, name, topCf, w, d, h, color, edgeColor, edge?)` raised slab with a lip
- `Build.inset(...)` framed patch on a surface
- `Build.signFrame(parent, baseCf, w, h, frameColor)` chunky sign on posts -> (model, face)
- `Build.label(part, text, color, offsetY, sizeStuds?)` big floating outlined label
- `Build.lighting()` bright cartoon lighting (colour correction, bloom, atmosphere)

## In Crush It
`Config.Look.Theme = "Teal"`: yellow studded ground, raised teal plot
platforms with dark edges and a coloured trim per plot, framed pad under the
press, conveyor with yellow rails, chunky studded sign + board, floating
labels over the press ("Rusty Press") and board ("Upgrades"). Plot floors are
now at y = 1.6 (raised platforms).
