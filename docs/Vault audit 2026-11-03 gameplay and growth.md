# Crush It vs the vault, round 2: gameplay, monetization and growth (3 Nov 2026)

The 2 Nov audit ([[Vault audit 2026-11-02]]) covered onboarding basics, receipts, data and anti-exploit; its items are done
except notifications. This round checks the game as it is after the 2-3 Nov updates (SMASH/FRENZY, golden toys,
Turbo, rebirth, shorter goals, intro cutscene, fill row, x10) against the checklists of these vault notes:
Core Loops and Session Design · First-Time User Experience and Onboarding · Retention and Return Hooks ·
Genre Playbook - RNG and Collection Games · Simulator and RNG Genre Teardown · Progression and Pacing Design ·
Economy Inflation Sinks and Faucets Math · Pricing and Store Design · Robux Price Points and Offer Design ·
Game Passes · Ethical Design and Player Trust · Social Design and Multiplayer Play · Community Building ·
Live Ops Events and Updates · Analytics and Funnels · Discovery and the Algorithm · Launch Strategy - The First Two
Weeks · Thumbnails Icons and Store Page · Sponsored Ads and Campaign Math.
The vault is advice (Roblox docs as of October 2026 plus rules of thumb); items are judged for this game.

## What we do well
- **Core loop and active play.** One-sentence loop (crush toys, sell scrap, roll and place crushers, grow the factory).
  SMASH/FRENZY makes active play worth about 2x idle (vault: 1.5-3x). Golden toys are a surprise every ~30 s.
- **First minutes.** Control at once, starter scrap makes the first collect instant, cheap first purchases, an
  intro that shows the long goal in minute one ("build the biggest factory"), 8 tutorial steps, then 12 short goals.
- **Funnel.** Every tutorial step and goal is logged (versioned when the list changes); economy events log every
  cash source and sink.
- **Return hooks.** Daily check-in (now with a grace day), daily spin, playtime gifts with a HUD countdown, offline
  earnings (capped), hourly factory events, What's New for returning players, codes.
- **Long loop.** Rebirth keeps the collection, shows now vs after, asks twice, costs grow with each rebirth, server
  banner. REBUILD and Equip Best make the replay fast.
- **Store basics.** Prices from GetProductInfo, one receipt handler, starter pack once per player, a cash ladder
  whose value per Robux rises (19/59/129 for 10/60/240 min), impulse items under 100, Turbo as a cash sink at
  every stage.
- **Odds and fairness.** Factory Crate checks PolicyService and shows odds; the Index shows your real odds with
  luck, passes and boosts; boosts stack by a written rule.
- **Social.** Friend boost (capped), invite button, rare rolls and rebirths announced to the server, a hub.
- **Tech.** Streaming on, world built by code, session-locked saves, Studio on a test save.

## Gaps, most useful first

| # | Gap (vault rule) | Why it matters here | Fix | Size |
|---|---|---|---|---|
| 1 | **"Press E" on phones** (FTUE: device-correct control text) | Tutorial steps 4 and 6 and the bay hints say "press E"; on a phone there is no E, there is a tap button. Most Roblox players are on phones, and these are funnel steps 5-7 | One helper: "press E" on PC, "tap the button" on touch, "press X" on gamepad | Small |
| 2 | **Full HUD from second one** (FTUE: HUD reveal driven by onboarding state) | A new player sees INDEX, SHOP, REWARDS, gift chip, SMASH, Auto Collect R$99, Turbo chip and the top row before the first collect. The vault calls this a bounce driver; 12.5% leave before collecting | Hide SHOP/offers, SMASH, top row until the tutorial step that needs them (SMASH appears with its goal) | Medium |
| 3 | **Auto Crush pass text is wrong** (Ethics: "see exactly what you get"; Game Passes: numeric effects) | The pass says "Crushes for you, even while you're AFK", but crushers always work; in this game it gives +25% damage. A buyer gets something else than the text promises | Rewrite to the real effect ("+25% crusher damage") or give the pass a real auto feature; update the dashboard text too. Same check for the cash-pack dashboard texts ("25% of your next press" is from the old game) | Small |
| 4 | **No pity / bad-luck protection** (RNG playbook: pity or token system, shown to players) | Long dry streaks on rolls are the main frustration in RNG games; the Index luck reward is the only help | A visible counter: "Legendary guaranteed in 120 rolls" (resets on a Legendary+) | Medium |
| 5 | ~~No shop funnel~~ | Correction: a shop funnel already exists (server/Shop, 31 Oct: Opened -> Saw a Robux price -> Bought). My first check searched for the wrong name | - | - |
| 6 | **First rebirth time unknown** (Pacing: long loop 1-3 h for the first; time per step logged) | Rebirth needs Factory IV ($87M) + $150M. If that takes 6+ hours, most players never see rebirth; each later run is now ~2.7x longer (vault's "gentle" is ~1.3-2x; plan new multiplier sources) | Log time-to-Factory III/IV and first rebirth (custom event with minutes played); tune after a few days | Small |
| 7 | **No in-game feedback path** (Community: feedback / report path) | Your players already give good ideas (fill row, rebuild); now they can only tell you in person | A FEEDBACK button: short filtered text, saved server-side for you to read | Medium |
| 8 | **No notifications** (Live Ops / Retention, open since 2 Nov) | Cheap D1 lever: "your offline cash is full", "event in 10 min" | Opt-in prompt at a value moment + Open Cloud sender (needs a small outside script) | Medium |
| 9 | **Store page and events** (Thumbnails; Discovery; Launch) | Play-through rate is the #1 ranking signal; custom thumbnails are required for Home | 3-5 thumbnails from the best ads, honest description, one Experience Event on the page, check "exclude from recommendations" is off | You (Creator Hub) |
| 10 | **Weekly review not a habit yet** (Analytics: weekly review, release dates annotated) | We publish several times a day; without dates the charts can't be read | Keep the Decisions log as the release log (already dated); look at funnel + retention once a week | Process |

## Smaller notes
- **Rewarded video ads** (Ads and Rewarded Video): eligible from 2,000+ monthly visitors; a "watch an ad for a
  2x cash boost" is a good fit later. Not urgent.
- **Offer engine** (Price Points): one server-side rule for when offers pop (after wins, cooldowns, caps). The
  pop-up gate covers automatic panels; a real offer engine only matters once there are more offers.
- **Numbers:** the suffix table goes to Dc (1e33). Fine for now; check if rebirths push cash past that.
- **Shared boss** (Social): factory events run per plot; a server-wide moment where everyone helps is the
  vault's strongest "come back together" pattern. Bigger project.

## Not relevant now
Trading, PvP, battle pass, subscriptions, season resets, combat anti-cheat.

## Suggested order
1, 3 and 5 are small and safe: do them now. Then 2 (HUD reveal) and 6 (timing data), then 4 (pity) and 7 (feedback).
9 is Willem's Creator Hub work; it is the cheapest lever for the algorithm.

## Done (3 Nov)
- 1 "press E" now reads "tap the button" on phones and "press X" on gamepads (Style.controls; tutorial hints and notices).
- 3 the pass card says "Production Boost: +25% damage for all your crushers, forever" (its dashboard name);
  cash pack texts say "10 minutes / 1 hour / 4 hours of your earnings". Willem: update the dashboard descriptions.
- 6 timing events: ReachedFactory (minutes played, factory name), ReachedFactoryAfterRebirth, RebirthMinutes.
