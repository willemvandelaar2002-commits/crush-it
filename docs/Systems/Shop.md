# Shop, onboarding, analytics

## 30 Oct Factory Crate presentation

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
