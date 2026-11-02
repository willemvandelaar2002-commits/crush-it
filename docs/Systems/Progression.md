# Progression (rebirth, rare objects, collection)

22 Oct redesign: progression now means global Production upgrades, global
Rolling upgrades and levels on unique owned crusher instances. Rebirth/object
collection are retained for recovery and migration, with no active legacy
income. The Book panel now compares crushers. See [[Collectible crushers]].

All numbers in `src/shared/Config.luau`.

## Rebirth
- Unlocks once your press reaches `Config.Rebirth.RequiredTier(rebirths)`:
  the Car for the first rebirth, one tier further each time (capped at the Planet).
- Resets cash, press size and Power/Speed/Value levels.
- Gives a permanent cash multiplier: 1 + 0.5 × rebirths (x1.5, x2.0, x2.5…).
- Button: the gold "Rebirth" card under Bigger Press; tap twice ("SURE?") to confirm.

## Golden and Diamond objects
- Every object that rolls in can be **Golden** (5%, pays x10) or
  **Diamond** (0.5%, pays x50). Same HP as normal.
- Gold/diamond tint, sparkles, a special burst and "GOLDEN!" / "DIAMOND!" on the crush.
- A Diamond crush is announced to everyone in the server.

## Collection book
- "BOOK" button (top left) → every object with a 3D preview (black until
  crushed) and how many Normal / Golden / Diamond you've crushed.
- The first crush of each version adds a permanent cash bonus:
  Normal +1%, Golden +3%, Diamond +10% (all 39 = x2.82).
- A red dot on the BOOK button means something new was added.

## Cash per crush
`ObjectValue(tier) × Value upgrade × variant mult × rebirth mult × collection mult`
(rebirth × collection is shown next to your cash as "x1.75" etc.)

## Goal bar (Goal.client.luau)
Top centre, Destroy a Vault style: cash / price of the next Bigger Press with
"Next up: <object>". Full bar pulses and says "Tap to unlock"; tapping buys the
press. Once rebirth is unlocked it turns gold: "Rebirth ready! Cash xA > xB".
Cash moved to the bottom-left corner (top centre on phones, because of the thumbstick).

## Leaderboard (Leaderboard.client.luau + Kit/Leaderboard)
Top right, replaces Roblox's player list. Tabs: Here (this server, live),
Friends (you + friends in this server), Global (all-time top 50 by cash,
OrderedDataStore "CashBoard_v1", refreshed every 2 min; empty in Studio).
4 rows visible, your own row pinned under them when off screen, X collapses it to 🏆.
Score is current cash (like Destroy a Vault), so it drops when you spend or rebirth.

## Free rewards (server/Rewards.luau + client/Rewards.client.luau)
REWARDS gift button next to INDEX/SHOP, "!" badge when something can be claimed.
Panel styled after the reference game: purple header with the gift poking out, Skip All and X in the header,
Playtime/Daily tabs down the left, six cards (3x2) and the grand prize (the last entry) in a wide rainbow bar.
Cards: reward on top, icon on white rays, green CLAIM / red countdown / grey CLAIMED bar. Stud pattern drifts.
- Playtime gifts (29 Oct balance): cash 30s / 90s / 200s / 600s of earnings at 2, 5, 15, 40 min; Rare crusher at 10 min, Epic at 25 min; grand prize at 60 min = Legendary crusher + 20 min of cash (5% Mythic chance). Per session, reset on rejoin.
- Daily check-in: 7 days, one claim per UTC day (`data.daily = { day, streak }`); missing a day restarts at day 1, after day 7 it starts over. Cash 2/4/6/8 min of earnings, Rare on day 3, Epic on day 6 (1% Mythic), day 7 = Legendary + 20 min of cash (2% Mythic).
- Cash rewards are N seconds of your current earning rate (min $25), so they stay useful at every stage. `bonusSeconds` on a crusher reward pays that much cash on top. Full inventory: a crusher reward becomes 4 min of cash.
- Quest token shop: 15m Time Skip 50 tokens, 1h Time Skip 160 tokens (were 20/60). Index milestones: 4 min and 10 min of cash (were 10/30).
- All numbers in `Config.Rewards`. Server checks time and claims; analytics events PlaytimeReward / DailyReward.

