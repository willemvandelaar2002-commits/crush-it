# Shop, onboarding, analytics

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
