# Retention hooks (4 Nov 2026)

First data (Creator Dashboard, 7 days to 2 Nov): **D1 retention 1.1-1.2%**, Roblox's simulation benchmark is 7-13%
(50th-90th percentile). Mostly cheap ad traffic; D7 not available yet. Stickiness (DAU/MAU) 42%.

## Come back tomorrow (client/ComeBack, server/Rewards)
- After today's daily reward is claimed, a card shows "COME BACK TOMORROW / Day N: <tomorrow's prize>"
  (cash at today's earning rate). Once per session; goes away by itself after 7 s when there is no question.
- In the Rewards panel the claimed tile shows CLAIMED and tomorrow's tile counts down ("TOMORROW 4:35:52").

## Daily pops up on join (client/Rewards)
When you join with today's daily ready, the Rewards window opens on the DAILY tab once, after any other window, never during an event/cutscene or the first tutorial; gives up after 2 minutes.

## Notifications (server/Notify, Shared/NotifyConfig)
- REMIND ME on that card opens Roblox's own opt-in prompt (only shown when Roblox allows asking: 13+, not opted in,
  not asked in the last 30 days, and only once NotifyConfig.DailyReady is set).
- On leaving (session of 3+ min), one job goes into the MemoryStore sorted map `NotifyDaily_v1`, due 22 h later
  and never before tomorrow's daily can be claimed. Joining any server deletes it. Servers poll every 20-30 s,
  claim a job before sending, and send it with Roblox's Open Cloud package (ServerScriptService.OpenCloud,
  asset 16584168800, saved in the place file, not in Git). Studio never sends.
- **Willem:** create the string in Creator Dashboard > Engagement > Notifications ("Day {day} reward is ready: {reward}! Your factory kept
  crushing while you were away."), paste its asset id in NotifyConfig.DailyReady,
  and Publish (the place must include the OpenCloud package). Watch the Turn Off rate on its Analytics tab.

## LUCKY WEEKEND (Shared/WeekendConfig, client/WeekendHud)
- Every Saturday 00:00 to Monday 00:00 UTC: 2x luck on rolls for everyone (perks.lucky in CrusherGame).
- HUD pill under the top-right buttons: Friday "LUCKY WEEKEND in 9h 20m", during it "2x LUCK WEEKEND · 1d 4h".
- **Willem:** a weekly Experience Event "Lucky Weekend" (Creator Hub > Events, Notify Me) and "2x luck every
  weekend" in the description.

## Creator Rewards (Roblox payouts, no code)
5 R$ per day per Active Spender who plays 10+ min and opens Crush It among their first 3 games that day;
35% of new/returning users' first $100 of purchases (needs 100+ average DAU, ID-verified creator).
Levers: the daily reward + notifications (open us first), a first session past 10 minutes, invites/share links.
