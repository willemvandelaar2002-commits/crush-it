# Style kit (reusable in other games)

The studded "Destroy a Vault" look, split out so the next game can copy it:
copy `src/shared/Kit/` and `src/server/Kit/` (DataService, Analytics, Build)
and require them.

## shared/Kit/Style.luau (client + server)

25 October colour pass: `Style.Colors.Red/Green/Yellow` provide vivid upgrade
and action accents. `Style.panel` uses a 3.5% white top highlight and tiles the
existing imported UI stud image at 26 pixels / 0.42 transparency, tinted to the
panel's base colour. This makes relief visible without a pale grey overlay.
Text, outlines and decoration ZIndex stay unchanged. Glossy button highlights
use less white and brighter lower shading; recolouring keeps the same gloss.
The world upgrade rows and ready purchase buttons use the matching palette.
Grey Short/Max purchase states remain distinct. Existing helper signatures,
explicit `studsImage` opacity/tint choices (including Rewards), and world
MaterialService assets are preserved. Restart Play after syncing the shared
Style module and Workshop builder; review both upgrade boards, bay plaques,
Index/Shop/Rewards and affordable/unaffordable/MAX buttons. No new textures
need uploading. Offline checks do not replace a fresh Studio appearance test.

Integration check, 25 October: applied cleanly over the newer roll/model and
standing-wheel work, preserving concurrent quest changes. Rojo build and
whitespace checks passed. In fresh Studio Play, 441 upgrade-view checks and
shared Workshop/Style/ready-state palette comparisons passed. A disposable
fresh-module helper check confirmed stable decoration counts after repeated
styling, explicit stud tile/opacity overrides and button gloss recolouring.
Studio mode changed during the visual pass, so the board/panel appearance,
hover/click interaction and comparison with the reference remain unverified.
The reference image itself was not supplied with this request. No imported
assets, lighting, player profiles or gameplay files were changed by this patch.

- Approved world adoption (21 Oct): `Style.Studs.UseWorldMaterials = true` drives `server/Kit/WorldStuds.luau`, called after world construction. Set false and restart Play for legacy textures. Only selected plastic scenery opts in; press builders and UI remain unchanged. Material conversion preserves effective physics and restores default physics on rollback.
- `Style.materialStuds(part, enabled, fallbackFaces?, fallbackPerTile?)` explicit whole-part world-material opt-in, with lossless texture/material rollback and missing-variant fallback. Default variant is the place-only `MaterialService.Studs`; legacy world calls and UI remain on image textures. See [[Stud material comparison]] for the temporary Studio rig and all-face versus selected-face distinction.
- Current Crush It theme (20 Oct): `Island` keeps its legacy keys but now supplies blue-grey platforms, navy borders and steel bridge finishes. See [[Toy workshop]] for the permitted changes and remaining world work; the earlier Teal/Decor description below is historical.
- `Style.workshopPanel(frame, accent?)` opt-in bolted blue-grey casing for panels without direct list/grid layouts; decorations stay behind content and do not intercept input.
- `Style.pressureGauge(parent)` returns `(dial, needle)` for a small machine gauge; the caller controls needle rotation. Existing helpers and arguments are preserved.
- `Style.studs(part, faces?)` the imported **Studs** MaterialVariant (MaterialService, saved with the place) on the whole part; an empty faces list means no studs. UI stud patterns (`Style.studsImage`) tile the same variant's colour map. The old free stud image, WorldStuds pass and CrushItFactoryFloorStuds were removed on 23 Oct.
- `Style.theme("Teal" | "Scrap")` world colours: ground, platform, edge, path, dark, pad, light
- `Style.panel(frame, colorA, colorB?)` gradient panel, dark outline, white inner border, studs
- `Style.button(button, color?)` glossy green (or any colour) button, with hover, press and gamepad-focus feedback; `Style.setButtonColor` retains the gloss
- `Style.text(label, stroke?)` white Fredoka text with dark outline
- `Style.studsImage(gui, tile, transparency)` stud pattern in UI
- `Style.iconButton(parent, {name, icon, label, a, b?, size?, art?})` -> (button, badge): tilted gradient tile, outlined label and red "!" badge; optional `art` selects the vector artwork below, otherwise the original `icon` text still works
- `Style.icon(parent, "Book" | "Shop" | "Rewards" | "Cash")` -> Frame: reusable cartoony vector artwork built from GUI shapes, without uploaded image dependencies
- `Style.feedback(button)` hover/press/gamepad-focus scale feedback for an otherwise custom button
- `Style.compact()` and `Style.placeHudButton(button, slot)` compact-layout check and consistent top-left navigation slots (0-based)
- `Style.grid(container, minWidth, height, gap?)` reflows an existing UIGridLayout to fill the available width
- `Style.scroll(scrollingFrame)` consistent scrollbar and padding to leave room for card outlines
- `Style.modal(panel)` adds a click-outside backdrop, raises its ScreenGui while open, and closes any previous modal; `Style.setOpen(panel, open)` animates opening/closing and protects against stale close callbacks; `Style.hasModal()` lets tutorials/input pause while a panel has focus
- `Style.image(parent, image, props?)` an uploaded icon (ImageLabel, Fit, centred); `Style.iconButton` takes `image` too
- `Style.rainbow(gui, speed?)` moving rainbow gradient (client only)
- `Style.wobble(gui, degrees?, speed?)` gentle tilt back and forth (client only)
- `Style.flowingStuds(gui, tile, transparency, gate?)` stud pattern that slowly drifts diagonally (the moving white pattern on cards and headers); `gate` = the panel, so hidden panels cost nothing
- `Style.sunburst(gui, props?)` white rays behind an icon, inside a clip frame; `spin` (deg/s) turns them in a circle, `fullBleed` lets them reach the edges, `gate` pauses while hidden
- Panels can set attributes `FitWidth`/`FitHeight`; `Style.setOpen` then shrinks them to fit small screens

