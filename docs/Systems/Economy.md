# Economy

22 Oct redesign: the current economy is documented in [[Collectible crushers]]
and configured in shared/CrusherConfig.luau (Config.Crushers). The object-tier
prices below are historical and retained for recovery; that income loop is dormant.

All numbers in `src/shared/Config.luau`. t = tier (1 = Apple), l = level.

| Thing | Formula |
|---|---|
| Object HP | 3 · 3.4^(t-1) |
| Object value | 3 · 6^(t-1) |
| Power (damage per press) | 1.28^l, cost 10 · 1.75^l |
| Speed (seconds per press) | max(0.3, 0.93^l), cost 15 · 1.8^l, max level 17 |
| Value (cash multiplier) | 1 + 0.2·l, cost 25 · 1.9^l |
| Bigger press (tier t → t+1) | value(t) · 10 · 1.32^(t-1) |
| Conveyor | 0.8 s between objects |

Simulated first run (greedy buyer): tier 2 at ~1.3 min, Car ~12 min, Tank
~23 min, Plane ~77 min. Later tiers slow down on purpose; rebirth takes over.

Tiers: Apple, Teddy Bear, Phone, TV, Fridge, Car, Truck, Tank, House, Plane,
Ship, Statue, Planet.

- 31 Oct: crusher strikes are timed from when they were due (CrusherRules.step), so real output matches the shown $/min (measured 99.9%; was ~98%). 2x Cash pass and 2x Cash boost multiply (x4 together). 5 Nov: the pass is a ladder (2x/4x/8x/16x, highest owned counts, see Shop).

- 31 Oct: overkill: damage above a toy's hp gives scrap x(1 + C.OverkillBonus*log2(damage/hp)), OverkillBonus 0.05 (+5% per doubling; ~+1.2% income per Damage level late game). Board Damage/Speed lines show the next level's real income gain on equipped crushers (CrusherUpgradeView incomeGain).

- 31 Oct: luck factor per rarity = (1 + LuckPerLevel*luck*rank) * LuckGrowth^(luck*rank), LuckGrowth 1.01 (2 Nov: LuckPerLevel 0.3 and LuckGrowth 1.015, about 2x the Legendaries at every level: per pedestal Legendary+ 1 in 90 at Luck 5, 55 at 10, 31 at 20, 21 at 30; Secret 1 in 970 at 10) (C.luckFactor, used by rolls and roll-odds text). Roll board shows "Legendary+ 1 in N > 1 in N".

- 31 Oct: YieldPerLevel 0.3 (was 0.2), OverkillBonus 0.08 (was 0.05), toy placing time = C.inputDelay(speed) = 0.8 x max(0.6, 0.94^speed) (Strike Speed now shortens it too).

- 31 Oct (rebalance): YieldPerLevel 0.25, OverkillBonus 0.065, PlacingFloor 0.7; plot costs Factory II/III/IV/V = $31.9M / $2.21B / $167B / $1.33T (III-V x0.8/x0.7/x0.6 of the bay-cost formula).

## 2 Nov: economy events (Creator Dashboard > Analytics > Economy)
Kit/Analytics `cash(player, sku, tx, before, after)` logs every cash change with its reason, summed per player and sent once a minute (and on leave); `cashBalance` (every second) logs whatever no call explained as `Passive` (gain) or `Other` (loss). Currency "Cash". Sources: SellScrap, AutoSell, GoalReward (Onboarding), Gift / GiftBonus / DailySpin / OfflineCash / TimeSkip / Code (TimedReward), IndexReward, FactoryEvent, QuestShop, cash packs and OfflineMultiplier / OfferPack (IAP), Passive. Sinks: UnlockBay, BuyCrusher (Shop), FactoryUpgrade, LevelUp, PlotUpgrade, Coating, Fusion, RollUpgrade.

5 Nov: the Luck board shows Legendary+ odds up to Luck 39 and Secret+ odds from Luck 40 (C.LuckBoardSecretFrom), where Legendary+ barely moves per level.

## 11 Nov: luck multipliers and the ROLL ODDS window (audit findings 1 and 3)
- **Multipliers work at every Luck level now.** Before, the Lucky pass, 2x Luck Boost, Server Luck, the
  weekend, rebirth luck, Gem Luck and Index luck multiplied every non-Common weight by the same number,
  which only shrank the Common share: after Luck ~10 a paid "2x luck" changed Legendary+ by about 10%.
  Now `C.rollWeights` multiplies the chance of every rarity-or-better: x2 = twice the chance of Rare or
  better, of Legendary or better, of Secret or better, of Eternal (each capped at 100%; the rarity below
  then gets less and Common can drop to 0%). All multipliers together count up to `C.LuckMultCap` = 10.
  The Luck upgrade still shapes the base (`C.luckFactor`). Server roll, pedestal odds, Index, Auto Roller
  and the Luck board all use this one function.
- **Effect (per pedestal):** rebirth 3 + Lucky pass (Luck 30, x3.5): Legendary+ 1 in 5, Secret+ 1 in 63,
  Eternal 1 in 1,243 (was about 1 in 4,200 with or without the pass). Rebirth 10 (Luck 50, x3.5):
  Eternal 1 in 315 (was 1 in 1,082). Rebirth 5 + pass + boost (x9): Eternal 1 in 238. Top rarities get
  more common for players with several multipliers: tune with `C.LuckMultCap` / `C.LuckGrowth` (open
  item, audit finding 4).
- **Texts from the player's own odds:** the shop (Lucky pass, Server Luck, 2x Luck Boost, Super Boost),
  the quick shop and the Boosts window show what 2x does for YOU now, e.g. "Exotic or better: 11% -> 16%"
  (the most common tier still under 40% for you), or that your luck is already at the maximum.
  `C.luckPreview` / `C.luckPreviewFor(player)`; the server publishes RollLuck, RollLuckMult and
  RollLuckBonus every second.
- **ROLL ODDS window** (client/RollOdds): the gold ODDS button top right on the roll machine. Every rarity
  that can roll right now with its chance per pedestal in percent (at least four digits after the first
  non-zero one; they add up to 100%), "1 in N" and the number of crushers; luck level and multiplier
  below, with a rounding note. Updates while a boost, Server Luck or the weekend starts or ends.
- Paid luck for players where paid random items are restricted: left as is (Willem: the luck also works
  on rolling, which is free).
