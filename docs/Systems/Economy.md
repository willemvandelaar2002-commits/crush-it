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

- 31 Oct: crusher strikes are timed from when they were due (CrusherRules.step), so real output matches the shown $/min (measured 99.9%; was ~98%). 2x Cash pass and 2x Cash boost multiply (x4 together).

- 31 Oct: overkill: damage above a toy's hp gives scrap x(1 + C.OverkillBonus*log2(damage/hp)), OverkillBonus 0.05 (+5% per doubling; ~+1.2% income per Damage level late game). Board Damage/Speed lines show the next level's real income gain on equipped crushers (CrusherUpgradeView incomeGain).

- 31 Oct: luck factor per rarity = (1 + LuckPerLevel*luck*rank) * LuckGrowth^(luck*rank), LuckGrowth 1.01 (2 Nov: LuckPerLevel 0.3 and LuckGrowth 1.015, about 2x the Legendaries at every level: per pedestal Legendary+ 1 in 90 at Luck 5, 55 at 10, 31 at 20, 21 at 30; Secret 1 in 970 at 10) (C.luckFactor, used by rolls and roll-odds text). Roll board shows "Legendary+ 1 in N > 1 in N".

- 31 Oct: YieldPerLevel 0.3 (was 0.2), OverkillBonus 0.08 (was 0.05), toy placing time = C.inputDelay(speed) = 0.8 x max(0.6, 0.94^speed) (Strike Speed now shortens it too).

- 31 Oct (rebalance): YieldPerLevel 0.25, OverkillBonus 0.065, PlacingFloor 0.7; plot costs Factory II/III/IV/V = $31.9M / $2.21B / $167B / $1.33T (III-V x0.8/x0.7/x0.6 of the bay-cost formula).

## 2 Nov: economy events (Creator Dashboard > Analytics > Economy)
Kit/Analytics `cash(player, sku, tx, before, after)` logs every cash change with its reason, summed per player and sent once a minute (and on leave); `cashBalance` (every second) logs whatever no call explained as `Passive` (gain) or `Other` (loss). Currency "Cash". Sources: SellScrap, AutoSell, GoalReward (Onboarding), Gift / GiftBonus / DailySpin / OfflineCash / TimeSkip / Code (TimedReward), IndexReward, FactoryEvent, QuestShop, cash packs and OfflineMultiplier / OfferPack (IAP), Passive. Sinks: UnlockBay, BuyCrusher (Shop), FactoryUpgrade, LevelUp, PlotUpgrade, Coating, Fusion, RollUpgrade.

5 Nov: the Luck board shows Legendary+ odds up to Luck 39 and Secret+ odds from Luck 40 (C.LuckBoardSecretFrom), where Legendary+ barely moves per level.
