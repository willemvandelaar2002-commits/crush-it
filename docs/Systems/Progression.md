# Progression (rebirth, rare objects, collection)

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
REWARDS gift button next to BOOK/SHOP, "!" badge when something can be claimed.
- Playtime gifts: 8 rewards after 2, 5, 10, 15, 25, 40, 60, 90 minutes in this session (reset on rejoin).
- Daily check-in: 7 days, one claim per UTC day (`data.daily = { day, streak }`); missing a day restarts at day 1, after day 7 it starts over.
- Cash rewards are N seconds of your current earning rate (min $25), so they stay useful at every stage; some slots give Golden objects (adds to goldenRush).
- All numbers in `Config.Rewards`. Server checks time and claims; analytics events PlaytimeReward / DailyReward.

## Friend boost (server/FriendBoost.luau)
+10% crush cash per Roblox friend in the same server, max +50% (`Config.FriendBoost`).
Player attribute FriendBoost; multiplies crush cash and the offline/reward rate.
HUD: "Friend Boost: X%" under the cash with a green + that opens Roblox's invite dialog.

## Ground guide (client/Guide.client.luau + Kit/GuidePath)
White chevrons on the ground lead to: the upgrade board while the tutorial is
on "Buy An Upgrade" (first session, can afford it, no upgrades yet), and back
to your own press whenever you're more than 40 studs from it. Hidden otherwise.