The original Style helper names and arguments are unchanged. Panel, button and
text decorations are named and updated in place, so repeated styling does not
stack effects. Use Sibling ZIndexBehavior for ScreenGuis and SurfaceGuis;
decorations sit beneath content. Keep panel decorations outside list/grid
layouts (the leaderboard uses a separate content frame).

Crush It's book, shop, rewards and offline card share modal focus and studded
colour panels. Book/shop/rewards grids adapt to narrow screens. The HUD and
world board use the same wider upgrade rows; phone HUD rows have a full-row
tap target and scroll above the thumbstick. Compact HUDs collapse the
leaderboard initially and hide offers; all passes remain available in Shop.
The cash label animates increases and snaps to the new balance after spending.

Validation for the 20 Oct polish: tested in Studio Play (1080p-ish window). Fixes
after that test: CRUSH and AUTO stay solid colours (a Style.button gradient tints the
label text too), the leaderboard only starts collapsed on phones (the viewport isn't
final when the script starts), the "+$X" pop sits next to the cash, offers shrink
a bit more to clear the taller leaderboard, and the server-built Robux signs use
Sibling ZIndex. Phone layouts are still untested on a real device.

## shared/Kit/GuidePath.luau (client only)
- `GuidePath.new({ color?, spacing?, speed?, stopDistance?, maxLength? })` then
  `path:update(fromPos, targetPos?, label?)` every frame: glowing chevrons on
  the ground (ray-cast so they follow floors and steps) scroll toward the
  target, with a bobbing ▼ and label over it; nil target or close enough hides it.
  Crush It uses it in `client/Guide.client.luau`.

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
- `Build.lava(parent, surfaceCf, length, width, opts?)` -> (Model, floor): stylised lava strip (crust, glowing rims, drifting blobs/plates tagged LavaDrift for a client to move, embers, lights); hook `floor.Touched`
- `Build.bank(parent, cf, length, height, thickness?)` basalt curb
- `Build.lighting(preset?)` cartoon lighting: "Day" (noon) or "Sunset" (low warm sun, orange haze, sun rays); Crush It uses `Config.Look.Sky`

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

