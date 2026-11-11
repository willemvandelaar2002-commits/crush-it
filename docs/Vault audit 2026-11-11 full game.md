# Full game check vs LihFolk Vault V2 (11 Nov 2026)

Round 8, on main `bff9f79`. Method: V2 `commands/audit.md` (the checker over `src/`, then the remote, data,
purchase and performance skills), measurements in Studio Play, and an economy bot that plays the real shared
rules (`CrusherRules.act`) with a greedy policy. Nothing was changed in the game.

Limits: Studio numbers are not phone numbers (frame rate in Studio was not usable; memory is inflated by
Studio). The bot never walks, hesitates or goes offline and uses no passes, boosts, frenzy, events or daily
rewards: it is the fastest a player could go, real players are several times slower. Real retention and
funnel numbers are in the Creator Dashboard, not here.

## 1. Code safety: no new problems
Checker: 224 files, 2 errors, 17 warnings, 184 info. All 19 checked and dismissed (same reasons as 5 Nov:
Studio-only test path, a display-only cash value, arguments compared to fixed strings, MemoryStore entry,
leaderboard score). The three new ones are GemMine (a pass prompt next to `math.random` for gem positions;
remote `kind` compared to fixed strings) and AutoRoll (picks whitelisted, 100 max).
Data (session lock, UpdateAsync, retries, autosave, BindToClose, SaveOff), receipts (grant + remember without
yielding, Granted only after a save) and the 23 remote handlers hold up. Still open from 5 Nov: chat prefix
tags end Feb 2027; `/credits` works for the owner in live servers.

## 2. Findings, most important first

