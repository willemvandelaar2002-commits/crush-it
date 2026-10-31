# Shop, onboarding, analytics

## 31 Oct Cash pack icons

The three cash packs in the Cash tab each have their own illustrated icon,
`ShopArt.CashPacks` by product id: CashSmall = Cash Pile 91590888539709,
CashMedium = Cash Stack 140435524782279, CashLarge = Cash Vault 72188129858951
(sources in `assets/shop-card/cash/`). Only these cards use them; Icons.Cash is
unchanged everywhere else (HUD, rewards, Starter Pack, AutoCollect pass).
- `cashCard` in ShopPanel: 122 px art slot on the left (same slot for all three,
  ScaleType Fit, old cash icon as fallback until loaded); right side in separate
  rows: title, live amount (+Store.cashPackAmount), "<time> of earnings" from
  Store.CashPackMinutes, then the buy button bottom-right. Card height unchanged.
- Art is still at rest; hover grows/tilts the slot a little (Style.hoverLift),
  the buy button keeps Style.feedback. Prices, amounts, SOON state and buying unchanged.
- Studio check 31 Oct (MockData): three different correct icons load with clean
  transparency, full vault visible; amounts +$1.5K / +$9K / +$36K and R$ 19 / 59 /
  129 live; hover/press/leave back to the exact pose; no new Output errors. No
  purchase made. Desktop only.

## 31 Oct Prism Mech showroom card

`client/PrismMechCard.luau` builds the Prism Mech card in Featured and Packs
(replaces the old gradient banner). Third card of the shop art pass.
- Art: `ShopArt.PrismMech.Backplate` = 102747752191257 (PrismMech-Background.png,
  source in `assets/shop-card/`), 1974 x 797, 816 x 329 design size. A plain violet/
  gold card shows until it loads. Prism Mech icon = existing CrusherIcons entry.