## Friend boost (server/FriendBoost.luau)
+10% crush cash per Roblox friend in the same server, max +50% (`Config.FriendBoost`).
Player attribute FriendBoost; multiplies crush cash and the offline/reward rate.
HUD: "Friend Boost: X%" under the cash with a green + that opens Roblox's invite dialog.

## Ground guide (client/Guide.client.luau + Kit/GuidePath)
White chevrons on the ground lead to: the upgrade board while the tutorial is
on "Buy An Upgrade" (first session, can afford it, no upgrades yet), and back
to your own press whenever you're more than 40 studs from it. Hidden otherwise.

## 2 Nov evening: more to do (Willem's "making the game faster" doc + Sell Ores + vault)
- **SMASH + FRENZY** (server/Frenzy, client/Frenzy, `C.Frenzy`): red SMASH button on the right (key F). Each tap pays 0.25 s of income (max 4 counted taps a second) and fills a 25-tap meter; full = FRENZY, every crusher 2x fast for 10 s (perks.speed in CrusherRules.stats). The meter drains after 2 s idle. Active play earns about 2x idle (vault: 1.5-3x).
- **Golden toys** (server/GoldenToys, `C.GoldenToys`): every 25-45 s, while you are on your plot after the first collect + sell, a glowing golden toy lands at one of your bays for 12 s. Walk into it or press E: 30-60 s of income, 12% chance of a 2-min 2x Cash/Luck boost instead.
- **TURBO pump** (server/Turbo, client/Turbo, Shared/TurboConfig; a station on every plot by the Production board): cash-bought income multipliers, price = seconds of your income: TURBO x2 5 min (150 s), MEGA x3 10 min (600 s, Factory II), HYPER x5 15 min (1800 s, Factory III), ULTRA x8 15 min (3600 s, Factory IV). The strongest running turbo counts; time stacks to 60 min; saved across rejoins. A chip shows the running turbo.
- **Free-gift countdown** under the REWARDS button ("FREE RARE CRUSHER 4:12"); tap it to open Rewards.
- **Rare-roll banner**: anyone rolling a Legendary or better is announced to the whole server (client/RarePull).
- **Prices and caps**: bays x1.36 each all the way (no blend back to x1.45); factories 10x their first new bay: $39K / $2.2M / $87M / $3.5B / $22B. Caps start 20/40, then 30/60, 40/80, 55/110, 70/140, 90/180 (factory upgrade / crusher level); Luck keeps 20-60.
- Goals v4 (20): Frenzy after Bay3, Golden after Fill5, Turbo after Fill6.

## 2 Nov evening (2): merge, Coating Lab earlier, rebirth
- ~~MERGE~~ removed the same evening (Willem: the fuser already combines crushers). Crushers merged while it was live keep their stars (`item.stars`, x1.5 each); nothing adds stars any more. Goals v6 drop the Merge goal; a save sitting on a removed goal moves to the next goal that still exists.
- **Coating Lab** now opens with Factory II (`C.CoatingPlotLevel = 1`) instead of Factory III, so coatings are there early.
- **REBIRTH** (`C.Rebirth`, CrusherRules "Rebirth", client/Rebirth, HUD button slot 3 shown from Factory III): needs Factory IV and $150M x8^rebirths cash. Resets cash (to $1K), scrap, bays (back to 1, bay 1 keeps its crusher), factory level, Damage/Speed/Yield and crusher levels. Keeps every crusher (coatings, fused), the Index, Luck, pedestals, passes. Each rebirth +50% income forever (x1.5, x2, x2.5...; in perks.mult). Server-wide banner. Saved as `d.crushers.rebirths` (the old `d.rebirths` belongs to the retired press game). The panel asks twice.
- Roll-speed upgrade: not added; RollSpeed was retired for pedestals earlier and pedestals already speed up rolling.
- Lucky Block helpers: waiting for models.
