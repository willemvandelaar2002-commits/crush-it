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

## 31 Oct Prism Mech pad
The showroom machine is built 1.5x a bay's size (`OfferConfig.Showroom.pad.scale`,
passed to SpecialCrushers.build as an optional scale) on a 14-stud pad. The E prompt
is on `PromptAnchor` 3 studs above the pad centre (reach = pad radius + 8), not on
the raised name tag.

Robux signs: their SurfaceGui and drawn price button are inactive (Active and
Interactable off), otherwise the button eats the click and the ClickDetector never fires.

## 31 Oct crate reward shine
Legendary and Mythic crate rewards (the three tiles on the card and the rows in
the crate details) get the Index's CardFx: turning rays, shimmering rim and
sparkles (Epic stays plain, like the Index). Rows turn the rays behind the icon
(CardFx.special opts.center).

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
| Offline Earnings | 149 | (old pass, retired 30 Oct) offline cash is free: 10% of your normal rate, up to 6 h (1 Nov; was 50%, 8 h); 2x / 5x on the welcome-back card |

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
31 Oct, crusher game (the old press funnel below only ran in the retired game):
- Onboarding funnel (LogOnboardingFunnelStepEvent), saves that start fresh
  (tutorial step 1 on first join; `data.onboarding` = {funnel, funnelStep}).
  Step names = `C.FunnelNames`: 01 Joined the game, 02 Collected scrap,
  03 Sold scrap, 04 Rolled a crusher, 05 Bought a crusher, 06 Unlocked a 2nd bay,
  07 Placed a crusher, 08 Bought a factory upgrade, 09 Leveled up a crusher
  (tutorial done), 10-13 Has 6 / 12 / 18 / all 24 bays (only logged once the tutorial
  is done), 14-17 Bought Factory II / III / IV / V (1 Nov; were 10-13 for one day). Tutorial steps are
  logged in order when the tutorial moves on (also when it skips ahead).
- Shop funnel (LogFunnelStepEvent "Shop", one session per shop visit, 10 min):
  1 Opened the shop (not tab switches), 2 Saw a Robux price (a product or pass
  prompt closed), 3 Bought something (receipt granted / pass bought).
Old press-game funnel: 1 Joined, 2 FirstCrush, 3 FirstUpgrade,
4 SecondPress, 5 RebirthPress (Car), 6 FirstRebirth.
Custom events: ShopOpened (where from), PassPurchase, RobuxPurchase, Rebirth.

## Art
`docs/art/CrushIt_thumbnail.png` (1920x1080) and `CrushIt_icon.png` (512x512):
first versions made from an in-game shot of a golden car in the press.

## Offer buttons (right side, Shop.client.luau)
- Rainbow wobbling "2X Cash / ONLY R$ x" button. 5 Nov: it climbs the cash pass ladder
  (Store.CashLadder): 2X -> 4X -> 8X -> 16X CASH, always the next one up; gone after 16x
  (or while the next pass has id 0).
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

## 2 Nov: safer receipts, luck stacking, codes (vault audit)
- **Saving off = no purchases.** DataService sets the player attribute `SaveOff` when a session can't save (load failed, or another server took the profile). A red bar says so (client/SaveWarning), every Robux product prompt is refused, and `ProcessReceipt` answers `NotProcessedYet` without granting, so the receipt waits for a session that can save.
- **Retry without double grant.** A receipt whose purchase id is already in memory (granted, save failed) only retries the save, then answers `PurchaseGranted`.
- **Purchase log:** `data.purchaseLog`, last 30 `{ k = product, t = time, p = purchase id }`, for support.
- **Luck:** the Lucky pass and the 2x Luck boost now stack (x2 each, x4 with both; before, a pass owner who bought the boost got nothing). One weights function `C.rollWeights` feeds the server roll, the roll pedestal odds, the Index and the upgrade board; the Index shows YOUR odds (Luck upgrade, pass / boost, Index luck). Lucky pass text: "2x luck on crusher rolls: Uncommon or better about 30% -> 46% of rolls" (update the Creator Dashboard description too).
- **Codes** (Shared/CodesConfig, server/Codes, CODES tab in Rewards): once per player (`data.codesUsed`), optional expiry date, rewards cash seconds / boosts / crushers. Live codes: CRUSHIT (10 min of earnings), GOALS (2x Luck 15 min + 5 min of earnings, until 23 Nov 2026).
- **What's New** (Shared/NewsConfig, server/WhatsNew, client/WhatsNew): once per `Version`, never for players still in the tutorial, waits until no menu is open and no factory event runs. Bump `Version` and rewrite the lines with every update.