- Layout: Prism Mech large on the left over the glow; right side inside the safe
  area (x 38-80 %, y 16-77 %, clear of the corner crystals): PRISM MECH title
  (cyan-pink-gold), MYTHIC badge (`Style.RarityGradients.PrismMythic`: #9BDEFF,
  #57EFFF, #A775FF, #FF5EC8, small #FFE475 accent), GUARANTEED CRUSHER tag
  (OWNED when owned), "Plot showcase: visit your plot to inspect it", then green
  FIND ON PLOT and cyan DETAILS side by side (glossy, dark lower edge).
- Behaviour unchanged: FIND ON PLOT fires the existing Travel "Plot" and closes
  the shop; DETAILS and the hero open showroomDetail (price/buying stay there).
  No tiles, odds, timers or scarcity text: one guaranteed crusher.
- Motion: hero floats (4 px, 3 degrees, 3.6 s) only while visible and uncovered;
  buttons use Style.feedback (grow/press/restore).
- Studio check 31 Oct (MockData): Featured and Packs show it; backplate and Prism
  Mech icon load with clean transparency; hero moves without hover, pauses on the
  hidden tab, when scrolled out of view and under details; hover/press/leave on
  both buttons back to scale 1; DETAILS opens details (R$ 399 live price), Back
  works; FIND ON PLOT closed the shop and moved the player back to the plot; OWNED
  switch checked with a client-only attribute (no purchase); no new Output errors.
  Desktop only; phone not checked.

## 31 Oct Candy Starter Pack card

`client/StarterPackCard.luau` builds the Starter Pack card in Featured and Packs
(replaces the old gradient banner; ShopPanel passes the live contents in).
- Art: `ShopArt.CandyStarter.Backplate` = 85230684065313 (CandyStarter-Background.png,
  source kept in `assets/shop-card/`), native 1974 x 797 (~2.48:1), 816 x 329 design
  size scaled to the banner width. A plain purple/pink card shows until it loads.
  Candy Colossus, Icons.Cash and Icons.DoubleCash are the existing icons, unchanged.
- Layout: Candy Colossus large on the left (on the mint glow); right side: STARTER
  PACK + ONE-TIME PACK tag, three tiles (MYTHIC Candy Colossus GUARANTEED / CASH live
  amount + "1H EARNINGS" / BOOST 2x Cash + "15 MIN"), glossy green VIEW PACK with a
  dark lower edge; all clear of the corner sweets and the lower shelf.
- Values are live: crusher, rarity, cashMinutes and boost minutes from
  OfferConfig.StarterPack / BoostConfig; the cash amount = Store.cashFor(CashRate,
  cashMinutes), same as the details page (falls back to "1H OF CASH" at rate 0).
  Owned: tag and button switch to OWNED (grey). No odds: everything is guaranteed.
- Colours: `Style.rewardCard` with the new palettes CandyMythic, Cash and CashBoost
  in `Style.RarityGradients` (palettes are colour lists, evenly spaced, or a ready
  ColorSequence; Legendary moved to one, unchanged look).
- Motion: Candy Colossus floats (4 px, 3 degrees, 3.4 s) only while the card is
  visible and not covered by details/reveal; tiles use `Style.hoverLift` (6 %, lift
  4 px, tilt 3 degrees, icon 10 %, press 95 %); VIEW PACK uses Style.feedback.
- Hero, tiles and VIEW PACK all open the existing Starter Pack details (price,
  ownership and purchase stay there).
- Studio check 31 Oct (MockData): Featured and Packs both show it; backplate, Candy
  Colossus, cash and 2x cash icons load with clean transparency; hero moves on its
  own and pauses on the hidden tab and under details; hover/press/leave on all
  three tiles and the button return to the exact pose; VIEW PACK opens details
  (R$ 69 live price), Back works; OWNED switch checked with a client-only attribute
  (no purchase). No new Output errors (one Roblox 500 permission hiccup on the
  Arcade Claw icon, unrelated). Desktop only; phone not checked.

## 31 Oct Factory Crate card (illustrated, approved compact layout)

`client/FactoryCrateCard.luau` builds the same card in Featured and Crates. It
replaces the 30 Oct showcase layout below (the motion helpers stay).
- Art: `shared/ShopArt.luau` holds the uploaded IDs (FactoryCrate-512 chest
  70891364292898, FactoryCrate-Backplate 77076356662252, FactoryCrate-Illustrated
  117905280807172 hi-res, unused). The backplate keeps its ~2.48:1 ratio (816 x 329
  design size, scaled to the banner width) and already carries the border, studs,
  glow, gears and shelf, so the card draws none of those itself. Fallbacks: a plain
  blue/gold card and the old crate icon (Icons.FactoryCrate) until each image loads.
- Layout: chest left (on the backplate glow) with the crate title under it;
  "SOME OF WHAT'S INSIDE" over three reward cards on the right, all inside the
  safe area (x 6-94 %, y 15-84 %). Each reward card has separate bands for
  rarity / crusher icon / name (2 lines) / chance pill, so nothing overlaps.
- Preview: Ducky Dynamo, Arcade Claw, Disco Destroyer (Card.Approved) while they
  are still in the crate; a missing one is replaced by one crusher per rarity.
  Icons, names, rarity and each crusher's own chance come from the game data.
- Reward look: `Style.rewardCard(frame, rarity)` (new, reusable): diagonal
  multicolour gradient per rarity (`Style.RarityGradients`: Epic lilac-violet-blue-
  cyan, Legendary cream-yellow-gold with a cyan accent, Mythic pink-hot pink-purple-
  cyan), #13172A outline, white inner rim, soft top highlight; static rays behind
  the crusher.
- Motion: the chest floats all the time the card is visible (4.5 px, 3 degrees,
  3.4 s; paused when the shop is closed, offscreen or covered by details/reveal).
  Reward cards are still until hovered/focused: `Style.hoverLift` (new) grows 6 %,
  lifts 4 px, tilts 2 degrees, crusher art 10 %; press compresses to 95 %; leaving
  or clicking restores the pose; every change cancels the previous tweens.
- Clicking the chest or any reward opens the existing crate details (all nine
  rewards with exact chances). Pricing, purchase, receipts, reveal unchanged.
- Studio check 31 Oct (MockData): both tabs show the card, both images load with
  clean transparency, chest moves on its own, hover/press/leave and fast repeated
  hovering return to the exact pose, click opens details and the chest pauses
  there, Back works, no new Output errors. Desktop only; phone layout not checked.

## 30 Oct Factory Crate presentation (superseded layout)

`client/FactoryCrateCard.luau` builds the same showcase in Featured and Crates.
The crate is first in Featured for this presentation pass. The card is taller (338 authored pixels): blue/gold factory theme, large existing
crate image, four individual preview portraits and one larger spotlight. Every
percentage is copied verbatim from `OfferConfig.odds`; this is a labelled subset
of the full reward list. The spotlight uses highest rarity then lowest chance,
with source-order ties; it does not claim unique best output or change weights.
All artwork/portrait/CTA clicks open the existing full crate details. No new
images or upload IDs are needed.

Shared Style helpers `floatArt`, `spinArt`, `glint` and `focusBlur` delegate to
`Kit/ShowcaseMotion`. Art motion shares one client 30 Hz connection, stops writing
while an ancestor/page/ScreenGui is hidden, the card is clipped offscreen, or a
detail/reveal overlay covers it, and cleans up destroyed targets. Camera blur is
owned by the shop and preserves other effects. Buttons retain Style.feedback.
The common detail page gets a short cancellable entrance slide.

Desktop presentation first; existing panel fitting remains, but this pass does
not claim phone-layout acceptance. Studio checks: Featured/Crates, scroll edges,
all preview/CTA routes, full odds and price/eligibility states, detail back/close,
reveal/skip/collect, modal handoff, camera replacement and repeated open/close.
No changes to server/OfferConfig/Store/remotes/receipts. Offline validation is
not Studio Play verification.

## 27 Oct shop window and offers (current)
Shop window = `client/ShopPanel.luau` (built by `Shop.client`, same `ShopHud`,
`ShopButton` and `OpenShop` contract; new `OpenOffer` = offer id opens its
details). Gold studded header, tilted basket, tabs FEATURED / CRATES / PACKS /
PASSES / CASH, wide banners, detail pages, crate reveal. Prices shown come from
Roblox (`GetProductInfo`), never from config; id 0 shows SOON.

Offers (`shared/OfferConfig.luau`, rules `shared/OfferRules.luau`, server
`server/Offers.luau`). **All amounts and odds are test defaults, not approved.**

| Offer | Store product | Contents | Rule |
|---|---|---|---|
| Starter Pack | `StarterPack` | Candy Colossus + CashPacks.CashMedium cash + 2x Cash boost (BoostConfig minutes) | once per player |
| Factory Crate | `FactoryCrate1` | one of 9: Ducky / Wind-Up / Gumball (Epic, 18% each), Arcade / Disco / Kraken (Legendary, 12% each), Jackpot / Seraph / Phantom (Mythic, 3.3333% each); test odds | paid random item |
| Prism Mech | `Mythic_PrismMech` (existing id kept) | Prism Mech | once per player, showroom pad on every plot |

- Buying: client sends `OfferAction("Prompt", product)`; the server checks id ≠ 0,
  not already owned, crate eligibility and one open prompt at a time, then
  prompts. Granting only happens in Shop's single ProcessReceipt.
- Receipts: `processFor` checks PurchaseId → grants (no yields) → remembers id →
  saves. Offers check everything first, then apply crusher/cash/boost together,
  so a receipt is all or nothing. Paid crushers ignore the inventory limit. A
  second paid receipt for a one-time offer (two servers racing) still delivers and
  logs a warning.
- Crates: PolicyService `ArePaidRandomItemsRestricted` per player (attribute
  `PaidRandomItems`; unknown = restricted). Restricted players see UNAVAILABLE and
  the server refuses the prompt; guaranteed offers stay buyable. Odds are shown on
  every crate banner and on See all rewards & chances before purchase (4 digits
  past the first non-zero digit + Roblox's rounding note). The server picks the
  crusher at the receipt, grants it and saves a reveal (`d.offers.reveals`). The
  reveal animation only shows it; COLLECT sends Seen. Skip/close/leave = the same
  result shows again; nothing rerolls. Willem's own account (NL) is restricted.
- Save: `d.offers = { owned = {StarterPack, PrismMech}, reveals = {...} }`;
  attributes `Offer_StarterPack`, `Offer_PrismMech`.
- Showroom (`server/PrismShowroom.luau`, `client/PrismShowroom.client.luau`):
  plot-local pad (-59, 99), 11 studs, front-left corner by the entrance (in the
  longer front yard, Plots.Front 112); machine faces entrance + walkway (yaw 45°). Real
  imported model via SpecialCrushers.build, demo stroke every 4 s, slow soft
  rainbow ring/light, name tag with GUARANTEED CRUSHER / OWNED ✓ per viewer, E =
  View offer. Cosmetic only, no scrap.
- The other four Mythic_* products are hidden but still honoured by receipts.
- Studio tests: `ServerStorage.DevReceipt:Invoke(player, product, purchaseId)`
  (real receipt path), `DevCrateAccess:Invoke(player, "allowed"|"restricted")`,
  `DevProduct` (grant only). Set ServerStorage attribute `MockData = true` to keep
  Play off the real DataStore; remove it afterwards.
- Still to configure: product ids + Roblox prices for StarterPack, FactoryCrate1,
  Mythic_PrismMech; final pack amounts and crate odds.

22 Oct redesign: [[Collectible crushers]] documents the current tutorial and
perk mapping. Basic automatic crushing is free; AutoCrush owners gain +25%
damage, Lucky improves crusher rarity weights, AutoCollect collects/sells,
DoubleCash and OfflineEarnings use fleet production. IDs and ownership attribute
contracts are retained. FinishSmelt now sells finished scrap, and GoldenRush
keeps ten 10x completion bonuses. Legacy promotions are hidden during the new loop.

## Robux (`src/shared/Store.luau`)
All ids are **0** until the passes/products exist on the Creator Dashboard;
a 0 id shows "SOON" and can't be bought. Fill the ids in Store.luau only.

| Pass | Price | What it does |
|---|---|---|
| Auto Crush | 199 | Crushes for you (AUTO switch on the CRUSH button), keeps you from the AFK kick |
| 2x Cash | 249 | Double cash per crush |
| Lucky | 149 | 2x Golden and Diamond chance |
| Offline Earnings | 149 | 50% of your normal rate while offline, up to 8h |

| Product | Price | What it gives |
|---|---|---|
| Cash Pile | 29 | 25% of the next press's price |
| Cash Stack | 79 | 1x the next press's price |
| Cash Vault | 199 | 4x the next press's price |
| Golden Rush | 49 | Next 10 objects are Golden |

- Receipts (server/Shop.luau): grant → remember PurchaseId (last 50) →
  save → PurchaseGranted. Failed save = NotProcessedYet (Roblox retries).
- Returning players who were away 5+ min see a "Welcome back" card: owners
  get the offline cash, others see what they missed + the pass.
- Locked AUTO button opens the Auto Crush purchase.
- Studio test hooks (ServerStorage): `DevPass:Invoke(player, perk, true)`,
  `DevProduct:Invoke(player, id)`, `DevOffline:Invoke(player, hours)`,
  `DevGiveCash:Invoke(player, amount)`.
- Chat command `/credits <amount>` (or `/cash`): gives cash, e.g. `/credits 5m`
  (k/m/b/t/qa). Works in Studio and, live, only for the place owner.

## Onboarding (`src/client/Onboarding.client.luau`)
Pulsing ring + hint: Hold CRUSH → buy first upgrade (when affordable) →
get a bigger press (when affordable). Gone once the press is bigger.

## Analytics (`src/server/Kit/Analytics.luau`)
Funnel (new saves only): 1 Joined, 2 FirstCrush, 3 FirstUpgrade,
4 SecondPress, 5 RebirthPress (Car), 6 FirstRebirth.
Custom events: ShopOpened (where from), PassPurchase, RobuxPurchase, Rebirth.

## Art
`docs/art/CrushIt_thumbnail.png` (1920x1080) and `CrushIt_icon.png` (512x512):
first versions made from an in-game shot of a golden car in the press.

## Offer buttons (right side, Shop.client.luau)
- Rainbow wobbling "2X Cash / ONLY R$ 249" button (DoubleCash pass); hidden once owned.
- Featured pass card under it with a "BEST!" ribbon: Auto Crush, then Lucky, then Offline Earnings (first one not owned); hidden when all owned.
- Both fire ShopOpened analytics ("DoubleCashOffer" / "FeaturedOffer") and prompt the pass ("Coming soon!" while ids are 0).
- SHOP is now a big icon button with a "!" badge until the shop is opened once per session; hidden offers while the book is open.

## Robux signs on the plot (server/RobuxSigns.luau)
Two chunky signs left of the press (mirroring the upgrade board, moved with it
when the press grows): Auto Crush and 2x Cash with icon, description and a green
price button. Click (ClickDetector, 60 studs) -> server prompts the pass ("coming
soon" notice while the id is 0, analytics "SignClicked"). On the owner's plot a
pass they have shows OWNED. Which passes: `RobuxSigns.Signs`.

## Offline earnings card (30 Oct, after Destroy a Vault)
The Offline Earnings game pass is gone: everyone gets offline cash (Store.Offline:
50% of the normal rate, up to 8 h, from 5 min away). The welcome-back card has a
gold studded header with the moon icon, "While OFFLINE you earned...", and three
columns: **Take It** (free, 1x, red), **2X IT!** (blue) and a rainbow **5X IT!**,
each with its amount. Studs are tinted with each colour and drift; the 5X IT! rainbow flows (hue cycles), glows and pulses. Products OfflineX2 (R$ 25) and OfflineX5 (R$ 59) are in
Store.Products with productId 0 (the card shows SOON) until Willem creates them.
Server (Shop.luau): the record is saved as `data.offline = {cash, seconds, paid}`.
Take It pays 1x; a multiplier receipt pays up to mult x the cash minus what was
already paid (so Take It then 2x pays the extra 1x). A receipt with no record pays
30 min of earnings x mult. An unanswered card pays 1x on the next join.
OfflineAction remote: "Collect".

## Game pass ids and Robux signs (31 Oct)
Pass ids: Production Boost (perk AutoCrush) 2060699266, 2x Cash 2039584674, Lucky
2041580327, Auto Collect 2057934074. The old Auto Crush (2041790315) and Offline
Earnings (2039938725) passes are not used. Prices everywhere come from Roblox
(Store.livePrice on the client, RobuxSigns.price on the server).
Small Robux signs (6x4 studs, CrusherConfig.RobuxSignSize) on every plot, facing
the walkway (CrusherConfig.RobuxSignSpots): Auto Collect beside the bin, 2x Cash beside
Sell, Lucky by the road (no Production Boost sign). Click = pass prompt; OWNED on the
owner's own signs.
