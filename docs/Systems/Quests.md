# Quests

Reference: Willem's video of another game's Quests window (25 Oct).

- **Window** (`client/Quests.client`): gold studded header with a ticket icon, tabs
  Daily / Weekly / Shop with "Your Tokens" underneath, "Refreshes in 14h 19m",
  rows with icon, title, progress bar (gold, green when done), token reward and
  Claim (grey / green / "Claimed"). "+5 Quest Tokens!" pops above the window.
  Opens from the QUESTS HUD button (red "!" when something is claimable) or the
  `[E]` plate on the Quests booth in the hub (tag `QuestsPrompt`).
- **Lists and shop** (`shared/QuestConfig`): 6 daily and 7 weekly quests
  (play time, rolls, crushed toys, sells, crusher buys, level-ups, upgrades,
  Daily Spin), paid in Quest Tokens. Shop: 15 min / 1 h time skips (cash from
  current earnings) and Uncommon to Legendary crushers (into the backpack;
  refunded when the inventory is full).
- **Rules** (`shared/QuestRules`, tests in `Tests/QuestRules.spec`): progress is
  "counter now - counter at the start of the day/week" (UTC days, weeks from
  Monday). Counters: `crushers.rolls`, `crushed`, and `d.stats` (play, sells,
  buys, levels, upgrades, spins), bumped by `CrusherRules.act`, Daily Spin and
  the server's 15 s online tick (`server/Quests`). Each quest pays once per period.