## QuickShop and the starter offer (3 Nov; monetization audit, vault: Pricing and Store Design)
- **5 Nov: retired as the shop.** The SHOP button always opens the full art shop (phones too). QuickShop only hosts the pushed Starter Pack card; the rows below are unused.
- client/QuickShop: a phone-sized shop in real pixels (rows 68-96 px, R$ buttons 104x48, text >= 14 px; measured 0 small
  texts / 0 small taps at 750x381). Phones always open it; on bigger screens it is the first page for players who own
  no pass, Starter Pack or Prism Mech. Sections: Starter Pack (until owned), passes you don't own, cash packs, boosts,
  then SEE EVERYTHING (crates with odds, Mythics) opens the full shop.
- Starter offer: once per session, after the tutorial and the first goal and at least 3 minutes in the session, when
  no menu/cutscene/pop-up is open and saving works: the same window with only the Starter Pack and SEE THE SHOP.
  Never shown to owners. Logged as ShopOpened "StarterOffer".

## 4 Nov Starter Pack offer card
The once-per-session pushed offer (Shop.client -> QuickShop.openOffer) opens `client/StarterOffer.luau`, built after
Willem's mockup: real Candy Colossus portrait (CrusherIcon), cash = Store.cashFor(CashRate, cashMinutes), boost minutes
from OfferConfig, live Robux price (GetProductInfo; id 0 = COMING SOON). Buy = OfferAction "Prompt" (same as the shop);
"Browse shop" opens the full shop (5 Nov); closes itself when the pack is owned. Hover motions run only while it is open.

## 5 Nov monetization round 2
- Store: VIP pass (gamePassId 0 until created), products ServerLuck (R$99), TurboNow (R$49), CashHuge (12 h, R$299), CashMega (24 h, R$499); ids 0 stay hidden (Store.existing).
- server/ServerLuck (workspace ServerLuckEnds/ServerLuckBy; perks.lucky x2), server/Turbo.grantNow, Shop.grant handlers; VIP x1.5 in perks.mult and 12 h offline.
- client/MomentOffer (one small card, max one unprompted offer per session with the starter offer: attribute AutoOfferShown), WeekendHud Server Luck pill, Turbo panel Instant Turbo strip, VipTag chat prefix.
- RobuxSigns: product signs (CashSmall, CashMedium) with the plot owner's amount, at plot x 12 z 98.

## 5 Nov: Roblox Plus card and V2 audit fixes
- Shop > Passes ends with a Roblox Plus card (`PromptRobloxSubscriptionPurchase`, shows ACTIVE when
  `player.HasRobloxSubscription`). Roblox pays 250 R$/month for a subscriber's first 3 months when they sign up
  through it (vault V2, Subscriptions and Premium Payouts). Perk: [PLUS] chat tag (VipTag.client), cosmetic only.
- `ShopOpened` analytics: only known source names (else "Other"), max one per 0.5 s per player.
- Pass ownership at join: 4 tries with backoff.
- See [[Vault audit 2026-11-05 code audit V2]].

## 5 Nov: status tags, odds in text, grant check, processing pill
- server/NameTags: a gold "VIP" (VIP pass) or blue "PLUS" (Roblox Plus) pill above the head, built on the
  server so everyone sees it; VIP wins. Mirrors Plus to the player attribute `PlusMember` (the chat tag reads it).
  The chat tags (VipTag.client) stop working when Roblox's platform-integrated chat becomes default (Feb 2027);
  the head tags stay.
- Server Luck and 2x Luck Boost texts state the odds: "Uncommon or better about 30% -> 46% of rolls".
- Shop.canGrant + a startup warning in Output for any product without a grant; an unknown product is refused
  (the receipt waits) instead of falling through to the cash-pack branch.
- Purchase processing pill (Shop.client, own ScreenGui): shows when Roblox's window closes with a buy, until the
  server's Purchased event; after 15 s "On its way: it arrives by itself, even if you rejoin."; gone after 25 s.

## 5 Nov: live ids and Willem's price cut
Product ids: Server Luck 3728462569 (R$79), Instant Turbo 3728462615 (R$29), 12H Time Skip 3728462797 (R$299),
24H Time Skip 3728462818 (R$399); VIP pass 2072630333 (R$399). Willem lowered: Production Boost 199 -> 79,
2x Cash 249 -> 59, Lucky 149 -> 99, Auto Collect 99 -> 69, Starter Pack 69 -> 49. Managed pricing on.
The game shows Roblox's live price everywhere; `price` in Store.luau is only the fallback.
No "was/now" sale label: the old prices were live for under a week (vault Limited-Time Offers: a reference price
must have been the live price for 30+ days; Roblox: no permanent "sale").
Quests (QuestConfig): "Start FRENZY 3 times!" (daily) and "Grab 50 golden toys!" (weekly) replace the Daily Spin
quests; QuestRules keeps frenzies/goldenToys/turbos/gifts (they were wiped on load before).
- 5 Nov: red "LOWER PRICE!" ribbon (ShopPanel `lowerPrice`, `Store.PriceDrop`) on the four passes and the Starter Pack
  whose price Willem cut, hidden once owned, gone by itself on 13 Nov 00:00 Amsterdam. No "was" price shown.
  VIP went live at R$199 (new, so no ribbon).
