# QoL, game feel and platform vs LihFolk Vault V2 (5 Nov 2026, evening)

Round 7. Earlier audits covered code safety, tutorial, thumbnails, retention and monetization; this one covers
what they did not: player settings and QoL, game feel, and the 2025-2026 platform changes.

## Code checker: clean
`lihfolk-check --scan src`: 202 files, 2 errors, 14 warnings, 147 info. All 16 errors/warnings checked and dismissed:
- `datastore-no-pcall` DataService:233: `reloadForTest`, Studio mock only (asserts).
- `client-sets-currency` Main:491: a local NumberValue that animates the cash label, not leaderstats.
- `remote-unvalidated-args` x10 (Quests, Rewards, Offers, DailySpin, Shop, Feedback, Travel, Turbo, WhatsNew,
  Boosts): each compares the argument to fixed strings / looks it up in config before use; rate limits where value moves.
- `paid-random-no-policy` Scrap:145: `math.random` picks a scrap pile to merge into; nothing paid.
- `datastore-setasync-player` Notify:50: MemoryStore schedule entry, not player data.
- `datastore-no-bindtoclose` Kit/Leaderboard:83: leaderboard score only; the save itself has BindToClose.
- `instance-new-parent` PrismShowroom:50: one-off model build, fine.
The 147 info lines are FindFirstChild chains in client UI; none on a hot path. Same verdict as this morning's code audit.

## Gaps, most useful first

| # | Gap (vault) | Here | Fix | Size |
|---|---|---|---|---|
| 1 | **No settings menu** (QoL Top 25: #1 music/SFX volume via SoundGroups, #4 shake slider, #5 flash toggle, #13 saved settings, #14 effects density) | Music plays always, no way to mute it or the crusher sounds except the system volume; shake and flashes (big roll, frenzy, events) can't be turned down; `Style.lite()` only follows the device | A SETTINGS button: Music on/off + volume, Sound effects volume (SoundGroups), Screen shake on/off, Flashes on/off, Effects High/Low (drives `Style.lite`). Saved in the profile | S-M |
| 2 | **No crusher lock** (QoL #15: item lock enforced server-side in every destructive path) | Trash "all <rarity>" can take a coated, fused or Lv 100 crusher with one confirm; nothing marks a crusher as keep-forever | Lock toggle in the inventory; TrashMany, RecycleDuplicates and Fuse skip locked crushers (server); lock icon on the card. Auto-lock Secret+ on purchase | M |
| 3 | **No haptics** (Feedback Timing: sound, visual and haptic in sync) | Most players are on phones; SMASH, frenzy, golden toys and the big roll impact are silent to the hand | `HapticService` small pulse on SMASH tap and golden toy grab, strong one on big roll impact and plot upgrade; off with the shake setting | S |
| 4 | **Algorithm reads organic players only** (Discovery changes 2025-2026: RFY since Jun 2026 counts only joins from Recommended For You; signals = PTR, first-play bounce, 28-day retention) | All players come from ads, which feed none of those signals. Good ad numbers don't get the game recommended | Willem: Creator Analytics > Acquisition > Home Recommendations, watch PTR / bounce / D8-28 for organic joins only; keep ads as the way to fill servers, judge the game on organic data once it exists | You |
| 5 | **Week 2-4 reasons to return** (28-day window) | Daily reward is a 7-day cycle; after a week the reasons are rebirth and events | Check D8-28 retention first; if low: a weekly goal set or a week-2 daily cycle with a Secret-chance reward | Later |
| 6 | **Share links for invites** (Creator Rewards, Audience Expansion: 35% of a new player's first $100 if they joined through your Share Link; needs 100+ DAU avg over 60 days) | Invite button uses the game invite prompt | Not eligible yet (DAU). Revisit at 100 DAU | Later |

## Already fine (checked)
Prices from `GetProductInfoAsync` everywhere (regional pricing / Plus discounts correct); Plus via
`HasRobloxSubscription` (no deprecated MembershipType); custom thumbnails live; VIP tag already off chat
PrefixText; Reduced Motion respected in big roll, tutorial and shop; one automatic pop-up at a time (pop-up gate);
skippable tutorial; error toasts for rejected actions ("Need $X more").

## Suggested order
1 (settings) and 3 (haptics) together, then 2 (lock). 4 is a dashboard habit, no code.

Vault notes used: Top 25 QoL Wins by Effort; Discovery and Monetization Changes 2025-2026; Feedback Timing - Sound
Visual and Haptic Sync; Inventory QoL - Sort Filter Search Stack and Lock; hooks/scripts/rules.tsv (checker).
