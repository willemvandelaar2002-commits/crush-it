# Tutorial and thumbnails vs LihFolk Vault V2 (5 Nov 2026)

Sources: skill lihfolk-tutorial (+ references/ftue-checklist.md, quality-score/rubrics/tutorial.md), Onboarding by
Genre - The First Five Minutes, 61 Thumbnails and CTR (Thumbnail Review Checklist and Scoring Rubric, Thumbnail
Genre Patterns, Thumbnail and Icon A-B Testing), Discovery and Monetization Changes 2025-2026.

## Tutorial (8 steps, then Goals2)
Measured in Studio: own Collect bin 70 studs from spawn, Sell 34, Roll 51 (walk speed 28: 1-3 s each);
intro cutscene ~4.5 s with Skip; step 1 pays at once (StarterScrap). First action well under 20 s.

Passes: server-owned progress and rewards, funnel per step (Joined ... tutorial done ... goals), reward every
step, one target with outline + trail, control names per device (E -> tap / X), pop-ups wait for the tutorial,
HUD revealed by goal, a next-goal chain after the tutorial, rejoin resumes.

| Gap (vault) | Status |
|---|---|
| Stuck hints after 6-10 s (ours 15 s) | **Fixed: 8 s** |
| Reduced Motion honoured (no pulsing) | **Fixed** for the tutorial outline, floor disc and HUD arrow |
| Skip for new players after step 1, with confirm, paying the step rewards (hard gate) | Open: Willem decides |
| One verb per step: goal 1 "Fill 3 bays" bundles unlock + roll + buy + place (the 21% drop) | The arrow already follows the sub-step; re-check with a fresh funnel before splitting |
| Core loop closed 3+ times in 5 minutes (simulators) | Collect/sell once in the tutorial, then repeated by the goals |
| Progress saved as step ids, not an index | Index (fine while steps are only appended) |
| Intro uses `PlayerModule:GetControls()` | Works until the Input Action System becomes default (Phase 2) |

## Thumbnails (Thumbnails/used = live; two unused)
Required since 19 Oct 2026 for Home: a custom 16:9 thumbnail. We have four (1672x941, fine; 1920x1080 ideal).
Scored with the vault rubric (0-10, 8.5 = ship; my estimate, not a blind review):

| Thumbnail | Est. | Notes |
|---|---|---|
| CRUSH IT! (press + grinning avatar) | ~7.5 | Best live one: hero, face, 2 words, reads at 160x90. Avatar and button touch the bottom-right corner |
| STARTER / PRO / SECRET | ~6.5 | Clean progression, readable; no face, three equal heroes |
| NOOB / PRO / HACKER | gate risk | "HACKER" tier doesn't exist in the game (G1 truthful); rename to SECRET or MYTHIC |
| STARTER -> MAX FACTORY | ~5 | Busy at small size, red arrow sticker (rubric: no arrows) |
| unused: NOOB vs PRO (two faces) | ~8 | Strongest concept: faces, emotion, 2 words, clear hero |
| unused: evening factory | ~5 | No hero, no face, no text |

Common to all: they show presses crushing grey cubes and cars. The game's unique twist is collectible crushers
crushing colourful toys into cash. Vault (simulator dialect): excited avatar + your one unique collectible at hero
size + visible currency; a before/after scale shot stands out. Test one change at a time, 7-14 days, keep the control.
