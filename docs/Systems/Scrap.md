# Scrap and the scrap shop (20 Oct)

The core loop changed (after the Yuzu game Willem liked): **crushing no longer
pays cash**. The object breaks into scrap you pick up and sell.

1. **Crush** -> 3..6 scrap pieces (more for bigger objects, `Config.Scrap`) fly
   over the press onto **one pile** behind it (on a steel tray with a yellow
   frame, between the press and the shop); the pile grows wider and taller. Together
   they're worth exactly what the crush used to pay (Value upgrade, variant,
   rebirth, collection, 2x Cash, friend boost all still count). Pieces look like
   bits of the object (its colours mixed with metal; gold/glass for Golden and
   Diamond) and glint.
2. **Pick up** by walking into the pile (takes all of it) or over loose pieces (5.5 studs). No carrying limit. Carried
   scrap is `data.scrap` (saved), shown as the orange pill at the bottom
   ("$X scrap, Sell it at your Scrap Shop!").
3. **Sell** by standing on the yellow SELL pad of your own scrap shop: all scrap
   becomes cash, the furnace flares, coins, a big "+$X" over the smelter.
4. Max 40 pieces per plot on the floor; more value merges into lying pieces.
   Pieces are cleared on rebirth and when the owner leaves.

**Auto Collect** (Robux pass, R$ 99, id 0 for now): landed pieces fly to you
after 0.7 s and are sold straight away. Sign on the island next to the pad,
in the shop and in the featured offer rotation.

**Scrap shop island** (`server/ScrapShop.luau`, one per plot, behind it):
a lava channel across the back of the plot (`Config.ScrapShop.Channel` "Lava"
or "Oil", 7 wide; deep red cracked lava with a slow-moving glowing skin,
bubbles and lights; falling in puts you back on the plot side of the bridge), steel
bridge with yellow rails, a "SCRAP SHOP" gate with hazard pillars and orange
lamps, a 48 x 34 island with a hazard edge, the SELL pad, a conveyor into a
smelter (glowing furnace mouth with grill, hopper, smoking chimney, spinning
gear on the roof) and the Auto Collect sign. The fence and tree band moved back
behind the islands.

**Tutorial/guide:** after the first crush the banner says "Pick Up The Scrap!",
then "Sell Your Scrap At The Shop!" until you can afford the first upgrade;
the ground arrows lead to the sell pad when you carry scrap (always in the
first session, later once it would pay for an upgrade), and back to the press
when you're off your plot.

Not changed: offline earnings, rewards and cash packs still pay cash directly.

Files: `server/Scrap.luau`, `server/ScrapShop.luau`, `client/Scrap.client.luau`,
`Config.Scrap`, `Config.ScrapShop`, remotes ScrapPicked / ScrapSold.

## 20 Oct, round 2
- Pieces land on a pile behind the press instead of around it.
- Water replaced by lava (oil also available); channel 7 wide instead of 12 and the
  sell pad right behind the gate, so the walk press -> pile -> shop is shorter.
- Sky presets in Build.lighting: Day, Sunset (default), GoldenHour, Dusk, Smog
  (`Config.Look.Sky`).
