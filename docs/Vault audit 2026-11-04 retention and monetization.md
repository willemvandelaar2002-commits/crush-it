# Retention and monetization vs the vault, round 3 (4 Nov 2026)

Checked against: Retention and Return Hooks, Robux Price Points and Offer Design, Subscriptions and Premium Payouts
(Creator Rewards), Ads and Rewarded Video, Limited-Time Offers, case studies Grow a Garden / Pet Simulator 99 /
Steal a Brainrot. Earlier rounds: [[Vault audit 2026-11-03 gameplay and growth]], [[Vault audit 2026-11-03 monetization]].

## First: the numbers we don't have yet
- Vault: "if D1 retention is poor, offers are rearranging the deck chairs". We have never looked at D1 / D7.
  Creator Dashboard > Analytics > Retention (D1, D7) and Engagement (play days per user, the discovery signal).
- Shop funnel since QuickShop (3 Nov): Opened -> Saw a Robux price -> Bought. Tells whether the shop is seen at all.

## Retention: what we have (hook families, vault: combine 3-4)
Calendar (daily 7-day + grace day, daily spin), timer (playtime gifts), goal (goals, now to the first rebirth;
daily/weekly quests), accumulation (offline cash + welcome-back card), social (friend boost, invite, group goal,
rare-pull/rebirth banners), collection (Index + rewards), content (hourly factory events, What's New, codes).
All seven families exist; the gaps are in the details.

| # | Gap (vault rule) | Fix | Size |
|---|---|---|---|
| R1 | Chore quests: "Play 30 min / 5 h" and "Spin the Daily Spin" reward being present, not playing ("retired chore quests" in the vault's reference game) | Replace with loop verbs: golden toys, FRENZY, Turbo, fill a row, coat | Small |
| R2 | Quest rewards are fixed tokens; vault: rewards scale with progress | Token shop already scales cash; fine. Check the quest panel is visible to new players after the tutorial | Check |
| R3 | No "resolves tomorrow" moment at the end of a session (D1 hook) | Show tomorrow's daily reward (e.g. "Tomorrow: RARE crusher") on the daily panel and the leave screen of the rewards chip | Small |
| R4 | No notifications (open since 2 Nov) | Opt-in prompt after a good moment ("tell me when my offline cash is full") + Open Cloud sender | Medium + outside script |
| R5 | Creator Rewards pays 5 R$/day per Active Spender who plays 10+ min and opens us among their first 3 games of the day | Same levers as D1: daily first-open reward, keep the first session past 10 min | (design aim) |
| R6 | D30 needs content: vault cadence = small update every 2-4 weeks, events announced in advance | A weekend server-wide event (2x luck Saturday) announced on the page + Experience Event | Medium |

## Monetization: still open from the 3 Nov plan
Done: QuickShop for phones / non-payers, Starter Pack offer once per session, honest texts, pity.

| # | Item (vault) | Why | Size |
|---|---|---|---|
| M1 | **Server Luck** (99): 2x luck for everyone in the server, 15 min, buyer announced | Social visibility sells; also helps every other player (friendly, not pay-to-win) | Medium |
| M2 | **Near-miss / big-moment offers**: after a Legendary+ roll or a 1-off pity, a small dismissible "2x Luck 15 min - 19" card; one server-side offer gate with a global gap | "The moment beats the price"; Luck/Super boosts exist but are hidden | Small-medium |
| M3 | **VIP pass** (399): x1.5 cash, +2 h offline cap, VIP tag in chat/leaderboard | Empty 299-599 rung; status for kids | Medium |
| M4 | **Robux Turbo** at the pump (instant ULTRA) | Consumable at the moment a player wants speed | Small |
| M5 | Rewarded video (2x cash 10 min) | Only from 2,000+ unique monthly visitors; check Monetization > Ads > Eligibility | Small once eligible |
| - | Not now: subscription (needs a daily loop and payers first), battle pass, comeback discounts (teach players to leave), more passes (vault: 3-5 is enough at this size) |

## Suggested order
1. Willem: screenshot Retention (D1/D7) and the shop funnel since 3 Nov.
2. R1 + R3 (small, both D1).
3. M1 Server Luck + M2 moment offers (one offer gate).
4. R4 notifications, then M3 VIP.
