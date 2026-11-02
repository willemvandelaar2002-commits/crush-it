# Crush It vs the Roblox vault checklists (2 Nov 2026)

Checked the game against the checklists in the LihFolk vault (`willemvandelaar2002-commits/roblox-vault`):
onboarding, core loop, retention, simulator / RNG playbooks, monetization, receipts, odds and policy, data
saving, live ops, anti-exploit. The vault is advice, not law; items are judged for this game.

## Already in good shape
- **Onboarding:** control at once, first collect instant (starter scrap), tutorial rewards, cheap first purchases,
  end moment + 16-goal chain, one goal on screen, exact arrows, funnel step per step (01-28).
- **Receipts:** exactly one `ProcessReceipt` (server/Shop), purchase id stored with the grant, `PurchaseGranted`
  only after a successful save, unknown product / missing player = `NotProcessedYet`, retired products keep
  their grant code.
- **Paid random items:** the Factory Crate checks `PolicyService` (`ArePaidRandomItemsRestricted`) and shows odds;
  the Daily Spin shows odds per prize; the Index shows "1 in N" per crusher.
- **Data:** DataService has a session lock inside `UpdateAsync`, autosave, save on leave, `BindToClose`, and a
  failed load never saves over the real profile. Saves migrate (Schema).
- **Prices** in the shop come from `GetProductInfo`; id 0 shows SOON.
- **Remotes:** CrusherAction checks distance to the station on the server.
- **Retention:** daily spin, playtime gifts, quests/goals board, offline earnings capped (10%, 6 h), events every
  hour with a quiet countdown, friend boost, invite button.

## Gaps, most useful first
1. **No economy events.** Nothing calls `AnalyticsService:LogEconomyEvent`, so the Creator Dashboard can't show
   where cash comes from (crushing, selling, rewards, packs) or where it goes (bays, upgrades, rolls, plots).
   That is exactly what the balancing of the last weeks needed. Fix: one helper that logs every cash source and
   sink (batched, fixed names). *Medium.*
2. **Studio plays on the real save.** With API access on, Studio loads and saves Willem's live profile; a test
   can change it (2 Nov: a test set his goal counter). Fix: MockData on by default in Studio, real save only
   with an explicit switch. *Small.*
3. **Lucky pass description was wrong** ("Golden and Diamond objects", a removed system). Fixed in Store.luau
   (2 Nov): "2x luck on crusher rolls: Uncommon or better about 30% -> 46% of rolls". **Willem: update the
   pass description on the Creator Dashboard too.**
4. **Odds don't include your luck.** The Index shows base "1 in N"; with Lucky, a 2x Luck boost or the Index luck
   bonus your real odds are better. The vault (and Roblox's paid-modifier guidance) wants the odds screens to
   show the effective odds live, numbers before / after for luck products. *Small-medium.*
5. **Failed load is silent.** If the DataStore is down the player plays on a fresh save that will not be kept.
   Fix: a clear "saving is off, please rejoin" banner and block Robux purchases for that session. *Small.*
6. **No return notifications.** Experience Notifications (opt-in after a delayed-payoff moment, e.g. "your next
   event starts in 10 min" / "your offline earnings are full") are a cheap D1/D7 lever and the game is eligible.
   *Medium.*
7. **No codes.** Codes (once per player, with expiry) are the standard way to reward group members and bring
   players back with each update. *Small-medium.*
8. **No in-game "What's New".** A once-per-version panel (skipped for brand-new players) makes updates visible and
   pairs with update announcements. *Small.*
9. **Pop-up gate:** check that a first session never stacks automatic pop-ups (offline card, starter pack,
   spin) and that they go through one rule. *Check first.*
10. **Purchase log for support:** saves keep the last 50 purchase ids only; a short log (product, time) helps with
    "I bought X and didn't get it". *Small.*

## Done (2 Nov, same day)
1 economy events · 2 Studio test save by default · 3 Lucky text · 4 your odds in the Index (+ pass and boost now stack) ·
5 saving-off warning, purchases blocked, receipts wait · 7 codes · 8 What's New · 9 pop-up gate (only the offline card
and What's New pop up on their own; What's New waits for the others) · 10 purchase log.
Open: 6 notifications (needs an Open Cloud sender outside Roblox; for now use Creator Hub update announcements).

## Not relevant now
Combat / movement anti-cheat, trading, battle pass, subscriptions, season resets, commerce.

Sources (vault notes): First-Time User Experience and Onboarding · Core Loops and Session Design · Retention and
Return Hooks · Genre Playbook - Simulators · Genre Playbook - RNG and Collection Games · Analytics and Funnels ·
Developer Products and ProcessReceipt · Paid Random Items and Odds Disclosure in Practice · Data Loss Prevention
and Recovery · Experience Notifications and Return Prompts · Live Ops Events and Updates · Patch Notes and Player
Communication.