- 5 Nov (Willem's reference video; vault: "sections stacked in one scroll, featured first"): the shop is ONE scroll
  (ShopPanel `scroll`): Featured (Starter Pack, Prism Mech) -> Crates (+ odds note) -> Boosts -> Passes + Roblox Plus
  -> Cash. The tabs (FEATURED, CRATES, BOOSTS, PASSES, CASH) jump to their section and light up for the section in
  view; the shop opens at the top. Cash: "Cash Pile / Cash Stack / Cash Vault" (10 min / 1 h / 4 h of earnings, the
  Roblox names) and a "Time Skips" row (12H, 24H, Willem's clock icon 139908856885129).
- 5 Nov: banners show live prices: Starter Pack and Prism Mech buttons show "R$ n" and buy directly (tiles/crusher
  still open details); the Factory Crate has a price button under the chest that opens its details with all the
  odds first (paid random item: never bought straight from the banner). Shop buttons are studded like Willem's
  reference shop (`Style.buttonStuds`: stud colour map tinted with the button colour; a caption child keeps the
  text above the studs; RobuxIcons skips the invisible button text).
- 5 Nov shop polish (Willem's brief): cash and time-skip products are 3:4 portrait cards (designed at 240 x 320,
  scaled to a third of the shop width) on Willem's backgrounds (cash 91426858476957, time skip 74672158230253):
  title, bobbing icon, live amount, "Cash = N of earnings" (no timers move), studded price button. Boosts and
  passes are benefit-first cards (title, big benefit like "2x LUCK", one short line at a fixed size, full-width
  price/OWNED button) in cyan/blue, pink/purple or yellow/orange. Roblox Plus is one full-width row. The Starter
  Pack details show three big reward tiles (featured-card colours) and the live price on BUY. Icons bob 2.5 px
  (ShowcaseMotion, paused when the shop is hidden); Style.feedback press is now 0.97.

## 5 Nov: cash pass ladder (Willem)
Four game passes: `DoubleCash` 2x (R$ 19), `CashX4` 4x (R$ 49), `CashX8` 8x (R$ 129), `CashX16` 16x (R$ 299).
You get the highest one you own (`Store.cashPassMult`), not all multiplied together, so 16x is 16x (with the
VIP x1.5 and the timed boosts still on top, like before). The right-side button, the shop panel and the quick
shop only offer the next step (`Store.nextCashPass`); the shop panel shows your top one as OWNED at the end.
New passes have id 0 until Willem creates them (hidden until then). The 2x Cash sign beside Sell is gone
(C.RobuxSignSpots). Owning a higher pass without the lower ones (bought from the game page) works fine.

## 6 Nov: First Buy Deal (R$ 5)
Product `FirstBuy` (Store), contents `O.FirstBuy` (OfferConfig): Gumball Gobbler (Epic) + 15 min 2x Cash + 15 min
2x Luck, once per player (d.offers.owned.FirstBuy, attribute Offer_FirstBuy). Granted by server/Offers via the one
ProcessReceipt (OfferRules handles `boosts`, a list). client/FirstBuy: a rainbow wobbling "R$ 5 DEAL" icon button
after the last visible button of the top-left row (Index / Shop / Rewards / Rebirth), in the Shop gui, so it shows
when the shop does; opens Willem's empty card board (image 77919314377312, FirstBuy.Art) with the title, crusher icon
and name, the two boost tiles, a close sprite, a BUY R$ 5 button (live price) and "Only once per player!" laid out on it
like his reference picture. Hidden while the
product id is 0 and once owned. Shop funnel source "FirstBuyButton".

## 6 Nov: phones
The right-side offers are hidden on phones (FitsScreen false), so the next cash pass is a rainbow icon button
"PhoneCashButton" in the top-left row there (same ladder, same buyPass; ShopOpened source "PhoneCashButton").
The shop window on phones is scaled by width only and made shorter (fitPhone in ShopPanel); the page scrolls.

## 6 Nov: no featured pass card
The featured pass card under the cash button (Auto Crush / Auto Collect / Lucky / Offline) is gone (Willem); the
right side only has the cash ladder button. First Buy Deal: now game pass `FirstBuy` (2074832519), hidden from pass
lists; server/Offers grants O.FirstBuy once when it sees the pass owned.

- 2026-11-08 (Willem, "impatient kid" playtest): the R$ 5 deal and the 2x/4x/8x/16x cash button show from goal C.RobuxButtonsGoal (5), read from the HudStage attribute (client/HudReveal). The starter pack no longer pops up 3 minutes in: only once all main goals are done (after Factory II), still once per session.

- 2026-11-11: AUTO WALK pass (`AutoWalk`, 2079272256, R$ 49), hidden from the pass lists: sold by its board beside the gem platform in the Gem Mine (see [[Systems/Gem Mine]]).