| # | Area | Finding | Evidence | Fix | Size |
|---|---|---|---|---|---|
| 1 | Economy / shop honesty | **Every luck multiplier except the Luck upgrade does almost nothing after the first minutes.** Lucky pass (R$ 49), 2x Luck Boost (R$ 19), Server Luck (R$ 79), First Buy Deal's luck, rebirth luck (+25% each), Gem Luck (5,101 Gems), Lucky Weekend, Index luck, Divine/Eternal aftershock all multiply every non-Common weight by the same number, so they only shrink the Common share. Once Commons are rare there is nothing left to shrink | `C.rollWeights`. Legendary or better with a paid 2x: Luck 0 0.25% -> 0.38%; Luck 10 2.31% -> 2.66%; Luck 20 4.11% -> 4.41%; Luck 40 + rebirth 5 9.12% -> 9.21%. The bot has Luck 10 after 3 minutes. The shop text "Uncommon or better about 30% -> 46%" is only true at Luck 0 | Make a multiplier count more for higher ranks (e.g. as extra Luck levels, or weight x mult^rank share), and compute the shop text from the buyer's own current odds; if it does nothing for them, say so (vault: Paid Random Items in Practice, section 4) | M |
| 2 | Policy | **Paid luck is sold to players for whom paid random items are restricted** (the Netherlands and Belgium among others). Roblox lists luck boosts as paid random items ("probability modifier items"); only the Factory Crate checks `ArePaidRandomItemsRestricted`. The product prompts are client-side, so the gate must also be on the server | `Offers.luau:100` gates `kind == "crate"` only; `Boosts.client:106`, `Shop.client:98` prompt directly. The docs page does not spell out the restricted treatment for modifiers; the vault's reading is "block with a clear message" | Hide or disable Lucky pass, Luck Boost, Server Luck and the luck half of the First Buy Deal for restricted players (the attribute `PaidRandomItems` already exists); don't apply paid luck to them | S-M |
| 3 | Policy | **Roll odds are shown as "1 in N" only.** While a paid luck effect is active (also someone else's Server Luck) the rule asks for percentages of all outcomes that add up to 100% | `CrusherRollPresentation.oddsText`, Index, Auto Roller | An ODDS panel at the roll machine: every rarity with your current percentage (keep "1 in N" beside it) | S-M |
| 4 | Economy | **The top rarities stop being rare.** Base odds are 1 in 500,000 pedestals for an Eternal, but Luck scales with rank: Luck 25 + rebirth 1 = 1 in 6,214 per pedestal (about an hour of rolling with 5 pedestals); Luck 60 = 1 in 580 (one every ~6 minutes). The bot bought 9 Eternals, 16 Divines and 72 Secrets in 3,514 rolls. The big-roll counter shows the base odds, far from the roller's real odds | `C.luckFactor(60, 6.5)` = 39,232 | Decide what a late player should chase: lower `LuckGrowth` for the top ranks, or cap the factor per rank; and/or add a next tier or per-crusher depth (stars, coatings) as the long chase | M |
| 5 | Economy | **Big roll cinematics get too frequent late.** At Luck 40 + rebirth 5 a Secret or better is about 0.8% per pedestal, so about every 20-25 rolls (a bit over a minute) the roll holds 4.6-9 s. Skip exists but is manual | `C.BigRoll`, odds table | Short version for a type you already own; full cinematic for a first-time type | S |
| 6 | Economy | **Gems run out of purpose.** All mine upgrades are maxed after about 26 minutes in the mine (360 Gems a minute); every gem upgrade in the game costs about 59,600 Gems, 2-3 hours of mine time. After that only the Gem Crate (750) is left, and it is weaker than rolling: a Divine is 2% of a crate but at Luck 40 comes from rolling every ~8 minutes | bot on `GemConfig` | Hold the planned "Gem Yield" cash upgrade (it makes this faster). Give Gems a lasting sink: crate-only crushers or coatings, a cosmetic, or a repeatable upgrade | M |
| 7 | Performance | **Every client loads all six plots in full, including what is hidden.** 114,000 instances on the client; an empty plot is 7,326 instances with 2,782 invisible parts (later factory stages built up front), 164 SurfaceGuis, 78 prompts, 64 lights. Streaming is on but the target radius (1,024) covers the whole map | Measured in Play: Workspace 49,242 descendants (25,501 parts, 1,016 SurfaceGuis, 7,377 UIStrokes, 479 prompts, 390 lights) | Build a plot's later stages when its owner reaches them (or keep them in ServerStorage until then), and keep unowned plots to a shell. Then try a smaller streaming radius | L |
| 8 | Performance | **Crusher strikes are tweened on the server**, so every moving part's position is sent to every player all the time | Measured: about 27 kbps with 1 crusher, about 90 kbps (peaks over 200) with 60 special crushers, for one factory; six late-game players add up. Vault target: low tens of kbps per player | Send one "strike" event per bay (or use the existing `CrusherStrike` data) and play the motion on each client; skip factories far away | M |
| 9 | Performance | A full Factory VI of special crushers is 442,000 triangles and 377 draw calls in view, 1.35 M shadow triangles. Inside the vault's phone range (300-600k) but at the top; shadows are off on low phone settings | Measured in Play | With `Style.lite()`: `CastShadow` off on crusher meshes; nothing urgent | S |
| 10 | Pacing | **Fastest possible pace:** Factory II 3 min, III 7 min, IV 17 min, rebirth 1 at 20 min; later runs 14 min growing to about 1 hour; rebirth 10 at about 4 h, rebirth 12 at about 6 h. Factory V first shows up in run 4, Factory VI in run 6. Real players are several times slower, so the first rebirth is probably 1-2 hours, inside the vault's 1-3 h. Run growth (about x1.15 per rebirth) is gentler than the vault's x1.3-2 | bot, 2 seeds | No change before real numbers. Check `ReachedFactory` / `RebirthMinutes` in the dashboard; if real first rebirths are under an hour, raise `Rebirth.Growth` a little rather than the first cost | - |
| 11 | Content | **Nothing new after rebirth 10** (Gem Mine at 1, awakened crusher at 5, gem caps at 5 and 10). Data on 8 Nov: 3 players at rebirth 10 | config | Rebirth milestones at 15/20/25 (a look, a bay skin, a title) are cheap; the bigger answer is finding 4 and 6 | S-M |

## 3. Core loop
Crushers work by themselves, you collect, sell, roll for free, buy what you rolled, place, level, upgrade,
unlock bays, upgrade the factory, rebirth, mine gems. The vault's loop checks pass: a reward in the first
minute, numbers that grow fast, a free roll every 3 s with visible surprises, a long loop (rebirth), an own
verb (SMASH / frenzy, golden toys), an event every 15 minutes, a second place to be (Gem Mine).
Where it is thin: there are few real choices (buying everything affordable and pressing Equip Best is always
right), and the roll, the main thrill, loses its meaning late (findings 1, 4, 5). The strongest levers for fun
are therefore 4 (keep something rare) and 1 (make luck purchases and rewards do what they say).

## 4. Not checked here
A real phone (vault: 15-minute soak with the Developer Console memory page: Gui, GraphicsTexture, LuaHeap),
touch target sizes, D1/D7 retention, the shop funnel.

Vault notes used: commands/audit.md; Paid Random Items and Odds Disclosure in Practice; Genre Playbook - RNG and
Collection Games; Mobile and Low-End Optimization; Art Budgets - Triangles Draw Calls Memory; Interest Management
and Per-Player Replication; Client-Server Model; Progression and Pacing Design; World-Space UI. Roblox docs:
Paid random items policy guidelines.