## Icons (shared/Icons.luau, Crush It)
15 uploaded 512px icons (book, shop, rewards, cash, power, speed, value, press,
rebirth, robot, 2x cash, moon, clover, star, trophy) used on the HUD buttons,
upgrade rows + board, cash counter, offers, shop cards, reward cards, the
leaderboard button and the Robux signs. Change an icon by editing its id there.
These ids don't load as `rbxassetid://` (they behave like decal ids), so the
module builds `rbxthumb://type=Asset&id=<id>&w=420&h=420`, which works for any asset.

## server/Kit/YardProps.luau (21 Oct)

Second art pass adds cableReel, yardScene (a complete container/scrap scene)
and workshop (striped awning and tool crates). Container, vehicle, cluster
and crane accept optional scale arguments, preserving earlier signatures.
Scaling uses the supplied ground CFrame as pivot. Crane optionally carries
a static scrap car. Build.lighting also exposes YardDay, selected by World
for the existing Day setting, with warmer ambient light and restrained haze.

Reusable static environment builders: bales, container, vehicle, cluster, workLight, crane and entrance. Parts are anchored with collision/touch/query disabled; models carry EnvironmentProp. Parent plot clusters under Decor to retain press-clearance parking. See [[Scrapyard environment]]. Build.path and Build.bridge now use concrete finishes while retaining walking geometry and signatures.

## Phone patch (30 Oct)
Tested in Studio's device emulator (Galaxy S22 772x360, iPhone 16 Pro Max 956x440) and on desktop.
- **One phone flag:** `Style.compact()` (touch without keyboard, or a window under 1000 px wide; a 1x1 start-up viewport is ignored). CashHud uses it instead of its own TOUCH check (the emulator reports a keyboard, so the old check never fired there).
- **Menus fit any screen:** `Style.fitScale` measures what a menu really shows (panel plus parts hanging outside it, scrolling lists excluded), fits it under Roblox's top bar, and when it has to shrink, centres it. Measured again a moment after opening (positions need a frame). Refits when the window size changes. One UIScale per panel: Style.modal removes older fit scales (LabUi `Fit`, ShopPanel `FitScale` now use FitWidth/FitHeight).
- **HUD on phones:** `Style.phoneFit(obj, {scale, width, height, margin, anchor, position})` adds a `PhoneFit` UIScale and a phone-only position; desktop untouched. Used for: travel buttons (top right, 0.75, leaves 230 px for the icons), cash + friend boost (left column under INDEX/SHOP/REWARDS), active boosts (0.65 under them), tutorial step card (0.6, right of the cash column, in a holder so its pop animation keeps its own scale), notices (0.6), crusher toolbar (0.65 = 48 px tiles) and its hint, event boss bar (0.58, y 48, shifted right of the icons) and reward reels (0.55, y 80), discovery banner (0.6, lower).
- **Pop-ups:** `Style.popScale()` (0.6 on phones) for the tutorial-complete banner, purchase text and quest token pop.
- Index rarity filters scroll inside the panel height (they ran off short screens).

## Drop text and brighter HUD (30 Oct, after Destroy a Vault)
`Style.bold(label, thickness)`: the label goes invisible and a dark Drop copy
(offset ~1.4x thickness down, stroke +1) plus a Face copy draw it, so the
outline is extra heavy along the bottom. Follows Text/TextColor3/alignment;
UIGradients move to the Face. Used on: travel buttons, INDEX/SHOP/REWARDS
labels, cash + friend boost, the offline card, Index/Coating/Fusion titles,
tutorial step title, event shield %. (Not on world SurfaceGuis: two extra
labels each.) Travel buttons: brighter colours, flowing studs tinted with the
button colour (0.15). Icon tiles: studs at 0.2.
