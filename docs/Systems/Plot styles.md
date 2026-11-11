# Plot styles (plan, 11 Nov 2026)

Status: **built 11 Nov (step 1): earned styles as palette recolours, the PLOT STYLES board, the
window, cash bonus.** Gem styles wait for Willem's designs. Agreed with Willem on 11 Nov after the funnel (Factory II -> III 19%,
III -> IV 18%): no extra guide; Factory III gets its own reward, and gems get a lasting purpose.
Willem designs the styles (Legendary and up, plus special ones).

## The idea

A plot style changes how your whole factory looks, without changing its layout: floor, trim, rim
and lamps, columns, board frames, the entrance arch, the lights and one signature prop. Other
players see it when they walk past. Styles are kept forever (through rebirths).

## How you get one

| Kind | Styles | How |
| --- | --- | --- |
| Classic | today's look | everyone has it |
| Earned | Legendary, Exotic, Secret, Divine, Eternal | a full row (6 bays) of that rarity or better, equipped at the same time, once; the server checks it when your rows change |
| Special | Willem's themes (e.g. Candy, Neon City, Crystal Cave, Arctic, Jungle) | bought with Gems at the Style board |

- The **Style board** stands on your plot from **FACTORY III** (the Factory III cutscene's unlock
  text becomes "PLOT STYLES"). Before that the styles don't show anywhere.
- The board shows every style: owned ones to pick, earned ones with their row goal ("6 Legendary
  in one row"), special ones with their Gem price. Picking one is free.
- Proposed Gem prices for special styles: 15,000 / 30,000 / 60,000 (about 40 min, 1.5 h and 3 h of a
  maxed Gem Mine). Gems so far only have upgrades worth ~59,600 in total, so this doubles what
  there is to spend them on and keeps going as Willem adds styles.
- Every style you own adds cash forever (they add up; Willem: "more expensive give higher cash"):
  Legendary +2%, Exotic +3%, Secret +4%, Divine +6%, Eternal +8% (all five: +23%). Gem styles:
  +2% / +3% / +5% for 15,000 / 30,000 / 60,000 Gems. It multiplies income like the other cash
  boosts (CrusherGame perks).

## What a style changes (what Willem designs per style)

Per style, the same pieces as the trim kit, with the style's name as suffix (`CornerBrace_Legendary`):

- floor: colour and material (or a texture), a stud pattern or checker
- rim block and rim corner (the platform edge), lamp post and lamp colour
- support beam / column, corner brace (foot of a column)
- board frame (round the station boards)
- entrance arch
- one signature prop (placed at two fixed spots on the plot)
- a palette: floor, trim, accent, light colour (hex)

Pieces that are missing fall back to a recolour of the Classic piece in the style's palette, so a
style can ship with only a palette and gain its models later.

## How it is built (code)

- Save: `crushers.styles = { owned = { id = true }, active = "Classic" }`, migrated in CrusherRules;
  rebirth keeps it.
- `Shared.PlotStyles`: the list (id, kind, rarity or Gem price, palette, kit suffix).
- Server: earning is checked where rows are recomputed (`CrusherRows`); `Equip`/`Buy` style actions
  through the existing CrusherAction remote; the plot look is applied in `PlotStages`
  (floor colours, trim colours, the trim kit, which today picks a colour version per factory level)
  and on the plot's rim/lamps/arch.
- The plot's style shows to everyone (it is the plot itself); a small "LEGENDARY PLOT" plate by the
  entrance names it.
- Analytics: StyleEarned, StyleBought, StyleEquipped.

## As built (11 Nov)

- `Shared/PlotStyles` (list, palettes, cash, earning check), `CrusherRules` (save `crushers.styles`,
  `SetStyle`, `BuyStyle`, `R.earnStyles`), `server/PlotStyleLook` (recolours floor tops, trim,
  rim blocks/corners, lamp posts/caps/lights; PlotStages.sync reads `plot.stylePalette`),
  `client/PlotStyles` (the window), the PLOT STYLES board in `FactoryProgressionVisuals` at
  plot-local (15.5, 15) beside the road (OPEN = CrusherHud action "Styles").
- Earning is checked every second in `send`; a new style is announced server-wide and goes on
  your plot if it still showed Classic. Earning counts from FACTORY III, or once you own a style.
- The FACTORY III cutscene spotlights the board ("PLOT STYLES").
- Spec: `Tests/PlotStyles.spec` (24 checks). Tested in Play: a Legendary and an Exotic row earned
  both, Exotic went on the plot, switching works, a style you don't own is refused.

## Order

1. Framework + Style board + earned styles as palette recolours (no models needed), at Factory III.
2. Willem's kits per style as they come in.
3. Special styles for Gems once at least two exist.
